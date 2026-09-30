local StandZone = {}

--/ SHORTCUT VARIABLES /--
local Workspace = game:GetService("Workspace")

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

--/ JOB METHODS /--
function StandZone.StartJob(job)
    job._lastTick = os.clock()

    while job.Completed == false do
        local progress = StandZone.CheckProgress(job)
        job.Progress += progress
        task.wait(1)
        print(progress)

        if job.Progress >= job.FinishedProgress then
            job:Finish()
            break
        end
    end
end

function StandZone.CheckProgress(job): number
    local zone = GetZonePart(job)
    if not zone or not job.Owner then
        return job.Progress
    end

    local now = os.clock()
    local lastTick = job._lastTick or now
    job._lastTick = now

    if not IsPlayerInZone(job.Owner, zone) then
        return job.Progress
    end

    return job.Progress + (now - lastTick)
end

function StandZone.CleanupJob(_job)
end

return StandZone
