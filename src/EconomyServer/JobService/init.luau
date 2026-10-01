local JobService = {}
JobService.__index = JobService

JobService.ActiveJobs = {}
JobService.JobId = 0
JobService.GetPartsCache = {}

--/ SHORTCUT VARIABLES /--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local EconomyServer = ServerScriptService:WaitForChild("EconomyServer")
local EconomyShared = ReplicatedStorage:WaitForChild("EconomyShared")
local Modules = EconomyShared:WaitForChild("Modules")
local Events = EconomyShared:WaitForChild("Events")
local Players = game:GetService("Players")

local Constants = require(Modules:WaitForChild("Constants"))
local EconomyManager = require(EconomyServer:WaitForChild("EconomyManager"))

local Workspace = game:GetService("Workspace")

--/ TYPES /--
type Job = {
    Owner: Player,
    Type: string,
    Progress: number,
    Payout: number,
    ExtraData: any,
    JobDescription: string,

    FinishedProgress: number, -- Progress when the job is finished
    Completed: boolean,
    Id: number,
    LoopedJob: boolean,
    ProgressActive: boolean,
    ProgressDivisor: number,
}

type JobConfig = {
    Owner: Player,
    Type: string,
    Progress: number,
    Payout: number,
    JobDescription: string,
    FinishedProgress: number,
    ProgressDivisor: number?,
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

local function GetCharactersInZone(touching: { BasePart }, charactersFolder: Instance): { [Model]: boolean }
    local charactersInZone = {}
    for _, part in touching do
        local instance = part
        while instance and instance ~= charactersFolder do
            if instance:IsA("Model") and instance.Parent == charactersFolder then
                charactersInZone[instance] = true
                break
            end

            instance = instance.Parent
        end
    end

    return charactersInZone
end

function JobService.GetCachedZoneParts(zone: BasePart): { [Model]: boolean }
    local cachedGetParts = JobService.GetPartsCache[zone]
    if cachedGetParts and cachedGetParts[1] and cachedGetParts[2] and tick() - cachedGetParts[2] < Constants.REUSE_PARTS_CACHE_THRESHOLD then
        return cachedGetParts[1]
    end

    local characters = Workspace:FindFirstChild("Characters")
    if not characters then
        return {}
    end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Include
    overlapParams.FilterDescendantsInstances = { characters }

    local touching = Workspace:GetPartsInPart(zone, overlapParams)
    local charactersInZone = GetCharactersInZone(touching, characters)
    JobService.GetPartsCache[zone] = { charactersInZone, tick() }
    return charactersInZone
end

function JobService.IsPlayerInCachedZone(player: Player, zone: BasePart): boolean
    local character = player.Character
    if not character then
        return false
    end

    return JobService.GetCachedZoneParts(zone)[character] == true
end

--/ CORE METHODS /--
function JobService.NewJob(config: JobConfig, extraData: any)
    local jobModule = GetJobModule(config.Type)
    local job : Job = {
        Owner = config.Owner,
        Type = config.Type,
        Progress = config.Progress,
        Payout = config.Payout,
        ExtraData = extraData,
        JobDescription = config.JobDescription,

        FinishedProgress = config.FinishedProgress,
        Completed = false,
        Id = JobService.JobId,
        LoopedJob = jobModule ~= nil and jobModule.LoopedJob == true,
        ProgressActive = false,
        ProgressDivisor = config.ProgressDivisor or 1,
    }

    if not JobService.ActiveJobs[config.Owner] then
        JobService.ActiveJobs[config.Owner] = {}
    end

    JobService.ActiveJobs[config.Owner][job.Id] = job
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
    Events:WaitForChild("UpdateJobUI"):FireClient(self.Owner, { Id = self.Id })
end

function JobService:CleanupPlayer(player: Player)
    local jobs = JobService.ActiveJobs[player]
    if not jobs then
        return
    end

    for _, job in jobs do
        job.Completed = true
        local jobModule = GetJobModule(job.Type)
        if not jobModule then
            continue
        end

        jobModule.CleanupJob(job)
    end

    JobService.ActiveJobs[player] = nil
end

--/ MAIN LOOP METHOD /--
local function PackageJob(job: Job)
    return {
        Id = job.Id,
        JobDescription = job.JobDescription,
        Progress = job.Progress,
        FinishedProgress = job.FinishedProgress,
        Completed = job.Completed,
        ProgressActive = job.ProgressActive,
        ProgressDivisor = job.ProgressDivisor,
    }
end

function JobService:InitializeLoop()
    local updateEvent = Events:WaitForChild("UpdateJobUI")

    while true do
        local players = #Players:GetChildren()
        for player, jobs in JobService.ActiveJobs do
            for _, job in jobs do
                if job.LoopedJob then
                    job:CheckProgress()
                end
                updateEvent:FireClient(player, PackageJob(job))

                if players > 50 then
                    task.wait()
                end
            end
        end

        task.wait(Constants.JOB_LOOP_INTERVAL)
    end
end
return JobService