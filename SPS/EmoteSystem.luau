-- EmoteSystem -- StarterPlayerScripts --
-- Diperbaiki oleh Karina (Cross-UI Hiding dengan Music Player & Koin Alignment)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SIDE_WIDTH = 220
local SIDE_HEIGHT = 300
local SIDE_VISIBLE_X = 50
local SIDE_HIDDEN_X = -SIDE_WIDTH - 10
local SIDE_VERTICAL_ADJUST = 150

local COLORS = {
	Background = Color3.fromRGB(20, 45, 85),     
	Panel = Color3.fromRGB(40, 75, 125),         
	Button = Color3.fromRGB(30, 59, 103),        
	ButtonHover = Color3.fromRGB(50, 85, 140),
	Active = Color3.fromRGB(247, 173, 175),      
	Primary = Color3.fromRGB(247, 173, 175),     
	PrimaryLight = Color3.fromRGB(255, 190, 190),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(175, 195, 225),
	Accent = Color3.fromRGB(247, 173, 175)
}

-- Bersihkan UI Lama
for _, name in ipairs({"SidebarEmoteUI", "EmoteUI"}) do
	local old = playerGui:FindFirstChild(name)
	if old then old:Destroy() end
end
local oldBlur = Lighting:FindFirstChild("EmotePanelBlur")
if oldBlur then oldBlur:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SidebarEmoteUI"
gui.IgnoreGuiInset = false 
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- ==========================================
-- OVERLAY KLIK-UNTUK-TUTUP
-- ==========================================
local closeOverlay = Instance.new("TextButton", gui)
closeOverlay.Name = "CloseOverlay"
closeOverlay.Size = UDim2.new(1, 0, 1, 0)
closeOverlay.BackgroundTransparency = 1
closeOverlay.Text = ""
closeOverlay.ZIndex = 1
closeOverlay.Visible = false

-- ==========================================
-- TOMBOL TOGGLE POSE (Y = 20)
-- ==========================================
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Name = "EmoteToggleBtn"
toggleBtn.Size = UDim2.new(0, 110, 0, 46) 
toggleBtn.AnchorPoint = Vector2.new(0, 0)
toggleBtn.Position = UDim2.new(0, 20, 0, 20) 
toggleBtn.BackgroundTransparency = 1 
toggleBtn.Text = ""
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 10

local btnBg = Instance.new("Frame", toggleBtn)
btnBg.Name = "Background"
btnBg.AnchorPoint = Vector2.new(0, 0.5)
btnBg.Position = UDim2.new(0, 0, 0.5, 0)
btnBg.Size = UDim2.new(1, 0, 0, 28) 
btnBg.BackgroundColor3 = Color3.fromRGB(16, 44, 87) 
btnBg.BackgroundTransparency = 0.25
btnBg.BorderSizePixel = 0
btnBg.ZIndex = 9
Instance.new("UICorner", btnBg).CornerRadius = UDim.new(1, 0)

local btnGradient = Instance.new("UIGradient", btnBg)
btnGradient.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0.00, 1.00), 
	NumberSequenceKeypoint.new(0.15, 0.00), 
	NumberSequenceKeypoint.new(0.85, 0.00), 
	NumberSequenceKeypoint.new(1.00, 1.00)
}

local toggleIcon = Instance.new("ImageLabel", toggleBtn)
toggleIcon.Name = "Icon"
toggleIcon.AnchorPoint = Vector2.new(0, 0.5)
toggleIcon.Position = UDim2.new(0, 5, 0.5, 0)
toggleIcon.Size = UDim2.new(0, 46, 0, 46)
toggleIcon.BackgroundTransparency = 1
toggleIcon.Image = "rbxassetid://90721588355158"
toggleIcon.ZIndex = 11

local toggleText = Instance.new("TextLabel", toggleBtn)
toggleText.Name = "ToggleText"
toggleText.AnchorPoint = Vector2.new(0, 0.5)
toggleText.Position = UDim2.new(0, 59, 0.5, 0)
toggleText.Size = UDim2.new(1, -59, 0, 28)
toggleText.BackgroundTransparency = 1
toggleText.Text = "Pose"
toggleText.Font = Enum.Font.GothamBold
toggleText.TextColor3 = COLORS.Text
toggleText.TextSize = 16
toggleText.TextXAlignment = Enum.TextXAlignment.Left
toggleText.ZIndex = 11

