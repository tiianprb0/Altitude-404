--[[
    ALTITUDE PROFILE CONTROLLER V2.9 (LIVE AVATAR & NAME FETCHING)
    Tempatkan di: StarterPlayer > StarterPlayerScripts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local pGui = player:WaitForChild("PlayerGui")
local screenGui = pGui:WaitForChild("AltitudeProfileUI", 30)
if not screenGui then return end

local main = screenGui:WaitForChild("MainFrame")
local visualBg = main:WaitForChild("VisualBg")
local mainScroll = visualBg:WaitForChild("MainScroll")

local headerContainer = mainScroll:WaitForChild("HeaderContainer")
local infoContainer = headerContainer:WaitForChild("InfoContainer")
local roleTitleLabel = infoContainer:WaitForChild("RoleTitleLabel")
local summitTitleLabel = infoContainer:WaitForChild("SummitTitleLabel")
local itemsContainer = mainScroll:WaitForChild("ItemsContainer")
local templateCard = screenGui:WaitForChild("ItemTemplate")

local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
main.GroupTransparency = 1
main.Visible = false

local uiBlur = Lighting:FindFirstChild("ShopBlur")
if not uiBlur then
	uiBlur = Instance.new("BlurEffect")
	uiBlur.Name = "ShopBlur"
	uiBlur.Size = 0 
	uiBlur.Parent = Lighting
end

local currentToggleIndex = 0

local function toggleUI(visible)
	currentToggleIndex = currentToggleIndex + 1
	local thisToggleIndex = currentToggleIndex

	if visible then
		main.Visible = true
		TweenService:Create(main, TWEEN_INFO, {GroupTransparency = 0}):Play()
		TweenService:Create(uiBlur, TWEEN_INFO, {Size = 20}):Play()
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
	else
		TweenService:Create(main, TWEEN_INFO, {GroupTransparency = 1}):Play()
		TweenService:Create(uiBlur, TWEEN_INFO, {Size = 0}):Play()
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
		task.delay(TWEEN_INFO.Time, function()
			if currentToggleIndex == thisToggleIndex then
				main.Visible = false
			end
		end)
	end
end

local profileButton
task.spawn(function()
	local KariTopbar = require(ReplicatedStorage:WaitForChild("KariTopbar", 15))
	if KariTopbar then
		profileButton = KariTopbar.new("12000216664") 
		profileButton:Bind(
			function() toggleUI(true) end,
			function() toggleUI(false) end
		)
	end
end)

main.CloseBtn.XButton.MouseButton1Click:Connect(function()
	if profileButton then
		pcall(function() profileButton:Deselect() end)
		pcall(function() profileButton:ResetState() end)
	else
		toggleUI(false)
	end
end)

-- [KARINA ADD] INISIALISASI PROFIL PLAYER (Wajah & Nama Asli)
task.spawn(function()
	-- Set Nama
	local nameLabel = infoContainer:FindFirstChild("NameLabel")
	if nameLabel then
		nameLabel.Text = player.DisplayName or player.Name
	end

	-- Set Avatar Thumbnail
	local avatarImg = headerContainer:FindFirstChild("AvatarImage", true)
	if avatarImg then
		local success, content, isReady = pcall(function()
			-- Meminta gambar wajah (HeadShot) dengan resolusi tinggi dari server Roblox
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		if success and isReady then
			avatarImg.Image = content
		end
	end
end)


-- LOGIKA HIDE AURA (Menyembunyikan Distraksi Partikel Pemain Lain)
local isHideAuraActive = false
local hideAuraToggleButton = nil

local function ApplyHideAura()
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local theirAura = otherPlayer.Character:FindFirstChild("ActiveCosmeticAura")
			if theirAura then
				for _, part in pairs(theirAura:GetDescendants()) do
					if part:IsA("ParticleEmitter") or part:IsA("Beam") or part:IsA("Trail") then
						part.Enabled = not isHideAuraActive
					elseif part:IsA("PointLight") or part:IsA("SurfaceLight") then
						part.Enabled = not isHideAuraActive
					end
				end
			end
		end
	end
end

RunService.RenderStepped:Connect(function()
	if isHideAuraActive then ApplyHideAura() end
end)

local function BuildHideAuraToggleButton()
	if not player:GetAttribute("HasHideAura") then return end
	if not hideAuraToggleButton then
		hideAuraToggleButton = infoContainer:FindFirstChild("HideAuraToggleButton")
		if not hideAuraToggleButton then return end

		hideAuraToggleButton.MouseButton1Click:Connect(function()
			isHideAuraActive = not isHideAuraActive
			if isHideAuraActive then
				hideAuraToggleButton.Text = "👁️ Hide Aura: ON"
				hideAuraToggleButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
			else
				hideAuraToggleButton.Text = "👁️ Hide Aura: OFF"
				hideAuraToggleButton.BackgroundColor3 = Color3.fromRGB(40, 75, 125) 
				ApplyHideAura() 
			end
		end)
	end
	hideAuraToggleButton.Visible = true
end

-- PEMBARUAN ANGKA KOIN & SUMMITS SECARA LIVE
local function UpdateStatsUI()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local statsContainer = infoContainer:FindFirstChild("StatsContainer")

	local summitsVal = leaderstats:FindFirstChild("Summits")
	if summitsVal then
		local count = summitsVal.Value
		local rank, color
		if count < 20 then rank, color = "Snuggly Camper", Color3.fromRGB(222, 235, 255)
		elseif count < 50 then rank, color = "Marshmallow Hiker", Color3.fromRGB(255, 182, 193)
		elseif count < 75 then rank, color = "Cotton Candy Climber", Color3.fromRGB(245, 210, 255)
		elseif count < 100 then rank, color = "Starlight Trekker", Color3.fromRGB(255, 244, 180)
		elseif count < 150 then rank, color = "Moonlight Explorer", Color3.fromRGB(180, 240, 255)
		elseif count < 200 then rank, color = "Sunrise Guardian", Color3.fromRGB(255, 200, 150)
		elseif count < 250 then rank, color = "Galaxy Dreamer", Color3.fromRGB(210, 190, 255)
		else rank, color = "Aurora Legend", Color3.fromRGB(255, 223, 128) end

		summitTitleLabel.Text = rank
		summitTitleLabel.TextColor3 = color

		if statsContainer then
			local sStat = statsContainer:FindFirstChild("SummitsStat")
			if sStat and sStat:FindFirstChild("ValueLabel") then
				sStat.ValueLabel.Text = tostring(count)
			end
		end
	end

	local coinsVal = leaderstats:FindFirstChild("Coins")
	if coinsVal and statsContainer then
		local cStat = statsContainer:FindFirstChild("CoinsStat")
		if cStat and cStat:FindFirstChild("ValueLabel") then
			cStat.ValueLabel.Text = tostring(coinsVal.Value)
		end
	end
end

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local summitsVal = leaderstats:WaitForChild("Summits", 5)
		if summitsVal then summitsVal.Changed:Connect(UpdateStatsUI) end

		local coinsVal = leaderstats:WaitForChild("Coins", 5)
		if coinsVal then coinsVal.Changed:Connect(UpdateStatsUI) end

		UpdateStatsUI() 
	end
end)

local function UpdateRoleTitle()
	local giftFolder = player:FindFirstChild("GiftTitle")
	if giftFolder then
		local typeVal = giftFolder:FindFirstChild("Type")
		local textVal = giftFolder:FindFirstChild("Text")
		local colorVal = giftFolder:FindFirstChild("Color")
		local titleStr = ""
		if textVal and textVal.Value ~= "" then titleStr = textVal.Value
		elseif typeVal and typeVal.Value ~= "" then titleStr = typeVal.Value end

		if titleStr ~= "" then
			roleTitleLabel.Text = titleStr
			if colorVal then roleTitleLabel.TextColor3 = colorVal.Value end
			roleTitleLabel.Visible = true
		else roleTitleLabel.Visible = false end
	else roleTitleLabel.Visible = false end
end

local function SetupTitleListener(folder)
	UpdateRoleTitle()
	folder.ChildAdded:Connect(UpdateRoleTitle)
	for _, child in pairs(folder:GetChildren()) do
		if child:IsA("ValueBase") then child.Changed:Connect(UpdateRoleTitle) end
	end
end

player.ChildAdded:Connect(function(child)
	if child.Name == "GiftTitle" then SetupTitleListener(child) end
end)
local existingFolder = player:FindFirstChild("GiftTitle")
if existingFolder then SetupTitleListener(existingFolder) end


-- DATABASE MURNI TANPA KEBUTUHAN GAMBAR (NO ICONS)
local LOADOUT_METADATA = {
	["A_GF"] = {Name = "God of Light", Type = "Aura", AttributeName = "HasGodoflight", ID = "Godoflight"},
	["A_BL"] = {Name = "Blossom Aura", Type = "Aura", AttributeName = "HasBlossom", ID = "Blossom"},
	["A_GL"] = {Name = "Glitch Aura", Type = "Aura", AttributeName = "HasGlitch", ID = "Glitch"},
	["A_RA"] = {Name = "Rare Aura", Type = "Aura", AttributeName = "HasRare", ID = "Rare"},
	["A_RI"] = {Name = "Rich Aura", Type = "Aura", AttributeName = "HasRich", ID = "Rich"},
	["A_SM"] = {Name = "Sword Master", Type = "Aura", AttributeName = "HasSwordMaster", ID = "SwordMaster"},

	["A_CH"] = {Name = "Chained Aura", Type = "Aura", AttributeName = "HasChained", ID = "Chained"},
	["A_CO"] = {Name = "Cosmic Aura", Type = "Aura", AttributeName = "HasCosmic", ID = "Cosmic"},
	["A_CU"] = {Name = "Cubic Aura", Type = "Aura", AttributeName = "HasCubic", ID = "Cubic"},
	["A_DS"] = {Name = "Dual Swords", Type = "Aura", AttributeName = "HasDualSwords", ID = "DualSwords"},
	["A_FR"] = {Name = "Frost Aura", Type = "Aura", AttributeName = "HasFrost", ID = "Frost"},
	["A_LO"] = {Name = "Love Aura", Type = "Aura", AttributeName = "HasLove", ID = "Love"},
	["A_PO"] = {Name = "Poison Aura", Type = "Aura", AttributeName = "HasPoison", ID = "Poison"},
	["A_PL"] = {Name = "Powerless", Type = "Aura", AttributeName = "HasPowerless", ID = "Powerless"},
	["A_SD"] = {Name = "Sand Demon", Type = "Aura", AttributeName = "HasSandDemon", ID = "SandDemon"},
	["A_SN"] = {Name = "Sound Ninja", Type = "Aura", AttributeName = "HasSoundNinja", ID = "SoundNinja"},
	["A_TG"] = {Name = "Thunder God", Type = "Aura", AttributeName = "HasThunderGod", ID = "ThunderGod"},
}

local loadoutButtons = {} 

local function BuildLoadout()
	for _, child in pairs(itemsContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	table.clear(loadoutButtons)

	for id, data in pairs(LOADOUT_METADATA) do
		if player:GetAttribute(data.AttributeName) == true then
			local card = templateCard:Clone()
			card.Name = data.ID

			local itemName = card:FindFirstChild("ItemName")
			if itemName then itemName.Text = data.Name end

			card.Visible = true
			card.Parent = itemsContainer

			local equipBtn = card:FindFirstChild("EquipButton")
			local statusLbl = card:FindFirstChild("StatusLabel")

			if equipBtn and statusLbl then
				loadoutButtons[data.ID] = {Button = equipBtn, Status = statusLbl, Data = data}

				equipBtn.MouseButton1Click:Connect(function()
					local currentEquipped = player:GetAttribute("ActiveAura")
					local equipRemote = ReplicatedStorage:FindFirstChild("EquipRemote")

					if currentEquipped == data.ID then
						if equipRemote then equipRemote:FireServer("Aura", "") end
					else
						if equipRemote then equipRemote:FireServer("Aura", data.ID) end
					end

					toggleUI(false)
				end)
			end
		end
	end

	UpdateLoadoutButtons()
end

function UpdateLoadoutButtons()
	local activeAura = player:GetAttribute("ActiveAura")

	for id, elements in pairs(loadoutButtons) do
		local btn = elements.Button
		local status = elements.Status

		if activeAura == id then
			btn.Text = "UNEQUIP"
			btn.BackgroundColor3 = Color3.fromRGB(248, 113, 113) 
			status.Text = "Currently Equipped"
			status.TextColor3 = Color3.fromRGB(46, 204, 113) 
		else
			btn.Text = "EQUIP"
			btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
			status.Text = "Not Equipped"
			status.TextColor3 = Color3.fromRGB(175, 195, 225) 
		end
	end
end

player.AttributeChanged:Connect(function(attributeName)
	if attributeName == "ActiveAura" then
		UpdateLoadoutButtons()
	elseif string.sub(attributeName, 1, 3) == "Has" then
		BuildLoadout()
		BuildHideAuraToggleButton()
	end
end)

task.spawn(function()
	repeat task.wait(0.5) until player:GetAttribute("DataLoaded") == true
	BuildLoadout()
	BuildHideAuraToggleButton()
end)