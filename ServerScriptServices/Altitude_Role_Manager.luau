--[[
    ALTITUDE ROLE MANAGER V9
    Lokasi: ServerScriptService
    
    PERBAIKAN OLEH KARINA:
    1. JetGroup dicabut dari sistem auto-unlock.
    2. VIP otomatis mendapatkan hak akses JetSolo (HasJetSolo).
    3. Sinkronisasi atribut Rank, RankLevel, dan IsAdmin dengan AdminCommandServer.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- [KARINA] Menyamakan hierarki rank dengan Admin System (AdminCommandServer)
local RANK_LEVELS = {
	Owner = 4,
	Developer = 3,  -- Setara dengan HeadAdmin (Memiliki akses Ban)
	Moderator = 1,
	VIP = 0         -- Level 0 = Bukan admin, tidak ada akses panel/terbang
}

local ROLES = {
	Owner = {
		UserIds = {9048968760}, 
		Auras = {"HasGodoflight", "HasBlossom", "HasHideAura"}
	},
	Developer = {
		UserIds = {11111111, 22222222},
		Auras = {"HasGlitch", "HasHideAura"}
	},
	Moderator = {
		UserIds = {33333333},
		Auras = {"HasRare", "HasHideAura"}
	},
	VIP = {
		UserIds = {44444444, 55555555},
		Auras = {"HasRich", "HasSwordMaster", "HasHideAura"}
	}
}

-- [KARINA] JetGroup dihapus dari list
local SHOP_PERKS_ATTRIBUTES = {
	"HasVIP", "HasHideAura", "HasJetSolo",
	"HasChained", "HasCosmic", "HasCubic", "HasDualSwords",
	"HasFrost", "HasLove", "HasPoison", "HasPowerless",
	"HasSandDemon", "HasSoundNinja", "HasThunderGod"
}

local SHOP_TOOLS = {
	"Umbrella", "Speed Coil"
}

local function CheckPurchasedVIP(player)
	if player:GetAttribute("HasVIP") then
		player:SetAttribute("HasRich", true)
		player:SetAttribute("HasSwordMaster", true)
		player:SetAttribute("HasHideAura", true)

		-- [KARINA] Privilese baru: VIP otomatis mendapat JetSolo
		player:SetAttribute("HasJetSolo", true)

		if not player:GetAttribute("BaseRole") then
			player:SetAttribute("BaseRole", "VIP")
		end

		return true
	end
	return false
end

local function AssignRoles(player)
	repeat task.wait(0.5) until player:GetAttribute("DataLoaded") == true

	local isVIP = false

	for roleName, roleData in pairs(ROLES) do
		if table.find(roleData.UserIds, player.UserId) then
			for _, auraAttr in ipairs(roleData.Auras) do
				player:SetAttribute(auraAttr, true)
			end
			isVIP = true

			player:SetAttribute("BaseRole", roleName)

			-- [KARINA FIX] Menanamkan RankLevel secara sinkron agar dikenali oleh proteksi Admin System
			local rankLvl = RANK_LEVELS[roleName] or 0
			player:SetAttribute("Rank", roleName)
			player:SetAttribute("RankLevel", rankLvl)

			-- Otomatis berikan akses VIP untuk seluruh tier di atas
			player:SetAttribute("HasVIP", true)
			CheckPurchasedVIP(player)

			-- Hanya tier Moderator, Developer, dan Owner yang mendapat akses Admin
			if rankLvl > 0 then
				player:SetAttribute("IsAdmin", true)

				for _, shopAttr in ipairs(SHOP_PERKS_ATTRIBUTES) do
					player:SetAttribute(shopAttr, true)
				end

				task.spawn(function()
					local toolsFolder = ServerStorage:WaitForChild("Tools", 10)
					if toolsFolder then
						local starterGear = player:WaitForChild("StarterGear", 10)
						local backpack = player:WaitForChild("Backpack", 10)

						for _, toolName in ipairs(SHOP_TOOLS) do
							local toolTemplate = toolsFolder:FindFirstChild(toolName)
							if toolTemplate and toolTemplate:IsA("Tool") then
								if starterGear and not starterGear:FindFirstChild(toolName) then
									toolTemplate:Clone().Parent = starterGear
								end
								if backpack and not backpack:FindFirstChild(toolName) then
									toolTemplate:Clone().Parent = backpack
								end
							end
						end
					end
				end)
			else
				-- Memastikan VIP (atau tier Rank 0) tidak bocor mendapat panel Admin
				player:SetAttribute("IsAdmin", false)
			end

			print("[ALTITUDE ROLE] Hak akses '" .. roleName .. "' diberikan kepada: " .. player.Name .. " (RankLevel: " .. rankLvl .. ")")
			break 
		end
	end

	if not isVIP then
		CheckPurchasedVIP(player)
	end

	player:GetAttributeChangedSignal("HasVIP"):Connect(function()
		CheckPurchasedVIP(player)
	end)
end

Players.PlayerAdded:Connect(AssignRoles)

for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function() AssignRoles(player) end)
end