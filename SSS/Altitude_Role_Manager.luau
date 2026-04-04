--[[
    ALTITUDE ROLE MANAGER V12
    Lokasi: ServerScriptService
    
    PERBAIKAN OLEH KARINA:
    1. JetGroup dicabut dari sistem auto-unlock.
    2. VIP otomatis mendapatkan hak akses JetSolo (HasJetSolo).
    3. Sinkronisasi atribut Rank, RankLevel, dan IsAdmin dengan AdminCommandServer.
    4. UNIVERSAL TOOL RESTORE: Fungsi restorasi Tool dipindah ke luar blok Admin. 
    5. [NEW] AUTO STAFF TOOLS: Otomatis membaca ServerStorage > Tools > Staff dan memberikannya ke Admin.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local RANK_LEVELS = {
	Owner = 4,
	Developer = 3, 
	Moderator = 1,
	VIP = 0         
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

			assignedRankLevel = RANK_LEVELS[roleName] or 0
			player:SetAttribute("Rank", roleName)
			player:SetAttribute("RankLevel", assignedRankLevel)

			player:SetAttribute("HasVIP", true)
			CheckPurchasedVIP(player)

			if assignedRankLevel > 0 then
				player:SetAttribute("IsAdmin", true)
				for _, shopAttr in ipairs(SHOP_PERKS_ATTRIBUTES) do
					player:SetAttribute(shopAttr, true)
				end
			else
				player:SetAttribute("IsAdmin", false)
			end

			print("[ALTITUDE ROLE] Hak akses '" .. roleName .. "' diberikan kepada: " .. player.Name .. " (RankLevel: " .. assignedRankLevel .. ")")
			break 
		end
	end

	if not isVIP then
		CheckPurchasedVIP(player)
		player:SetAttribute("RankLevel", 0)
		player:SetAttribute("IsAdmin", false)
	end

	player:GetAttributeChangedSignal("HasVIP"):Connect(function()
		CheckPurchasedVIP(player)
	end)

	local function RestoreOwnedTools(character)
		local toolsFolder = ServerStorage:FindFirstChild("Tools")
		local staffToolsFolder = toolsFolder and toolsFolder:FindFirstChild("Staff")

		local backpack = player:WaitForChild("Backpack", 30) 
		local starterGear = player:FindFirstChild("StarterGear")
		local isAdmin = player:GetAttribute("IsAdmin") == true

		if backpack then
			-- 1. Mengembalikan Item Pembelian Pemain
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

			-- 2. [KARINA NEW] Mengembalikan Item Khusus Staff (Tanpa perlu beli)
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

	if player.Character then 
		task.spawn(function() RestoreOwnedTools(player.Character) end) 
	end

	player.CharacterAdded:Connect(RestoreOwnedTools)
end

Players.PlayerAdded:Connect(AssignRoles)

for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function() AssignRoles(player) end)
end