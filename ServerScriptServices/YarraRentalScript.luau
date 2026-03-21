--[[
    YARRA RENTAL SCRIPT (SERVER)
    Perbaikan Karina: 
    1. Menghapus JetGroup sepenuhnya.
    2. Integrasi akses JetSolo untuk VIP dan pembeli Gamepass (50 Robux).
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ChatService = game:GetService("Chat")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RentalSystem = script.Parent

-- --- SETUP REMOTE EVENT ---
local cameraEvent = ReplicatedStorage:FindFirstChild("YarraCameraEvent")
if not cameraEvent then
	cameraEvent = Instance.new("RemoteEvent")
	cameraEvent.Name = "YarraCameraEvent"
	cameraEvent.Parent = ReplicatedStorage
end

-- --- REFERENSI ---
local NPC = RentalSystem:WaitForChild("Yarraa", 10)
if not NPC then warn("CRITICAL: Model 'Yarraa' tidak ketemu!") return end

local SpawnPointPart = RentalSystem:WaitForChild("SpawnPoint", 10)
if not SpawnPointPart then warn("CRITICAL: Part 'SpawnPoint' tidak ketemu!") return end

local Humanoid = NPC:WaitForChild("Humanoid", 10)
local Animator = Humanoid and Humanoid:WaitForChild("Animator", 5)

local JetskiFolder = ServerStorage:WaitForChild("Jetski", 10)
if not JetskiFolder then warn("CRITICAL: Folder 'Jetski' tidak ketemu!") return end

local npcHead = NPC:FindFirstChild("Head")
local npcTorso = NPC:FindFirstChild("UpperTorso") or NPC:FindFirstChild("Torso")
local isR15 = Humanoid.RigType == Enum.HumanoidRigType.R15

-- PERBAIKAN ANCHOR
for _, part in ipairs(NPC:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = (part.Name == "HumanoidRootPart")
	end
end

-- --- KONFIGURASI ---
-- TIAN: Ganti angka ini dengan ID Gamepass JetSolo milikmu (harga 50 Robux)
local JETSOLO_GAMEPASS = 12345678 

local ANIM_IDLE = "rbxassetid://507766388"
local ANIM_WAVE = "rbxassetid://507770239" 
local LOOK_RADIUS = 15

local ADMIN_IDS = {
	[game.CreatorId] = true,
}

local activeSessions = {} 
local spawnedVehicles = {} 

local function speak(message)
	if npcHead then
		ChatService:Chat(npcHead, message, Enum.ChatColor.White)
	end
end

local function isUserAdmin(player)
	return ADMIN_IDS[player.UserId] or false
end

-- --- FUNGSI PEMBERSIHAN KENDARAAN ---
local function removeVehicle(userId)
	if spawnedVehicles[userId] then
		if spawnedVehicles[userId].Instance and spawnedVehicles[userId].Instance.Parent then
			spawnedVehicles[userId].Instance:Destroy()
		end
		if spawnedVehicles[userId].DespawnTask then
			task.cancel(spawnedVehicles[userId].DespawnTask)
		end
		spawnedVehicles[userId] = nil 
	end
end

-- --- LOGIKA CEK AKSES KENDARAAN (VIP & GAMEPASS) ---
local function getPlayerAccess(player)
	-- Cek apakah dia admin, sudah punya attribute JetSolo, ATAU seorang VIP
	local hasAccess = isUserAdmin(player) or player:GetAttribute("HasJetSolo") == true or player:GetAttribute("HasVIP") == true

	local access = {
		HasJetSolo = hasAccess
	}

	-- Jika belum punya akses, cek ke Roblox Marketplace (apakah dia beli gamepass?)
	if not access.HasJetSolo then
		pcall(function()
			if MarketplaceService:UserOwnsGamePassAsync(player.UserId, JETSOLO_GAMEPASS) then
				access.HasJetSolo = true
				player:SetAttribute("HasJetSolo", true)
			end
		end)
	end

	return access
end

-- --- LOGIKA SPAWN KENDARAAN ---
local function spawnSelectedVehicle(player, vehicleName)
	removeVehicle(player.UserId)

	local template = JetskiFolder:FindFirstChild(vehicleName)
	if not template then 
		speak("Maaf, " .. vehicleName .. " sedang tidak tersedia.")
		return 
	end

	speak("Ini dia " .. vehicleName .. " kamu, " .. player.DisplayName .. "!")

	local newVehicle = template:Clone()
	newVehicle:SetAttribute("OwnerId", player.UserId)
	newVehicle:SetAttribute("OwnerName", player.Name)

	local driverSeat = newVehicle:FindFirstChild("VehicleSeat", true) or newVehicle:FindFirstChildOfClass("VehicleSeat")
	if driverSeat then newVehicle.PrimaryPart = driverSeat end

	newVehicle:PivotTo(SpawnPointPart.CFrame * CFrame.new(0, 5, 0))
	newVehicle.Parent = workspace

	spawnedVehicles[player.UserId] = {
		Instance = newVehicle,
		HasBeenMounted = false,
		DespawnTask = nil
	}

	local vehData = spawnedVehicles[player.UserId]

	vehData.DespawnTask = task.delay(15, function()
		if not vehData.HasBeenMounted then
			removeVehicle(player.UserId)
			speak("Kendaraan " .. player.DisplayName .. " ditarik karena tidak digunakan.")
		end
	end)

	if driverSeat then
		driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local occupant = driverSeat.Occupant
			if occupant then
				local char = occupant.Parent
				local driver = Players:GetPlayerFromCharacter(char)

				if driver then
					if driver.UserId == player.UserId then
						vehData.HasBeenMounted = true
						if vehData.DespawnTask then
							task.cancel(vehData.DespawnTask)
							vehData.DespawnTask = nil
						end
					else
						occupant.Jump = true
						speak("Maaf " .. driver.DisplayName .. ", kemudi ini khusus untuk " .. player.DisplayName .. ". Silakan duduk di bangku penumpang.")
					end
				else
					occupant.Jump = true 
				end
			else
				if vehData.DespawnTask then task.cancel(vehData.DespawnTask) end
				vehData.DespawnTask = task.delay(30, function()
					removeVehicle(player.UserId)
					speak("Kendaraan " .. player.DisplayName .. " ditarik kembali ke dermaga.")
				end)
			end
		end)
	end
end

-- --- MENERIMA SINYAL DARI CLIENT ---
cameraEvent.OnServerEvent:Connect(function(player, action, data)
	if action == "SpawnVehicle" then
		activeSessions[player.UserId] = nil

		local access = getPlayerAccess(player)
		if data == "JetSolo" and not access.HasJetSolo then return end

		spawnSelectedVehicle(player, data)

	elseif action == "EndSession" then
		activeSessions[player.UserId] = nil
	end
end)

-- --- PEMBUATAN TANDA SERU (!) ---
local questMarker = nil
if npcHead then
	questMarker = Instance.new("BillboardGui")
	questMarker.Name = "QuestMarker"
	questMarker.Size = UDim2.new(1.5, 0, 1.5, 0)
	questMarker.ExtentsOffset = Vector3.new(-1.2, 1.5, -0.5) 
	questMarker.AlwaysOnTop = true

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "!"
	textLabel.TextColor3 = Color3.new(1, 0, 0.1) 
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.Rotation = -15 
	textLabel.Parent = questMarker

	questMarker.Parent = npcHead
end

-- --- LOGIKA PROMPT & INTERAKSI ---
local rootPart = NPC:FindFirstChild("HumanoidRootPart") or npcTorso

if rootPart and Animator then
	local waveAnimObj = Instance.new("Animation")
	waveAnimObj.AnimationId = ANIM_WAVE
	local waveTrack = Animator:LoadAnimation(waveAnimObj)
	waveTrack.Looped = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Yarra"      
	prompt.ActionText = "Sewa Kendaraan" 
	prompt.HoldDuration = 0.5        
	prompt.MaxActivationDistance = 10
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.Parent = rootPart

	local hasWaved = false

	prompt.PromptShown:Connect(function()
		if not hasWaved then
			hasWaved = true
			waveTrack:Play()
		end
	end)

	prompt.PromptHidden:Connect(function()
		hasWaved = false
	end)

	prompt.Triggered:Connect(function(player)
		if activeSessions[player.UserId] then return end
		activeSessions[player.UserId] = true

		if questMarker then
			questMarker:Destroy()
			questMarker = nil
		end

		speak("Halo " .. player.DisplayName .. "! Mau sewa apa hari ini?")

		if npcHead then cameraEvent:FireClient(player, "StartPOV", npcHead) end

		task.wait(5)

		if not player.Parent then return end 

		local accessData = getPlayerAccess(player)
		cameraEvent:FireClient(player, "EndPOVAndShowGUI", accessData)
	end)
end

-- --- LOGIKA HEAD TRACKING ---
local neckJoint = nil
if npcHead then neckJoint = npcHead:FindFirstChild("Neck") end
if not neckJoint and npcTorso then neckJoint = npcTorso:FindFirstChild("Neck") end

if neckJoint then
	local originalC0 = neckJoint.C0

	RunService.Heartbeat:Connect(function()
		local closestPlayer = nil
		local shortestDistance = LOOK_RADIUS 
		local playerHead = nil

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
				local distance = (char.HumanoidRootPart.Position - rootPart.Position).Magnitude
				if distance <= shortestDistance then
					shortestDistance = distance
					closestPlayer = char.HumanoidRootPart
					playerHead = char.Head
				end
			end
		end

		if closestPlayer and playerHead then
			local relativeDir = rootPart.CFrame:PointToObjectSpace(playerHead.Position)
			local yaw = math.atan2(-relativeDir.X, -relativeDir.Z) 
			local pitch = math.asin(relativeDir.Y / relativeDir.Magnitude) 

			yaw = math.clamp(yaw, -math.rad(60), math.rad(60))
			pitch = math.clamp(pitch, -math.rad(45), math.rad(45))

			if isR15 then
				local targetC0 = originalC0 * CFrame.Angles(pitch, yaw, 0)
				neckJoint.C0 = neckJoint.C0:Lerp(targetC0, 0.1)
			else
				local targetC0 = originalC0 * CFrame.Angles(0, -yaw, 0) * CFrame.Angles(pitch, 0, 0)
				neckJoint.C0 = neckJoint.C0:Lerp(targetC0, 0.1)
			end
		else
			if neckJoint.C0 ~= originalC0 then
				neckJoint.C0 = neckJoint.C0:Lerp(originalC0, 0.1)
			end
		end
	end)
end

-- --- MANAJEMEN PEMAIN KELUAR ---
Players.PlayerRemoving:Connect(function(player)
	removeVehicle(player.UserId)
	activeSessions[player.UserId] = nil
end)

-- --- SETUP VISUAL & ANIMASI IDLE ---
if Humanoid then
	Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
end

if Animator then
	local animObj = Instance.new("Animation")
	animObj.AnimationId = ANIM_IDLE
	local track = Animator:LoadAnimation(animObj)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Idle
	track:Play()
end