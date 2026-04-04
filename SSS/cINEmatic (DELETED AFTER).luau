--[[
    CINEMATIC GUI GENERATOR (STYLE: CLEAN SIDEBAR V6 - FULLY ALIGNED & LOWERED)
    Simpan script ini di ServerScriptService.
]]

local Players = game:GetService("Players")

local THEME = {
	MainBG = Color3.fromRGB(30, 59, 103),
	SidebarBG = Color3.fromRGB(20, 45, 85),
	CardBG = Color3.fromRGB(40, 75, 125),
	Accent = Color3.fromRGB(247, 173, 175),
	RobuxColor = Color3.fromRGB(46, 204, 113), 
	TextMain = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(175, 195, 225),
	Warning = Color3.fromRGB(239, 68, 68)
}
local FONT_GLOBAL = Enum.Font.Montserrat
local CLOSE_ICON = "rbxassetid://11293981586"

local MODES = {
	{Name = "Drone Zoom Out", Desc = "Mundur menjauh ke angkasa"},
	{Name = "Drone Zoom In", Desc = "Mendekat fokus ke objek"},
	{Name = "Zoom In Step", Desc = "Zoom Jitter style Spider-Verse"},
	{Name = "Orbit 360", Desc = "Berputar mengelilingi karakter"},
	{Name = "Cinematic Pan", Desc = "Geser kamera kiri ke kanan"},
	{Name = "Reveal Up", Desc = "Gerakan dari kaki ke kepala"},
	{Name = "Dolly Zoom", Desc = "Efek Vertigo (Background zoom)"}
}

