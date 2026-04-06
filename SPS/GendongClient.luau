-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Remotes
local CarryRemote = ReplicatedStorage:WaitForChild("CarryRemote")

-- Config
local SIT_R15_ID = 95436946826593
local SIT_R6_ID  = 107194998566748
local CARRY_R15_ID = 102136348212590
local CARRY_R6_ID  = 140093067448509
local MAX_CLICK_DISTANCE = 20

local THEME_CARDBG = Color3.fromRGB(40, 75, 125)
local THEME_DISABLED = Color3.fromRGB(60, 80, 110)
local THEME_SUCCESS = Color3.fromRGB(100, 170, 255) -- Soft Blue

-- Player/UI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local gui = script.Parent

-- Audio
local sndClick = gui:WaitForChild("Snd_Click")
local sndPrompt = gui:WaitForChild("Snd_Prompt")
local sndSendSuccess = gui:WaitForChild("Snd_SendSuccess")
local sndReceiveCoin = gui:WaitForChild("Snd_ReceiveCoin")

-- Putar klik untuk semua tombol
for _, obj in pairs(gui:GetDescendants()) do
	if obj:IsA("TextButton") then
		obj.MouseButton1Click:Connect(function() sndClick:Play() end)
	end
end

-- UI Panels
local selFrame = gui:WaitForChild("SelectFrame")
local sAvatar = selFrame:WaitForChild("AvatarImage")
local sName = selFrame:WaitForChild("NameLabel")
local btnCarry = selFrame:WaitForChild("CarryBtn")
local btnSync = selFrame:WaitForChild("SyncBtn")
local btnCoin = selFrame:WaitForChild("CoinBtn")
local btnConnect = selFrame:WaitForChild("ConnectBtn")
local btnClose = selFrame:WaitForChild("CloseBtn")

local cprmFrame = gui:WaitForChild("CoinPromptFrame")
local cpName = cprmFrame:WaitForChild("NameLabel")
local cpInput = cprmFrame:WaitForChild("AmountInput")
local cpSend = cprmFrame:WaitForChild("SendBtn")
local cpCancel = cprmFrame:WaitForChild("CancelBtn")

local prmFrame = gui:WaitForChild("PromptFrame")
local pAvatar = prmFrame:WaitForChild("AvatarImage")
local pName = prmFrame:WaitForChild("NameLabel")
local btnYes = prmFrame:WaitForChild("YesBtn")
local btnNo = prmFrame:WaitForChild("NoBtn")

-- Coin Receive Prompt
local crpFrame = gui:WaitForChild("CoinReceivePrompt")
local crpAvatar = crpFrame:WaitForChild("AvatarImage")
local crpName = crpFrame:WaitForChild("NameLabel")
local crpYes = crpFrame:WaitForChild("YesBtn")
local crpNo = crpFrame:WaitForChild("NoBtn")

local crFrame = gui:WaitForChild("CarrierFrame")
local crName = crFrame:WaitForChild("NameLabel")
local btnPutDown = crFrame:WaitForChild("PutDownBtn")

local cdFrame = gui:WaitForChild("CarriedFrame")
local cdName = cdFrame:WaitForChild("NameLabel")
local btnGetDown = cdFrame:WaitForChild("GetDownBtn")

-- Hide all initially
local function hideAllFrames() 
	selFrame.Visible=false; prmFrame.Visible=false; 
	crFrame.Visible=false; cdFrame.Visible=false; 
	cprmFrame.Visible=false; crpFrame.Visible=false
end
hideAllFrames()

-- Chat Command Logic
player.Chatted:Connect(function(msg)
	local lowerMsg = string.lower(msg)
	if lowerMsg == "/carry off" then
		player:SetAttribute("CarryDisabled", true)
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = "[Gendong] Fitur digendong/trade DIMATIKAN. Orang lain tidak akan bisa mengirim permintaan kepadamu.",
			Color = Color3.fromRGB(255, 100, 100)
		})
	elseif lowerMsg == "/carry on" then
		player:SetAttribute("CarryDisabled", false)
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = "[Gendong] Fitur digendong/trade DIHIDUPKAN kembali.",
			Color = Color3.fromRGB(100, 170, 255)
		})
	end
end)