toggleBtn.MouseEnter:Connect(function() TweenService:Create(btnBg, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play() end)
toggleBtn.MouseLeave:Connect(function() TweenService:Create(btnBg, TweenInfo.new(0.15), {BackgroundTransparency = 0.25}):Play() end)

-- ==========================================
-- MEMBANGUN SIDEBAR & ISINYA
-- ==========================================
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIDE_WIDTH, 0, SIDE_HEIGHT)
sidebar.Position = UDim2.new(0, SIDE_HIDDEN_X, 0.5, -SIDE_HEIGHT/2 + SIDE_VERTICAL_ADJUST)
sidebar.AnchorPoint = Vector2.new(0, 0.5)
sidebar.BackgroundColor3 = COLORS.Background
sidebar.BackgroundTransparency = 0
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 10
sidebar.Parent = gui
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

local tabContainer = Instance.new("Frame", sidebar)
tabContainer.Size = UDim2.new(1, -20, 0, 36)
tabContainer.Position = UDim2.new(0, 10, 0, 10)
tabContainer.BackgroundTransparency = 1
tabContainer.ZIndex = 10

local function createTab(name, xPos)
	local btn = Instance.new("TextButton", tabContainer)
	btn.Size = UDim2.new(0.5, -3, 1, 0)
	btn.Position = UDim2.new(xPos, 0, 0, 0)
	btn.BackgroundColor3 = COLORS.Button
	btn.BackgroundTransparency = 0.5
	btn.Font = Enum.Font.GothamBold
	btn.Text = name
	btn.TextSize = 14
	btn.TextColor3 = COLORS.Text
	btn.BorderSizePixel = 0
	btn.ZIndex = 10
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local dancesTab = createTab("DANCE", 0)
local emotesTab = createTab("EMOTE", 0.5)

local speedContainer = Instance.new("Frame", sidebar)
speedContainer.Size = UDim2.new(1, -20, 0, 50)
speedContainer.Position = UDim2.new(0, 10, 0, 52)
speedContainer.BackgroundColor3 = COLORS.Panel
speedContainer.BackgroundTransparency = 0
speedContainer.BorderSizePixel = 0
speedContainer.ZIndex = 10
Instance.new("UICorner", speedContainer).CornerRadius = UDim.new(0, 8)

local speedLabel = Instance.new("TextLabel", speedContainer)
speedLabel.Size = UDim2.new(1, -10, 0, 18)
speedLabel.Position = UDim2.new(0, 5, 0, 3)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 1.0x"
speedLabel.TextColor3 = COLORS.Text
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 13
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.ZIndex = 10

local sliderTrack = Instance.new("Frame", speedContainer)
sliderTrack.Size = UDim2.new(1, -20, 0, 6)
sliderTrack.Position = UDim2.new(0, 10, 0, 28)
sliderTrack.BackgroundColor3 = COLORS.Button
sliderTrack.BackgroundTransparency = 0.3
sliderTrack.BorderSizePixel = 0
sliderTrack.ZIndex = 10
Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame", sliderTrack)
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = COLORS.Primary
sliderFill.BackgroundTransparency = 0
sliderFill.BorderSizePixel = 0
sliderFill.ZIndex = 10
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local gradient = Instance.new("UIGradient", sliderFill)
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, COLORS.Primary),
	ColorSequenceKeypoint.new(1, COLORS.PrimaryLight)
}

local sliderKnob = Instance.new("TextButton", speedContainer)
sliderKnob.Size = UDim2.new(0, 20, 0, 20)
sliderKnob.Position = UDim2.new(0.5, -10, 0, 23)
sliderKnob.BackgroundColor3 = COLORS.Text
sliderKnob.BackgroundTransparency = 0
sliderKnob.BorderSizePixel = 0
sliderKnob.Text = ""
sliderKnob.AutoButtonColor = false
sliderKnob.Active = true
sliderKnob.ZIndex = 11
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

