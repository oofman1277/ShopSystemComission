local Players = game:GetService("Players")
local EconomySaving = {}
EconomySaving.Profiles = {}
EconomySaving.ProfileConnections = {}
EconomySaving.SignalsEnabled = false

local DATASTORE_NAME = "EconomyData"

--/ SHORTCUT VARIABLES /--
local EconomyServer = script.Parent
local Packages = EconomyServer:WaitForChild("Packages")

local ProfileStore = require(Packages:WaitForChild("ProfileStore"))
local ProfileTemplate = require(Packages:WaitForChild("ProfileTemplate"))
local Datastore = ProfileStore.New(DATASTORE_NAME, ProfileTemplate)

--/ MAIN METHODS /--
function EconomySaving:LoadPlayerData(player: Player)
    if EconomySaving.Profiles[player] then 
        warn(player.Name.." is already loaded!")
        return
    end

    local profile = Datastore:StartSessionAsync(tostring(player.UserId), {
        Cancel = function()
            return player.Parent ~= Players
        end
    })

    if not profile then
        player:Kick("Failed to load data saving! Please rejoin!")
        warn("[EconomySaving] FAILED TO FETCH PLAYER PROFILE FOR USER ID: ".. tostring(player.UserId).." USERNAME: "..tostring(player.Name))
		return
    end

    profile:AddUserId(player.UserId) -- Essentially adds player to this profile (datastore)
    profile:Reconcile()

    if player.Parent == Players then
        EconomySaving.Profiles[player] = profile
    else
        profile:EndSession()
    end
end

function EconomySaving:InitializeConnections(player: Player)
    local profile = EconomySaving.Profiles[player]
    if not profile then return end

    local endedConnection = profile.OnSessionEnd:Connect(function()
        EconomySaving:CleanupSession(player)
    end)

    EconomySaving.ProfileConnections[player] = {endedConnection}
end

function EconomySaving:InitializeSignals(player: Player)
    if EconomySaving.SignalsEnabled == true then return end -- Already active

	ProfileStore.OnError:Connect(function(message, storeName, profileKey)
		warn(`[EconomySaving] ProfileStore error ({storeName} / {profileKey}): {message}`)
	end)

	ProfileStore.OnOverwrite:Connect(function(storeName, profileKey)
		warn(`[EconomySaving] ProfileStore overwrote invalid profile ({storeName} / {profileKey})`)
	end)

	ProfileStore.OnCriticalToggle:Connect(function(isCritical)
		if isCritical then
			warn("[EconomySaving] ProfileStore entered critical state")
			return
		end

		print("[EconomySaving] ProfileStore left critical state")
	end)

	EconomySaving.SignalsEnabled = true
	print("[EconomySaving] Store signals connected")
end

function EconomySaving:CleanupSession(player)
    EconomySaving[player] = nil

    if player and player.Parent == Players then
        player:Kick("Profile session ended! Please rejoin!")
    end
end

--/ READER METHODS /--
function EconomySaving:GetProfile(player: Player)
	return EconomySaving.Profiles[player]
end

function EconomySaving:GetPlayerData(player: Player)
	local profile = EconomySaving.Profiles[player]
	if not profile then
		return nil
	end

	return profile.Data
end

function EconomySaving:IsSessionActive(player: Player): boolean
	local profile = EconomySaving.Profiles[player]
	if not profile then
		return false
	end

	return profile:IsActive()
end

function EconomySaving:GetCurrency(player: Player)
	local data = self:GetPlayerData(player)
	if not data then
		return nil
	end

	return data.Currency
end

function EconomySaving:GetPurchasedTools(player: Player)
	local data = self:GetPlayerData(player)
	if not data then
		return nil
	end

	return data.PurchasedTools
end

--/ WRITER METHODS /--
local function WarnInactiveWrite(player: Player, action: string)
	warn(`[EconomySaving] Cannot {action} for {player.Name}: session is not active`)
end

function EconomySaving:SetCurrency(player: Player, amount: number): boolean
	if not self:IsSessionActive(player) then
		WarnInactiveWrite(player, "SetCurrency")
		return false
	end

	EconomySaving.Profiles[player].Data.Currency = amount
	return true
end

function EconomySaving:SetPurchasedTools(player: Player, tools: { [string]: boolean }): boolean
	if not self:IsSessionActive(player) then
		WarnInactiveWrite(player, "SetPurchasedTools")
		return false
	end

	EconomySaving.Profiles[player].Data.PurchasedTools = tools
	return true
end

function EconomySaving:SetPurchasedTool(player: Player, toolId: string, owned: boolean): boolean
	if not self:IsSessionActive(player) then
		WarnInactiveWrite(player, "SetPurchasedTool")
		return false
	end

	local data = EconomySaving.Profiles[player].Data
	data.PurchasedTools = data.PurchasedTools or {}

	if owned then
		data.PurchasedTools[toolId] = true
	else
		data.PurchasedTools[toolId] = nil
	end

	return true
end

return EconomySaving