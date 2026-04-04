--[[
    ALTITUDE AVATAR CHANGER (UNIFIED THEME)
    Design Adapted for Christian John Benaya Purba (Tian)
    
    Updates by Karina (Revision 7):
    1. UI Unified with Altitude Shop Theme (Colors, Fonts, Corner Radius).
    2. Responsive Scaling (UDim2 0.65 x 0.7) with AspectRatioConstraint.
    3. Edgy Diamond Close Button FIXED (CanvasGroup changed to Frame to prevent clipping).
    4. Sidebar layout aligned with Cinematic V6 (0.25 Width, UIListLayout).
    5. 3D Preview Camera FIXED (Dynamic focus height and distance to prevent cut-offs).
    6. RESTORED: MouseEnter/MouseLeave Hover animations for all interactables.
    7. RESTORED: "EQUIPPED" label adapted to Altitude's clean aesthetic.
    8. COLOR UPDATE: Custom Navy Blue & Soft Pink palette requested by Tian.
    9. IMMERSION UPDATE: UI centered optically at 0.58 Y (Dropped by 3%).
    10. EXTERNAL GUI LOGIC: Advanced state memory with Tween fading for external CanvasGroups.
    11. OOP TOPBAR: Integrated custom KariTopbar using robust .new() and :Bind() methods.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Import Custom Topbar buatan Tian (Menggunakan pola OOP)
local KariTopbar = require(ReplicatedStorage:WaitForChild("KariTopbar"))

-- RemoteEvents
local changeAvatarEvent = ReplicatedStorage:WaitForChild("ChangeAvatarEvent")
local resetAvatarEvent = ReplicatedStorage:WaitForChild("ResetAvatarEvent")
local addAccessoryEvent = ReplicatedStorage:WaitForChild("AddAccessoryEvent")
local removeAccessoryEvent = ReplicatedStorage:WaitForChild("RemoveAccessoryEvent")

-- ============================================
-- 0. KONFIGURASI GUI EKSTERNAL (MODAL OPEN)
-- ============================================
-- [KARINA] Masukkan nama GUI yang ingin disembunyikan saat panel Avatar TERBUKA.
-- PERHATIAN: JANGAN masukkan "AltitudeAvatarChanger" ke sini.
local EXTERNAL_GUIS = {"AltitudeCatalogUI", "StatsGui", "ShopGui", "CinematicGUI"} 
local externalGuiStates = {}

local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ============================================
-- THEME & ICONS
-- ============================================
local THEME = {
	MainBG = Color3.fromRGB(30, 59, 103),
	SidebarBG = Color3.fromRGB(20, 42, 77),
	CardBG = Color3.fromRGB(42, 75, 124),
	CardHover = Color3.fromRGB(56, 95, 150),
	Accent = Color3.fromRGB(247, 173, 175),
	Success = Color3.fromRGB(46, 204, 113), 
	Danger = Color3.fromRGB(237, 66, 69),
	TextMain = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(180, 195, 220),
}

local ICONS = {
	Close = "rbxassetid://11293981586",
}

local FONT_GLOBAL = Enum.Font.Montserrat

-- ============================================
-- AVATAR & ACCESSORY DATA
-- ============================================
local AVATARS = {
	Boys = {
		{name = "Boys 1", id = 9101259798}, {name = "Boys 2", id = 8912185225},
		{name = "Boys 3", id = 8935877365}, {name = "Boys 4", id = 8352609716},
		{name = "Boys 5", id = 8976748119}, {name = "Boys 6", id = 8968308984},
		{name = "Boys 7", id = 4832303740}, {name = "Boys 8", id = 9220382005},
		{name = "Boys 9", id = 9046030552}, {name = "Boys 10", id = 9000844254},
		{name = "Boys 11", id = 8966687266}, {name = "Boys 12", id = 9112933446}
	},
	Girls = {
		{name = "Girls 1", id = 9181935703}, {name = "Girls 2", id = 7843828496},
		{name = "Girls 3", id = 3226668321}, {name = "Girls 4", id = 7260068521},
		{name = "Girls 5", id = 8592887007}, {name = "Girls 6", id = 9093398365},
		{name = "Girls 7", id = 8918025774}, {name = "Girls 8", id = 8935328065},
		{name = "Girls 9", id = 8891975253}, {name = "Girls 10", id = 8486540814},
		{name = "Girls 11", id = 9101275612}, {name = "Girls 12", id = 9084296513}
	}
}

local ACCESSORIES = {
	{name = "Crown 8 Bit", id = 10159600649},
	{name = "8-Bit Extra Life", id = 10159606132},
	{name = "8-Bit HP Bar", id = 10159610478},
	{name = "8-Bit Roblox Coin", id = 10159622004},
	{name = "8-Bit Tabby Cat", id = 10159617728},
}

-- ============================================
-- GUI CONSTRUCTION
-- ============================================
local gui = Instance.new("ScreenGui")
gui.Name = "AltitudeAvatarChanger"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1 
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = gui

-- MAIN FRAME (Diubah menjadi Frame agar tidak clipping tombol Close)
local main = Instance.new("Frame")
main.Name = "MainFrame"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.new(0.65, 0, 0.7, 0)
main.Position = UDim2.new(0.5, 0, 0.58, 0) -- Diturunkan sesuai Cinematic V6
main.BackgroundColor3 = THEME.MainBG
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui

Instance.new("UISizeConstraint", main).MaxSize = Vector2.new(900, 550)
Instance.new("UIAspectRatioConstraint", main).AspectRatio = 1.65
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

-- DIAMOND CLOSE BUTTON (OUTSIDE CONTAINER - Cinematic Style)
local closeBg = Instance.new("Frame", main)
closeBg.Name = "CloseBtn"
closeBg.Size = UDim2.new(0, 32, 0, 32)
closeBg.Position = UDim2.new(1, 0, 0, 0)
closeBg.AnchorPoint = Vector2.new(0.5, 0.5)
closeBg.BackgroundColor3 = THEME.Accent
closeBg.ZIndex = 5000 
closeBg.Rotation = 45 
Instance.new("UICorner", closeBg).CornerRadius = UDim.new(0, 8)

local closeIcon = Instance.new("ImageLabel", closeBg)
closeIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
closeIcon.Position = UDim2.new(0.25, 0, 0.25, 0)
closeIcon.Image = ICONS.Close
closeIcon.ImageColor3 = THEME.MainBG
closeIcon.BackgroundTransparency = 1
closeIcon.Rotation = -45
closeIcon.ZIndex = 5001

local closeBtnAction = Instance.new("TextButton", closeBg)
closeBtnAction.Name = "Action"
closeBtnAction.Size = UDim2.new(1, 0, 1, 0)
closeBtnAction.BackgroundTransparency = 1
closeBtnAction.Text = ""
closeBtnAction.ZIndex = 5002 -- Memastikan area klik berada di atas Ikon

-- SIDEBAR (Cinematic Style: 0.25 Width)
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0.25, 0, 1, 0)
sidebar.BackgroundColor3 = THEME.SidebarBG
sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

local navContainer = Instance.new("Frame", sidebar)
navContainer.Size = UDim2.new(1, 0, 1, -60)
navContainer.BackgroundTransparency = 1

local navList = Instance.new("UIListLayout", navContainer)
navList.Padding = UDim.new(0, 10)
navList.SortOrder = Enum.SortOrder.LayoutOrder
navList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local navPad = Instance.new("UIPadding", navContainer)
navPad.PaddingTop = UDim.new(0, 30)

-- RESET BUTTON (Tetap di bawah sidebar)
local resetBtn = Instance.new("TextButton", sidebar)
resetBtn.Size = UDim2.new(0.85, 0, 0, 38)
resetBtn.Position = UDim2.new(0.075, 0, 1, -50)
resetBtn.BackgroundColor3 = THEME.CardBG
resetBtn.Text = "RESET AVATAR"
resetBtn.Font = FONT_GLOBAL
resetBtn.TextColor3 = THEME.TextMuted
resetBtn.TextSize = 11
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 8)

