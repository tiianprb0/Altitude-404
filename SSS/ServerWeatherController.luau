--[[
    SERVER WEATHER CONTROLLER (KARINA UPDATE v58 - PRISTINE SKY FIX)
    - Mengembalikan integrasi penuh dengan Admin Panel (KarinaWeatherEvent).
    - Memperbaiki logika Acid Rain agar benar-benar memberikan damage.
    - Menggunakan RaycastParams global & Sistem Pengecekan Folder (Pohon/Gubuk).
    - UPDATE (KARINA): Menetralisir "Phantom Atmosphere" di awal script. Jika map asli tidak punya 
      Atmosphere, script tidak akan merekam kabut sisa sebagai setelan "Cerah".
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Defaults = {
	Lighting = {},
	Atmosphere = {}
}

local function setupAndCapture()
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atm then
		atm = Instance.new("Atmosphere")
		atm.Name = "WeatherAtmosphere"
		-- KARINA FIX: Netralisir objek baru agar nilainya tidak berbekas saat cerah
		atm.Density = 0
		atm.Offset = 0
		atm.Haze = 0
		atm.Glare = 0
		atm.Parent = Lighting
	end

	Defaults.Lighting = {
		Brightness = Lighting.Brightness,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Ambient = Lighting.Ambient,
		FogColor = Lighting.FogColor,
		FogEnd = Lighting.FogEnd,
		ClockTime = Lighting.ClockTime
	}

	Defaults.Atmosphere = {
		Density = atm.Density,
		Offset = atm.Offset,
		Color = atm.Color, 
		Decay = atm.Decay, 
		Glare = atm.Glare,
		Haze = atm.Haze
	}
	return atm
end

local Atmosphere = setupAndCapture() 

local ADMIN_USERS = { "tiianprb", "Player1" } 
local BURNT_DURATION = 30 
local RAIN_DAMAGE_PERCENT = 5    
local RAIN_DAMAGE_INTERVAL = 1   

Lighting:SetAttribute("AllowAcid", true) 
Lighting:SetAttribute("AllowDroplets", true) 

if Lighting:GetAttribute("AllowDrizzle") == nil then Lighting:SetAttribute("AllowDrizzle", true) end
if Lighting:GetAttribute("AllowNormal") == nil then Lighting:SetAttribute("AllowNormal", true) end
if Lighting:GetAttribute("AllowStorm") == nil then Lighting:SetAttribute("AllowStorm", true) end
if Lighting:GetAttribute("AllowFog") == nil then Lighting:SetAttribute("AllowFog", true) end
if Lighting:GetAttribute("AllowLightningVisual") == nil then Lighting:SetAttribute("AllowLightningVisual", true) end 
if Lighting:GetAttribute("AllowLightningStrike") == nil then Lighting:SetAttribute("AllowLightningStrike", true) end 

if Lighting:GetAttribute("IsRaining") == nil then Lighting:SetAttribute("IsRaining", false) end
if Lighting:GetAttribute("IsAcidRain") == nil then Lighting:SetAttribute("IsAcidRain", false) end
if Lighting:GetAttribute("IsFoggy") == nil then Lighting:SetAttribute("IsFoggy", false) end
if Lighting:GetAttribute("RainType") == nil then Lighting:SetAttribute("RainType", "None") end 

local acidRemote = ReplicatedStorage:FindFirstChild("AcidRainEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
acidRemote.Name = "AcidRainEvent"

local warningRemote = ReplicatedStorage:FindFirstChild("WeatherWarningEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
warningRemote.Name = "WeatherWarningEvent"

local autoCycle = true
local currentLoopId = 0 
local lastChosenState = "None"

local serverRayParams = RaycastParams.new()
serverRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function darkenColor(color, factor)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, v * factor)
end

local function findPlayer(namePartial)
	if not namePartial then return nil end
	namePartial = string.lower(namePartial)
	for _, p in pairs(Players:GetPlayers()) do
		if string.find(string.lower(p.Name), namePartial) or string.find(string.lower(p.DisplayName), namePartial) then
			return p
		end
	end
	return nil
end

local function hasUmbrella(character)
	if not character then return false end
	for _, obj in pairs(character:GetChildren()) do
		if obj:IsA("Tool") then
			local name = string.lower(obj.Name)
			if string.find(name, "payung") or string.find(name, "umbrella") then
				return true
			end
		end
	end
	return false
end

local function isProtected(character)
	if hasUmbrella(character) then return true end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return true end 

	serverRayParams.FilterDescendantsInstances = {character} 
	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, 60, 0), serverRayParams)

	if result then
		local hitPart = result.Instance
		local current = hitPart

		local isPohon = false
		local isGubuk = false

		while current and current ~= workspace do
			if current:GetAttribute("tembusHujan") == true then
				return false 
			end

			local lowerName = string.lower(current.Name)
			if string.find(lowerName, "pohon") then
				isPohon = true
			elseif string.find(lowerName, "gubuk") then
				isGubuk = true
			end

			current = current.Parent
		end

		if isPohon then return false end
		if isGubuk then return true end

		return (result.Material ~= Enum.Material.LeafyGrass and result.Material ~= Enum.Material.Water)
	end
	return false 
end

local function setRainyWeather(intensityType)
	intensityType = intensityType or "Normal"
	Lighting:SetAttribute("RainType", intensityType)
	Lighting:SetAttribute("IsFoggy", false) 

	local isAcid = false
	if intensityType == "Storm" and Lighting:GetAttribute("AllowAcid") then
		isAcid = true
	end

	Lighting:SetAttribute("IsAcidRain", isAcid)

	if isAcid then 
		warningRemote:FireAllClients("RAIN_WARNING") 
	end

	local transDuration = (intensityType == "Storm" and 25) or (intensityType == "Normal" and 18) or 12
	local tweenInfo = TweenInfo.new(transDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local targetLighting = {}
	local targetAtmosphere = {}

	if intensityType == "Drizzle" then
		targetLighting = {Brightness = Defaults.Lighting.Brightness * 0.9, OutdoorAmbient = darkenColor(Defaults.Lighting.OutdoorAmbient, 0.9), FogColor = Defaults.Lighting.FogColor, FogEnd = 1000}
		targetAtmosphere = {Density = 0.3, Haze = 1}
	elseif intensityType == "Normal" then
		targetLighting = {Brightness = Defaults.Lighting.Brightness * 0.7, OutdoorAmbient = darkenColor(Defaults.Lighting.OutdoorAmbient, 0.7), FogColor = darkenColor(Defaults.Lighting.FogColor, 0.8), FogEnd = 300}
		targetAtmosphere = {Density = 0.45, Haze = 2}
	elseif intensityType == "Storm" then
		targetLighting = {Brightness = 0.5, OutdoorAmbient = Color3.fromRGB(30, 30, 40), FogColor = Color3.fromRGB(200, 200, 210), FogEnd = 120}
		targetAtmosphere = {Density = 0.7, Haze = 4, Color = Color3.fromRGB(180, 180, 180), Decay = Color3.fromRGB(50, 50, 60)}
	end

	TweenService:Create(Lighting, tweenInfo, targetLighting):Play()
	TweenService:Create(Atmosphere, tweenInfo, targetAtmosphere):Play()

	task.delay(transDuration * 0.6, function()
		if Lighting:GetAttribute("RainType") == intensityType then 
			Lighting:SetAttribute("IsRaining", true) 
		end
	end)
end

local function setFoggyWeather()
	Lighting:SetAttribute("IsRaining", false)
	Lighting:SetAttribute("IsAcidRain", false)
	Lighting:SetAttribute("IsFoggy", true)
	Lighting:SetAttribute("RainType", "None")

	local tweenInfo = TweenInfo.new(20, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut) 
	TweenService:Create(Lighting, tweenInfo, {Brightness = Defaults.Lighting.Brightness, OutdoorAmbient = Color3.fromRGB(200, 200, 200), FogColor = Color3.fromRGB(255, 255, 255), FogEnd = 100}):Play()
	TweenService:Create(Atmosphere, tweenInfo, {Density = 0.65, Haze = 3, Color = Color3.fromRGB(255, 255, 255), Decay = Color3.fromRGB(200, 200, 200), Glare = 0.2}):Play()
end

local function setClearWeather()
	Lighting:SetAttribute("IsRaining", false)
	Lighting:SetAttribute("IsAcidRain", false)
	Lighting:SetAttribute("IsFoggy", false)
	Lighting:SetAttribute("RainType", "None")

	local tweenInfo = TweenInfo.new(15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(Lighting, tweenInfo, Defaults.Lighting):Play()
	TweenService:Create(Atmosphere, tweenInfo, Defaults.Atmosphere):Play()
end

local function applyCharredEffect(character)
	if not character then return end

	local originalStates = {}

	for _, obj in pairs(character:GetDescendants()) do
		if obj:IsA("Clothing") or obj:IsA("ShirtGraphic") or obj:IsA("Decal") then
			originalStates[obj] = { Parent = obj.Parent }
			obj.Parent = nil 
		elseif obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			local state = { Color = obj.Color, Material = obj.Material }
			if obj:IsA("MeshPart") then
				state.TextureID = obj.TextureID
				obj.TextureID = "" 
			end
			originalStates[obj] = state

			obj.Color = Color3.fromRGB(15, 15, 15) 
			obj.Material = Enum.Material.Slate     
		elseif obj:IsA("SpecialMesh") then
			originalStates[obj] = { TextureId = obj.TextureId }
			obj.TextureId = ""
		end
	end

	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if torso then
		local smoke = Instance.new("Smoke")
		smoke.Color = Color3.fromRGB(20, 20, 20)
		smoke.Size = 0.5
		smoke.Opacity = 0.6
		smoke.RiseVelocity = 4
		smoke.Parent = torso
		Debris:AddItem(smoke, BURNT_DURATION)
	end

	task.delay(BURNT_DURATION, function()
		if not character or not character.Parent then return end

		for obj, state in pairs(originalStates) do
			if obj then
				if state.Parent then obj.Parent = state.Parent end
				if state.Color then obj.Color = state.Color end
				if state.Material then obj.Material = state.Material end
				if state.TextureID then obj.TextureID = state.TextureID end
				if state.TextureId then obj.TextureId = state.TextureId end
			end
		end
	end)
end

local function spawnLightningVisual(targetPosition)
	local lightningFolder = Instance.new("Folder")
	lightningFolder.Name = "LightningStrike"
	lightningFolder.Parent = workspace
	Debris:AddItem(lightningFolder, 0.4) 

	local startPos = targetPosition + Vector3.new(math.random(-50, 50), 400, math.random(-50, 50))
	local endPos = targetPosition
	local segmentCount = 12 
	local lastPoint = startPos
	local flashInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for i = 1, segmentCount do
		local alpha = i / segmentCount
		local nextPoint = startPos:Lerp(endPos, alpha)
		if i < segmentCount then
			local offset = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))
			nextPoint = nextPoint + offset
		end
		local distance = (nextPoint - lastPoint).Magnitude
		local segment = Instance.new("Part")
		segment.Anchored = true; segment.CanCollide = false
		segment.Material = Enum.Material.Neon; segment.BrickColor = BrickColor.new("New Yeller")
		segment.Size = Vector3.new(0.6, 0.6, distance + 0.5) 
		segment.CFrame = CFrame.lookAt(lastPoint, nextPoint) * CFrame.new(0, 0, -distance/2)
		segment.Parent = lightningFolder
		TweenService:Create(segment, flashInfo, {Transparency = 1, Size = Vector3.new(0.1, 0.1, distance + 0.5)}):Play()
		lastPoint = nextPoint
	end

	local explosion = Instance.new("Explosion")
	explosion.Position = targetPosition
	explosion.BlastPressure = 0; explosion.BlastRadius = 6
	explosion.DestroyJointRadiusPercent = 0; explosion.ExplosionType = Enum.ExplosionType.NoCraters 
	explosion.Parent = workspace

	local sfxPart = Instance.new("Part")
	sfxPart.Name = "ThunderSFX"
	sfxPart.Transparency = 1
	sfxPart.Anchored = true
	sfxPart.CanCollide = false
	sfxPart.Position = targetPosition
	sfxPart.Parent = workspace

	local sfx = Instance.new("Sound")
	sfx.SoundId = "rbxassetid://133426162" 
	sfx.Volume = 3
	sfx.RollOffMaxDistance = 800
	sfx.RollOffMinDistance = 50
	sfx.Parent = sfxPart
	sfx:Play()

	sfx.Ended:Connect(function()
		if sfxPart then sfxPart:Destroy() end
	end)
	Debris:AddItem(sfxPart, 15) 
end

local function strikeLogic(targetPlayer, mode)
	if not targetPlayer or not targetPlayer.Character then return end
	local rootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then return end

	if mode == "single" then
		spawnLightningVisual(rootPart.Position)
		applyCharredEffect(targetPlayer.Character)
		humanoid:TakeDamage(humanoid.MaxHealth * 0.3)
	elseif mode == "kill" then
		task.spawn(function()
			if rootPart and humanoid and humanoid.Health > 0 then
				spawnLightningVisual(rootPart.Position)
				humanoid:TakeDamage(humanoid.MaxHealth * 0.2)
			end

			task.wait(math.random(15, 30) / 10) 

			if rootPart and humanoid and humanoid.Health > 0 then
				spawnLightningVisual(rootPart.Position)
				humanoid:TakeDamage(humanoid.MaxHealth * 0.4)
			end

			task.wait(math.random(5, 12) / 10) 

			if rootPart and humanoid and humanoid.Health > 0 then
				spawnLightningVisual(rootPart.Position)
				applyCharredEffect(targetPlayer.Character)
				humanoid.Health = 0
			end
		end)
	end
end

local function startAutoCycle()
	currentLoopId = currentLoopId + 1
	local myLoopId = currentLoopId
	autoCycle = true

	task.spawn(function()
		print("[AUTO] Siklus Cuaca Dimulai")
		while autoCycle and myLoopId == currentLoopId do
			local chance = math.random(1, 100)
			local duration = 0
			local newState = "Clear"

			if chance <= 40 then newState = "Clear"
			elseif chance <= 55 then newState = "Storm"
			elseif chance <= 70 then newState = "Normal"
			elseif chance <= 85 then newState = "Fog"
			else newState = "Drizzle" end

			if newState == lastChosenState then task.wait(1) continue end
			lastChosenState = newState

			if newState == "Clear" then
				setClearWeather()
				duration = math.random(120, 240)
			elseif newState == "Storm" then
				setRainyWeather("Storm")
				duration = math.random(60, 90) + 25 
			elseif newState == "Normal" then
				setRainyWeather("Normal")
				duration = math.random(90, 120) + 18 
			elseif newState == "Fog" then
				setFoggyWeather()
				duration = math.random(120, 150) 
			elseif newState == "Drizzle" then
				setRainyWeather("Drizzle")
				duration = math.random(120, 150) + 12
			end

			task.wait(duration)
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(RAIN_DAMAGE_INTERVAL)
		if Lighting:GetAttribute("IsRaining") and Lighting:GetAttribute("IsAcidRain") then
			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and not isProtected(player.Character) then
					local hum = player.Character:FindFirstChild("Humanoid")
					if hum and hum.Health > 0 then
						hum:TakeDamage(hum.MaxHealth * (RAIN_DAMAGE_PERCENT / 100))
						acidRemote:FireClient(player)
					end
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(math.random(10, 25)) 

		if Lighting:GetAttribute("IsRaining") and Lighting:GetAttribute("RainType") == "Storm" and Lighting:GetAttribute("AllowLightningStrike") then
			local players = Players:GetPlayers()
			local unprotectedPlayers = {}

			for _, p in pairs(players) do
				if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					if not isProtected(p.Character) then
						table.insert(unprotectedPlayers, p)
					end
				end
			end

			if #unprotectedPlayers > 0 then
				local chance = math.random(1, 100)
				local targetPlayer = unprotectedPlayers[math.random(1, #unprotectedPlayers)]
				local rootPos = targetPlayer.Character.HumanoidRootPart.Position

				if chance <= 30 then
					strikeLogic(targetPlayer, "single")
				else
					local offsetX = (math.random() > 0.5 and 1 or -1) * math.random(15, 50)
					local offsetZ = (math.random() > 0.5 and 1 or -1) * math.random(15, 50)
					local targetPos = rootPos + Vector3.new(offsetX, 0, offsetZ)

					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.FilterDescendantsInstances = {targetPlayer.Character}

					local result = workspace:Raycast(targetPos + Vector3.new(0, 200, 0), Vector3.new(0, -300, 0), rayParams)
					if result then
						spawnLightningVisual(result.Position)
					end
				end
			end
		end
	end
end)

local weatherBindable = ServerStorage:FindFirstChild("KarinaWeatherEvent") or Instance.new("BindableEvent", ServerStorage)
weatherBindable.Name = "KarinaWeatherEvent"

weatherBindable.Event:Connect(function(adminName, actionType, cmd, targetName)
	if actionType == "Global" then
		autoCycle = false
		if cmd == "Auto" then startAutoCycle()
		elseif cmd == "Cerah" then setClearWeather()
		elseif cmd == "Gerimis" then setRainyWeather("Drizzle")
		elseif cmd == "Hujan" then setRainyWeather("Normal")
		elseif cmd == "Badai" then setRainyWeather("Storm")
		elseif cmd == "Kabut" then setFoggyWeather() end
	elseif actionType == "Target" then
		local target = findPlayer(targetName)
		if target then
			if cmd == "Petir" then strikeLogic(target, "single")
			elseif cmd == "Petirkill" then strikeLogic(target, "kill") end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		local args = string.split(string.lower(msg), " ")
		if args[1] == ";auto" then startAutoCycle() end
	end)
end)

startAutoCycle()