-- Helpers
local function setAvatar(imgElement, userId)
	if not userId then return end

	-- [PERBAIKAN ECA] Menangani pemain dummy (Player1, Player2) saat testing di Studio
	if userId > 0 then
		-- Pemain asli dengan UserId valid
		imgElement.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
	else
		-- Pemain bot/test (UserId negatif seperti -1 atau -2)
		-- Menggunakan gambar placeholder default Roblox agar UI tetap terlihat rapi saat testing
		imgElement.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" 
	end
end

local function getHumanoid() return player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
local function getHRP() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
local function getAnimator(hum) return hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)) end
local function rigIsR15(hum) return hum and hum.RigType == Enum.HumanoidRigType.R15 end

local function pointOverOurGui(px, py)
	local list = playerGui:GetGuiObjectsAtPosition(px, py)
	for _, o in ipairs(list) do
		if o:IsDescendantOf(gui) then return true end
	end
	return false
end

local function pickPlayerAt(px, py)
	if pointOverOurGui(px, py) then return nil end
	local ray = camera:ViewportPointToRay(px, py)
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character}
	local rc = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	if not rc then return nil end
	local model = rc.Instance:FindFirstAncestorOfClass("Model"); if not model then return nil end
	local pTarget = Players:GetPlayerFromCharacter(model)
	if not pTarget or pTarget == player then return nil end

	local myHRP, tHRP = getHRP(), pTarget.Character and pTarget.Character:FindFirstChild("HumanoidRootPart")
	if not myHRP or not tHRP or (myHRP.Position - tHRP.Position).Magnitude > MAX_CLICK_DISTANCE then return nil end
	return pTarget
end

-- ==========================================
-- SYNC LOGIC
-- ==========================================
local currentSyncTargetId = nil
local syncConnections = {}
local syncedTracks = {}
local syncTether = nil

local function cleanupSync()
	if syncTether then syncTether:Disconnect(); syncTether = nil end
	for _, conn in ipairs(syncConnections) do conn:Disconnect() end
	table.clear(syncConnections)
	for targetTrack, myTrack in pairs(syncedTracks) do
		pcall(function() myTrack:Stop(); myTrack:Destroy() end)
	end
	table.clear(syncedTracks)
	currentSyncTargetId = nil
	btnSync.Text = "Sync"
	btnSync.BackgroundColor3 = THEME_CARDBG
end

local function isSyncable(track)
	local anim = track.Animation; if not anim then return false end
	local n1, n2 = string.lower(anim.Name or ""), string.lower(track.Name or "")
	local blockList = {"idle", "walk", "run", "jump", "fall", "climb", "swim", "sit", "toolnone"}
	for _, bad in ipairs(blockList) do
		if string.find(n1, bad) or string.find(n2, bad) then return false end
	end
	if track.Priority == Enum.AnimationPriority.Movement then return false end
	return true
end

local function mimicTrack(targetTrack)
	if not isSyncable(targetTrack) then return end
	if syncedTracks[targetTrack] then return end 
	if not targetTrack.Animation or targetTrack.Animation.AnimationId == "" then return end

	local myAnimator = getAnimator(getHumanoid())
	if not myAnimator then return end

	local anim = Instance.new("Animation"); anim.AnimationId = targetTrack.Animation.AnimationId
	local myTrack
	local ok = pcall(function()
		myTrack = myAnimator:LoadAnimation(anim)
		local pri = targetTrack.Priority
		myTrack.Priority = (pri == Enum.AnimationPriority.Core or pri == Enum.AnimationPriority.Idle) and Enum.AnimationPriority.Action or pri
		myTrack:Play()
		myTrack:AdjustSpeed(targetTrack.Speed)
	end)

	if ok and myTrack then
		syncedTracks[targetTrack] = myTrack
		local stopConn
		stopConn = targetTrack.Stopped:Connect(function()
			pcall(function() myTrack:Stop(); myTrack:Destroy() end)
			syncedTracks[targetTrack] = nil
			if stopConn then stopConn:Disconnect() end
		end)
		table.insert(syncConnections, stopConn)
	end
end

