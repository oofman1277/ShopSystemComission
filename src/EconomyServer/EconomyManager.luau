local EconomyManager = {}
EconomyManager.__index = EconomyManager

--/ SHORTCUT VARIABLES /--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyServer = script.Parent
local EconomyShared = ReplicatedStorage:WaitForChild("EconomyShared")
local SharedModules = EconomyShared:WaitForChild("Modules")

local Constants = require(SharedModules:WaitForChild("Constants"))
local EconomySaving = require(EconomyServer:WaitForChild("EconomySaving"))

--/ CORE METHODS /--
function EconomyManager:InitializeAttribute(player: Player)
    if player:GetAttribute(Constants.CURRENCY_ATTRIBUTE_NAME) ~= nil then return end -- already initialized

    local profile = EconomySaving.Profiles[player]
    if not profile or not profile.Data then return end

    player:SetAttribute(Constants.CURRENCY_ATTRIBUTE_NAME, profile.Data.Currency)
end

--/ READERS /--
function EconomyManager:GetPlayerMoney(player: Player)
    return EconomySaving:GetCurrency(player)
end

--/ WRITERS /--
function EconomyManager:SetCurrency(player: Player, amount: number)
    EconomySaving:SetCurrency(player, amount)
    player:SetAttribute(Constants.CURRENCY_ATTRIBUTE_NAME, amount)
end

function EconomyManager:AddCurrency(player: Player, amount: number): boolean
    local currentAmount = EconomySaving:GetCurrency(player)
    if not currentAmount then return false end

    local newAmount = math.clamp(currentAmount + amount, 0, math.huge)
    EconomySaving:SetCurrency(player, newAmount)
    player:SetAttribute(Constants.CURRENCY_ATTRIBUTE_NAME, newAmount)
    return true
end

return EconomyManager