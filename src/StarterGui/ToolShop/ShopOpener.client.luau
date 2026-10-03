local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CollectionService = game:GetService("CollectionService")

local ProximityPrompts = CollectionService:GetTagged("ToolShopProximity")

local function InitializeProximity(proximity)
    if not proximity:IsA("ProximityPrompt") then return end

    proximity.Triggered:Connect(function(triggeredPlayer: Player)
        if triggeredPlayer ~= Player then return end
        local Shop = PlayerGui:WaitForChild("ToolShop")
        Shop.Enabled = true
    end)
end

for _, proximity in ProximityPrompts do
    InitializeProximity(proximity)
end

CollectionService:GetInstanceAddedSignal("ToolShopProximity"):Connect(function(proximity: Instance)
    InitializeProximity(proximity)
end)