-- CONTENT CONTAINER (Adjusted for 0.25 Sidebar)
local contentContainer = Instance.new("Frame", main)
contentContainer.Size = UDim2.new(0.75, 0, 1, 0)
contentContainer.Position = UDim2.new(0.25, 0, 0, 0)
contentContainer.BackgroundTransparency = 1

-- Sub Categories (Boys/Girls)
local categoryTabs = Instance.new("Frame", contentContainer)
categoryTabs.Size = UDim2.new(0.55, 0, 0, 50)
categoryTabs.BackgroundTransparency = 1

local catLayout = Instance.new("UIListLayout", categoryTabs)
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.Padding = UDim.new(0, 15)
catLayout.VerticalAlignment = Enum.VerticalAlignment.Center
catLayout.SortOrder = Enum.SortOrder.LayoutOrder

local catPadding = Instance.new("UIPadding", categoryTabs)
catPadding.PaddingLeft = UDim.new(0, 20)

-- Left: Grid Content
local gridContainer = Instance.new("Frame", contentContainer)
gridContainer.Size = UDim2.new(0.55, 0, 1, -60)
gridContainer.Position = UDim2.new(0, 0, 0, 60)
gridContainer.BackgroundTransparency = 1

local gridScroll = Instance.new("ScrollingFrame", gridContainer)
gridScroll.Size = UDim2.new(1, -20, 1, -20)
gridScroll.Position = UDim2.new(0, 20, 0, 0)
gridScroll.BackgroundTransparency = 1
gridScroll.ScrollBarThickness = 3
gridScroll.ScrollBarImageColor3 = THEME.Accent
gridScroll.ScrollingDirection = Enum.ScrollingDirection.Y
gridScroll.CanvasSize = UDim2.new(0,0,0,0)

