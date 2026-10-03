--/ SHORTCUT VARIABLES /--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local EconomyServer = script.Parent
local JobServiceModule = EconomyServer:WaitForChild("JobService")
local JobService = require(JobServiceModule)
local JobOptions = require(JobServiceModule:WaitForChild("JobOptions"))
local EconomySaving = require(EconomyServer:WaitForChild("EconomySaving"))
local EconomyManager = require(EconomyServer:WaitForChild("EconomyManager"))
local ShopService = require(EconomyServer:WaitForChild("ShopService"))

--/ CORE /--
Players.PlayerAdded:Connect(function(player: Player)
    EconomySaving:LoadPlayerData(player)
    EconomySaving:InitializeConnections(player)
    EconomySaving:InitializeSignals(player)

    EconomyManager:InitializeAttribute(player)
    ShopService.SendCatalog(player)
    JobService:InitializeKillPay(player)
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
JobService:InitializeWage()
JobService:InitializeLoop()
