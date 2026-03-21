--[[
    KARINA - ALTITUDE ADMIN CORE (V25 - FORCE EQUIP & PHYSICAL DESYNC HOTFIX)
    Lokasi: ServerScriptService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local AdminDS = DataStoreService:GetDataStore("AdminData_V1")
local BanDS = DataStoreService:GetDataStore("BanData_V1")
local LogDS = DataStoreService:GetDataStore("KarinaAdminLogs_V1")

-- [REMOTE EVENTS]
local adminEvent = ReplicatedStorage:FindFirstChild("AltitudeAdminCore")
if not adminEvent then
	adminEvent = Instance.new("RemoteEvent")
	adminEvent.Name = "AltitudeAdminCore"
	adminEvent.Parent = ReplicatedStorage
end

local adminShopRequest = ReplicatedStorage:FindFirstChild("AdminShopRequest")
if not adminShopRequest then
	adminShopRequest = Instance.new("RemoteEvent")
	adminShopRequest.Name = "AdminShopRequest"
	adminShopRequest.Parent = ReplicatedStorage
end

local notificationEvent = ReplicatedStorage:FindFirstChild("GiftTitleResponse")

local function sendNotify(player, msg)
	adminEvent:FireClient(player, "Notify", msg)
end

local function sendNotification(player, message)
	sendNotify(player, message)
end

-- ==========================================
-- 1. HIERARKI RANK & BAN CHECK
-- ==========================================
local RANKS = { Owner = 4, HeadAdmin = 3, Admin = 2, Moderator = 1, Player = 0 }
local SUPER_OWNERS = { [9048968760] = true }

local JailedPlayers = {} 
local FrozenPlayers = {}
local GodPlayers = {}
local SpeedPlayers = {}
local SizePlayers = {}
local MorphPlayers = {}

Players.PlayerAdded:Connect(function(player)
	local isBanned = false
	pcall(function() isBanned = BanDS:GetAsync("Ban_"..player.UserId) end)
	if isBanned then
		player:Kick("\nKamu telah diblokir permanen dari server ini.")
		return
	end

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
							local targetChar = targetPlayer.Character
							local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
							if targetHRP then
								local randomOffset = CFrame.new(math.random(-5, 5), 0, math.random(-5, 5))
								targetHRP.CFrame = senderHRP.CFrame * randomOffset
								count = count + 1
							end
						end
					end

					local logEvent = ServerStorage:FindFirstChild("KarinaLogEvent")
					if logEvent then logEvent:Fire(player.Name, "Menarik (Bring All) " .. count .. " pemain ke lokasinya") end
					sendNotify(player, "✅ Berhasil menarik " .. count .. " pemain ke lokasimu.")
				else
					sendNotify(player, "❌ Karaktermu tidak ditemukan, gagal melakukan Bring All.")
				end
			end
		end
	end)

	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 5)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hrp or not hum then return end

		task.wait(1) 
		if not player.Character or hum.Health <= 0 then return end

		local uid = player.UserId

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
			hum.MaxHealth = math.huge
			hum.Health = math.huge
			local ff = Instance.new("ForceField")
			ff.Visible = false
			ff.Parent = char
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
-- 2. SISTEM LOG AKTIVITAS (GLOBAL BINDABLE)
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

task.spawn(function()
	while task.wait(300) do
		local validLogs = {}
		for _, log in ipairs(AdminLogs) do
			if os.time() - log.Timestamp < 86400 then table.insert(validLogs, log) end
		end
		pcall(function() LogDS:SetAsync("GlobalLogs", validLogs) end)
	end
end)

game:BindToClose(function()
	local validLogs = {}
	for _, log in ipairs(AdminLogs) do
		if os.time() - log.Timestamp < 86400 then table.insert(validLogs, log) end
	end
	pcall(function() LogDS:SetAsync("GlobalLogs", validLogs) end)
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
adminEvent.OnServerEvent:Connect(function(sender, category, arg1, arg2, arg3, arg4, arg5, arg6)
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

		local targetPlayer = Players:FindFirstChild(targetName)
		if not targetPlayer and cmd ~= "Morph" then sendNotify(sender, "❌ Target tidak valid."); return end

		if targetPlayer then
			local targetLevel = targetPlayer:GetAttribute("RankLevel") or 0
			if targetLevel == 4 and senderLevel < 4 then
				sendNotify(sender, "❌ Ditolak: Kamu tidak memiliki wewenang menargetkan Owner.")
				return
			end
		end

		local targetChar = targetPlayer and targetPlayer.Character
		local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
		local senderHRP = sender.Character and sender.Character:FindFirstChild("HumanoidRootPart")

		if cmd == "Kick" then
			targetPlayer:Kick("\nDikick oleh Admin " .. sender.Name .. "\nAlasan: " .. tostring(val))
			addLog(sender.Name, "Mengeluarkan (Kick) " .. targetPlayer.Name .. " - Alasan: " .. tostring(val))
			sendNotify(sender, "✅ Berhasil melakukan Kick pada " .. targetPlayer.Name .. ".")
		elseif cmd == "Ban" then
			if senderLevel < RANKS.HeadAdmin then sendNotify(sender, "❌ Hanya HeadAdmin+ yang bisa Banned."); return end
			pcall(function() BanDS:SetAsync("Ban_"..targetPlayer.UserId, true) end)
			targetPlayer:Kick("\nKamu telah diblokir permanen oleh Admin " .. sender.Name)
			addLog(sender.Name, "Memblokir permanen (Ban) " .. targetPlayer.Name)
			sendNotify(sender, "✅ " .. targetPlayer.Name .. " telah di-banned secara permanen.")
		elseif cmd == "Bring" and targetHRP and senderHRP then
			targetHRP.CFrame = senderHRP.CFrame * CFrame.new(0, 0, -5)
			addLog(sender.Name, "Menarik (Bring) " .. targetPlayer.Name .. " ke lokasinya")
			sendNotify(sender, "✅ Berhasil menarik " .. targetPlayer.Name .. " ke lokasimu.")
		elseif cmd == "Goto" and targetHRP and senderHRP then
			senderHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -5)
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
			if targetHum.MaxHealth > 100 then
				targetHum.MaxHealth = 100; targetHum.Health = 100
				GodPlayers[targetPlayer.UserId] = nil
				local ff = targetChar:FindFirstChildOfClass("ForceField")
				if ff then ff:Destroy() end
				addLog(sender.Name, "Mencabut God Mode dari " .. targetPlayer.Name)
				sendNotify(sender, "✅ God Mode dicabut dari " .. targetPlayer.Name .. ".")
			else
				targetHum.MaxHealth = math.huge; targetHum.Health = math.huge
				local ff = Instance.new("ForceField")
				ff.Visible = false
				ff.Parent = targetChar
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
		elseif cmd == "Morph" and sender.Character and sender.Character:FindFirstChild("Humanoid") then
			local targetUsername = val
			local targetUserId = nil
			local p = Players:FindFirstChild(targetUsername)
			if p then
				targetUserId = p.UserId
			else
				local success, id = pcall(function() return Players:GetUserIdFromNameAsync(targetUsername) end)
				if success then targetUserId = id end
			end
			if targetUserId then
				task.spawn(function()
					local success, hd = pcall(function() return Players:GetHumanoidDescriptionFromUserId(targetUserId) end)
					if success and hd and sender.Character and sender.Character:FindFirstChild("Humanoid") then
						sender.Character.Humanoid:ApplyDescription(hd)
						MorphPlayers[sender.UserId] = targetUserId
						task.spawn(function()
							task.wait(0.5) 
							sender:SetAttribute("RefreshAura", os.clock())
						end)
						addLog(sender.Name, "Mengubah wujud (Morph) menjadi " .. targetUsername)
						sendNotify(sender, "✅ Berhasil meniru (Morph) avatar " .. targetUsername .. ".")
					else
						sendNotify(sender, "❌ Gagal memuat data avatar " .. targetUsername .. ". (Roblox API Error)")
					end
				end)
			else
				sendNotify(sender, "❌ Username '" .. targetUsername .. "' tidak ditemukan di Roblox.")
			end
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
				r.Attachment0 = att0; r.Attachment1 = att1; r.Visible = true; r.Length = 10; r.Thickness = 0.2
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
-- 5. SHOP MANAGER LOGIC (PHYSICAL FIX)
-- ==========================================
adminShopRequest.OnServerEvent:Connect(function(sender, action, targetName, itemType, itemId, amount, itemName)
	local senderLevel = sender:GetAttribute("RankLevel") or 0
	if senderLevel < 1 then
		sendNotification(sender, "❌ Kamu tidak memiliki otoritas untuk fitur Shop ini.")
		return
	end

	local targetPlayer = Players:FindFirstChild(targetName)
	if not targetPlayer then
		sendNotification(sender, "❌ Pemain " .. targetName .. " tidak ditemukan di server.")
		return
	end

	local targetLevel = targetPlayer:GetAttribute("RankLevel") or 0
	if targetLevel == 4 and senderLevel < 4 then
		sendNotification(sender, "❌ Ditolak: Kamu tidak memiliki wewenang memodifikasi Shop Owner.")
		return
	end

	if not targetPlayer:GetAttribute("DataLoaded") then
		sendNotification(sender, "❌ Data " .. targetName .. " belum selesai dimuat. Tunggu sebentar.")
		return
	end

	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")

	local safeItemId = string.gsub(itemId, "%s+", "")

	if action == "Give" then
		if itemType == "Currency" then
			if coins then
				coins.Value = coins.Value + amount
				sendNotification(sender, "✅ Berhasil memberikan " .. amount .. " " .. itemName .. " ke " .. targetName)
				addLog(sender.Name, "Memberikan " .. amount .. " " .. itemName .. " kepada " .. targetName)
			end

		elseif itemType == "Perk" then
			if targetPlayer:GetAttribute(itemId) == true then
				sendNotification(sender, "⚠️ Ditolak: " .. targetName .. " sudah memiliki akses " .. itemName .. ".")
				return
			end

			targetPlayer:SetAttribute(itemId, true)
			sendNotification(sender, "✅ Berhasil memberikan " .. itemName .. " ke " .. targetName)
			addLog(sender.Name, "Memberikan akses " .. itemName .. " kepada " .. targetName)

		elseif itemType == "Tool" then
			if targetPlayer:GetAttribute("OwnsTool_" .. safeItemId) then
				sendNotification(sender, "⚠️ Ditolak: " .. targetName .. " sudah memiliki Tool " .. itemName .. " di dalam datanya.")
				return
			end

			local hasPhysicalTool = false
			local bp = targetPlayer:FindFirstChild("Backpack")
			if bp and bp:FindFirstChild(itemId) then hasPhysicalTool = true end
			if targetPlayer.Character and targetPlayer.Character:FindFirstChild(itemId) then hasPhysicalTool = true end

			if hasPhysicalTool then
				targetPlayer:SetAttribute("OwnsTool_" .. safeItemId, true)
				sendNotification(sender, "⚠️ Ditolak: " .. targetName .. " sudah memegang Tool " .. itemName .. ".")
				return
			end

			local toolsFolder = ServerStorage:FindFirstChild("Tools")
			if toolsFolder then
				local toolPrefab = toolsFolder:FindFirstChild(itemId)
				if toolPrefab and toolPrefab:IsA("Tool") then

					targetPlayer:SetAttribute("OwnsTool_" .. safeItemId, true) 

					-- [KARINA FIX] Force Equip: Jika karakter hidup, letakkan langsung di tangan.
					local starterGear = targetPlayer:FindFirstChild("StarterGear")
					if starterGear then toolPrefab:Clone().Parent = starterGear end

					if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") and targetPlayer.Character.Humanoid.Health > 0 then
						toolPrefab:Clone().Parent = targetPlayer.Character
					elseif bp then
						toolPrefab:Clone().Parent = bp
					end

					sendNotification(sender, "✅ Berhasil memberikan Tool " .. itemName .. " ke " .. targetName)
					addLog(sender.Name, "Memberikan tool " .. itemName .. " kepada " .. targetName)
				else
					sendNotification(sender, "❌ Tool " .. itemName .. " tidak ditemukan di ServerStorage/Tools.")
				end
			end
		end

	elseif action == "Take" then
		if itemType == "Currency" then
			if coins then
				coins.Value = math.max(0, coins.Value - amount) 
				sendNotification(sender, "✅ Berhasil menarik " .. amount .. " " .. itemName .. " dari " .. targetName)
				addLog(sender.Name, "Menarik " .. amount .. " " .. itemName .. " dari " .. targetName)
			end

		elseif itemType == "Perk" then
			targetPlayer:SetAttribute(itemId, false)
			sendNotification(sender, "✅ Berhasil mencabut hak akses " .. itemName .. " dari " .. targetName)
			addLog(sender.Name, "Mencabut akses " .. itemName .. " dari " .. targetName)

		elseif itemType == "Tool" then
			targetPlayer:SetAttribute("OwnsTool_" .. safeItemId, false)

			local found = false

			-- [KARINA FIX] Menghapus dengan toleransi pengecekan Backpack yang lebih baik
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
				sendNotification(sender, "✅ Berhasil merampas Tool " .. itemName .. " dari " .. targetName)
				addLog(sender.Name, "Merampas tool " .. itemName .. " dari " .. targetName)
			else
				sendNotification(sender, "⚠️ " .. targetName .. " tidak memiliki fisik " .. itemName .. " (Hanya Atribut yang dihapus)")
			end
		end
	end
end)