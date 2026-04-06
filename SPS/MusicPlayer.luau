-- MusicPlayerSystem -- StarterPlayerScripts --
-- Dibuat oleh Karina (No Static Title, Big Song Title, & Compact Layout)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService") 

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local uiName = "SidebarMusicUI"
local oldUi = playerGui:FindFirstChild(uiName)
if oldUi then oldUi:Destroy() end

local localSound = SoundService:FindFirstChild("KarinaLocalMusic")
if not localSound then
	localSound = Instance.new("Sound")
	localSound.Name = "KarinaLocalMusic"
	localSound.Parent = SoundService
end
localSound.Volume = 0.5
localSound.Looped = false

local SIDE_WIDTH = 250
local SIDE_HEIGHT = 280 
local SIDE_VISIBLE_X = 20
local SIDE_HIDDEN_X = -SIDE_WIDTH - 20

local COLORS = {
	Background = Color3.fromRGB(20, 45, 85),     
	Panel = Color3.fromRGB(40, 75, 125),         
	Button = Color3.fromRGB(30, 59, 103),        
	Active = Color3.fromRGB(247, 173, 175),      
	Primary = Color3.fromRGB(247, 173, 175),     
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(175, 195, 225),
	Accent = Color3.fromRGB(247, 173, 175)
}

local ICONS = {
	Next = "rbxassetid://76721791659054",
	Prev = "rbxassetid://78003809338896",
	Play = "rbxassetid://135801850600261",
	Pause = "rbxassetid://137487032567277",
	Repeat = "rbxassetid://121672310190692",
	Volume = "rbxassetid://91259334550163"
}

local gui = Instance.new("ScreenGui")
gui.Name = uiName
gui.IgnoreGuiInset = false 
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- ==========================================
-- TOMBOL TOGGLE 
-- ==========================================
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Name = "MusicToggleBtn"
toggleBtn.Size = UDim2.new(0, 110, 0, 46) 
toggleBtn.AnchorPoint = Vector2.new(0, 0)
toggleBtn.Position = UDim2.new(0, 20, 0, 66) 
toggleBtn.BackgroundTransparency = 1 
toggleBtn.Text = ""
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 10

local btnBg = Instance.new("Frame", toggleBtn)
btnBg.AnchorPoint = Vector2.new(0, 0.5)
btnBg.Position = UDim2.new(0, 0, 0.5, 0)
btnBg.Size = UDim2.new(1, 0, 0, 28) 
btnBg.BackgroundColor3 = COLORS.Background 
btnBg.BackgroundTransparency = 0.15
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
toggleIcon.AnchorPoint = Vector2.new(0, 0.5)
toggleIcon.Position = UDim2.new(0, 5, 0.5, 0)
toggleIcon.Size = UDim2.new(0, 46, 0, 46)
toggleIcon.BackgroundTransparency = 1
toggleIcon.Image = "rbxassetid://131463298653584"
toggleIcon.ZIndex = 11

local toggleText = Instance.new("TextLabel", toggleBtn)
toggleText.AnchorPoint = Vector2.new(0, 0.5)
toggleText.Position = UDim2.new(0, 59, 0.5, 0)
toggleText.Size = UDim2.new(1, -59, 0, 28)
toggleText.BackgroundTransparency = 1
toggleText.Text = "Music"
toggleText.Font = Enum.Font.GothamBold
toggleText.TextColor3 = COLORS.Text
toggleText.TextSize = 16
toggleText.TextXAlignment = Enum.TextXAlignment.Left
toggleText.ZIndex = 11

