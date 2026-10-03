local ShopService = {}

--/ SHORTCUT VARIABLES /--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EconomyServer = script.Parent
local EconomyShared = ReplicatedStorage:WaitForChild("EconomyShared")
local Events = EconomyShared:WaitForChild("Events")

local EconomySaving = require(EconomyServer:WaitForChild("EconomySaving"))
local EconomyManager = require(EconomyServer:WaitForChild("EconomyManager"))
local ShopItems = require(script:WaitForChild("ShopItems"))

local FetchToolData = Events:WaitForChild("FetchToolData")
local PurchaseTools = Events:WaitForChild("PurchaseTools")

local MAX_COUNT = 100
local purchasing = {}

--/ LOCAL HELPER FUNCTIONS /--
local function IsOwned(purchasedTools, item): boolean
	if not item.Permanent then
		return false
	end

	if typeof(purchasedTools) ~= "table" then
		return false
	end

	return purchasedTools[item.Id] == true
end

local function CopyItem(item, owned: boolean)
	return {
		Id = item.Id,
		Name = item.Name,
		Price = item.Price,
		Permanent = item.Permanent,
		IconId = item.IconId,
		Description = item.Description,
		Owned = owned,
	}
end

--/ CORE /--
function ShopService.BuildCatalog(player: Player)
	if not EconomySaving:IsSessionActive(player) then
		return nil
	end

	local purchasedTools = EconomySaving:GetPurchasedTools(player)
	local catalog = {}

	for _, item in ShopItems.Tools do
		table.insert(catalog, CopyItem(item, IsOwned(purchasedTools, item)))
	end

	return catalog
end

function ShopService.SendCatalog(player: Player)
	local catalog = ShopService.BuildCatalog(player)
	if not catalog then
		return
	end

	FetchToolData:FireClient(player, catalog)
end

FetchToolData.OnServerEvent:Connect(function(player: Player)
	ShopService.SendCatalog(player)
end)

--/ PURCHASE /--
local function ReadCount(value): number?
	if typeof(value) ~= "number" then
		return nil
	end

	local count = math.floor(value)
	if count <= 0 or count > MAX_COUNT then
		return nil
	end

	return count
end

local function RejectPurchase(player: Player)
	PurchaseTools:FireClient(player, false)
end

local function BuildPurchaseLines(player: Player, cart)
	if typeof(cart) ~= "table" then
		return nil
	end

	if not EconomySaving:IsSessionActive(player) then
		return nil
	end

	local purchasedTools = EconomySaving:GetPurchasedTools(player) or {}
	local lines = {}

	for toolId, rawCount in cart do
		if typeof(toolId) ~= "string" then
			return nil
		end

		local item = ShopItems.Get(toolId)
		local count = ReadCount(rawCount)
		if not item or not count then
			return nil
		end

		if item.Permanent and count ~= 1 then
			return nil
		end

		if item.Permanent and purchasedTools[toolId] == true then
			continue
		end

		table.insert(lines, { Item = item, Count = count })
	end

	return lines
end

local function GetLineTotal(lines): number
	local total = 0
	for _, line in lines do
		total += line.Item.Price * line.Count
	end

	return total
end

local function CanGrantLines(lines): boolean
	for _, line in lines do
		local template = ShopItems.GetTemplate(line.Item.ToolName)
		if not template then
			warn("[ShopService] Tool template missing: " .. tostring(line.Item.ToolName))
			return false
		end
	end

	return true
end

local function SavePermanentTools(player: Player, lines): { string }
	local savedIds = {}
	for _, line in lines do
		if not line.Item.Permanent then
			continue
		end

		local saved = EconomySaving:SetPurchasedTool(player, line.Item.Id, true)
		if not saved then
			return savedIds
		end

		table.insert(savedIds, line.Item.Id)
	end

	return savedIds
end

local function UndoPermanentTools(player: Player, savedIds: { string })
	for _, toolId in savedIds do
		EconomySaving:SetPurchasedTool(player, toolId, false)
	end
end

local function GiveTools(player: Player, lines): { Tool }
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return {}
	end

	local granted = {}
	for _, line in lines do
		local template = ShopItems.GetTemplate(line.Item.ToolName)
		for _ = 1, line.Count do
			local tool = template:Clone()
			tool.Parent = backpack
			table.insert(granted, tool)
		end
	end

	return granted
end

local function DestroyGranted(granted: { Tool })
	for _, tool in granted do
		tool:Destroy()
	end
end

local function CanAfford(player: Player, total: number): boolean
	local money = EconomyManager:GetPlayerMoney(player)
	if typeof(money) ~= "number" then
		return false
	end

	return money >= total
end

local function ExpectedToolCount(lines): number
	local expected = 0
	for _, line in lines do
		expected += line.Count
	end

	return expected
end

local function PermanentLineCount(lines): number
	local count = 0
	for _, line in lines do
		if line.Item.Permanent then
			count += 1
		end
	end

	return count
end

local function RefundPurchase(player: Player, total: number, granted: { Tool }, savedIds: { string })
	DestroyGranted(granted)
	EconomyManager:AddCurrency(player, total)
	UndoPermanentTools(player, savedIds)
end

local function FinishPurchase(player: Player, lines, total): boolean
	if not EconomySaving:IsSessionActive(player) then
		return false
	end

	local savedIds = SavePermanentTools(player, lines)
	if #savedIds ~= PermanentLineCount(lines) then
		UndoPermanentTools(player, savedIds)
		return false
	end

	if not EconomyManager:AddCurrency(player, -total) then
		UndoPermanentTools(player, savedIds)
		return false
	end

	local granted = GiveTools(player, lines)
	if #granted == ExpectedToolCount(lines) then
		return true
	end

	RefundPurchase(player, total, granted, savedIds)
	return false
end

function ShopService.Purchase(player: Player, cart)
	if purchasing[player] then
		return
	end

	local lines = BuildPurchaseLines(player, cart)
	if not lines then
		RejectPurchase(player)
		return
	end

	if #lines == 0 then
		PurchaseTools:FireClient(player, true)
		ShopService.SendCatalog(player)
		return
	end

	local total = GetLineTotal(lines)
	if not CanAfford(player, total) or not CanGrantLines(lines) then
		RejectPurchase(player)
		return
	end

	purchasing[player] = true
	local success = FinishPurchase(player, lines, total)
	purchasing[player] = nil

	if not success then
		RejectPurchase(player)
		return
	end

	PurchaseTools:FireClient(player, true)
	ShopService.SendCatalog(player)
end

PurchaseTools.OnServerEvent:Connect(function(player: Player, cart)
	ShopService.Purchase(player, cart)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	purchasing[player] = nil
end)

return ShopService
