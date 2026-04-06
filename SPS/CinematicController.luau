--[[ 
    CINEMATIC CAMERA CONTROLLER - CUSTOM TOPBAR V5 (V45)
    Update: 
    1. UI Architecture Aligned Pixel-Perfectly.
    2. Reset button removed completely (visually & logically), Launch takes full width.
    3. Hotbar (Backpack) automatically hidden when Cinematic Modal opens.
    4. TopbarPlus replaced with Custom KariTopbar Module. State tracking done manually.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui") 
local UserInputService = game:GetService("UserInputService") 

local KariTopbar = require(ReplicatedStorage:WaitForChild("KariTopbar"))
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local THEME = {
	MainBG = Color3.fromRGB(30, 59, 103),
	SidebarBG = Color3.fromRGB(20, 45, 85),
	CardBG = Color3.fromRGB(40, 75, 125),
	Accent = Color3.fromRGB(247, 173, 175),
	RobuxColor = Color3.fromRGB(46, 204, 113), 
	Warning = Color3.fromRGB(239, 68, 68),
	TextMain = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(175, 195, 225)
}

local config = {
	duration = 5, distance = 20, height = 10,
	fov = 70, useBars = true, useHeadTrack = true,
	useSloMo = false, useBreathing = true, allowMovement = true 
}

local isRunning, isStepMode = false, false 
local progressTween, renderConnection = nil, nil 
local selectedModeFunc = nil
local guiStates = {} 
local originalNeckC0 = nil

local progressValue = Instance.new("NumberValue")
progressValue.Name = "CinematicProgress"
progressValue.Value = 0

local ghostCFrameValue = Instance.new("CFrameValue")
ghostCFrameValue.Name = "GhostCamProxy"

local blurEffect = Lighting:FindFirstChild("CinematicBlur")
if not blurEffect then
	blurEffect = Instance.new("BlurEffect")
	blurEffect.Name = "CinematicBlur"
	blurEffect.Size = 0
	blurEffect.Parent = Lighting
end

--------------------------------------------------------------------------------
-- 0. KONFIGURASI GUI EKSTERNAL (MODAL OPEN)
--------------------------------------------------------------------------------
local EXTERNAL_GUIS = {"AltitudeCatalogUI", "StatsGui", "ShopGui"} 
local externalGuiStates = {}

--------------------------------------------------------------------------------
-- 0. TOPBAR INITIALIZATION (KARI TOPBAR OOP) & MODAL LOGIC
--------------------------------------------------------------------------------
local isGuiOpen = false
local isIconLocked = false

local function closeCinematicGui()
	if not isGuiOpen then return end
	isGuiOpen = false

	local pGui = player:FindFirstChild("PlayerGui")
	local gui = pGui and pGui:FindFirstChild("CinematicGUI")
	local mPanel = gui and gui:FindFirstChild("MainPanel")

	if mPanel then
		mPanel.Visible = false 
		TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size=0}):Play() 
	end
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)

	if pGui then
		for guiName, wasEnabled in pairs(externalGuiStates) do
			local targetGui = pGui:FindFirstChild(guiName)
			if targetGui and targetGui:IsA("ScreenGui") then
				targetGui.Enabled = wasEnabled
			end
		end
	end
	table.clear(externalGuiStates)
end

local function openCinematicGui()
	if isGuiOpen then return end

	local pGui = player:FindFirstChild("PlayerGui")
	local gui = pGui and pGui:FindFirstChild("CinematicGUI")
	local mPanel = gui and gui:FindFirstChild("MainPanel")

	if mPanel then
		isGuiOpen = true
		mPanel.Visible = true 
		TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size=24}):Play() 
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)

		for _, guiName in ipairs(EXTERNAL_GUIS) do
			local targetGui = pGui:FindFirstChild(guiName)
			if targetGui and targetGui:IsA("ScreenGui") then
				externalGuiStates[guiName] = targetGui.Enabled
				targetGui.Enabled = false
			end
		end
	else
		warn("[Cinematic] GUI tidak ditemukan! Pastikan CinematicGUI sudah dicopy ke StarterGui.")
	end
