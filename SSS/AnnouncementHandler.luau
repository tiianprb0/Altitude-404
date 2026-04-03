--[[
    KARINA - ANNOUNCEMENT SERVER HANDLER (CENTRALIZED ADMIN VERSION)
    Logic: Menggunakan Attribute 'RankLevel' untuk izin akses.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

print("[SERVER] AnnouncementHandler dimulai...")

-- 1. SETUP REMOTE EVENT
local remoteName = "SystemAnnouncementEvent"
local remote = ReplicatedStorage:FindFirstChild(remoteName)
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = ReplicatedStorage
end

-- 2. PERMISSION CHECK (BY ATTRIBUTE)
-- Moderator (Level 1) ke atas boleh kirim pengumuman
local MIN_ANNOUNCE_LEVEL = 1 

local function canAnnounce(player)
	local level = player:GetAttribute("RankLevel") or 0
	return level >= MIN_ANNOUNCE_LEVEL
end

-- 3. HANDLE REQUEST
remote.OnServerEvent:Connect(function(player, messageType, content)
	print("[SERVER] Menerima sinyal dari: " .. player.Name)

	-- Security Check
	if not canAnnounce(player) then
		warn("[SECURITY] Pemain " .. player.Name .. " mencoba mengirim pengumuman tanpa izin!")
		return
	end

	if type(content) ~= "string" or #content == 0 then 
		return 
	end

	-- Text Filtering
	local filteredText = ""
	local success, errorMessage = pcall(function()
		local textObject = TextService:FilterStringAsync(content, player.UserId)
		filteredText = textObject:GetNonChatStringForBroadcastAsync()
	end)

	if not success then
		warn("[SERVER FILTER ERROR] Gagal memfilter teks.")
		filteredText = content 
	end

	-- Kirim ke semua client
	remote:FireAllClients(messageType, player.Name, player.UserId, filteredText)
end)