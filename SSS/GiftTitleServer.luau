-- ServerScriptService.GiftTitleServer
-- Sistem gift title (ProfileService Integration + Reactive Sync)
-- Diperbarui oleh Karina: Keamanan Session Lock, Auto-Sync Memory, dan Filter Kata Terlarang

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileService = require(ServerScriptService:WaitForChild("ProfileService"))

local PROFILE_STORE_KEY = "GiftTitles_Profile_V1"

local DEFAULT_TITLE_DATA = {
	Type  = "",
	Text  = "",
	Color = {255, 255, 255}, -- Disimpan dalam RGB Array agar aman di JSON
	Font  = "GothamBold",
	Icon  = ""
}

local TitleStore = ProfileService.GetProfileStore(PROFILE_STORE_KEY, DEFAULT_TITLE_DATA)
local Profiles = {}

----------------------------------------------------
-- 1. KONFIGURASI ID & WARNA                      --
----------------------------------------------------

local ICONS = {
	Owner     = "rbxassetid://99840264488161",   
	Developer = "rbxassetid://129077744848614",  
	Admin     = "rbxassetid://88380319128808",
	Moderator = "rbxassetid://88380319128808",
	VIP       = "rbxassetid://1234567890", 
	Streamer  = "rbxassetid://0987654321", 
	Custom    = "rbxassetid://79851096577729",   
}

local DEFAULT_COLORS = {
	Owner     = Color3.fromRGB(255, 232, 140),
	Developer = Color3.fromRGB(180, 240, 255),
	Admin     = Color3.fromRGB(255, 180, 180),
	Moderator = Color3.fromRGB(255, 180, 180),
	VIP       = Color3.fromRGB(255, 215, 0),   
	Streamer  = Color3.fromRGB(147, 112, 219), 
	Custom    = Color3.fromRGB(255, 190, 230),
}

----------------------------------------------------
-- 2. SETUP REMOTES                               --
----------------------------------------------------

local requestEvent = ReplicatedStorage:FindFirstChild("GiftTitleRequest") or Instance.new("RemoteEvent", ReplicatedStorage)
requestEvent.Name = "GiftTitleRequest"

local responseEvent = ReplicatedStorage:FindFirstChild("GiftTitleResponse") or Instance.new("RemoteEvent", ReplicatedStorage)
responseEvent.Name = "GiftTitleResponse"

local function sendMessage(player, text)
	responseEvent:FireClient(player, text)
end

----------------------------------------------------
-- 3. FUNGSI SINKRONISASI (FOLDER <-> PROFILE)    --
----------------------------------------------------
local function SetupTitleSync(player, profile)
	-- 1. BUAT FOLDER & VALUES
	local folder = Instance.new("Folder")
	folder.Name = "GiftTitle"
	folder.Parent = player

	local typeVal = Instance.new("StringValue"); typeVal.Name = "Type"; typeVal.Parent = folder
	local textVal = Instance.new("StringValue"); textVal.Name = "Text"; textVal.Parent = folder
	local colorVal = Instance.new("Color3Value"); colorVal.Name = "Color"; colorVal.Parent = folder
	local fontVal = Instance.new("StringValue"); fontVal.Name = "Font"; fontVal.Parent = folder
	local iconVal = Instance.new("StringValue"); iconVal.Name = "Icon"; iconVal.Parent = folder

	-- 2. MUAT DATA DARI PROFILE KE VALUES
	local roleType = profile.Data.Type or ""
	typeVal.Value = roleType

	-- [KARINA FIX] Konversi Teks Legacy: Ubah "Owner" menjadi "Creator"
	local loadedText = profile.Data.Text or ""
	if roleType == "Owner" and (loadedText == "" or loadedText == "Owner") then
		loadedText = "Creator"
	elseif loadedText == "" then
		loadedText = roleType
	end
	textVal.Value = loadedText

	if typeof(profile.Data.Color) == "table" and #profile.Data.Color == 3 then
		colorVal.Value = Color3.fromRGB(profile.Data.Color[1], profile.Data.Color[2], profile.Data.Color[3])
	else
		colorVal.Value = DEFAULT_COLORS[roleType] or Color3.new(1,1,1)
	end

	fontVal.Value = profile.Data.Font or "GothamBold"
	iconVal.Value = profile.Data.Icon or ICONS[roleType] or ICONS.Custom

	-- 3. SINKRONISASI REAKTIF (VALUES -> PROFILE)
	-- Setiap kali ada script yang merubah nilai di folder ini, datanya langsung ter-save ke memori
	typeVal.Changed:Connect(function(val) profile.Data.Type = val end)
	textVal.Changed:Connect(function(val) profile.Data.Text = val end)
	fontVal.Changed:Connect(function(val) profile.Data.Font = val end)
	iconVal.Changed:Connect(function(val) profile.Data.Icon = val end)
	colorVal.Changed:Connect(function(val) 
		profile.Data.Color = { math.floor(val.R*255), math.floor(val.G*255), math.floor(val.B*255) }
	end)

	-- 4. AUTO-SYNC BASE ROLE (Saat pertama kali join tapi belum punya title)
	player:GetAttributeChangedSignal("BaseRole"):Connect(function()
		local baseRole = player:GetAttribute("BaseRole")
		if baseRole and ICONS[baseRole] then
			if typeVal.Value == "" then
				typeVal.Value = baseRole
				textVal.Value = (baseRole == "Owner") and "Creator" or baseRole
				colorVal.Value = DEFAULT_COLORS[baseRole] or Color3.new(1,1,1)
				fontVal.Value = "GothamBold"
				iconVal.Value = ICONS[baseRole]
			end
		end
	end)
