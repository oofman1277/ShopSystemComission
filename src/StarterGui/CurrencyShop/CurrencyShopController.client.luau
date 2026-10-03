--/ SHORTCUT VARIABLES /--
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyShared = ReplicatedStorage:WaitForChild("EconomyShared")
local Events = EconomyShared:WaitForChild("Events")
local PurchaseCurrency = Events:WaitForChild("PurchaseCurrency")

local currencyShop = script.Parent.Parent
local BackImage = currencyShop:WaitForChild("Back")
local BackButton = BackImage:WaitForChild("Button")

local HOVER_SCALE = 1.075
local REST_SCALE = 1
local HOVER_IMAGE_COLOR = Color3.fromRGB(195, 195, 195)
local DEFAULT_IMAGE_COLOR = Color3.fromRGB(40, 40, 40)
local HOVER_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local activeTweens = {}

--/ LOCAL HELPER FUNCTIONS /--
local function GetProductId(button: Instance): number?
	local productId = button:GetAttribute("DevProductId")
	if typeof(productId) ~= "number" then
		return nil
	end

	return productId
end

local function PlayTween(instance: Instance, goal)
	local existingTween = activeTweens[instance]
	if existingTween then
		existingTween:Cancel()
	end

	local tween = TweenService:Create(instance, HOVER_TWEEN_INFO, goal)
	activeTweens[instance] = tween
	tween:Play()
end

local function BindHoverScale(frame: GuiObject)
	local uiScale = frame:FindFirstChild("UIScale")
	if not uiScale or not uiScale:IsA("UIScale") then
		return
	end

	frame.MouseEnter:Connect(function()
		PlayTween(uiScale, { Scale = HOVER_SCALE })
	end)

	frame.MouseLeave:Connect(function()
		PlayTween(uiScale, { Scale = REST_SCALE })
	end)
end

local function BindBackHover()
	BackImage.MouseEnter:Connect(function()
		PlayTween(BackImage, { ImageColor3 = HOVER_IMAGE_COLOR })
	end)

	BackImage.MouseLeave:Connect(function()
		PlayTween(BackImage, { ImageColor3 = DEFAULT_IMAGE_COLOR })
	end)
end

local function ConnectButton(button: TextButton)
	local productId = GetProductId(button)
	if not productId then
		print("No id")
		return
	end

	button.MouseButton1Click:Connect(function()
		print("Activated")
		PurchaseCurrency:FireServer(productId)
	end)

	local frame = button.Parent
	if frame and frame:IsA("GuiObject") then
		BindHoverScale(frame)
	end
end

--/ CORE /--
BindBackHover()

BackButton.MouseButton1Click:Connect(function()
	currencyShop.Enabled = false
end)

for _, descendant in currencyShop:GetDescendants() do
	if descendant:IsA("TextButton") then
		ConnectButton(descendant)
	end
end
