--[[
    ALTITUDE PROFILE GENERATOR V4.0 (CINEMATIC STYLE - COMPACT 2 COLUMNS)
    Cara pakai: Jalankan script ini di Studio. UI akan otomatis masuk ke StarterGui.
    Setelah selesai, copy hasilnya, lalu hapus script ini.
]]

local StarterGui = game:GetService("StarterGui")

-- Bersihkan UI Lama
local oldGui = StarterGui:FindFirstChild("AltitudeProfileUI")
if oldGui then oldGui:Destroy() end

local THEME = {
	MainBG = Color3.fromRGB(30, 59, 103),
	SidebarBG = Color3.fromRGB(20, 45, 85),
	CardBG = Color3.fromRGB(40, 75, 125),
	Accent = Color3.fromRGB(247, 173, 175),
	RobuxColor = Color3.fromRGB(46, 204, 113), 
	TextMain = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(175, 195, 225),
}

local FONT_GLOBAL = Enum.Font.Montserrat
local FONT_BOLD = Enum.Font.GothamBold

-- 1. SCREEN GUI
local sg = Instance.new("ScreenGui")
sg.Name = "AltitudeProfileUI"
sg.IgnoreGuiInset = true
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = StarterGui

-- 2. MAIN FRAME (COMPACT & TALL)
local main = Instance.new("CanvasGroup", sg)
main.Name = "MainFrame"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.new(0.45, 0, 0.65, 0) -- Dipersempit agar tidak melebar
main.Position = UDim2.new(0.5, 0, 0.58, 0)
main.BackgroundTransparency = 1
main.Visible = true 
Instance.new("UISizeConstraint", main).MaxSize = Vector2.new(550, 650) -- Batas maksimal ukuran dibuat lebih vertikal

local visualBg = Instance.new("Frame", main)
visualBg.Name = "VisualBg"
visualBg.Size = UDim2.new(1, -40, 1, -40)
visualBg.Position = UDim2.new(0.5, 0, 0.5, 0)
visualBg.AnchorPoint = Vector2.new(0.5, 0.5)
visualBg.BackgroundColor3 = THEME.MainBG
Instance.new("UICorner", visualBg).CornerRadius = UDim.new(0, 12)

-- TOMBOL CLOSE (Cinematic Diamond Style)
local closeBg = Instance.new("Frame", main)
closeBg.Name = "CloseBtn"
closeBg.Size = UDim2.new(0, 32, 0, 32)
closeBg.Position = UDim2.new(1, -20, 0, 20)
closeBg.AnchorPoint = Vector2.new(0.5, 0.5)
closeBg.BackgroundColor3 = THEME.Accent
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
closeIcon.Image = "rbxassetid://11293981586"
closeIcon.ImageColor3 = THEME.MainBG
closeIcon.BackgroundTransparency = 1
closeIcon.Rotation = -45

-- 3. SCROLLING FRAME UTAMA
local mainScroll = Instance.new("ScrollingFrame", visualBg)
mainScroll.Name = "MainScroll"
mainScroll.Size = UDim2.new(1, 0, 1, 0)
mainScroll.BackgroundTransparency = 1
mainScroll.ScrollBarThickness = 3
mainScroll.ScrollBarImageColor3 = THEME.Accent
mainScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
mainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local scrollLayout = Instance.new("UIListLayout", mainScroll)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 20)
scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local scrollPadding = Instance.new("UIPadding", mainScroll)
scrollPadding.PaddingTop = UDim.new(0, 25)
scrollPadding.PaddingBottom = UDim.new(0, 40)

-- 4. HEADER CONTAINER (Menyesuaikan dengan lebar baru)
local headerContainer = Instance.new("Frame", mainScroll)
headerContainer.Name = "HeaderContainer"
headerContainer.Size = UDim2.new(0.9, 0, 0, 160)
headerContainer.BackgroundColor3 = THEME.SidebarBG
headerContainer.LayoutOrder = 1
Instance.new("UICorner", headerContainer).CornerRadius = UDim.new(0, 12)

