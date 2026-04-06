--[[
    Altitude 404: Client Earthquake Visuals
    Refined by ESKA
    
    PERBAIKAN ECA:
    - FIX: Sinkronisasi waktu gempa (durasi kini dikendalikan penuh oleh Server).
    - OPTIMASI MEMORI: Menghapus OverlapParams. Pengecekan zona kini 
      menggunakan kalkulasi matematis AABB (PointToObjectSpace) yang 
      memiliki 0 biaya komputasi fisika, membuatnya sangat ringan untuk CPU.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local FolderGempa = ReplicatedStorage:WaitForChild("Gempa", 10)
if not FolderGempa then return end

local SinyalGempa = FolderGempa:WaitForChild("SinyalGempa", 10)
if not SinyalGempa then return end

local folderUtama = Workspace:WaitForChild("FolderSistemGempa", 10)
if not folderUtama then return end

local areaGempa = folderUtama:WaitForChild("AreaGempa", 10)
local suaraGemuruh = folderUtama:WaitForChild("SuaraGemuruh", 10)
local folderLampu = folderUtama:WaitForChild("LampuGempa", 10)
local partDebu = folderUtama:WaitForChild("DebuGempa", 10)

local kekuatanGuncangan = 0.6
local volumeAsli = suaraGemuruh and suaraGemuruh.Volume or 0.5

local gempaSedangAktif = false
local pemainDiDalamArea = false 

-- [ECA OPTIMASI] Kalkulasi AABB (Matematika Murni, Tanpa Beban Fisika)
local function cekPemainDiDalamArea()
	local character = player.Character
	if not character then return false end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not areaGempa then return false end

	-- Mengonversi posisi pemain menjadi titik koordinat lokal terhadap AreaGempa
	local localPoint = areaGempa.CFrame:PointToObjectSpace(rootPart.Position)
	local halfSize = areaGempa.Size / 2

	-- Mengecek apakah titik tersebut berada di dalam batas (X, Y, Z) dari balok
	if math.abs(localPoint.X) <= halfSize.X and
		math.abs(localPoint.Y) <= halfSize.Y and
		math.abs(localPoint.Z) <= halfSize.Z then
		return true
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
				-- Efek Flicker Korsleting Realistis
				for _, light in pairs(lights) do 
					light.Enabled = (math.random(1, 100) <= 40)
				end
				task.wait(math.random(5, 25) / 100)
			else
				for _, light in pairs(lights) do 
					light.Enabled = true 
				end
				task.wait(0.2) 
			end
		end

		-- SAFETY NET
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

-- [ECA FIX] Menerima durasi absolut dari argumen Server
local function mulaiSesiGempa(durasiDariServer)
	if gempaSedangAktif then return end
	gempaSedangAktif = true

	local durasiGempa = durasiDariServer or 15
	local waktuMulai = tick()
	local statusTerakhir = false 

	local waktuCekTerakhir = 0
	local intervalCek = 0.1 

	print("[ESKA SYSTEM] Sesi Gempa Global disinkronisasi selama " .. durasiGempa .. " detik.")

	jalankanLogikaLampu()

	if suaraGemuruh then 
		suaraGemuruh.Volume = 0 
		suaraGemuruh.TimePosition = 0
		suaraGemuruh:Play()
	end

	RunService:BindToRenderStep("EfekGempaCamera", Enum.RenderPriority.Camera.Value + 1, function()
		local saatIni = tick()

		if saatIni - waktuMulai >= durasiGempa then
			RunService:UnbindFromRenderStep("EfekGempaCamera")
			gempaSedangAktif = false
			efekDebu(false)
			aturAudio(false)

			task.delay(2, function() if suaraGemuruh then suaraGemuruh:Stop() end end)
			print("[ESKA SYSTEM] Sesi Gempa Selesai.")
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

		if pemainDiDalamArea then
			local x = (math.random() - 0.5) * kekuatanGuncangan
			local y = (math.random() - 0.5) * kekuatanGuncangan
			local z = (math.random() - 0.5) * kekuatanGuncangan
			camera.CFrame = camera.CFrame * CFrame.new(x, y, z)
		end
	end)
end

SinyalGempa.OnClientEvent:Connect(mulaiSesiGempa)