local knobShadow = Instance.new("Frame", sliderKnob)
knobShadow.Size = UDim2.new(1, 6, 1, 6)
knobShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
knobShadow.AnchorPoint = Vector2.new(0.5, 0.5)
knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
knobShadow.BackgroundTransparency = 1
knobShadow.BorderSizePixel = 0
knobShadow.ZIndex = 9
Instance.new("UICorner", knobShadow).CornerRadius = UDim.new(1, 0)

local touchHitbox = Instance.new("TextButton", speedContainer)
touchHitbox.Size = UDim2.new(0, 40, 0, 40)
touchHitbox.Position = UDim2.new(0.5, -20, 0, 11)
touchHitbox.BackgroundTransparency = 1
touchHitbox.Text = ""
touchHitbox.ZIndex = 12
touchHitbox.Active = true

local currentSpeed = 1.0
local MIN_SPEED = 0.1
local MAX_SPEED = 3.0
local currentTrack = nil

local function updateSpeedVisual(speed)
	currentSpeed = math.clamp(speed, MIN_SPEED, MAX_SPEED)
	speedLabel.Text = string.format("Speed: %.1fx", currentSpeed)

	local percent = (currentSpeed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
	sliderKnob.Position = UDim2.new(percent, -10, 0, 23)
	touchHitbox.Position = UDim2.new(percent, -20, 0, 11)
	sliderFill.Size = UDim2.new(percent, 0, 1, 0)

	if currentTrack and currentTrack.IsPlaying then
		currentTrack:AdjustSpeed(currentSpeed)
	end
	sliderFill.BackgroundColor3 = COLORS.Primary 
end

local dragging = false

local function updateSliderFromInput(input)
	local trackPos = sliderTrack.AbsolutePosition.X
	local trackSize = sliderTrack.AbsoluteSize.X
	local mouseX = input.Position.X
	local percent = math.clamp((mouseX - trackPos) / trackSize, 0, 1)
	local speed = MIN_SPEED + (percent * (MAX_SPEED - MIN_SPEED))
	updateSpeedVisual(speed)
end

local function startDrag(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		updateSliderFromInput(input)
		TweenService:Create(sliderKnob, TweenInfo.new(0.1), {
			Size = UDim2.new(0, 24, 0, 24),
			BackgroundTransparency = 0
		}):Play()
	end
end

local function endDrag(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
		TweenService:Create(sliderKnob, TweenInfo.new(0.1), {
			Size = UDim2.new(0, 20, 0, 20),
			BackgroundTransparency = 0
		}):Play()
	end
end

sliderKnob.InputBegan:Connect(startDrag)
sliderKnob.InputEnded:Connect(endDrag)
touchHitbox.InputBegan:Connect(startDrag)
touchHitbox.InputEnded:Connect(endDrag)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
		input.UserInputType == Enum.UserInputType.Touch) then
		updateSliderFromInput(input)
	end
end)

sliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.UserInputType == Enum.UserInputType.Touch then
		updateSliderFromInput(input)
		dragging = true
	end
end)

sliderTrack.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

sliderKnob.MouseEnter:Connect(function()
	if not dragging then
		TweenService:Create(sliderKnob, TweenInfo.new(0.15), {
			Size = UDim2.new(0, 22, 0, 22),
			BackgroundTransparency = 0
		}):Play()
	end
end)

sliderKnob.MouseLeave:Connect(function()
	if not dragging then
		TweenService:Create(sliderKnob, TweenInfo.new(0.15), {
			Size = UDim2.new(0, 20, 0, 20),
			BackgroundTransparency = 0
		}):Play()
	end
end)

local dancesList = Instance.new("ScrollingFrame", sidebar)
dancesList.Size = UDim2.new(1, -20, 1, -160)
dancesList.Position = UDim2.new(0, 10, 0, 108)
dancesList.BackgroundTransparency = 1
dancesList.ScrollBarThickness = 4
dancesList.ScrollBarImageColor3 = COLORS.Accent
dancesList.AutomaticCanvasSize = Enum.AutomaticSize.Y
dancesList.VerticalScrollBarInset = Enum.ScrollBarInset.Always
dancesList.BorderSizePixel = 0
dancesList.ZIndex = 10
Instance.new("UIListLayout", dancesList).Padding = UDim.new(0, 6)

local emotesList = dancesList:Clone()
emotesList.Parent = sidebar
emotesList.Visible = false