end

-- Membuat Objek Tombol Cinematic menggunakan Module KariTopbar OOP
local cinematicTopbar = KariTopbar.new("rbxassetid://72456524311201")

cinematicTopbar:Bind(
	function()
		if isIconLocked then return end
		openCinematicGui()
	end,
	function()
		if isIconLocked then return end
		closeCinematicGui()
	end
)

--------------------------------------------------------------------------------
-- 1. FUNGSI KAMERA (Head Tracking, Transform, 3D Bars)
--------------------------------------------------------------------------------
local function updateHeadTracking()
	if not config.useHeadTrack then return end
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	local humanoid = char:FindFirstChild("Humanoid")

	if head and torso and humanoid and humanoid.Health > 0 then
		local neck = head:FindFirstChild("Neck") or torso:FindFirstChild("Neck")
		if neck then
			if not originalNeckC0 then originalNeckC0 = neck.C0 end
			local camPos = camera.CFrame.Position
			local headPos = head.Position
			local lookDir = (camPos - headPos).Unit
			local torsoLook = torso.CFrame.LookVector
			local dot = torsoLook:Dot(lookDir)

			local targetC0 = originalNeckC0
			if dot > 0.3 then 
				local lookCFrame = CFrame.lookAt(head.Position, camPos)
				local relativePos = torso.CFrame:ToObjectSpace(lookCFrame) * CFrame.new(0, -neck.C0.Y, 0)
				if char:FindFirstChild("UpperTorso") then 
					targetC0 = CFrame.new(0, originalNeckC0.Y, 0) * relativePos.Rotation
				else 
					targetC0 = CFrame.new(0, originalNeckC0.Y, 0) * relativePos.Rotation * CFrame.Angles(math.pi/2, 0, 0)
				end
			end
			neck.C0 = neck.C0:Lerp(targetC0, 0.1)
		end
	end
end

local timeAccumulator, breathTime = 0, 0
local STEP_RATE, JITTER_INTENSITY, BREATH_SPEED, BREATH_AMP = 1/12, 0.3, 0.5, 0.5 

local function updateCameraTransform(dt)
	local targetCF = ghostCFrameValue.Value
	if config.useBreathing then
		breathTime = breathTime + dt
		local noiseX = math.noise(breathTime * BREATH_SPEED, 0, 0)
		local noiseY = math.noise(0, breathTime * BREATH_SPEED, 0)
		local noiseZ = math.noise(0, 0, breathTime * BREATH_SPEED)
		local breathOffset = CFrame.new(noiseX * BREATH_AMP, noiseY * BREATH_AMP, 0) * CFrame.Angles(math.rad(noiseX * BREATH_AMP), math.rad(noiseY * BREATH_AMP), math.rad(noiseZ * (BREATH_AMP/2)))
		targetCF = targetCF * breathOffset
	end

	if isStepMode then
		timeAccumulator = timeAccumulator + dt
		if timeAccumulator >= STEP_RATE then
			camera.CFrame = targetCF * CFrame.new(Vector3.new((math.random()-0.5)*JITTER_INTENSITY, (math.random()-0.5)*JITTER_INTENSITY, (math.random()-0.5)*JITTER_INTENSITY))
			timeAccumulator = 0
		end
	else
		camera.CFrame = targetCF
	end
	updateHeadTracking()
end

local barCoverageValue = Instance.new("NumberValue", script)
local topPart, bottomPart = Instance.new("Part"), Instance.new("Part")
for _, p in pairs({topPart, bottomPart}) do
	p.Name = "CinematicBarPart"; p.Anchored = true; p.CanCollide = false; p.CastShadow = false
	p.Material = Enum.Material.Neon; p.Color = Color3.new(0,0,0); p.Transparency = 1; p.Parent = camera
end