local uiGrid = Instance.new("UIGridLayout", gridScroll)
uiGrid.CellSize = UDim2.new(0.3, 0, 0, 100)
uiGrid.CellPadding = UDim2.new(0.03, 0, 0, 10)

-- Right: 3D Preview Panel
local previewPanel = Instance.new("Frame", contentContainer)
previewPanel.Size = UDim2.new(0.45, -20, 1, -40)
previewPanel.Position = UDim2.new(0.55, 0, 0, 20)
previewPanel.BackgroundColor3 = THEME.CardBG
Instance.new("UICorner", previewPanel).CornerRadius = UDim.new(0, 10)

local previewTitle = Instance.new("TextLabel", previewPanel)
previewTitle.Size = UDim2.new(1, 0, 0, 30)
previewTitle.Text = "PREVIEW"
previewTitle.Font = Enum.Font.MontserratBold
previewTitle.TextColor3 = THEME.TextMuted
previewTitle.TextSize = 12
previewTitle.BackgroundTransparency = 1

local viewport = Instance.new("ViewportFrame", previewPanel)
viewport.Size = UDim2.new(1, -20, 1, -120)
viewport.Position = UDim2.new(0, 10, 0, 30)
viewport.BackgroundTransparency = 1

local camera = Instance.new("Camera")
camera.Parent = viewport
viewport.CurrentCamera = camera

local worldModel = Instance.new("WorldModel")
worldModel.Parent = viewport
local previewCharacter = nil
local rotationConnection = nil

local selectedName = Instance.new("TextLabel", previewPanel)
selectedName.Size = UDim2.new(1, -20, 0, 30)
selectedName.Position = UDim2.new(0, 10, 1, -85)
selectedName.Text = "Select an item"
selectedName.Font = FONT_GLOBAL
selectedName.TextColor3 = THEME.TextMain
selectedName.TextSize = 13
selectedName.BackgroundTransparency = 1
selectedName.TextTruncate = Enum.TextTruncate.AtEnd

-- ACTION BUTTON (Use/Add)
local actionBtn = Instance.new("TextButton", previewPanel)
actionBtn.Size = UDim2.new(1, -40, 0, 35)
actionBtn.Position = UDim2.new(0, 20, 1, -45)
actionBtn.BackgroundColor3 = THEME.Accent
actionBtn.Text = "EQUIP"
actionBtn.Font = Enum.Font.MontserratBold
actionBtn.TextColor3 = THEME.MainBG
actionBtn.TextSize = 12
Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 8)

-- EFEK BLUR (Aman mencegah duplikasi)
local blurEffect = Lighting:FindFirstChild("AvatarChangerBlur")
if not blurEffect then
	blurEffect = Instance.new("BlurEffect")
	blurEffect.Name = "AvatarChangerBlur"
	blurEffect.Size = 0
	blurEffect.Parent = Lighting
end

-- ============================================
-- FUNGSI MANAJEMEN GUI EKSTERNAL
-- ============================================
local function toggleExternalGui(isOpening)
	for _, guiName in ipairs(EXTERNAL_GUIS) do
		local extGui = playerGui:FindFirstChild(guiName)
		if extGui then
			local mainContainer = extGui:FindFirstChildWhichIsA("CanvasGroup")

			if isOpening then
				externalGuiStates[guiName] = extGui.Enabled 
				if externalGuiStates[guiName] then
					if mainContainer then
						local tween = TweenService:Create(mainContainer, TWEEN_INFO, {GroupTransparency = 1})
						tween:Play()
						tween.Completed:Connect(function()
							if main.Visible then extGui.Enabled = false end
						end)
					else
						extGui.Enabled = false 
					end
				end
			else
				if externalGuiStates[guiName] then
					extGui.Enabled = true
					if mainContainer then
						TweenService:Create(mainContainer, TWEEN_INFO, {GroupTransparency = 0}):Play()
					end
				end
			end
		end
	end
