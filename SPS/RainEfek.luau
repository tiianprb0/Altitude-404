--[[
    RAIN EFEK CLIENT (KARINA ROLLBACK v47 - FOG TO CLEAR NOTIF FIX)
    - Menghapus keseluruhan "Zone Aware Lighting" yang gagal.
    - Otoritas Fog dan Lighting dikembalikan murni ke Server.
    - UPDATE: Memasukkan 'camera' ke FilterDescendantsInstances (Phantom Roof Fix).
    - UPDATE (KARINA): Memperbaiki celah logika ketiadaan notifikasi saat cuaca berubah dari Kabut ke Cerah.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- === KONFIGURASI AUDIO & EFEK ===
local MUFFLE_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Sine)

-- === SETUP GUI ===
local screenGui = player:WaitForChild("PlayerGui"):WaitForChild("WeatherEffectsGui")
local redFrame = screenGui:WaitForChild("RedFlash")
local notifFrame = screenGui:WaitForChild("NotificationCard")
local colorBar = notifFrame:WaitForChild("ColorIndicator")
local titleLabel = notifFrame:WaitForChild("Title")
local descLabel = notifFrame:WaitForChild("Desc")

local dropletFolder = ReplicatedStorage:WaitForChild("Droplet Rain", 5) 
if not dropletFolder then
	warn("[KARINA WARNING] Folder 'Droplet Rain' tidak ditemukan di ReplicatedStorage!")
end

notifFrame.Position = UDim2.new(0.5, 0, -0.3, 0)
notifFrame.Visible = false

-- === FUNGSI ANIMASI NOTIFIKASI ===
local currentTween = nil
local hideTask = nil

local function showCustomNotification(title, text, colorType, duration)
	duration = duration or 5
	local barColor = Color3.fromRGB(255, 255, 255) 

	if colorType == "Info" then 
		barColor = Color3.fromRGB(247, 173, 175) 
	elseif colorType == "Warning" then 
		barColor = Color3.fromRGB(255, 150, 0) 
	elseif colorType == "Danger" then 
		barColor = Color3.fromRGB(135, 42, 44) 
	end

	titleLabel.Text = string.upper(title)
	descLabel.Text = text
	colorBar.BackgroundColor3 = barColor

	if currentTween then currentTween:Cancel() end
	if hideTask then task.cancel(hideTask) end

	notifFrame.Visible = true
	local targetPos = UDim2.new(0.5, 0, 0.17, 0) 

	local sound = Instance.new("Sound", workspace)
	sound.SoundId = "rbxassetid://4612375233" 
	sound.Volume = 0.5
	sound:Play()
	Debris:AddItem(sound, 1)

	currentTween = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos})
	currentTween:Play()

	hideTask = task.delay(duration, function()
		local exitPos = UDim2.new(0.5, 0, -0.3, 0)
		currentTween = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = exitPos})
		currentTween:Play()
	end)
end

-- === LOGIKA VISUAL: DROPLET DI LAYAR ===
local dropletLoop = nil

