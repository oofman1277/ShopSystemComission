local MoneyManagement = {}
MoneyManagement.__index = MoneyManagement

--/ SHORTCUT VARIABLES /--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyShared = ReplicatedStorage:WaitForChild("EconomyShared")
local SharedModules = EconomyShared:WaitForChild("Modules")

local Constants = require(SharedModules:WaitForChild("Constants"))

--/ HELPER METHODS /--
function MoneyManagement:InitialisePlayer(player: Player): (boolean, string?)
    if self:IsPlayerInitialised(player) then return false, "Player already initialised!" end

    local currentMoney = 5 --Placeholder, fetch from datastorage module once implemented
    player:SetAttribute(Constants.CurrencyAttributeName, currentMoney)
    return true
end

function MoneyManagement:IsPlayerInitialised(player: Player)
    return player:GetAttribute(Constants.CurrencyAttributeName) ~= nil
end

function MoneyManagement:GetPlayerMoney(player: Player)
    if not self:IsPlayerInitialised(player) then 
        self:InitialisePlayer(player)
    end

    return player:GetAttribute(Constants.CurrencyAttributeName)
end

--/ MONEY CHANGE METHODS /--
function MoneyManagement:SetMoney(player: Player, amount: number)
    if not self:IsPlayerInitialised(player) then 
        self:InitialisePlayer(player)
    end

    player:SetAttribute(Constants.CurrencyAttributeName, amount)
end

function MoneyManagement:AddMoney(player: Player, amount: number)
    if not self:IsPlayerInitialised(player) then
        self:InitialisePlayer(player)
    end

    local currentMoney = MoneyManagement:GetPlayerMoney(player)
    self:SetMoney(player, currentMoney + amount)
end

return MoneyManagement