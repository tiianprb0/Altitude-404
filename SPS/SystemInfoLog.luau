-- AltitudeInfoSystem & Settings -- StarterPlayerScripts --
-- Dioptimasi oleh Karina & ECA (DisplayOrder 99999, Dynamic Staff Tab, Leak-Free V10)
-- Update: Sistem In-Chat Welcome Message Anti-Gagal (Robust Retry Loop)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local UserService = game:GetService("UserService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [KARINA] Memanggil module TopbarPlus
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))

local uiName = "AltitudeInfoUI"
local oldUi = playerGui:FindFirstChild(uiName)
if oldUi then oldUi:Destroy() end

local oldBlur = Lighting:FindFirstChild("AltitudeInfoBlur")
if oldBlur then oldBlur:Destroy() end

local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "AltitudeInfoBlur"
blurEffect.Size = 0
blurEffect.Parent = Lighting

local THEME = {
	MainBG = Color3.fromRGB(30, 59, 103),
	SidebarBG = Color3.fromRGB(20, 45, 85),
	CardBG = Color3.fromRGB(40, 75, 125),
	Accent = Color3.fromRGB(247, 173, 175),
	TextMain = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(175, 195, 225),
	Highlight = Color3.fromRGB(250, 204, 21),
	Success = Color3.fromRGB(74, 222, 128),
	Danger = Color3.fromRGB(248, 113, 113)
}

local FONT_GLOBAL = Enum.Font.Montserrat

local gui = Instance.new("ScreenGui")
gui.Name = uiName
gui.IgnoreGuiInset = true 
gui.ResetOnSpawn = false
gui.DisplayOrder = 99999 
gui.Parent = playerGui

-- ==========================================
-- FUNGSI BANTUAN ANIMASI PANEL
-- ==========================================
local activePanel = nil

local function openPanel(panel)
	if activePanel == panel then return end
	if activePanel then
		TweenService:Create(activePanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.58, 0), GroupTransparency = 1
		}):Play()
		task.delay(0.2, function() activePanel.Visible = false end)
	else
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
		TweenService:Create(blurEffect, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 20}):Play()
	end

	activePanel = panel
	panel.Visible = true
	TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0), GroupTransparency = 0
	}):Play()
end

local function closeAllPanels()
	if not activePanel then return end
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
	TweenService:Create(blurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = 0}):Play()

	local tOut = TweenService:Create(activePanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.58, 0), GroupTransparency = 1
	})
	tOut:Play()

	local panelToClose = activePanel
	activePanel = nil
	tOut.Completed:Wait()
	if activePanel ~= panelToClose then panelToClose.Visible = false end
end

local function createPanelBase(name, size, useAspect)
	local p = Instance.new("CanvasGroup", gui)
	p.Name = name
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Size = size
	p.Position = UDim2.new(0.5, 0, 0.58, 0) 
	p.BackgroundTransparency = 1 
	p.Visible = false 
	p.GroupTransparency = 1
	p.ZIndex = 100 
	Instance.new("UISizeConstraint", p).MaxSize = Vector2.new(960, 610)

	if useAspect then
		Instance.new("UIAspectRatioConstraint", p).AspectRatio = 1.65
	end

	local visualBg = Instance.new("Frame", p)
	visualBg.Name = "VisualBg"
	visualBg.Size = UDim2.new(1, -60, 1, -60)
	visualBg.Position = UDim2.new(0.5, 0, 0.5, 0)
	visualBg.AnchorPoint = Vector2.new(0.5, 0.5)
	visualBg.BackgroundColor3 = THEME.MainBG
	Instance.new("UICorner", visualBg).CornerRadius = UDim.new(0, 12)

	local closeBg = Instance.new("Frame", p)
	closeBg.Name = "CloseBtn"
	closeBg.Size = UDim2.new(0, 32, 0, 32)
	closeBg.Position = UDim2.new(1, -30, 0, 30) 
	closeBg.AnchorPoint = Vector2.new(0.5, 0.5) 
	closeBg.BackgroundColor3 = THEME.Accent
	closeBg.ZIndex = 5000 
	closeBg.Rotation = 45 
	Instance.new("UICorner", closeBg).CornerRadius = UDim.new(0, 8) 

	local closeBtnAction = Instance.new("TextButton", closeBg)
	closeBtnAction.Size = UDim2.new(1, 0, 1, 0)
	closeBtnAction.BackgroundTransparency = 1
	closeBtnAction.Text = ""
	closeBtnAction.ZIndex = 5001

	local closeIcon = Instance.new("ImageLabel", closeBg)
	closeIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
	closeIcon.Position = UDim2.new(0.25, 0, 0.25, 0)
	closeIcon.Image = "rbxassetid://11293981586"
	closeIcon.ImageColor3 = THEME.MainBG
	closeIcon.BackgroundTransparency = 1
	closeIcon.Rotation = -45 
	closeIcon.ZIndex = 5001

	closeBtnAction.MouseEnter:Connect(function() TweenService:Create(closeBg, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Danger}):Play() end)
	closeBtnAction.MouseLeave:Connect(function() TweenService:Create(closeBg, TweenInfo.new(0.15), {BackgroundColor3 = THEME.Accent}):Play() end)

	return p, visualBg, closeBtnAction
