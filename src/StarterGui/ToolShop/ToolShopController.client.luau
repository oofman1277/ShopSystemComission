--/ SHORTCUT VARIABLES /--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyShared = ReplicatedStorage:WaitForChild("EconomyShared")
local Events = EconomyShared:WaitForChild("Events")
local FetchToolData = Events:WaitForChild("FetchToolData")
local PurchaseTools = Events:WaitForChild("PurchaseTools")

local scriptsFolder = script.Parent
local ToolShop = scriptsFolder.Parent
local CheckoutButton = ToolShop:WaitForChild("Checkout"):WaitForChild("Button")
local ToolShopUI = require(scriptsFolder:WaitForChild("ToolShopUI"))

local MAX_COUNT = 100

-- Display only. Price, permanence, and ownership are decided on the server.
local cachedTools = nil
local cart = {}
local checkoutPending = false
local purchaseSucceeded = false

--/ LOCAL HELPER FUNCTIONS /--
local function GetCachedTool(toolId: string)
	if typeof(cachedTools) ~= "table" then
		return nil
	end

	for _, toolData in cachedTools do
		if toolData.Id == toolId then
			return toolData
		end
	end

	return nil
end

local function ClearCart()
	table.clear(cart)
	ToolShopUI:UpdateTotal(0)
end

local function RefreshTotal()
	local total = 0
	for toolId, count in cart do
		local toolData = GetCachedTool(toolId)
		if toolData and typeof(toolData.Price) == "number" then
			total += toolData.Price * count
		end
	end

	ToolShopUI:UpdateTotal(total)
end

local function SetCartCount(toolId: string, count: number)
	if count <= 0 then
		cart[toolId] = nil
		ToolShopUI:SetQuantity(toolId, 0)
		ToolShopUI:SetInCart(toolId, false)
	else
	cart[toolId] = count
	ToolShopUI:SetQuantity(toolId, count)
	ToolShopUI:SetInCart(toolId, true)
	end

	RefreshTotal()
end

local function AddTool(toolId: string)
	local toolData = GetCachedTool(toolId)
	if not toolData then
		return
	end

	if toolData.Permanent and toolData.Owned then
		return
	end

	local count = cart[toolId] or 0
	if toolData.Permanent then
		SetCartCount(toolId, if count > 0 then 0 else 1)
		return
	end

	SetCartCount(toolId, math.min(count + 1, MAX_COUNT))
end

local function RemoveOne(toolId: string)
	local count = cart[toolId]
	if not count then
		return
	end

	SetCartCount(toolId, count - 1)
end

local function HasCartItems(): boolean
	return next(cart) ~= nil
end

local function ApplyCatalog(tools)
	if typeof(tools) ~= "table" then
		return
	end

	cachedTools = tools
	checkoutPending = false
	if purchaseSucceeded then
		purchaseSucceeded = false
		ClearCart()
	end

	ToolShopUI:BuildToolUI(cachedTools)
	RefreshTotal()
end

local function RequestCatalog()
	FetchToolData:FireServer()
	if cachedTools then
		ToolShopUI:BuildToolUI(cachedTools)
	end
	RefreshTotal()
end

local function CopyCart()
	local payload = {}
	for toolId, count in cart do
		payload[toolId] = count
	end

	return payload
end

local function Checkout()
	if checkoutPending or not HasCartItems() then
		return
	end

	checkoutPending = true
	PurchaseTools:FireServer(CopyCart())
end

--/ CORE /--
ToolShopUI.OnToolPressed = AddTool
ToolShopUI.OnQuantityPressed = RemoveOne

FetchToolData.OnClientEvent:Connect(ApplyCatalog)

PurchaseTools.OnClientEvent:Connect(function(success: boolean)
	if success then
		purchaseSucceeded = true
		return
	end

	checkoutPending = false
end)

CheckoutButton.MouseButton1Click:Connect(Checkout)

ToolShop:GetPropertyChangedSignal("Enabled"):Connect(function()
	if ToolShop.Enabled then
		RequestCatalog()
		return
	end

	ClearCart()
	checkoutPending = false
	purchaseSucceeded = false
	ToolShopUI:BuildToolUI(cachedTools or {})
end)

RequestCatalog()
