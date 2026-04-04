--[[
    KARINA - UI CONTROLLER V63 (REACTIVE ADMIN LISTENER & CLEAN FLY UI)
    Letak: Di dalam AdminPanelGUI atau StarterPlayerScripts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local THEME = {
	Accent = Color3.fromRGB(247, 173, 175),
	SidebarBG = Color3.fromRGB(20, 45, 85),
	CardBG = Color3.fromRGB(40, 75, 125),
	DarkerBG = Color3.fromRGB(15, 35, 65),
	FlyOn = Color3.fromRGB(167, 243, 208), 
	FlyOff = Color3.fromRGB(247, 173, 175),
	TextMain = Color3.fromRGB(255, 255, 255) 
}

local isMobile = UserInputService.TouchEnabled

local flyAnim = Instance.new("Animation")
flyAnim.AnimationId = "rbxassetid://98592107544485"
local currentFlyTrack = nil

local activeUIConnections = {}

local function SafeFire(remoteObj, ...)
	if player:GetAttribute("IsAdmin") == true then
		if remoteObj then remoteObj:FireServer(...) end
	else
		warn("[KARINA SECURITY] Percobaan eksekusi diblokir dari sisi Client. Otoritas ditolak.")
	end
end

local function ShowWelcomeToast()
	local toastGui = PlayerGui:FindFirstChild("KarinaWelcomeToast")
	if toastGui then toastGui:Destroy() end

	toastGui = Instance.new("ScreenGui")
	toastGui.Name = "KarinaWelcomeToast"
	toastGui.DisplayOrder = 1000 
	toastGui.Parent = PlayerGui

	local bg = Instance.new("Frame", toastGui)
	bg.Size = UDim2.new(0, 340, 0, 45)
	bg.AnchorPoint = Vector2.new(0.5, 0)
	bg.Position = UDim2.new(0.5, 0, 0, -60) 
	bg.BackgroundColor3 = THEME.SidebarBG
	bg.BorderSizePixel = 0
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", bg)
	stroke.Color = THEME.Accent
	stroke.Thickness = 1
	stroke.Transparency = 0.5

	local icon = Instance.new("TextLabel", bg)
	icon.Size = UDim2.new(0, 40, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "💡"
	icon.Font = Enum.Font.GothamMedium
	icon.TextSize = 18

	local desc = Instance.new("TextLabel", bg)
	desc.Size = UDim2.new(1, -50, 1, 0)
	desc.Position = UDim2.new(0, 40, 0, 0)
	desc.BackgroundTransparency = 1
	desc.Text = "Tekan [F] untuk membuka Admin Panel (5s)"
	desc.Font = Enum.Font.GothamMedium
	desc.TextColor3 = Color3.new(1, 1, 1)
	desc.TextScaled = true
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Center

	local tsc = Instance.new("UITextSizeConstraint", desc)
	tsc.MaxTextSize = 13
	tsc.MinTextSize = 9

	TweenService:Create(bg, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 60)}):Play()

	task.spawn(function()
		for i = 5, 1, -1 do
			if not toastGui.Parent then break end
			desc.Text = "Tekan [F] untuk membuka Admin Panel (" .. i .. "s)"
			task.wait(1)
		end

		if toastGui.Parent then
			local tOut = TweenService:Create(bg, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -60)})
			tOut:Play()
			tOut.Completed:Wait()
			toastGui:Destroy()
		end
	end)
end

local altitudeAdminEvent = ReplicatedStorage:WaitForChild("AltitudeAdminCore", 10)
local adminShopRequest = ReplicatedStorage:WaitForChild("AdminShopRequest", 10)
local giftTitleRequest = ReplicatedStorage:WaitForChild("GiftTitleRequest", 10)

local isInitialized = false
local currentHub, currentAdmin = nil, nil
local hiddenGuisCache = {}
local isScanning = false

local function setupMobileToggle()
	local existingToggle = PlayerGui:FindFirstChild("AdminToggleUI")
	if existingToggle then existingToggle:Destroy() end

	local toggleGui = Instance.new("ScreenGui", PlayerGui)
	toggleGui.Name = "AdminToggleUI"; toggleGui.ResetOnSpawn = false; toggleGui.IgnoreGuiInset = true

	local toggleBtn = Instance.new("TextButton", toggleGui)
	toggleBtn.Name = "ToggleBtn"
	toggleBtn.Size = UDim2.new(0, 38, 0, 38)
	toggleBtn.AnchorPoint = Vector2.new(1, 1) 
	toggleBtn.Position = UDim2.new(1, -140, 1, -25) 
	toggleBtn.BackgroundColor3 = THEME.SidebarBG
	toggleBtn.BackgroundTransparency = 0.2
	toggleBtn.Text = ""
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

	local icon = Instance.new("ImageLabel", toggleBtn)
	icon.Size = UDim2.new(0.55, 0, 0.55, 0)
	icon.Position = UDim2.new(0.225, 0, 0.225, 0)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://133410751840488"
	icon.ImageColor3 = Color3.new(1, 1, 1)

	toggleBtn.MouseButton1Click:Connect(function()
		if player:GetAttribute("IsAdmin") then
			local hub, admin = scanForAdminMenu()
			if hub and admin then
				if not hub.Visible and not admin.Visible then
					setMenuState(true, "Hub")
				else
					setMenuState(false)
				end
			end
		end
	end)
end

-- ========================================================
-- [KARINA FIX] REAKTIF ADMIN LISTENER
-- Menggantikan sistem pengecekan pasif untuk mengatasi Race Condition
-- ========================================================
local function HandleAdminSetup()
	local isAdmin = player:GetAttribute("IsAdmin")

	if isAdmin == true then
		if not isMobile then
			if not PlayerGui:FindFirstChild("KarinaWelcomeToast") and not isInitialized then
				task.spawn(ShowWelcomeToast)
			end
		else
			setupMobileToggle()
		end

		if not isScanning and not isInitialized then
			isScanning = true
			task.spawn(function()
				while task.wait(0.5) do 
					if not isInitialized and player:GetAttribute("IsAdmin") == true then 
						scanForAdminMenu() 
					else 
						isScanning = false
						break 
					end 
				end
			end)
		end
	elseif isAdmin == false then
		-- Jangan didestroy agar tidak hilang permanen, sembunyikan saja.
		local panel = PlayerGui:FindFirstChild("AdminPanelGUI")
		if panel then panel.Enabled = false end 

		local toggle = PlayerGui:FindFirstChild("AdminToggleUI")
		if toggle then toggle:Destroy() end

		isInitialized = false
		isScanning = false
		currentHub = nil
		currentAdmin = nil
	end
