--[[
    ALTITUDE CATALOG CONTROLLER V68 (REVISI KARINA)
    Tempatkan di: StarterPlayer > StarterPlayerScripts

    PERBAIKAN OLEH KARINA:
    1. PRE-CHECK OWNERSHIP: Mengecek kepemilikan lokal sebelum memunculkan Modal Konfirmasi.
    2. CHAT LISTENER: Menangkap pesan Gifting global dan memunculkannya via TextChatService.
    3. EXCHANGE LOGIC: Integrasi modal konfirmasi khusus untuk penukaran Summit.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")
local player = Players.LocalPlayer
local aurasFolder = ReplicatedStorage:WaitForChild("Auras")

local pGui = player:WaitForChild("PlayerGui")
local screenGui = pGui:WaitForChild("AltitudeCatalogUI", 30)
if not screenGui then return end

local main = screenGui:WaitForChild("MainFrame")
local visualBg = main:WaitForChild("VisualBg")
local giftModal = screenGui:WaitForChild("GiftModal")
local gmVisual = giftModal:WaitForChild("GmVisual")

-- Modal Konfirmasi Beli Normal
local confirmModal = screenGui:WaitForChild("ConfirmModal")
local cmVisual = confirmModal:WaitForChild("CmVisual")
local cmYesBtn = cmVisual:WaitForChild("YesBtn")
local cmNoBtn = cmVisual:WaitForChild("NoBtn")
local cmMsgLabel = cmVisual:WaitForChild("MsgLabel")
local pendingPurchaseID = nil

-- [KARINA] Modal Konfirmasi Exchange (Tukar Summit)
local exchangeModal = screenGui:WaitForChild("ExchangeModal", 10)
local exVisual = exchangeModal and exchangeModal:WaitForChild("CmVisual")
local exYesBtn = exVisual and exVisual:WaitForChild("YesBtn")
local exNoBtn = exVisual and exVisual:WaitForChild("NoBtn")
local exMsgLabel = exVisual and exVisual:WaitForChild("MsgLabel")

local playerList = gmVisual:WaitForChild("PlayerList")
local template = screenGui:WaitForChild("PlayerTemplate")
local emptyLabel = gmVisual:FindFirstChild("EmptyLabel") 
local sidebar = visualBg:WaitForChild("Sidebar")
local container = visualBg:WaitForChild("ContentContainer")

local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local EXTERNAL_GUIS = {"StatsGui", "CinematicGUI"} 
local externalGuiStates = {} 

local shopBlur = Lighting:FindFirstChild("ShopBlur")
if not shopBlur then
	shopBlur = Instance.new("BlurEffect")
	shopBlur.Name = "ShopBlur"
	shopBlur.Size = 0 
	shopBlur.Parent = Lighting
end

-- Fungsi Pemutar Audio Dinamis
local function PlayAudio(audioType)
	local soundId = ""
	if audioType == "BuyCoin" then
		soundId = "rbxassetid://87685313476669"
	elseif audioType == "BuyItem" then
		soundId = "rbxassetid://122766504688172"
	elseif audioType == "Redeem" then
		soundId = "rbxassetid://117570443671176"
	end

	if soundId ~= "" then
		local s = Instance.new("Sound")
		s.SoundId = soundId
		s.Volume = 1
		s.Parent = pGui
		s:Play()
		s.Ended:Connect(function() s:Destroy() end)
		task.delay(5, function() if s and s.Parent then s:Destroy() end end) 
	end
end

local function ShowGlobalNotification(message, isSuccess)
	local notif = Instance.new("TextLabel")
	notif.Name = "ShopNotification"
	notif.Size = UDim2.new(0, 320, 0, 50)
	notif.Position = UDim2.new(0.5, -160, 0.85, 0)
	notif.BackgroundColor3 = isSuccess and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(248, 113, 113)
	notif.TextColor3 = Color3.fromRGB(255, 255, 255)
	notif.Text = message
	notif.Font = Enum.Font.Montserrat
	notif.TextSize = 14
	notif.ZIndex = 10000
	notif.BackgroundTransparency = 1 
	notif.TextTransparency = 1 
	Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)
	notif.Parent = screenGui

	local slideIn = TweenService:Create(notif, TWEEN_INFO, {Position = UDim2.new(0.5, -160, 0.75, 0), TextTransparency = 0, BackgroundTransparency = 0})
	slideIn:Play()

	task.delay(3, function()
		local slideOut = TweenService:Create(notif, TWEEN_INFO, {Position = UDim2.new(0.5, -160, 0.85, 0), TextTransparency = 1, BackgroundTransparency = 1})
		slideOut:Play()
		slideOut.Completed:Connect(function() notif:Destroy() end)
	end)
end

-- PRE-CHECK LOGIC (Agar user tidak masuk funnel modal jika sudah punya)
local function ClientHasItem(actionType, itemName, attrName)
	if actionType == "Tool" then
		return (player:FindFirstChild("StarterGear") and player.StarterGear:FindFirstChild(itemName) ~= nil)
	elseif actionType == "Perk" and attrName then
		return player:GetAttribute(attrName) == true
	end
	return false
end

local function toggleExternalGui(isShopOpening)
	for _, guiName in ipairs(EXTERNAL_GUIS) do
		local extGui = pGui:FindFirstChild(guiName)
		if extGui then
			local mainContainer = extGui:FindFirstChildWhichIsA("CanvasGroup")
			if isShopOpening then
				externalGuiStates[guiName] = extGui.Enabled 
				if externalGuiStates[guiName] then
					if mainContainer then
						TweenService:Create(mainContainer, TWEEN_INFO, {GroupTransparency = 1}):Play()
						task.delay(TWEEN_INFO.Time, function() if main.Visible then extGui.Enabled = false end end)
					else extGui.Enabled = false end
				end
			else
				if externalGuiStates[guiName] then
					extGui.Enabled = true
					if mainContainer then TweenService:Create(mainContainer, TWEEN_INFO, {GroupTransparency = 0}):Play() end
				end
			end
		end
	end
end

local function closeGiftModal()
	TweenService:Create(giftModal, TWEEN_INFO, {GroupTransparency = 1}):Play()
	task.delay(TWEEN_INFO.Time, function()
		giftModal.Visible = false
		main.Visible = true
		TweenService:Create(main, TWEEN_INFO, {GroupTransparency = 0}):Play()
	end)
end

local function CloseConfirmModal()
	TweenService:Create(confirmModal, TWEEN_INFO, {GroupTransparency = 1}):Play()
	task.delay(TWEEN_INFO.Time, function()
		confirmModal.Visible = false
		main.Visible = true
		TweenService:Create(main, TWEEN_INFO, {GroupTransparency = 0}):Play()
	end)
	pendingPurchaseID = nil
end

local function OpenConfirmModal(itemID, itemName, itemPrice)
	pendingPurchaseID = itemID

	local formattedPrice = tostring(itemPrice)
	local k
	while true do
		formattedPrice, k = string.gsub(formattedPrice, "^(-?%d+)(%d%d%d)", '%1.%2')
		if k == 0 then break end
	end

	cmMsgLabel.Text = "Apakah kamu yakin ingin membeli\n<b>" .. itemName .. "</b>\nseharga " .. formattedPrice .. " Coins?"

	TweenService:Create(main, TWEEN_INFO, {GroupTransparency = 1}):Play()
	task.delay(TWEEN_INFO.Time, function() main.Visible = false end)

	confirmModal.Visible = true
	confirmModal.GroupTransparency = 1
	TweenService:Create(confirmModal, TWEEN_INFO, {GroupTransparency = 0}):Play()
end

-- [KARINA] Fungsi Penutup Modal Exchange
local function CloseExchangeModal()
	if not exchangeModal then return end
	TweenService:Create(exchangeModal, TWEEN_INFO, {GroupTransparency = 1}):Play()
	task.delay(TWEEN_INFO.Time, function()
		exchangeModal.Visible = false
		main.Visible = true
		TweenService:Create(main, TWEEN_INFO, {GroupTransparency = 0}):Play()
	end)
end

local function refreshPlayerList(itemID)
	local count = 0
	for _, v in pairs(playerList:GetChildren()) do
		if v:IsA("TextButton") then v:Destroy() end
	end
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer == player then continue end 
		count = count + 1
		local card = template:Clone()
		card.Name = otherPlayer.Name
		card.PName.Text = otherPlayer.DisplayName or otherPlayer.Name
		card.Visible = true
		card.Parent = playerList
		task.spawn(function()
			local content, isReady = Players:GetUserThumbnailAsync(otherPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			if isReady then card.Avatar.Image = content end
		end)
		card.MouseButton1Click:Connect(function()
			ReplicatedStorage.GiftRemote:FireServer(itemID, otherPlayer.Name)
			closeGiftModal()
		end)
	end
	if emptyLabel then emptyLabel.Visible = (count == 0) end
end

local currentToggleIndex = 0

local function toggleUI(visible)
	currentToggleIndex = currentToggleIndex + 1
	local thisToggleIndex = currentToggleIndex

	if visible then
		main.Visible = true
		TweenService:Create(main, TWEEN_INFO, {GroupTransparency = 0}):Play()
		TweenService:Create(shopBlur, TWEEN_INFO, {Size = 20}):Play()
		toggleExternalGui(true)
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
	else
		TweenService:Create(main, TWEEN_INFO, {GroupTransparency = 1}):Play()
		TweenService:Create(shopBlur, TWEEN_INFO, {Size = 0}):Play()
		toggleExternalGui(false)
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
		task.delay(TWEEN_INFO.Time, function()
			if currentToggleIndex == thisToggleIndex then main.Visible = false end
		end)
	end
end

local shopButton
task.spawn(function()
	local KariTopbar = require(ReplicatedStorage:WaitForChild("KariTopbar", 15))
	if KariTopbar then
		shopButton = KariTopbar.new("83393655834955")
		shopButton:Bind(function() toggleUI(true) end, function() toggleUI(false) end)
	end
end)

for _, btn in pairs(sidebar:GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			local target = btn:GetAttribute("TargetPage")
			for _, page in pairs(container:GetChildren()) do
				if page:IsA("ScrollingFrame") then page.Visible = (page.Name == target) end
			end
			for _, other in pairs(sidebar:GetChildren()) do
				if other:IsA("TextButton") then 
					other.BackgroundTransparency = 1 
					other.TextColor3 = Color3.new(1,1,1) 
				end
			end
			btn.BackgroundTransparency = 0 
			btn.TextColor3 = Color3.fromRGB(15, 23, 42)
		end)
	end
end

local isPreviewing = false
local currentPreviewAura = nil
local hiddenVisuals = {}
local previewSession = 0 

local function ClearPreview()
	if currentPreviewAura then
		currentPreviewAura:Destroy()
		currentPreviewAura = nil
	end

	for obj, data in pairs(hiddenVisuals) do
		if obj and obj.Parent then
			if data.Type == "Part" or data.Type == "Decal" then
				obj.Transparency = data.Value
			else
				obj.Enabled = data.Value
			end
		end
	end
	table.clear(hiddenVisuals)
	isPreviewing = false
end

local function PlayLocalPreview(modelName)
	if isPreviewing then ClearPreview() end
	local character = player.Character
	if not character then return end

	local rootTarget = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
	local trueRoot = character:FindFirstChild("HumanoidRootPart") or rootTarget
	if not rootTarget then return end

	local auraPrefab = aurasFolder:FindFirstChild(modelName)
	if not auraPrefab then return end

	isPreviewing = true
	previewSession = previewSession + 1 
	local thisSession = previewSession

	local currentAura = character:FindFirstChild("ActiveCosmeticAura")
	if currentAura then
		for _, obj in pairs(currentAura:GetDescendants()) do
			if obj:IsA("BasePart") then
				hiddenVisuals[obj] = {Type = "Part", Value = obj.Transparency}
				obj.Transparency = 1
			elseif obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Light") or obj:IsA("PointLight") or obj:IsA("SurfaceLight") then
				hiddenVisuals[obj] = {Type = "Effect", Value = obj.Enabled}
				obj.Enabled = false
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				hiddenVisuals[obj] = {Type = "Decal", Value = obj.Transparency}
				obj.Transparency = 1
			end
		end
	end

	currentPreviewAura = auraPrefab:Clone()
	currentPreviewAura.Name = "PreviewCosmeticAura"

	local auraRoot = currentPreviewAura:FindFirstChild("AuraPart") or currentPreviewAura.PrimaryPart or currentPreviewAura:FindFirstChild("HumanoidRootPart")
	if auraRoot then
		currentPreviewAura.PrimaryPart = auraRoot

		local bawahParts = {}
		local bawahAttachments = {} 

		for _, obj in pairs(currentPreviewAura:GetDescendants()) do
			if string.lower(obj.Name) == "bawah" then
				if obj:IsA("BasePart") and obj ~= auraRoot then
					table.insert(bawahParts, obj)
				elseif obj:IsA("Attachment") then
					table.insert(bawahAttachments, obj)
				end
			elseif obj:IsA("BasePart") and obj ~= auraRoot then
				local autoWeld = Instance.new("WeldConstraint")
				autoWeld.Part0 = auraRoot
				autoWeld.Part1 = obj
				autoWeld.Parent = obj
			end
		end

		local dummyAnimate = currentPreviewAura:FindFirstChild("Animate")
		if dummyAnimate then dummyAnimate:Destroy() end
		local dummyHum = currentPreviewAura:FindFirstChildOfClass("Humanoid")
		if dummyHum then dummyHum:Destroy() end

		for _, part in pairs(currentPreviewAura:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Massless = true
				part.Anchored = false
				local name = string.lower(part.Name)
				if (name == "head" or name == "torso" or name == "humanoidrootpart" or string.find(name, "arm") or string.find(name, "leg")) and name ~= "aurapart" then
					part.Transparency = 1
				end
			end
		end

		currentPreviewAura:PivotTo(rootTarget.CFrame)
		currentPreviewAura.Parent = character

		local builtInWeld = auraRoot:FindFirstChildOfClass("Weld") or auraRoot:FindFirstChildOfClass("ManualWeld")
		if builtInWeld then
			builtInWeld.Part0 = rootTarget
			builtInWeld.Part1 = auraRoot
		else
			local fallbackWeld = Instance.new("WeldConstraint")
			fallbackWeld.Part0 = rootTarget
			fallbackWeld.Part1 = auraRoot
			fallbackWeld.Parent = auraRoot
		end

		if #bawahParts > 0 or #bawahAttachments > 0 then
			local legTarget = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg") or trueRoot
			local bottomCFrame = CFrame.new(trueRoot.Position.X, legTarget.Position.Y, trueRoot.Position.Z) * trueRoot.CFrame.Rotation

			local bawahAnchor = Instance.new("Part")
			bawahAnchor.Name = "BawahAnchor"
			bawahAnchor.Transparency = 1
			bawahAnchor.CanCollide = false
			bawahAnchor.Massless = true
			bawahAnchor.Anchored = false
			bawahAnchor.Size = Vector3.new(1, 1, 1)
			bawahAnchor.CFrame = bottomCFrame
			bawahAnchor.Parent = currentPreviewAura

			local weldAnchor = Instance.new("WeldConstraint")
			weldAnchor.Part0 = trueRoot
			weldAnchor.Part1 = bawahAnchor
			weldAnchor.Parent = bawahAnchor

			for _, part in ipairs(bawahParts) do
				part.CFrame = bottomCFrame
				local weldBawah = Instance.new("WeldConstraint")
				weldBawah.Part0 = bawahAnchor
				weldBawah.Part1 = part
				weldBawah.Parent = part
			end

			for _, att in ipairs(bawahAttachments) do
				att.Parent = bawahAnchor
				att.WorldCFrame = bottomCFrame
			end
		end
	end

	task.delay(5, function()
		if previewSession == thisSession then
			ClearPreview()
		end
	end)
end

local function setupInteractions(page)
	for _, descendant in pairs(page:GetDescendants()) do
		if descendant:IsA("GuiButton") then

			if descendant.Name == "BuyButton" then 
				descendant.MouseButton1Click:Connect(function() 
					local currency = descendant:GetAttribute("Currency")
					local itemID = descendant:GetAttribute("ItemID")
					local itemName = descendant:GetAttribute("ItemName")
					local actionType = descendant:GetAttribute("ActionType")
					local attrName = descendant:GetAttribute("AttributeName")

					if actionType ~= "Currency" then
						if ClientHasItem(actionType, itemName, attrName) then
							ShowGlobalNotification("Kamu sudah memiliki item ini!", false)
							return
						end
					end

					if currency == "Coins" then
						local itemPrice = descendant:GetAttribute("ItemPrice")
						OpenConfirmModal(itemID, itemName, itemPrice)
					else
						ReplicatedStorage.ShopRemote:FireServer(itemID) 
					end
				end) 

			elseif descendant.Name == "GiftButton" then 
				descendant.MouseButton1Click:Connect(function()
					refreshPlayerList(descendant:GetAttribute("ItemID"))
					TweenService:Create(main, TWEEN_INFO, {GroupTransparency = 1}):Play()
					task.delay(TWEEN_INFO.Time, function() main.Visible = false end)
					giftModal.Visible = true
					giftModal.GroupTransparency = 1
					TweenService:Create(giftModal, TWEEN_INFO, {GroupTransparency = 0}):Play()
				end) 

			elseif descendant.Name == "PreviewButton" then
				descendant.MouseButton1Click:Connect(function()
					local modelName = descendant:GetAttribute("ModelName")
					if modelName then
						toggleUI(false) 
						PlayLocalPreview(modelName)
					end
				end)

				-- [KARINA] Interaksi Tombol Exchange
			elseif descendant.Name == "ExchangeButton" then
				descendant.MouseButton1Click:Connect(function()
					if exchangeModal then
						exMsgLabel.Text = "Apakah kamu yakin ingin menukar <font color='#FACC15'><b>SELURUH</b></font> Summit kamu menjadi Coins?\n\n(1 Summit = 500 Coins)"

						TweenService:Create(main, TWEEN_INFO, {GroupTransparency = 1}):Play()
						task.delay(TWEEN_INFO.Time, function() main.Visible = false end)

						exchangeModal.Visible = true
						exchangeModal.GroupTransparency = 1
						TweenService:Create(exchangeModal, TWEEN_INFO, {GroupTransparency = 0}):Play()
					end
				end)
			end

		end
	end
end

for _, page in pairs(container:GetChildren()) do
	if page:IsA("ScrollingFrame") then setupInteractions(page) end
end

main.CloseBtn.XButton.MouseButton1Click:Connect(function() 
	toggleUI(false) 
	if shopButton then
		pcall(function() shopButton:Deselect() end) 
		pcall(function() shopButton:ResetState() end)
	end
end)
giftModal.ImageButton.MouseButton1Click:Connect(closeGiftModal)

cmYesBtn.MouseButton1Click:Connect(function()
	if pendingPurchaseID then
		ReplicatedStorage.ShopRemote:FireServer(pendingPurchaseID)
	end
	CloseConfirmModal()
end)
cmNoBtn.MouseButton1Click:Connect(CloseConfirmModal)

-- [KARINA] Binding Tombol Modal Exchange
if exchangeModal then
	exYesBtn.MouseButton1Click:Connect(function()
		ReplicatedStorage.ShopRemote:FireServer("EXCHANGE_SUMMIT")
		CloseExchangeModal()
	end)
	exNoBtn.MouseButton1Click:Connect(CloseExchangeModal)
end

local redeemSection = nil
for _, desc in pairs(container:GetDescendants()) do
	if desc:IsA("Frame") and desc.Name == "RedeemSection" then redeemSection = desc; break end
end

ReplicatedStorage:WaitForChild("RedeemResult").OnClientEvent:Connect(function(msg, success, audioType)
	ShowGlobalNotification(msg, success)

	if success and audioType then
		PlayAudio(audioType)
	end

	if redeemSection then
		local statusLabel = redeemSection:FindFirstChild("StatusLabel")
		if statusLabel then
			statusLabel.Text = msg
			statusLabel.TextColor3 = success and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(248, 113, 113)
			task.delay(3, function() if statusLabel.Text == msg then statusLabel.Text = "" end end)
		end
	end
end)

local globalChatRemote = ReplicatedStorage:WaitForChild("GlobalChatBroadcast", 10)
if globalChatRemote then
	globalChatRemote.OnClientEvent:Connect(function(formattedMessage)
		local sysChannel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXSystem")
		if sysChannel then
			sysChannel:DisplaySystemMessage(formattedMessage)
		end
	end)
end

if redeemSection then
	local codeInput = redeemSection:WaitForChild("CodeInput")
	local redeemBtn = redeemSection:WaitForChild("RedeemBtn")
	redeemBtn.MouseButton1Click:Connect(function()
		local code = codeInput.Text
		if code ~= "" then
			ReplicatedStorage.RedeemRemote:FireServer(code)
			codeInput.Text = ""
		end
	end)
end