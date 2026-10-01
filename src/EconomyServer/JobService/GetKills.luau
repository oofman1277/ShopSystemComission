local GetKills = {}
GetKills.LoopedJob = true

--/ JOB METHODS /--
function GetKills.StartJob(job)
    local kills = job.Owner:GetAttribute("Kills")
    job._startKills = if typeof(kills) == "number" then kills else 0
    job.ProgressActive = true
end

function GetKills.CheckProgress(job): number
    local kills = job.Owner:GetAttribute("Kills")
    if typeof(kills) ~= "number" then
        kills = 0
    end

    local killsGained = kills - (job._startKills or 0)
    if killsGained < 0 then
        return 0
    end

    return killsGained
end

function GetKills.CleanupJob(job)
    job.ProgressActive = false
end

return GetKills
