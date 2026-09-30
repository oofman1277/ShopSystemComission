local JobService = {}
JobService.__index = JobService

JobService.ActiveJobs = {}
JobService.JobId = 0

--/ SHORTCUT VARIABLES /--
local ServerScriptService = game:GetService("ServerScriptService")
local EconomyServer = ServerScriptService:WaitForChild("EconomyServer")
local EconomyManager = require(EconomyServer:WaitForChild("EconomyManager"))

--/ TYPES /--
type Job = {
    Owner: Player,
    Type: string,
    Progress: number,
    Payout: number,
    ExtraData: any,

    FinishedProgress: number, -- Progress when the job is finished
    Completed: boolean,
    Id: number,
}

--/ LOCAL HELPER FUNCTIONS /--
local function GetJobModule(type: string)
    local module = script:FindFirstChild(type)
    if not module then
        warn("[JobService] Job module not found: " .. type)
        return nil
    end

    return require(module)
end

--/ CORE METHODS /--
function JobService.NewJob(player: Player, type: string, payout: number, progress: number, finishedProgress: number, extraData: any)
    local job = {
        Owner = player,
        Type = type,
        Progress = progress,
        Payout = payout,
        ExtraData = extraData,

        FinishedProgress = finishedProgress,
        Completed = false,
        Id = JobService.JobId,
    }

    if not JobService.ActiveJobs[player] then
        JobService.ActiveJobs[player] = {}
    end

    JobService.ActiveJobs[player][job.Id] = job
    setmetatable(job, JobService)
    JobService.JobId += 1
    return job
end

function JobService:Start()
    if not self.Owner then return end
    if self.Completed then return end

    local jobModule = GetJobModule(self.Type)
    if not jobModule then return end

    jobModule.StartJob(self)
end

function JobService:CheckProgress()
    if not self.Owner then return end

    local jobModule = GetJobModule(self.Type)
    if not jobModule then return end

    self.Progress = jobModule.CheckProgress(self)
    if self.Progress >= self.FinishedProgress then
        self:Finish()
    end
end

function JobService:Finish()
    if not self.Owner then return end
    if self.Progress < self.FinishedProgress then return end

    local jobModule = GetJobModule(self.Type)
    if not jobModule then return end

    local success = EconomyManager:AddCurrency(self.Owner, self.Payout)
    if not success then
        warn("[JobService] Failed to add currency to player: " .. self.Owner.Name)
        return
    end

    jobModule.CleanupJob(self)
    JobService.ActiveJobs[self.Owner][self.Id] = nil
    self.Completed = true
end

return JobService