--[[
    ESKA - SERVER ROLE API (SINGLE SOURCE OF TRUTH)
    Lokasi: ServerScriptService > ServerRoleAPI (ModuleScript)
    
    DESKRIPSI:
    Sistem otorisasi terpusat. Mengunci seluruh hierarki pangkat di dalam memori server 
    (Zero Trust to Client). Atribut klien hanya digunakan untuk kebutuhan kosmetik UI.
]]

local ServerRoleAPI = {}

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local AdminDS = DataStoreService:GetDataStore("AdminData_V1")

local SUPER_OWNERS = { [9048968760] = true }

local RANK_LEVELS = {
	Owner = 4,
	HeadAdmin = 3,
	Developer = 3, 
	Admin = 2,
	Moderator = 1,
	VIP = 0,
	Player = 0
}

local ROLES = {
	Owner = {
		UserIds = {9048968760}, 
		Auras = {"HasGodoflight", "HasBlossom", "HasHideAura"}
	},
	Developer = {
		UserIds = {8967444995, 22222222},
		Auras = {"HasGlitch", "HasHideAura"}
	},
	Moderator = {
		UserIds = {4715523276, 8283435988, 9777814507, 7155269748, 9270416939, 9308895997, 9148442635, 9054982038, 9308895997, 8674490432},
		Auras = {"HasRare", "HasHideAura"}
	},
	VIP = {
		UserIds = {44444444, 55555555},
		Auras = {"HasRich", "HasSwordMaster", "HasHideAura"}
	}
}

local SHOP_PERKS_ATTRIBUTES = {
	"HasVIP", "HasHideAura", "HasJetSolo",
	"HasChained", "HasCosmic", "HasCubic", "HasDualSwords",
	"HasFrost", "HasLove", "HasPoison", "HasPowerless",
	"HasSandDemon", "HasSoundNinja", "HasThunderGod"
}

-- Private Server Memory Cache (Zero Trust)
local PlayerSessionCache = {}

-- ==========================================
-- FUNGSI VALIDASI PUBLIK (API)
-- ==========================================

function ServerRoleAPI.GetRankLevel(player)
	if not player or not PlayerSessionCache[player.UserId] then return 0 end
	return PlayerSessionCache[player.UserId].RankLevel
end

function ServerRoleAPI.IsAdmin(player)
	return ServerRoleAPI.GetRankLevel(player) > 0
end

-- Mengecek apakah Sender memiliki wewenang memodifikasi Target
function ServerRoleAPI.CanTarget(sender, targetPlayer)
	if not sender or not targetPlayer then return false end
	local senderLevel = ServerRoleAPI.GetRankLevel(sender)
	local targetLevel = ServerRoleAPI.GetRankLevel(targetPlayer)

	-- Owner tidak bisa ditarget oleh siapapun kecuali sesama Owner
	if targetLevel == 4 and senderLevel < 4 then
		return false
	end
	return true
end

-- ==========================================
-- LOGIKA INTERNAL & INISIALISASI
-- ==========================================

local function CheckPurchasedVIP(player)
	if player:GetAttribute("HasVIP") then
		player:SetAttribute("HasRich", true)
		player:SetAttribute("HasSwordMaster", true)
		player:SetAttribute("HasHideAura", true)
		player:SetAttribute("HasJetSolo", true)

		if not player:GetAttribute("BaseRole") then
			player:SetAttribute("BaseRole", "VIP")
		end
		return true
	end
	return false
end