end

-- ==========================================
-- 1. MEMBANGUN PANEL INFO (LORE, LOG & STAFF)
-- ==========================================
local infoPanel, infoBg, infoClose = createPanelBase("InfoPanel", UDim2.new(0.65, 60, 0.7, 60), true)

local sidebar = Instance.new("Frame", infoBg)
sidebar.Size = UDim2.new(0.25, 0, 1, 0)
sidebar.BackgroundColor3 = THEME.SidebarBG
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

local navList = Instance.new("UIListLayout", sidebar)
navList.Padding = UDim.new(0, 10)
navList.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 30)

local contentContainer = Instance.new("Frame", infoBg)
contentContainer.Position = UDim2.new(0.25, 0, 0, 0)
contentContainer.Size = UDim2.new(0.75, 0, 1, 0)
contentContainer.BackgroundTransparency = 1

local function CreateNavBtn(name)
	local btn = Instance.new("TextButton", sidebar)
	btn.Size = UDim2.new(0.85, 0, 0, 42) 
	btn.BackgroundColor3 = THEME.Accent
	btn.BackgroundTransparency = 1 
	btn.Text = name
	btn.Font = Enum.Font.MontserratBold
	btn.TextSize = 12
	btn.TextColor3 = THEME.TextMuted
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8) 
	return btn
end

local btnInfo = CreateNavBtn("PEMBERITAHUAN")
local btnLog = CreateNavBtn("UPDATE LOG")
local btnStaff = CreateNavBtn("STAFF")

local function CreatePage(name, iconId, textContent)
	local f = Instance.new("ScrollingFrame", contentContainer)
	f.Size = UDim2.new(1, 0, 1, 0)
	f.BackgroundTransparency = 1
	f.ScrollBarThickness = 2
	f.ScrollBarImageColor3 = THEME.Accent
	f.ScrollingDirection = Enum.ScrollingDirection.Y
	f.AutomaticCanvasSize = Enum.AutomaticSize.Y
	f.Visible = false

	local list = Instance.new("UIListLayout", f)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 20) 
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local pad = Instance.new("UIPadding", f)
	pad.PaddingLeft = UDim.new(0, 30); pad.PaddingRight = UDim.new(0, 30)
	pad.PaddingTop = UDim.new(0, 30); pad.PaddingBottom = UDim.new(0, 40) 

	if iconId and textContent then
		local bigIcon = Instance.new("ImageLabel", f)
		bigIcon.Size = UDim2.new(0, 80, 0, 80)
		bigIcon.BackgroundTransparency = 1
		bigIcon.Image = iconId
		bigIcon.ImageColor3 = THEME.Accent
		bigIcon.LayoutOrder = 1

		local textLbl = Instance.new("TextLabel", f)
		textLbl.Size = UDim2.new(1, 0, 0, 0)
		textLbl.BackgroundTransparency = 1
		textLbl.Text = textContent
		textLbl.Font = FONT_GLOBAL
		textLbl.TextColor3 = THEME.TextMuted
		textLbl.TextSize = 13
		textLbl.TextXAlignment = Enum.TextXAlignment.Left
		textLbl.TextYAlignment = Enum.TextYAlignment.Top
		textLbl.TextWrapped = true
		textLbl.RichText = true
		textLbl.AutomaticSize = Enum.AutomaticSize.Y
		textLbl.LayoutOrder = 2
	end
	return f, list
