local JobOptions = {}

--/ SHORTCUT VARIABLES /--
local Workspace = game:GetService("Workspace")
local JobService = require(script.Parent)

local NPC_INIT_YIELD_THRESHOLD = 200
local NPC_INIT_YIELD_EVERY = 3

--/ JOB GROUPS /--
JobOptions.Mail = {
    {
        Type = "Haul",
        Payout = 2,
        Progress = 0,
        FinishedProgress = 1,
        JobDescription = "Haul the crate",
        ExtraData = {
            PartA = "HaulJobStart",
            PartB = "HaulJobEnd",
            ToolName = "Crate",
            WalkSpeed = 8,
            StrictCarrying = true,
        },
    },
}

JobOptions.Standing = {
    {
        Type = "StandZone",
        Payout = 0.6,
        Progress = 0,
        FinishedProgress = 300,
        JobDescription = "Stand in Standzone",
        ProgressDivisor = 60,
        ExtraData = {
            Location = "TestLocation",
        },
    },
}

JobOptions.ToolWork = {
    {
        Type = "ToolZone",
        Payout = 2,
        Progress = 0,
        FinishedProgress = 15,
        JobDescription = "Hold JobShovel in TestLocation",
        ExtraData = {
            Location = "TestLocation",
            Tool = "JobShovel",
        },
    },
}

JobOptions.Kills = {
    {
        Type = "GetKills",
        Payout = 2,
        Progress = 0,
        FinishedProgress = 2,
        JobDescription = "Get 2 kills",
        ExtraData = {},
    },
}

--/ LOCAL HELPER FUNCTIONS /--
local function ResolveExtraData(extraData: any): any
    if typeof(extraData) ~= "table" then
        return extraData
    end

    local resolved = table.clone(extraData)
    if typeof(resolved.PartA) == "string" then
        resolved.PartA = Workspace:FindFirstChild(resolved.PartA)
    end
    if typeof(resolved.PartB) == "string" then
        resolved.PartB = Workspace:FindFirstChild(resolved.PartB)
    end

    return resolved
end

local function ConnectJobProximity(prompt: ProximityPrompt)
    local groupName = prompt:GetAttribute("JobGroup")
    if typeof(groupName) ~= "string" then
        warn("[JobOptions] JobProximity is missing JobGroup")
        return
    end

    prompt.Triggered:Connect(function(player: Player)
        local group = JobOptions[groupName]
        if typeof(group) ~= "table" or #group == 0 then
            warn("[JobOptions] Invalid JobGroup:", groupName)
            return
        end

        JobOptions.AssignRandom(player, group)
    end)
end

--/ CORE /--
function JobOptions.Assign(player: Player, option: any)
    if not option then
        warn("[JobOptions] Missing job option")
        return nil
    end

    local job = JobService.NewJob({
        Owner = player,
        Type = option.Type,
        Payout = option.Payout,
        Progress = option.Progress,
        FinishedProgress = option.FinishedProgress,
        JobDescription = option.JobDescription,
        ProgressDivisor = option.ProgressDivisor,
    }, ResolveExtraData(option.ExtraData))

    job:Start()
    return job
end

function JobOptions.AssignRandom(player: Player, group: { any })
    if not group or #group == 0 then
        warn("[JobOptions] Empty job group")
        return nil
    end

    return JobOptions.Assign(player, group[math.random(1, #group)])
end

function JobOptions.InitializeJobNPCs()
    local descendants = Workspace:WaitForChild("JobNPCs"):GetDescendants()
    local shouldYield = #descendants > NPC_INIT_YIELD_THRESHOLD

    for index, descendant in descendants do
        if shouldYield and index % NPC_INIT_YIELD_EVERY == 0 then
            task.wait()
        end

        if descendant.Name ~= "JobProximity" then
            continue
        end

        if not descendant:IsA("ProximityPrompt") or not descendant:GetAttribute("JobGroup") then
            warn(`[JobOptions] {descendant:GetFullName()} either isn't a ProximityPrompt, or is missing the JobGroup attribute.`)
            continue
        end

        ConnectJobProximity(descendant)
    end
end

return JobOptions