local function update3DBars()
	local coverage = barCoverageValue.Value
	if coverage <= 0.001 then topPart.Transparency = 1; bottomPart.Transparency = 1; return end
	topPart.Transparency = 0; bottomPart.Transparency = 0

	local cam = workspace.CurrentCamera
	local fov = math.rad(cam.FieldOfView)
	local aspect = cam.ViewportSize.X / cam.ViewportSize.Y
	local visibleHeight = 2 * math.tan(fov / 2)
	local visibleWidth = visibleHeight * aspect
	local cropHeight = visibleHeight * coverage
	local physicalBarHeight = visibleHeight * 0.6 

	topPart.Size = Vector3.new(visibleWidth * 2, physicalBarHeight, 0.001)
	bottomPart.Size = Vector3.new(visibleWidth * 2, physicalBarHeight, 0.001)
	topPart.CFrame = cam.CFrame * CFrame.new(0, ((visibleHeight / 2) - cropHeight) + (physicalBarHeight / 2), -1)
	bottomPart.CFrame = cam.CFrame * CFrame.new(0, ((-visibleHeight / 2) + cropHeight) - (physicalBarHeight / 2), -1)
end

RunService:BindToRenderStep("CinematicUpdateLoop", Enum.RenderPriority.Last.Value + 5, function(dt)
	if isRunning then updateCameraTransform(dt) end
	update3DBars()
end)

local function animateBars(show)
	TweenService:Create(barCoverageValue, TweenInfo.new(1.5, Enum.EasingStyle.Quart), {Value = show and (UserInputService.TouchEnabled and 0.13 or 0.08) or 0}):Play()
end

local function playSmartProgress(onComplete)
	progressValue.Value = 0 
	local dur = config.duration
	if config.useSloMo then
		local exDur = dur * 1.5 
		local t1 = TweenService:Create(progressValue, TweenInfo.new(exDur * 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Value = 0.3})
		local t2 = TweenService:Create(progressValue, TweenInfo.new(exDur * 0.70, Enum.EasingStyle.Linear), {Value = 0.7})
		local t3 = TweenService:Create(progressValue, TweenInfo.new(exDur * 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Value = 1})
		t1:Play(); progressTween = t1
		t1.Completed:Connect(function() if isRunning then t2:Play(); t2.Completed:Connect(function() if isRunning then t3:Play(); t3.Completed:Connect(onComplete) end end) end end)
	else
		progressTween = TweenService:Create(progressValue, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Value = 1})
		progressTween:Play(); progressTween.Completed:Connect(onComplete)
	end
end

--------------------------------------------------------------------------------
-- 2. SETUP & CONNECT GUI (SIDEBAR V3 - SINGLE LAUNCH BUTTON)
--------------------------------------------------------------------------------
local gui = player:WaitForChild("PlayerGui"):WaitForChild("CinematicGUI")
local mainPanel = gui:WaitForChild("MainPanel")

local leftPanel = mainPanel:WaitForChild("LeftPanel")
local rightPanel = mainPanel:WaitForChild("RightPanel")
local pageContainer = rightPanel:WaitForChild("PageContainer")
local launchBar = rightPanel:WaitForChild("LaunchBar")
local countdownUi = gui:WaitForChild("Countdown")

local closeBtnAction = mainPanel:WaitForChild("CloseBtn"):WaitForChild("Action")
closeBtnAction.MouseButton1Click:Connect(function() closeCinematicGui() end)

-- TAB SWITCHING LOGIC (SIDEBAR)
local tabs = {
	{Btn = leftPanel:WaitForChild("ModesNav"), Page = pageContainer:WaitForChild("ModesPage")},
	{Btn = leftPanel:WaitForChild("SettingsNav"), Page = pageContainer:WaitForChild("SettingsPage")},
	{Btn = leftPanel:WaitForChild("ParametersNav"), Page = pageContainer:WaitForChild("ParametersPage")}
}