local avatarBg = Instance.new("Frame", headerContainer)
avatarBg.Size = UDim2.new(0, 110, 0, 110)
avatarBg.Position = UDim2.new(0, 20, 0.5, -55)
avatarBg.BackgroundColor3 = THEME.CardBG
Instance.new("UICorner", avatarBg).CornerRadius = UDim.new(0, 12)

local avatarImg = Instance.new("ImageLabel", avatarBg)
avatarImg.Name = "AvatarImage"
avatarImg.Size = UDim2.new(1, 0, 1, 0)
avatarImg.BackgroundTransparency = 1
avatarImg.Image = "rbxassetid://12000216664" 
Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(0, 12)

local infoContainer = Instance.new("Frame", headerContainer)
infoContainer.Name = "InfoContainer"
infoContainer.Size = UDim2.new(1, -150, 1, -30)
infoContainer.Position = UDim2.new(0, 145, 0, 15)
infoContainer.BackgroundTransparency = 1

local infoLayout = Instance.new("UIListLayout", infoContainer)
infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoLayout.Padding = UDim.new(0, 4)

local nameLabel = Instance.new("TextLabel", infoContainer)
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(1, 0, 0, 22)
nameLabel.BackgroundTransparency = 1
nameLabel.Font = FONT_BOLD
nameLabel.TextColor3 = THEME.TextMain
nameLabel.TextSize = 20
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Text = "Username"
nameLabel.LayoutOrder = 1

local roleLabel = Instance.new("TextLabel", infoContainer)
roleLabel.Name = "RoleTitleLabel"
roleLabel.Size = UDim2.new(1, 0, 0, 16)
roleLabel.BackgroundTransparency = 1
roleLabel.Font = FONT_GLOBAL
roleLabel.TextColor3 = THEME.Accent
roleLabel.TextSize = 13
roleLabel.TextXAlignment = Enum.TextXAlignment.Left
roleLabel.Text = "Player"
roleLabel.LayoutOrder = 2

local summitLabel = Instance.new("TextLabel", infoContainer)
summitLabel.Name = "SummitTitleLabel"
summitLabel.Size = UDim2.new(1, 0, 0, 16)
summitLabel.BackgroundTransparency = 1
summitLabel.Font = FONT_GLOBAL
summitLabel.TextColor3 = Color3.fromRGB(222, 235, 255)
summitLabel.TextSize = 13
summitLabel.TextXAlignment = Enum.TextXAlignment.Left
summitLabel.Text = "Snuggly Camper"
summitLabel.LayoutOrder = 3

-- STATS CONTAINER (Disesuaikan agar muat di layar kecil)
local statsContainer = Instance.new("Frame", infoContainer)
statsContainer.Name = "StatsContainer"
statsContainer.Size = UDim2.new(1, 0, 0, 28)
statsContainer.BackgroundTransparency = 1
statsContainer.LayoutOrder = 4

local statsLayout = Instance.new("UIListLayout", statsContainer)
statsLayout.FillDirection = Enum.FillDirection.Horizontal
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Padding = UDim.new(0, 10)

