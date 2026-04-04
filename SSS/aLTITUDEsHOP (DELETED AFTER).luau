--[[
    ALTITUDE CATALOG GENERATOR V73 (PURE ATTRIBUTE SYNC)
    Play Test, Copy AltitudeCatalogUI ke StarterGui, Hapus Script.
    
    PERBAIKAN OLEH KARINA:
    1. Harga disinkronisasi total sesuai inflasi baru.
    2. VIP Banner dinaikkan tingginya menjadi 420px.
    3. MENGHAPUS INJEKSI LOCALSCRIPT: Tombol Exchange murni UI.
    4. [HOTFIX] Mengembalikan penciptaan ExchangeModal.
    5. UPDATE ICON: Menerapkan icon kustom.
    6. [ARCHITECTURAL FIX] CheckOwnership sekarang 100% membaca Atribut, BUKAN StarterGear.
]]

local Players = game:GetService("Players")

local THEME = {
	MainBG = Color3.fromRGB(30, 59, 103),
	SidebarBG = Color3.fromRGB(20, 45, 85),
	CardBG = Color3.fromRGB(40, 75, 125),
	Accent = Color3.fromRGB(247, 173, 175),
	RobuxColor = Color3.fromRGB(46, 204, 113), 
	PreviewColor = Color3.fromRGB(250, 204, 21),
	TextMain = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(175, 195, 225),
}

local ICONS = {
	DogCoin = "rbxassetid://9341850470", 
	DogTool = "rbxassetid://13470748119", 
	SpeedCoil = "rbxassetid://139484720378416", 
	Umbrella = "rbxassetid://92461427391132",
	VIPAccess = "rbxassetid://436230647", 
	DogAura = "rbxassetid://13470748887",
	JetSolo = "rbxassetid://99294174745387",
	HideAura = "rbxassetid://127929972352071",
	Close = "rbxassetid://11293981586",
	UserPlaceholder = "rbxassetid://12000216664"
}

local FONT_GLOBAL = Enum.Font.Montserrat