local function switchTab(targetIndex)
	for i, tabData in ipairs(tabs) do
		local isActive = (i == targetIndex)
		tabData.Page.Visible = isActive
		tabData.Btn.BackgroundTransparency = isActive and 0 or 1
		tabData.Btn.TextColor3 = isActive and THEME.MainBG or THEME.TextMain
	end
end

for i, tabData in ipairs(tabs) do
	tabData.Btn.MouseButton1Click:Connect(function() switchTab(i) end)
end

-- TOGGLE LOGIC WITH DOT INDICATOR (SETTINGS PAGE)
local function setupToggle(btnName, configKey, defaultState)
	local btn = pageContainer.SettingsPage:FindFirstChild(btnName)
	if btn then
		local dot = btn:WaitForChild("StatusDot")
		local function updateVisual()
			dot.BackgroundColor3 = config[configKey] and THEME.RobuxColor or THEME.Warning
		end
		config[configKey] = defaultState
		updateVisual()
		btn.MouseButton1Click:Connect(function() config[configKey] = not config[configKey]; updateVisual() end)
	end
end

setupToggle("BarsToggle", "useBars", true)
setupToggle("HeadToggle", "useHeadTrack", true)
setupToggle("SloMoToggle", "useSloMo", false)

-- INPUT LOGIC (PARAMETERS PAGE)
local function validate(boxName, min, max, defaultVal, configKey)
	local box = pageContainer.ParametersPage:FindFirstChild(boxName, true)
	if box then
		box.FocusLost:Connect(function()
			local num = tonumber(box.Text)
			if not num then box.Text = tostring(defaultVal); config[configKey] = defaultVal; return end
			local clamped = math.clamp(num, min, max)
			box.Text = tostring(clamped); config[configKey] = clamped
		end)
	end
end
validate("DurBox", 1, 120, 5, "duration")
validate("DistBox", 5, 500, 20, "distance")
validate("HeightBox", 2, 200, 10, "height")

--------------------------------------------------------------------------------
-- 3. CAMERA LOGIC & MODES 
--------------------------------------------------------------------------------
local function resetCamera()
	if progressTween then progressTween:Cancel() end
	camera.CameraType = Enum.CameraType.Custom; camera.FieldOfView = 70 
	isRunning, isStepMode = false, false 
	if renderConnection then renderConnection:Disconnect() end

	if originalNeckC0 then
		local neck = player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("Neck")
		if neck then neck.C0 = originalNeckC0 end
		originalNeckC0 = nil
	end

	for g, state in pairs(guiStates) do if g and g.Parent then g.Enabled = state end end
	table.clear(guiStates)
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)

	animateBars(false)
	isIconLocked = false
end

local function prepareCamera()
	if isRunning then resetCamera() end; isRunning = true
	for _, g in pairs(player.PlayerGui:GetChildren()) do if g:IsA("ScreenGui") and g.Name ~= "CinematicGUI" then guiStates[g] = g.Enabled; g.Enabled = false end end

	if config.allowMovement then
		pcall(function() 
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
		end)
	else pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end) end

	camera.CameraType = Enum.CameraType.Scriptable
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then resetCamera(); return nil end
	ghostCFrameValue.Value = camera.CFrame
	return root
end

local function runLinear(zoomIn, step)
	local root = prepareCamera(); if not root then return end; isStepMode = step
	local startOff = zoomIn and Vector3.new(0, config.height, config.distance) or Vector3.new(0, 5, 5)
	local endOff = zoomIn and Vector3.new(0, 3, 5) or Vector3.new(0, config.height, config.distance)

	renderConnection = progressValue.Changed:Connect(function(v)
		if root.Parent then ghostCFrameValue.Value = CFrame.lookAt(root.Position + startOff:Lerp(endOff, v), root.Position + Vector3.new(0, 2, 0)) end
	end)
	playSmartProgress(resetCamera)
end

