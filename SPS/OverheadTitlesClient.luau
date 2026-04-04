--[[
    OVERHEAD TITLES CLIENT V6 (KARINA SETTINGS & VANISH INTEGRATED)
    - Memory Leak Fixed.
    - CPU Render Fixed & Terhubung dengan Settings Hide Overhead.
    - [NEW] Sinkronisasi dengan sistem Vanish (Client-Sided bypass).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

-- ID Icons
local VERIFIED_ICON_ID = "rbxassetid://72206613131435"
local PREMIUM_ICON_ID = "rbxassetid://11400262106" 
local VIP_ICON_ID = "rbxassetid://82258159627738" 

-- Konfigurasi Jarak & Scaling
local CONFIG = {
	MinDist = 10,      
	MaxDist = 40,      
	MinScale = 0.85,   
	MaxScale = 1.1,    
	MinYOffset = 2.5,  
	MaxYOffset = 6.0,  
}

local ROLE_BG_COLOR = Color3.fromRGB(16, 44, 87)

local HARDCODED_ROLES = {
	Owner = true, 
	Developer = true, 
	Admin = true, 
	Moderator = true
}

local activeOverheads = {}

local function mapFont(name)
	if name == "Cartoony" then return Enum.Font.Cartoon
	elseif name == "SourceSansBold" then return Enum.Font.SourceSansBold
	elseif name == "GothamBold" then return Enum.Font.GothamBold
	elseif name == "Gotham" then return Enum.Font.Gotham
	else return Enum.Font.GothamBold end
end

local function cleanupOverhead(player)
	if activeOverheads[player] then
		for _, conn in ipairs(activeOverheads[player].connections) do
			if conn.Connected then conn:Disconnect() end
		end
		activeOverheads[player] = nil
	end
end

local function createOverhead(character, targetPlayer)
	if not character or not targetPlayer then return end

	local head = character:WaitForChild("Head", 5)
	if not head then return end

	cleanupOverhead(targetPlayer)

	if head:FindFirstChild("OverheadBillboard") then 
		head.OverheadBillboard:Destroy() 
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	local charConnections = {}

	-- ===== BILLBOARD UTAMA =====
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadBillboard"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 300, 0, 135) 
	billboard.StudsOffset = Vector3.new(0, CONFIG.MinYOffset, 0)
	billboard.AlwaysOnTop = false 
	billboard.MaxDistance = CONFIG.MaxDist + 10 

	-- [KARINA] Sinkronisasi awal dengan Atribut HideOverhead (Settings) & IsVanished (Admin)
	local isSettingHidden = localPlayer:GetAttribute("HideOverhead") == true
	local isVanished = targetPlayer:GetAttribute("IsVanished") == true
	billboard.Enabled = not (isSettingHidden or isVanished)

	billboard.Parent = head

	local root = Instance.new("Frame")
	root.Name = "Container"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundTransparency = 1
	root.Parent = billboard

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2) 
	list.Parent = root

	-- ===== 1. ROLE / GIFT TITLE =====
	local roleFrame = Instance.new("Frame")
	roleFrame.Name = "1_RoleFrame"
	roleFrame.Size = UDim2.new(0, 0, 0, 28) 
	roleFrame.AutomaticSize = Enum.AutomaticSize.X
	roleFrame.BackgroundColor3 = ROLE_BG_COLOR 
	roleFrame.BackgroundTransparency = 0.25 
	roleFrame.LayoutOrder = 1
	roleFrame.Visible = false
	roleFrame.BorderSizePixel = 0
	roleFrame.Parent = root

	Instance.new("UICorner", roleFrame).CornerRadius = UDim.new(1, 0)

	local rfGrad = Instance.new("UIGradient")
	rfGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 1),
		NumberSequenceKeypoint.new(0.45, 0), 
		NumberSequenceKeypoint.new(0.55, 0), 
		NumberSequenceKeypoint.new(1.0, 1)
	})
	rfGrad.Parent = roleFrame

	local roleList = Instance.new("UIListLayout")
	roleList.FillDirection = Enum.FillDirection.Horizontal
	roleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	roleList.VerticalAlignment = Enum.VerticalAlignment.Center
	roleList.Padding = UDim.new(0, 5) 
	roleList.Parent = roleFrame

	local rfPad = Instance.new("UIPadding")
	rfPad.PaddingLeft = UDim.new(0, 20) 
	rfPad.PaddingRight = UDim.new(0, 20)
	rfPad.PaddingTop = UDim.new(0, 2)
	rfPad.PaddingBottom = UDim.new(0, 2)
	rfPad.Parent = roleFrame

	local roleIcon = Instance.new("ImageLabel")
	roleIcon.Name = "Icon"
	roleIcon.Size = UDim2.new(0, 16, 0, 16) 
	roleIcon.BackgroundTransparency = 1
	roleIcon.Parent = roleFrame

	local roleLabel = Instance.new("TextLabel")
	roleLabel.Name = "Text"
	roleLabel.Size = UDim2.new(0, 0, 1, 0)
	roleLabel.AutomaticSize = Enum.AutomaticSize.X
	roleLabel.BackgroundTransparency = 1
	roleLabel.TextColor3 = Color3.new(1, 1, 1)
	roleLabel.TextSize = 14 
	roleLabel.Font = Enum.Font.GothamBold
	roleLabel.Text = "Role"
	roleLabel.Parent = roleFrame

	-- ===== 2. SUMMIT TITLE =====
	local summitLabel = Instance.new("TextLabel")
	summitLabel.Name = "2_SummitLabel"
	summitLabel.Size = UDim2.new(1, 0, 0, 16) 
	summitLabel.BackgroundTransparency = 1
	summitLabel.TextColor3 = Color3.fromRGB(222, 235, 255)
	summitLabel.TextStrokeTransparency = 0.6
	summitLabel.TextScaled = true
	summitLabel.Font = Enum.Font.GothamBold
	summitLabel.TextSize = 12 
	summitLabel.Text = "Loading..."
	summitLabel.LayoutOrder = 2
	summitLabel.Parent = root

	-- ===== 3. NAMA PLAYER CONTAINER =====
	local nameWrapper = Instance.new("Frame")
	nameWrapper.Name = "3_NameWrapper"
	nameWrapper.Size = UDim2.new(1, 0, 0, 22) 
	nameWrapper.BackgroundTransparency = 1
	nameWrapper.LayoutOrder = 3
	nameWrapper.Parent = root

	local nameList = Instance.new("UIListLayout")
	nameList.FillDirection = Enum.FillDirection.Horizontal
	nameList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	nameList.VerticalAlignment = Enum.VerticalAlignment.Center
	nameList.Padding = UDim.new(0, 4) 
	nameList.SortOrder = Enum.SortOrder.LayoutOrder
	nameList.Parent = nameWrapper

	-- 3A. Premium Icon
	local premiumIcon = Instance.new("ImageLabel")
	premiumIcon.Name = "PremiumIcon"
	premiumIcon.Size = UDim2.new(0, 16, 0, 16) 
	premiumIcon.BackgroundTransparency = 1
	premiumIcon.Image = PREMIUM_ICON_ID
	premiumIcon.LayoutOrder = 0
	premiumIcon.Visible = (targetPlayer.MembershipType == Enum.MembershipType.Premium)
	premiumIcon.Parent = nameWrapper

	-- 3B. VIP Icon
	local vipIcon = Instance.new("ImageLabel")
	vipIcon.Name = "VipIcon"
	vipIcon.Size = UDim2.new(0, 20, 0, 16) 
	vipIcon.BackgroundTransparency = 1
	vipIcon.Image = VIP_ICON_ID
	vipIcon.LayoutOrder = 1
	vipIcon.Visible = false 
	vipIcon.Parent = nameWrapper

	-- 3C. Nama Player
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0, 0, 1, 0) 
	nameLabel.AutomaticSize = Enum.AutomaticSize.X
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = targetPlayer.DisplayName 
	nameLabel.LayoutOrder = 2
	nameLabel.Parent = nameWrapper

	-- 3D. Verified Icon
	local verifiedIcon = Instance.new("ImageLabel")
	verifiedIcon.Name = "VerifiedIcon"
	verifiedIcon.Size = UDim2.new(0, 16, 0, 16) 
	verifiedIcon.BackgroundTransparency = 1
	verifiedIcon.Image = VERIFIED_ICON_ID
	verifiedIcon.LayoutOrder = 3
	verifiedIcon.Visible = false 
	verifiedIcon.Parent = nameWrapper

	------------------------------------------------
	-- UPDATE DATA
	------------------------------------------------
	local summitsVal = targetPlayer:WaitForChild("Summits", 5)
	local function updateSummit()
		local count = summitsVal and summitsVal.Value or 0
		local rank, color

		if count < 20 then rank, color = "Snuggly Camper", Color3.fromRGB(222, 235, 255)
		elseif count < 50 then rank, color = "Marshmallow Hiker", Color3.fromRGB(255, 182, 193)
		elseif count < 75 then rank, color = "Cotton Candy Climber", Color3.fromRGB(245, 210, 255)
		elseif count < 100 then rank, color = "Starlight Trekker", Color3.fromRGB(255, 244, 180)
		elseif count < 150 then rank, color = "Moonlight Explorer", Color3.fromRGB(180, 240, 255)
		elseif count < 200 then rank, color = "Sunrise Guardian", Color3.fromRGB(255, 200, 150)
		elseif count < 250 then rank, color = "Galaxy Dreamer", Color3.fromRGB(210, 190, 255)
		else rank, color = "Aurora Legend", Color3.fromRGB(255, 223, 128) end

		summitLabel.Text = string.format("%s | %d Summit", rank, count)
		summitLabel.TextColor3 = color
	end

	if summitsVal then
		table.insert(charConnections, summitsVal.Changed:Connect(updateSummit))
		updateSummit()
	end

	local giftFolder = targetPlayer:WaitForChild("GiftTitle", 5)
	local function updateGift()
		if not giftFolder then 
			roleFrame.Visible = false; verifiedIcon.Visible = false; vipIcon.Visible = false; return 
		end

		local typeVal = giftFolder:FindFirstChild("Type")
		local textVal = giftFolder:FindFirstChild("Text")
		local colorVal = giftFolder:FindFirstChild("Color")
		local fontVal = giftFolder:FindFirstChild("Font")
		local iconVal = giftFolder:FindFirstChild("Icon")

		if not (typeVal and typeVal.Value ~= "") then
			roleFrame.Visible = false; verifiedIcon.Visible = false; vipIcon.Visible = false; return
		end

		roleFrame.Visible = true
		local text = (textVal and textVal.Value ~= "") and textVal.Value or typeVal.Value
		roleLabel.Text = text
		roleLabel.Font = mapFont(fontVal and fontVal.Value or "GothamBold")
		roleLabel.TextColor3 = colorVal and colorVal.Value or Color3.new(1,1,1)

		local img = iconVal and iconVal.Value or ""
		if img ~= "" then
			if not string.find(img, "rbxassetid://") and not string.find(img, "rbxthumb://") then 
				img = "rbxassetid://" .. tostring(img) 
			end
			roleIcon.Image = img
			roleIcon.Visible = true
		else
			roleIcon.Visible = false
		end

		local currentType = typeVal.Value
		local baseRole = targetPlayer:GetAttribute("BaseRole")
		local isElite = HARDCODED_ROLES[currentType] or (baseRole and HARDCODED_ROLES[baseRole])

		if isElite then
			verifiedIcon.Visible = true; vipIcon.Visible = true 
		else
			verifiedIcon.Visible = false; vipIcon.Visible = (targetPlayer:GetAttribute("HasVIP") == true)
		end
	end

	table.insert(charConnections, targetPlayer:GetAttributeChangedSignal("HasVIP"):Connect(function()
		if giftFolder then
			local typeVal = giftFolder:FindFirstChild("Type")
			local baseRole = targetPlayer:GetAttribute("BaseRole")
			if (typeVal and HARDCODED_ROLES[typeVal.Value]) or (baseRole and HARDCODED_ROLES[baseRole]) then return end
		end
		vipIcon.Visible = (targetPlayer:GetAttribute("HasVIP") == true)
	end))

	-- [KARINA] Listener Reaktif untuk Vanish target secara spesifik
	table.insert(charConnections, targetPlayer:GetAttributeChangedSignal("IsVanished"):Connect(function()
		local isS_Hidden = localPlayer:GetAttribute("HideOverhead") == true
		local isV_Hidden = targetPlayer:GetAttribute("IsVanished") == true
		billboard.Enabled = not (isS_Hidden or isV_Hidden)
	end))

	local function setupGiftListener(folder)
		table.insert(charConnections, folder.ChildAdded:Connect(function() task.wait(0.1) updateGift() end))
		for _, c in ipairs(folder:GetChildren()) do
			if c:IsA("ValueBase") then 
				table.insert(charConnections, c.Changed:Connect(updateGift))
			end
		end
		updateGift()
	end

	if giftFolder then setupGiftListener(giftFolder)
	else
		task.spawn(function()
			giftFolder = targetPlayer:WaitForChild("GiftTitle", 5)
			if giftFolder then setupGiftListener(giftFolder) end
		end)
	end

	-- Daftarkan ke ActiveOverheads
	activeOverheads[targetPlayer] = {
		billboard = billboard,
		head = head,
		connections = charConnections
	}

	table.insert(charConnections, character.AncestryChanged:Connect(function(_, parent)
		if not parent then cleanupOverhead(targetPlayer) end
	end))
