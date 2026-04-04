local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local cam = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local pocongFolder = ReplicatedStorage:WaitForChild("Pocong", 10)
if not pocongFolder then return end

local scareEvent = pocongFolder:WaitForChild("PocongScareEvent", 10)
if not scareEvent then return end

local screamSoundId = "rbxassetid://133889228934156"
local heartbeatSoundId = "rbxassetid://2828628043"
local jumpscareImageId = "rbxassetid://100987804421325" -- Menggunakan Texture ID yang kamu berikan

scareEvent.OnClientEvent:Connect(function()
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local playerRoot = char:FindFirstChild("HumanoidRootPart")

	--------------------------------
	-- 1. INSTANT SHOCK: GRAYSCALE & PINGSAN
	--------------------------------
	-- Buat player langsung jatuh pingsan secara instan
	if humanoid then
		humanoid.PlatformStand = true 
	end

	-- Efek visual layar jadi hitam putih (Grayscale)
	local color = Instance.new("ColorCorrectionEffect")
	color.Saturation = -1
	color.Brightness = -0.3
	color.Parent = Lighting

	--------------------------------
	-- 2. MUNCULKAN JUMPSCARE DECAL (2D UI)
	--------------------------------
	local scareGui = Instance.new("ScreenGui")
	scareGui.Name = "PocongJumpscareUI"
	scareGui.IgnoreGuiInset = true -- Mengabaikan topbar Roblox agar full screen
	scareGui.DisplayOrder = 999 -- Pastikan berada di atas UI lain

	local scareImage = Instance.new("ImageLabel")
	scareImage.Size = UDim2.new(1, 0, 1, 0)
	scareImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	scareImage.AnchorPoint = Vector2.new(0.5, 0.5)
	scareImage.BackgroundTransparency = 1
	scareImage.Image = jumpscareImageId
	scareImage.ScaleType = Enum.ScaleType.Fit -- Fit agar proporsi gambar pocong tidak gepeng
	scareImage.Parent = scareGui
	scareGui.Parent = playerGui

	--------------------------------
	-- 3. CAMERA SHAKE & SCREAM
	--------------------------------
	local connection
	local shakeIntensity = 0.5
	local timeElapsed = 0

	-- Guncangan UI dan Kamera untuk menambah efek kacau
	connection = RunService.RenderStepped:Connect(function(deltaTime)
		timeElapsed += deltaTime * 30
		local shakeX = math.noise(timeElapsed, 0, 0) * shakeIntensity
		local shakeY = math.noise(0, timeElapsed, 0) * shakeIntensity

		-- Guncang UI
		scareImage.Position = UDim2.new(0.5 + (shakeX * 0.05), 0, 0.5 + (shakeY * 0.05), 0)

		-- Guncang Kamera sedikit
		cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(shakeX), math.rad(shakeY), 0)
	end)

	local scream = Instance.new("Sound")
	scream.SoundId = screamSoundId
	scream.Volume = 3 
	scream.Parent = workspace
	scream:Play()

	-- Durasi gambar menempel di layar
	task.wait(2.5) 

	--------------------------------
	-- 4. JUMPSCARE HILANG, TERSISA PINGSAN
	--------------------------------
	connection:Disconnect()
	scareGui:Destroy()
	scream:Destroy()

	local heartbeat = Instance.new("Sound")
	heartbeat.SoundId = heartbeatSoundId
	heartbeat.Volume = 2
	heartbeat.Looped = true
	heartbeat.Parent = workspace
	heartbeat:Play()

	-- Durasi player tidak sadar di tanah (layar masih hitam putih)
	task.wait(2)

	--------------------------------
	-- 5. BANGUN & WARNA KEMBALI NORMAL
	--------------------------------
	if humanoid then
		humanoid.PlatformStand = false -- Kembalikan kontrol player
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	-- Transisi warna kembali normal secara perlahan
	for i = 1, 40 do
		color.Saturation += (1 / 40)
		color.Brightness += (0.3 / 40)
		heartbeat.Volume -= (2 / 40)
		task.wait(0.05)
	end

	color:Destroy()
	heartbeat:Destroy()
end)