local function RestoreOwnedTools(player, character)
	local toolsFolder = ServerStorage:FindFirstChild("Tools")
	local staffToolsFolder = toolsFolder and toolsFolder:FindFirstChild("Staff")

	local backpack = player:WaitForChild("Backpack", 30) 
	local starterGear = player:FindFirstChild("StarterGear")
	local isAdmin = ServerRoleAPI.IsAdmin(player)

	if backpack then
		if toolsFolder then
			for _, toolTemplate in ipairs(toolsFolder:GetChildren()) do
				if toolTemplate:IsA("Tool") then
					local safeName = string.gsub(toolTemplate.Name, "%s+", "")
					if player:GetAttribute("OwnsTool_" .. safeName) == true then
						if starterGear and not starterGear:FindFirstChild(toolTemplate.Name) then
							toolTemplate:Clone().Parent = starterGear
						end
						if not backpack:FindFirstChild(toolTemplate.Name) and not character:FindFirstChild(toolTemplate.Name) then
							toolTemplate:Clone().Parent = backpack
						end
					end
				end
			end
		end

		if isAdmin and staffToolsFolder then
			for _, staffTool in ipairs(staffToolsFolder:GetChildren()) do
				if staffTool:IsA("Tool") then
					if starterGear and not starterGear:FindFirstChild(staffTool.Name) then
						staffTool:Clone().Parent = starterGear
					end
					if not backpack:FindFirstChild(staffTool.Name) and not character:FindFirstChild(staffTool.Name) then
						staffTool:Clone().Parent = backpack
					end
				end
			end
		end
	end
end

function ServerRoleAPI.InitializePlayer(player)
	repeat task.wait(0.5) until player:GetAttribute("DataLoaded") == true

	local rankName = "Player"
	local rankLevel = 0
	local isVIP = false

	-- 1. Evaluasi Super Owner
	if SUPER_OWNERS[player.UserId] then
		rankName = "Owner"
		rankLevel = RANK_LEVELS.Owner
	else
		-- 2. Evaluasi Hardcoded Roles
		local foundRole = false
		for rName, roleData in pairs(ROLES) do
			if table.find(roleData.UserIds, player.UserId) then
				rankName = rName
				rankLevel = RANK_LEVELS[rName] or 0

				for _, auraAttr in ipairs(roleData.Auras) do
					player:SetAttribute(auraAttr, true)
				end
				if rName == "VIP" or rankLevel > 0 then isVIP = true end

				player:SetAttribute("BaseRole", rName)
				player:SetAttribute("HasVIP", true)
				CheckPurchasedVIP(player)
				foundRole = true
				break
			end
		end

		-- 3. Evaluasi Admin Datastore (Jika tidak ada di hardcoded)
		if not foundRole then
			local success, savedRank = pcall(function() return AdminDS:GetAsync("Admin_"..player.UserId) end)
			if success and savedRank and RANK_LEVELS[savedRank] then
				rankName = savedRank
				rankLevel = RANK_LEVELS[savedRank]
			end
		end
	end

	-- Simpan di Memory Server (Single Source of Truth)
	PlayerSessionCache[player.UserId] = {
		RankName = rankName,
		RankLevel = rankLevel
	}

	-- Set atribut hanya untuk kebutuhan tampilan UI klien
	player:SetAttribute("Rank", rankName)
	player:SetAttribute("RankLevel", rankLevel)
	player:SetAttribute("IsAdmin", rankLevel > 0)

	if rankLevel > 0 then
		for _, shopAttr in ipairs(SHOP_PERKS_ATTRIBUTES) do
			player:SetAttribute(shopAttr, true)
		end
	end

	if not isVIP then
		CheckPurchasedVIP(player)
	end

	print("[ESKA SYSTEM] Pangkat diinisialisasi untuk: " .. player.Name .. " | Pangkat: " .. rankName .. " | Level: " .. rankLevel)

	player:GetAttributeChangedSignal("HasVIP"):Connect(function()
		CheckPurchasedVIP(player)
	end)

	if player.Character then 
		task.spawn(function() RestoreOwnedTools(player, player.Character) end) 
	end

	player.CharacterAdded:Connect(function(character)
		RestoreOwnedTools(player, character)
	end)
end

function ServerRoleAPI.RemovePlayer(player)
	if PlayerSessionCache[player.UserId] then
		PlayerSessionCache[player.UserId] = nil
	end
end

-- Auto-Init
Players.PlayerAdded:Connect(ServerRoleAPI.InitializePlayer)
Players.PlayerRemoving:Connect(ServerRoleAPI.RemovePlayer)

return ServerRoleAPI