toggleBtn.MouseEnter:Connect(function() TweenService:Create(btnBg, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play() end)
toggleBtn.MouseLeave:Connect(function() TweenService:Create(btnBg, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play() end)

-- ==========================================
-- SIDEBAR PREMIUM
-- ==========================================
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIDE_WIDTH, 0, SIDE_HEIGHT)
sidebar.Position = UDim2.new(0, SIDE_HIDDEN_X, 0.5, 0) 
sidebar.AnchorPoint = Vector2.new(0, 0.5)
sidebar.BackgroundColor3 = COLORS.Background
sidebar.BackgroundTransparency = 0.05 
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 10
sidebar.Parent = gui
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

local sStroke = Instance.new("UIStroke", sidebar)
sStroke.Color = COLORS.Accent
sStroke.Thickness = 1
sStroke.Transparency = 0.6

-- [KARINA] Judul Lagu menjadi Centerpiece dengan Font Lebih Besar
local nowPlayingLabel = Instance.new("TextLabel", sidebar)
nowPlayingLabel.Size = UDim2.new(1, -30, 0, 20)
nowPlayingLabel.Position = UDim2.new(0, 15, 0, 15)
nowPlayingLabel.BackgroundTransparency = 1
nowPlayingLabel.Text = "Menunggu lagu..."
nowPlayingLabel.Font = Enum.Font.GothamBold
nowPlayingLabel.TextColor3 = COLORS.Accent
nowPlayingLabel.TextSize = 14
nowPlayingLabel.TextXAlignment = Enum.TextXAlignment.Left
nowPlayingLabel.TextTruncate = Enum.TextTruncate.AtEnd
nowPlayingLabel.ZIndex = 11

local clientHint = Instance.new("TextLabel", sidebar)
clientHint.Size = UDim2.new(1, -30, 0, 12)
clientHint.Position = UDim2.new(0, 15, 0, 38)
clientHint.BackgroundTransparency = 1
clientHint.Text = "Hanya kamu yang dapat mendengar musik ini."
clientHint.Font = Enum.Font.GothamMedium
clientHint.TextColor3 = COLORS.TextDim
clientHint.TextSize = 9
clientHint.TextXAlignment = Enum.TextXAlignment.Left
clientHint.ZIndex = 11

-- ==========================================
-- KONTROL MEDIA
-- ==========================================
local controlsContainer = Instance.new("Frame", sidebar)
controlsContainer.Size = UDim2.new(1, 0, 0, 30)
controlsContainer.Position = UDim2.new(0, 0, 0, 60)
controlsContainer.BackgroundTransparency = 1
controlsContainer.ZIndex = 11

local controlList = Instance.new("UIListLayout", controlsContainer)
controlList.FillDirection = Enum.FillDirection.Horizontal
controlList.HorizontalAlignment = Enum.HorizontalAlignment.Center
controlList.VerticalAlignment = Enum.VerticalAlignment.Center
controlList.Padding = UDim.new(0, 10)

local function createControlBtn(iconId, btnSize)
	local btn = Instance.new("TextButton", controlsContainer)
	btn.Size = UDim2.new(0, btnSize, 0, 30)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.ZIndex = 12

	local icon = Instance.new("ImageLabel", btn)
	icon.Size = UDim2.new(0.6, 0, 0.6, 0)
	icon.Position = UDim2.new(0.2, 0, 0.2, 0)
	icon.BackgroundTransparency = 1
	icon.Image = iconId
	icon.ImageColor3 = COLORS.Text
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 12

	btn.MouseEnter:Connect(function() TweenService:Create(icon, TweenInfo.new(0.1), {ImageColor3 = COLORS.Accent}):Play() end)
	btn.MouseLeave:Connect(function() TweenService:Create(icon, TweenInfo.new(0.1), {ImageColor3 = COLORS.Text}):Play() end)
	return btn, icon
end

local btnPrev, iconPrev = createControlBtn(ICONS.Prev, 30)
local btnPlay, iconPlay = createControlBtn(ICONS.Play, 38)
local btnNext, iconNext = createControlBtn(ICONS.Next, 30)
local btnRepeat, iconRepeat = createControlBtn(ICONS.Repeat, 30)
local btnVol, iconVol = createControlBtn(ICONS.Volume, 30)

iconPlay.Size = UDim2.new(0.7, 0, 0.7, 0)
iconPlay.Position = UDim2.new(0.15, 0, 0.15, 0)

iconRepeat.ImageColor3 = COLORS.TextDim
btnRepeat.MouseLeave:Connect(function() 
	TweenService:Create(iconRepeat, TweenInfo.new(0.1), {ImageColor3 = localSound.Looped and COLORS.Accent or COLORS.TextDim}):Play() 
end)

-- ==========================================
-- VERTICAL VOLUME POPUP 
-- ==========================================
local volPopup = Instance.new("Frame", sidebar)
volPopup.Size = UDim2.new(0, 40, 0, 110)
volPopup.Position = UDim2.new(1, 10, 0, 25) 
volPopup.BackgroundColor3 = COLORS.Background
volPopup.BackgroundTransparency = 0.05
volPopup.Visible = false
volPopup.ZIndex = 10
Instance.new("UICorner", volPopup).CornerRadius = UDim.new(0, 8)
local vStroke = Instance.new("UIStroke", volPopup)
vStroke.Color = COLORS.Accent
vStroke.Transparency = 0.6

local volTrack = Instance.new("Frame", volPopup)
volTrack.Size = UDim2.new(0, 4, 1, -20)
volTrack.Position = UDim2.new(0.5, -2, 0, 10)
volTrack.BackgroundColor3 = COLORS.Panel
volTrack.BorderSizePixel = 0
volTrack.ZIndex = 11
Instance.new("UICorner", volTrack).CornerRadius = UDim.new(1, 0)

local volFill = Instance.new("Frame", volTrack)
volFill.AnchorPoint = Vector2.new(0, 1) 
volFill.Position = UDim2.new(0, 0, 1, 0)
volFill.Size = UDim2.new(1, 0, 0.5, 0)
volFill.BackgroundColor3 = COLORS.Accent
volFill.BorderSizePixel = 0
volFill.ZIndex = 11
Instance.new("UICorner", volFill).CornerRadius = UDim.new(1, 0)

local volKnob = Instance.new("TextButton", volPopup)
volKnob.Size = UDim2.new(0, 14, 0, 14)
volKnob.Position = UDim2.new(0.5, -7, 0.5, -7)
volKnob.BackgroundColor3 = COLORS.Text
volKnob.Text = ""
volKnob.ZIndex = 12
Instance.new("UICorner", volKnob).CornerRadius = UDim.new(1, 0)

local volHitbox = Instance.new("TextButton", volPopup)
volHitbox.Size = UDim2.new(1, 0, 1, 0)
volHitbox.BackgroundTransparency = 1
volHitbox.Text = ""
volHitbox.ZIndex = 13

btnVol.MouseButton1Click:Connect(function()
	volPopup.Visible = not volPopup.Visible
end)

-- ==========================================
-- INPUT CUSTOM ID 
-- ==========================================
local inputContainer = Instance.new("Frame", sidebar)
inputContainer.Size = UDim2.new(1, -30, 0, 32)
inputContainer.Position = UDim2.new(0, 15, 0, 98)
inputContainer.BackgroundTransparency = 1
inputContainer.ZIndex = 11

local idInput = Instance.new("TextBox", inputContainer)
idInput.Size = UDim2.new(0.7, -5, 1, 0)
idInput.BackgroundColor3 = COLORS.Panel
idInput.BackgroundTransparency = 0.3 
idInput.Text = ""
idInput.PlaceholderText = "Paste Audio ID..."
idInput.Font = Enum.Font.Gotham
idInput.TextSize = 11
idInput.TextColor3 = COLORS.Text
idInput.ZIndex = 12
Instance.new("UICorner", idInput).CornerRadius = UDim.new(0, 6)

local addBtn = Instance.new("TextButton", inputContainer)
addBtn.Size = UDim2.new(0.3, 0, 1, 0)
addBtn.Position = UDim2.new(0.7, 5, 0, 0)
addBtn.BackgroundColor3 = COLORS.Accent
addBtn.Text = "ADD"
addBtn.Font = Enum.Font.GothamBold
addBtn.TextColor3 = COLORS.Background
addBtn.TextSize = 11
addBtn.ZIndex = 12
Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- SCROLLING LIST
-- ==========================================
local songListFrame = Instance.new("ScrollingFrame", sidebar)
songListFrame.Size = UDim2.new(1, -30, 1, -148)
songListFrame.Position = UDim2.new(0, 15, 0, 138)
songListFrame.BackgroundTransparency = 1
songListFrame.ScrollBarThickness = 2
songListFrame.ScrollBarImageColor3 = COLORS.Accent
songListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
songListFrame.ZIndex = 11

local sListLayout = Instance.new("UIListLayout", songListFrame)
sListLayout.Padding = UDim.new(0, 4)
sListLayout.SortOrder = Enum.SortOrder.LayoutOrder 

-- ==========================================
-- SISTEM LOGIKA MUSIK & DIVIDER
-- ==========================================
local playlist = {
	{name = "Bintang 5", id = "134435445558993"},
	{name = "sayang culik aku dong", id = "119254319180287"},
	{name = "tabola bale", id = "104207837699519"},
	{name = "kita usahakan lagi", id = "96077163288111"},
	{name = "dola", id = "139590201617508"},
	{name = "Multo", id = "97574638837693"}
}

local currentIndex = 0
local isPlaying = false

local function playSong(index)
	if index < 1 or index > #playlist then return end
	currentIndex = index

	local song = playlist[currentIndex]
	nowPlayingLabel.Text = song.name
	nowPlayingLabel.TextColor3 = COLORS.Accent 
	localSound.SoundId = "rbxassetid://" .. song.id

	localSound:Play()
	isPlaying = true
	iconPlay.Image = ICONS.Pause

	for _, child in ipairs(songListFrame:GetChildren()) do
		if child:IsA("TextButton") then
			if child.Name == tostring(index) then
				child.BackgroundTransparency = 0.5
				child.BackgroundColor3 = COLORS.Panel
				child.TextColor3 = COLORS.Accent
			else
				child.BackgroundTransparency = 1
				child.TextColor3 = COLORS.TextDim
			end
		end
	end
end

local function togglePlayPause()
	if currentIndex == 0 and #playlist > 0 then
		playSong(1)
		return
	end

	if isPlaying then
		localSound:Pause()
		iconPlay.Image = ICONS.Play
		isPlaying = false
	else
		localSound:Resume()
		iconPlay.Image = ICONS.Pause
		isPlaying = true
	end
end

local function nextSong()
	if #playlist == 0 then return end
	local nextIdx = currentIndex + 1
	if nextIdx > #playlist then nextIdx = 1 end
	playSong(nextIdx)
end

local function prevSong()
	if #playlist == 0 then return end
	local prevIdx = currentIndex - 1
	if prevIdx < 1 then prevIdx = #playlist end
	playSong(prevIdx)
end

btnRepeat.MouseButton1Click:Connect(function()
	localSound.Looped = not localSound.Looped
	iconRepeat.ImageColor3 = localSound.Looped and COLORS.Accent or COLORS.TextDim
end)

localSound.Ended:Connect(function()
	if not localSound.Looped then nextSong() end
end)

btnPlay.MouseButton1Click:Connect(togglePlayPause)
btnNext.MouseButton1Click:Connect(nextSong)
btnPrev.MouseButton1Click:Connect(prevSong)

local function renderPlaylist()
	for _, child in ipairs(songListFrame:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
	end

	for i, song in ipairs(playlist) do
		local btn = Instance.new("TextButton", songListFrame)
		btn.Name = tostring(i)
		btn.LayoutOrder = i * 2 
		btn.Size = UDim2.new(1, -6, 0, 28)
		btn.BackgroundColor3 = COLORS.Panel
		btn.BackgroundTransparency = (i == currentIndex) and 0.5 or 1
		btn.TextColor3 = (i == currentIndex) and COLORS.Accent or COLORS.TextDim
		btn.Text = "  " .. song.name
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.BorderSizePixel = 0
		btn.ZIndex = 12
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

		btn.MouseButton1Click:Connect(function() playSong(i) end)
		btn.MouseEnter:Connect(function() 
			if i ~= currentIndex then TweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = COLORS.Text}):Play() end
		end)
		btn.MouseLeave:Connect(function() 
			if i ~= currentIndex then TweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = COLORS.TextDim}):Play() end
		end)

		if i < #playlist then
			local divider = Instance.new("Frame", songListFrame)
			divider.Name = "Divider"
			divider.LayoutOrder = (i * 2) + 1 
			divider.Size = UDim2.new(1, -10, 0, 1)
			divider.BackgroundColor3 = COLORS.Panel
			divider.BackgroundTransparency = 0.3
			divider.BorderSizePixel = 0
			divider.ZIndex = 12
		end
	end
