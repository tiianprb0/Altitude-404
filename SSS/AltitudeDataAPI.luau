--[[
    ESKA - ALTITUDE DATA API (GLOBAL ECONOMY & PROFILE MANAGER)
    Lokasi: ServerScriptService > AltitudeDataAPI (ModuleScript)
    
    DESKRIPSI:
    Bertindak sebagai Single Source of Truth untuk seluruh data pemain.
    Modifikasi ekonomi (Coins & Summits) wajib melalui API ini untuk 
    mencegah desinkronisasi antara ProfileStore dan Leaderstats.
]]

local AltitudeDataAPI = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local BadgeService = game:GetService("BadgeService")

local ProfileService = require(ServerScriptService:WaitForChild("ProfileService"))

local PROFILE_STORE_KEY = "AltitudeData_Profile_V1"

--// CONFIG PLAYTIME BADGE
local IS_BETA_ACTIVE = true
local TIME_REQUIRED = 300 
local BADGE_ID = 2616197412534465

local DEFAULT_DATA = {
	Coins = 0,
	Summits = 0,
	Checkpoint = 0,
	SubCp = "",
	OwnedTools = {},
	OwnedPerks = {},
	ClaimedCodes = {},

	ActiveAura = "",
	ActiveTitle = "",

	PlayTime = 0
}

local AltitudeStore = ProfileService.GetProfileStore(PROFILE_STORE_KEY, DEFAULT_DATA)
local Profiles = {}

-- ==========================================
-- GLOBAL API FUNCTIONS
-- ==========================================

function AltitudeDataAPI.GetProfile(player)
	return Profiles[player]
end

function AltitudeDataAPI.GetCoins(player)
	local profile = Profiles[player]
	return profile and profile.Data.Coins or 0
end

function AltitudeDataAPI.AddCoins(player, amount)
	local profile = Profiles[player]
	if not profile then return false end

	amount = math.floor(math.abs(amount))
	if amount == 0 then return true end

	profile.Data.Coins += amount

	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Coins") then
		ls.Coins.Value = profile.Data.Coins
	end
	return true
end

function AltitudeDataAPI.DeductCoins(player, amount)
	local profile = Profiles[player]
	if not profile then return false end

	amount = math.floor(math.abs(amount))
	if amount == 0 then return true end

	if profile.Data.Coins >= amount then
		profile.Data.Coins -= amount

		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Coins") then
			ls.Coins.Value = profile.Data.Coins
		end
		return true
	end
	return false
end

function AltitudeDataAPI.GetSummits(player)
	local profile = Profiles[player]
	return profile and profile.Data.Summits or 0
end

function AltitudeDataAPI.AddSummits(player, amount)
	local profile = Profiles[player]
	if not profile then return false end

	amount = math.floor(math.abs(amount))
	if amount == 0 then return true end

	profile.Data.Summits += amount

	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Summits") then
		ls.Summits.Value = profile.Data.Summits
	end
	return true
end

function AltitudeDataAPI.DeductSummits(player, amount)
	local profile = Profiles[player]
	if not profile then return false end

	amount = math.floor(math.abs(amount))
	if amount == 0 then return true end

	if profile.Data.Summits >= amount then
		profile.Data.Summits -= amount

		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Summits") then
			ls.Summits.Value = profile.Data.Summits
		end
		return true
	end
	return false
end

function AltitudeDataAPI.ResetSummits(player)
	local profile = Profiles[player]
	if not profile then return false end

	profile.Data.Summits = 0

	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Summits") then
		ls.Summits.Value = 0
	end
	return true
end

-- ==========================================
-- INTERNAL SYNC LOGIC
-- ==========================================

