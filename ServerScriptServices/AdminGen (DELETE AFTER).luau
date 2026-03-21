--[[
    ADMIN PANEL GUI GENERATOR (PURE BUILDER V38 - COLOR SYNC)
    Simpan script ini di ServerScriptService.
]]

local Players = game:GetService("Players")

local THEME = {
	MainBG = Color3.fromRGB(30, 59, 103),
	SidebarBG = Color3.fromRGB(20, 45, 85),
	CardBG = Color3.fromRGB(40, 75, 125),
	Accent = Color3.fromRGB(247, 173, 175),
	ElegantGive = Color3.fromRGB(59, 130, 246), 
	ElegantTake = Color3.fromRGB(225, 29, 72),  
	Success = Color3.fromRGB(46, 204, 113), 
	Warning = Color3.fromRGB(239, 68, 68),  
	TextMain = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(175, 195, 225),
	DarkerBG = Color3.fromRGB(15, 35, 65),
	FlyOn = Color3.fromRGB(167, 243, 208),  
	FlyOff = Color3.fromRGB(247, 173, 175)  
}

local FONT_GLOBAL = Enum.Font.Montserrat
local FONT_BOLD = Enum.Font.GothamBold
local CLOSE_ICON = "rbxassetid://11293981586"

local SHOP_CATEGORIES = {
	{ Title = "Currency", OrderBase = 10, Items = {{Name = "Coins", Type = "Currency", Id = "Coins"}} },
	{ Title = "Perks & Tools", OrderBase = 20, Items = {
		{Name = "VIP Access", Type = "Perk", Id = "HasVIP"}, {Name = "JetSolo", Type = "Perk", Id = "HasJetSolo"},
		{Name = "Hide Aura", Type = "Perk", Id = "HasHideAura"}, {Name = "Umbrella", Type = "Tool", Id = "Umbrella"},
		{Name = "Speed Coil", Type = "Tool", Id = "Speed Coil"}
	}},
	{ Title = "Auras", OrderBase = 30, Items = {
		{Name = "Chained Aura", Type = "Perk", Id = "HasChained"}, {Name = "Cosmic Aura", Type = "Perk", Id = "HasCosmic"},
		{Name = "Cubic Aura", Type = "Perk", Id = "HasCubic"}, {Name = "Dual Swords", Type = "Perk", Id = "HasDualSwords"},
		{Name = "Frost Aura", Type = "Perk", Id = "HasFrost"}, {Name = "Love Aura", Type = "Perk", Id = "HasLove"},
		{Name = "Poison Aura", Type = "Perk", Id = "HasPoison"}, {Name = "Powerless", Type = "Perk", Id = "HasPowerless"},
		{Name = "Sand Demon", Type = "Perk", Id = "HasSandDemon"}, {Name = "Sound Ninja", Type = "Perk", Id = "HasSoundNinja"},
		{Name = "Thunder God", Type = "Perk", Id = "HasThunderGod"}
	}}
}