end

-- ============================================
-- LOGIC & TWEENS
-- ============================================
local currentMainTab = "AVATARS"
local currentCategory = "Boys"
local selected = nil
local selectedAccessory = nil
local navButtons = {}
local catButtons = {}
local equippedAccessories = {}

local function tween(obj, props, time)
	TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad), props):Play()
end

-- Clear Preview
local function clearPreview()
	if rotationConnection then rotationConnection:Disconnect(); rotationConnection = nil end
	if previewCharacter then previewCharacter:Destroy(); previewCharacter = nil end
	worldModel:ClearAllChildren()
end

-- Load Preview
local function loadPreviewCharacter(userId)
	clearPreview()
	selectedName.Text = "Loading..."
	task.spawn(function()
		local success, character = pcall(function() return Players:CreateHumanoidModelFromUserId(userId) end)
		if success and character then
			character.Parent = worldModel
			previewCharacter = character

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local descSuccess, description = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
				if descSuccess and description then pcall(function() humanoid:ApplyDescription(description) end) end
			end

			task.wait(0.5)
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Anchored = true
				hrp.CFrame = CFrame.new(0, 0, 0) 

				local charSize = character:GetExtentsSize()
				local focusHeight = charSize.Y * 0.1 
				local distance = charSize.Y * 1.15 

				camera.CFrame = CFrame.new(
					Vector3.new(0, focusHeight, distance), 
					Vector3.new(0, focusHeight, 0)
				)

				local angle = 0
				rotationConnection = RunService.RenderStepped:Connect(function(dt)
					if previewCharacter and previewCharacter.Parent and hrp then
						angle = angle + (dt * 40)
						hrp.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(angle), 0)
					else
						if rotationConnection then rotationConnection:Disconnect(); rotationConnection = nil end
					end
				end)
				selectedName.Text = "Preview Ready"
			end
		else
			selectedName.Text = "Failed to load"
		end
	end)
end

-- Create Item Cards
local function createCard(data, isAvatar)
	local card = Instance.new("TextButton", gridScroll)
	card.BackgroundColor3 = THEME.CardBG
	card.Text = ""
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", card)
	stroke.Color = THEME.TextMuted
	stroke.Transparency = 0.8

	local img = Instance.new("ImageLabel", card)
	img.Size = UDim2.new(1, -10, 0, 60)
	img.Position = UDim2.new(0, 5, 0, 5)
	img.BackgroundTransparency = 1
	img.ScaleType = isAvatar and Enum.ScaleType.Crop or Enum.ScaleType.Fit
	Instance.new("UICorner", img).CornerRadius = UDim.new(0, 6)

	if isAvatar then
		img.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. data.id .. "&width=150&height=150&format=png"
	else
		img.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		task.spawn(function()
			local success, result = pcall(function() return "https://www.roblox.com/asset-thumbnail/image?assetId=" .. data.id .. "&width=150&height=150&format=png" end)
			if success then img.Image = result end
		end)
	end

	local name = Instance.new("TextLabel", card)
	name.Size = UDim2.new(1, -10, 0, 20)
	name.Position = UDim2.new(0, 5, 0, 70)
	name.BackgroundTransparency = 1
	name.Text = data.name
	name.Font = FONT_GLOBAL
	name.TextColor3 = THEME.TextMuted
	name.TextSize = 10
	name.TextTruncate = Enum.TextTruncate.AtEnd

	local equippedIndicator
	if not isAvatar then
		equippedIndicator = Instance.new("TextLabel", card)
		equippedIndicator.Size = UDim2.new(1, -10, 0, 14)
		equippedIndicator.Position = UDim2.new(0, 5, 0, 5)
		equippedIndicator.BackgroundColor3 = THEME.Success
		equippedIndicator.Text = "✓ EQUIPPED"
		equippedIndicator.TextColor3 = THEME.MainBG
		equippedIndicator.Font = Enum.Font.MontserratBold
		equippedIndicator.TextSize = 9
		Instance.new("UICorner", equippedIndicator).CornerRadius = UDim.new(0, 4)
		equippedIndicator.Visible = equippedAccessories[data.id] or false
		equippedIndicator.ZIndex = 2
	end

	card.MouseEnter:Connect(function()
		local isSelected = (isAvatar and selected == data) or (not isAvatar and selectedAccessory == data)
		if not isSelected then
			tween(card, {BackgroundColor3 = THEME.CardHover})
			tween(stroke, {Transparency = 0.4})
		end
	end)

	card.MouseLeave:Connect(function()
		local isSelected = (isAvatar and selected == data) or (not isAvatar and selectedAccessory == data)
		if not isSelected then
			tween(card, {BackgroundColor3 = THEME.CardBG})
			tween(stroke, {Transparency = 0.8})
		end
	end)

	card.MouseButton1Click:Connect(function()
		for _, c in pairs(gridScroll:GetChildren()) do
			if c:IsA("TextButton") then
				tween(c, {BackgroundColor3 = THEME.CardBG})
				c.UIStroke.Transparency = 0.8
				c.TextLabel.TextColor3 = THEME.TextMuted
			end
		end

		tween(card, {BackgroundColor3 = THEME.Accent})
		stroke.Transparency = 0
		name.TextColor3 = THEME.MainBG
		selectedName.Text = data.name

		if isAvatar then
			selected = data
			selectedAccessory = nil
			loadPreviewCharacter(data.id)
			actionBtn.Text = "USE AVATAR"
			tween(actionBtn, {BackgroundColor3 = THEME.Accent})
		else
			selectedAccessory = data
			selected = nil
			if equippedAccessories[data.id] then
				actionBtn.Text = "REMOVE ITEM"
				tween(actionBtn, {BackgroundColor3 = THEME.Danger})
			else
				actionBtn.Text = "EQUIP ITEM"
				tween(actionBtn, {BackgroundColor3 = THEME.Accent})
			end
		end
	end)