end

----------------------------------------------------
-- 4. PROFILE MANAGEMENT                          --
----------------------------------------------------
local function PlayerAdded(player)
	local profile = TitleStore:LoadProfileAsync("Title_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("\nAltitude System ⚠️\n\nSesi data (Title) telah diambil alih oleh server lain.")
		end)

		if player:IsDescendantOf(Players) == true then
			Profiles[player] = profile
			SetupTitleSync(player, profile)
		else
			profile:Release()
		end
	else
		player:Kick("\nAltitude System ⚠️\n\nGagal memuat data kosmetik karena gangguan server Roblox.")
	end
end

for _, player in ipairs(Players:GetPlayers()) do task.spawn(PlayerAdded, player) end
Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile ~= nil then profile:Release() end
end)

----------------------------------------------------
-- 5. REMOTE COMMANDS (Admin)                     --
----------------------------------------------------
requestEvent.OnServerEvent:Connect(function(sender, action, targetName, titleType, titleText, colorTable, fontName)
	if not sender:GetAttribute("IsAdmin") then
		sendMessage(sender, "❌ Kamu tidak memiliki izin Admin Panel.")
		return
	end

	local target = Players:FindFirstChild(targetName)
	if not target or not target:FindFirstChild("GiftTitle") then
		sendMessage(sender, "❌ Player '" .. targetName .. "' tidak ditemukan atau data belum siap.")
		return
	end

	local folder = target.GiftTitle
	local typeVal, textVal, colorVal = folder.Type, folder.Text, folder.Color
	local fontVal, iconVal = folder.Font, folder.Icon

	if action == "clear" then
		local baseRole = target:GetAttribute("BaseRole")
		if baseRole and ICONS[baseRole] then
			typeVal.Value = baseRole
			textVal.Value = (baseRole == "Owner") and "Creator" or baseRole
			colorVal.Value = DEFAULT_COLORS[baseRole] or Color3.new(1,1,1)
			fontVal.Value = "GothamBold"
			iconVal.Value = ICONS[baseRole]

			local displayInfo = (baseRole == "Owner") and "Creator (Sistem: Owner)" or baseRole
			sendMessage(sender, "✅ Title " .. target.Name .. " di-reset ke identitas aslinya: " .. displayInfo .. ".")
		else
			typeVal.Value = ""
			textVal.Value = ""
			iconVal.Value = ""
			sendMessage(sender, "✅ Title untuk " .. target.Name .. " dihapus sepenuhnya.")
		end
		return
	end

	titleType = tostring(titleType or "")
	if titleType ~= "Streamer" and titleType ~= "Custom" then
		sendMessage(sender, "❌ Akses Ditolak: Panel hanya dapat memberikan title Streamer dan Custom.")
		return
	end

	local finalText
	if titleType == "Custom" then
		finalText = (titleText ~= nil and titleText ~= "") and titleText or "Bestie"

		local lowerText = string.lower(finalText)
		local forbiddenWords = {"owner", "admin", "developer", "dev", "vip", "creator", "pemilik", "moderator", "mod", "staff"}

		for _, word in ipairs(forbiddenWords) do
			if string.match(lowerText, "%f[%a]" .. word .. "%f[%A]") then
				sendMessage(sender, "❌ Ditolak: Kata '" .. word .. "' dilarang keras digunakan pada Custom Title.")
				return
			end
		end
	else
		finalText = titleType
	end

	local finalColor = DEFAULT_COLORS[titleType] or Color3.new(1,1,1)
	if typeof(colorTable) == "table" and #colorTable == 3 then
		finalColor = Color3.fromRGB(colorTable[1], colorTable[2], colorTable[3])
	end

	-- Karena sudah memakai Reactive Sync, mengubah .Value disini akan otomatis menyimpan data ke Profile!
	typeVal.Value  = titleType
	textVal.Value  = finalText
	colorVal.Value = finalColor
	fontVal.Value  = tostring(fontName or "Gotham")
	iconVal.Value  = ICONS[titleType] or ICONS.Custom

	sendMessage(sender, ("✅ Title %s sukses diberikan kepada %s."):format(titleType, target.Name))
end)