local function startSync(targetPlayer)
	cleanupSync()
	local targetAnimator = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid") and targetPlayer.Character.Humanoid:FindFirstChildOfClass("Animator")
	if not targetAnimator then return end

	currentSyncTargetId = targetPlayer.UserId
	btnSync.Text = "Unsync"
	btnSync.BackgroundColor3 = Color3.fromRGB(200, 80, 80) 

	for _, track in ipairs(targetAnimator:GetPlayingAnimationTracks()) do mimicTrack(track) end
	table.insert(syncConnections, targetAnimator.AnimationPlayed:Connect(mimicTrack))

	syncTether = RunService.Heartbeat:Connect(function()
		for tTrack, mTrack in pairs(syncedTracks) do
			if tTrack.IsPlaying and mTrack.IsPlaying then
				if mTrack.Speed ~= tTrack.Speed then mTrack:AdjustSpeed(tTrack.Speed) end
				if mTrack.Length > 0 and tTrack.Length > 0 and math.abs(mTrack.TimePosition - tTrack.TimePosition) > 0.05 then
					mTrack.TimePosition = tTrack.TimePosition
				end
			end
		end
	end)

	table.insert(syncConnections, targetPlayer.CharacterAdded:Connect(cleanupSync))
	table.insert(syncConnections, player.CharacterAdded:Connect(cleanupSync))
	table.insert(syncConnections, Players.PlayerRemoving:Connect(function(plr) if plr.UserId == currentSyncTargetId then cleanupSync() end end))
end

-- ==========================================
-- ANIMATION CARRY LOGIC
-- ==========================================
local sitTrack, carryTrack
local function playAnim(isSit)
	local hum = getHumanoid(); if not hum then return end
	if isSit then hum.Sit = true end
	local animId = isSit and (rigIsR15(hum) and SIT_R15_ID or SIT_R6_ID) or (rigIsR15(hum) and CARRY_R15_ID or CARRY_R6_ID)
	if animId == 0 then return end
	local animator = getAnimator(hum)
	local track = isSit and sitTrack or carryTrack
	if track then track:Stop(0.1) end
	local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://"..tostring(animId)
	pcall(function()
		track = animator:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action; track.Looped = true; track:Play(0.2)
		if isSit then sitTrack = track else carryTrack = track end
	end)
end
local function stopAnim(isSit)
	local track = isSit and sitTrack or carryTrack
	if track then track:Stop(0.2); if isSit then sitTrack=nil else carryTrack=nil end end
	if isSit then local h = getHumanoid(); if h then h.Sit = false end end
end

-- ==========================================
-- STATE & UI LOGIC
-- ==========================================
local uiMode = "idle"
local selectedTargetId, selectedTargetName, lastRequesterId = nil, nil, nil
local coinRequesterId = nil
local carriedList = {}
local isCarried, currentCarrierId = false, nil
local jumpBlockConn = nil

local function setConnectionButtonFor(userId, btnElement)
	if not userId or userId == player.UserId then
		btnElement.Text = "Connection"; btnElement.BackgroundColor3 = THEME_DISABLED; btnElement.Active = false; return
	end
	task.spawn(function()
		local ok, isFriend = pcall(function() return player:IsFriendsWith(userId) end)
		if ok and isFriend then
			btnElement.Text = "Connection"; btnElement.BackgroundColor3 = THEME_DISABLED; btnElement.Active = false
		else
			btnElement.Text = "Add Connection"; btnElement.BackgroundColor3 = THEME_CARDBG; btnElement.Active = true
		end
	end)
end

local function setJumpBlock(state)
	if state then
		if not jumpBlockConn then jumpBlockConn = UserInputService.JumpRequest:Connect(function() local h = getHumanoid() if h then h.Jump = false end end) end
	else
		if jumpBlockConn then jumpBlockConn:Disconnect(); jumpBlockConn = nil end
	end
end

local function setModeSelect(pTarget)
	if player:GetAttribute("CarryDisabled") then return end 
	hideAllFrames()
	uiMode = "select"; selectedTargetId = pTarget.UserId; selectedTargetName = pTarget.DisplayName
	sName.Text = selectedTargetName; setAvatar(sAvatar, selectedTargetId)

	btnCarry.Text = "Carry"; btnCarry.BackgroundColor3 = Color3.fromRGB(247, 173, 175); btnCarry.Active = true
	btnSync.Text = (currentSyncTargetId == selectedTargetId) and "Unsync" or "Sync"
	btnSync.BackgroundColor3 = (currentSyncTargetId == selectedTargetId) and Color3.fromRGB(200, 80, 80) or THEME_CARDBG

	setConnectionButtonFor(selectedTargetId, btnConnect)
	selFrame.Visible = true