local function BuildAdminUI(player)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then return end

	local pGui = player:WaitForChild("PlayerGui", 20)
	if not pGui then return end

	if pGui:FindFirstChild("AdminPanelGUI") then pGui.AdminPanelGUI:Destroy() end
	if pGui:FindFirstChild("MobileFlyGui") then pGui.MobileFlyGui:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "AdminPanelGUI"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling 
	sg.DisplayOrder = 50 

	local hubMenu = Instance.new("Frame", sg)
	hubMenu.Name = "HubMenu"
	hubMenu.Visible = false 
	hubMenu.AnchorPoint = Vector2.new(0.5, 0.5)
	hubMenu.Size = UDim2.new(0.55, 0, 0.55, 0) 
	hubMenu.Position = UDim2.new(0.5, 0, 0.5, 0) 
	hubMenu.BackgroundColor3 = THEME.MainBG
	hubMenu.BorderSizePixel = 0
	Instance.new("UISizeConstraint", hubMenu).MaxSize = Vector2.new(550, 380)
	Instance.new("UISizeConstraint", hubMenu).MinSize = Vector2.new(400, 280)
	Instance.new("UIAspectRatioConstraint", hubMenu).AspectRatio = 1.5
	Instance.new("UICorner", hubMenu).CornerRadius = UDim.new(0, 12)

	local hubCloseBg = Instance.new("Frame", hubMenu)
	hubCloseBg.Name = "CloseBtn"
	hubCloseBg.Size = UDim2.new(0, 32, 0, 32)
	hubCloseBg.Position = UDim2.new(1, -10, 0, -10)
	hubCloseBg.AnchorPoint = Vector2.new(1, 0)
	hubCloseBg.BackgroundColor3 = THEME.Accent
	hubCloseBg.ZIndex = 5000 
	hubCloseBg.Rotation = 45 
	Instance.new("UICorner", hubCloseBg).CornerRadius = UDim.new(0, 8)

	local hubCloseBtnAct = Instance.new("TextButton", hubCloseBg)
	hubCloseBtnAct.Name = "Action"
	hubCloseBtnAct.Size = UDim2.new(1, 0, 1, 0)
	hubCloseBtnAct.BackgroundTransparency = 1
	hubCloseBtnAct.Text = ""

	local hubCloseIcon = Instance.new("ImageLabel", hubCloseBg)
	hubCloseIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
	hubCloseIcon.Position = UDim2.new(0.25, 0, 0.25, 0)
	hubCloseIcon.Image = CLOSE_ICON
	hubCloseIcon.ImageColor3 = THEME.MainBG
	hubCloseIcon.BackgroundTransparency = 1
	hubCloseIcon.Rotation = -45

	local greeting = Instance.new("TextLabel", hubMenu)
	greeting.Name = "GreetingLabel"
	greeting.Size = UDim2.new(0.85, 0, 0.15, 0) 
	greeting.Position = UDim2.new(0.075, 0, 0.12, 0) 
	greeting.BackgroundTransparency = 1
	greeting.Text = "Hi, Admin,\nLagi mau ngapain?" 
	greeting.Font = FONT_BOLD
	greeting.TextColor3 = THEME.TextMain
	greeting.TextScaled = true
	greeting.TextWrapped = true 
	greeting.TextXAlignment = Enum.TextXAlignment.Left 
	greeting.TextYAlignment = Enum.TextYAlignment.Bottom 
	Instance.new("UITextSizeConstraint", greeting).MaxTextSize = 22 

	local btnContainer = Instance.new("Frame", hubMenu)
	btnContainer.Name = "BtnContainer"
	btnContainer.Size = UDim2.new(0.85, 0, 0.6, 0)
	btnContainer.Position = UDim2.new(0.075, 0, 0.32, 0)
	btnContainer.BackgroundTransparency = 1

	local homeGrid = Instance.new("UIGridLayout", btnContainer)
	homeGrid.CellSize = UDim2.new(0.48, 0, 0.22, 0)
	homeGrid.CellPadding = UDim2.new(0.04, 0, 0.04, 0)
	homeGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	homeGrid.VerticalAlignment = Enum.VerticalAlignment.Center
	homeGrid.SortOrder = Enum.SortOrder.LayoutOrder

	local function createHomeButton(name, text, order, customBg)
		local btn = Instance.new("TextButton", btnContainer)
		btn.Name = name
		btn.BackgroundColor3 = customBg or THEME.CardBG
		btn.Text = text
		btn.Font = FONT_BOLD
		btn.TextColor3 = THEME.TextMain
		btn.TextSize = 13 
		btn.TextScaled = true
		btn.LayoutOrder = order
		btn.TextXAlignment = Enum.TextXAlignment.Left 
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		Instance.new("UITextSizeConstraint", btn).MaxTextSize = 13
		Instance.new("UITextSizeConstraint", btn).MinTextSize = 9
		local pad = Instance.new("UIPadding", btn)
		pad.PaddingLeft = UDim.new(0.1, 0)
		pad.PaddingRight = UDim.new(0.05, 0)
	end

	createHomeButton("BtnSummit", "SUMMIT", 1)
	createHomeButton("BtnGift", "GIFT TITLE", 2)
	createHomeButton("BtnAnnounce", "ANNOUNCEMENT", 3)
	createHomeButton("BtnShop", "SHOP MANAGER", 4)
	createHomeButton("BtnFly", "FLY: DISABLED", 5, THEME.FlyOff) 
	createHomeButton("BtnExtra", "EXTRA MENU", 6)

	-- [KARINA] Mengembalikan warna default untuk Log dan Weather
	createHomeButton("BtnActivity", "ACTIVITY LOG", 7)
	createHomeButton("BtnWeather", "WEATHER", 8)

	local adminMenu = Instance.new("Frame", sg)
	adminMenu.Name = "AdminMenu"
	adminMenu.Visible = false 
	adminMenu.AnchorPoint = Vector2.new(0.5, 0.5)
	adminMenu.Size = UDim2.new(0.7, 0, 0.75, 0) 
	adminMenu.Position = UDim2.new(0.5, 0, 0.55, 0) 
	adminMenu.BackgroundColor3 = THEME.MainBG
	adminMenu.BorderSizePixel = 0
	Instance.new("UISizeConstraint", adminMenu).MaxSize = Vector2.new(900, 550)
	Instance.new("UIAspectRatioConstraint", adminMenu).AspectRatio = 1.65
	Instance.new("UICorner", adminMenu).CornerRadius = UDim.new(0, 12)

	local contentCloseBg = Instance.new("Frame", adminMenu)
	contentCloseBg.Name = "CloseBtn"
	contentCloseBg.Size = UDim2.new(0, 32, 0, 32)
	contentCloseBg.Position = UDim2.new(1, -10, 0, -10)
	contentCloseBg.AnchorPoint = Vector2.new(1, 0)
	contentCloseBg.BackgroundColor3 = THEME.Accent
	contentCloseBg.ZIndex = 5000 
	contentCloseBg.Rotation = 45 
	Instance.new("UICorner", contentCloseBg).CornerRadius = UDim.new(0, 8)

	local contentCloseBtnAct = Instance.new("TextButton", contentCloseBg)
	contentCloseBtnAct.Name = "Action"
	contentCloseBtnAct.Size = UDim2.new(1, 0, 1, 0)
	contentCloseBtnAct.BackgroundTransparency = 1
	contentCloseBtnAct.Text = ""

	local contentCloseIcon = Instance.new("ImageLabel", contentCloseBg)
	contentCloseIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
	contentCloseIcon.Position = UDim2.new(0.25, 0, 0.25, 0)
	contentCloseIcon.Image = CLOSE_ICON
	contentCloseIcon.ImageColor3 = THEME.MainBG
	contentCloseIcon.BackgroundTransparency = 1
	contentCloseIcon.Rotation = -45

	local backBtn = Instance.new("TextButton", adminMenu)
	backBtn.Name = "BackBtn"
	backBtn.Size = UDim2.new(0, 80, 0, 32)
	backBtn.Position = UDim2.new(0, 15, 0, 15)
	backBtn.BackgroundColor3 = THEME.SidebarBG
	backBtn.Text = "< BACK"
	backBtn.Font = FONT_BOLD
	backBtn.TextColor3 = THEME.Accent
	backBtn.TextSize = 14
	Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 8)

	local rightPanel = Instance.new("Frame", adminMenu)
	rightPanel.Name = "ContentContainer"
	rightPanel.Position = UDim2.new(0, 20, 0, 60) 
	rightPanel.Size = UDim2.new(1, -40, 1, -80)
	rightPanel.BackgroundTransparency = 1

	local function createPlayerList(parentFrame, prefixName)
		local listContainer = Instance.new("Frame", parentFrame)
		listContainer.Name = "PlayerListArea"
		listContainer.Size = UDim2.new(0.32, 0, 1, 0)
		listContainer.Position = UDim2.new(0, 0, 0, 0)
		listContainer.BackgroundColor3 = THEME.CardBG
		Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)

		local searchBox = Instance.new("TextBox", listContainer)
		searchBox.Name = "SearchBox"
		searchBox.Size = UDim2.new(0.9, 0, 0, 35)
		searchBox.AnchorPoint = Vector2.new(0.5, 0)
		searchBox.Position = UDim2.new(0.5, 0, 0.02, 0) 
		searchBox.BackgroundColor3 = THEME.DarkerBG
		searchBox.Text = ""
		searchBox.PlaceholderText = "Cari pemain..."
		searchBox.Font = FONT_GLOBAL
		searchBox.TextScaled = true
		searchBox.TextColor3 = THEME.TextMain
		Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
		Instance.new("UITextSizeConstraint", searchBox).MaxTextSize = 12

		local scrollFrame = Instance.new("ScrollingFrame", listContainer)
		scrollFrame.Name = prefixName .. "List"
		scrollFrame.Size = UDim2.new(0.9, 0, 1, -55) 
		scrollFrame.AnchorPoint = Vector2.new(0.5, 0)
		scrollFrame.Position = UDim2.new(0.5, 0, 0, 45) 
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.ScrollBarThickness = 3
		scrollFrame.ScrollBarImageColor3 = THEME.Accent
		scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
		scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

		local listLayout = Instance.new("UIListLayout", scrollFrame)
		listLayout.Padding = UDim.new(0, 5)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder

		return listContainer
	end

	local function createSectionTitle(text, parent)
		local lbl = Instance.new("TextLabel", parent)
		lbl.Size = UDim2.new(1, 0, 0, 15)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.Font = FONT_GLOBAL
		lbl.TextColor3 = THEME.TextMuted
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		return lbl 
	end

	local function createSeparator(parent, order)
		local line = Instance.new("Frame", parent)
		line.Size = UDim2.new(1, -12, 0, 1)
		line.BackgroundColor3 = THEME.TextMuted
		line.BackgroundTransparency = 0.8
		line.BorderSizePixel = 0
		line.LayoutOrder = order
		return line
	end

	-- ================== CONFIRMATION MODAL ==================
	local confirmModal = Instance.new("Frame", adminMenu)
	confirmModal.Name = "ConfirmModal"
	confirmModal.Size = UDim2.new(1, 0, 1, 0)
	confirmModal.Position = UDim2.new(0, 0, 0, 0)
	confirmModal.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
	confirmModal.BackgroundTransparency = 0.3
	confirmModal.Visible = false
	confirmModal.ZIndex = 100
	Instance.new("UICorner", confirmModal).CornerRadius = UDim.new(0, 12)

	local cmBox = Instance.new("Frame", confirmModal)
	cmBox.Size = UDim2.new(0.5, 0, 0.4, 0)
	cmBox.Position = UDim2.new(0.25, 0, 0.3, 0)
	cmBox.BackgroundColor3 = THEME.MainBG
	cmBox.ZIndex = 101
	Instance.new("UICorner", cmBox).CornerRadius = UDim.new(0, 12)
	local cmStroke = Instance.new("UIStroke", cmBox)
	cmStroke.Color = THEME.Warning
	cmStroke.Thickness = 2

	local cmTitle = Instance.new("TextLabel", cmBox)
	cmTitle.Name = "TitleMessage"
	cmTitle.Size = UDim2.new(0.9, 0, 0.5, 0)
	cmTitle.Position = UDim2.new(0.05, 0, 0.1, 0)
	cmTitle.BackgroundTransparency = 1
	cmTitle.Text = "Are you sure?"
	cmTitle.Font = FONT_BOLD
	cmTitle.TextColor3 = THEME.TextMain
	cmTitle.TextScaled = true
	cmTitle.TextWrapped = true
	cmTitle.ZIndex = 102
	Instance.new("UITextSizeConstraint", cmTitle).MaxTextSize = 20

	local btnYes = Instance.new("TextButton", cmBox)
	btnYes.Name = "BtnYes"
	btnYes.Size = UDim2.new(0.4, 0, 0, 35) 
	btnYes.Position = UDim2.new(0.075, 0, 0.65, 0)
	btnYes.BackgroundColor3 = THEME.Warning
	btnYes.Text = "YA, EKSEKUSI"
	btnYes.Font = FONT_BOLD
	btnYes.TextColor3 = THEME.TextMain
	btnYes.ZIndex = 102
	Instance.new("UICorner", btnYes).CornerRadius = UDim.new(0, 8)

	local btnNo = Instance.new("TextButton", cmBox)
	btnNo.Name = "BtnNo"
	btnNo.Size = UDim2.new(0.4, 0, 0, 35) 
	btnNo.Position = UDim2.new(0.525, 0, 0.65, 0)
	btnNo.BackgroundColor3 = THEME.SidebarBG
	btnNo.Text = "BATAL"
	btnNo.Font = FONT_BOLD
	btnNo.TextColor3 = THEME.TextMain
	btnNo.ZIndex = 102
	Instance.new("UICorner", btnNo).CornerRadius = UDim.new(0, 8)

	-- ================== PAGE A: SUMMIT ==================
	local pageA = Instance.new("Frame", rightPanel)
	pageA.Name = "Page_Summit"
	pageA.Size = UDim2.new(1, 0, 1, 0)
	pageA.BackgroundTransparency = 1
	pageA.Visible = false 
	createPlayerList(pageA, "Summit")

	local summitActions = Instance.new("Frame", pageA)
	summitActions.Name = "ActionArea"
	summitActions.Size = UDim2.new(0.65, 0, 1, 0)
	summitActions.Position = UDim2.new(0.35, 0, 0, 0)
	summitActions.BackgroundTransparency = 1

	local actionListA = Instance.new("UIListLayout", summitActions)
	actionListA.Padding = UDim.new(0, 8) 
	actionListA.SortOrder = Enum.SortOrder.LayoutOrder

	local selLabelA = Instance.new("TextLabel", summitActions)
	selLabelA.Name = "SelectedLabel"
	selLabelA.Size = UDim2.new(1, 0, 0, 20)
	selLabelA.BackgroundTransparency = 1
	selLabelA.Text = "Pemain: -"
	selLabelA.Font = FONT_BOLD
	selLabelA.TextColor3 = THEME.Accent
	selLabelA.TextSize = 14
	selLabelA.TextXAlignment = Enum.TextXAlignment.Left 
	local lblPad = Instance.new("UIPadding", selLabelA)
	lblPad.PaddingLeft = UDim.new(0, 5)

	local amountBox = Instance.new("TextBox", summitActions)
	amountBox.Name = "AmountInput"
	amountBox.Size = UDim2.new(1, -12, 0, 35)
	amountBox.BackgroundColor3 = THEME.CardBG
	amountBox.PlaceholderText = "Masukkan jumlah..."
	amountBox.Text = ""
	amountBox.Font = FONT_GLOBAL
	amountBox.TextColor3 = THEME.TextMain
	amountBox.TextSize = 14
	Instance.new("UICorner", amountBox).CornerRadius = UDim.new(0, 8)
	local txtPad = Instance.new("UIPadding", amountBox)
	txtPad.PaddingLeft = UDim.new(0, 10)

	local rowAddSub = Instance.new("Frame", summitActions)
	rowAddSub.Name = "RowAddSub"
	rowAddSub.Size = UDim2.new(1, -12, 0, 35)
	rowAddSub.BackgroundTransparency = 1

	local btnAdd = Instance.new("TextButton", rowAddSub)
	btnAdd.Name = "BtnAdd"
	btnAdd.Size = UDim2.new(0.48, 0, 1, 0)
	btnAdd.Position = UDim2.new(0, 0, 0, 0)
	btnAdd.BackgroundColor3 = THEME.ElegantGive
	btnAdd.Text = "+ ADD"
	btnAdd.Font = FONT_BOLD
	btnAdd.TextSize = 13
	btnAdd.TextColor3 = THEME.TextMain
	Instance.new("UICorner", btnAdd).CornerRadius = UDim.new(0, 8)

	local btnSub = Instance.new("TextButton", rowAddSub)
	btnSub.Name = "BtnSub"
	btnSub.Size = UDim2.new(0.48, 0, 1, 0)
	btnSub.Position = UDim2.new(0.52, 0, 0, 0)
	btnSub.BackgroundColor3 = THEME.ElegantTake
	btnSub.Text = "- SUB"
	btnSub.Font = FONT_BOLD
	btnSub.TextSize = 13
	btnSub.TextColor3 = THEME.TextMain
	Instance.new("UICorner", btnSub).CornerRadius = UDim.new(0, 8)

	local btnReset = Instance.new("TextButton", summitActions)
	btnReset.Name = "BtnReset"
	btnReset.Size = UDim2.new(1, -12, 0, 35)
	btnReset.BackgroundColor3 = THEME.DarkerBG
	btnReset.Text = "RESET SUMMIT"
	btnReset.Font = FONT_BOLD
	btnReset.TextSize = 13
	btnReset.TextColor3 = THEME.TextMain
	Instance.new("UICorner", btnReset).CornerRadius = UDim.new(0, 8)

	-- ================== PAGE B: GIFT ==================
	local pageB = Instance.new("Frame", rightPanel)
	pageB.Name = "Page_Gift"
	pageB.Size = UDim2.new(1, 0, 1, 0)
	pageB.BackgroundTransparency = 1
	pageB.Visible = false 
	createPlayerList(pageB, "Gift")

	local giftActions = Instance.new("ScrollingFrame", pageB)
	giftActions.Name = "SettingsArea"
	giftActions.Size = UDim2.new(0.65, 0, 1, 0)
	giftActions.Position = UDim2.new(0.35, 0, 0, 0)
	giftActions.BackgroundTransparency = 1
	giftActions.ScrollBarThickness = 3
	giftActions.ScrollBarImageColor3 = THEME.Accent
	giftActions.ScrollingDirection = Enum.ScrollingDirection.Y
	giftActions.AutomaticCanvasSize = Enum.AutomaticSize.Y
	giftActions.CanvasSize = UDim2.new(0, 0, 0, 0)

	local giftList = Instance.new("UIListLayout", giftActions)
	giftList.Padding = UDim.new(0, 8)
	giftList.SortOrder = Enum.SortOrder.LayoutOrder

	local selLabelB = selLabelA:Clone()
	selLabelB.Parent = giftActions

	createSectionTitle("Role Selection:", giftActions)
	local roleGridFrame = Instance.new("Frame", giftActions)
	roleGridFrame.Name = "RoleSelect"
	roleGridFrame.Size = UDim2.new(1, -12, 0, 30)
	roleGridFrame.BackgroundTransparency = 1
	local roleGrid = Instance.new("UIGridLayout", roleGridFrame)
	roleGrid.CellSize = UDim2.new(0.48, 0, 0, 25)
	roleGrid.CellPadding = UDim2.new(0.04, 0, 0, 8)

	local roles = {"Streamer", "Custom"}
	for _, r in ipairs(roles) do
		local btn = Instance.new("TextButton", roleGridFrame)
		btn.Name = r
		btn.BackgroundColor3 = THEME.CardBG
		btn.Text = r
		btn.Font = FONT_GLOBAL
		btn.TextColor3 = THEME.TextMain
		btn.TextSize = 11
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	end

	createSectionTitle("Custom Title Text:", giftActions)
	local customTextBox = Instance.new("TextBox", giftActions)
	customTextBox.Name = "CustomTitleInput"
	customTextBox.Size = UDim2.new(1, -12, 0, 35)
	customTextBox.BackgroundColor3 = THEME.CardBG
	customTextBox.PlaceholderText = "Tulis custom title..."
	customTextBox.Text = ""
	customTextBox.Font = FONT_GLOBAL
	customTextBox.TextColor3 = THEME.TextMain
	customTextBox.TextSize = 13
	Instance.new("UICorner", customTextBox).CornerRadius = UDim.new(0, 8)
	local customPad = Instance.new("UIPadding", customTextBox)
	customPad.PaddingLeft = UDim.new(0, 10)

	createSectionTitle("Font Style:", giftActions)
	local fontGridFrame = Instance.new("Frame", giftActions)
	fontGridFrame.Name = "FontSelect"
	fontGridFrame.Size = UDim2.new(1, -12, 0, 30) 
	fontGridFrame.BackgroundTransparency = 1
	local fontGrid = Instance.new("UIGridLayout", fontGridFrame)
	fontGrid.CellSize = UDim2.new(0.31, 0, 0, 25)
	fontGrid.CellPadding = UDim2.new(0.03, 0, 0, 8)

	local fonts = {"GothamBold", "Cartoony", "SourceSansBold"}
	for _, f in ipairs(fonts) do
		local btn = Instance.new("TextButton", fontGridFrame)
		btn.Name = f
		btn.BackgroundColor3 = THEME.CardBG
		btn.Text = (f == "GothamBold") and "Gotham" or (f == "Cartoony" and "Cartoon" or "Bold")
		local success, fontEnum = pcall(function() return Enum.Font[f] end)
		btn.Font = success and fontEnum or FONT_GLOBAL
		btn.TextColor3 = THEME.TextMain
		btn.TextSize = 11
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	end

	createSectionTitle("Title Color:", giftActions)
	local colorGridFrame = Instance.new("Frame", giftActions)
	colorGridFrame.Name = "ColorSelect"
	colorGridFrame.Size = UDim2.new(1, -12, 0, 30)
	colorGridFrame.BackgroundTransparency = 1
	local colorGrid = Instance.new("UIGridLayout", colorGridFrame)
	colorGrid.CellSize = UDim2.new(0, 25, 0, 25)
	colorGrid.CellPadding = UDim2.new(0, 12, 0, 8) 
	colorGrid.SortOrder = Enum.SortOrder.LayoutOrder

	local colors = { Kuning = Color3.fromRGB(253, 253, 150), Pink = Color3.fromRGB(255, 182, 193), Biru = Color3.fromRGB(174, 198, 207), AbuAbu = Color3.fromRGB(207, 207, 207) }
	for cName, cVal in pairs(colors) do
		local btn = Instance.new("TextButton", colorGridFrame)
		btn.Name = cName
		btn.BackgroundColor3 = cVal
		btn.Text = ""
		Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0) 
		if cName == "Pink" then
			local stroke = Instance.new("UIStroke")
			stroke.Name = "ActiveStroke"
			stroke.Thickness = 2
			stroke.Color = Color3.new(1,1,1)
			stroke.Parent = btn
		end
	end

	local applyBtn = Instance.new("TextButton", giftActions)
	applyBtn.Name = "ApplyBtn"
	applyBtn.Size = UDim2.new(1, -12, 0, 35)
	applyBtn.BackgroundColor3 = THEME.ElegantGive
	applyBtn.Text = "APPLY TITLE"
	applyBtn.Font = FONT_BOLD
	applyBtn.TextColor3 = THEME.TextMain
	applyBtn.TextSize = 13
	Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 8)

	local clearBtn = Instance.new("TextButton", giftActions)
	clearBtn.Name = "ClearBtn"
	clearBtn.Size = UDim2.new(1, -12, 0, 35)
	clearBtn.BackgroundColor3 = THEME.ElegantTake
	clearBtn.Text = "CLEAR TITLE"
	clearBtn.Font = FONT_BOLD
	clearBtn.TextColor3 = THEME.TextMain
	clearBtn.TextSize = 13
	Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 8)

	-- ================== PAGE C: ANNOUNCEMENT ==================
	local pageC = Instance.new("Frame", rightPanel)
	pageC.Name = "Page_Announce"
	pageC.Size = UDim2.new(0.9, 0, 1, 0)
	pageC.Position = UDim2.new(0.05, 0, 0, 0)
	pageC.BackgroundTransparency = 1
	pageC.Visible = false 

	local annLayout = Instance.new("UIListLayout", pageC)
	annLayout.Padding = UDim.new(0.04, 0)
	annLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local annInput = Instance.new("TextBox", pageC)
	annInput.Name = "AnnounceInput"
	annInput.Size = UDim2.new(1, 0, 0.6, 0)
	annInput.BackgroundColor3 = THEME.CardBG
	annInput.Text = ""
	annInput.PlaceholderText = "Tulis pesan pengumuman di sini..."
	annInput.Font = FONT_GLOBAL
	annInput.TextSize = 14
	annInput.TextColor3 = THEME.TextMain
	annInput.TextWrapped = true
	annInput.TextYAlignment = Enum.TextYAlignment.Top
	annInput.ClearTextOnFocus = false
	Instance.new("UICorner", annInput).CornerRadius = UDim.new(0, 8)
	local annPad = Instance.new("UIPadding", annInput)
	annPad.PaddingTop = UDim.new(0, 15)
	annPad.PaddingLeft = UDim.new(0, 15)
	annPad.PaddingRight = UDim.new(0, 15)

	local btnAreaC = Instance.new("Frame", pageC)
	btnAreaC.Name = "ButtonArea" 
	btnAreaC.Size = UDim2.new(1, 0, 0, 35)
	btnAreaC.BackgroundTransparency = 1

	local sendServerBtn = Instance.new("TextButton", btnAreaC)
	sendServerBtn.Name = "SendServer"
	sendServerBtn.Size = UDim2.new(0.48, 0, 1, 0)
	sendServerBtn.Position = UDim2.new(0, 0, 0, 0)
	sendServerBtn.BackgroundColor3 = THEME.SidebarBG
	sendServerBtn.Text = "SEND TO SERVER"
	sendServerBtn.Font = FONT_BOLD
	sendServerBtn.TextColor3 = THEME.TextMain
	sendServerBtn.TextSize = 13
	Instance.new("UICorner", sendServerBtn).CornerRadius = UDim.new(0, 8)

	local sendGlobalBtn = Instance.new("TextButton", btnAreaC)
	sendGlobalBtn.Name = "SendGlobal"
	sendGlobalBtn.Size = UDim2.new(0.48, 0, 1, 0)
	sendGlobalBtn.Position = UDim2.new(0.52, 0, 0, 0)
	sendGlobalBtn.BackgroundColor3 = THEME.ElegantTake
	sendGlobalBtn.Text = "SEND GLOBAL"
	sendGlobalBtn.Font = FONT_BOLD
	sendGlobalBtn.TextColor3 = THEME.TextMain
	sendGlobalBtn.TextSize = 13
	Instance.new("UICorner", sendGlobalBtn).CornerRadius = UDim.new(0, 8)

	-- ================== PAGE D: SHOP MANAGER ==================
	local pageShop = Instance.new("Frame", rightPanel)
	pageShop.Name = "Page_Shop"
	pageShop.Size = UDim2.new(1, 0, 1, 0)
	pageShop.BackgroundTransparency = 1
	pageShop.Visible = false
	createPlayerList(pageShop, "Shop")

	local shopActions = Instance.new("ScrollingFrame", pageShop)
	shopActions.Name = "SettingsArea"
	shopActions.Size = UDim2.new(0.65, 0, 1, 0)
	shopActions.Position = UDim2.new(0.35, 0, 0, 0)
	shopActions.BackgroundTransparency = 1
	shopActions.ScrollBarThickness = 3
	shopActions.ScrollBarImageColor3 = THEME.Accent
	shopActions.ScrollingDirection = Enum.ScrollingDirection.Y
	shopActions.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopActions.CanvasSize = UDim2.new(0, 0, 0, 0)

	local shopListLayout = Instance.new("UIListLayout", shopActions)
	shopListLayout.Padding = UDim.new(0, 8)
	shopListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local selLabelShop = selLabelA:Clone()
	selLabelShop.Parent = shopActions
	selLabelShop.Text = "Pemain: - | Item: -"
	selLabelShop.LayoutOrder = 1

	for _, cat in ipairs(SHOP_CATEGORIES) do
		createSectionTitle(cat.Title .. ":", shopActions).LayoutOrder = cat.OrderBase

		createSeparator(shopActions, cat.OrderBase + 1)

		local gridFrame = Instance.new("Frame", shopActions)
		gridFrame.Name = "Grid_" .. cat.Title
		gridFrame.Size = UDim2.new(1, -12, 0, math.ceil(#cat.Items / 2) * 43) 
		gridFrame.BackgroundTransparency = 1
		gridFrame.LayoutOrder = cat.OrderBase + 2

		local grid = Instance.new("UIGridLayout", gridFrame)
		grid.CellSize = UDim2.new(0.48, 0, 0, 35)
		grid.CellPadding = UDim2.new(0.04, 0, 0, 8)

		for _, item in ipairs(cat.Items) do
			local btn = Instance.new("TextButton", gridFrame)
			btn.Name = item.Id
			btn.BackgroundColor3 = THEME.CardBG
			btn.Text = item.Name
			btn.Font = FONT_GLOBAL
			btn.TextColor3 = THEME.TextMain
			btn.TextSize = 11
			btn.TextScaled = true 
			Instance.new("UITextSizeConstraint", btn).MaxTextSize = 11
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

			btn:SetAttribute("ItemType", item.Type)
			btn:SetAttribute("ItemName", item.Name)
		end

		if cat.Title == "Currency" then
			local shopAmountInput = amountBox:Clone()
			shopAmountInput.Name = "AmountInput"
			shopAmountInput.Parent = shopActions
			shopAmountInput.Visible = false 
			shopAmountInput.PlaceholderText = "Jumlah Koin (Misal: 10000)"
			shopAmountInput.Size = UDim2.new(1, -12, 0, 35)
			shopAmountInput.LayoutOrder = cat.OrderBase + 3
		end
	end

	local shopRowAddSub = rowAddSub:Clone()
	shopRowAddSub.Parent = shopActions
	shopRowAddSub.Size = UDim2.new(1, -12, 0, 35)
	shopRowAddSub.LayoutOrder = 100
	shopRowAddSub.BtnAdd.Text = "+ GIVE"
	shopRowAddSub.BtnAdd.BackgroundColor3 = THEME.ElegantGive
	shopRowAddSub.BtnSub.Text = "- TAKE"
	shopRowAddSub.BtnSub.BackgroundColor3 = THEME.ElegantTake

	-- ================== PAGE E: EXTRA MENU ==================
	local pageExtra = Instance.new("Frame", rightPanel)
	pageExtra.Name = "Page_Extra"
	pageExtra.Size = UDim2.new(1, 0, 1, 0)
	pageExtra.BackgroundTransparency = 1
	pageExtra.Visible = false
	createPlayerList(pageExtra, "Extra")

	local extraActions = Instance.new("ScrollingFrame", pageExtra)
	extraActions.Name = "SettingsArea"
	extraActions.Size = UDim2.new(0.65, 0, 1, 0)
	extraActions.Position = UDim2.new(0.35, 0, 0, 0)
	extraActions.BackgroundTransparency = 1
	extraActions.ScrollBarThickness = 3
	extraActions.ScrollBarImageColor3 = THEME.Accent
	extraActions.ScrollingDirection = Enum.ScrollingDirection.Y
	extraActions.AutomaticCanvasSize = Enum.AutomaticSize.Y
	extraActions.CanvasSize = UDim2.new(0, 0, 0, 0)

	local extraList = Instance.new("UIListLayout", extraActions)
	extraList.Padding = UDim.new(0, 8)
	extraList.SortOrder = Enum.SortOrder.LayoutOrder

	local selLabelExtra = selLabelA:Clone()
	selLabelExtra.Parent = extraActions
	selLabelExtra.Text = "Pemain: -"
	selLabelExtra.LayoutOrder = 1

	local extraInputGroup = Instance.new("Frame", extraActions)
	extraInputGroup.Name = "InputGroup"
	extraInputGroup.Size = UDim2.new(1, -12, 0, 78) 
	extraInputGroup.BackgroundTransparency = 1
	extraInputGroup.Visible = false
	extraInputGroup.LayoutOrder = 2

	local exInput = amountBox:Clone()
	exInput.Name = "AmountInput"
	exInput.Parent = extraInputGroup
	exInput.Size = UDim2.new(1, 0, 0, 35)
	exInput.Position = UDim2.new(0, 0, 0, 0)

	local exSubmitBtn = Instance.new("TextButton", extraInputGroup)
	exSubmitBtn.Name = "ExecuteBtn"
	exSubmitBtn.Size = UDim2.new(1, 0, 0, 35)
	exSubmitBtn.Position = UDim2.new(0, 0, 0, 43)
	exSubmitBtn.BackgroundColor3 = THEME.ElegantGive
	exSubmitBtn.Text = "SUBMIT"
	exSubmitBtn.Font = FONT_BOLD
	exSubmitBtn.TextColor3 = THEME.TextMain
	exSubmitBtn.TextSize = 13
	Instance.new("UICorner", exSubmitBtn).CornerRadius = UDim.new(0, 8)

	local extraGridFrame = Instance.new("Frame", extraActions)
	extraGridFrame.Name = "CommandGrid"
	extraGridFrame.Size = UDim2.new(1, -12, 0, 300) 
	extraGridFrame.BackgroundTransparency = 1
	extraGridFrame.LayoutOrder = 3

	local exGrid = Instance.new("UIGridLayout", extraGridFrame)
	exGrid.CellSize = UDim2.new(0.48, 0, 0, 35)
	exGrid.CellPadding = UDim2.new(0.04, 0, 0, 8)
	exGrid.SortOrder = Enum.SortOrder.LayoutOrder

	local extraCommands = {
		{Name = "BRING", Cmd = "Bring"}, {Name = "TELEPORT TO", Cmd = "Goto"},
		{Name = "HEAL FULL", Cmd = "Heal"}, {Name = "GOD MODE", Cmd = "God"},
		{Name = "JAIL", Cmd = "Jail"}, {Name = "FREEZE", Cmd = "Freeze"}, 
		{Name = "ROPE", Cmd = "Rope"}, {Name = "SET SPEED", Cmd = "Speed"},
		{Name = "SET SIZE", Cmd = "Size"}, {Name = "MORPH", Cmd = "Morph"},
		{Name = "GRANT FLY", Cmd = "GrantFly"}, {Name = "KILL PLAYER", Cmd = "Kill"},
		{Name = "KICK PLAYER", Cmd = "Kick"}, {Name = "BAN PLAYER", Cmd = "Ban"},
	}

	for i, cmd in ipairs(extraCommands) do
		local btn = Instance.new("TextButton", extraGridFrame)
		btn.Name = cmd.Cmd
		btn.BackgroundColor3 = THEME.CardBG 
		btn.Text = cmd.Name
		btn.Font = FONT_BOLD
		btn.TextColor3 = THEME.TextMain
		btn.TextSize = 12
		btn.LayoutOrder = i
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	end

	-- ================== PAGE F: ACTIVITY LOG ==================
	local pageActivity = Instance.new("Frame", rightPanel)
	pageActivity.Name = "Page_Activity"
	pageActivity.Size = UDim2.new(1, 0, 1, 0)
	pageActivity.BackgroundTransparency = 1
	pageActivity.Visible = false

	local logTopBar = Instance.new("Frame", pageActivity)
	logTopBar.Size = UDim2.new(1, 0, 0, 30)
	logTopBar.BackgroundTransparency = 1

	local logTitle = Instance.new("TextLabel", logTopBar)
	logTitle.Size = UDim2.new(0.7, 0, 1, 0)
	logTitle.BackgroundTransparency = 1
	logTitle.Text = "SERVER ACTIVITY LOG (LAST 24 HOURS)"
	logTitle.Font = FONT_BOLD
	logTitle.TextColor3 = THEME.Accent
	logTitle.TextSize = 14
	logTitle.TextXAlignment = Enum.TextXAlignment.Left

	local btnRefreshLog = Instance.new("TextButton", logTopBar)
	btnRefreshLog.Name = "BtnRefreshLog"
	btnRefreshLog.Size = UDim2.new(0, 100, 0, 25)
	btnRefreshLog.AnchorPoint = Vector2.new(1, 0.5)
	btnRefreshLog.Position = UDim2.new(1, -10, 0.5, 0)
	btnRefreshLog.BackgroundColor3 = THEME.SidebarBG
	btnRefreshLog.Text = "REFRESH"
	btnRefreshLog.Font = FONT_BOLD
	btnRefreshLog.TextColor3 = THEME.TextMain
	btnRefreshLog.TextSize = 11
	Instance.new("UICorner", btnRefreshLog).CornerRadius = UDim.new(0, 6)

	local logScroll = Instance.new("ScrollingFrame", pageActivity)
	logScroll.Name = "LogScroll"
	logScroll.Size = UDim2.new(1, -10, 1, -40)
	logScroll.Position = UDim2.new(0, 0, 0, 40)
	logScroll.BackgroundTransparency = 1
	logScroll.ScrollBarThickness = 3
	logScroll.ScrollBarImageColor3 = THEME.Accent
	logScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	local logLayout = Instance.new("UIListLayout", logScroll)
	logLayout.Padding = UDim.new(0, 6)
	logLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- ================== PAGE G: WEATHER ==================
	local pageWeather = Instance.new("Frame", rightPanel)
	pageWeather.Name = "Page_Weather"
	pageWeather.Size = UDim2.new(1, 0, 1, 0)
	pageWeather.BackgroundTransparency = 1
	pageWeather.Visible = false
	createPlayerList(pageWeather, "Weather")

	local weatherActions = Instance.new("ScrollingFrame", pageWeather)
	weatherActions.Name = "SettingsArea"
	weatherActions.Size = UDim2.new(0.65, 0, 1, 0)
	weatherActions.Position = UDim2.new(0.35, 0, 0, 0)
	weatherActions.BackgroundTransparency = 1
	weatherActions.ScrollBarThickness = 3
	weatherActions.ScrollBarImageColor3 = THEME.Accent
	weatherActions.ScrollingDirection = Enum.ScrollingDirection.Y
	weatherActions.AutomaticCanvasSize = Enum.AutomaticSize.Y
	weatherActions.CanvasSize = UDim2.new(0, 0, 0, 0)

	local weatherList = Instance.new("UIListLayout", weatherActions)
	weatherList.Padding = UDim.new(0, 8)
	weatherList.SortOrder = Enum.SortOrder.LayoutOrder

	createSectionTitle("Global Weather Control:", weatherActions)

	local globalWeatherGrid = Instance.new("Frame", weatherActions)
	globalWeatherGrid.Name = "GlobalWeatherGrid"
	globalWeatherGrid.Size = UDim2.new(1, -12, 0, 120) 
	globalWeatherGrid.BackgroundTransparency = 1
	local gwGrid = Instance.new("UIGridLayout", globalWeatherGrid)
	gwGrid.CellSize = UDim2.new(0.48, 0, 0, 35)
	gwGrid.CellPadding = UDim2.new(0.04, 0, 0, 8)

	local weatherModes = {"Auto", "Cerah", "Gerimis", "Hujan", "Badai", "Kabut"}
	for _, mode in ipairs(weatherModes) do
		local btn = Instance.new("TextButton", globalWeatherGrid)
		btn.Name = mode
		btn.BackgroundColor3 = THEME.CardBG
		btn.Text = string.upper(mode)
		btn.Font = FONT_BOLD
		btn.TextColor3 = THEME.TextMain
		btn.TextSize = 12
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	end

	createSeparator(weatherActions, 3)
	createSectionTitle("Targeted Lightning Strike:", weatherActions)

	local selLabelWeather = selLabelA:Clone()
	selLabelWeather.Parent = weatherActions
	selLabelWeather.Text = "Pemain: -"

	local lightningGrid = Instance.new("Frame", weatherActions)
	lightningGrid.Name = "LightningGrid"
	lightningGrid.Size = UDim2.new(1, -12, 0, 35)
	lightningGrid.BackgroundTransparency = 1
	local lgGrid = Instance.new("UIGridLayout", lightningGrid)
	lgGrid.CellSize = UDim2.new(0.48, 0, 0, 35)
	lgGrid.CellPadding = UDim2.new(0.04, 0, 0, 8)

	local strikeModes = {"Petir", "Petirkill"}
	for _, mode in ipairs(strikeModes) do
		local btn = Instance.new("TextButton", lightningGrid)
		btn.Name = mode
		btn.BackgroundColor3 = (mode == "Petirkill") and THEME.Warning or THEME.CardBG
		btn.Text = string.upper(mode)
		btn.Font = FONT_BOLD
		btn.TextColor3 = THEME.TextMain
		btn.TextSize = 12
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	end

	sg.Parent = pGui
end

for _, p in ipairs(Players:GetPlayers()) do 
	task.spawn(function() BuildAdminUI(p) end) 
end

Players.PlayerAdded:Connect(function(plr)
	BuildAdminUI(plr)
end)