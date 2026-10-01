local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyShared = ReplicatedStorage:WaitForChild("EconomyShared")
local SharedModules = EconomyShared:WaitForChild("Modules")
local Constants = require(SharedModules:WaitForChild("Constants"))

local amountText = script.Parent:WaitForChild("Amount")
local changeAmountTemplate = script.Parent:WaitForChild("ChangeAmount")

local function FormatMoney(number: number): string
	return string.format("%.2f", number)
end

local function GetOrCreateUIScale(label: TextLabel): UIScale
	local uiScale = label:FindFirstChildOfClass("UIScale")
	if uiScale then
		return uiScale
	end

	uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = label
	return uiScale
end

local function MoneyIncrementAnimation(startNum: number, endNum: number)
	local AnimationLength = 1
	local EasingStyle = Enum.EasingStyle.Circular
	local tempNumberValue = Instance.new("NumberValue")
	tempNumberValue.Value = startNum

	local tween = TweenService:Create(tempNumberValue, TweenInfo.new(AnimationLength, EasingStyle), { Value = endNum })
	tween:Play()

	tempNumberValue:GetPropertyChangedSignal("Value"):Connect(function()
		amountText.Text = "$ " .. FormatMoney(tempNumberValue.Value)
	end)

	tween.Completed:Connect(function()
		tempNumberValue:Destroy()
	end)
end

local function SizeIncreaseAnimation()
	local uiScale = GetOrCreateUIScale(amountText)
	local shakeInfo = TweenInfo.new(0.07, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local settleInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),{ Scale = 1.2 })
	tween:Play()

	task.spawn(function()
		for _, rotation in { 10, -10, 7, -7, 4, -4, 0 } do
			if not amountText.Parent then
				return
			end

			local shakeTween = TweenService:Create(amountText, shakeInfo, { Rotation = rotation })
			shakeTween:Play()
			shakeTween.Completed:Wait()
		end
	end)
	task.delay(1, function()
		if not amountText.Parent then
			return
		end
		TweenService:Create(uiScale, settleInfo, { Scale = 1 }):Play()
		TweenService:Create(amountText, settleInfo, { Rotation = 0 }):Play()
	end)
end

local function PlayColorAnimation(lastSum: number, nowSum: number)
	local color = Color3.fromRGB(100, 255, 100)
	if lastSum and nowSum < lastSum then
		color = Color3.fromRGB(255, 75, 75)
	end
	
	local colorTweenIn = TweenService:Create(amountText, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = Color3.fromRGB(100, 255, 100)})
	local colorTweenOut = TweenService:Create(amountText, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = Color3.fromRGB(255, 255, 255)})
	colorTweenIn:Play()
	colorTweenIn.Completed:Once(function()
		colorTweenOut:Play()
	end)
end

local function PlayChangeAmount(difference: number)
	if difference == 0 then
		return
	end

	local label = changeAmountTemplate:Clone()
	label.Visible = true
	label.TextTransparency = 0

	if difference > 0 then
		label.Text = "+ " .. FormatMoney(difference)
		label.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		label.Text = "- " .. FormatMoney(math.abs(difference))
		label.TextColor3 = Color3.fromRGB(255, 75, 75)
	end

	label.Parent = changeAmountTemplate.Parent

	local moveInfo = TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, moveInfo, {
		Position = label.Position + UDim2.fromOffset(0, -50),
	}):Play()

	local fadeTween = TweenService:Create(label, moveInfo, {
		TextTransparency = 1,
	})
	fadeTween:Play()
	fadeTween.Completed:Once(function()
		label:Destroy()
	end)
end

local function PlaySound()
	local sound = script:WaitForChild("MoneySound"):Clone()
	sound.Parent = Player
	sound.PlayOnRemove = true
	sound:Destroy()
end

local CurrencyAttribute = Player:GetAttribute(Constants.CURRENCY_ATTRIBUTE_NAME)
local lastSum = 0
if CurrencyAttribute ~= nil then
	amountText.Text = "$ " .. FormatMoney(CurrencyAttribute)
	lastSum = CurrencyAttribute
end

Player:GetAttributeChangedSignal(Constants.CURRENCY_ATTRIBUTE_NAME):Connect(function()
	CurrencyAttribute = Player:GetAttribute(Constants.CURRENCY_ATTRIBUTE_NAME)
	if CurrencyAttribute == nil then
		return
	end

	MoneyIncrementAnimation(lastSum, CurrencyAttribute)
	SizeIncreaseAnimation()
	PlaySound()
	PlayColorAnimation(lastSum, CurrencyAttribute)
	PlayChangeAmount(CurrencyAttribute - lastSum)
	lastSum = CurrencyAttribute
end)