local stopBtn = Instance.new("TextButton", sidebar)
stopBtn.Size = UDim2.new(1, -30, 0, 34)
stopBtn.Position = UDim2.new(0, 15, 1, -40)
stopBtn.BackgroundColor3 = COLORS.Primary
stopBtn.BackgroundTransparency = 0
stopBtn.Text = "Stop Animate"
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 16
stopBtn.TextColor3 = COLORS.Text
stopBtn.BorderSizePixel = 0
stopBtn.ZIndex = 10
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

local dances = {
	{name="DANCE1", animId=78416657618448},
	{name="DANCE2", animId=129373064455405},
	{name="DANCE3", animId=103948800984170},
	{name="DANCE4", animId=97086109091396},
	{name="DANCE5", animId=136095999219650},
	{name="DANCE6", animId=122254727316758},
	{name="DANCE7", animId=80933111363555},
	{name="DANCE8", animId=108759656834820},
	{name="DANCE9", animId=73314582348097},
	{name="DANCE10", animId=90518809140968},
	{name="DANCE11", animId=111257123835413},
	{name="DANCE12", animId=110494040742516},
	{name="DANCE13", animId=108804088066424},
	{name="DANCE14", animId=129764254213842},
	{name="DANCE15", animId=116835198609765},
	{name="DANCE16", animId=94480432559942},
	{name="DANCE17", animId=122719596509695},
	{name="DANCE18", animId=86501318752546},
	{name="DANCE19", animId=123471454475978},
	{name="DANCE20", animId=79689692681563},
	{name="DANCE21", animId=96147994216119},
	{name="DANCE22", animId=125724450808506},
	{name="DANCE23", animId=104149584253673},
	{name="DANCE24", animId=111754856931573},
	{name="DANCE25", animId=118468821959324},
	{name="DANCE26", animId=96100759913198},
	{name="DANCE27", animId=87282442358351},
	{name="DANCE28", animId=109364514498221},
	{name="DANCE29", animId=93062298566806},
	{name="DANCE30", animId=102864411236212},
	{name="DANCE31", animId=112534296956901},
	{name="DANCE32", animId=89558401923098},
	{name="DANCE33", animId=126771729094882},
	{name="DANCE34", animId=103710256055561},
	{name="DANCE35", animId=80621140833482},
	{name="DANCE36", animId=95127716920692},
	{name="DANCE37", animId=126597745883758},
	{name="DANCE38", animId=122727126017172},
	{name="DANCE39", animId=121966805049108},
	{name="DANCE40", animId=89794141549021},
	{name="DANCE41", animId=138671912289772},
	{name="DANCE42", animId=75117155576035},
	{name="DANCE43", animId=83650099589962},
	{name="DANCE44", animId=118552217459650},
	{name="DANCE45", animId=94593166146998},
	{name="DANCE46", animId=92354174724298},
	{name="DANCE47", animId=107075698225441},
	{name="DANCE48", animId=88050523705839},
	{name="DANCE49", animId=98046572213579},
	{name="DANCE50", animId=105075698225441},
	{name="DANCE51", animId=89794141549021},
	{name="DANCE52", animId=138671912289772},
	{name="DANCE53", animId=122727126017172},
	{name="DANCE54", animId=96100759913198},
}

