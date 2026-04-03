-- StarterPlayerScripts > ChatTagsClient
-- Sistem Chat Tags & Verified Icon
-- FIXED by Tian's Discovery: Menggunakan karakter spesial "?" (\uE000) sebagai pengganti gambar.
-- Update: Menghapus spasi antara Nama dan Simbol Verified agar nempel.
-- Update: Logika DNA (BaseRole) untuk mempertahankan Verified Icon.
-- Update: VIP dikeluarkan dari daftar penerima Ceklis Biru.

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- [CONFIG ICON]
-- Menggunakan karakter spesial yang Tian temukan.
-- Kode \u{E000} adalah representasi aman dari simbol "?" di script Lua.
local VERIFIED_SYMBOL = "\u{E000}" 

-- Fungsi bantu: Hex Color
local function toHex(color)
	local r = math.floor(color.R * 255)
	local g = math.floor(color.G * 255)
	local b = math.floor(color.B * 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

-- Fungsi bantu: Format Gambar (Masih dipakai untuk Role Icon di kiri)
local function getImgTag(assetId)
	if not assetId or assetId == "" then return "" end
	local cleanId = tostring(assetId):match("%d+")
	if not cleanId then return "" end
	return string.format('<img src="rbxassetid://%s" height="16" width="16"/>', cleanId)
end

local function onIncomingMessage(message)
	local props = Instance.new("TextChatMessageProperties")

	if message.TextSource then
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)

		if player then
			local giftFolder = player:FindFirstChild("GiftTitle")
			if giftFolder then
				local typeVal = giftFolder:FindFirstChild("Type")
				local textVal = giftFolder:FindFirstChild("Text")
				local colorVal = giftFolder:FindFirstChild("Color")
				local iconVal = giftFolder:FindFirstChild("Icon")

				-- Cek apakah punya Role
				if typeVal and typeVal.Value ~= "" then

					-- [1] LOGIKA SIAPA YANG DAPAT VERIFIED (DNA Based)
					local currentRole = typeVal.Value
					local baseRole = player:GetAttribute("BaseRole")

					-- Daftar role internal yang berhak mendapat ceklis biru di chat
					-- [KARINA FIX] VIP dihapus
					local hardcodedRoles = {
						Owner = true, 
						Developer = true, 
						Admin = true, 
						Moderator = true
					}

					-- Verified muncul jika title saat ini elit, ATAU DNA aslinya (BaseRole) elit
					local showVerified = hardcodedRoles[currentRole] or (baseRole and hardcodedRoles[baseRole]) or false

					-- [2] KOMPONEN TAMPILAN

					-- A. Warna & Teks Title
					local hexColor = "#FFFFFF"
					if colorVal then hexColor = toHex(colorVal.Value) end

					local titleText = currentRole
					if textVal and textVal.Value ~= "" then titleText = textVal.Value end

					-- B. Icon Role (Kiri Nama) - Masih pakai gambar
					local roleIconString = ""
					if iconVal and iconVal.Value ~= "" then
						local tag = getImgTag(iconVal.Value)
						if tag ~= "" then roleIconString = tag .. " " end
					end

					-- C. Verified Icon (Kanan Nama) - PAKAI SIMBOL
					local verifiedString = ""
					if showVerified then
						-- HAPUS SPASI DI SINI: Langsung simbol saja agar menempel pada nama
						verifiedString = VERIFIED_SYMBOL
					end

					-- [3] SUSUN STRING AKHIR
					local titleTag = string.format('<font color="%s"><b>[%s]</b></font>', hexColor, titleText)

					-- Bersihkan nama bawaan
					local rawName = message.PrefixText:gsub("[:%s]+$", "")

					-- FORMAT: [RoleIcon] [Title] [Nama][VerifiedSymbol] :
					-- Perhatikan tidak ada spasi antara rawName dan verifiedString
					props.PrefixText = roleIconString .. titleTag .. " " .. rawName .. verifiedString .. ":"
				end
			end
		end
	end

	return props
end

TextChatService.OnIncomingMessage = onIncomingMessage