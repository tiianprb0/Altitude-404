--[[
    Altitude 404: Client Earthquake Visuals
    Refined by Karina for Christian John Benaya Purba (Tian)
    
    Perbaikan Kritis:
    - FIX: Pathing SinyalGempa disesuaikan dengan hierarki Folder terbaru.
    - FIX: OverlapParams di-cache di luar loop untuk mencegah Memory Leak.
    - REVERT: Mengembalikan logika guncangan kamera (math.random + CFrame) sesuai preferensi pragmatis Tian.
    - FIX: Menggunakan WaitForChild untuk Lampu dan Debu agar client tidak kehilangan objek.
    - FIX (NEW): Merombak logika jalankanLogikaLampu menjadi sistem Flicker acak (Korsleting) agar lebih realistis.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- === FIX 1: HIERARKI YANG BENAR ===
local FolderGempa = ReplicatedStorage:WaitForChild("Gempa", 10)
if not FolderGempa then warn("Karina: Folder Gempa tidak ditemukan!") return end

local SinyalGempa = FolderGempa:WaitForChild("SinyalGempa", 10)
if not SinyalGempa then warn("Karina: SinyalGempa tidak ditemukan!") return end

-- === MENCARI FOLDER DAN OBJEK ===
local folderUtama = Workspace:WaitForChild("FolderSistemGempa", 10)
if not folderUtama then return end

local areaGempa = folderUtama:WaitForChild("AreaGempa", 10)
local suaraGemuruh = folderUtama:WaitForChild("SuaraGemuruh", 10)

-- FIX: Menggunakan WaitForChild agar client sabar menunggu objek termuat
local folderLampu = folderUtama:WaitForChild("LampuGempa", 10)
local partDebu = folderUtama:WaitForChild("DebuGempa", 10)

-- === KONFIGURASI EFEK ===
local kekuatanGuncangan = 0.6 -- Dikembalikan ke settingan asli Tian
local volumeAsli = suaraGemuruh and suaraGemuruh.Volume or 0.5

local gempaSedangAktif = false
local pemainDiDalamArea = false 

-- === FIX 2: CACHE OVERLAP PARAMS ===
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include

local function cekPemainDiDalamArea()
	local character = player.Character
	if not character then return false end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Cukup update target filternya saja
	overlapParams.FilterDescendantsInstances = {character}

	local partsInArea = Workspace:GetPartsInPart(areaGempa, overlapParams)
	for _, part in pairs(partsInArea) do
		if part == rootPart then return true end
	end
	return false
end

local function dapatkanSemuaLampu()
	if not folderLampu then return {} end
	local lights = {}
	for _, obj in pairs(folderLampu:GetDescendants()) do
		if obj:IsA("Light") then 
			table.insert(lights, obj)
		end
	end
	return lights
end

local function jalankanLogikaLampu()
	local lights = dapatkanSemuaLampu()
	task.spawn(function()
		while gempaSedangAktif do
			if pemainDiDalamArea then
				-- FIX: Efek Flicker Korsleting Realistis
				for _, light in pairs(lights) do 
					-- 40% kemungkinan lampu menyala, 60% kemungkinan mati (Kesan lampu kewalahan)
					light.Enabled = (math.random(1, 100) <= 40)
				end

				-- Jeda waktu diacak sangat cepat (antara 0.05 detik hingga 0.25 detik)
				-- Ini menciptakan efek kedip yang organik dan tidak berpola
				task.wait(math.random(5, 25) / 100)
			else
				-- Jika pemain di luar area, lampu menyala stabil
				for _, light in pairs(lights) do 
					light.Enabled = true 
				end
				task.wait(0.2) -- Jeda stabil agar tidak membebani CPU
			end
		end

		-- SAFETY NET: Pastikan semua menyala kembali saat gempa usai
		for _, light in pairs(lights) do
			light.Enabled = true
		end
	end)
end

local tweenAudio 
local function aturAudio(aktif)
	if not suaraGemuruh then return end
	if tweenAudio then tweenAudio:Cancel() end

	if aktif then
		if not suaraGemuruh.Playing then suaraGemuruh:Play() end
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
		tweenAudio = TweenService:Create(suaraGemuruh, tweenInfo, {Volume = volumeAsli})
		tweenAudio:Play()
	else
		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear)
		tweenAudio = TweenService:Create(suaraGemuruh, tweenInfo, {Volume = 0})
		tweenAudio:Play()
	end
end

local function efekDebu(aktif)
	if not partDebu then return end
	for _, child in pairs(partDebu:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = aktif
		end
	end
end

-- === FUNGSI UTAMA (SESI GEMPA) ===
local function mulaiSesiGempa()
	if gempaSedangAktif then return end
	gempaSedangAktif = true

	local durasiAcak = math.random(10, 20)
	local waktuMulai = tick()
	local statusTerakhir = false 

	local waktuCekTerakhir = 0
	local intervalCek = 0.1 

	print("Karina: Sesi Gempa Global dimulai selama " .. durasiAcak .. " detik.")

	jalankanLogikaLampu()

	if suaraGemuruh then 
		suaraGemuruh.Volume = 0 
		suaraGemuruh.TimePosition = 0
		suaraGemuruh:Play()
	end

	RunService:BindToRenderStep("EfekGempaCamera", Enum.RenderPriority.Camera.Value + 1, function()
		local saatIni = tick()

		if saatIni - waktuMulai >= durasiAcak then
			RunService:UnbindFromRenderStep("EfekGempaCamera")
			gempaSedangAktif = false
			efekDebu(false)
			aturAudio(false)

			task.delay(2, function() if suaraGemuruh then suaraGemuruh:Stop() end end)
			print("Karina: Sesi Gempa Selesai.")
			return
		end

		if saatIni - waktuCekTerakhir >= intervalCek then
			waktuCekTerakhir = saatIni
			pemainDiDalamArea = cekPemainDiDalamArea()

			if pemainDiDalamArea ~= statusTerakhir then
				aturAudio(pemainDiDalamArea)
				efekDebu(pemainDiDalamArea)
				statusTerakhir = pemainDiDalamArea
			end
		end

		-- Logika Asli Tian: Guncangan Kamera menggunakan math.random
		if pemainDiDalamArea then
			local x = (math.random() - 0.5) * kekuatanGuncangan
			local y = (math.random() - 0.5) * kekuatanGuncangan
			local z = (math.random() - 0.5) * kekuatanGuncangan
			camera.CFrame = camera.CFrame * CFrame.new(x, y, z)
		end
	end)
end

SinyalGempa.OnClientEvent:Connect(mulaiSesiGempa)