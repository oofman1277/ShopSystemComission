local CurrencyShop = {}

--/ SHORTCUT VARIABLES /--
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyServer = script.Parent
local EconomyShared = ReplicatedStorage:WaitForChild("EconomyShared")
local Events = EconomyShared:WaitForChild("Events")

local EconomySaving = require(EconomyServer:WaitForChild("EconomySaving"))
local EconomyManager = require(EconomyServer:WaitForChild("EconomyManager"))
local CurrencyProducts = require(EconomyServer:WaitForChild("CurrencyProducts"))

local PurchaseCurrency = Events:WaitForChild("PurchaseCurrency")

--/ LOCAL HELPER FUNCTIONS /--
local function GetPlayerById(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function GrantCurrency(player: Player, amount: number): boolean
	if not EconomySaving:IsSessionActive(player) then
		return false
	end

	return EconomyManager:AddCurrency(player, amount)
end

local function ProcessReceipt(receipt): Enum.ProductPurchaseDecision
	local amount = CurrencyProducts[receipt.ProductId]
	if typeof(amount) ~= "number" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = GetPlayerById(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted = GrantCurrency(player, amount)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

--/ CORE /--
function CurrencyShop.PromptPurchase(player: Player, productId: number)
	if typeof(productId) ~= "number" then
		return
	end

	if CurrencyProducts[productId] == nil then
		warn("[CurrencyShop] Unknown developer product:", productId)
		return
	end

	local success, errorMessage = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)

	if success then
		return
	end

	warn("[CurrencyShop] PromptProductPurchase failed:", errorMessage)
end

function CurrencyShop.Initialize()
	MarketplaceService.ProcessReceipt = ProcessReceipt
end

PurchaseCurrency.OnServerEvent:Connect(function(player: Player, productId: number)
	CurrencyShop.PromptPurchase(player, productId)
end)

return CurrencyShop