local ShopData = {
	VIP = {
		{ID = "A2", Name = "VIP Access", Price = 100, Currency = "Robux", Icon = ICONS.VIPAccess, ActionType = "Perk", AttributeName = "HasVIP"}
	},
	Credits = {
		{ID = "C1", Name = "5.000 Coins", Price = 15, Currency = "Robux", Icon = ICONS.DogCoin, ActionType = "Currency"},
		{ID = "C2", Name = "10.000 Coins", Price = 25, Currency = "Robux", Icon = ICONS.DogCoin, ActionType = "Currency"},
		{ID = "C3", Name = "25.000 Coins", Price = 50, Currency = "Robux", Icon = ICONS.DogCoin, ActionType = "Currency"},
		{ID = "C4", Name = "50.000 Coins", Price = 100, Currency = "Robux", Icon = ICONS.DogCoin, ActionType = "Currency"},
		{ID = "C5", Name = "100.000 Coins", Price = 150, Currency = "Robux", Icon = ICONS.DogCoin, ActionType = "Currency"},
		{ID = "C6", Name = "500.000 Coins", Price = 500, Currency = "Robux", Icon = ICONS.DogCoin, ActionType = "Currency"},
	},
	General = {
		ToolsAndPerks = { 
			{ID = "T1", Name = "Umbrella", Price = 5000, Currency = "Coins", Icon = ICONS.Umbrella, ActionType = "Tool"},
			{ID = "T2", Name = "Speed Coil", Price = 10, Currency = "Robux", Icon = ICONS.SpeedCoil, ActionType = "Tool"}, 
			{ID = "P_HA", Name = "Hide Aura", Price = 100000, Currency = "Coins", Icon = ICONS.HideAura, ActionType = "Perk", AttributeName = "HasHideAura"},
			{ID = "V_JS", Name = "JetSolo Access", Price = 100000, Currency = "Coins", Icon = ICONS.JetSolo, ActionType = "Perk", AttributeName = "HasJetSolo"},
		},
		Auras = { 
			{ID = "A_CH", Name = "Chained Aura", Price = 35000, Currency = "Coins", ModelName = "Chained", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasChained"},
			{ID = "A_CO", Name = "Cosmic Aura", Price = 1500, Currency = "Coins", ModelName = "Cosmic", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasCosmic"},
			{ID = "A_CU", Name = "Cubic Aura", Price = 35000, Currency = "Coins", ModelName = "Cubic", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasCubic"},
			{ID = "A_DS", Name = "Dual Swords", Price = 50, Currency = "Robux", ModelName = "DualSwords", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasDualSwords"},
			{ID = "A_FR", Name = "Frost Aura", Price = 25, Currency = "Robux", ModelName = "Frost", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasFrost"},
			{ID = "A_LO", Name = "Love Aura", Price = 10000, Currency = "Coins", ModelName = "Love", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasLove"},
			{ID = "A_PO", Name = "Poison Aura", Price = 75000, Currency = "Coins", ModelName = "Poison", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasPoison"},
			{ID = "A_PL", Name = "Powerless", Price = 10, Currency = "Robux", ModelName = "Powerless", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasPowerless"},
			{ID = "A_SD", Name = "Sand Demon", Price = 100000, Currency = "Coins", ModelName = "SandDemon", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasSandDemon"},
			{ID = "A_SN", Name = "Sound Ninja", Price = 100000, Currency = "Coins", ModelName = "SoundNinja", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasSoundNinja"},
			{ID = "A_TG", Name = "Thunder God", Price = 125000, Currency = "Coins", ModelName = "ThunderGod", Icon = ICONS.DogAura, ActionType = "Perk", AttributeName = "HasThunderGod"},
		}
	}
}

local function FormatNumber(n)
	local formatted = tostring(n)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
		if k == 0 then break end
	end
	return formatted
end

-- [KARINA FIX] 100% Mengandalkan Atribut, StarterGear diabaikan.
local function CheckOwnership(player, itemData)
	if itemData.ActionType == "Currency" then 
		return false
	elseif itemData.ActionType == "Tool" then 
		local safeName = string.gsub(itemData.Name, "%s+", "")
		return player:GetAttribute("OwnsTool_" .. safeName) == true
	elseif itemData.ActionType == "Perk" and itemData.AttributeName then 
		return player:GetAttribute(itemData.AttributeName) == true 
	end
	return false
end

local function BuildUI(player)
	local pGui = player:WaitForChild("PlayerGui", 20)
	if not pGui then return end

	local oldGui = pGui:FindFirstChild("AltitudeCatalogUI")
	if oldGui then oldGui:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "AltitudeCatalogUI"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling 
	sg.DisplayOrder = 100 
	sg.Parent = pGui

	local main = Instance.new("CanvasGroup", sg)
	main.Name = "MainFrame"
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Size = UDim2.new(0.65, 60, 0.7, 60)
	main.Position = UDim2.new(0.5, 0, 0.58, 0)
	main.BackgroundTransparency = 1 
	main.BorderSizePixel = 0
	main.Visible = false 
	main.ZIndex = 10
	Instance.new("UISizeConstraint", main).MaxSize = Vector2.new(960, 610)
	Instance.new("UIAspectRatioConstraint", main).AspectRatio = 1.65

	local visualBg = Instance.new("Frame", main)
	visualBg.Name = "VisualBg"
	visualBg.Size = UDim2.new(1, -60, 1, -60)
	visualBg.Position = UDim2.new(0.5, 0, 0.5, 0)
	visualBg.AnchorPoint = Vector2.new(0.5, 0.5)
	visualBg.BackgroundColor3 = THEME.MainBG
	Instance.new("UICorner", visualBg).CornerRadius = UDim.new(0, 12)

	local closeBg = Instance.new("Frame", main)
	closeBg.Name = "CloseBtn"
	closeBg.Size = UDim2.new(0, 32, 0, 32)
	closeBg.Position = UDim2.new(1, -30, 0, 30) 
	closeBg.AnchorPoint = Vector2.new(0.5, 0.5) 
	closeBg.BackgroundColor3 = THEME.Accent
	closeBg.ZIndex = 5000 
	closeBg.Rotation = 45 
	Instance.new("UICorner", closeBg).CornerRadius = UDim.new(0, 8) 

	local closeBtnAction = Instance.new("TextButton", closeBg)
	closeBtnAction.Name = "XButton"
	closeBtnAction.Size = UDim2.new(1, 0, 1, 0)
	closeBtnAction.BackgroundTransparency = 1
	closeBtnAction.Text = ""

	local closeIcon = Instance.new("ImageLabel", closeBg)
	closeIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
	closeIcon.Position = UDim2.new(0.25, 0, 0.25, 0)
	closeIcon.Image = ICONS.Close
	closeIcon.ImageColor3 = THEME.MainBG
	closeIcon.BackgroundTransparency = 1
	closeIcon.Rotation = -45 

	local sidebar = Instance.new("Frame", visualBg)
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0.25, 0, 1, 0)
	sidebar.BackgroundColor3 = THEME.SidebarBG
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

	local navList = Instance.new("UIListLayout", sidebar)
	navList.Padding = UDim.new(0, 10)
	navList.SortOrder = Enum.SortOrder.LayoutOrder
	navList.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local navPad = Instance.new("UIPadding", sidebar)
	navPad.PaddingTop = UDim.new(0, 30)

	local contentContainer = Instance.new("Frame", visualBg)
	contentContainer.Name = "ContentContainer"
	contentContainer.Position = UDim2.new(0.25, 0, 0, 0)
	contentContainer.Size = UDim2.new(0.75, 0, 1, 0)
	contentContainer.BackgroundTransparency = 1

	local giftModal = Instance.new("CanvasGroup", sg)
	giftModal.Name = "GiftModal"
	giftModal.Size = UDim2.new(0.85, 60, 0.65, 60) 
	giftModal.Position = UDim2.new(0.5, 0, 0.58, 0)
	giftModal.AnchorPoint = Vector2.new(0.5, 0.5)
	giftModal.BackgroundTransparency = 1
	giftModal.Visible = false
	giftModal.ZIndex = 6000

	local gmConstraint = Instance.new("UISizeConstraint", giftModal)
	gmConstraint.MaxSize = Vector2.new(400, 520)

	local gmVisual = Instance.new("Frame", giftModal)
	gmVisual.Name = "GmVisual"
	gmVisual.Size = UDim2.new(1, -60, 1, -60)
	gmVisual.Position = UDim2.new(0.5, 0, 0.5, 0)
	gmVisual.AnchorPoint = Vector2.new(0.5, 0.5)
	gmVisual.BackgroundColor3 = THEME.SidebarBG
	Instance.new("UICorner", gmVisual)
	Instance.new("UIStroke", gmVisual).Color = THEME.Accent

	local gClose = Instance.new("ImageButton", giftModal)
	gClose.Name = "ImageButton"
	gClose.Size = UDim2.new(0, 24, 0, 24)
	gClose.Position = UDim2.new(1, -30, 0, 30)
	gClose.AnchorPoint = Vector2.new(0.5, 0.5)
	gClose.BackgroundColor3 = THEME.CardBG 
	gClose.Rotation = 45 
	Instance.new("UICorner", gClose).CornerRadius = UDim.new(0, 6)
	local gStroke = Instance.new("UIStroke", gClose)
	gStroke.Color = THEME.TextMuted
	gStroke.Transparency = 0.5

	local gCloseIcon = Instance.new("ImageLabel", gClose)
	gCloseIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
	gCloseIcon.Position = UDim2.new(0.25, 0, 0.25, 0)
	gCloseIcon.BackgroundTransparency = 1
	gCloseIcon.Image = ICONS.Close
	gCloseIcon.ImageColor3 = THEME.TextMuted
	gCloseIcon.Rotation = -45

	local giftTitle = Instance.new("TextLabel", gmVisual)
	giftTitle.Text = "SEND GIFT TO:"
	giftTitle.Size = UDim2.new(1, 0, 0, 45)
	giftTitle.Font = FONT_GLOBAL
	giftTitle.TextColor3 = THEME.TextMain
	giftTitle.TextSize = 14
	giftTitle.BackgroundTransparency = 1

	local emptyState = Instance.new("TextLabel", gmVisual)
	emptyState.Name = "EmptyLabel"
	emptyState.Size = UDim2.new(1, 0, 1, -45)
	emptyState.Position = UDim2.new(0, 0, 0, 45)
	emptyState.BackgroundTransparency = 1
	emptyState.Text = "Tidak ada pemain lain\ndi server ini."
	emptyState.Font = FONT_GLOBAL
	emptyState.TextColor3 = THEME.TextMuted
	emptyState.TextSize = 13
	emptyState.Visible = false 

	local playerList = Instance.new("ScrollingFrame", gmVisual)
	playerList.Name = "PlayerList"
	playerList.Size = UDim2.new(1, -20, 1, -65)
	playerList.Position = UDim2.new(0, 10, 0, 55)
	playerList.BackgroundTransparency = 1
	playerList.ScrollBarThickness = 2
	playerList.ScrollBarImageColor3 = THEME.Accent
	playerList.ScrollingDirection = Enum.ScrollingDirection.Y
	playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
	playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local plListLayout = Instance.new("UIListLayout", playerList)
	plListLayout.Padding = UDim.new(0, 6)
	plListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local template = Instance.new("TextButton", sg)
	template.Name = "PlayerTemplate"
	template.Size = UDim2.new(1, -10, 0, 45)
	template.BackgroundColor3 = THEME.CardBG
	template.Text = ""
	template.Visible = false
	Instance.new("UICorner", template).CornerRadius = UDim.new(0, 6)

	local av = Instance.new("ImageLabel", template)
	av.Name = "Avatar"
	av.Size = UDim2.new(0, 35, 0, 35)
	av.Position = UDim2.new(0, 5, 0.5, -17.5)
	av.BackgroundTransparency = 1 
	av.Image = ICONS.UserPlaceholder
	av.ScaleType = Enum.ScaleType.Fit
	Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

	local pName = Instance.new("TextLabel", template)
	pName.Name = "PName"
	pName.Size = UDim2.new(1, -50, 1, 0)
	pName.Position = UDim2.new(0, 45, 0, 0)
	pName.BackgroundTransparency = 1
	pName.TextXAlignment = Enum.TextXAlignment.Left
	pName.Font = FONT_GLOBAL
	pName.TextColor3 = THEME.TextMain
	pName.TextSize = 12

	local confirmModal = Instance.new("CanvasGroup", sg)
	confirmModal.Name = "ConfirmModal"
	confirmModal.Size = UDim2.new(0.4, 60, 0.35, 60)
	confirmModal.Position = UDim2.new(0.5, 0, 0.58, 0)
	confirmModal.AnchorPoint = Vector2.new(0.5, 0.5)
	confirmModal.BackgroundTransparency = 1
	confirmModal.Visible = false
	confirmModal.ZIndex = 6500

	local cmConstraint = Instance.new("UISizeConstraint", confirmModal)
	cmConstraint.MaxSize = Vector2.new(410, 280)

	local cmVisual = Instance.new("Frame", confirmModal)
	cmVisual.Name = "CmVisual"
	cmVisual.Size = UDim2.new(1, -60, 1, -60)
	cmVisual.Position = UDim2.new(0.5, 0, 0.5, 0)
	cmVisual.AnchorPoint = Vector2.new(0.5, 0.5)
	cmVisual.BackgroundColor3 = THEME.SidebarBG
	Instance.new("UICorner", cmVisual).CornerRadius = UDim.new(0, 12)
	Instance.new("UIStroke", cmVisual).Color = THEME.Accent

	local cmTitle = Instance.new("TextLabel", cmVisual)
	cmTitle.Name = "TitleLabel"
	cmTitle.Text = "KONFIRMASI"
	cmTitle.Size = UDim2.new(1, 0, 0, 45)
	cmTitle.Font = Enum.Font.MontserratBold
	cmTitle.TextColor3 = THEME.Accent
	cmTitle.TextSize = 16
	cmTitle.BackgroundTransparency = 1

	local cmMsg = Instance.new("TextLabel", cmVisual)
	cmMsg.Name = "MsgLabel"
	cmMsg.Text = "Apakah kamu yakin ingin membeli item ini?"
	cmMsg.Size = UDim2.new(1, -40, 1, -110)
	cmMsg.Position = UDim2.new(0, 20, 0, 45)
	cmMsg.Font = FONT_GLOBAL
	cmMsg.TextColor3 = THEME.TextMain
	cmMsg.TextWrapped = true
	cmMsg.RichText = true
	cmMsg.TextSize = 14
	cmMsg.BackgroundTransparency = 1

	local cmYes = Instance.new("TextButton", cmVisual)
	cmYes.Name = "YesBtn"
	cmYes.Size = UDim2.new(0.4, 0, 0, 40)
	cmYes.Position = UDim2.new(0.08, 0, 1, -55)
	cmYes.BackgroundColor3 = THEME.RobuxColor
	cmYes.TextColor3 = THEME.TextMain
	cmYes.Text = "BELI"
	cmYes.Font = Enum.Font.MontserratBold
	cmYes.TextSize = 14
	Instance.new("UICorner", cmYes).CornerRadius = UDim.new(0, 8)

	local cmNo = Instance.new("TextButton", cmVisual)
	cmNo.Name = "NoBtn"
	cmNo.Size = UDim2.new(0.4, 0, 0, 40)
	cmNo.Position = UDim2.new(0.52, 0, 1, -55)
	cmNo.BackgroundColor3 = THEME.CardBG
	cmNo.TextColor3 = THEME.TextMain
	cmNo.Text = "BATAL"
	cmNo.Font = Enum.Font.MontserratBold
	cmNo.TextSize = 14
	Instance.new("UICorner", cmNo).CornerRadius = UDim.new(0, 8)

	local exModal = confirmModal:Clone()
	exModal.Name = "ExchangeModal"
	exModal.Parent = sg

	local function CreatePage(name)
		local f = Instance.new("ScrollingFrame", contentContainer)
		f.Name = name .. "Page"
		f.Size = UDim2.new(1, 0, 1, 0)
		f.BackgroundTransparency = 1
		f.ScrollBarThickness = 2
		f.ScrollBarImageColor3 = THEME.Accent
		f.ScrollingDirection = Enum.ScrollingDirection.Y
		f.CanvasSize = UDim2.new(0, 0, 0, 0)
		f.AutomaticCanvasSize = Enum.AutomaticSize.Y
		f.Visible = false

		local list = Instance.new("UIListLayout", f)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 20) 

		local padding = Instance.new("UIPadding", f)
		padding.PaddingLeft = UDim.new(0, 30)
		padding.PaddingRight = UDim.new(0, 30)
		padding.PaddingTop = UDim.new(0, 20)   
		padding.PaddingBottom = UDim.new(0, 40) 
		return f
	end

	-- PAGE CREATION
	local creditsPage = CreatePage("Credits")
	local generalPage = CreatePage("General")
	local exchangePage = CreatePage("Exchange") -- Tab Tukar Summit
	local vipPage = CreatePage("VIP")

	creditsPage.Visible = true 

	-- ========================================================
	-- EXCHANGE BANNER (TUKAR SUMMIT)
	-- ========================================================
	local exBanner = Instance.new("Frame", exchangePage)
	exBanner.Name = "ExchangeBanner"
	exBanner.Size = UDim2.new(1, 0, 0, 220) 
	exBanner.BackgroundColor3 = THEME.SidebarBG 
	exBanner.LayoutOrder = 1
	Instance.new("UICorner", exBanner).CornerRadius = UDim.new(0, 12)

	local eStroke = Instance.new("UIStroke", exBanner)
	eStroke.Color = THEME.Accent
	eStroke.Thickness = 1
	eStroke.Transparency = 0.5 

	local eTitle = Instance.new("TextLabel", exBanner)
	eTitle.Size = UDim2.new(1, -40, 0, 30)
	eTitle.Position = UDim2.new(0, 20, 0, 20)
	eTitle.BackgroundTransparency = 1
	eTitle.Font = Enum.Font.MontserratBold
	eTitle.TextSize = 20
	eTitle.TextColor3 = THEME.Accent
	eTitle.Text = "TUKAR SUMMIT"
	eTitle.TextXAlignment = Enum.TextXAlignment.Left

	local eDesc = Instance.new("TextLabel", exBanner)
	eDesc.Size = UDim2.new(1, -40, 0, 60)
	eDesc.Position = UDim2.new(0, 20, 0, 60)
	eDesc.BackgroundTransparency = 1
	eDesc.Font = FONT_GLOBAL
	eDesc.TextSize = 13
	eDesc.TextColor3 = THEME.TextMuted
	eDesc.RichText = true
	eDesc.TextWrapped = true
	eDesc.TextXAlignment = Enum.TextXAlignment.Left
	eDesc.TextYAlignment = Enum.TextYAlignment.Top
	eDesc.Text = "Ubah kerja kerasmu menjadi koin untuk dibelanjakan.\n\n<font color='#FFFFFF'><b>1 Summit = 500 Coins</b></font>\n\n<i>Peringatan: Seluruh jumlah Summit kamu saat ini akan direset menjadi 0 setelah ditukarkan.</i>"

	local exBtn = Instance.new("TextButton", exBanner)
	exBtn.Name = "ExchangeButton" 
	exBtn.Size = UDim2.new(0.6, 0, 0, 40)
	exBtn.Position = UDim2.new(0, 20, 1, -60) 
	exBtn.Font = Enum.Font.MontserratBold
	exBtn.TextSize = 14
	Instance.new("UICorner", exBtn).CornerRadius = UDim.new(0, 8)
	exBtn.Text = "TUKAR SEMUA SUMMIT"
	exBtn.BackgroundColor3 = THEME.Accent 
	exBtn.TextColor3 = THEME.MainBG

	exBtn:SetAttribute("ItemID", "EXCHANGE_SUMMIT")
	exBtn:SetAttribute("ItemName", "Tukar Summit")
	exBtn:SetAttribute("ActionType", "Exchange")

	-- ========================================================
	-- VIP BANNER REDESIGN (LUXURY MINIMALIST)
	-- ========================================================
	local vipBanner = Instance.new("Frame", vipPage)
	vipBanner.Name = "VIPBanner"
	vipBanner.Size = UDim2.new(1, 0, 0, 420) 
	vipBanner.BackgroundColor3 = THEME.SidebarBG 
	vipBanner.LayoutOrder = 1
	Instance.new("UICorner", vipBanner).CornerRadius = UDim.new(0, 12)

	local vStroke = Instance.new("UIStroke", vipBanner)
	vStroke.Color = THEME.PreviewColor
	vStroke.Thickness = 1
	vStroke.Transparency = 0.4 

	local benefitsFrame = Instance.new("Frame", vipBanner)
	benefitsFrame.Size = UDim2.new(1, -40, 0, 280)
	benefitsFrame.Position = UDim2.new(0, 20, 0, 20)
	benefitsFrame.BackgroundTransparency = 1

	local bList = Instance.new("UIListLayout", benefitsFrame)
	bList.SortOrder = Enum.SortOrder.LayoutOrder
	bList.Padding = UDim.new(0, 16)

	local benefitTexts = {
		"Sematkan <font color='#FACC15'><b>Title VIP</b></font> dan <font color='#FACC15'><b>Tag VIP</b></font> di Chat",
		"Bonus instan <font color='#FACC15'><b>10.000 Coins</b></font> saat pembelian",
		"Raih pendapatan <font color='#FACC15'><b>x2 Coins</b></font> setiap mencapai Summit",
		"Akses instan kendaraan eksklusif <font color='#FACC15'><b>JetSolo</b></font>",
		"Unlock efek visual <font color='#FACC15'><b>Rich Aura</b></font> & <font color='#FACC15'><b>Sword Master Aura</b></font>",
		"Visibilitas penuh untuk kontrol fitur <font color='#FACC15'><b>Hide Aura</b></font>",
		"Mendukung pengembangan developer Altitude"
	}

	for i, text in ipairs(benefitTexts) do
		local row = Instance.new("Frame", benefitsFrame)
		row.Size = UDim2.new(1, 0, 0, 18)
		row.BackgroundTransparency = 1
		row.LayoutOrder = i * 2

		local lbl = Instance.new("TextLabel", row)
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = FONT_GLOBAL
		lbl.TextSize = 13
		lbl.TextColor3 = THEME.TextMuted
		lbl.RichText = true
		lbl.Text = text
		lbl.TextXAlignment = Enum.TextXAlignment.Left

		if i < #benefitTexts then
			local line = Instance.new("Frame", benefitsFrame)
			line.Size = UDim2.new(1, 0, 0, 1)
			line.BackgroundColor3 = THEME.TextMuted
			line.BackgroundTransparency = 0.85
			line.BorderSizePixel = 0
			line.LayoutOrder = (i * 2) + 1
		end
	end

	local vipItemData = ShopData.VIP[1]
	local isOwnedVIP = CheckOwnership(player, vipItemData)

	local buyVipBtn = Instance.new("TextButton", vipBanner)
	buyVipBtn.Name = "BuyButton"
	buyVipBtn.Size = UDim2.new(0.4, 0, 0, 40)
	buyVipBtn.Position = UDim2.new(0, 20, 1, -60) 
	buyVipBtn.Font = Enum.Font.MontserratBold
	buyVipBtn.TextSize = 14
	Instance.new("UICorner", buyVipBtn).CornerRadius = UDim.new(0, 8)

	buyVipBtn:SetAttribute("ItemID", vipItemData.ID)
	buyVipBtn:SetAttribute("Currency", vipItemData.Currency)
	buyVipBtn:SetAttribute("ItemName", vipItemData.Name)
	buyVipBtn:SetAttribute("ActionType", vipItemData.ActionType)
	buyVipBtn:SetAttribute("AttributeName", vipItemData.AttributeName)

	if isOwnedVIP then
		buyVipBtn.Text = "ANDA SUDAH VIP"
		buyVipBtn.BackgroundColor3 = Color3.fromRGB(71, 85, 105)
		buyVipBtn.TextColor3 = THEME.TextMuted
		buyVipBtn.AutoButtonColor = false 
	else
		buyVipBtn.Text = "JADI VIP (R$ " .. vipItemData.Price .. ")"
		buyVipBtn.BackgroundColor3 = THEME.PreviewColor 
		buyVipBtn.TextColor3 = THEME.SidebarBG 
	end

	-- ========================================================
	-- FUNGSI STANDAR KATEGORI LAIN
	-- ========================================================
	local function AddCategory(titleText, items, parent, order, targetPlayer, hasPreview, showIcon)
		if showIcon == nil then showIcon = true end

		local section = Instance.new("Frame", parent)
		section.Name = titleText .. "Section"
		section.Size = UDim2.new(1, 0, 0, 0)
		section.AutomaticSize = Enum.AutomaticSize.Y
		section.BackgroundTransparency = 1
		section.LayoutOrder = order

		local label = Instance.new("TextLabel", section)
		label.Text = titleText:upper()
		label.Font = FONT_GLOBAL
		label.TextSize = 11
		label.TextColor3 = THEME.TextMuted
		label.Size = UDim2.new(1, 0, 0, 25)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1

		local gridFrame = Instance.new("Frame", section)
		gridFrame.Size = UDim2.new(1, 0, 0, 0)
		gridFrame.Position = UDim2.new(0, 0, 0, 30)
		gridFrame.AutomaticSize = Enum.AutomaticSize.Y
		gridFrame.BackgroundTransparency = 1

		local grid = Instance.new("UIGridLayout", gridFrame)
		if showIcon then
			grid.CellSize = UDim2.new(0.31, 0, 0, hasPreview and 170 or 145) 
		else
			grid.CellSize = UDim2.new(0.31, 0, 0, hasPreview and 125 or 100) 
		end
		grid.CellPadding = UDim2.new(0.035, 0, 0, 15)

		for _, item in pairs(items) do
			local card = Instance.new("Frame", gridFrame)
			card.BackgroundColor3 = THEME.CardBG
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

			if showIcon then
				local img = Instance.new("ImageLabel", card)
				img.Name = "Icon"
				img.Size = UDim2.new(0.5, 0, 0.35, 0)
				img.Position = UDim2.new(0.25, 0, 0.05, 0)
				img.BackgroundTransparency = 1
				img.Image = item.Icon or ICONS.UserPlaceholder
				img.ScaleType = Enum.ScaleType.Fit
			end

			local nLabel = Instance.new("TextLabel", card)
			nLabel.Size = UDim2.new(0.9, 0, 0, 15)
			nLabel.Position = showIcon and UDim2.new(0.05, 0, 0.42, 0) or UDim2.new(0.05, 0, 0.1, 0)
			nLabel.Text = item.Name
			nLabel.Font = FONT_GLOBAL
			nLabel.TextColor3 = THEME.TextMain
			nLabel.TextScaled = true
			nLabel.TextXAlignment = Enum.TextXAlignment.Center
			nLabel.BackgroundTransparency = 1

			local pLabel = Instance.new("TextLabel", card)
			pLabel.Size = UDim2.new(0.9, 0, 0, 14)
			pLabel.Position = showIcon and UDim2.new(0.05, 0, 0.53, 0) or UDim2.new(0.05, 0, 0.28, 0)
			pLabel.Font = Enum.Font.Montserrat
			pLabel.TextSize = 11
			pLabel.TextXAlignment = Enum.TextXAlignment.Center
			pLabel.BackgroundTransparency = 1

			if item.Currency == "Robux" then
				pLabel.Text = "R$ " .. item.Price
				pLabel.TextColor3 = THEME.RobuxColor
			else
				pLabel.Text = FormatNumber(item.Price)
				pLabel.TextColor3 = THEME.Accent
			end

			local isOwned = CheckOwnership(targetPlayer, item)

			local buyBtn = Instance.new("TextButton", card)
			buyBtn.Name = "BuyButton"
			buyBtn.Size = UDim2.new(0.43, 0, 0, 24)
			buyBtn.Position = showIcon and UDim2.new(0.05, 0, 0.65, 0) or UDim2.new(0.05, 0, 0.48, 0)
			buyBtn.Font = FONT_GLOBAL
			buyBtn.TextSize = 10
			Instance.new("UICorner", buyBtn)

			buyBtn:SetAttribute("ItemID", item.ID)
			buyBtn:SetAttribute("Currency", item.Currency)
			buyBtn:SetAttribute("ItemName", item.Name)
			buyBtn:SetAttribute("ActionType", item.ActionType)
			if item.AttributeName then buyBtn:SetAttribute("AttributeName", item.AttributeName) end
			if item.Currency == "Coins" then buyBtn:SetAttribute("ItemPrice", item.Price) end

			if isOwned then
				buyBtn.Text = "OWNED"
				buyBtn.BackgroundColor3 = Color3.fromRGB(71, 85, 105)
				buyBtn.TextColor3 = THEME.TextMuted
				buyBtn.AutoButtonColor = false 
			else
				buyBtn.Text = "BUY"
				buyBtn.BackgroundColor3 = THEME.Accent
				buyBtn.TextColor3 = THEME.MainBG
			end

			local giftBtn = buyBtn:Clone()
			giftBtn.Name = "GiftButton"
			giftBtn.Parent = card
			giftBtn.Position = showIcon and UDim2.new(0.52, 0, 0.65, 0) or UDim2.new(0.52, 0, 0.48, 0)
			giftBtn.BackgroundColor3 = THEME.SidebarBG
			giftBtn.TextColor3 = THEME.TextMain 
			giftBtn.Text = "GIFT"
			giftBtn.AutoButtonColor = true

			if hasPreview and item.ModelName then
				local prevBtn = Instance.new("TextButton", card)
				prevBtn.Name = "PreviewButton"
				prevBtn.Size = UDim2.new(0.9, 0, 0, 22)
				prevBtn.Position = showIcon and UDim2.new(0.05, 0, 0.83, 0) or UDim2.new(0.05, 0, 0.72, 0)
				prevBtn.BackgroundColor3 = THEME.PreviewColor
				prevBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
				prevBtn.Font = Enum.Font.GothamBold
				prevBtn.TextSize = 10
				prevBtn.Text = "PREVIEW (5s)"
				Instance.new("UICorner", prevBtn).CornerRadius = UDim.new(0, 4)
				prevBtn:SetAttribute("ModelName", item.ModelName)
			elseif not hasPreview then
				buyBtn.Position = showIcon and UDim2.new(0.05, 0, 0.75, 0) or UDim2.new(0.05, 0, 0.55, 0)
				giftBtn.Position = showIcon and UDim2.new(0.52, 0, 0.75, 0) or UDim2.new(0.52, 0, 0.55, 0)
			end
		end
	end

	AddCategory("Currency", ShopData.Credits, creditsPage, 1, player, false, true)
	AddCategory("Tools & Perks", ShopData.General.ToolsAndPerks, generalPage, 1, player, false, true)
	AddCategory("Aura", ShopData.General.Auras, generalPage, 2, player, true, false)

	local function CreateNav(name, pageName, order)
		local btn = Instance.new("TextButton", sidebar)
		btn.Name = name .. "Nav"
		btn.Size = UDim2.new(0.85, 0, 0, 42) 
		btn.BackgroundColor3 = THEME.Accent
		btn.BackgroundTransparency = (name == "CREDITS" and 0 or 1)
		btn.Text = name
		btn.Font = FONT_GLOBAL
		btn.TextSize = 12
		btn.TextColor3 = (name == "CREDITS" and THEME.MainBG or THEME.TextMain)
		btn.LayoutOrder = order
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8) 
		btn:SetAttribute("TargetPage", pageName)
	end

	CreateNav("CREDITS", "CreditsPage", 1)
	CreateNav("GENERAL", "GeneralPage", 2)
	CreateNav("EXCHANGE", "ExchangePage", 3)
	CreateNav("VIP EXCLUSIVE", "VIPPage", 4)

	local rs = Instance.new("Frame", generalPage)
	rs.Name = "RedeemSection"
	rs.Size = UDim2.new(1, 0, 0, 75)
	rs.BackgroundTransparency = 1
	rs.LayoutOrder = 99

	local ci = Instance.new("TextBox", rs)
	ci.Name = "CodeInput"
	ci.Size = UDim2.new(0.7, -10, 0, 42)
	ci.Position = UDim2.new(0, 0, 0, 10)
	ci.BackgroundColor3 = THEME.SidebarBG
	ci.PlaceholderText = "Masukkan kode promo..."
	ci.Text = "" 
	ci.Font = FONT_GLOBAL
	ci.TextColor3 = Color3.new(1,1,1)
	ci.TextSize = 12
	Instance.new("UICorner", ci).CornerRadius = UDim.new(0, 8)

	local ciPadding = Instance.new("UIPadding", ci)
	ciPadding.PaddingLeft = UDim.new(0, 12)
	ciPadding.PaddingRight = UDim.new(0, 12)

	local rb = Instance.new("TextButton", rs)
	rb.Name = "RedeemBtn"
	rb.Size = UDim2.new(0.3, 0, 0, 42) 
	rb.Position = UDim2.new(0.7, 0, 0, 10)
	rb.BackgroundColor3 = THEME.Accent
	rb.Text = "KLAIM"
	rb.Font = FONT_GLOBAL
	rb.TextColor3 = THEME.MainBG
	rb.TextSize = 12
	Instance.new("UICorner", rb).CornerRadius = UDim.new(0, 8)

	local sl = Instance.new("TextLabel", rs)
	sl.Name = "StatusLabel"
	sl.Size = UDim2.new(1, 0, 0, 15)
	sl.Position = UDim2.new(0, 0, 0, 60) 
	sl.BackgroundTransparency = 1
	sl.Text = ""
	sl.Font = FONT_GLOBAL
	sl.TextSize = 10
	sl.TextXAlignment = Enum.TextXAlignment.Center 
end

for _, p in pairs(Players:GetPlayers()) do task.spawn(BuildUI, p) end
Players.PlayerAdded:Connect(BuildUI)