local function CreateStat(id, title)
	local statFrame = Instance.new("Frame", statsContainer)
	statFrame.Name = id .. "Stat"
	statFrame.Size = UDim2.new(0, 95, 1, 0)
	statFrame.BackgroundColor3 = THEME.CardBG
	Instance.new("UICorner", statFrame).CornerRadius = UDim.new(0, 6)

	local titleLbl = Instance.new("TextLabel", statFrame)
	titleLbl.Size = UDim2.new(0.4, 0, 1, 0)
	titleLbl.Position = UDim2.new(0.05, 0, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = FONT_GLOBAL
	titleLbl.TextColor3 = THEME.TextMuted
	titleLbl.TextSize = 10
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Text = title .. ":"

	local valLbl = Instance.new("TextLabel", statFrame)
	valLbl.Name = "ValueLabel"
	valLbl.Size = UDim2.new(0.5, 0, 1, 0)
	valLbl.Position = UDim2.new(0.45, 0, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Font = FONT_BOLD
	valLbl.TextColor3 = THEME.TextMain
	valLbl.TextSize = 11
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Text = "0"
end
CreateStat("Summits", "Summits")
CreateStat("Coins", "Coins")

-- HIDE AURA TOGGLE
local hideAuraBtn = Instance.new("TextButton", infoContainer)
hideAuraBtn.Name = "HideAuraToggleButton"
hideAuraBtn.Size = UDim2.new(0, 130, 0, 22)
hideAuraBtn.BackgroundColor3 = THEME.CardBG
hideAuraBtn.TextColor3 = THEME.TextMain
hideAuraBtn.Font = FONT_BOLD
hideAuraBtn.TextSize = 10
hideAuraBtn.Text = "👁️ Hide Aura: OFF"
hideAuraBtn.LayoutOrder = 5
hideAuraBtn.Visible = false 
Instance.new("UICorner", hideAuraBtn).CornerRadius = UDim.new(0, 6)

-- 5. LABEL "YOUR AURAS"
local inventoryTitle = Instance.new("TextLabel", mainScroll)
inventoryTitle.Size = UDim2.new(0.9, 0, 0, 20)
inventoryTitle.BackgroundTransparency = 1
inventoryTitle.Font = FONT_BOLD
inventoryTitle.TextColor3 = THEME.TextMuted
inventoryTitle.TextSize = 12
inventoryTitle.TextXAlignment = Enum.TextXAlignment.Left
inventoryTitle.Text = "YOUR AURAS"
inventoryTitle.LayoutOrder = 2

-- 6. ITEMS CONTAINER (2 AURA PER BARIS)
local itemsContainer = Instance.new("Frame", mainScroll)
itemsContainer.Name = "ItemsContainer"
itemsContainer.Size = UDim2.new(0.9, 0, 0, 0)
itemsContainer.BackgroundTransparency = 1
itemsContainer.AutomaticSize = Enum.AutomaticSize.Y
itemsContainer.LayoutOrder = 3

-- Kalkulasi Presisi 2 Kolom: (0.48 * 2) + 0.04 padding = 1.0 (100% penuh)
local gridLayout = Instance.new("UIGridLayout", itemsContainer)
gridLayout.CellSize = UDim2.new(0.48, 0, 0, 100) 
gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 15)

-- 7. ITEM TEMPLATE (MINIMALIST)
local template = Instance.new("Frame", sg)
template.Name = "ItemTemplate"
template.BackgroundColor3 = THEME.CardBG
template.Visible = false
Instance.new("UICorner", template).CornerRadius = UDim.new(0, 8)

local tName = Instance.new("TextLabel", template)
tName.Name = "ItemName"
tName.Size = UDim2.new(0.9, 0, 0.4, 0)
tName.Position = UDim2.new(0.05, 0, 0.05, 0) 
tName.BackgroundTransparency = 1
tName.Font = FONT_BOLD
tName.TextColor3 = THEME.TextMain
tName.TextSize = 14
tName.TextWrapped = true
tName.TextYAlignment = Enum.TextYAlignment.Center

local tBtn = Instance.new("TextButton", template)
tBtn.Name = "EquipButton"
tBtn.Size = UDim2.new(0.8, 0, 0.25, 0)
tBtn.Position = UDim2.new(0.1, 0, 0.48, 0)
tBtn.BackgroundColor3 = THEME.Accent
tBtn.TextColor3 = THEME.MainBG
tBtn.Font = FONT_BOLD
tBtn.TextSize = 11
tBtn.Text = "EQUIP"
Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)

local tStat = Instance.new("TextLabel", template)
tStat.Name = "StatusLabel"
tStat.Size = UDim2.new(1, 0, 0, 15)
tStat.Position = UDim2.new(0, 0, 0.78, 0)
tStat.BackgroundTransparency = 1
tStat.Font = FONT_GLOBAL
tStat.TextColor3 = THEME.TextMuted
tStat.TextSize = 10
tStat.Text = "Not Equipped"

print("[KARINA] UI Profil Compact 2-Kolom (Cinematic Theme) berhasil di-generate di StarterGui!")