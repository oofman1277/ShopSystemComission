local ToolShopUI = {}
ToolShopUI.OnToolPressed = nil
ToolShopUI.OnQuantityPressed = nil

--/ SHORTCUT VARIABLES /--
local TweenService = game:GetService("TweenService")

local scriptsFolder = script.Parent
local toolShop = scriptsFolder.Parent

local PermanentTemplate = scriptsFolder:WaitForChild("PermanentTemplate")
local ReplenishableTemplate = scriptsFolder:WaitForChild("ReplenishableTemplate")

local Content = toolShop:WaitForChild("Container"):WaitForChild("Content")
local PermanentContainer = Content:WaitForChild("PermanentContainer")
local ReplenishableContainer = Content:WaitForChild("ReplenishableContainer")
local TotalLabel = toolShop:WaitForChild("TotalTab"):WaitForChild("Total")
local BackButton = toolShop:WaitForChild("Back"):WaitForChild("Button")
local BackImage = toolShop:WaitForChild("Back")
local CheckoutImage = toolShop:WaitForChild("Checkout")

local HOVER_SCALE = 1.075
local REST_SCALE = 1
local CART_COLOR = Color3.fromRGB(0, 170, 0)
local DEFAULT_FRAME_COLOR = Color3.fromRGB(111, 111, 83)
local HOVER_IMAGE_COLOR = Color3.fromRGB(195, 195, 195)
local DEFAULT_IMAGE_COLOR = Color3.fromRGB(40, 40, 40)
local HOVER_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local COLOR_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local activeTweens = {}

--/ LOCAL HELPER FUNCTIONS /--
local function FormatPrice(price: number): string
	return string.format("%.2f", price)
end

local function FormatTotal(amount: number): string
	return "$" .. string.format("%.2f", amount)
end

local function GetChild(parent: Instance, name: string): Instance?
	return parent:FindFirstChild(name, true)
end

local function PlayTween(instance: Instance, tweenInfo: TweenInfo, goal)
	local existingTween = activeTweens[instance]
	if existingTween then
		existingTween:Cancel()
	end

	local tween = TweenService:Create(instance, tweenInfo, goal)
	activeTweens[instance] = tween
	tween:Play()
end

local function TweenScale(uiScale: UIScale, scale: number)
	PlayTween(uiScale, HOVER_TWEEN_INFO, { Scale = scale })
end

local function TweenBackground(frame: GuiObject, inCart: boolean)
	local color = if inCart then CART_COLOR else DEFAULT_FRAME_COLOR
	PlayTween(frame, COLOR_TWEEN_INFO, { BackgroundColor3 = color })
end

local function TweenImageColor(image: ImageLabel, hovering: boolean)
	local color = if hovering then HOVER_IMAGE_COLOR else DEFAULT_IMAGE_COLOR
	PlayTween(image, HOVER_TWEEN_INFO, { ImageColor3 = color })
end

local function BindHoverScale(frame: GuiObject)
	local uiScale = frame:FindFirstChild("UIScale")
	if not uiScale or not uiScale:IsA("UIScale") then
		return
	end

	frame.MouseEnter:Connect(function()
		TweenScale(uiScale, HOVER_SCALE)
	end)

	frame.MouseLeave:Connect(function()
		TweenScale(uiScale, REST_SCALE)
	end)
end

local function BindImageHover(image: ImageLabel)
	image.MouseEnter:Connect(function()
		TweenImageColor(image, true)
	end)

	image.MouseLeave:Connect(function()
		TweenImageColor(image, false)
	end)
end

local function ClearContainer(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			activeTweens[child] = nil
			child:Destroy()
		end
	end
end

local function ApplyToolData(frame: Instance, toolData: { [string]: any })
	local toolName = GetChild(frame, "ToolName")
	if toolName and toolName:IsA("TextLabel") then
		toolName.Text = toolData.Name or toolData.ToolName or ""
	end

	local price = GetChild(frame, "Price")
	if price and price:IsA("TextLabel") then
		if toolData.Permanent and toolData.Owned then
			price.Text = "Owned"
		else
			price.Text = FormatPrice(toolData.Price or 0)
		end
	end

	local icon = GetChild(frame, "Icon")
	if icon and icon:IsA("ImageLabel") then
		local iconId = toolData.IconId
		if typeof(iconId) == "number" then
			icon.Image = `rbxassetid://{iconId}`
		else
			icon.Image = iconId or ""
		end
	end

	local quantity = GetChild(frame, "Quantity")
	if quantity and quantity:IsA("TextButton") then
		quantity.Text = "0"
	end
end

local function CreateToolFrame(toolData: { [string]: any }): Instance?
	local isPermanent = toolData.Permanent == true
	local template = if isPermanent then PermanentTemplate else ReplenishableTemplate
	local container = if isPermanent then PermanentContainer else ReplenishableContainer

	local clone = template:Clone()
	local toolId = toolData.Id
	clone.Name = toolId or toolData.Name or template.Name
	clone:SetAttribute("Id", toolId)
	clone:SetAttribute("Owned", toolData.Owned == true)
	ApplyToolData(clone, toolData)
	clone.Visible = true
	clone.Parent = container

	if clone:IsA("GuiObject") then
		BindHoverScale(clone)
	end

	local purchaseButton = GetChild(clone, "Button")
	if purchaseButton and purchaseButton:IsA("GuiButton") and toolId then
		purchaseButton.MouseButton1Click:Connect(function()
			if ToolShopUI.OnToolPressed then
				ToolShopUI.OnToolPressed(toolId)
			end
		end)
	end

	local quantity = GetChild(clone, "Quantity")
	if quantity and quantity:IsA("GuiButton") and toolId then
		quantity.MouseButton1Click:Connect(function()
			if ToolShopUI.OnQuantityPressed then
				ToolShopUI.OnQuantityPressed(toolId)
			end
		end)
	end

	return clone
end

--/ CORE /--
function ToolShopUI:BuildToolUI(tools: { { [string]: any } })
	if typeof(tools) ~= "table" then
		return
	end

	ClearContainer(PermanentContainer)
	ClearContainer(ReplenishableContainer)

	for _, toolData in tools do
		CreateToolFrame(toolData)
	end
end

function ToolShopUI:SetQuantity(toolId: string, amount: number)
	local frame = PermanentContainer:FindFirstChild(toolId) or ReplenishableContainer:FindFirstChild(toolId)
	if not frame then
		return
	end

	local quantity = GetChild(frame, "Quantity")
	if quantity and quantity:IsA("TextButton") then
		quantity.Text = tostring(amount)
	end

	if frame:IsA("GuiObject") then
		TweenBackground(frame, amount > 0)
	end
end

function ToolShopUI:SetInCart(toolId: string, inCart: boolean)
	local frame = PermanentContainer:FindFirstChild(toolId) or ReplenishableContainer:FindFirstChild(toolId)
	if not frame or not frame:IsA("GuiObject") then
		return
	end

	TweenBackground(frame, inCart)
end

function ToolShopUI:UpdateTotal(amount: number)
	TotalLabel.Text = FormatTotal(amount or 0)
end

function ToolShopUI:SetShopVisible(isVisible: boolean)
	toolShop.Enabled = isVisible
end

BindImageHover(BackImage)
BindImageHover(CheckoutImage)

BackButton.MouseButton1Click:Connect(function()
	ToolShopUI:SetShopVisible(false)
end)

ToolShopUI:UpdateTotal(0)

return ToolShopUI