end

-- Listener Dinamis (Trigger setiap kali ada perubahan status dari Role Manager/Server)
player:GetAttributeChangedSignal("IsAdmin"):Connect(HandleAdminSetup)

-- Inisialisasi awal
if player:GetAttribute("IsAdmin") ~= nil then
	HandleAdminSetup()
end

local function ShowNotif(msg)
	local notifGui = PlayerGui:FindFirstChild("KarinaAdminNotif")
	if not notifGui then
		notifGui = Instance.new("ScreenGui")
		notifGui.Name = "KarinaAdminNotif"
		notifGui.DisplayOrder = 1000 
		notifGui.Parent = PlayerGui
	end

	local bg = Instance.new("Frame", notifGui)
	bg.Size = UDim2.new(0, 260, 0, 35)
	bg.AnchorPoint = Vector2.new(1, 1)
	bg.Position = UDim2.new(1, 300, 1, -20) 
	bg.BackgroundColor3 = THEME.SidebarBG
	bg.BorderSizePixel = 0
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

	local desc = Instance.new("TextLabel", bg)
	desc.Size = UDim2.new(1, -20, 1, 0)
	desc.Position = UDim2.new(0, 10, 0, 0)
	desc.BackgroundTransparency = 1
	desc.Text = "🛡️ " .. msg
	desc.Font = Enum.Font.GothamMedium
	desc.TextColor3 = Color3.new(1, 1, 1)
	desc.TextScaled = true
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Center

	local tsc = Instance.new("UITextSizeConstraint", desc)
	tsc.MaxTextSize = 12
	tsc.MinTextSize = 8

	TweenService:Create(bg, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 1, -20)}):Play()

	task.delay(3, function()
		if bg then
			local tOut = TweenService:Create(bg, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 350, 1, -20)})
			tOut:Play()
			tOut.Completed:Wait()
			bg:Destroy()
		end
	end)
end

local blurEffect = Lighting:FindFirstChild("AdminPanelBlur") or Instance.new("BlurEffect", Lighting)
blurEffect.Name = "AdminPanelBlur"; blurEffect.Size = 0

local state = {
	summitPlayer = nil, giftPlayer = nil, shopPlayer = nil, extraPlayer = nil, weatherPlayer = nil,
	giftRole = "Custom", giftFont = "Gotham", giftColor = Color3.fromRGB(255, 182, 193),
	shopItemId = nil, shopItemType = nil, shopItemName = nil,
	masterFlyEnabled = false, isFlying = false, selectedExtraCmd = nil,
	mobileUpHeld = false, mobileDownHeld = false,
	isSpectating = nil, 
	targetStates = {},
	originalCollisions = {}
}

-- ========================================================
-- [KARINA] REDESAIN MOBILE FLY UI (CLEAN FLAT DESIGN)
-- ========================================================
local function SetupMobileFlyUI()
	local gui = PlayerGui:FindFirstChild("KarinaMobileFly")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "KarinaMobileFly"
		gui.ResetOnSpawn = false
		gui.Parent = PlayerGui

		-- Tombol Toggle Terbang (Ditempatkan di atas area lompat)
		local flyBtn = Instance.new("TextButton", gui)
		flyBtn.Name = "FlyToggle"
		flyBtn.Size = UDim2.new(0, 48, 0, 48)
		flyBtn.AnchorPoint = Vector2.new(1, 1)
		flyBtn.Position = UDim2.new(1, -20, 1, -170)
		flyBtn.BackgroundColor3 = THEME.CardBG
		flyBtn.Text = "FLY\nOFF"
		flyBtn.Font = Enum.Font.GothamBold
		flyBtn.TextColor3 = Color3.new(1,1,1)
		flyBtn.TextSize = 10
		Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(1, 0)

		-- Tombol Naik (▲)
		local upBtn = Instance.new("TextButton", gui)
		upBtn.Name = "UpBtn"
		upBtn.Size = UDim2.new(0, 55, 0, 55)
		upBtn.AnchorPoint = Vector2.new(1, 1)
		upBtn.Position = UDim2.new(1, -20, 1, -95) 
		upBtn.BackgroundColor3 = THEME.SidebarBG
		upBtn.Text = "▲"
		upBtn.Font = Enum.Font.GothamBold
		upBtn.TextColor3 = THEME.FlyOn
		upBtn.TextSize = 20
		upBtn.Visible = false -- Disembunyikan saat sedang tidak terbang
		Instance.new("UICorner", upBtn).CornerRadius = UDim.new(1, 0)

		-- Tombol Turun (▼)
		local downBtn = Instance.new("TextButton", gui)
		downBtn.Name = "DownBtn"
		downBtn.Size = UDim2.new(0, 55, 0, 55)
		downBtn.AnchorPoint = Vector2.new(1, 1)
		downBtn.Position = UDim2.new(1, -20, 1, -25) 
		downBtn.BackgroundColor3 = THEME.SidebarBG
		downBtn.Text = "▼"
		downBtn.Font = Enum.Font.GothamBold
		downBtn.TextColor3 = THEME.FlyOff
		downBtn.TextSize = 20
		downBtn.Visible = false -- Disembunyikan saat sedang tidak terbang
		Instance.new("UICorner", downBtn).CornerRadius = UDim.new(1, 0)

		gui.Enabled = false
	end
	return gui
end

local mobileGui = SetupMobileFlyUI()

mobileGui.FlyToggle.MouseButton1Click:Connect(function()
	if workspace:FindFirstChild("Jail_" .. player.Name) then
		ShowNotif("❌ Terbang ditolak. Kamu sedang dipenjara.")
		return
	end
	state.isFlying = not state.isFlying
	UpdateActualFly()
end)

mobileGui.UpBtn.MouseButton1Down:Connect(function() state.mobileUpHeld = true end)
mobileGui.UpBtn.MouseButton1Up:Connect(function() state.mobileUpHeld = false end)
mobileGui.UpBtn.MouseLeave:Connect(function() state.mobileUpHeld = false end)

mobileGui.DownBtn.MouseButton1Down:Connect(function() state.mobileDownHeld = true end)
mobileGui.DownBtn.MouseButton1Up:Connect(function() state.mobileDownHeld = false end)
mobileGui.DownBtn.MouseLeave:Connect(function() state.mobileDownHeld = false end)