end
renderPlaylist()

-- ==========================================
-- MARKETPLACE VALIDATION & WARNING
-- ==========================================
addBtn.MouseButton1Click:Connect(function()
	local text = idInput.Text
	local extractedId = string.match(text, "%d+") 

	if extractedId then
		local numId = tonumber(extractedId)
		idInput.Text = ""
		idInput.PlaceholderText = "Mencari data lagu..."
		addBtn.Text = "..."
		addBtn.AutoButtonColor = false

		task.spawn(function()
			local success, info = pcall(function()
				return MarketplaceService:GetProductInfo(numId)
			end)

			if success and info and info.AssetTypeId == 3 then
				table.insert(playlist, {name = info.Name, id = extractedId})
				idInput.PlaceholderText = "Lagu ditambahkan!"
				renderPlaylist()

				nowPlayingLabel.Text = "?? Valid, tapi akan bisu jika audio di-private."
				nowPlayingLabel.TextColor3 = Color3.fromRGB(250, 204, 21) 

				task.delay(4, function()
					if nowPlayingLabel.Text == "?? Valid, tapi akan bisu jika audio di-private." then
						nowPlayingLabel.Text = isPlaying and playlist[currentIndex].name or "Menunggu lagu..."
						nowPlayingLabel.TextColor3 = COLORS.Accent
					end
				end)
			else
				idInput.PlaceholderText = "ID tidak valid/bukan Audio!"
			end

			addBtn.Text = "ADD"
			addBtn.AutoButtonColor = true
			task.wait(2)
			if idInput.PlaceholderText ~= "Paste Audio ID..." then
				idInput.PlaceholderText = "Paste Audio ID..."
			end
		end)
	else
		idInput.Text = ""
		idInput.PlaceholderText = "Format ID salah!"
		task.delay(2, function() idInput.PlaceholderText = "Paste Audio ID..." end)
	end
end)

