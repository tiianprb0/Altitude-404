local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- --- REFERENSI OBJEK ---
local button = script.Parent 
local icon = button:WaitForChild("iconRun") 
local player = Players.LocalPlayer

-- --- KONFIGURASI ---
local NORMAL_SPEED = 11
local RUN_SPEED = 16
local NORMAL_FOV = 70
local RUN_FOV = 85

-- State (Status Lari)
local isSprinting = false
local coilListener = nil
local wsConnection = nil
local renderConnection = nil
local WS = nil

-- Variabel untuk transisi kamera manual
local currentFOV = NORMAL_FOV
local targetFOV = NORMAL_FOV

-- --- FUNGSI VISUAL (ANIMASI) ---
local function updateVisuals()
	if isSprinting then
		TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.2}):Play()
		TweenService:Create(icon, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(0, 0, 0)}):Play()
	else
		TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5}):Play()
		TweenService:Create(icon, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end
end

-- --- MANAJER KECEPATAN ---
local function updateSpeed()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local coilBoost = character:GetAttribute("CoilBoost") or 0
	local baseSpeed = isSprinting and RUN_SPEED or NORMAL_SPEED

	humanoid.WalkSpeed = baseSpeed + coilBoost
end

-- --- INISIALISASI WEAPONS SYSTEM ---
local function initWeaponsSystem()
	local wsFolder = ReplicatedStorage:WaitForChild("WeaponsSystem", 5)
	if wsFolder and wsFolder:FindFirstChild("WeaponsSystem") then
		pcall(function()
			WS = require(wsFolder.WeaponsSystem)
			-- Pastikan koneksi lama dibersihkan sebelum membuat yang baru
			if wsConnection then wsConnection:Disconnect() end

			wsConnection = WS.CurrentWeaponChanged:Connect(function()
				if WS and WS.camera then
					WS.camera.fieldOfView = targetFOV
				end
			end)
		end)
	end
end
task.spawn(initWeaponsSystem)

-- --- MANAJER KAMERA ABSOLUT ---
local function startCameraManager()
	if renderConnection then renderConnection:Disconnect() end

	renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
		local camera = workspace.CurrentCamera
		if not camera then return end

		targetFOV = isSprinting and RUN_FOV or NORMAL_FOV

		if WS and WS.camera and WS.camera.enabled then
			WS.camera.fieldOfView = targetFOV
		else
			currentFOV = currentFOV + (targetFOV - currentFOV) * math.min(1, deltaTime * 8)
			camera.FieldOfView = currentFOV
		end
	end)
end

-- --- LOGIKA UTAMA TEP TEP ---
local function toggleSprint()
	isSprinting = not isSprinting
	updateVisuals()
	updateSpeed()
end
button.Activated:Connect(toggleSprint)

-- --- LIFECYCLE KARAKTER & CLEANUP ---
local function cleanupPreviousCharacter()
	if coilListener then 
		coilListener:Disconnect()
		coilListener = nil
	end
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	-- wsConnection tidak dibersihkan di sini karena terhubung ke modul global,
	-- melainkan ditimpa di fungsi initWeaponsSystem jika dipanggil ulang.
end

local function onCharacterAdded(character)
	cleanupPreviousCharacter()

	isSprinting = false
	currentFOV = NORMAL_FOV
	updateVisuals()
	updateSpeed()
	startCameraManager()

	coilListener = character:GetAttributeChangedSignal("CoilBoost"):Connect(updateSpeed)
end

-- Pastikan cleanup berjalan jika karakter dihancurkan (mati/reset)
player.CharacterRemoving:Connect(cleanupPreviousCharacter)

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)