end

-- Teks Informasi
local infoText = "Halo, selamat datang di Altitude!<br/><br/>Di awal pendakian, kamu bisa milih satu dari dua jalur yang ada. Kalau mau santai, ada jalur yang bisa nyebrang pakai <b>boat atau jetski</b>. Makin ke atas, rintangannya bakal makin beragam. Hati-hati sama jalanan yang bolong tapi <b>ketutup daun</b> ya, itu sering bikin kegocek. Nanti juga ada goa yang isinya <b>bola batu ngglinding</b> sama <b>air beracun</b> yang bisa ngurangin darah. Pas masuk labirin, jangan kaget kalau tiba-tiba ngerasain <b>gempa</b> yang muncul terus hilang gitu aja, rasanya beneran kayak di dunia nyata.<br/><br/>Cuaca di sini juga ngga nentu loh, kadang cerah, eh tiba-tiba bisa turun kabut, hujan, atau badai. Terus denger-denger sih kadang ada <b>pocong</b> iseng yang nongol di beberapa spot, jadi waspada aja hehehe.<br/><br/>Kalau ngerasa mentok, coba perhatiin sekitar, siapa tahu kamu beruntung ketemu NPC namanya <b>Yarraa</b> di beberapa tempat tertentu. Kalau kamu bantuin quest dari dia, nanti dibukain <b>jalur alternatif</b>. Oh iya, sepanjang jalan juga banyak spot cantik buat foto-foto loh.<br/><br/>Terus kalau udah sampai puncak, ada <b>tugu</b> buat nanda-in kamu udah berhasil. Habis puas foto-foto, tinggal pakai <b>glider</b> aja di pinggir tebing buat melayang turun.<br/><br/>Oh iya satu lagi, biar pendakian awalnya lebih gampang, jangan lupa klaim kode promo <font color='#FACC15'><b>WELCOME</b></font> ya. Caranya buka menu <b>Shop</b>, pilih tab <b>General</b>, terus scroll ke paling bawah. Tinggal masukin aja kodenya di situ buat dapet modal awal 5.000 Coins. Have fun!"
local infoPage = CreatePage("Info", "rbxassetid://139244638766882", infoText)

local logText = "<font color='#F7ADAF'><b>[ V1.1.0 ] - Pembaruan & Eksplorasi</b></font><br/>"
logText = logText .. "- Pengalaman mengemudi <i>boat</i> kini lebih mulus dengan kendali dan kecepatan yang telah disesuaikan.<br/>"
logText = logText .. "- Fasilitas <i>Zipline</i> telah hadir, lengkap dengan penyesuaian jarak suara agar suasana alam tetap tenang.<br/>"
logText = logText .. "- Pembersihan dan penyesuaian letak rintangan di beberapa area strategis, termasuk goa, demi kelancaran dan kenyamanan eksplorasi.<br/>"
logText = logText .. "- Bagi yang mencari tantangan, kejutan kecil (pocong) kini telah ditambahkan di area labirin.<br/>"
logText = logText .. "- Suara petir telah diatur ulang agar terdengar natural tanpa mengganggu kenyamanan telinga.<br/>"
logText = logText .. "- Interaksi <i>quest</i> bersama NPC Yarraa kini berjalan lancar tanpa kendala.<br/>"
logText = logText .. "- Suasana cuaca yang lebih hidup dengan detail rintik air, efek hujan asam saat badai, serta performa visual yang tetap ringan.<br/>"
logText = logText .. "- Fitur Kompas kini tersedia untuk memandu arah eksplorasi menuju puncak.<br/>"
logText = logText .. "- Hadirnya fitur <i>Sync</i> untuk menyelaraskan gerakan animasi serentak bersama teman.<br/>"
logText = logText .. "- Sesama pendaki kini dapat saling berbagi dan mengirimkan Coins.<br/>"
logText = logText .. "- Fitur Gendong (<i>Carry</i>) telah diperbarui, lengkap dengan opsi Mode Privasi jika sedang tidak ingin menerima interaksi.<br/>"
logText = logText .. "- Penyegaran visual pada tekstur medan dan penambahan dekorasi alam sekitar agar pemandangan lebih memanjakan mata.<br/>"
logText = logText .. "- Perbaikan sistem penyimpanan; barang bawaan (<i>tools</i>) kini aman dan tidak hilang saat keluar dari permainan.<br/>"
logText = logText .. "- Pembersihan <i>bug</i> minor agar perjalanan di Altitude selalu nyaman dan stabil.<br/><br/>"