-- ==========================================
-- LOGIKA VERTICAL VOLUME SLIDER
-- ==========================================
local draggingVol = false

local function updateVolumeVisual(vol)
	local clampedVol = math.clamp(vol, 0, 1)
	localSound.Volume = clampedVol

	local distFromTop = 1 - clampedVol 

	volKnob.Position = UDim2.new(0.5, -7, distFromTop, -7)
	volFill.Size = UDim2.new(1, 0, clampedVol, 0)
end

local function handleVolInput(input)
	local trackPos = volTrack.AbsolutePosition.Y
	local trackSize = volTrack.AbsoluteSize.Y
	local mouseY = input.Position.Y

	local percent = math.clamp((mouseY - trackPos) / trackSize, 0, 1)
	local volume = 1 - percent
	updateVolumeVisual(volume)
end

volHitbox.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingVol = true; handleVolInput(input)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingVol = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		handleVolInput(input)
	end
end)

updateVolumeVisual(0.5)

-- ==========================================
-- SENSOR KLIK CERDAS & CROSS-UI HIDING
-- ==========================================
local visible = false
local function setSidebarVisible(v)
	visible = v
	toggleBtn.Visible = not v

	local emoteUI = playerGui:FindFirstChild("SidebarEmoteUI")
	if emoteUI then
		local poseBtn = emoteUI:FindFirstChild("EmoteToggleBtn")
		if poseBtn then
			poseBtn.Visible = not v
		end
	end

	local targetX = v and SIDE_VISIBLE_X or SIDE_HIDDEN_X
	TweenService:Create(sidebar, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, targetX, 0.5, 0)
	}):Play()

	if not v then volPopup.Visible = false end 
end

toggleBtn.MouseButton1Click:Connect(function()
	setSidebarVisible(true)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if visible and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local pos = input.Position
		local sPos = sidebar.AbsolutePosition
		local sSize = sidebar.AbsoluteSize

		local inSidebar = (pos.X >= sPos.X and pos.X <= (sPos.X + sSize.X) and pos.Y >= sPos.Y and pos.Y <= (sPos.Y + sSize.Y))

		local inVol = false
		if volPopup.Visible then
			local vPos = volPopup.AbsolutePosition
			local vSize = volPopup.AbsoluteSize
			inVol = (pos.X >= vPos.X and pos.X <= (vPos.X + vSize.X) and pos.Y >= vPos.Y and pos.Y <= (vPos.Y + vSize.Y))
		end

		if not inSidebar and not inVol then
			setSidebarVisible(false)
		end
	end
end)