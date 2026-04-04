--[[
    KARINA - ALTITUDE ADMIN CORE (V34 - TOOL GLITCH & FREEZE FIX)
    Lokasi: ServerScriptService
    
    PERBAIKAN OLEH KARINA:
    1. ANTI-FREEZE & ERROR: Tool fisik kini hanya dikirimkan ke Backpack, 
       tidak lagi dipaksa masuk ke Character (force-equip) yang menyebabkan 
       Weld dan Script Tool tersebut patah dan mematung.
    2. ARCHITECTURE ALIGNMENT: Menghapus pemasangan paksa ke StarterGear
       dari AdminServer untuk diserahkan sepenuhnya ke Altitude_Role_Manager.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local AdminDS = DataStoreService:GetDataStore("AdminData_V1")
local BanDS = DataStoreService:GetDataStore("BanData_V1")
local LogDS = DataStoreService:GetDataStore("KarinaAdminLogs_V1")

local adminEvent = ReplicatedStorage:FindFirstChild("AltitudeAdminCore") or Instance.new("RemoteEvent", ReplicatedStorage)
adminEvent.Name = "AltitudeAdminCore"

local adminShopRequest = ReplicatedStorage:FindFirstChild("AdminShopRequest") or Instance.new("RemoteEvent", ReplicatedStorage)
adminShopRequest.Name = "AdminShopRequest"

local function sendNotify(player, msg)
	adminEvent:FireClient(player, "Notify", msg)
end

local RANKS = { Owner = 4, HeadAdmin = 3, Admin = 2, Moderator = 1, Player = 0 }
local SUPER_OWNERS = { [9048968760] = true }

local ServerLocked = false 

local JailedPlayers = {} 
local FrozenPlayers = {}
local GodPlayers = {}
local SpeedPlayers = {}
local SizePlayers = {}
local MorphPlayers = {}

Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 5)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hrp or not hum then return end

		task.wait(1) 
		if not player.Character or hum.Health <= 0 then return end

		local uid = player.UserId

		if MorphPlayers[uid] then player:SetAttribute("IsMorphed", true) else player:SetAttribute("IsMorphed", false) end

		if player:GetAttribute("IsVanished") == true then
			task.spawn(function()
				task.wait(0.5) 
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Transparency = 1
						if part.Name == "Head" and part:FindFirstChild("face") then
							part.face.Transparency = 1
						end
					elseif part:IsA("Decal") then
						part.Transparency = 1
					elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") or part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then
						part.Enabled = false
					elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
						part.Enabled = false
					end
				end
			end)
		end

		if JailedPlayers[uid] then
			local oldJail = workspace:FindFirstChild("Jail_" .. player.Name)
			if oldJail then oldJail:Destroy() end
			char:PivotTo(JailedPlayers[uid] * CFrame.new(0, 1.5, 0))
			createJailBox(player, JailedPlayers[uid]) 
		end

		if FrozenPlayers[uid] then
			hrp.Anchored = true
			local ice = Instance.new("Part")
			ice.Name = "IceFreeze"; ice.Size = Vector3.new(4, 6, 4)
			ice.Anchored = true; ice.CanCollide = false; ice.Transparency = 0.4
			ice.BrickColor = BrickColor.new("Cyan"); ice.Material = Enum.Material.Ice
			ice.CFrame = hrp.CFrame
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hrp; weld.Part1 = ice; weld.Parent = ice
			ice.Parent = hrp
		end

		if GodPlayers[uid] then
			hum.MaxHealth = 10000000
			hum.Health = 10000000
		end

		if SpeedPlayers[uid] then
			hum.WalkSpeed = SpeedPlayers[uid]
		end

		if SizePlayers[uid] then
			local scaleVal = SizePlayers[uid]
			local scales = {"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale"}
			for _, s in ipairs(scales) do
				local valObj = hum:FindFirstChild(s)
				if valObj then valObj.Value = scaleVal end
			end
		end

		if MorphPlayers[uid] then
			task.spawn(function()
				local success, hd = pcall(function() return Players:GetHumanoidDescriptionFromUserId(MorphPlayers[uid]) end)
				if success and hd and player.Character and player.Character:FindFirstChild("Humanoid") then 
					player.Character.Humanoid:ApplyDescription(hd) 
				end
			end)
		end
	end)

	local banData = nil
	pcall(function() banData = BanDS:GetAsync("Ban_"..player.UserId) end)
	if banData and type(banData) == "table" and banData.Banned then
		if banData.ExpiresAt and os.time() > banData.ExpiresAt then
			pcall(function() BanDS:RemoveAsync("Ban_"..player.UserId) end)
		else
			local timeStr = banData.ExpiresAt and os.date("!%d/%m/%Y %H:%M", banData.ExpiresAt + (7 * 3600)) .. " WIB" or "Permanen"
			player:Kick("\nAltitude System ⚠️\n\nKamu telah diblokir.\nAlasan: " .. (banData.Reason or "Melanggar aturan.") .. "\nBatas Waktu: " .. timeStr)
			return
		end
	end

	if player:GetAttribute("RankLevel") == nil then
		local rankName, rankLevel = "Player", 0
		if SUPER_OWNERS[player.UserId] then 
			rankName, rankLevel = "Owner", RANKS.Owner 
		else
			pcall(function() rankName = AdminDS:GetAsync("Admin_"..player.UserId) or "Player" end)
			rankLevel = RANKS[rankName] or 0
		end

		player:SetAttribute("Rank", rankName)
		player:SetAttribute("RankLevel", rankLevel)
		player:SetAttribute("IsAdmin", rankLevel > 0)
	end

	task.spawn(function()
		task.wait(1)
		local rLevel = player:GetAttribute("RankLevel") or 0
		if ServerLocked and rLevel < 1 then
			player:Kick("\nAltitude System ⚠️\n\nServer saat ini sedang dikunci oleh Admin.")
		end
	end)

	player.Chatted:Connect(function(msg)
		local lowerMsg = string.lower(msg)
		if lowerMsg == ";unfly" then
			if player:GetAttribute("GrantedFly") then
				player:SetAttribute("GrantedFly", false)
				sendNotify(player, "Akses terbangmu telah dimatikan.")
			end
		elseif lowerMsg == ";bring all" then
			if player:GetAttribute("IsAdmin") then
				local senderChar = player.Character
				local senderHRP = senderChar and senderChar:FindFirstChild("HumanoidRootPart")

				if senderHRP then
					local count = 0
					for _, targetPlayer in ipairs(Players:GetPlayers()) do
						if targetPlayer ~= player then
							task.spawn(function()
								local targetChar = targetPlayer.Character
								local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
								if targetHRP then
									local randomOffset = CFrame.new(math.random(-5, 5), 0, math.random(-5, 5))
									targetChar:PivotTo(senderHRP.CFrame * randomOffset)
								end
							end)
							count = count + 1
						end
					end
					local logEvent = ServerStorage:FindFirstChild("KarinaLogEvent")
					if logEvent then logEvent:Fire(player.Name, "Menarik (Bring All) " .. count .. " pemain ke lokasinya") end
					sendNotify(player, "✅ Berhasil menarik " .. count .. " pemain ke lokasimu.")
				end
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local uid = player.UserId
	JailedPlayers[uid] = nil
	FrozenPlayers[uid] = nil
	GodPlayers[uid] = nil
	SpeedPlayers[uid] = nil
	SizePlayers[uid] = nil
	MorphPlayers[uid] = nil

	local oldJail = workspace:FindFirstChild("Jail_" .. player.Name)
	if oldJail then oldJail:Destroy() end
end)