local function spawnScreenDroplet()
	if not dropletFolder or not screenGui then return end

	local templates = dropletFolder:GetChildren()
	if #templates == 0 then return end
	local randomTemplate = templates[math.random(1, #templates)]

	local drop = randomTemplate:Clone()
	drop.Parent = screenGui
	drop.Name = "RainDroplet"
	drop.BackgroundTransparency = 1
	drop.ImageTransparency = 0 
	drop.AnchorPoint = Vector2.new(0.5, 0.5) 
	drop.ZIndex = 0 

	local randW, randH
	if math.random() < 0.7 then
		randW = math.random(10, 35)
		randH = math.random(15, 45)
	else
		randW = math.random(35, 75)
		randH = math.random(45, 95)
	end
	drop.Size = UDim2.new(0, randW, 0, randH)

	local randomX = math.random() * 1
	local randomY = math.random() * 1
	drop.Position = UDim2.new(randomX, 0, randomY, 0)

	local slideDuration = 0.5
	local stretchDuration = math.random(50, 80) / 100

	local slideDist = math.random(20, 50) / 1000 
	local slideTargetPos = drop.Position + UDim2.new(0, 0, slideDist, 0)

	local slideTween = TweenService:Create(drop, TweenInfo.new(slideDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
		Position = slideTargetPos
	})

	slideTween:Play()

	slideTween.Completed:Connect(function()
		if not drop or not drop.Parent then return end

		local endSize = UDim2.new(0, randW, 0, randH * 1.5)
		local finalPos = slideTargetPos + UDim2.new(0, 0, 0.05, 0) 

		local stretchTween = TweenService:Create(drop, TweenInfo.new(stretchDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = endSize,
			ImageTransparency = 1,
			Position = finalPos
		})

		stretchTween:Play()

		stretchTween.Completed:Connect(function()
			drop:Destroy()
		end)
	end)
end

local function startDropletEffect()
	if dropletLoop then task.cancel(dropletLoop) end
	dropletLoop = task.spawn(function()
		while true do
			local rType = Lighting:GetAttribute("RainType")

			local allowed = Lighting:GetAttribute("AllowDroplets")
			if allowed == nil then allowed = true end

			if Lighting:GetAttribute("IsRaining") and allowed and rType ~= "Drizzle" then
				spawnScreenDroplet()
			end

			local waitTime = 0.5 

			if rType == "Storm" then
				waitTime = math.random(10, 15) / 100   
			elseif rType == "Normal" then
				waitTime = math.random(30, 50) / 100   
			elseif rType == "Drizzle" then
				waitTime = math.random(100, 200) / 100 
			end

			task.wait(waitTime)
		end
	end)
end

local function stopDropletEffect()
	if dropletLoop then task.cancel(dropletLoop) end
	dropletLoop = nil
end

-- === VARIABLE LOGIC LAINNYA ===
local lastFlashTime = 0
local FLASH_COOLDOWN = 2 
local character, humanoid
local rainSoundObject = nil
local rainEqEffect = nil
local lastAudioState = "Outdoor" 
local EQ_INDOOR = {HighGain = -80, MidGain = -10, LowGain = 0} 
local EQ_OUTDOOR = {HighGain = 0, MidGain = 0, LowGain = 0}

local environmentRayParams = RaycastParams.new()
environmentRayParams.FilterType = Enum.RaycastFilterType.Exclude

-- === LISTENER ===
local lastRainType = "None"
Lighting:GetAttributeChangedSignal("RainType"):Connect(function()
	local rType = Lighting:GetAttribute("RainType")
	if rType == lastRainType then return end
	lastRainType = rType

	if rType == "Drizzle" then
		showCustomNotification("Gerimis", "Langit mendung ringan. Gerimis akan segera turun.", "Info", 6)
	elseif rType == "Normal" then
		showCustomNotification("Hujan Deras", "Awan gelap berkumpul. Hujan deras akan segera turun.", "Info", 6)
	elseif rType == "Storm" then
		showCustomNotification("PERINGATAN BADAI", "Atmosfer tidak stabil. Jarak pandang menurun drastis.", "Warning", 8)
	elseif rType == "None" then
		showCustomNotification("Cuaca Cerah", "Langit kembali cerah dan kondusif.", "Info", 5)
	end
end)

local warningRemote = ReplicatedStorage:WaitForChild("WeatherWarningEvent", 10)
if warningRemote then
	warningRemote.OnClientEvent:Connect(function(msg)
		if msg == "RAIN_WARNING" then
			showCustomNotification("BAHAYA EKSTRIM", "Hujan ini mengandung zat asam! Segera cari atap!", "Danger", 8)
		end
	end)
end

local acidRemote = ReplicatedStorage:WaitForChild("AcidRainEvent", 10)
if acidRemote then
	acidRemote.OnClientEvent:Connect(function()
		if not humanoid or humanoid.Health <= 0 then return end
		local healthPercent = humanoid.Health / humanoid.MaxHealth
		if tick() - lastFlashTime >= FLASH_COOLDOWN then
			lastFlashTime = tick()
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			redFrame.BackgroundTransparency = 0.6 
			TweenService:Create(redFrame, tweenInfo, {BackgroundTransparency = 1}):Play()

			local acidSfx = Instance.new("Sound", workspace)
			acidSfx.SoundId = "rbxassetid://118569637531741"
			acidSfx.Volume = 1
			acidSfx.PlayOnRemove = true 
			acidSfx:Destroy()

			if healthPercent <= 0.3 and not player:GetAttribute("WarnedAcid") then
				player:SetAttribute("WarnedAcid", true)
				showCustomNotification("KONDISI KRITIS", "Kesehatanmu sekarat akibat hujan asam!", "Danger", 5)
				task.delay(8, function() player:SetAttribute("WarnedAcid", nil) end)
			end
		end
	end)
end

local function getCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	return char, hum
end

character, humanoid = getCharacter()
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
end)

local thunder = Instance.new("Sound", game:GetService("SoundService"))
thunder.SoundId = "rbxassetid://133426162" 
thunder.Volume = 1.5 

local function cameraShake(intensity)
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if not hum then return end

	intensity = intensity or 0.8

	task.spawn(function()
		local originalOffset = hum.CameraOffset

		for i = 1, 15 do
			local offsetX = (math.random() - 0.5) * intensity
			local offsetY = (math.random() - 0.5) * intensity
			local offsetZ = (math.random() - 0.5) * intensity

			hum.CameraOffset = originalOffset + Vector3.new(offsetX, offsetY, offsetZ)
			task.wait(0.03)
		end

		hum.CameraOffset = originalOffset
	end)
end

local leafMeshes = {
	"rbxassetid://40282517", "rbxassetid://40282583", "rbxassetid://40282665",
	"rbxassetid://40302181", "rbxassetid://40302270"
}
local mapBounds = {min = Vector3.new(-500,20,-500), max = Vector3.new(500,50,500)}
local windDirection = Vector3.new(0,0,0)

spawn(function()
	while true do
		windDirection = Vector3.new(math.random(-15,15),math.random(-2,2),math.random(-15,15))
		task.wait(math.random(2,4))
	end
end)

local function spawnLeafCinematic()
	for layer = 1,3 do
		local layerCount = layer * 5 
		for i=1,layerCount do
			local part = Instance.new("Part")
			part.Size = Vector3.new(2,2,2)
			part.Anchored = false
			part.CanCollide = false
			part.Transparency = 1 

			local yMin, yMax = 0, 0
			if layer==1 then yMin,yMax = 35,50 end 
			if layer==2 then yMin,yMax = 20,35 end 
			if layer==3 then yMin,yMax = 10,20 end 
			part.Position = Vector3.new(
				math.random(mapBounds.min.X,mapBounds.max.X),
				math.random(yMin,yMax),
				math.random(mapBounds.min.Z,mapBounds.max.Z)
			)
			part.Parent = workspace
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = leafMeshes[math.random(1,#leafMeshes)]
			local scale = 3 - layer*0.5
			mesh.Scale = Vector3.new(scale,scale,scale)
			mesh.Parent = part
			part.BrickColor = BrickColor.new("Earth green")
			part.Transparency = 0
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = windDirection + Vector3.new(math.random(-2,2),0,math.random(-2,2))
			bv.MaxForce = Vector3.new(500,500,500)
			bv.Parent = part
			Debris:AddItem(part, math.random(10,20))
		end
	end
end

local function getRainSoundDirectly()
	local group = SoundService:FindFirstChild("__RainSoundGroup")
	return group and group:FindFirstChild("RainSound") or nil
end

local function setupAudioSystem()
	rainSoundObject = getRainSoundDirectly()
	if rainSoundObject then
		rainEqEffect = rainSoundObject:FindFirstChild("RainMuffler")
		if not rainEqEffect then
			rainEqEffect = Instance.new("EqualizerSoundEffect")
			rainEqEffect.Name = "RainMuffler"
			rainEqEffect.HighGain = 0
			rainEqEffect.MidGain = 0
			rainEqEffect.LowGain = 0
			rainEqEffect.Enabled = true
			rainEqEffect.Parent = rainSoundObject
		end
	end
end

local function hasUmbrella()
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

local function isUnderRoof()
	if not character then return false end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	environmentRayParams.FilterDescendantsInstances = {character, camera}

	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, 60, 0), environmentRayParams)

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

RunService.RenderStepped:Connect(function()
	if not Lighting:GetAttribute("IsRaining") then 
		rainSoundObject = nil 
		return 
	end
	if not rainSoundObject then
		setupAudioSystem()
		return
	end
	if not rainEqEffect then return end

	local protected = isUnderRoof() or hasUmbrella()
	local targetState = protected and "Indoor" or "Outdoor"

	if targetState ~= lastAudioState then
		lastAudioState = targetState
		if targetState == "Indoor" then
			TweenService:Create(rainEqEffect, MUFFLE_TWEEN_INFO, EQ_INDOOR):Play()
		else
			TweenService:Create(rainEqEffect, MUFFLE_TWEEN_INFO, EQ_OUTDOOR):Play()
		end
	end
end)

local isRainingLocal = false

Lighting:GetAttributeChangedSignal("IsRaining"):Connect(function()
	local raining = Lighting:GetAttribute("IsRaining")

	if raining and not isRainingLocal then
		isRainingLocal = true
		spawnLeafCinematic()
		startDropletEffect()
		task.delay(1, setupAudioSystem)

	elseif not raining and isRainingLocal then
		isRainingLocal = false
		stopDropletEffect()
	end
end)

local isFoggyLocal = false
Lighting:GetAttributeChangedSignal("IsFoggy"):Connect(function()
	local foggy = Lighting:GetAttribute("IsFoggy")

	if foggy and not isFoggyLocal then
		isFoggyLocal = true
		showCustomNotification("Kondisi Berkabut", "Kabut tebal mulai turun. Jarak pandang terbatas.", "Info", 5)
	elseif not foggy and isFoggyLocal then
		isFoggyLocal = false
		-- KARINA FIX: Memastikan notifikasi "Cerah" muncul saat kabut reda
		if Lighting:GetAttribute("RainType") == "None" then
			showCustomNotification("Cuaca Cerah", "Kabut telah terangkat. Langit kembali jernih.", "Info", 5)
		end
	end
end)

spawn(function()
	while true do
		task.wait(math.random(25, 50)) 
		if Lighting:GetAttribute("IsRaining") and Lighting:GetAttribute("RainType") == "Storm" then
			local oldB = Lighting.Brightness
			Lighting.Brightness = 10
			task.wait(0.1)
			Lighting.Brightness = oldB
			thunder:Play()
			cameraShake(0.8) 
		end
	end
end)