logText = logText .. "<font color='#F7ADAF'><b>[ V1.0.0 ] - Beta Testing</b></font><br/>"
logText = logText .. "- Selamat datang di tahap Beta Testing Altitude!<br/>"
logText = logText .. "- Area utama dan jalur pendakian dasar telah dibuka untuk umum.<br/>"
logText = logText .. "- Sistem ekonomi, Katalog, dan antarmuka utama siap digunakan.<br/>"
logText = logText .. "- Harap maklumi jika terdapat beberapa ketidaknyamanan selama fase pengujian ini berjalan."
local logPage = CreatePage("Log", "rbxassetid://99568097706760", logText)

-- ==========================================
-- PEMBUATAN TAB STAFF (DYNAMIC FETCH)
-- ==========================================
local staffPage, staffLayout = CreatePage("Staff", nil, nil)
staffLayout.Padding = UDim.new(0, 15)
local staffStatusCache = {}

local STAFF_DATA = {
	{ roleName = "CREATOR", ids = {9048968760} },
	{ roleName = "DEVELOPER", ids = {8967444995, 22222222} },
	{ roleName = "MODERATOR", ids = {4715523276, 8283435988, 9777814507, 7155269748, 9270416939, 9148442635, 9054982038, 8674490432} }
}

local currentLayoutOrder = 1

for _, group in ipairs(STAFF_DATA) do
	local roleTitle = Instance.new("TextLabel", staffPage)
	roleTitle.Size = UDim2.new(1, -20, 0, 20)
	roleTitle.BackgroundTransparency = 1
	roleTitle.Text = group.roleName
	roleTitle.Font = Enum.Font.MontserratBold
	roleTitle.TextSize = 12
	roleTitle.TextColor3 = THEME.Accent
	roleTitle.TextXAlignment = Enum.TextXAlignment.Left
	roleTitle.LayoutOrder = currentLayoutOrder
	currentLayoutOrder += 1

	for _, id in ipairs(group.ids) do
		local card = Instance.new("Frame", staffPage)
		card.Size = UDim2.new(1, -20, 0, 56)
		card.BackgroundColor3 = THEME.CardBG
		card.LayoutOrder = currentLayoutOrder
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
		currentLayoutOrder += 1

		local avatar = Instance.new("ImageLabel", card)
		avatar.Size = UDim2.new(0, 40, 0, 40)
		avatar.Position = UDim2.new(0, 8, 0.5, 0)
		avatar.AnchorPoint = Vector2.new(0, 0.5)
		avatar.BackgroundColor3 = THEME.SidebarBG
		avatar.BackgroundTransparency = 0
		Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

		local nameLbl = Instance.new("TextLabel", card)
		nameLbl.Size = UDim2.new(1, -100, 0.5, 0)
		nameLbl.Position = UDim2.new(0, 58, 0, 8)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = "Memuat..."
		nameLbl.Font = Enum.Font.MontserratBold
		nameLbl.TextSize = 14
		nameLbl.TextColor3 = THEME.TextMain
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left

		local userLbl = Instance.new("TextLabel", card)
		userLbl.Size = UDim2.new(1, -100, 0.5, 0)
		userLbl.Position = UDim2.new(0, 58, 0.5, -2)
		userLbl.BackgroundTransparency = 1
		userLbl.Text = "@" .. tostring(id)
		userLbl.Font = Enum.Font.Montserrat
		userLbl.TextSize = 12
		userLbl.TextColor3 = THEME.TextMuted
		userLbl.TextXAlignment = Enum.TextXAlignment.Left

		local isOnline = Players:GetPlayerByUserId(id) ~= nil

		local statusContainer = Instance.new("Frame", card)
		statusContainer.Size = UDim2.new(0, 70, 0, 20)
		statusContainer.Position = UDim2.new(1, -10, 0.5, 0)
		statusContainer.AnchorPoint = Vector2.new(1, 0.5)
		statusContainer.BackgroundTransparency = 1

		local statusDot = Instance.new("Frame", statusContainer)
		statusDot.Size = UDim2.new(0, 8, 0, 8)
		statusDot.Position = UDim2.new(1, 0, 0.5, 0)
		statusDot.AnchorPoint = Vector2.new(1, 0.5)
		statusDot.BackgroundColor3 = isOnline and THEME.Success or THEME.SidebarBG
		Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

		local statusText = Instance.new("TextLabel", statusContainer)
		statusText.Size = UDim2.new(1, -15, 1, 0)
		statusText.BackgroundTransparency = 1
		statusText.Text = isOnline and "Di Server" or "Offline"
		statusText.Font = Enum.Font.Montserrat
		statusText.TextSize = 10
		statusText.TextColor3 = isOnline and THEME.Success or THEME.TextMuted
		statusText.TextXAlignment = Enum.TextXAlignment.Right

		staffStatusCache[id] = { dot = statusDot, text = statusText }

		task.spawn(function()
			local success, infos = pcall(function()
				return UserService:GetUserInfosByUserIdsAsync({id})
			end)

			if success and infos and infos[1] then
				local info = infos[1]
				avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. info.Id .. "&w=150&h=150"
				avatar.BackgroundTransparency = 1
				nameLbl.Text = info.DisplayName
				userLbl.Text = "@" .. info.Username
			else
				nameLbl.Text = "Pengguna Tidak Valid"
			end
		end)
	end

	local divider = Instance.new("Frame", staffPage)
	divider.Size = UDim2.new(1, -20, 0, 1)
	divider.BackgroundColor3 = THEME.CardBG
	divider.BorderSizePixel = 0
	divider.LayoutOrder = currentLayoutOrder
	currentLayoutOrder += 1
