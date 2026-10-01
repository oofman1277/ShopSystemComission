--/ SHORTCUT VARIABLES /--
local Players = game:GetService("Players")
local Teams = game:GetService('Teams')
local Workspace = game:GetService("Workspace")

local EconomyServer = script.Parent
local JobService = require(EconomyServer:WaitForChild("JobService"))
local EconomySaving = require(EconomyServer:WaitForChild("EconomySaving"))
local EconomyManager = require(EconomyServer:WaitForChild("EconomyManager"))

--/ CORE /--
Players.PlayerAdded:Connect(function(player: Player)
    EconomySaving:LoadPlayerData(player)
    EconomySaving:InitializeConnections(player)
    EconomySaving:InitializeSignals(player)

    EconomyManager:InitializeAttribute(player)
    if player.Character then
        player.Character.Parent = Workspace:WaitForChild("Characters")
    end

    player.CharacterAdded:Connect(function(character: Model)
        character.Parent = Workspace:WaitForChild("Characters")
    end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    JobService:CleanupPlayer(player)

    local profile = EconomySaving:GetProfile(player)
    profile:EndSession()
end)

task.wait(10)

-- local testJob = JobService.NewJob({
--     Owner = game.Players:WaitForChild("oofman1277"),
--     Type = "StandZone",
--     Payout = 0.6,
--     Progress = 0,
--     FinishedProgress = 300,
--     JobDescription = "Stand in Standzone",
--     ProgressDivisor = 60,
-- }, { Location = "TestLocation" })

local haulJob = JobService.NewJob({
    Owner = game.Players:WaitForChild("oofman1277"),
    Type = "Haul",
    Payout = 2,
    Progress = 0,
    FinishedProgress = 1,
    JobDescription = "Haul the crate",
}, {
    PartA = workspace:WaitForChild("HaulJobStart"),
    PartB = workspace:WaitForChild("HaulJobEnd"),
    ToolName = "Crate",
    WalkSpeed = 8,
    StrictCarrying = true,
})

workspace:WaitForChild("HaulJobStart"):WaitForChild("HaulJob").Triggered:Connect(function()
    haulJob:Start()
end)

local testPlayer = game.Players:WaitForChild("oofman1277")

local killsJob = JobService.NewJob({
    Owner = testPlayer,
    Type = "GetKills",
    Payout = 2,
    Progress = 0,
    FinishedProgress = 2,
    JobDescription = "Get 2 kills",
}, {})
killsJob:Start()

local toolZoneJob = JobService.NewJob({
    Owner = testPlayer,
    Type = "ToolZone",
    Payout = 2,
    Progress = 0,
    FinishedProgress = 15,
    JobDescription = "Hold Jobshovel in TestLocation",
}, {
    Location = "TestLocation",
    Tool = "JobShovel",
})
toolZoneJob:Start()

local standJob = JobService.NewJob({
    Owner = testPlayer,
    Type = "StandZone",
    Payout = 0.6,
    Progress = 0,
    FinishedProgress = 300,
    JobDescription = "Stand in Standzone",
    ProgressDivisor = 60,
}, { Location = "TestLocation" })
standJob:Start()

JobService:InitializeLoop()

while true do
    for _, player: Player in Players:GetChildren() do
        if player.Team == Teams["Federal States"] then
            EconomyManager:AddCurrency(player, 0.07)
        elseif player.Team == Teams["Hostile Forces"] then
            EconomyManager:AddCurrency(player, 0.05)
        end
    end
    task.wait(900)
end
