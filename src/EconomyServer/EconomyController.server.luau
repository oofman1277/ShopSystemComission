--/ SHORTCUT VARIABLES /--
local Players = game:GetService("Players")
local Teams = game:GetService('Teams')
local Workspace = game:GetService("Workspace")

local EconomyServer = script.Parent
local JobServiceModule = EconomyServer:WaitForChild("JobService")
local JobService = require(JobServiceModule)
local JobOptions = require(JobServiceModule:WaitForChild("JobOptions"))
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

JobOptions.InitializeJobNPCs()
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