end

Players.PlayerAdded:Connect(function(p)
	local cache = staffStatusCache[p.UserId]
	if cache then
		cache.dot.BackgroundColor3 = THEME.Success
		cache.text.Text = "Di Server"
		cache.text.TextColor3 = THEME.Success
	end
end)
Players.PlayerRemoving:Connect(function(p)
	local cache = staffStatusCache[p.UserId]
	if cache then
		cache.dot.BackgroundColor3 = THEME.SidebarBG
		cache.text.Text = "Offline"
		cache.text.TextColor3 = THEME.TextMuted
	end
end)

-- ==========================================
-- LOGIKA NAVIGASI TAB INFO
-- ==========================================
local function switchInfoTab(tabName)
	btnInfo.BackgroundTransparency = 1; btnInfo.TextColor3 = THEME.TextMuted
	btnLog.BackgroundTransparency = 1; btnLog.TextColor3 = THEME.TextMuted
	btnStaff.BackgroundTransparency = 1; btnStaff.TextColor3 = THEME.TextMuted
	infoPage.Visible = false; logPage.Visible = false; staffPage.Visible = false

	if tabName == "Info" then
		btnInfo.BackgroundTransparency = 0; btnInfo.TextColor3 = THEME.MainBG
		infoPage.Visible = true
	elseif tabName == "Log" then
		btnLog.BackgroundTransparency = 0; btnLog.TextColor3 = THEME.MainBG
		logPage.Visible = true
	elseif tabName == "Staff" then
		btnStaff.BackgroundTransparency = 0; btnStaff.TextColor3 = THEME.MainBG
		staffPage.Visible = true
	end
end

btnInfo.MouseButton1Click:Connect(function() switchInfoTab("Info") end)
btnLog.MouseButton1Click:Connect(function() switchInfoTab("Log") end)
btnStaff.MouseButton1Click:Connect(function() switchInfoTab("Staff") end)
switchInfoTab("Info")

-- ==========================================
-- 2. MEMBANGUN PANEL SETTINGS KUSTOM
-- ==========================================
local isMobile = UserInputService.TouchEnabled

local panelHeightScale = isMobile and 0.85 or 0.5
local panelMaxHeight = isMobile and 600 or 330