local function BuildUI(player)
	local pGui = player:WaitForChild("PlayerGui", 20)
	if not pGui then return end

	if pGui:FindFirstChild("CinematicGUI") then pGui.CinematicGUI:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "CinematicGUI"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling 
	sg.DisplayOrder = 100 
	sg.Parent = pGui

	-- COUNTDOWN OVERLAY
	local cd = Instance.new("TextLabel", sg)
	cd.Name = "Countdown"
	cd.Size = UDim2.new(1, 0, 1, 0)
	cd.AnchorPoint = Vector2.new(0.5, 0.5)
	cd.Position = UDim2.new(0.5, 0, 0.5, 0)
	cd.BackgroundTransparency = 1
	cd.Font = Enum.Font.GothamBlack
	cd.Text = "3"
	cd.TextColor3 = THEME.TextMain
	cd.TextSize = 150
	cd.Visible = false
	cd.ZIndex = 9000
	local stroke = Instance.new("UIStroke", cd)
	stroke.Thickness = 4
	stroke.Color = THEME.SidebarBG

	-- MAIN FRAME (Container Utama)
	local main = Instance.new("Frame", sg)
	main.Name = "MainPanel"
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Size = UDim2.new(0.65, 0, 0.7, 0)
	-- [KARINA INFO] Titik Y diturunkan sebesar 0.03 (dari 0.55 menjadi 0.58) sesuai permintaan Tian.
	main.Position = UDim2.new(0.5, 0, 0.58, 0) 
	main.BackgroundColor3 = THEME.MainBG
	main.BorderSizePixel = 0
	main.Visible = false 
	main.ZIndex = 10
	Instance.new("UISizeConstraint", main).MaxSize = Vector2.new(900, 550)
	Instance.new("UIAspectRatioConstraint", main).AspectRatio = 1.65
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

	-- DIAMOND CLOSE BUTTON (OUTSIDE CONTAINER)
	local closeBg = Instance.new("Frame", main)
	closeBg.Name = "CloseBtn"
	closeBg.Size = UDim2.new(0, 32, 0, 32)
	closeBg.Position = UDim2.new(1, 0, 0, 0)
	closeBg.AnchorPoint = Vector2.new(0.5, 0.5)
	closeBg.BackgroundColor3 = THEME.Accent
	closeBg.ZIndex = 5000 
	closeBg.Rotation = 45 
	Instance.new("UICorner", closeBg).CornerRadius = UDim.new(0, 8)

	local closeBtnAction = Instance.new("TextButton", closeBg)
	closeBtnAction.Name = "Action"
	closeBtnAction.Size = UDim2.new(1, 0, 1, 0)
	closeBtnAction.BackgroundTransparency = 1
	closeBtnAction.Text = ""

	local closeIcon = Instance.new("ImageLabel", closeBg)
	closeIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
	closeIcon.Position = UDim2.new(0.25, 0, 0.25, 0)
	closeIcon.Image = CLOSE_ICON
	closeIcon.ImageColor3 = THEME.MainBG
	closeIcon.BackgroundTransparency = 1
	closeIcon.Rotation = -45

	-- SIDEBAR (LEFT PANEL)
	local sidebar = Instance.new("Frame", main)
	sidebar.Name = "LeftPanel"
	sidebar.Size = UDim2.new(0.25, 0, 1, 0)
	sidebar.BackgroundColor3 = THEME.SidebarBG
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

	local navList = Instance.new("UIListLayout", sidebar)
	navList.Padding = UDim.new(0, 10)
	navList.SortOrder = Enum.SortOrder.LayoutOrder
	navList.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local navPad = Instance.new("UIPadding", sidebar)
	navPad.PaddingTop = UDim.new(0, 30)

	local function createNav(name, text, order, isActive)
		local btn = Instance.new("TextButton", sidebar)
		btn.Name = name
		btn.Size = UDim2.new(0.85, 0, 0, 42)
		btn.BackgroundColor3 = THEME.Accent
		btn.BackgroundTransparency = isActive and 0 or 1
		btn.Text = text
		btn.Font = FONT_GLOBAL
		btn.TextSize = 12
		btn.TextColor3 = isActive and THEME.MainBG or THEME.TextMain
		btn.LayoutOrder = order
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		return btn
	end

	createNav("ModesNav", "MODES", 1, true)
	createNav("SettingsNav", "SETTINGS", 2, false)
	createNav("ParametersNav", "PARAMETERS", 3, false)

	-- RIGHT PANEL (CONTENT CONTAINER)
	local rightPanel = Instance.new("Frame", main)
	rightPanel.Name = "RightPanel"
	rightPanel.Position = UDim2.new(0.25, 0, 0, 0)
	rightPanel.Size = UDim2.new(0.75, 0, 1, 0)
	rightPanel.BackgroundTransparency = 1

	-- FIXED LAUNCH BAR (FULL WIDTH)
	local launchBar = Instance.new("Frame", rightPanel)
	launchBar.Name = "LaunchBar"
	launchBar.Size = UDim2.new(1, -60, 0, 45) 
	launchBar.Position = UDim2.new(0, 30, 1, -30)
	launchBar.AnchorPoint = Vector2.new(0, 1)
	launchBar.BackgroundTransparency = 1 

	local startBtn = Instance.new("TextButton", launchBar)
	startBtn.Name = "StartBtn"
	startBtn.Size = UDim2.new(1, 0, 1, 0) 
	startBtn.Position = UDim2.new(0, 0, 0, 0)
	startBtn.BackgroundColor3 = THEME.Accent
	startBtn.Text = "LAUNCH"
	startBtn.Font = FONT_GLOBAL
	startBtn.TextSize = 13
	startBtn.TextColor3 = THEME.MainBG
	Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 6)

	-- PAGE CONTAINER
	local pageContainer = Instance.new("Frame", rightPanel)
	pageContainer.Name = "PageContainer"
	pageContainer.Size = UDim2.new(1, 0, 1, -85)
	pageContainer.Position = UDim2.new(0, 0, 0, 0)
	pageContainer.BackgroundTransparency = 1

	-- PAGE 1: MODES
	local modesPage = Instance.new("ScrollingFrame", pageContainer)
	modesPage.Name = "ModesPage"
	modesPage.Size = UDim2.new(1, 0, 1, 0)
	modesPage.BackgroundTransparency = 1
	modesPage.ScrollBarThickness = 2
	modesPage.ScrollBarImageColor3 = THEME.Accent
	modesPage.ScrollingDirection = Enum.ScrollingDirection.Y
	modesPage.Visible = true

	local mpGrid = Instance.new("UIGridLayout", modesPage)
	mpGrid.CellSize = UDim2.new(0.46, 0, 0, 60)
	mpGrid.CellPadding = UDim2.new(0.03, 0, 0, 12)
	mpGrid.SortOrder = Enum.SortOrder.LayoutOrder

	local mpPad = Instance.new("UIPadding", modesPage)
	mpPad.PaddingTop = UDim.new(0, 25)
	mpPad.PaddingLeft = UDim.new(0, 30)
	mpPad.PaddingRight = UDim.new(0, 20)

	for i, mode in ipairs(MODES) do
		local btn = Instance.new("TextButton", modesPage)
		btn.Name = mode.Name
		btn.BackgroundColor3 = THEME.CardBG
		btn.Text = ""
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

		local t = Instance.new("TextLabel", btn)
		t.Text = mode.Name
		t.Size = UDim2.new(1, 0, 0, 20)
		t.Position = UDim2.new(0, 0, 0, 10)
		t.BackgroundTransparency = 1
		t.Font = FONT_GLOBAL
		t.TextColor3 = THEME.TextMain
		t.TextSize = 12
		t.TextXAlignment = Enum.TextXAlignment.Center

		local d = Instance.new("TextLabel", btn)
		d.Text = mode.Desc
		d.Size = UDim2.new(1, -10, 0, 15)
		d.Position = UDim2.new(0, 5, 0, 30)
		d.BackgroundTransparency = 1
		d.Font = FONT_GLOBAL
		d.TextColor3 = THEME.TextMuted
		d.TextSize = 10
		d.TextScaled = true
		d.TextXAlignment = Enum.TextXAlignment.Center
	end

	-- PAGE 2: SETTINGS (TOGGLES WITH DOTS)
	local settingsPage = Instance.new("ScrollingFrame", pageContainer)
	settingsPage.Name = "SettingsPage"
	settingsPage.Size = UDim2.new(1, 0, 1, 0)
	settingsPage.BackgroundTransparency = 1
	settingsPage.ScrollBarThickness = 0
	settingsPage.Visible = false

	local spList = Instance.new("UIListLayout", settingsPage)
	spList.Padding = UDim.new(0, 15)
	spList.SortOrder = Enum.SortOrder.LayoutOrder

	local spPad = Instance.new("UIPadding", settingsPage)
	spPad.PaddingTop = UDim.new(0, 30)
	spPad.PaddingLeft = UDim.new(0, 30)
	spPad.PaddingRight = UDim.new(0, 30)

	local function createToggleUI(name, text, parent)
		local btn = Instance.new("TextButton", parent)
		btn.Name = name
		-- [KARINA FIX] Lebar mutlak UDim2(1, 0) agar 100% sejajar dengan container Parameter & Launch Bar.
		btn.Size = UDim2.new(1, 0, 0, 50) 
		btn.BackgroundColor3 = THEME.CardBG
		btn.Text = ""
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

		local lbl = Instance.new("TextLabel", btn)
		lbl.Size = UDim2.new(0.8, 0, 1, 0)
		lbl.Position = UDim2.new(0, 20, 0, 0)
		lbl.Text = text
		lbl.Font = FONT_GLOBAL
		lbl.TextSize = 13
		lbl.TextColor3 = THEME.TextMain
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.BackgroundTransparency = 1

		local dot = Instance.new("Frame", btn)
		dot.Name = "StatusDot"
		dot.Size = UDim2.new(0, 14, 0, 14)
		dot.Position = UDim2.new(1, -30, 0.5, 0)
		dot.AnchorPoint = Vector2.new(0, 0.5)
		dot.BackgroundColor3 = THEME.RobuxColor
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	end

	createToggleUI("BarsToggle", "Cinematic Bars", settingsPage)
	createToggleUI("HeadToggle", "Head Tracking", settingsPage)
	createToggleUI("SloMoToggle", "Slow Motion Effects", settingsPage)

	-- PAGE 3: PARAMETERS (INPUT BOXES)
	local paramPage = Instance.new("ScrollingFrame", pageContainer)
	paramPage.Name = "ParametersPage"
	paramPage.Size = UDim2.new(1, 0, 1, 0)
	paramPage.BackgroundTransparency = 1
	paramPage.ScrollBarThickness = 0
	paramPage.Visible = false

	local ppList = Instance.new("UIListLayout", paramPage)
	ppList.Padding = UDim.new(0, 15)
	ppList.SortOrder = Enum.SortOrder.LayoutOrder

	local ppPad = Instance.new("UIPadding", paramPage)
	ppPad.PaddingTop = UDim.new(0, 30)
	ppPad.PaddingLeft = UDim.new(0, 30)
	ppPad.PaddingRight = UDim.new(0, 30)

	local function createInputGroup(name, labelText, defaultVal, parent)
		local frame = Instance.new("Frame", parent)
		frame.Size = UDim2.new(1, 0, 0, 50)
		frame.BackgroundColor3 = THEME.SidebarBG
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

		local lbl = Instance.new("TextLabel", frame)
		lbl.Size = UDim2.new(0.6, 0, 1, 0)
		lbl.Position = UDim2.new(0, 20, 0, 0)
		lbl.Text = labelText
		lbl.Font = FONT_GLOBAL
		lbl.TextSize = 13
		lbl.TextColor3 = THEME.TextMuted
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.BackgroundTransparency = 1

		local box = Instance.new("TextBox", frame)
		box.Name = name
		box.Size = UDim2.new(0.3, 0, 0, 30)
		box.Position = UDim2.new(1, -15, 0.5, 0)
		box.AnchorPoint = Vector2.new(1, 0.5)
		box.BackgroundColor3 = THEME.CardBG
		box.Text = tostring(defaultVal)
		box.Font = FONT_GLOBAL
		box.TextSize = 13
		box.TextColor3 = THEME.TextMain
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
	end

	createInputGroup("DurBox", "Duration (Seconds)", 5, paramPage)
	createInputGroup("DistBox", "Distance (Studs)", 20, paramPage)
	createInputGroup("HeightBox", "Height (Studs)", 10, paramPage)

	print("Sidebar UI V6 Generated (Fully Aligned & Lowered)! Silakan copy CinematicGUI dari PlayerGui.")
end

for _, p in pairs(Players:GetPlayers()) do task.spawn(BuildUI, p) end
Players.PlayerAdded:Connect(BuildUI)