end

-- ===== MULTI-PLAYER HANDLER =====
local function onPlayerAdded(p)
	p.CharacterAdded:Connect(function(char)
		task.wait(0.5) 
		createOverhead(char, p)
	end)
	p.AncestryChanged:Connect(function(_, parent)
		if not parent then cleanupOverhead(p) end
	end)
	if p.Character then createOverhead(p.Character, p) end
end

for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)

------------------------------------------------
-- [KARINA] KONEKSI KE SYSTEM SETTINGS (HIDE OVERHEAD)
------------------------------------------------
local function updateVisibility()
	local isSettingHidden = localPlayer:GetAttribute("HideOverhead") == true
	for p, data in pairs(activeOverheads) do
		if data.billboard then
			local isV_Hidden = p:GetAttribute("IsVanished") == true
			data.billboard.Enabled = not (isSettingHidden or isV_Hidden)
		end
	end
end

-- Deteksi jika atribut HideOverhead berubah dari script Settings
localPlayer:GetAttributeChangedSignal("HideOverhead"):Connect(updateVisibility)

------------------------------------------------
-- RENDERSTEP UNIVERSAL (TEROPTIMASI)
------------------------------------------------
local baseSize = Vector2.new(300, 135)

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local camPos = cam.CFrame.Position

	if localPlayer:GetAttribute("HideOverhead") == true then return end

	for playerTarget, data in pairs(activeOverheads) do
		if data.head and data.billboard and data.head.Parent then

			-- [KARINA OPTIMASI] Jangan repot-repot ukur jarak & zoom jika pemain target sedang Vanish
			if playerTarget:GetAttribute("IsVanished") == true then continue end

			local dist = (camPos - data.head.Position).Magnitude
			local t = math.clamp((dist - CONFIG.MinDist) / (CONFIG.MaxDist - CONFIG.MinDist), 0, 1)

			local currentScale = CONFIG.MaxScale + (CONFIG.MinScale - CONFIG.MaxScale) * t
			data.billboard.Size = UDim2.new(0, baseSize.X * currentScale, 0, baseSize.Y * currentScale)

			local currentYOffset = CONFIG.MinYOffset + (CONFIG.MaxYOffset - CONFIG.MinYOffset) * t
			data.billboard.StudsOffset = Vector3.new(0, currentYOffset, 0)
		else
			cleanupOverhead(playerTarget)
		end
	end
end)

-- SISTEM PEMANTAUAN OVERHEAD MANDIRI
task.spawn(function()
	while task.wait(2) do
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("Head") then
				if not activeOverheads[p] or activeOverheads[p].head ~= p.Character.Head then
					createOverhead(p.Character, p)
				end
			end
		end
	end
end)