local settingsPanel, setBg, setClose = createPanelBase("SettingsPanel", UDim2.new(0.85, 0, panelHeightScale, 0), false)
settingsPanel:FindFirstChildOfClass("UISizeConstraint").MaxSize = Vector2.new(400, panelMaxHeight)

local setTitle = Instance.new("TextLabel", setBg)
setTitle.Size = UDim2.new(1, 0, 0, 60)
setTitle.BackgroundTransparency = 1
setTitle.Text = "S E T T I N G S"
setTitle.Font = Enum.Font.MontserratBold
setTitle.TextSize = 18
setTitle.TextColor3 = THEME.Accent

local setListFrame = Instance.new("ScrollingFrame", setBg)
setListFrame.Size = UDim2.new(1, 0, 1, -70)
setListFrame.Position = UDim2.new(0, 0, 0, 60)
setListFrame.BackgroundTransparency = 1
setListFrame.ScrollBarThickness = 3
setListFrame.ScrollBarImageColor3 = THEME.CardBG
setListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
setListFrame.CanvasSize = UDim2.new(0,0,0,0)

local sList = Instance.new("UIListLayout", setListFrame)
sList.SortOrder = Enum.SortOrder.LayoutOrder
sList.Padding = UDim.new(0, 12)
sList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local sPad = Instance.new("UIPadding", setListFrame)
sPad.PaddingBottom = UDim.new(0, 20)

local function createDivider(order)
	local d = Instance.new("Frame", setListFrame)
	d.Size = UDim2.new(0.85, 0, 0, 2)
	d.BackgroundColor3 = THEME.CardBG
	d.BorderSizePixel = 0
	d.LayoutOrder = order
end

local function createActionUI(labelText, btnText, btnColor, callback, order)
	local container = Instance.new("Frame", setListFrame)
	container.Size = UDim2.new(0.85, 0, 0, 45)
	container.BackgroundColor3 = THEME.CardBG
	container.LayoutOrder = order
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel", container)
	lbl.Size = UDim2.new(0.6, 0, 1, 0)
	lbl.Position = UDim2.new(0, 15, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.Font = FONT_GLOBAL
	lbl.TextColor3 = THEME.TextMain
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", container)
	btn.Size = UDim2.new(0, 90, 0, 26)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -10, 0.5, 0)
	btn.BackgroundColor3 = btnColor
	btn.Text = btnText
	btn.Font = Enum.Font.MontserratBold
	btn.TextColor3 = THEME.MainBG
	btn.TextSize = 11
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Click:Connect(callback)
end

local function createToggleUI(name, labelText, defaultState, callback, order)
	local container = Instance.new("Frame", setListFrame)
	container.Size = UDim2.new(0.85, 0, 0, 45)
	container.BackgroundColor3 = THEME.CardBG
	container.LayoutOrder = order
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel", container)
	lbl.Size = UDim2.new(0.7, 0, 1, 0)
	lbl.Position = UDim2.new(0, 15, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.Font = FONT_GLOBAL
	lbl.TextColor3 = THEME.TextMain
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", container)
	btn.Size = UDim2.new(0, 60, 0, 26)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -10, 0.5, 0)
	btn.BackgroundColor3 = defaultState and THEME.Success or THEME.SidebarBG
	btn.Text = defaultState and "ON" or "OFF"
	btn.Font = Enum.Font.MontserratBold
	btn.TextColor3 = Color3.new(1,1,1)
	btn.TextSize = 12
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	local state = defaultState
	btn.MouseButton1Click:Connect(function()
		state = not state
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = state and THEME.Success or THEME.SidebarBG}):Play()
		btn.Text = state and "ON" or "OFF"
		callback(state)
	end)
end

