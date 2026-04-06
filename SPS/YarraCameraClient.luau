local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local cameraTween = nil

local cameraEvent = ReplicatedStorage:WaitForChild("YarraCameraEvent", 10)

-- TEMA WARNA & IKON DARI CINEMATIC
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
local CLOSE_ICON = "rbxassetid://11293981586"

local function ShowRentalGUI(accessData)
	local pGui = player:WaitForChild("PlayerGui")
	if pGui:FindFirstChild("YarraRentalGUI") then pGui.YarraRentalGUI:Destroy() end

	-- 1. Sembunyikan Hotbar
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)

	-- 2. Buat Efek Blur
	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = Lighting
	TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Size = 15}):Play()

	-- 3. Bangun GUI
	local sg = Instance.new("ScreenGui")
	sg.Name = "YarraRentalGUI"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true

	local bgDim = Instance.new("Frame")
	bgDim.Size = UDim2.new(1, 0, 1, 0)
	bgDim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bgDim.BackgroundTransparency = 1
	bgDim.BorderSizePixel = 0
	bgDim.Parent = sg
	TweenService:Create(bgDim, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()

	local main = Instance.new("Frame")
	main.Name = "MainPanel"
	main.Size = UDim2.new(0.65, 0, 0.7, 0) 
	main.Position = UDim2.new(0.5, 0, 1.5, 0) 
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BackgroundColor3 = THEME.MainBG
	main.BorderSizePixel = 0
	main.Parent = sg

	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(500, 480) 
	constraint.Parent = main
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

	local function closeGUI()
		TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
		TweenService:Create(bgDim, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()

		local blurTween = TweenService:Create(blur, TweenInfo.new(0.4), {Size = 0})
		blurTween:Play()

		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)

		task.wait(0.4)
		blur:Destroy()
		sg:Destroy()
		cameraEvent:FireServer("EndSession") 
	end

	local closeBg = Instance.new("Frame")
	closeBg.Name = "CloseBtn"
	closeBg.Size = UDim2.new(0, 32, 0, 32)
	closeBg.Position = UDim2.new(1, -5, 0, -5) 
	closeBg.AnchorPoint = Vector2.new(0.5, 0.5)
	closeBg.BackgroundColor3 = THEME.Accent
	closeBg.ZIndex = 5000 
	closeBg.Rotation = 45 
	closeBg.Parent = main
	Instance.new("UICorner", closeBg).CornerRadius = UDim.new(0, 8)

	local closeBtnAction = Instance.new("TextButton")
	closeBtnAction.Size = UDim2.new(1, 0, 1, 0)
	closeBtnAction.BackgroundTransparency = 1
	closeBtnAction.Text = ""
	closeBtnAction.ZIndex = 5001 
	closeBtnAction.Modal = true 
	closeBtnAction.Parent = closeBg

	local closeIcon = Instance.new("ImageLabel")
	closeIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
	closeIcon.Position = UDim2.new(0.25, 0, 0.25, 0)
	closeIcon.Image = CLOSE_ICON
	closeIcon.ImageColor3 = THEME.MainBG
	closeIcon.BackgroundTransparency = 1
	closeIcon.Rotation = -45
	closeIcon.ZIndex = 5000
	closeIcon.Parent = closeBg

	closeBtnAction.MouseButton1Click:Connect(closeGUI)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "YARRA RENTALS"
	title.TextColor3 = THEME.TextMain
	title.Font = Enum.Font.Montserrat
	title.TextSize = 20
	title.Parent = main

	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(0.85, 0, 0, 2)
	sep.Position = UDim2.new(0.075, 0, 0, 45)
	sep.BackgroundColor3 = THEME.SidebarBG
	sep.BorderSizePixel = 0
	sep.Parent = main

	local listContainer = Instance.new("ScrollingFrame")
	listContainer.Size = UDim2.new(1, -30, 1, -70)
	listContainer.Position = UDim2.new(0, 15, 0, 60)
	listContainer.BackgroundTransparency = 1
	listContainer.ScrollBarThickness = 4
	listContainer.ScrollBarImageColor3 = THEME.Accent
	listContainer.Parent = main

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = listContainer

	-- [KARINA] Tabel Opsi Diperbarui. JetGroup dihapus.
	local options = {
		{Name = "Boat", RequiredAttribute = nil, ImageId = "rbxassetid://1234567890", Desc = "Kapal kayu biasa, gratis digunakan."}, 
		{Name = "JetSolo", RequiredAttribute = "HasJetSolo", ImageId = "rbxassetid://1234567890", Desc = "Jetski cepat. Eksklusif untuk VIP atau beli di Shop."}
	}

	for _, opt in ipairs(options) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -10, 0, 95)
		card.BackgroundColor3 = THEME.CardBG
		card.Parent = listContainer
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

		local imgBg = Instance.new("Frame")
		imgBg.Size = UDim2.new(0, 65, 0, 65)
		imgBg.Position = UDim2.new(0, 10, 0.5, -32.5)
		imgBg.BackgroundColor3 = THEME.SidebarBG
		imgBg.Parent = card
		Instance.new("UICorner", imgBg).CornerRadius = UDim.new(0, 8)

		local img = Instance.new("ImageLabel")
		img.Size = UDim2.new(1, -10, 1, -10)
		img.Position = UDim2.new(0, 5, 0, 5)
		img.BackgroundTransparency = 1
		img.Image = opt.ImageId
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = imgBg

		local textFrame = Instance.new("Frame")
		textFrame.Size = UDim2.new(1, -200, 1, -10)
		textFrame.Position = UDim2.new(0, 85, 0, 5)
		textFrame.BackgroundTransparency = 1
		textFrame.Parent = card

		local nameTxt = Instance.new("TextLabel")
		nameTxt.Size = UDim2.new(1, 0, 0, 20)
		nameTxt.Position = UDim2.new(0, 0, 0, 5)
		nameTxt.BackgroundTransparency = 1
		nameTxt.Text = string.upper(opt.Name)
		nameTxt.TextColor3 = THEME.TextMain
		nameTxt.Font = Enum.Font.Montserrat
		nameTxt.TextSize = 15
		nameTxt.TextXAlignment = Enum.TextXAlignment.Left
		nameTxt.Parent = textFrame

		local descTxt = Instance.new("TextLabel")
		descTxt.Size = UDim2.new(1, 0, 0, 30)
		descTxt.Position = UDim2.new(0, 0, 0, 25)
		descTxt.BackgroundTransparency = 1
		descTxt.Text = opt.Desc
		descTxt.TextColor3 = THEME.TextMuted
		descTxt.Font = Enum.Font.Montserrat
		descTxt.TextSize = 11
		descTxt.TextWrapped = true 
		descTxt.TextXAlignment = Enum.TextXAlignment.Left
		descTxt.TextYAlignment = Enum.TextYAlignment.Top
		descTxt.Parent = textFrame

		-- Cek Kondisi Akses
		local canSpawn = true
		if opt.RequiredAttribute and not accessData[opt.RequiredAttribute] then
			canSpawn = false
		end

		local statusTxt = Instance.new("TextLabel")
		statusTxt.Size = UDim2.new(1, 0, 0, 20)
		statusTxt.Position = UDim2.new(0, 0, 0, 55)
		statusTxt.BackgroundTransparency = 1
		statusTxt.Text = canSpawn and "FREE ACCESS" or "BUY IN SHOP"
		statusTxt.TextColor3 = canSpawn and THEME.RobuxColor or THEME.Warning
		statusTxt.Font = Enum.Font.Montserrat
		statusTxt.TextSize = 10
		statusTxt.TextXAlignment = Enum.TextXAlignment.Left
		statusTxt.Parent = textFrame

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 80, 0, 32)
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, -10, 0.5, 0)
		btn.Font = Enum.Font.Montserrat
		btn.TextSize = 11
		btn.Modal = true

		if canSpawn then
			btn.Text = "SPAWN"
			btn.BackgroundColor3 = THEME.Accent
			btn.TextColor3 = THEME.MainBG
		else
			btn.Text = "LOCKED"
			btn.BackgroundColor3 = THEME.SidebarBG
			btn.TextColor3 = THEME.TextMuted
		end

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.Parent = card

		btn.MouseButton1Click:Connect(function()
			if canSpawn then
				cameraEvent:FireServer("SpawnVehicle", opt.Name)
				closeGUI()
			end
		end)
	end

	listContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 15)
	sg.Parent = pGui

	TweenService:Create(main, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.58, 0)}):Play()
end

if cameraEvent then
	-- [KARINA] Menangkap accessData yang dikirimkan server
	cameraEvent.OnClientEvent:Connect(function(action, data1, data2)
		if action == "StartPOV" and data1 then 
			local character = player.Character
			if not character or not character:FindFirstChild("Head") then return end
			local playerHead = character.Head

			camera.CameraType = Enum.CameraType.Scriptable
			local targetCFrame = CFrame.lookAt(playerHead.Position + (playerHead.CFrame.LookVector * 1.5), data1.Position)
			cameraTween = TweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = targetCFrame})
			cameraTween:Play()

		elseif action == "EndPOVAndShowGUI" then
			if cameraTween then cameraTween:Cancel() end
			camera.CameraType = Enum.CameraType.Custom
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				camera.CameraSubject = player.Character.Humanoid
			end
			-- data1 di sini adalah tabel `accessData`
			ShowRentalGUI(data1) 
		end
	end)
end