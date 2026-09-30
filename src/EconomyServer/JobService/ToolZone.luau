local ToolZone = {}

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

local function GetLocationName(extraData: any): string?
    if typeof(extraData) ~= "table" then
        return nil
    end

    return extraData.Location or extraData.location
end

local function GetToolName(extraData: any): string?
    if typeof(extraData) ~= "table" then
        return nil
    end

    return extraData.Tool or extraData.tool or extraData.ToolName
end

local function GetZonePart(job): BasePart?
    local locationName = GetLocationName(job.ExtraData)
    if not locationName then
        warn("[ToolZone] Missing location in ExtraData")
        return nil
    end

    local folder = Workspace:FindFirstChild("JobLocations")
    if not folder then
        warn("[ToolZone] Workspace.JobLocations not found")
        return nil
    end

    local zone = folder:FindFirstChild(locationName)
    if not zone or not zone:IsA("BasePart") then
        warn("[ToolZone] Job location part not found: " .. locationName)
        return nil
    end

    return zone
end

local function HasEquippedTool(character: Model, toolName: string): boolean
    for _, child in character:GetChildren() do
        if child:IsA("Tool") and child.Name == toolName then
            return true
        end
    end

    return false
end

local function IsPlayerInZone(player: Player, zone: BasePart): boolean
    local character = player.Character
    if not character then
        return false
    end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Include
    overlapParams.FilterDescendantsInstances = { character }

    local touching = Workspace:GetPartsInPart(zone, overlapParams)
    return #touching > 0
end

local function BindCharacter(job, character: Model)
    DisconnectConnections(job._characterConnections)
    job._characterConnections = {}

    local toolName = GetToolName(job.ExtraData)
    if not toolName then
        job._toolEquipped = false
        return
    end

    job._toolEquipped = HasEquippedTool(character, toolName)

    table.insert(job._characterConnections, character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child.Name == toolName then
            job._toolEquipped = true
        end
    end))

    table.insert(job._characterConnections, character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and child.Name == toolName then
            job._toolEquipped = HasEquippedTool(character, toolName)
        end
    end))
end

--/ JOB METHODS /--
function ToolZone.StartJob(job)
    job._lastTick = os.clock()
    job._toolEquipped = false
    job._connections = {}
    job._characterConnections = {}

    local toolName = GetToolName(job.ExtraData)
    if not toolName then
        warn("[ToolZone] Missing tool name in ExtraData")
        return
    end

    local player = job.Owner
    table.insert(job._connections, player.CharacterAdded:Connect(function(character)
        BindCharacter(job, character)
    end))

    if player.Character then
        BindCharacter(job, player.Character)
    end
end

function ToolZone.CheckProgress(job): number
    local zone = GetZonePart(job)
    if not zone or not job.Owner then
        return job.Progress
    end

    local now = os.clock()
    local lastTick = job._lastTick or now
    job._lastTick = now

    if not job._toolEquipped or not IsPlayerInZone(job.Owner, zone) then
        return job.Progress
    end

    return job.Progress + (now - lastTick)
end

function ToolZone.CleanupJob(job)
    DisconnectConnections(job._connections)
    DisconnectConnections(job._characterConnections)
    job._connections = nil
    job._characterConnections = nil
    job._toolEquipped = false
end

return ToolZone