local function createSliderUI(labelText, minVal, maxVal, defaultVal, isInt, callback, order)
	local container = Instance.new("Frame", setListFrame)
	container.Size = UDim2.new(0.85, 0, 0, 65)
	container.BackgroundColor3 = THEME.CardBG
	container.LayoutOrder = order
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel", container)
	lbl.Size = UDim2.new(1, -20, 0, 25)
	lbl.Position = UDim2.new(0, 15, 0, 5)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.Font = FONT_GLOBAL
	lbl.TextColor3 = THEME.TextMain
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local valLbl = Instance.new("TextLabel", container)
	valLbl.Size = UDim2.new(0, 50, 0, 25)
	valLbl.Position = UDim2.new(1, -60, 0, 5)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = isInt and string.format("%d", math.floor(defaultVal)) or string.format("%.2f", defaultVal)
	valLbl.Font = Enum.Font.MontserratBold
	valLbl.TextColor3 = THEME.Highlight
	valLbl.TextSize = 13
	valLbl.TextXAlignment = Enum.TextXAlignment.Right

	local track = Instance.new("Frame", container)
	track.Size = UDim2.new(1, -30, 0, 6)
	track.Position = UDim2.new(0, 15, 0, 40)
	track.BackgroundColor3 = THEME.SidebarBG
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame", track)
	fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = THEME.Accent
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("TextButton", fill)
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(1, 0, 0.5, 0)
	knob.BackgroundColor3 = THEME.TextMain
	knob.Text = ""
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local isDragging = false
	local function updateSlider(input)
		local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(pos, 0, 1, 0)
		local value = minVal + (pos * (maxVal - minVal))
		if isInt then value = math.floor(value) end
		valLbl.Text = isInt and string.format("%d", value) or string.format("%.2f", value)
		callback(value)
	end

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input)
		end
	end)
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			updateSlider(input)
			isDragging = true
		end
	end)
end

-- ==========================================
-- DEKLARASI TOPBARPLUS ICONS
-- ==========================================
local showUiIcon = Icon.new()
showUiIcon:setLabel("SHOW UI")
showUiIcon:setRight()
showUiIcon:setEnabled(false)

local settingsIcon = Icon.new()
settingsIcon:setImage("rbxassetid://7059346373")
settingsIcon:setRight()

local infoIcon = Icon.new()
infoIcon:setLabel("INFO") 
infoIcon:setRight()

-- ==========================================
-- LOGIKA CINEMATIC & SETTINGS UI
-- ==========================================
local TARGET_GUIS_TO_HIDE = { "TianKari_TopbarUI", "StatsGui", "SidebarMusicUI", "SidebarEmoteUI" }
local hiddenGuisCache = {}

createActionUI("Cinematic Mode", "HIDE UI", THEME.Accent, function()
	closeAllPanels()
	table.clear(hiddenGuisCache)

	settingsIcon:setEnabled(false)
	infoIcon:setEnabled(false)

	for _, name in ipairs(TARGET_GUIS_TO_HIDE) do
		local targetUi = playerGui:FindFirstChild(name)
		if targetUi and targetUi:IsA("ScreenGui") then
			hiddenGuisCache[targetUi] = targetUi.Enabled
			targetUi.Enabled = false
		end
	end

	local topbarGui = playerGui:FindFirstChild("TopbarPlus")
	if topbarGui then
		for _, container in ipairs(topbarGui:GetDescendants()) do
			if container.Name == "Left" or container.Name == "Center" or container.Name == "Right" then
				for _, widget in ipairs(container:GetChildren()) do
					if widget:IsA("Frame") or widget:IsA("ImageButton") then
						if widget.Visible then
							local isShowBtn = false
							for _, txt in ipairs(widget:GetDescendants()) do
								if txt:IsA("TextLabel") and txt.Text == "SHOW UI" then
									isShowBtn = true; break
								end
							end

							if not isShowBtn then
								hiddenGuisCache[widget] = widget.Visible
								widget.Visible = false
							end
						end
					end
				end
			end
		end
	end

	showUiIcon:setEnabled(true)
end, 1)

showUiIcon:bindEvent("selected", function()
	showUiIcon:deselect() 
	showUiIcon:setEnabled(false) 

	for child, wasVisible in pairs(hiddenGuisCache) do
		if child and child.Parent then
			if child:IsA("ScreenGui") then 
				child.Enabled = wasVisible 
			else
				child.Visible = wasVisible
			end
		end
	end

	table.clear(hiddenGuisCache)
	task.wait(0.1)
	settingsIcon:setEnabled(true)
	infoIcon:setEnabled(true)
end)

-- B. HIDE OVERHEAD & SHADOWS
createToggleUI("OverheadToggle", "Hide Overhead Titles", false, function(state)
	player:SetAttribute("HideOverhead", state)
end, 2)