local emotes = {
	{name="EMOTE1", animId=507770239},
	{name="EMOTE2", animId=507776043},
	{name="EMOTE3", animId=507770677},
	{name="EMOTE4", animId=99622371046192},
	{name="EMOTE5", animId=126899447275562},
	{name="EMOTE6", animId=112082806790047},
	{name="EMOTE7", animId=105824857171709},
	{name="EMOTE8", animId=132760747409859},
	{name="EMOTE9", animId=74129426877661},
	{name="EMOTE10", animId=77139456213922},
	{name="EMOTE11", animId=80222624644964},
	{name="EMOTE12", animId=100698821205549},
	{name="EMOTE13", animId=115257437995638},
	{name="EMOTE14", animId=109030594660124},
	{name="EMOTE15", animId=125706053264171},
	{name="EMOTE16", animId=98352002677627},
	{name="EMOTE17", animId=85945097006032},
	{name="EMOTE18", animId=123975418223144},
	{name="EMOTE19", animId=106808430180168},
	{name="EMOTE20", animId=124522818196151},
	{name="EMOTE21", animId=96308221977337},
	{name="EMOTE22", animId=128941887300629},
	{name="EMOTE23", animId=100678061110922},
	{name="EMOTE24", animId=104595291484684},
	{name="EMOTE25", animId=88042477607072},
	{name="EMOTE26", animId=117597565445349},
	{name="EMOTE27", animId=132798681855515},
	{name="EMOTE28", animId=74231110404376},
	{name="EMOTE29", animId=138859415166285},
	{name="EMOTE30", animId=138591721528570},
	{name="EMOTE31", animId=138706623195970},
	{name="EMOTE32", animId=111251252458517},
	{name="EMOTE33", animId=10214319518},
	{name="EMOTE34", animId=127626736897320},
	{name="EMOTE35", animId=80879471830819},
	{name="EMOTE36", animId=96731289267640},
	{name="EMOTE37", animId=107990372400562}
}

local function playEmote(animId)
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	if currentTrack then
		currentTrack:Stop()
		currentTrack:Destroy()
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://"..animId
	currentTrack = humanoid:LoadAnimation(anim)
	currentTrack:Play()
	currentTrack:AdjustSpeed(currentSpeed)
end

stopBtn.MouseButton1Click:Connect(function()
	if currentTrack then
		currentTrack:Stop()
		currentTrack:Destroy()
		currentTrack = nil
	end
end)

local function addButton(parent, entry)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = COLORS.Button
	btn.BackgroundTransparency = 0
	btn.TextColor3 = COLORS.Text
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 16
	btn.Text = entry.name
	btn.BorderSizePixel = 0
	btn.ZIndex = 10
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.MouseButton1Click:Connect(function() playEmote(entry.animId) end)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {
			BackgroundColor3 = COLORS.ButtonHover,
			BackgroundTransparency = 0
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {
			BackgroundColor3 = COLORS.Button,
			BackgroundTransparency = 0
		}):Play()
	end)
end

for _, d in ipairs(dances) do addButton(dancesList, d) end
for _, e in ipairs(emotes) do addButton(emotesList, e) end

local activeTab = "dances"
local function setActiveTab(tab)
	activeTab = tab
	dancesList.Visible = (tab == "dances")
	emotesList.Visible = (tab == "emotes")

	TweenService:Create(dancesTab, TweenInfo.new(0.2), {
		BackgroundColor3 = (tab == "dances") and COLORS.Active or COLORS.Button,
		BackgroundTransparency = 0
	}):Play()

	TweenService:Create(emotesTab, TweenInfo.new(0.2), {
		BackgroundColor3 = (tab == "emotes") and COLORS.Active or COLORS.Button,
		BackgroundTransparency = 0
	}):Play()

end

setActiveTab("dances")
dancesTab.MouseButton1Click:Connect(function() setActiveTab("dances") end)
emotesTab.MouseButton1Click:Connect(function() setActiveTab("emotes") end)

-- ==========================================
-- SENSOR KLIK CERDAS & CROSS-UI HIDING
-- ==========================================
local visible = false
local function setSidebarVisible(v)
	visible = v
	closeOverlay.Visible = v 
	toggleBtn.Visible = not v

	-- [KARINA FIX] Berkomunikasi dengan UI Musik untuk menyembunyikannya
	local musicUI = playerGui:FindFirstChild("SidebarMusicUI")
	if musicUI then
		local musicBtn = musicUI:FindFirstChild("MusicToggleBtn")
		if musicBtn then
			-- Jika panel Pose terbuka, paksa sembunyikan toggle Music
			musicBtn.Visible = not v
		end
	end

	local targetX = v and SIDE_VISIBLE_X or SIDE_HIDDEN_X
	TweenService:Create(sidebar, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, targetX, 0.5, -SIDE_HEIGHT/2 + SIDE_VERTICAL_ADJUST)
	}):Play()
end

toggleBtn.MouseButton1Click:Connect(function()
	setSidebarVisible(not visible)
end)

closeOverlay.MouseButton1Click:Connect(function()
	setSidebarVisible(false)
end)

updateSpeedVisual(1.0)