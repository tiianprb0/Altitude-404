--[[
    KARINA - NOTIFICATION RECEIVER (LOGIC ONLY)
    Lokasi: StarterPlayerScripts (Atau StarterGui)
    Catatan: Membutuhkan "Notification Bar" di dalam PlayerGui.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- :: REFERENSI UI ::
local notifGui = PlayerGui:WaitForChild("Notification Bar", 10)
local bg = notifGui:WaitForChild("Background")

local icon = bg:WaitForChild("imageProfile")
local nameLabel = bg:WaitForChild("name")
local typeLabel = bg:WaitForChild("typeANN")
local contentLabel = bg:WaitForChild("isi")

-- :: KONFIGURASI POSISI ::
local HIDDEN_POS = UDim2.new(0.5, 0, 0, -200)
local SHOW_POS = UDim2.new(0.5, 0, 0, 40)

-- :: SETUP AUDIO ::
local notifSound = Instance.new("Sound")
notifSound.Name = "NotifSound"
notifSound.SoundId = "rbxassetid://135272730546427"
notifSound.Volume = 1
notifSound.Parent = bg

-- Setup State Awal (Sembunyikan saat game baru mulai)
bg.Position = HIDDEN_POS
bg.Visible = false

-- :: ANIMATION & EVENT LOGIC ::
local remote = ReplicatedStorage:WaitForChild("SystemAnnouncementEvent")

local tweenInfoIn = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenInfoOut = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local isShowing = false

remote.OnClientEvent:Connect(function(msgType, senderName, senderId, message)
	-- Auto-Wake ScreenGui jika dalam kondisi Disabled
	if not notifGui.Enabled then
		notifGui.Enabled = true
	end

	if isShowing then 
		bg.Position = HIDDEN_POS
		bg.Visible = false
	end
	isShowing = true

	-- Logika Display Name: Cek apakah player masih ada di server, jika ya pakai DisplayName, jika tidak fallback ke senderName
	local senderPlayer = Players:GetPlayerByUserId(senderId)
	local displayName = senderPlayer and senderPlayer.DisplayName or senderName

	-- Update Teks
	typeLabel.Text = string.upper(msgType .. " ANNOUNCE")
	nameLabel.Text = displayName
	contentLabel.Text = message

	-- Load Thumbnail (Async)
	task.spawn(function()
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size100x100
		local success, thumb = pcall(function() 
			return Players:GetUserThumbnailAsync(senderId, thumbType, thumbSize)
		end)
		if success and icon then icon.Image = thumb end
	end)

	-- Mainkan Animasi Masuk & Audio
	bg.Visible = true
	notifSound:Play()
	local tweenIn = TweenService:Create(bg, tweenInfoIn, {Position = SHOW_POS})
	tweenIn:Play()

	-- Tahan di layar selama 6 detik
	task.wait(6)

	-- Mainkan Animasi Keluar
	local tweenOut = TweenService:Create(bg, tweenInfoOut, {Position = HIDDEN_POS})
	tweenOut:Play()

	tweenOut.Completed:Wait()
	bg.Visible = false
	isShowing = false
end)