local modeFunctions = {
	["Drone Zoom Out"] = function() runLinear(false, false) end,
	["Drone Zoom In"] = function() runLinear(true, false) end,
	["Zoom In Step"] = function() runLinear(true, true) end,
	["Orbit 360"] = function()
		local root = prepareCamera(); if not root then return end
		renderConnection = progressValue.Changed:Connect(function(v)
			if root.Parent then
				local angle = v * math.pi * 2
				ghostCFrameValue.Value = CFrame.lookAt(root.Position + Vector3.new(math.sin(angle)*config.distance, config.height, math.cos(angle)*config.distance), root.Position)
			end
		end)
		playSmartProgress(resetCamera)
	end,
	["Cinematic Pan"] = function()
		local root = prepareCamera(); if not root then return end
		local rOff, fOff = root.CFrame.RightVector * config.distance, root.CFrame.LookVector * 10
		local sOff = -rOff + fOff + Vector3.new(0, config.height/2, 0)
		local eOff = rOff + fOff + Vector3.new(0, config.height/2, 0)
		renderConnection = progressValue.Changed:Connect(function(v)
			if root.Parent then ghostCFrameValue.Value = CFrame.lookAt(root.Position + sOff:Lerp(eOff, v), root.Position) end
		end)
		playSmartProgress(resetCamera)
	end,
	["Reveal Up"] = function()
		local root = prepareCamera(); if not root then return end
		local fwd = root.CFrame.LookVector * 10
		local sPosOff, ePosOff = fwd - Vector3.new(0, 2, 0), (root.CFrame.LookVector * 12) + Vector3.new(0, config.height, 0)
		local sLook, eLook = Vector3.new(0, -2, 0), Vector3.new(0, 2, 0)
		renderConnection = progressValue.Changed:Connect(function(v)
			if root.Parent then ghostCFrameValue.Value = CFrame.lookAt(root.Position + sPosOff:Lerp(ePosOff, v), root.Position + sLook:Lerp(eLook, v)) end
		end)
		playSmartProgress(resetCamera)
	end,
	["Dolly Zoom"] = function()
		local root = prepareCamera(); if not root then return end
		local fwd = root.CFrame.LookVector
		local sOff, eOff = (fwd * 5) + Vector3.new(0, 2, 0), (fwd * math.max(config.distance, 20)) + Vector3.new(0, 2, 0)
		local eFOV = math.deg(2 * math.atan((5 * math.tan(math.rad(70) / 2)) / math.max(config.distance, 20)))
		renderConnection = progressValue.Changed:Connect(function(v)
			if root.Parent then
				ghostCFrameValue.Value = CFrame.lookAt(root.Position + sOff:Lerp(eOff, v), root.Position + Vector3.new(0, 2, 0))
				camera.FieldOfView = 70 + (eFOV - 70) * v
			end
		end)
		playSmartProgress(resetCamera)
	end
}

-- MAPPING MODES DARI GRID
for _, child in pairs(pageContainer.ModesPage:GetChildren()) do
	if child:IsA("TextButton") and modeFunctions[child.Name] then
		child.MouseButton1Click:Connect(function()
			for _, b in pairs(pageContainer.ModesPage:GetChildren()) do 
				if b:IsA("TextButton") then b.BackgroundColor3 = THEME.CardBG end 
			end
			child.BackgroundColor3 = THEME.Accent
			selectedModeFunc = modeFunctions[child.Name]
		end)
	end
end

-- FIXED LAUNCH BAR ACTIONS (FULL WIDTH)
launchBar:WaitForChild("StartBtn").MouseButton1Click:Connect(function()
	if not selectedModeFunc then switchTab(1); return end
	closeCinematicGui()
	isIconLocked = true

	countdownUi.Visible = true
	for i=3,1,-1 do 
		countdownUi.Text = tostring(i)
		countdownUi.Size = UDim2.new(0.5,0,0.5,0)
		TweenService:Create(countdownUi, TweenInfo.new(0.5,Enum.EasingStyle.Back), {Size=UDim2.new(1,0,1,0)}):Play()
		task.wait(1) 
	end
	countdownUi.Visible = false
	if config.useBars then animateBars(true) end
	selectedModeFunc()
end)