-- ==========================================
-- 2. SISTEM LOG AKTIVITAS
-- ==========================================
local AdminLogs = {}

pcall(function()
	local savedLogs = LogDS:GetAsync("GlobalLogs")
	if savedLogs then
		for _, log in ipairs(savedLogs) do
			if os.time() - log.Timestamp < 86400 then table.insert(AdminLogs, log) end
		end
	end
end)

local function addLog(adminName, actionDesc)
	local t = os.time()
	local wibTime = t + (7 * 3600) 
	local tStr = os.date("!%H:%M | %d/%m", wibTime) 

	local logEntry = {Timestamp = t, TimeStr = tStr, Admin = adminName, Action = actionDesc}
	table.insert(AdminLogs, 1, logEntry)

	if #AdminLogs > 300 then table.remove(AdminLogs, 301) end 
end

local logEvent = Instance.new("BindableEvent")
logEvent.Name = "KarinaLogEvent"
logEvent.Parent = ServerStorage
logEvent.Event:Connect(function(adminName, actionDesc)
	addLog(adminName, actionDesc)
end)

-- ==========================================
-- 3. FUNGSI EFEK FISIK (JAIL & FREEZE)
-- ==========================================
function createJailBox(targetPlayer, setCFrame)
	local char = targetPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hrp = char.HumanoidRootPart
	local pos = setCFrame and setCFrame.Position or hrp.Position

	char:PivotTo(CFrame.new(pos) * CFrame.new(0, 1.5, 0))

	local oldJail = workspace:FindFirstChild("Jail_" .. targetPlayer.Name)
	if oldJail then oldJail:Destroy() end

	local jailModel = Instance.new("Model")
	jailModel.Name = "Jail_" .. targetPlayer.Name
	local radius = 3.5; local height = 8; local barThickness = 0.4

	local baseFloor = Instance.new("Part")
	baseFloor.Size = Vector3.new(radius * 2.2, 0.4, radius * 2.2)
	baseFloor.Position = pos + Vector3.new(0, -height/2, 0)
	baseFloor.Anchored = true; baseFloor.CanCollide = true
	baseFloor.Material = Enum.Material.WoodPlanks
	baseFloor.Color = Color3.fromRGB(90, 60, 40)
	Instance.new("CylinderMesh", baseFloor)
	baseFloor.Parent = jailModel

	local roof = baseFloor:Clone()
	roof.Position = pos + Vector3.new(0, height/2, 0)
	roof.Parent = jailModel

	local barCount = 14
	for i = 1, barCount do
		local angle = (math.pi * 2 / barCount) * i
		local barX = pos.X + math.cos(angle) * radius
		local barZ = pos.Z + math.sin(angle) * radius

		local bar = Instance.new("Part")
		bar.Size = Vector3.new(barThickness, height, barThickness)
		bar.Position = Vector3.new(barX, pos.Y, barZ)
		bar.Anchored = true; bar.CanCollide = true
		bar.Material = Enum.Material.Wood
		bar.Color = Color3.fromRGB(110, 75, 50)
		Instance.new("CylinderMesh", bar)
		bar.Parent = jailModel
	end
	jailModel.Parent = workspace
	return CFrame.new(pos)