local flySpeed = 150 
local bg, bv
local currentFlyVel = Vector3.new(0,0,0)

local function canFly()
	if player:GetAttribute("GrantedFly") then return true end
	if player:GetAttribute("IsAdmin") and state.masterFlyEnabled then return true end
	return false
end

-- [KARINA] Helper UI Control untuk menyembunyikan tombol lompat bawaan Roblox
local function setRobloxJumpVisible(isVisible)
	local touchGui = PlayerGui:FindFirstChild("TouchGui")
	if touchGui then
		local jumpBtn = touchGui:FindFirstChild("JumpButton", true)
		if jumpBtn then 
			jumpBtn.Visible = isVisible 
		end
	end
end

function UpdateActualFly()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)

	if state.isFlying and canFly() then
		state.originalCollisions = {}
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				state.originalCollisions[part] = part.CanCollide
			end
		end

		bg = Instance.new("BodyGyro", hrp); bg.P = 9e4; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = hrp.CFrame
		bv = Instance.new("BodyVelocity", hrp); bv.Velocity = Vector3.new(0, 0, 0); bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		hum.PlatformStand = true

		if not currentFlyTrack then
			currentFlyTrack = animator:LoadAnimation(flyAnim)
			currentFlyTrack.Priority = Enum.AnimationPriority.Action
		end
		if not currentFlyTrack.IsPlaying then
			currentFlyTrack:Play()
		end

		-- [KARINA] Terapkan UI Replacement
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		setRobloxJumpVisible(false)
		if mobileGui then
			local uBtn = mobileGui:FindFirstChild("UpBtn")
			local dBtn = mobileGui:FindFirstChild("DownBtn")
			if uBtn then uBtn.Visible = true end
			if dBtn then dBtn.Visible = true end
		end
	else
		if bg then bg:Destroy(); bg = nil end
		if bv then bv:Destroy(); bv = nil end

		hum.PlatformStand = false

		for part, originalState in pairs(state.originalCollisions) do
			if part and part.Parent then
				part.CanCollide = originalState
			end
		end
		state.originalCollisions = {}

		hrp.CFrame = hrp.CFrame + Vector3.new(0, 1.5, 0)
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)

		if currentFlyTrack and currentFlyTrack.IsPlaying then
			currentFlyTrack:Stop()
		end

		-- [KARINA] Kembalikan Status UI Normal
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		setRobloxJumpVisible(true)
		if mobileGui then
			local uBtn = mobileGui:FindFirstChild("UpBtn")
			local dBtn = mobileGui:FindFirstChild("DownBtn")
			if uBtn then uBtn.Visible = false end
			if dBtn then dBtn.Visible = false end
		end
	end

	if mobileGui then
		local fBtn = mobileGui:FindFirstChild("FlyToggle")
		if fBtn then
			fBtn.Text = state.isFlying and "FLY\nON" or "FLY\nOFF"
			fBtn.BackgroundColor3 = state.isFlying and THEME.SidebarBG or THEME.CardBG
			fBtn.TextColor3 = state.isFlying and THEME.FlyOn or Color3.new(1, 1, 1)
		end
	end
end

player:GetAttributeChangedSignal("GrantedFly"):Connect(function()
	if player:GetAttribute("GrantedFly") then
		ShowNotif("Akses Terbang Diberikan! Tekan E / Spasi & Q.")
		if isMobile then mobileGui.Enabled = true end
	else
		state.isFlying = false
		UpdateActualFly()
		if not (player:GetAttribute("IsAdmin") and state.masterFlyEnabled) then
			mobileGui.Enabled = false
		end
	end
end)

local function toggleAdminPanelLogic()
	if not player:GetAttribute("IsAdmin") then return end
	local hub, admin = scanForAdminMenu()
	if hub and admin then
		if not hub.Visible and not admin.Visible then
			local content = admin:FindFirstChild("ContentContainer")
			if content then
				for _, page in ipairs(content:GetChildren()) do
					if page:IsA("Frame") then page.Visible = false end
				end
			end
			setMenuState(true, "Hub")
		else
			setMenuState(false)
		end
	else
		warn("[KARINA] ⚠️ Struktur AdminPanelGUI tidak ditemukan. Coba tunggu sebentar.")
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.E and canFly() then 
		if workspace:FindFirstChild("Jail_" .. player.Name) then
			ShowNotif("❌ Akses terbang ditolak! Kamu sedang dipenjara.")
			return
		end
		state.isFlying = not state.isFlying
		UpdateActualFly()
	end

	if input.KeyCode == Enum.KeyCode.F and player:GetAttribute("IsAdmin") then
		toggleAdminPanelLogic()
	end
end)

RunService.RenderStepped:Connect(function()
	if state.isFlying and bg and bv and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		if workspace:FindFirstChild("Jail_" .. player.Name) then
			state.isFlying = false
			UpdateActualFly()
			return
		end

		local char = player.Character
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")

		for _, part in ipairs(char:GetDescendants()) do 
			if part:IsA("BasePart") then 
				part.CanCollide = false 
			end 
		end

		local moveDir = Vector3.new(0,0,0)
		if hum and hum.MoveDirection.Magnitude > 0 then
			moveDir = hum.MoveDirection
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) or state.mobileUpHeld then moveDir = moveDir + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) or state.mobileDownHeld then moveDir = moveDir + Vector3.new(0, -1, 0) end

		local targetCFrame = CFrame.new(hrp.Position, hrp.Position + camera.CFrame.LookVector)
		bg.CFrame = bg.CFrame:Lerp(targetCFrame, 0.03)

		local targetVel = Vector3.new(0,0,0)
		if moveDir.Magnitude > 0 then targetVel = moveDir.Unit * flySpeed end

		currentFlyVel = currentFlyVel:Lerp(targetVel, 0.1) 
		bv.Velocity = currentFlyVel
	end

	if state.isSpectating then
		local targetPlr = Players:FindFirstChild(state.isSpectating)
		if not targetPlr or not targetPlr.Character or not targetPlr.Character:FindFirstChild("Humanoid") then
			camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid")
			state.isSpectating = nil
			ShowNotif("Target mati/hilang, Spectate dihentikan.")
		end
	end
end)

