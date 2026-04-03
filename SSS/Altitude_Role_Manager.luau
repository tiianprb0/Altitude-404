--[[
    ALTITUDE ROLE MANAGER V11
    Lokasi: ServerScriptService
    
    PERBAIKAN OLEH KARINA:
    1. JetGroup dicabut dari sistem auto-unlock.
    2. VIP otomatis mendapatkan hak akses JetSolo (HasJetSolo).
    3. Sinkronisasi atribut Rank, RankLevel, dan IsAdmin dengan AdminCommandServer.
    4. UNIVERSAL TOOL RESTORE: Fungsi restorasi Tool dipindah ke luar blok Admin. 
       Kini semua pemain (termasuk non-admin) yang mendapat gift/beli Tool akan 
       mendapatkan kembali itemnya saat respawn berdasarkan atribut 'OwnsTool_'.
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
		UserIds = {8967444995, 22222222},
		Auras = {"HasGlitch", "HasHideAura"}
	},
	Moderator = {
		UserIds = {4715523276, 8283435988, 9777814507, 7155269748, 9270416939, 9148442635, 9054982038, 8674490432},
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
	local assignedRankLevel = 0

	for roleName, roleData in pairs(ROLES) do
		if table.find(roleData.UserIds, player.UserId) then
			for _, auraAttr in ipairs(roleData.Auras) do
				player:SetAttribute(auraAttr, true)
			end
			isVIP = true

			player:SetAttribute("BaseRole", roleName)

			-- [KARINA] Menanamkan RankLevel secara sinkron agar dikenali oleh proteksi Admin System
			assignedRankLevel = RANK_LEVELS[roleName] or 0
			player:SetAttribute("Rank", roleName)
			player:SetAttribute("RankLevel", assignedRankLevel)

			-- Otomatis berikan akses VIP untuk seluruh tier di atas
			player:SetAttribute("HasVIP", true)
			CheckPurchasedVIP(player)

			-- Hanya tier Moderator, Developer, dan Owner yang mendapat privilese Admin
			if assignedRankLevel > 0 then
				player:SetAttribute("IsAdmin", true)

				for _, shopAttr in ipairs(SHOP_PERKS_ATTRIBUTES) do
					player:SetAttribute(shopAttr, true)
				end
			else
				-- Memastikan VIP tidak bocor mendapat panel Admin
				player:SetAttribute("IsAdmin", false)
			end

			print("[ALTITUDE ROLE] Hak akses '" .. roleName .. "' diberikan kepada: " .. player.Name .. " (RankLevel: " .. assignedRankLevel .. ")")
			break 
		end
	end

	-- Jika pemain sama sekali tidak terdaftar di ROLES (Player biasa yang mungkin beli VIP manual)
	if not isVIP then
		CheckPurchasedVIP(player)
		player:SetAttribute("RankLevel", 0)
		player:SetAttribute("IsAdmin", false)
	end

	player:GetAttributeChangedSignal("HasVIP"):Connect(function()
		CheckPurchasedVIP(player)
	end)

	-- =========================================================================
	-- [KARINA UNIVERSAL RESTORE]
	-- Logika pemberian Tool dikeluarkan dari blok "if rankLvl > 0" agar 
	-- semua pemain yang memiliki kepemilikan valid (dari beli/gift)
	-- tetap menerima Tool mereka setiap kali respawn.
	-- =========================================================================
	local function RestoreOwnedTools(character)
		local toolsFolder = ServerStorage:FindFirstChild("Tools")
		if not toolsFolder then return end

		-- Kita tunggu Backpack tanpa batas waktu kritis
		local backpack = player:WaitForChild("Backpack", 30) 
		local starterGear = player:FindFirstChild("StarterGear")

		if backpack then
			for _, toolTemplate in ipairs(toolsFolder:GetChildren()) do
				if toolTemplate:IsA("Tool") then
					-- Hapus spasi untuk pencocokan standar atribut (misal "Speed Coil" jadi "SpeedCoil")
					local safeName = string.gsub(toolTemplate.Name, "%s+", "")

					-- Syarat 1: Pemain memiliki Tool secara personal (dari Shop / Gift Admin)
					local ownsByAttribute = player:GetAttribute("OwnsTool_" .. safeName) == true

					-- Syarat 2: Pemain adalah Admin dan Tool tersebut adalah Tool default Admin
					local ownsByAdmin = (player:GetAttribute("IsAdmin") == true) and table.find(SHOP_TOOLS, toolTemplate.Name)

					if ownsByAttribute or ownsByAdmin then
						-- Masukkan ke StarterGear sebagai backup permanen
						if starterGear and not starterGear:FindFirstChild(toolTemplate.Name) then
							toolTemplate:Clone().Parent = starterGear
						end

						-- Masukkan ke tas (Backpack) jika belum ada dan sedang tidak dipegang di tangan
						if not backpack:FindFirstChild(toolTemplate.Name) and not character:FindFirstChild(toolTemplate.Name) then
							toolTemplate:Clone().Parent = backpack
						end
					end
				end
			end
		end
	end

	-- Eksekusi langsung jika karakter sudah ada saat loading selesai
	if player.Character then 
		task.spawn(function() RestoreOwnedTools(player.Character) end) 
	end

	-- Pantau secara permanen untuk setiap kali karakter respawn
	player.CharacterAdded:Connect(RestoreOwnedTools)
end

Players.PlayerAdded:Connect(AssignRoles)

for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function() AssignRoles(player) end)
end