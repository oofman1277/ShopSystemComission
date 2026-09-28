--/ SHORTCUT VARIABLES /--
local Players = game:GetService("Players")

local EconomyServer = script.Parent
local MoneyManagement = require(EconomyServer:WaitForChild("MoneyManagement"))

--/ CORE FUNCTIONALITY /--
Players.PlayerAdded:Connect(function(player: Player)
    local success, reason = MoneyManagement:InitialisePlayer(player)
    print(success, reason)
end)

while true do
    task.wait(1)
    for _, player in Players:GetChildren() do
        if not player:IsA("Player") then continue end
        MoneyManagement:AddMoney(player, 0.25)
    end
end