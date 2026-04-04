	--[[
	    NAMA FILE: DeathEffect.client.lua
	    LOKASI: StarterPlayer -> StarterPlayerScripts
	    
	    DESKRIPSI:
	    Script ini membuat layar menjadi Hitam Putih saat mati.
	    
	    UPDATE (DYNAMIC TRACKING & TELEPORT SYNC):
	    - Mengganti TweenService statis dengan RenderStepped agar kamera 
	      secara dinamis mengikuti HRP yang jatuh/bergerak (menghilangkan patahan 'tertinggal').
	    - Menambahkan sinkronisasi waktu tunggu untuk memastikan CheckpointSystem 
	      selesai melakukan teleportasi sebelum layar hitam diangkat.
	    - [KARINA UPDATE] Menambahkan sistem First-Spawn Bypass agar tidak 
	      bertabrakan dengan CinematicLoader saat pertama kali masuk ke permainan.
	]]

	local Players = game:GetService("Players")
	local Lighting = game:GetService("Lighting")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService") 
	local Workspace = game:GetService("Workspace")
	local StarterGui = game:GetService("StarterGui")

	local player = Players.LocalPlayer
	local camera = Workspace.CurrentCamera

	-- 1. KITA BUAT EFEKNYA DULU
	local deathEffect = Instance.new("ColorCorrectionEffect")
	deathEffect.Name = "KarinaDeathEffect"
	deathEffect.Parent = Lighting
	deathEffect.Enabled = false 
	deathEffect.Saturation = 0 
	deathEffect.Contrast = 0 
	deathEffect.Brightness = 0

	-- Konfigurasi Visual
	local DEAD_SATURATION = -1   -- Hitam Putih total
	local DEAD_CONTRAST = 0.2    -- Sedikit kontras
	local DEAD_BRIGHTNESS = -1   -- Gelap Gulita untuk menyembunyikan perpindahan lokasi
	local FADE_TIME = 0.5        -- Waktu transisi warna

	-- Konfigurasi Waktu & Kamera
	local LANDING_SPEED = 1.5    -- Durasi kamera turun dari langit ke punggung (detik)
	local CAM_HEIGHT = 14        -- Tinggi kamera saat mati (Top Down)
	local CAM_FOV_ZOOM = 45      -- FOV saat mati (Zoom In)
	local LANDING_DIST = 12      -- Jarak kamera di belakang punggung
	local LANDING_UP = 2.5       -- Tinggi kamera dari root part

	-- Variabel Status
	local fovTween
	local renderConn
	local isDead = false
	local isFirstSpawn = true -- Penanda untuk spawn pertama kali di server

	-- Fungsi menyalakan efek mati (Grayscale + Zoom)
	local function enableDeathVisuals(character)
		isDead = true
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)

		deathEffect.Enabled = true
		deathEffect.Brightness = 0 -- Pastikan mulai dari kecerahan normal
		TweenService:Create(deathEffect, TweenInfo.new(FADE_TIME), {Saturation = DEAD_SATURATION, Contrast = DEAD_CONTRAST}):Play()

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.FieldOfView = 70 

			local targetPos = hrp.Position + Vector3.new(0, CAM_HEIGHT, 0)
			camera.CFrame = CFrame.new(targetPos, hrp.Position)

			fovTween = TweenService:Create(camera, TweenInfo.new(Players.RespawnTime - 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = CAM_FOV_ZOOM})
			fovTween:Play()
		end
	end

	-- Fungsi transisi turun (Landing) yang Dinamis dan Real-time
	local function playLandingAnimation(newCharacter)
		local hrp = newCharacter:WaitForChild("HumanoidRootPart", 5)
		local humanoid = newCharacter:WaitForChild("Humanoid", 5)
		if not hrp or not humanoid then return end

		-- Kunci Limit Zoom Kamera Roblox sementara
		player.CameraMinZoomDistance = LANDING_DIST
		player.CameraMaxZoomDistance = LANDING_DIST
		camera.CameraType = Enum.CameraType.Scriptable

		-- Angkat tirai hitam perlahan
		TweenService:Create(deathEffect, TweenInfo.new(LANDING_SPEED * 0.8), {Saturation = 0, Contrast = 0, Brightness = 0}):Play()

		local elapsed = 0
		local startHeight = CAM_HEIGHT + 15

		if renderConn then renderConn:Disconnect() end

		-- DYNAMIC TRACKING: Mengikuti karakter ke mana pun ia bergerak selama 1.5 detik
		renderConn = RunService.RenderStepped:Connect(function(dt)
			if not hrp or not hrp.Parent or humanoid.Health <= 0 then
				if renderConn then renderConn:Disconnect() end
				return
			end

			elapsed = elapsed + dt
			local alpha = math.min(elapsed / LANDING_SPEED, 1)

			-- Easing Quint Out (Melambat di akhir pendaratan)
			local easeAlpha = TweenService:GetValue(alpha, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

			-- Update posisi karakter SECARA REAL-TIME (Mengatasi masalah "tertinggal")
			local currentPos = hrp.Position
			local backDir = -hrp.CFrame.LookVector 

			-- Kalkulasi target punggung yang terus bergeser jika karakter jalan/jatuh
			local targetPos = currentPos + (backDir * LANDING_DIST) + Vector3.new(0, LANDING_UP, 0)
			local lookAtPos = currentPos + Vector3.new(0, 1.5, 0)
			local idealEndCFrame = CFrame.new(targetPos, lookAtPos)

			-- Posisi langit selalu berada persis di atas karakter saat ini
			local startPos = currentPos + Vector3.new(0, startHeight, 0)
			local idealStartCFrame = CFrame.new(startPos, currentPos)

			-- Lakukan Interpolasi
			camera.CFrame = idealStartCFrame:Lerp(idealEndCFrame, easeAlpha)
			camera.FieldOfView = 70

			-- Jika animasi pendaratan selesai
			if alpha >= 1 then
				renderConn:Disconnect()
				if humanoid.Health > 0 then
					camera.CameraType = Enum.CameraType.Custom
					camera.CameraSubject = humanoid

					-- Kembalikan batas zoom normal secara perlahan agar bebas dikontrol pemain
					task.delay(0.1, function()
						player.CameraMinZoomDistance = 0.5 
						player.CameraMaxZoomDistance = 400 
					end)
				end

				pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)

				task.delay(FADE_TIME, function()
					if not isDead then deathEffect.Enabled = false end
				end)
			end
		end)
	end

	-- LOGIKA UTAMA SIKLUS HIDUP KARAKTER
	local function onCharacterAdded(character)
		isDead = false
		if fovTween then fovTween:Cancel() end
		if renderConn then renderConn:Disconnect() end

		local isInitialSpawn = isFirstSpawn
		isFirstSpawn = false -- Matikan penanda agar respawn berikutnya bisa melakukan pendaratan kamera

		-- SINKRONISASI TELEPORT: Tunggu CheckpointSystem selesai bekerja
		task.spawn(function()
			-- Bypas logika kamera pendaratan jika ini adalah spawn pertama saat player join.
			-- Biarkan CinematicLoader bekerja tanpa interupsi.
			if isInitialSpawn then return end 

			-- 0.6 detik sengaja diberikan untuk melampaui task.wait(0.5) di CheckpointSystem
			task.wait(0.6) 

			while not player:GetAttribute("DataLoaded") do
				task.wait(0.1)
			end

			-- Beri 1 frame tambahan agar fisik Roblox selesai memproses PivotTo() teleport
			RunService.Heartbeat:Wait() 

			-- Sekarang posisi karakter SUDAH di checkpoint. Tirai hitam aman untuk dibuka.
			if character and character.Parent then
				playLandingAnimation(character)
			end
		end)

		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			-- Mulai visual kematian (Kamera naik & Grayscale)
			enableDeathVisuals(character)

			-- Tunggu sampai sesaat (0.2 detik) sebelum pemain benar-benar respawn
			local waitBeforeBlackout = math.max(0, Players.RespawnTime - FADE_TIME - 0.2)
			task.wait(waitBeforeBlackout)

			-- Turunkan "Tirai Hitam" agar perpindahan kamera/teleportasi tidak terlihat pemain
			if isDead then
				TweenService:Create(deathEffect, TweenInfo.new(FADE_TIME), {Brightness = DEAD_BRIGHTNESS}):Play()
			end
		end)
	end

	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end