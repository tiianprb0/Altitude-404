-- ServerScriptService.GiftTitleServer
-- Sistem gift title + Auto Fix Icon Image ID + Security Filter + Smart Reset & Auto Sync
-- Diperbarui oleh Karina: Display Text "Owner" diubah menjadi "Creator" (Termasuk menimpa data lama di DataStore)
-- Update: Filter kata terlarang berlaku mutlak untuk semua pemain.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local titleStore = DataStoreService:GetDataStore("GiftTitles")

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

local requestEvent = ReplicatedStorage:FindFirstChild("GiftTitleRequest")
if not requestEvent then
	requestEvent = Instance.new("RemoteEvent")
	requestEvent.Name = "GiftTitleRequest"
	requestEvent.Parent = ReplicatedStorage
end

local responseEvent = ReplicatedStorage:FindFirstChild("GiftTitleResponse")
if not responseEvent then
	responseEvent = Instance.new("RemoteEvent")
	responseEvent.Name = "GiftTitleResponse"
	responseEvent.Parent = ReplicatedStorage
end

local function sendMessage(player, text)
	responseEvent:FireClient(player, text)
end

----------------------------------------------------
-- 3. CORE FUNCTIONS (LOAD & SAVE)                --
----------------------------------------------------

local function getOrCreateGiftFolder(player)
	local folder = player:FindFirstChild("GiftTitle")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GiftTitle"
		folder.Parent = player
	end

	local function checkVal(name, cls)
		local v = folder:FindFirstChild(name)
		if not v then
			v = Instance.new(cls)
			v.Name = name
			v.Parent = folder
		end
		return v
	end

	return folder, 
	checkVal("Type", "StringValue"),
	checkVal("Text", "StringValue"),
	checkVal("Color", "Color3Value"),
	checkVal("Font", "StringValue"),
	checkVal("Icon", "StringValue")
end

local function saveTitleToStore(player)
	local folder = player:FindFirstChild("GiftTitle")
	if not folder then return end

	local typeVal  = folder:FindFirstChild("Type")
	local textVal  = folder:FindFirstChild("Text")
	local colorVal = folder:FindFirstChild("Color")
	local fontVal  = folder:FindFirstChild("Font")
	local iconVal  = folder:FindFirstChild("Icon")

	if not (typeVal and textVal and colorVal and fontVal and iconVal) then return end

	if typeVal.Value == "" then
		pcall(function()
			titleStore:RemoveAsync("user_" .. player.UserId)
		end)
		return
	end

	local c = colorVal.Value
	local data = {
		Type  = typeVal.Value,
		Text  = textVal.Value,
		Color = { math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255) },
		Font  = fontVal.Value,
		Icon  = iconVal.Value,
	}

	pcall(function()
		titleStore:SetAsync("user_" .. player.UserId, data)
	end)
end

local function loadTitleFromStore(player)
	local folder, typeVal, textVal, colorVal, fontVal, iconVal = getOrCreateGiftFolder(player)

	-- Auto-Sync BaseRole (Hanya berjalan jika DataStore kosong/belum ada Type)
	player:GetAttributeChangedSignal("BaseRole"):Connect(function()
		local baseRole = player:GetAttribute("BaseRole")
		if baseRole and ICONS[baseRole] then
			if typeVal.Value == "" then
				typeVal.Value = baseRole
				-- [KARINA] Manipulasi visual: Jika Owner, tampilkan Creator
				textVal.Value = (baseRole == "Owner") and "Creator" or baseRole
				colorVal.Value = DEFAULT_COLORS[baseRole] or Color3.new(1,1,1)
				fontVal.Value = "GothamBold"
				iconVal.Value = ICONS[baseRole]
			end
		end
	end)

	local success, data = pcall(function()
		return titleStore:GetAsync("user_" .. player.UserId)
	end)

	if success and data then
		local roleType = data.Type or ""
		typeVal.Value = roleType

		-- [KARINA FIX] Paksa konversi teks lama di database. 
		-- Jika datastore menyimpan teks "Owner", kita paksa ubah menjadi "Creator".
		local loadedText = data.Text or ""
		if roleType == "Owner" and (loadedText == "" or loadedText == "Owner") then
			loadedText = "Creator"
		elseif loadedText == "" then
			loadedText = roleType
		end

		textVal.Value = loadedText

		if data.Color and typeof(data.Color) == "table" then
			colorVal.Value = Color3.fromRGB(data.Color[1], data.Color[2], data.Color[3])
		else
			colorVal.Value = DEFAULT_COLORS[roleType] or Color3.new(1,1,1)
		end

		fontVal.Value = data.Font or "GothamBold"
		iconVal.Value = ICONS[roleType] or data.Icon or ICONS.Custom
	else
		typeVal.Value = ""
		colorVal.Value = Color3.new(1,1,1)
	end
end

----------------------------------------------------
-- 4. EVENT HANDLERS                              --
----------------------------------------------------

Players.PlayerAdded:Connect(loadTitleFromStore)
Players.PlayerRemoving:Connect(saveTitleToStore)

for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(function() loadTitleFromStore(plr) end)
end

----------------------------------------------------
-- 5. REMOTE COMMANDS (Admin)                     --
----------------------------------------------------
requestEvent.OnServerEvent:Connect(function(sender, action, targetName, titleType, titleText, colorTable, fontName)
	if not sender:GetAttribute("IsAdmin") then
		sendMessage(sender, "❌ Kamu tidak memiliki izin Admin Panel.")
		return
	end

	local target = Players:FindFirstChild(targetName)
	if not target then
		sendMessage(sender, "❌ Player '" .. targetName .. "' tidak ditemukan di server.")
		return
	end

	local folder, typeVal, textVal, colorVal, fontVal, iconVal = getOrCreateGiftFolder(target)

	if action == "clear" then
		local baseRole = target:GetAttribute("BaseRole")
		if baseRole and ICONS[baseRole] then
			typeVal.Value = baseRole
			-- [KARINA] Terapkan logika Creator saat Admin menghapus Custom Title
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
		saveTitleToStore(target)
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

		-- [KARINA FIX] Pencabutan hak istimewa. Filter kata terlarang kini berlaku mutlak untuk SEMUA ORANG tanpa terkecuali.
		local lowerText = string.lower(finalText)
		local forbiddenWords = {"owner", "admin", "developer", "dev", "vip", "creator", "pemilik", "moderator", "mod", "staff"}

		for _, word in ipairs(forbiddenWords) do
			-- Menggunakan Frontier Pattern %f[%a] agar hanya mendeteksi kata utuh (menghindari false positive)
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

	typeVal.Value  = titleType
	textVal.Value  = finalText
	colorVal.Value = finalColor
	fontVal.Value  = tostring(fontName or "Gotham")
	iconVal.Value  = ICONS[titleType] or ICONS.Custom

	saveTitleToStore(target)
	sendMessage(sender, ("✅ Title %s sukses diberikan kepada %s."):format(titleType, target.Name))
end)