end

-- Sidebar Navigation
local function createNav(name, text, order, isActive)
	local btn = Instance.new("TextButton", navContainer)
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

	navButtons[text] = btn

	btn.MouseEnter:Connect(function()
		if currentMainTab ~= text then tween(btn, {BackgroundTransparency = 0.8}) end
	end)
	btn.MouseLeave:Connect(function()
		if currentMainTab ~= text then tween(btn, {BackgroundTransparency = 1}) end
	end)

	btn.MouseButton1Click:Connect(function()
		currentMainTab = text
		for n, b in pairs(navButtons) do
			if n == text then
				tween(b, {BackgroundTransparency = 0, TextColor3 = THEME.MainBG})
			else
				tween(b, {BackgroundTransparency = 1, TextColor3 = THEME.TextMain})
			end
		end

		for _, c in pairs(gridScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		clearPreview()
		selectedName.Text = "Select an item"
		actionBtn.Text = "EQUIP"

		if text == "AVATARS" then
			categoryTabs.Visible = true
			for _, data in ipairs(AVATARS[currentCategory]) do createCard(data, true) end
		else
			categoryTabs.Visible = false
			for _, data in ipairs(ACCESSORIES) do createCard(data, false) end
		end
		gridScroll.CanvasSize = UDim2.new(0, 0, 0, uiGrid.AbsoluteContentSize.Y + 20)
	end)
end

createNav("AvatarsNav", "AVATARS", 1, true)
createNav("ItemsNav", "ITEMS", 2, false)

-- Category Navigation (Boys/Girls)
local function createCat(name)
	local btn = Instance.new("TextButton", categoryTabs)
	btn.Size = UDim2.new(0, 60, 0, 30)
	btn.BackgroundColor3 = THEME.CardBG
	btn.Text = name
	btn.Font = FONT_GLOBAL
	btn.TextSize = 11
	btn.TextColor3 = (name == "Boys" and THEME.Accent or THEME.TextMuted)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	catButtons[name] = btn

	btn.MouseEnter:Connect(function()
		if currentCategory ~= name then tween(btn, {BackgroundColor3 = THEME.CardHover}) end
	end)
	btn.MouseLeave:Connect(function()
		if currentCategory ~= name then tween(btn, {BackgroundColor3 = THEME.CardBG}) end
	end)

	btn.MouseButton1Click:Connect(function()
		currentCategory = name
		for n, b in pairs(catButtons) do
			if n == name then
				tween(b, {TextColor3 = THEME.Accent, BackgroundColor3 = THEME.CardBG})
			else
				tween(b, {TextColor3 = THEME.TextMuted, BackgroundColor3 = THEME.CardBG})
			end
		end

		for _, c in pairs(gridScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for _, data in ipairs(AVATARS[name]) do createCard(data, true) end
		gridScroll.CanvasSize = UDim2.new(0, 0, 0, uiGrid.AbsoluteContentSize.Y + 20)
	end)
end

createCat("Boys")
createCat("Girls")

uiGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	gridScroll.CanvasSize = UDim2.new(0, 0, 0, uiGrid.AbsoluteContentSize.Y + 20)
end)

-- Default Load
for _, data in ipairs(AVATARS["Boys"]) do createCard(data, true) end

-- ============================================
-- MASTER TOGGLE UI (Menggabungkan Logika Buka/Tutup)
-- ============================================
local function toggleUI(visible)
	if visible then
		overlay.Visible = true
		TweenService:Create(blurEffect, TWEEN_INFO, {Size = 15}):Play()
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)

		toggleExternalGui(true)
		main.Visible = true
	else
		TweenService:Create(blurEffect, TWEEN_INFO, {Size = 0}):Play()
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)

		toggleExternalGui(false)
		main.Visible = false
		task.wait(0.2)
		overlay.Visible = false
		clearPreview()
	end