local function checkTargetIsProtectedOwner(targetName)
	local tPlr = Players:FindFirstChild(targetName)
	if not tPlr then return false end
	local tLvl = tPlr:GetAttribute("RankLevel") or 0
	local myLvl = player:GetAttribute("RankLevel") or 0

	if tLvl == 4 and myLvl < 4 then
		ShowNotif("❌ Akses Ditolak: Tidak bisa memodifikasi Owner.")
		return true
	end
	return false
end

function setMenuState(isVisible, targetView)
	if not isVisible then
		if currentHub then currentHub.Visible = false end
		if currentAdmin then currentAdmin.Visible = false end
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
		blurEffect.Size = 0

		for _, data in ipairs(hiddenGuisCache) do
			if data.gui and data.gui.Parent then
				data.gui.Enabled = data.wasEnabled
			end
		end
		hiddenGuisCache = {}
	else
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
		blurEffect.Size = 20

		if #hiddenGuisCache == 0 then
			for _, child in ipairs(PlayerGui:GetChildren()) do
				if child:IsA("ScreenGui") and child.Name ~= "AdminPanelGUI" and child.Name ~= "AdminToggleUI" and child.Name ~= "KarinaAdminNotif" and child.Name ~= "KarinaMobileFly" and child.Name ~= "KarinaWelcomeToast" and child.Name ~= "Chat" and child.Name ~= "Freecam" then
					table.insert(hiddenGuisCache, {gui = child, wasEnabled = child.Enabled})
					child.Enabled = false
				end
			end
		end

		if targetView == "Hub" then
			if currentAdmin then currentAdmin.Visible = false end
			if currentHub then currentHub.Visible = true end
		elseif targetView == "Admin" then
			if currentHub then currentHub.Visible = false end
			if currentAdmin then currentAdmin.Visible = true end
		end
	end
end

