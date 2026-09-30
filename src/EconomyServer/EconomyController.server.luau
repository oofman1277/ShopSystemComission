--/ SHORTCUT VARIABLES /--
local Players = game:GetService("Players")
local Teams = game:GetService('Teams')

local EconomyServer = script.Parent
local JobService = require(script.Parent.JobService)
local EconomySaving = require(EconomyServer:WaitForChild("EconomySaving"))
local EconomyManager = require(EconomyServer:WaitForChild("EconomyManager"))

--/ CORE /--
Players.PlayerAdded:Connect(function(player: Player)
    EconomySaving:LoadPlayerData(player)
    EconomySaving:InitializeConnections(player)
    EconomySaving:InitializeSignals(player)

    EconomyManager:InitializeAttribute(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    local profile = EconomySaving:GetProfile(player)
    profile:EndSession()
end)

task.wait(10)

local testJob = JobService.NewJob(game.Players:WaitForChild("oofman1277"), "StandZone", 0.6, 0, 10, {Location = "TestLocation"})
testJob:Start()

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
