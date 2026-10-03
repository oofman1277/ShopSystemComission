local Haul = {}
Haul.LoopedJob = false

local savedWalkSpeeds = {}

--/ SHORTCUT VARIABLES /--
local Workspace = game:GetService("Workspace")

--/ LOCAL HELPER FUNCTIONS /--
local function DisconnectConnections(connections)
    if not connections then
        return
    end

    for _, connection in connections do
        connection:Disconnect()
    end
end

local function GetToolName(extraData: any): string?
    if typeof(extraData) ~= "table" then
        return nil
    end

    return extraData.ToolName or extraData.toolName or extraData.Tool
end

local function GetWalkSpeed(extraData: any): number?
    if typeof(extraData) ~= "table" then
        return nil
    end

    return extraData.WalkSpeed or extraData.walkSpeed
end

local function IsStrictCarrying(extraData: any): boolean
    if typeof(extraData) ~= "table" then
        return false
    end

    return extraData.StrictCarrying == true or extraData.strictCarrying == true
end

local function GetZonePart(value: any): BasePart?
    if typeof(value) == "Instance" and value:IsA("BasePart") then
        return value
    end

    if typeof(value) ~= "string" then
        return nil
    end

    local folder = Workspace:FindFirstChild("JobLocations")
    if not folder then
        return nil
    end

    local zone = folder:FindFirstChild(value)
    if not zone or not zone:IsA("BasePart") then
        return nil
    end

    return zone
end

local function GetEndPart(extraData: any): BasePart?
    if typeof(extraData) ~= "table" then
        return nil
    end

    return GetZonePart(extraData.PartB or extraData.partB or extraData.End)
end

local function GetHaulPrompt(part: BasePart): ProximityPrompt?
    local prompt = part:FindFirstChild("HaulJob")
    if prompt and prompt:IsA("ProximityPrompt") then
        return prompt
    end

    return nil
end

local function RememberWalkSpeed(job, humanoid: Humanoid, haulSpeed: number?)
    local saved = savedWalkSpeeds[job.Owner]
    if saved == nil then
        saved = humanoid.WalkSpeed
        if haulSpeed and saved == haulSpeed then
            saved = 16
        end
        savedWalkSpeeds[job.Owner] = saved
    end

    job._originalWalkSpeed = saved
end

local function RestoreWalkSpeed(job)
    local humanoid = job._humanoid
    local saved = job.Owner and savedWalkSpeeds[job.Owner]
    if not humanoid or not saved then
        return
    end

    humanoid.WalkSpeed = saved
    savedWalkSpeeds[job.Owner] = nil
end

local function IsToolEquipped(job): boolean
    local tool = job._haulTool
    local character = job.Owner and job.Owner.Character
    if not tool or not character then
        return false
    end

    return tool.Parent == character
end

local function CancelIfStrictCarrying(job, extraData)
    if job.Completed then
        return
    end
    if not IsStrictCarrying(extraData) then
        return
    end

    job:Cancel()
end

local function ConnectTool(job, tool: Tool, humanoid: Humanoid)
    local extraData = job.ExtraData
    local haulSpeed = GetWalkSpeed(extraData)

    table.insert(job._connections, tool.Equipped:Connect(function()
        if haulSpeed then
            humanoid.WalkSpeed = haulSpeed
        end
        job.ProgressActive = true
    end))

    table.insert(job._connections, tool.Unequipped:Connect(function()
        RestoreWalkSpeed(job)
        if IsStrictCarrying(extraData) then
            if job._haulTool then
                job._haulTool:Destroy()
                job._haulTool = nil
            end
            CancelIfStrictCarrying(job, extraData)
            return
        end

        local toolParent = job._haulTool and job._haulTool.Parent
        job.ProgressActive = toolParent == job.Owner.Backpack or toolParent == job.Owner.Character
    end))

    table.insert(job._connections, tool.Destroying:Connect(function()
        job._haulTool = nil
        RestoreWalkSpeed(job)
        CancelIfStrictCarrying(job, extraData)
    end))

    if tool.Parent == humanoid.Parent and haulSpeed then
        humanoid.WalkSpeed = haulSpeed
    end
end

local function ConnectEndPrompt(job, prompt: ProximityPrompt)
    table.insert(job._connections, prompt.Triggered:Connect(function(player: Player)
        if player ~= job.Owner then
            return
        end

        if job.Completed then
            return
        end

        if not IsToolEquipped(job) then
            return
        end

        job.Progress = job.FinishedProgress
        job:Finish()
    end))
end

--/ JOB METHODS /--
function Haul.StartJob(job)
    local extraData = job.ExtraData
    local toolName = GetToolName(extraData)
    if not toolName then
        warn("[Haul] Missing ToolName in ExtraData")
        return
    end

    local template = script:FindFirstChild(toolName)
    if not template or not template:IsA("Tool") then
        warn("[Haul] Tool template not found under Haul module: " .. toolName)
        return
    end

    local character = job.Owner.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[Haul] Player has no character/humanoid")
        return
    end

    local endPart = GetEndPart(extraData)
    local prompt = endPart and GetHaulPrompt(endPart)
    if not prompt then
        warn("[Haul] Part B HaulJob proximity prompt not found")
        return
    end

    job._connections = {}
    job._humanoid = humanoid
    RememberWalkSpeed(job, humanoid, GetWalkSpeed(extraData))

    local tool = template:Clone()
    job._haulTool = tool
    tool.Parent = job.Owner.Backpack
    humanoid:EquipTool(tool)

    ConnectTool(job, tool, humanoid)
    ConnectEndPrompt(job, prompt)
    job.ProgressActive = true
end

function Haul.CheckProgress(job): number
    if job.Completed then
        return job.FinishedProgress
    end

    return job.Progress
end

function Haul.CleanupJob(job)
    DisconnectConnections(job._connections)
    job._connections = nil

    RestoreWalkSpeed(job)
    job._humanoid = nil
    job._originalWalkSpeed = nil

    if job._haulTool then
        job._haulTool:Destroy()
        job._haulTool = nil
    end

    job.ProgressActive = false
end

return Haul
