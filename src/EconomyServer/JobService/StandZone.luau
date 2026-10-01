local StandZone = {}
StandZone.LoopedJob = true

--/ SHORTCUT VARIABLES /--
local Workspace = game:GetService("Workspace")

local JobService = require(script.Parent)

--/ LOCAL HELPER FUNCTIONS /--
local function GetLocationName(extraData: any): string?
    if typeof(extraData) == "string" then
        return extraData
    end

    if typeof(extraData) ~= "table" then
        return nil
    end

    return extraData.Location or extraData.location
end

local function GetZonePart(job): BasePart?
    local locationName = GetLocationName(job.ExtraData)
    if not locationName then
        warn("[StandZone] Missing location in ExtraData")
        return nil
    end

    local folder = Workspace:FindFirstChild("JobLocations")
    if not folder then
        warn("[StandZone] Workspace.JobLocations not found")
        return nil
    end

    local zone = folder:FindFirstChild(locationName)
    if not zone or not zone:IsA("BasePart") then
        warn("[StandZone] Job location part not found: " .. locationName)
        return nil
    end

    return zone
end

local function IsPlayerInZone(player: Player, zone: BasePart): boolean
    return JobService.IsPlayerInCachedZone(player, zone)
end

--/ JOB METHODS /--
function StandZone.StartJob(job)
    job._lastTick = os.clock()
    job._zonePart = GetZonePart(job)
end

function StandZone.CheckProgress(job): number
    local zone = job._zonePart
    if not zone or not job.Owner then
        job.ProgressActive = false
        return job.Progress
    end

    local now = os.clock()
    local lastTick = job._lastTick or now
    job._lastTick = now

    local inZone = IsPlayerInZone(job.Owner, zone)
    job.ProgressActive = inZone
    if not inZone then
        return job.Progress
    end

    return job.Progress + (now - lastTick)
end

function StandZone.CleanupJob(_job)
end

return StandZone