end

local function toggleJail(targetPlayer)
	if JailedPlayers[targetPlayer.UserId] then
		JailedPlayers[targetPlayer.UserId] = nil
		local oldJail = workspace:FindFirstChild("Jail_" .. targetPlayer.Name)
		if oldJail then oldJail:Destroy() end
		return false
	else
		local hrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			JailedPlayers[targetPlayer.UserId] = createJailBox(targetPlayer)
		end
		return true
	end
end

local function toggleFreeze(targetPlayer)
	local char = targetPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if FrozenPlayers[targetPlayer.UserId] then
		FrozenPlayers[targetPlayer.UserId] = nil
		hrp.Anchored = false
		local ice = hrp:FindFirstChild("IceFreeze")
		if ice then ice:Destroy() end
		return false
	else
		FrozenPlayers[targetPlayer.UserId] = true
		hrp.Anchored = true
		local ice = Instance.new("Part")
		ice.Name = "IceFreeze"; ice.Size = Vector3.new(4, 6, 4)
		ice.Anchored = true; ice.CanCollide = false; ice.Transparency = 0.4
		ice.BrickColor = BrickColor.new("Cyan"); ice.Material = Enum.Material.Ice
		ice.CFrame = hrp.CFrame
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp; weld.Part1 = ice; weld.Parent = ice
		ice.Parent = hrp
		return true
	end
end

