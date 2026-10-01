--/ SHORTCUT VARIABLES /--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local EconomyShared = ReplicatedStorage:WaitForChild("EconomyShared")
local Events = EconomyShared:WaitForChild("Events")

local JobTemplate = script:WaitForChild("JobTemplate")
local Container = script.Parent
local ScrollFrame = Container:WaitForChild("ScrollFrame")

local ACTIVE_COLOR = Color3.fromRGB(0, 170, 0)
local IDLE_COLOR = Color3.fromRGB(144, 144, 144)
local COLOR_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local activeJobs = {}
local colorTweens = {}

--/ HELPER FUNCTIONS /--
local function CreateNewTemplate(data: {[string]: any})
	local clone = JobTemplate:Clone()
	clone.Parent = ScrollFrame
	clone.Name = data.Id

	return clone
end

local function GetJobFrame(id)
	return ScrollFrame:FindFirstChild(id)
end

local function Round(number: number, decimalPlace: number): number
	return math.round(number * 10 ^ decimalPlace) / 10 ^ decimalPlace
end

local function TweenJobColor(jobFrame, progressActive: boolean)
	local targetColor = if progressActive then ACTIVE_COLOR else IDLE_COLOR
	local existingTween = colorTweens[jobFrame]
	if existingTween then
		existingTween:Cancel()
	end

	local tween = TweenService:Create(jobFrame, COLOR_TWEEN_INFO, {
		BackgroundColor3 = targetColor,
	})
	colorTweens[jobFrame] = tween
	tween:Play()
end

local function CleanupJob(id)
	activeJobs[id] = nil
	local jobFrame = GetJobFrame(id)
	if not jobFrame then
		return
	end

	if colorTweens[jobFrame] then
		colorTweens[jobFrame]:Cancel()
		colorTweens[jobFrame] = nil
	end
	jobFrame:Destroy()
end

local function UpdateJob(data: {[string]: any})
	local jobFrame = GetJobFrame(data.Id)
	if not jobFrame then
		return
	end

	local divisor = data.ProgressDivisor or 1
	jobFrame.JobText.Text = `- {data.JobDescription}: {Round(data.Progress / divisor, 2)}/{Round(data.FinishedProgress / divisor, 2)}`

	local lastData = activeJobs[data.Id]
	if not lastData or lastData.ProgressActive ~= data.ProgressActive then
		TweenJobColor(jobFrame, data.ProgressActive)
	end
end

--/ CORE /--
local UpdateEvent = Events:WaitForChild("UpdateJobUI")
UpdateEvent.OnClientEvent:Connect(function(jobData)
	if not jobData then
		return
	end

	if typeof(jobData) == "number" then
		CleanupJob(jobData)
		return
	end

	if jobData.Id ~= nil and jobData.JobDescription == nil and jobData.Progress == nil then
		CleanupJob(jobData.Id)
		return
	end

	if jobData.Completed then
		CleanupJob(jobData.Id)
		return
	end

	if not activeJobs[jobData.Id] then
		CreateNewTemplate(jobData)
		UpdateJob(jobData)
	else
		UpdateJob(jobData)
	end

	activeJobs[jobData.Id] = jobData
end)