function initializeUI(hubMenu, adminMenu)
	for _, conn in ipairs(activeUIConnections) do if conn then conn:Disconnect() end end
	table.clear(activeUIConnections)

	local hubCloseBtn = hubMenu:FindFirstChild("CloseBtn", true)
	if hubCloseBtn then hubCloseBtn:FindFirstChild("Action").MouseButton1Click:Connect(function() setMenuState(false) end) end

	local greeting = hubMenu:FindFirstChild("GreetingLabel")
	if greeting then
		greeting.Text = "Hi, " .. string.upper(player.DisplayName) .. ",\nLagi mau ngapain hari ini?"
	end

	local btnContainer = hubMenu:FindFirstChild("BtnContainer")
	local btnSummit = btnContainer and btnContainer:FindFirstChild("BtnSummit")
	local btnGift = btnContainer and btnContainer:FindFirstChild("BtnGift")
	local btnAnnounce = btnContainer and btnContainer:FindFirstChild("BtnAnnounce")
	local btnShop = btnContainer and btnContainer:FindFirstChild("BtnShop")
	local btnFly = btnContainer and btnContainer:FindFirstChild("BtnFly")
	local btnExtra = btnContainer and btnContainer:FindFirstChild("BtnExtra")
	local btnActivity = btnContainer and btnContainer:FindFirstChild("BtnActivity")
	local btnWeather = btnContainer and btnContainer:FindFirstChild("BtnWeather")

	local adminCloseBtn = adminMenu:FindFirstChild("CloseBtn")
	if adminCloseBtn then adminCloseBtn:FindFirstChild("Action").MouseButton1Click:Connect(function() setMenuState(false) end) end

	local backBtn = adminMenu:FindFirstChild("BackBtn")
	local content = adminMenu:FindFirstChild("ContentContainer")
	local confirmModal = adminMenu:FindFirstChild("ConfirmModal")
	if not content or not backBtn then return end

	local pageSummit = content:FindFirstChild("Page_Summit")
	local pageGift = content:FindFirstChild("Page_Gift")
	local pageAnnounce = content:FindFirstChild("Page_Announce")
	local pageShop = content:FindFirstChild("Page_Shop")
	local pageExtra = content:FindFirstChild("Page_Extra")
	local pageActivity = content:FindFirstChild("Page_Activity") 
	local pageWeather = content:FindFirstChild("Page_Weather") 

	local function switchTab(menuName)
		if pageSummit then pageSummit.Visible = false end
		if pageGift then pageGift.Visible = false end
		if pageAnnounce then pageAnnounce.Visible = false end
		if pageShop then pageShop.Visible = false end
		if pageExtra then pageExtra.Visible = false end
		if pageActivity then pageActivity.Visible = false end
		if pageWeather then pageWeather.Visible = false end
		if confirmModal then confirmModal.Visible = false end

		if menuName == "Home" then
			setMenuState(true, "Hub")
		else
			setMenuState(true, "Admin")
			if menuName == "Summit" and pageSummit then pageSummit.Visible = true end
			if menuName == "Gift" and pageGift then pageGift.Visible = true end
			if menuName == "Announce" and pageAnnounce then pageAnnounce.Visible = true end
			if menuName == "Shop" and pageShop then pageShop.Visible = true end
			if menuName == "Extra" and pageExtra then pageExtra.Visible = true end
			if menuName == "Weather" and pageWeather then pageWeather.Visible = true end
			if menuName == "Activity" and pageActivity then 
				pageActivity.Visible = true 
				SafeFire(altitudeAdminEvent, "GetLogs")
			end
		end
	end

	backBtn.MouseButton1Click:Connect(function() switchTab("Home") end)
	if btnSummit then btnSummit.MouseButton1Click:Connect(function() switchTab("Summit") end) end
	if btnGift then btnGift.MouseButton1Click:Connect(function() switchTab("Gift") end) end
	if btnAnnounce then btnAnnounce.MouseButton1Click:Connect(function() switchTab("Announce") end) end
	if btnShop then btnShop.MouseButton1Click:Connect(function() switchTab("Shop") end) end
	if btnExtra then btnExtra.MouseButton1Click:Connect(function() switchTab("Extra") end) end
	if btnActivity then btnActivity.MouseButton1Click:Connect(function() switchTab("Activity") end) end
	if btnWeather then btnWeather.MouseButton1Click:Connect(function() switchTab("Weather") end) end

	if btnFly then
		btnFly.MouseButton1Click:Connect(function()
			state.masterFlyEnabled = not state.masterFlyEnabled
			if state.masterFlyEnabled then
				btnFly.BackgroundColor3 = THEME.FlyOn
				btnFly.Text = "FLY: ENABLED"
				if isMobile then mobileGui.Enabled = true end
			else
				btnFly.BackgroundColor3 = THEME.FlyOff
				btnFly.Text = "FLY: DISABLED"
				state.isFlying = false
				UpdateActualFly()
				if not player:GetAttribute("GrantedFly") then mobileGui.Enabled = false end
			end
		end)
	end

	switchTab("Home")
	setMenuState(false) 

	local function updatePlayerList(listContainer, searchBox, callback, listType)
		if not listContainer or not searchBox then return end
		local scrollFrame = listContainer:FindFirstChild(listType .. "List")
		if not scrollFrame then return end

		for _, child in ipairs(scrollFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

		local filter = string.lower(searchBox.Text)
		for _, p in ipairs(Players:GetPlayers()) do
			if filter == "" or string.find(string.lower(p.Name), filter) then
				local btn = Instance.new("TextButton", scrollFrame)
				btn.Name = p.Name; btn.Size = UDim2.new(1, -8, 0, 30); btn.BackgroundColor3 = THEME.SidebarBG
				btn.Text = "  " .. p.Name; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.Montserrat; btn.TextSize = 12; btn.TextXAlignment = Enum.TextXAlignment.Left
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

				table.insert(activeUIConnections, btn.MouseButton1Click:Connect(function()
					if state[string.lower(listType) .. "Player"] == p.Name then
						btn.BackgroundColor3 = THEME.SidebarBG
						callback(nil)
					else
						for _, b in ipairs(scrollFrame:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = THEME.SidebarBG end end
						btn.BackgroundColor3 = THEME.Accent
						callback(p.Name)
					end
				end))
			end
		end
	end

	local listAreaSummit = pageSummit and pageSummit:FindFirstChild("PlayerListArea")
	local listAreaGift = pageGift and pageGift:FindFirstChild("PlayerListArea")
	local listAreaShop = pageShop and pageShop:FindFirstChild("PlayerListArea")
	local listAreaExtra = pageExtra and pageExtra:FindFirstChild("PlayerListArea")
	local listAreaWeather = pageWeather and pageWeather:FindFirstChild("PlayerListArea")

	local searchSummit = listAreaSummit and listAreaSummit:FindFirstChild("SearchBox")
	local searchGift = listAreaGift and listAreaGift:FindFirstChild("SearchBox")
	local searchShop = listAreaShop and listAreaShop:FindFirstChild("SearchBox")
	local searchExtra = listAreaExtra and listAreaExtra:FindFirstChild("SearchBox")
	local searchWeather = listAreaWeather and listAreaWeather:FindFirstChild("SearchBox")

	local actionSummit = pageSummit and pageSummit:FindFirstChild("ActionArea")
	local actionGift = pageGift and pageGift:FindFirstChild("SettingsArea")
	local actionShop = pageShop and pageShop:FindFirstChild("SettingsArea")
	local actionExtra = pageExtra and pageExtra:FindFirstChild("SettingsArea")
	local actionWeather = pageWeather and pageWeather:FindFirstChild("SettingsArea")

	local labelSummit = actionSummit and actionSummit:FindFirstChild("SelectedLabel")
	local labelGift = actionGift and actionGift:FindFirstChild("SelectedLabel")
	local labelShop = actionShop and actionShop:FindFirstChild("SelectedLabel")
	local labelExtra = actionExtra and actionExtra:FindFirstChild("SelectedLabel")
	local labelWeather = actionWeather and actionWeather:FindFirstChild("SelectedLabel")

	local gridTargeted = actionExtra and actionExtra:FindFirstChild("TargetedGrid")
	local gridServer = actionExtra and actionExtra:FindFirstChild("ServerGrid")

	local extraInputGroup = actionExtra and actionExtra:FindFirstChild("InputGroup")
	local extraAmountInput = extraInputGroup and extraInputGroup:FindFirstChild("AmountInput")
	local extraTimeInput = extraInputGroup and extraInputGroup:FindFirstChild("TimeInput")
	local extraExecuteBtn = extraInputGroup and extraInputGroup:FindFirstChild("ExecuteBtn")

	local function getAllExtraButtons()
		local btns = {}
		if gridTargeted then
			for _, b in ipairs(gridTargeted:GetChildren()) do if b:IsA("TextButton") then table.insert(btns, b) end end
		end
		if gridServer then
			for _, b in ipairs(gridServer:GetChildren()) do if b:IsA("TextButton") then table.insert(btns, b) end end
		end
		return btns
	end

	local function updateExtraTexts()
		local pTarget = state.extraPlayer or player.Name 
		local pState = state.targetStates[pTarget] or {}

		local function setBtn(name, isToggled, txtOn, txtOff)
			local b = nil
			if gridTargeted and gridTargeted:FindFirstChild(name) then b = gridTargeted[name] end
			if not b and gridServer and gridServer:FindFirstChild(name) then b = gridServer[name] end

			if b then 
				b.Text = isToggled and txtOn or txtOff 
				if state.selectedExtraCmd ~= name then
					b.BackgroundColor3 = isToggled and THEME.DarkerBG or THEME.CardBG
				end
			end
		end

		setBtn("God", pState.God, "UN-GOD", "GOD MODE")
		setBtn("Jail", pState.Jail, "UNJAIL", "JAIL")
		setBtn("Freeze", pState.Freeze, "UNFREEZE", "FREEZE")
		setBtn("Rope", pState.Rope, "UNROPE", "ROPE")

		local isSpec = (state.isSpectating == pTarget)
		setBtn("Spectate", isSpec, "UN-SPECTATE", "SPECTATE")

		local tPlr = Players:FindFirstChild(pTarget)
		local isMorphed = false
		if tPlr then isMorphed = tPlr:GetAttribute("IsMorphed") == true end
		setBtn("Morph", isMorphed, "UNMORPH", "MORPH")
	end

	local function refreshAllLists()
		if listAreaSummit and searchSummit and labelSummit then
			updatePlayerList(listAreaSummit, searchSummit, function(name)
				state.summitPlayer = name; labelSummit.Text = "Pemain: " .. (name or "- (Diri Sendiri)")
			end, "Summit")
		end
		if listAreaGift and searchGift and labelGift then
			updatePlayerList(listAreaGift, searchGift, function(name)
				state.giftPlayer = name; labelGift.Text = "Pemain: " .. (name or "- (Diri Sendiri)"); labelGift.TextColor3 = state.giftColor 
			end, "Gift")
		end
		if listAreaShop and searchShop and labelShop then
			updatePlayerList(listAreaShop, searchShop, function(name)
				state.shopPlayer = name; labelShop.Text = "Pemain: " .. (name or "-") .. " | Item: " .. tostring(state.shopItemName or "-")
			end, "Shop")
		end
		if listAreaExtra and searchExtra and labelExtra then
			updatePlayerList(listAreaExtra, searchExtra, function(name)
				state.extraPlayer = name; labelExtra.Text = "Pemain: " .. (name or "- (Diri Sendiri)")
				updateExtraTexts() 
			end, "Extra")
		end
		if listAreaWeather and searchWeather and labelWeather then
			updatePlayerList(listAreaWeather, searchWeather, function(name)
				state.weatherPlayer = name; labelWeather.Text = "Pemain: " .. (name or "- (Diri Sendiri)")
			end, "Weather")
		end
	end

	table.insert(activeUIConnections, Players.PlayerAdded:Connect(refreshAllLists))
	table.insert(activeUIConnections, Players.PlayerRemoving:Connect(refreshAllLists))
	table.insert(activeUIConnections, Players.LocalPlayer:GetAttributeChangedSignal("IsMorphed"):Connect(updateExtraTexts))

	if searchSummit then table.insert(activeUIConnections, searchSummit:GetPropertyChangedSignal("Text"):Connect(refreshAllLists)) end
	if searchGift then table.insert(activeUIConnections, searchGift:GetPropertyChangedSignal("Text"):Connect(refreshAllLists)) end
	if searchShop then table.insert(activeUIConnections, searchShop:GetPropertyChangedSignal("Text"):Connect(refreshAllLists)) end
	if searchExtra then table.insert(activeUIConnections, searchExtra:GetPropertyChangedSignal("Text"):Connect(refreshAllLists)) end
	if searchWeather then table.insert(activeUIConnections, searchWeather:GetPropertyChangedSignal("Text"):Connect(refreshAllLists)) end
	refreshAllLists() 

	if actionSummit then
		local amountInput = actionSummit:FindFirstChild("AmountInput")
		local rowAddSub = actionSummit:FindFirstChild("RowAddSub")
		local btnAdd = rowAddSub and rowAddSub:FindFirstChild("BtnAdd")
		local btnSub = rowAddSub and rowAddSub:FindFirstChild("BtnSub")
		local btnReset = actionSummit:FindFirstChild("BtnReset")

		local function sendSummit(actionType)
			local tName = state.summitPlayer or player.Name
			if checkTargetIsProtectedOwner(tName) then return end 
			local amount = amountInput and tonumber(amountInput.Text) or 1
			SafeFire(altitudeAdminEvent, "Summit", actionType, tName, amount)
		end
		if btnAdd then table.insert(activeUIConnections, btnAdd.MouseButton1Click:Connect(function() sendSummit("add") end)) end
		if btnSub then table.insert(activeUIConnections, btnSub.MouseButton1Click:Connect(function() sendSummit("sub") end)) end
		if btnReset then table.insert(activeUIConnections, btnReset.MouseButton1Click:Connect(function() sendSummit("reset") end)) end
	end

	if actionGift then
		local roleGrid = actionGift:FindFirstChild("RoleSelect")
		local fontGrid = actionGift:FindFirstChild("FontSelect")
		local colorGrid = actionGift:FindFirstChild("ColorSelect")
		local customInput = actionGift:FindFirstChild("CustomTitleInput")
		local btnApply = actionGift:FindFirstChild("ApplyBtn")
		local btnClear = actionGift:FindFirstChild("ClearBtn")

		if roleGrid then
			for _, btn in ipairs(roleGrid:GetChildren()) do
				if btn:IsA("TextButton") then
					table.insert(activeUIConnections, btn.MouseButton1Click:Connect(function()
						for _, b in ipairs(roleGrid:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = THEME.CardBG end end
						btn.BackgroundColor3 = THEME.Accent; state.giftRole = btn.Name
					end))
				end
			end
		end
		if fontGrid then
			for _, btn in ipairs(fontGrid:GetChildren()) do
				if btn:IsA("TextButton") then
					table.insert(activeUIConnections, btn.MouseButton1Click:Connect(function()
						for _, b in ipairs(fontGrid:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = THEME.CardBG end end
						btn.BackgroundColor3 = THEME.Accent; state.giftFont = btn.Name
					end))
				end
			end
		end
		if colorGrid then
			for _, btn in ipairs(colorGrid:GetChildren()) do
				if btn:IsA("TextButton") then
					table.insert(activeUIConnections, btn.MouseButton1Click:Connect(function()
						for _, b in ipairs(colorGrid:GetChildren()) do
							if b:IsA("TextButton") then
								local stroke = b:FindFirstChild("ActiveStroke")
								if stroke then stroke:Destroy() end
							end
						end
						local stroke = Instance.new("UIStroke"); stroke.Name = "ActiveStroke"; stroke.Thickness = 2; stroke.Color = Color3.new(1,1,1); stroke.Parent = btn
						state.giftColor = btn.BackgroundColor3; if labelGift then labelGift.TextColor3 = state.giftColor end
					end))
				end
			end
		end

		if btnApply then
			table.insert(activeUIConnections, btnApply.MouseButton1Click:Connect(function()
				local tName = state.giftPlayer or player.Name
				if checkTargetIsProtectedOwner(tName) then return end 
				local txt = customInput and customInput.Text or ""
				local c = state.giftColor
				SafeFire(giftTitleRequest, "set", tName, state.giftRole, txt, {c.R * 255, c.G * 255, c.B * 255}, state.giftFont)
			end))
		end
		if btnClear then
			table.insert(activeUIConnections, btnClear.MouseButton1Click:Connect(function()
				local tName = state.giftPlayer or player.Name
				if checkTargetIsProtectedOwner(tName) then return end 
				SafeFire(giftTitleRequest, "clear", tName)
			end))
		end
	end

	if pageAnnounce then
		local annInput = pageAnnounce:FindFirstChild("AnnounceInput")
		local btnAreaC = pageAnnounce:FindFirstChild("ButtonArea")
		local btnServer = btnAreaC and btnAreaC:FindFirstChild("SendServer")
		local btnGlobal = btnAreaC and btnAreaC:FindFirstChild("SendGlobal")

		if annInput and btnServer and btnGlobal then
			local function sendAnnouncement(msgType)
				local text = annInput.Text
				if text == "" or text == " " then return end
				SafeFire(altitudeAdminEvent, "Announce", msgType, text)
				annInput.Text = ""
			end
			table.insert(activeUIConnections, btnServer.MouseButton1Click:Connect(function() sendAnnouncement("Server") end))
			table.insert(activeUIConnections, btnGlobal.MouseButton1Click:Connect(function() sendAnnouncement("Global") end))
		end
	end

	if actionShop then
		local amountInput = actionShop:FindFirstChild("AmountInput")
		local rowAddSub = actionShop:FindFirstChild("RowAddSub")
		local btnGive = rowAddSub and rowAddSub:FindFirstChild("BtnAdd")
		local btnTake = rowAddSub and rowAddSub:FindFirstChild("BtnSub")

		for _, frame in ipairs(actionShop:GetChildren()) do
			if string.find(frame.Name, "Grid_") then
				for _, btn in ipairs(frame:GetChildren()) do
					if btn:IsA("TextButton") then
						table.insert(activeUIConnections, btn.MouseButton1Click:Connect(function()
							for _, f in ipairs(actionShop:GetChildren()) do
								if string.find(f.Name, "Grid_") then
									for _, b in ipairs(f:GetChildren()) do 
										if b:IsA("TextButton") then b.BackgroundColor3 = THEME.CardBG end 
									end
								end
							end
							btn.BackgroundColor3 = THEME.Accent
							state.shopItemId = btn.Name
							state.shopItemType = btn:GetAttribute("ItemType")
							state.shopItemName = btn:GetAttribute("ItemName")

							if amountInput then amountInput.Visible = (state.shopItemType == "Currency") end
							local pName = state.shopPlayer or "-"
							if labelShop then labelShop.Text = "Pemain: " .. pName .. " | Item: " .. state.shopItemName end
						end))
					end
				end
			end
		end

		local function sendShopRequest(actionType)
			if not adminShopRequest then return end
			if not state.shopPlayer then ShowNotif("Pilih pemain terlebih dahulu!"); return end
			if checkTargetIsProtectedOwner(state.shopPlayer) then return end 
			if not state.shopItemId then ShowNotif("Pilih item dari daftar terlebih dahulu!"); return end

			local amount = 0
			if state.shopItemType == "Currency" then
				amount = amountInput and tonumber(amountInput.Text) or 0
				if amount <= 0 then ShowNotif("Masukkan jumlah koin yang valid!"); return end
			end
			SafeFire(adminShopRequest, actionType, state.shopPlayer, state.shopItemType, state.shopItemId, amount, state.shopItemName)
		end
		if btnGive then table.insert(activeUIConnections, btnGive.MouseButton1Click:Connect(function() sendShopRequest("Give") end)) end
		if btnTake then table.insert(activeUIConnections, btnTake.MouseButton1Click:Connect(function() sendShopRequest("Take") end)) end
	end

	if actionExtra then
		local requiresInput = {
			Speed = "Input Kecepatan (ex: 50)", Size = "Input Skala (ex: 2)", Morph = "Ketik Username (Kosongkan = Unmorph)",
			Kick = "Alasan Kick (Bisa dikosongkan)", Ban = "Alasan Ban (Bisa dikosongkan)", Shutdown = "Alasan Shutdown (Bisa dikosongkan)"
		}

		local requiresTargetCmds = {Kick = true, Ban = true, Spectate = true, Bring = true, Goto = true}
		local noTargetCmds = {Lock = true, Shutdown = true, Restart = true}

		local conYes, conNo 
		local currentSubmitConn

		local allBtns = getAllExtraButtons()
		for _, btn in ipairs(allBtns) do
			table.insert(activeUIConnections, btn.MouseButton1Click:Connect(function()
				local cmd = btn.Name
				state.selectedExtraCmd = cmd

				if not state.extraPlayer and requiresTargetCmds[cmd] then
					ShowNotif("❌ Pilih pemain di daftar kiri terlebih dahulu untuk " .. string.upper(cmd) .. "!")
					return
				end

				local targetName = state.extraPlayer or player.Name 

				if cmd ~= "Morph" and not noTargetCmds[cmd] and checkTargetIsProtectedOwner(targetName) then return end

				if cmd == "Spectate" then
					local targetPlr = Players:FindFirstChild(targetName)
					local targetHum = targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("Humanoid")

					if state.isSpectating == targetName then
						camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid")
						state.isSpectating = nil
						ShowNotif("Berhenti mengawasi " .. targetName)
					else
						if targetHum then
							camera.CameraSubject = targetHum
							state.isSpectating = targetName
							ShowNotif("Sedang mengawasi " .. targetName)
						else
							ShowNotif("❌ Karakter " .. targetName .. " tidak ditemukan.")
						end
					end
					updateExtraTexts()
					return 
				end

				for _, b in ipairs(allBtns) do b.BackgroundColor3 = THEME.CardBG end
				btn.BackgroundColor3 = THEME.Accent

				if requiresInput[cmd] and extraInputGroup and extraAmountInput and extraExecuteBtn then
					extraInputGroup.Visible = true
					extraAmountInput.PlaceholderText = requiresInput[cmd]

					if cmd == "Ban" and extraTimeInput then
						extraTimeInput.Visible = true
					elseif extraTimeInput then
						extraTimeInput.Visible = false
					end

					extraAmountInput.Text = ""
					if extraTimeInput then extraTimeInput.Text = "" end

					local submitText = "EKSEKUSI " .. string.upper(cmd)
					if cmd == "Morph" then
						local tPlr = Players:FindFirstChild(targetName)
						if tPlr and tPlr:GetAttribute("IsMorphed") then
							submitText = "EKSEKUSI UNMORPH"
						end
					end
					extraExecuteBtn.Text = submitText

					if currentSubmitConn then currentSubmitConn:Disconnect() end
					currentSubmitConn = extraExecuteBtn.MouseButton1Click:Connect(function()
						local val = extraAmountInput.Text
						local timeVal = (extraTimeInput and extraTimeInput.Visible) and extraTimeInput.Text or ""

						if (val == "" or val == " ") and (cmd ~= "Kick" and cmd ~= "Ban" and cmd ~= "Shutdown" and cmd ~= "Morph") then
							ShowNotif("⚠️ Kotak input wajib diisi untuk mengeksekusi " .. string.upper(cmd))
							return
						end

						SafeFire(altitudeAdminEvent, "Extra", cmd, targetName, val, timeVal)

						extraInputGroup.Visible = false
						if extraTimeInput then extraTimeInput.Visible = false end
						btn.BackgroundColor3 = THEME.CardBG
						currentSubmitConn:Disconnect()
					end)
					table.insert(activeUIConnections, currentSubmitConn)
					return
				else
					if extraInputGroup then extraInputGroup.Visible = false end
					if extraTimeInput then extraTimeInput.Visible = false end
				end

				if cmd == "Kick" or cmd == "Ban" or cmd == "Shutdown" or cmd == "Restart" then
					if confirmModal then
						local title = confirmModal:FindFirstChild("TitleMessage", true)
						local btnYes = confirmModal:FindFirstChild("BtnYes", true)
						local btnNo = confirmModal:FindFirstChild("BtnNo", true)

						if title then 
							if cmd == "Shutdown" then title.Text = "Yakin mau mematikan seluruh server?"
							elseif cmd == "Restart" then title.Text = "Yakin mau merestart server (Rejoin Otomatis)?"
							else title.Text = "Yakin mau " .. string.upper(cmd) .. " " .. targetName .. "?" end
						end
						confirmModal.Visible = true

						if conYes then conYes:Disconnect() end
						if conNo then conNo:Disconnect() end

						conYes = btnYes.MouseButton1Click:Connect(function()
							confirmModal.Visible = false
							conYes:Disconnect(); conNo:Disconnect()
							SafeFire(altitudeAdminEvent, "Extra", cmd, targetName, "", "")
						end)

						conNo = btnNo.MouseButton1Click:Connect(function()
							confirmModal.Visible = false
							conYes:Disconnect(); conNo:Disconnect()
							btn.BackgroundColor3 = THEME.CardBG
						end)
						table.insert(activeUIConnections, conYes)
						table.insert(activeUIConnections, conNo)
					end
					return
				end

				if cmd ~= "Lock" and cmd ~= "Shutdown" and cmd ~= "Restart" and cmd ~= "Morph" then
					local pState = state.targetStates[targetName] or {God = false, Jail = false, Freeze = false, Rope = false}
					if cmd == "God" or cmd == "Jail" or cmd == "Freeze" or cmd == "Rope" then
						pState[cmd] = not pState[cmd]
						state.targetStates[targetName] = pState
						updateExtraTexts()
					end
				end

				SafeFire(altitudeAdminEvent, "Extra", cmd, targetName, "", "")
			end))
		end
	end

	if actionWeather then
		local globalGrid = actionWeather:FindFirstChild("GlobalWeatherGrid")
		if globalGrid then
			for _, btn in ipairs(globalGrid:GetChildren()) do
				if btn:IsA("TextButton") then
					table.insert(activeUIConnections, btn.MouseButton1Click:Connect(function()
						SafeFire(altitudeAdminEvent, "Weather", "Global", btn.Name, "")
					end))
				end
			end
		end

		local lightningGrid = actionWeather:FindFirstChild("LightningGrid")
		if lightningGrid then
			for _, btn in ipairs(lightningGrid:GetChildren()) do
				if btn:IsA("TextButton") then
					table.insert(activeUIConnections, btn.MouseButton1Click:Connect(function()
						local tName = state.weatherPlayer or player.Name
						if checkTargetIsProtectedOwner(tName) then return end 
						SafeFire(altitudeAdminEvent, "Weather", "Target", btn.Name, tName)
					end))
				end
			end
		end
	end

	local function renderLogs(logData)
		if not pageActivity then return end
		local scroll = pageActivity:FindFirstChild("LogScroll")
		if not scroll then return end

		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end

		for i, log in ipairs(logData) do
			local item = Instance.new("Frame", scroll)
			item.Name = "Log_"..i 
			item.Size = UDim2.new(1, -10, 0, 30)
			item.BackgroundColor3 = THEME.CardBG
			item.LayoutOrder = i 
			Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)

			local tLbl = Instance.new("TextLabel", item)
			tLbl.Size = UDim2.new(0, 100, 1, 0)
			tLbl.Position = UDim2.new(0, 10, 0, 0)
			tLbl.BackgroundTransparency = 1
			tLbl.Text = log.TimeStr
			tLbl.TextColor3 = THEME.Accent
			tLbl.Font = Enum.Font.GothamBold
			tLbl.TextSize = 11
			tLbl.TextXAlignment = Enum.TextXAlignment.Left

			local dLbl = Instance.new("TextLabel", item)
			dLbl.Size = UDim2.new(1, -120, 1, 0)
			dLbl.Position = UDim2.new(0, 110, 0, 0)
			dLbl.BackgroundTransparency = 1
			dLbl.Text = "[" .. string.upper(log.Admin) .. "] " .. log.Action
			dLbl.TextColor3 = THEME.TextMain
			dLbl.Font = Enum.Font.Gotham
			dLbl.TextSize = 11
			dLbl.TextXAlignment = Enum.TextXAlignment.Left
			dLbl.TextWrapped = true
		end
	end

	if altitudeAdminEvent then
		table.insert(activeUIConnections, altitudeAdminEvent.OnClientEvent:Connect(function(action, arg1)
			if action == "UpdateLogs" then
				renderLogs(arg1)
			elseif action == "Notify" then
				ShowNotif(arg1)
			end
		end))
	end

	local btnRefreshLog = pageActivity and pageActivity:FindFirstChild("BtnRefreshLog", true)
	if btnRefreshLog then
		table.insert(activeUIConnections, btnRefreshLog.MouseButton1Click:Connect(function()
			SafeFire(altitudeAdminEvent, "GetLogs")
		end))
	end
end

function scanForAdminMenu()
	local panelGui = PlayerGui:FindFirstChild("AdminPanelGUI")
	local foundHub = panelGui and panelGui:FindFirstChild("HubMenu")
	local foundAdmin = panelGui and panelGui:FindFirstChild("AdminMenu")

	if foundHub and foundAdmin and (currentHub ~= foundHub or currentAdmin ~= foundAdmin) then
		isInitialized = false; currentHub = foundHub; currentAdmin = foundAdmin
	end

	if currentHub and currentAdmin and not isInitialized then
		task.delay(0.5, function() initializeUI(currentHub, currentAdmin) end)
		isInitialized = true
	end

	return currentHub, currentAdmin
end