-- ==========================================
-- 4. JANTUNG EKSEKUSI (EXTRA, DLL)
-- ==========================================
adminEvent.OnServerEvent:Connect(function(sender, category, arg1, arg2, arg3, arg4)
	if not sender:GetAttribute("IsAdmin") then return end
	local senderLevel = sender:GetAttribute("RankLevel") or 0

	if category == "GetLogs" then
		adminEvent:FireClient(sender, "UpdateLogs", AdminLogs)

	elseif category == "Weather" then
		local actionType = arg1
		local cmd = arg2
		local targetName = arg3

		local weatherBindable = ServerStorage:FindFirstChild("KarinaWeatherEvent")
		if not weatherBindable then
			weatherBindable = Instance.new("BindableEvent")
			weatherBindable.Name = "KarinaWeatherEvent"
			weatherBindable.Parent = ServerStorage
		end
		weatherBindable:Fire(sender.Name, actionType, cmd, targetName)

		if actionType == "Global" then
			addLog(sender.Name, "Mengubah cuaca menjadi: " .. cmd)
			sendNotify(sender, "✅ Cuaca berhasil diubah menjadi: " .. cmd)
		elseif actionType == "Target" then
			if targetName and targetName ~= "" then
				addLog(sender.Name, "Menjatuhkan " .. cmd .. " kepada " .. targetName)
				sendNotify(sender, "✅ Berhasil menjatuhkan " .. cmd .. " ke " .. targetName)
			end
		end

	elseif category == "Extra" then
		local cmd = arg1
		local targetName = arg2
		local val = arg3
		local timeVal = arg4

		local noTargetCmds = {Lock = true, Shutdown = true, Restart = true}
		local targetPlayer = nil

		if not noTargetCmds[cmd] then
			targetPlayer = Players:FindFirstChild(targetName)
			if not targetPlayer then sendNotify(sender, "❌ Target tidak valid."); return end

			if targetPlayer then
				local targetLevel = targetPlayer:GetAttribute("RankLevel") or 0
				if targetLevel == 4 and senderLevel < 4 then
					sendNotify(sender, "❌ Ditolak: Kamu tidak memiliki wewenang menargetkan Owner.")
					return
				end
			end
		end

		local targetChar = targetPlayer and targetPlayer.Character
		local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
		local senderHRP = sender.Character and sender.Character:FindFirstChild("HumanoidRootPart")

		if cmd == "Lock" then
			ServerLocked = not ServerLocked
			addLog(sender.Name, ServerLocked and "Mengunci Server" or "Membuka Kunci Server")
			sendNotify(sender, ServerLocked and "✅ Server TERKUNCI. Pemain non-admin tidak akan bisa masuk." or "✅ Server DIBUKA.")

		elseif cmd == "Shutdown" then
			if senderLevel < RANKS.HeadAdmin then sendNotify(sender, "❌ Hanya Developer/Owner yang bisa mematikan Server."); return end
			local reason = (val and val ~= "" and val ~= " ") and val or "Pembaruan/Maintenance."
			addLog(sender.Name, "Melakukan Shutdown Server. Alasan: " .. reason)
			for _, p in pairs(Players:GetPlayers()) do
				p:Kick("\nAltitude System ⚠️\n\nServer sedang dimatikan oleh Admin.\nAlasan: " .. reason)
			end

		elseif cmd == "Restart" then
			if senderLevel < RANKS.HeadAdmin then sendNotify(sender, "❌ Hanya Developer/Owner yang bisa melakukan Restart."); return end
			addLog(sender.Name, "Melakukan Restart Server (Soft-Rejoin)")

			local TeleportService = game:GetService("TeleportService")
			for _, p in pairs(Players:GetPlayers()) do
				task.spawn(function()
					local success = pcall(function() TeleportService:Teleport(game.PlaceId, p) end)
					if not success then
						p:Kick("\nAltitude System ⚠️\n\nServer sedang direstart (Pembaruan Sistem).\nMohon masuk kembali secara manual.")
					end
				end)
			end

		elseif cmd == "Kick" then
			local kickReason = (val and val ~= "" and val ~= " ") and val or "Tidak ada alasan spesifik."
			targetPlayer:Kick("\nAltitude System ⚠️\n\nKamu dikeluarkan (Kick) oleh Admin " .. sender.Name .. "\nAlasan: " .. kickReason)
			addLog(sender.Name, "Mengeluarkan (Kick) " .. targetPlayer.Name .. " - Alasan: " .. kickReason)
			sendNotify(sender, "✅ Berhasil melakukan Kick pada " .. targetPlayer.Name .. ".")

		elseif cmd == "Ban" then
			if senderLevel < RANKS.HeadAdmin then sendNotify(sender, "❌ Hanya Developer/Owner yang bisa Banned."); return end
			local banReason = (val and val ~= "" and val ~= " ") and val or "Melanggar aturan server secara fatal."

			local duration = tonumber(timeVal)
			local expiresAt = nil
			local timeLogMsg = "Permanen"

			if duration and duration > 0 then
				expiresAt = os.time() + (duration * 60)
				timeLogMsg = duration .. " Menit"
			end

			pcall(function() BanDS:SetAsync("Ban_"..targetPlayer.UserId, {Banned = true, Reason = banReason, ExpiresAt = expiresAt}) end)

			local displayTime = expiresAt and os.date("!%d/%m/%Y %H:%M", expiresAt + (7 * 3600)) .. " WIB" or "Permanen"
			targetPlayer:Kick("\nAltitude System ⚠️\n\nKamu telah diblokir oleh Admin " .. sender.Name .. "\nAlasan: " .. banReason .. "\nBatas Waktu: " .. displayTime)
			addLog(sender.Name, "Memblokir (Ban) " .. targetPlayer.Name .. " [" .. timeLogMsg .. "] - Alasan: " .. banReason)
			sendNotify(sender, "✅ " .. targetPlayer.Name .. " telah di-banned (" .. timeLogMsg .. ").")

		elseif cmd == "Vanish" then
			if not targetChar then return end
			local isVanished = targetPlayer:GetAttribute("IsVanished") == true
			local newState = not isVanished
			targetPlayer:SetAttribute("IsVanished", newState)

			for _, part in pairs(targetChar:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Transparency = newState and 1 or 0
					if part.Name == "Head" and part:FindFirstChild("face") then
						part.face.Transparency = newState and 1 or 0
					end
				elseif part:IsA("Decal") then
					part.Transparency = newState and 1 or 0
				elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") or part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then
					part.Enabled = not newState
				elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
					part.Enabled = not newState
				end
			end

			addLog(sender.Name, (newState and "Menghilang (Vanish) " or "Memunculkan (Unvanish) ") .. targetPlayer.Name)
			sendNotify(sender, newState and "✅ " .. targetPlayer.Name .. " sekarang tidak terlihat (Vanish)." or "✅ " .. targetPlayer.Name .. " kembali terlihat.")

		elseif cmd == "Morph" and targetChar and targetHum then
			local targetUsername = val
			if targetUsername == "" or targetUsername == " " then
				task.spawn(function()
					local success, hd = pcall(function() return Players:GetHumanoidDescriptionFromUserId(targetPlayer.UserId) end)
					if success and hd then
						targetHum:ApplyDescription(hd)
						MorphPlayers[targetPlayer.UserId] = nil
						targetPlayer:SetAttribute("IsMorphed", false) 

						task.wait(0.5)
						targetPlayer:SetAttribute("RefreshAura", os.clock())

						addLog(sender.Name, "Mengembalikan wujud asli (Unmorph) " .. targetPlayer.Name)
						sendNotify(sender, "✅ Berhasil mengembalikan wujud asli " .. targetPlayer.Name .. ".")
					else
						sendNotify(sender, "❌ Gagal memuat data wujud asli dari Roblox API.")
					end
				end)
			else
				local morphUserId = nil
				local p = Players:FindFirstChild(targetUsername)
				if p then
					morphUserId = p.UserId
				else
					local success, id = pcall(function() return Players:GetUserIdFromNameAsync(targetUsername) end)
					if success then morphUserId = id end
				end

				if morphUserId then
					task.spawn(function()
						local success, hd = pcall(function() return Players:GetHumanoidDescriptionFromUserId(morphUserId) end)
						if success and hd and targetChar and targetChar:FindFirstChild("Humanoid") then
							targetChar.Humanoid:ApplyDescription(hd)
							MorphPlayers[targetPlayer.UserId] = morphUserId
							targetPlayer:SetAttribute("IsMorphed", true) 

							task.spawn(function()
								task.wait(0.5) 
								targetPlayer:SetAttribute("RefreshAura", os.clock())
							end)
							addLog(sender.Name, "Mengubah wujud (Morph) " .. targetPlayer.Name .. " menjadi " .. targetUsername)
							sendNotify(sender, "✅ Berhasil mengubah (Morph) avatar " .. targetPlayer.Name .. " menjadi " .. targetUsername .. ".")
						else
							sendNotify(sender, "❌ Gagal memuat data avatar " .. targetUsername .. ". (Roblox API Error)")
						end
					end)
				else
					sendNotify(sender, "❌ Username '" .. targetUsername .. "' tidak ditemukan di Roblox.")
				end
			end

		elseif cmd == "Bring" and targetChar and senderHRP then
			targetChar:PivotTo(senderHRP.CFrame * CFrame.new(0, 0, -5))
			addLog(sender.Name, "Menarik (Bring) " .. targetPlayer.Name .. " ke lokasinya")
			sendNotify(sender, "✅ Berhasil menarik " .. targetPlayer.Name .. " ke lokasimu.")
		elseif cmd == "Goto" and sender.Character and targetHRP then
			sender.Character:PivotTo(targetHRP.CFrame * CFrame.new(0, 0, -5))
			addLog(sender.Name, "Beteleportasi (Goto) ke lokasi " .. targetPlayer.Name)
			sendNotify(sender, "✅ Berhasil teleportasi ke lokasi " .. targetPlayer.Name .. ".")
		elseif cmd == "Heal" and targetHum then
			targetHum.Health = targetHum.MaxHealth
			addLog(sender.Name, "Menyembuhkan penuh (Heal) " .. targetPlayer.Name)
			sendNotify(sender, "✅ Berhasil memulihkan darah (Heal) " .. targetPlayer.Name .. ".")
		elseif cmd == "Kill" and targetHum then
			targetHum.Health = 0
			addLog(sender.Name, "Mengeksekusi mati (Kill) " .. targetPlayer.Name)
			sendNotify(sender, "✅ Berhasil mengeksekusi (Kill) " .. targetPlayer.Name .. ".")
		elseif cmd == "GrantFly" and targetPlayer then
			local targetLevel = targetPlayer:GetAttribute("RankLevel") or 0
			if targetLevel > 0 and senderLevel < 4 then
				sendNotify(sender, "❌ Ditolak: Hanya Owner yang bisa mengatur terbang staff.")
				return
			end
			local isFly = targetPlayer:GetAttribute("GrantedFly")
			targetPlayer:SetAttribute("GrantedFly", not isFly)
			if not isFly then
				addLog(sender.Name, "Memberikan akses terbang (Grant Fly) kepada " .. targetPlayer.Name)
				sendNotify(sender, "✅ Izin terbang (Fly) diberikan kepada " .. targetPlayer.Name .. ".")
			else
				addLog(sender.Name, "Mencabut akses terbang (Revoke Fly) dari " .. targetPlayer.Name)
				sendNotify(sender, "✅ Izin terbang (Fly) dicabut dari " .. targetPlayer.Name .. ".")
			end
		elseif cmd == "God" and targetHum then
			if GodPlayers[targetPlayer.UserId] then
				targetHum.MaxHealth = 100; targetHum.Health = 100
				GodPlayers[targetPlayer.UserId] = nil
				addLog(sender.Name, "Mencabut God Mode dari " .. targetPlayer.Name)
				sendNotify(sender, "✅ God Mode dicabut dari " .. targetPlayer.Name .. ".")
			else
				targetHum.MaxHealth = 10000000; targetHum.Health = 10000000
				GodPlayers[targetPlayer.UserId] = true
				addLog(sender.Name, "Mengaktifkan God Mode untuk " .. targetPlayer.Name)
				sendNotify(sender, "✅ God Mode diaktifkan untuk " .. targetPlayer.Name .. ".")
			end
		elseif cmd == "Speed" and targetHum then
			local speedVal = tonumber(val) or 16
			targetHum.WalkSpeed = math.clamp(speedVal, 0, 500) 
			if speedVal == 16 then SpeedPlayers[targetPlayer.UserId] = nil else SpeedPlayers[targetPlayer.UserId] = speedVal end
			addLog(sender.Name, "Mengatur kecepatan (Speed) " .. targetPlayer.Name .. " menjadi " .. speedVal)
			sendNotify(sender, "✅ Kecepatan " .. targetPlayer.Name .. " diatur menjadi " .. tostring(targetHum.WalkSpeed) .. ".")
		elseif cmd == "Size" and targetHum then
			local scaleVal = tonumber(val) or 1
			local scales = {"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale"}
			for _, s in ipairs(scales) do
				local valObj = targetHum:FindFirstChild(s)
				if valObj then valObj.Value = math.clamp(scaleVal, 0.1, 10) end
			end
			if scaleVal == 1 then SizePlayers[targetPlayer.UserId] = nil else SizePlayers[targetPlayer.UserId] = scaleVal end
			addLog(sender.Name, "Mengubah skala ukuran (Size) " .. targetPlayer.Name .. " menjadi " .. scaleVal)
			sendNotify(sender, "✅ Skala ukuran " .. targetPlayer.Name .. " diubah menjadi " .. scaleVal .. ".")
		elseif cmd == "Jail" then
			local isJailed = toggleJail(targetPlayer)
			if isJailed then
				addLog(sender.Name, "Memenjarakan (Jail) " .. targetPlayer.Name)
				sendNotify(sender, "✅ Berhasil memenjarakan " .. targetPlayer.Name .. " di lokasinya.")
			else
				addLog(sender.Name, "Membebaskan (Unjail) " .. targetPlayer.Name)
				sendNotify(sender, "✅ Berhasil membebaskan " .. targetPlayer.Name .. " dari penjara.")
			end
		elseif cmd == "Freeze" then
			local isFrozen = toggleFreeze(targetPlayer)
			if isFrozen then
				addLog(sender.Name, "Membekukan (Freeze) " .. targetPlayer.Name)
				sendNotify(sender, "✅ Berhasil membekukan " .. targetPlayer.Name .. ".")
			else
				addLog(sender.Name, "Mencairkan (Unfreeze) " .. targetPlayer.Name)
				sendNotify(sender, "✅ Berhasil mencairkan " .. targetPlayer.Name .. ".")
			end
		elseif cmd == "Rope" and senderHRP and targetHRP then
			local rope = targetHRP:FindFirstChild("AdminRope")
			if rope then
				rope:Destroy()
				addLog(sender.Name, "Melepaskan ikatan tali (Rope) dari " .. targetPlayer.Name)
				sendNotify(sender, "✅ Ikatan tali pada " .. targetPlayer.Name .. " telah dilepaskan.")
			else
				local att0 = senderHRP:FindFirstChild("RopeAtt") or Instance.new("Attachment", senderHRP); att0.Name = "RopeAtt"
				local att1 = targetHRP:FindFirstChild("RopeAtt") or Instance.new("Attachment", targetHRP); att1.Name = "RopeAtt"
				local r = Instance.new("RopeConstraint"); r.Name = "AdminRope"
				r.Attachment0 = att0; r.Attachment1 = att1; r.Visible = true; r.Length = 15; r.Thickness = 0.2
				r.Parent = targetHRP
				addLog(sender.Name, "Mengikat (Rope) " .. targetPlayer.Name .. " ke dirinya")
				sendNotify(sender, "✅ Berhasil mengikat " .. targetPlayer.Name .. " ke karaktermu.")
			end
		end

	elseif category == "Announce" then
		local sysAnnounce = ReplicatedStorage:FindFirstChild("SystemAnnouncementEvent")
		if sysAnnounce then
			local msgType = (arg1 == "Global") and "GLOBAL" or "SERVER"
			addLog(sender.Name, "Mengirim Pengumuman " .. msgType .. " (" .. arg2 .. ")")
			sysAnnounce:FireAllClients(msgType, sender.Name, sender.UserId, arg2)
			sendNotify(sender, "✅ Pengumuman " .. msgType .. " berhasil dikirim.")
		end

	elseif category == "Summit" then
		local targetPlayer = Players:FindFirstChild(arg2)
		if targetPlayer then
			local targetLevel = targetPlayer:GetAttribute("RankLevel") or 0
			if targetLevel == 4 and senderLevel < 4 then
				sendNotify(sender, "❌ Ditolak: Kamu tidak memiliki wewenang mengedit Summit Owner.")
				return
			end
			local ls = targetPlayer:FindFirstChild("leaderstats")
			local summits = ls and ls:FindFirstChild("Summits")
			if summits then
				local amt = tonumber(arg3) or 1
				amt = math.floor(math.abs(amt))

				if amt <= 0 then 
					sendNotify(sender, "❌ Angka tidak valid.")
					return
				end

				if arg1 == "add" then 
					summits.Value = summits.Value + amt
					addLog(sender.Name, "Menambahkan " .. amt .. " Summit kepada " .. arg2)
					sendNotify(sender, "✅ " .. amt .. " Summit ditambahkan ke " .. arg2 .. ".")
				elseif arg1 == "sub" then 
					summits.Value = math.max(0, summits.Value - amt)
					addLog(sender.Name, "Mengurangi " .. amt .. " Summit dari " .. arg2)
					sendNotify(sender, "✅ " .. amt .. " Summit dikurangi dari " .. arg2 .. ".")
				elseif arg1 == "reset" then 
					summits.Value = 0 
					addLog(sender.Name, "Mereset total Summit " .. arg2 .. " menjadi 0")
					sendNotify(sender, "✅ Summit " .. arg2 .. " berhasil direset.")
				end
			end
		end
	end
end)

-- ==========================================
-- 5. SHOP MANAGER LOGIC
-- ==========================================
adminShopRequest.OnServerEvent:Connect(function(sender, action, targetName, itemType, itemId, amount, itemName)
	local senderLevel = sender:GetAttribute("RankLevel") or 0
	if senderLevel < 1 then
		sendNotify(sender, "❌ Kamu tidak memiliki otoritas untuk fitur Shop ini.")
		return
	end

	local targetPlayer = Players:FindFirstChild(targetName)
	if not targetPlayer then
		sendNotify(sender, "❌ Pemain " .. targetName .. " tidak ditemukan di server.")
		return
	end

	local targetLevel = targetPlayer:GetAttribute("RankLevel") or 0
	if targetLevel == 4 and senderLevel < 4 then
		sendNotify(sender, "❌ Ditolak: Kamu tidak memiliki wewenang memodifikasi Shop Owner.")
		return
	end

	if not targetPlayer:GetAttribute("DataLoaded") then
		sendNotify(sender, "❌ Data " .. targetName .. " belum selesai dimuat. Tunggu sebentar.")
		return
	end

	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")

	local safeItemId = string.gsub(itemId, "%s+", "")

	if action == "Give" then
		if itemType == "Currency" then
			if coins then
				amount = math.floor(math.abs(tonumber(amount) or 0))
				if amount <= 0 then return end

				coins.Value = coins.Value + amount
				sendNotify(sender, "✅ Berhasil memberikan " .. amount .. " " .. itemName .. " ke " .. targetName)
				addLog(sender.Name, "Memberikan " .. amount .. " " .. itemName .. " kepada " .. targetName)
			end

		elseif itemType == "Perk" then
			if targetPlayer:GetAttribute(itemId) == true then
				sendNotify(sender, "⚠️ Ditolak: " .. targetName .. " sudah memiliki akses " .. itemName .. ".")
				return
			end

			targetPlayer:SetAttribute(itemId, true)
			sendNotify(sender, "✅ Berhasil memberikan " .. itemName .. " ke " .. targetName)
			addLog(sender.Name, "Memberikan akses " .. itemName .. " kepada " .. targetName)

		elseif itemType == "Tool" then
			-- [KARINA FIX] Validasi kepemilikan. Jika sudah punya, tolak.
			if targetPlayer:GetAttribute("OwnsTool_" .. safeItemId) then
				sendNotify(sender, "⚠️ Ditolak: " .. targetName .. " sudah memiliki Tool " .. itemName .. " di dalam datanya.")
				return
			end

			local hasPhysicalTool = false
			local bp = targetPlayer:FindFirstChild("Backpack")
			if bp and bp:FindFirstChild(itemId) then hasPhysicalTool = true end
			if targetPlayer.Character and targetPlayer.Character:FindFirstChild(itemId) then hasPhysicalTool = true end

			if hasPhysicalTool then
				targetPlayer:SetAttribute("OwnsTool_" .. safeItemId, true)
				sendNotify(sender, "⚠️ Ditolak: " .. targetName .. " sudah memegang Tool fisik " .. itemName .. ".")
				return
			end

			local toolsFolder = ServerStorage:FindFirstChild("Tools")
			if toolsFolder then
				local toolPrefab = toolsFolder:FindFirstChild(itemId)
				if toolPrefab and toolPrefab:IsA("Tool") then

					-- 1. Catat ke Attribute (Source of Truth untuk disimpan ke ProfileStore)
					targetPlayer:SetAttribute("OwnsTool_" .. safeItemId, true) 

					-- 2. Berikan Fisiknya HANYA ke Backpack. 
					-- DILARANG MENGKLONING LANGSUNG KE CHARACTER KARENA MEMICU GLITCH WELD & SCRIPT.
					if bp then
						toolPrefab:Clone().Parent = bp
					end

					sendNotify(sender, "✅ Berhasil memberikan Tool " .. itemName .. " ke " .. targetName)
					addLog(sender.Name, "Memberikan tool " .. itemName .. " kepada " .. targetName)
				else
					sendNotify(sender, "❌ Tool " .. itemName .. " tidak ditemukan di ServerStorage/Tools.")
				end
			end
		end

	elseif action == "Take" then

		if targetLevel > 0 and (itemType == "Tool" or itemType == "Perk") then
			sendNotify(sender, "⚠️ Ditolak: " .. itemName .. " adalah privilese mutlak bawaan Role/Pangkat dan tidak bisa dirampas.")
			return
		end

		if itemType == "Currency" then
			if coins then
				amount = math.floor(math.abs(tonumber(amount) or 0))
				if amount <= 0 then return end

				coins.Value = math.max(0, coins.Value - amount) 
				sendNotify(sender, "✅ Berhasil menarik " .. amount .. " " .. itemName .. " dari " .. targetName)
				addLog(sender.Name, "Menarik " .. amount .. " " .. itemName .. " dari " .. targetName)
			end

		elseif itemType == "Perk" then
			targetPlayer:SetAttribute(itemId, false)

			if targetPlayer.Character then
				local keyword = string.gsub(itemId, "Has", "")

				for _, desc in pairs(targetPlayer.Character:GetDescendants()) do
					if string.find(string.lower(desc.Name), string.lower(keyword)) then
						desc:Destroy()
					end
				end

				if targetPlayer:GetAttribute("ActiveAura") == keyword then
					targetPlayer:SetAttribute("ActiveAura", "")
				end
			end

			sendNotify(sender, "✅ Berhasil mencabut hak akses " .. itemName .. " dari " .. targetName)
			addLog(sender.Name, "Mencabut akses " .. itemName .. " dari " .. targetName)

		elseif itemType == "Tool" then
			targetPlayer:SetAttribute("OwnsTool_" .. safeItemId, false)

			local found = false

			local bp = targetPlayer:FindFirstChild("Backpack")
			if bp then
				local inBackpack = bp:FindFirstChild(itemId)
				if inBackpack then inBackpack:Destroy(); found = true end
			end

			local starterGear = targetPlayer:FindFirstChild("StarterGear")
			if starterGear then
				local inGear = starterGear:FindFirstChild(itemId)
				if inGear then inGear:Destroy(); found = true end
			end

			if targetPlayer.Character then
				local equippedTool = targetPlayer.Character:FindFirstChild(itemId)
				if equippedTool then equippedTool:Destroy(); found = true end
			end

			if found then
				sendNotify(sender, "✅ Berhasil merampas Tool " .. itemName .. " dari " .. targetName)
				addLog(sender.Name, "Merampas tool " .. itemName .. " dari " .. targetName)
			else
				sendNotify(sender, "⚠️ " .. targetName .. " tidak memiliki fisik " .. itemName .. " (Hanya Atribut yang dihapus)")
			end
		end
	end
end)