end

-- Action Button Logic & Hover
actionBtn.MouseButton1Click:Connect(function()
	if currentMainTab == "AVATARS" and selected then
		changeAvatarEvent:FireServer(selected.id)
		actionBtn.Text = "SUCCESS!"
		tween(actionBtn, {BackgroundColor3 = THEME.Success})
		task.wait(1)
		toggleUI(false)
		actionBtn.Text = "USE AVATAR"
		tween(actionBtn, {BackgroundColor3 = THEME.Accent})
	elseif currentMainTab == "ITEMS" and selectedAccessory then
		if equippedAccessories[selectedAccessory.id] then
			removeAccessoryEvent:FireServer(selectedAccessory.id)
			equippedAccessories[selectedAccessory.id] = nil
			actionBtn.Text = "EQUIP ITEM"
			tween(actionBtn, {BackgroundColor3 = THEME.Accent})
		else
			addAccessoryEvent:FireServer(selectedAccessory.id)
			equippedAccessories[selectedAccessory.id] = true
			actionBtn.Text = "REMOVE ITEM"
			tween(actionBtn, {BackgroundColor3 = THEME.Danger})
		end
		for _, c in pairs(gridScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for _, data in ipairs(ACCESSORIES) do createCard(data, false) end
		gridScroll.CanvasSize = UDim2.new(0, 0, 0, uiGrid.AbsoluteContentSize.Y + 20)
	end
end)

actionBtn.MouseEnter:Connect(function() tween(actionBtn, {BackgroundTransparency = 0.15}) end)
actionBtn.MouseLeave:Connect(function() tween(actionBtn, {BackgroundTransparency = 0}) end)

-- Reset Button Logic & Hover
resetBtn.MouseButton1Click:Connect(function()
	resetAvatarEvent:FireServer()
	equippedAccessories = {}
	selected = nil
	selectedAccessory = nil
	clearPreview()
	selectedName.Text = "Avatar Reset!"
	task.wait(1)
	selectedName.Text = "Select an item"
end)

resetBtn.MouseEnter:Connect(function() tween(resetBtn, {BackgroundColor3 = THEME.CardHover, TextColor3 = THEME.TextMain}) end)
resetBtn.MouseLeave:Connect(function() tween(resetBtn, {BackgroundColor3 = THEME.CardBG, TextColor3 = THEME.TextMuted}) end)

-- Topbar Integration & Modal Logic
task.spawn(function()
	if KariTopbar then
		local avatarButton = KariTopbar.new("124581140465120")

		avatarButton:Bind(
			function()
				toggleUI(true)
			end,
			function()
				toggleUI(false)
			end
		)

		main:GetPropertyChangedSignal("Visible"):Connect(function() 
			if not main.Visible then 
				pcall(function() avatarButton:Deselect() end) 
			end 
		end)
	else
		warn("[ALTITUDE WARNING] Modul KariTopbar tidak ditemukan di ReplicatedStorage!")
	end
end)

-- Close Button Logic & Hover
closeBtnAction.MouseEnter:Connect(function() tween(closeBg, {BackgroundColor3 = THEME.Danger}) end)
closeBtnAction.MouseLeave:Connect(function() tween(closeBg, {BackgroundColor3 = THEME.Accent}) end)

closeBtnAction.MouseButton1Click:Connect(function()
	toggleUI(false)
end)