end

local function setModePrompt(fromId, fromName)
	if player:GetAttribute("CarryDisabled") then
		CarryRemote:FireServer("Response", {requesterId = fromId, accept = false}); return
	end
	hideAllFrames()
	uiMode = "prompt"; lastRequesterId = fromId
	pName.Text = ("%s wants to carry you."):format(fromName)
	setAvatar(pAvatar, fromId)
	prmFrame.Visible = true
	sndPrompt:Play()
end

local function setCoinPrompt(fromId, fromName, amount)
	if player:GetAttribute("CarryDisabled") then
		CarryRemote:FireServer("CoinResponse", {requesterId = fromId, accept = false}); return
	end
	hideAllFrames()
	uiMode = "coin_receive"; coinRequesterId = fromId
	crpName.Text = ("%s is sending %s Coins."):format(fromName, tostring(amount))
	setAvatar(crpAvatar, fromId)
	crpFrame.Visible = true
	sndPrompt:Play()
end

local function ensureStatusCarried()
	if not isCarried or not currentCarrierId then return end
	hideAllFrames(); uiMode = "carried"
	cdName.Text = "Carrier: " .. (currentCarrierName or "Player")
	cdFrame.Visible = true; setJumpBlock(true)
end

local function refreshCarrierUI()
	if #carriedList <= 0 then crFrame.Visible = false; stopAnim(false); return end
	hideAllFrames(); crName.Text = ("Carrying: %s"):format(carriedList[1].name)
	crFrame.Visible = true; if not carryTrack then playAnim(false) end
end

local function resetUI()
	uiMode = "idle"
	if isCarried then ensureStatusCarried()
	elseif #carriedList > 0 then refreshCarrierUI()
	else hideAllFrames() end
end

-- World Input
UserInputService.InputBegan:Connect(function(inp, gp)
	if gp or (uiMode ~= "idle" and uiMode ~= "select" and uiMode ~= "carried") then return end
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
		local pTarget = pickPlayerAt(inp.Position.X, inp.Position.Y)
		if pTarget then setModeSelect(pTarget) end
	end
end)

-- Standard Buttons
btnClose.MouseButton1Click:Connect(resetUI)

btnCarry.MouseButton1Click:Connect(function()
	if not selectedTargetId then return end
	btnCarry.Text = "Waiting..."; btnCarry.Active = false; btnCarry.BackgroundColor3 = THEME_DISABLED
	CarryRemote:FireServer("Request", {targetId = selectedTargetId})
end)

-- Carry Prompt Buttons
btnYes.MouseButton1Click:Connect(function()
	if lastRequesterId then CarryRemote:FireServer("Response", {requesterId = lastRequesterId, accept = true}) end
	resetUI()
end)
btnNo.MouseButton1Click:Connect(function()
	if lastRequesterId then CarryRemote:FireServer("Response", {requesterId = lastRequesterId, accept = false}) end
	resetUI()
end)

-- Coin Prompt Buttons (RECEIVER)
crpYes.MouseButton1Click:Connect(function()
	if coinRequesterId then CarryRemote:FireServer("CoinResponse", {requesterId = coinRequesterId, accept = true}) end
	resetUI()
end)
crpNo.MouseButton1Click:Connect(function()
	if coinRequesterId then CarryRemote:FireServer("CoinResponse", {requesterId = coinRequesterId, accept = false}) end
	resetUI()
end)

local function reqFriend(uid, btn)
	if not uid then return end
	pcall(function() player:RequestFriendship(Players:GetPlayerByUserId(uid)) end)
	btn.Text = "Sent"; btn.Active = false; btn.BackgroundColor3 = THEME_DISABLED
end
btnConnect.MouseButton1Click:Connect(function() reqFriend(selectedTargetId, btnConnect) end)

btnSync.MouseButton1Click:Connect(function()
	if not selectedTargetId then return end
	if currentSyncTargetId == selectedTargetId then cleanupSync()
	else
		local tPlayer = Players:GetPlayerByUserId(selectedTargetId)
		if tPlayer then startSync(tPlayer) end
	end
end)