local function SetupDataSync(player, profile)
	-- 1. SETUP LEADERSTATS
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("NumberValue")
	coins.Name = "Coins"
	coins.Value = profile.Data.Coins
	coins.Parent = leaderstats

	local summits = Instance.new("IntValue")
	summits.Name = "Summits"
	summits.Value = profile.Data.Summits
	summits.Parent = leaderstats

	local checkpoint = Instance.new("IntValue")
	checkpoint.Name = "Checkpoint"
	checkpoint.Value = profile.Data.Checkpoint
	checkpoint.Parent = leaderstats

	local pCoins = coins:Clone(); pCoins.Parent = player
	local pSummits = summits:Clone(); pSummits.Parent = player
	local pCheckpoint = checkpoint:Clone(); pCheckpoint.Parent = player

	pCoins.Changed:Connect(function(val) if coins.Value ~= val then coins.Value = val end end)
	coins.Changed:Connect(function(val) 
		if pCoins.Value ~= val then pCoins.Value = val end 
		profile.Data.Coins = val 
	end)

	pSummits.Changed:Connect(function(val) if summits.Value ~= val then summits.Value = val end end)
	summits.Changed:Connect(function(val) 
		if pSummits.Value ~= val then pSummits.Value = val end 
		profile.Data.Summits = val 
	end)

	pCheckpoint.Changed:Connect(function(val) if checkpoint.Value ~= val then checkpoint.Value = val end end)
	checkpoint.Changed:Connect(function(val) 
		if pCheckpoint.Value ~= val then pCheckpoint.Value = val end 
		profile.Data.Checkpoint = val 
	end)

	-- 2. SETUP ATTRIBUTES
	player:SetAttribute("SubCp", profile.Data.SubCp or "")
	player:SetAttribute("ActiveAura", profile.Data.ActiveAura or "")
	player:SetAttribute("ActiveTitle", profile.Data.ActiveTitle or "")
	player:SetAttribute("PlayTime", profile.Data.PlayTime or 0)
	player:SetAttribute("PlayTimeBadgeAwarded", false)

	for _, toolName in pairs(profile.Data.OwnedTools) do
		player:SetAttribute("OwnsTool_" .. string.gsub(toolName, "%s+", ""), true) 
	end
	for _, perkName in pairs(profile.Data.OwnedPerks) do
		player:SetAttribute(perkName, true)
	end
	for _, code in pairs(profile.Data.ClaimedCodes) do
		player:SetAttribute("ClaimedCode_" .. code, true)
	end

	-- 3. SINKRONISASI REAKTIF (ATTRIBUTES -> PROFILE)
	player.AttributeChanged:Connect(function(attrName)
		local val = player:GetAttribute(attrName)

		if attrName == "SubCp" then
			profile.Data.SubCp = val
		elseif attrName == "ActiveAura" then
			profile.Data.ActiveAura = val
		elseif attrName == "ActiveTitle" then
			profile.Data.ActiveTitle = val
		elseif attrName == "PlayTime" then
			profile.Data.PlayTime = val
		elseif string.sub(attrName, 1, 9) == "OwnsTool_" then
			local toolName = string.sub(attrName, 10)
			if val == true then
				if not table.find(profile.Data.OwnedTools, toolName) then
					table.insert(profile.Data.OwnedTools, toolName)
				end
			else
				local idx = table.find(profile.Data.OwnedTools, toolName)
				if idx then table.remove(profile.Data.OwnedTools, idx) end
			end
		elseif string.sub(attrName, 1, 3) == "Has" then
			if val == true then
				if not table.find(profile.Data.OwnedPerks, attrName) then
					table.insert(profile.Data.OwnedPerks, attrName)
				end
			end
		elseif string.sub(attrName, 1, 12) == "ClaimedCode_" then
			local code = string.sub(attrName, 13)
			if val == true then
				if not table.find(profile.Data.ClaimedCodes, code) then
					table.insert(profile.Data.ClaimedCodes, code)
				end
			end
		end
	end)

	player:SetAttribute("DataLoaded", true)
end

local function PlayerAdded(player)
	local profile = AltitudeStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId) 
		profile:Reconcile() 

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("\nAltitude System ??\n\nSesi datamu telah diambil alih oleh server lain.\nIni adalah fitur keamanan agar datamu tidak corrupt. Silakan rejoin.")
		end)

		if player:IsDescendantOf(Players) == true then
			Profiles[player] = profile
			SetupDataSync(player, profile)
			print("[ESKA DATA] ProfileStore berhasil dimuat untuk " .. player.Name)
		else
			profile:Release()
		end
	else
		player:Kick("\nAltitude System ??\n\nGagal memuat datamu karena gangguan server Roblox.\nMohon rejoin ulang agar data lamamu tidak hilang.") 
	end
end

-- ==========================================
-- PLAYTIME TIMER & EVENTS BINDING
-- ==========================================

if IS_BETA_ACTIVE then
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				if Profiles[player] and player:GetAttribute("DataLoaded") then
					local currentPlayTime = (player:GetAttribute("PlayTime") or 0) + 1
					player:SetAttribute("PlayTime", currentPlayTime)

					if currentPlayTime >= TIME_REQUIRED and not player:GetAttribute("PlayTimeBadgeAwarded") then
						player:SetAttribute("PlayTimeBadgeAwarded", true)

						task.spawn(function()
							local success, hasBadge = pcall(function()
								return BadgeService:UserHasBadgeAsync(player.UserId, BADGE_ID)
							end)

							if success and not hasBadge then
								local awardSuccess = pcall(function()
									BadgeService:AwardBadge(player.UserId, BADGE_ID)
								end)
								if not awardSuccess then
									player:SetAttribute("PlayTimeBadgeAwarded", false)
								end
							end
						end)
					end
				end
			end
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:Release() 
		print("[ESKA DATA] Data disimpan & Profile dirilis untuk " .. player.Name)
	end
end)

return AltitudeDataAPI