createToggleUI("ShadowToggle", "Hide Global Shadows", false, function(state)
	Lighting.GlobalShadows = not state
end, 3)

-- C. MOBILE JUMP CONTROLS
createDivider(4)

local jumpScale = 1.0
local jumpOffsetX = 0
local jumpOffsetY = 0
local originalJumpPos = nil

local function applyJumpSettings()
	local touchGui = playerGui:FindFirstChild("TouchGui")
	if not touchGui then return end
	local jumpBtn = touchGui:FindFirstChild("JumpButton", true)
	if not jumpBtn then return end

	if not originalJumpPos then originalJumpPos = jumpBtn.Position end

	local uiScale = jumpBtn:FindFirstChild("KarinaJumpScale")
	if not uiScale then
		uiScale = Instance.new("UIScale", jumpBtn)
		uiScale.Name = "KarinaJumpScale"
	end
	uiScale.Scale = jumpScale

	local newPos = UDim2.new(
		originalJumpPos.X.Scale, 
		originalJumpPos.X.Offset + jumpOffsetX, 
		originalJumpPos.Y.Scale, 
		originalJumpPos.Y.Offset + jumpOffsetY
	)
	jumpBtn.Position = newPos
end

playerGui.ChildAdded:Connect(function(child)
	if child.Name == "TouchGui" then
		task.wait(0.5) 
		applyJumpSettings()
	end
end)

if isMobile then
	createSliderUI("Jump Button: Ukuran", 0.5, 1.6, 1.0, false, function(val) jumpScale = val; applyJumpSettings() end, 5)
	createSliderUI("Jump Button: Geser X", -120, 120, 0, true, function(val) jumpOffsetX = val; applyJumpSettings() end, 6)
	createSliderUI("Jump Button: Geser Y", -120, 120, 0, true, function(val) jumpOffsetY = val * -1; applyJumpSettings() end, 7)
end

-- ==========================================
-- BINDING TOPBARPLUS
-- ==========================================
settingsIcon:bindEvent("selected", function()
	if infoIcon.isSelected then infoIcon:deselect() end
	openPanel(settingsPanel)
end)
settingsIcon:bindEvent("deselected", function()
	closeAllPanels()
end)

infoIcon:bindEvent("selected", function()
	if settingsIcon.isSelected then settingsIcon:deselect() end
	openPanel(infoPanel)
end)
infoIcon:bindEvent("deselected", function()
	closeAllPanels()
end)

infoClose.MouseButton1Click:Connect(function() infoIcon:deselect() end)
setClose.MouseButton1Click:Connect(function() settingsIcon:deselect() end)

-- ==========================================
-- PESAN SAMBUTAN IN-CHAT (ANTI-GAGAL)
-- ==========================================
task.spawn(function()
	local TextChatService = game:GetService("TextChatService")
	local welcomeHTML = "<font color='#F7ADAF'><b>[Altitude]</b> Selamat datang. Silakan akses menu INFO di kanan atas untuk pembaruan terbaru, panduan fasilitas, dan daftar staf kami.</font>"
	local legacyText = "[Altitude] Selamat datang. Silakan akses menu INFO di kanan atas untuk pembaruan terbaru, panduan fasilitas, dan daftar staf kami."

	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		-- Tunggu channel RBXSystem termuat sempurna (Anti-Gagal)
		local channels = TextChatService:WaitForChild("TextChannels", 10)
		if channels then
			local sysChannel = channels:WaitForChild("RBXSystem", 10)
			if sysChannel then
				-- Beri jeda ekstra agar UI chat benar-benar sudah digambar di layar
				task.wait(2)
				sysChannel:DisplaySystemMessage(welcomeHTML)
			end
		end
	else
		-- Legacy Chat: Butuh mekanisme retry karena SetCore sering tertahan saat join awal
		local success = false
		local attempts = 0
		while not success and attempts < 15 do
			success = pcall(function()
				StarterGui:SetCore("ChatMakeSystemMessage", {
					Text = legacyText,
					Color = THEME.Accent,
					Font = Enum.Font.Montserrat
				})
			end)
			if not success then
				task.wait(1)
				attempts += 1
			end
		end
	end
end)