-- COIN SEND LOGIC (SENDER)
btnCoin.MouseButton1Click:Connect(function()
	if not selectedTargetId then return end
	hideAllFrames(); uiMode = "coin_send"
	cpName.Text = "Send to " .. (selectedTargetName or "Player")
	cpInput.Text = ""; cpSend.Text = "Send"; cpSend.Active = true; cpSend.BackgroundColor3 = THEME_SUCCESS
	cprmFrame.Visible = true
end)

cpCancel.MouseButton1Click:Connect(function()
	if selectedTargetId then
		local tPlayer = Players:GetPlayerByUserId(selectedTargetId)
		if tPlayer then setModeSelect(tPlayer) else resetUI() end
	else resetUI() end
end)

cpSend.MouseButton1Click:Connect(function()
	local amount = tonumber(cpInput.Text)
	if not amount or amount <= 0 or amount ~= math.floor(amount) then
		cpSend.Text = "Invalid"; cpSend.BackgroundColor3 = THEME_DISABLED
		task.delay(1.5, function() cpSend.Text = "Send"; cpSend.BackgroundColor3 = THEME_SUCCESS end)
		return
	end
	cpSend.Text = "Awaiting..."; cpSend.Active = false; cpSend.BackgroundColor3 = THEME_DISABLED
	CarryRemote:FireServer("SendCoins", {targetId = selectedTargetId, amount = amount})
end)

btnGetDown.MouseButton1Click:Connect(function() CarryRemote:FireServer("Stop", {}) end)
btnPutDown.MouseButton1Click:Connect(function()
	if #carriedList > 0 then CarryRemote:FireServer("Stop", {targetId = carriedList[1].id}) end
end)

-- Remote Handling
local function showMsg(msg)
	if uiMode == "select" then btnCarry.Text = msg; task.delay(1.5, resetUI) else resetUI() end
end

CarryRemote.OnClientEvent:Connect(function(action, data)
	if action == "Prompt" then setModePrompt(data.fromId, data.fromName)
	elseif action == "CoinPrompt" then setCoinPrompt(data.fromId, data.fromName, data.amount)
	elseif action == "Start" then
		if data.youAreCarrier then
			table.insert(carriedList, {id=data.targetId, name=data.targetName}); refreshCarrierUI()
		else
			isCarried = true; currentCarrierId = data.carrierId; currentCarrierName = data.carrierName
			playAnim(true); ensureStatusCarried()
		end
	elseif action == "End" then
		if data.youAreCarrier then
			for i, v in ipairs(carriedList) do if v.id == data.removedId then table.remove(carriedList, i) break end end
			refreshCarrierUI()
		else
			isCarried = false; currentCarrierId = nil; setJumpBlock(false); stopAnim(true); resetUI()
		end
	elseif action == "CarrierList" then
		carriedList = data.list or {}; refreshCarrierUI()

	elseif action == "CoinSuccess" then
		resetUI()
		sndSendSuccess:Play()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = "[Transfer] Berhasil mengirim " .. tostring(data.amount) .. " Coins kepada " .. tostring(data.targetName) .. ".",
			Color = THEME_SUCCESS
		})
	elseif action == "CoinReceived" then
		resetUI()
		sndReceiveCoin:Play()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = "[Transfer] Kamu menerima " .. tostring(data.amount) .. " Coins dari " .. tostring(data.senderName) .. "!",
			Color = Color3.fromRGB(247, 173, 175)
		})

	elseif action == "Declined" then showMsg("Declined")
	elseif action == "TooFar" then showMsg("Too far")
	elseif action == "Busy" then showMsg("Busy")
	elseif action == "Failed" then 
		if uiMode == "coin_send" then cpSend.Text = data.reason or "Failed"; task.delay(1.5, resetUI)
		else showMsg(data.reason or "Failed") end
	elseif action == "RequestExpired" or action == "PromptClose" or action == "PromptExpire" then resetUI()
	end
end)

player.CharacterAdded:Connect(function()
	stopAnim(true); stopAnim(false); setJumpBlock(false)
	cleanupSync() 
	isCarried = false; currentCarrierId = nil; carriedList = {}; resetUI()
end)