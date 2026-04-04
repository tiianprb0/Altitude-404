--[[
    QUEST LOCAL SYSTEM (Taruh di StarterPlayerScripts)
    REVISI KARINA: 
    1. Sistem Kamera POV diadaptasi dari YarraCameraClient.
    2. Player Freeze (Kunci pergerakan).
    3. Handshake sinkron (Anti Race Condition & Memory Leak).
    4. FAIL-SAFE: Anti-Softlock jika pemain mati/reset saat interaksi.
    5. FIX KARINA (Jembatan & Lokasi Kayu): Pengambilan Part dibuat Real-time 
       dan dinamis untuk mengatasi isu StreamingEnabled / Replication Delay.
]]

local player = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local Chat = game:GetService("Chat")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local questFolderRS = RS:WaitForChild("QuestSystem", 10)
local remote = questFolderRS:WaitForChild("QuestRemote", 10)

if not remote then 
	warn("KARINA: Remote Quest gagal dimuat.")
	return 
end

local folderQuest = workspace:WaitForChild("QuestArea1", 999)
local npcObj = folderQuest:WaitForChild("Yarraa", 999)
local jembatan = folderQuest:WaitForChild("Jembatan", 10)

-- =========================================================================
-- VARIABEL UI & STATE
-- =========================================================================
local exclamationModel = nil
local progressGui = nil
local renderConnExclamation = nil

local camera = workspace.CurrentCamera
local originalCamCFrame = nil
local cameraTween = nil

local oldWalkSpeed = 16
local oldJumpPower = 50

-- =========================================================================
-- FAIL-SAFE ANTI-SOFTLOCK (Pemain Mati / Reset)
-- =========================================================================
local function forceReleaseCamera(humanoidTarget)
	if cameraTween then cameraTween:Cancel() end
	camera.CameraType = Enum.CameraType.Custom
	if humanoidTarget then
		camera.CameraSubject = humanoidTarget
	end
	originalCamCFrame = nil
end

player.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid", 5)
	if humanoid then
		forceReleaseCamera(humanoid)
		humanoid.Died:Connect(function()
			forceReleaseCamera(humanoid)
		end)
	end
end)

-- =========================================================================
-- FUNGSI SISTEM QUEST
-- =========================================================================
local function cleanupSisaKayuLokal()
	for _, child in ipairs(folderQuest:GetChildren()) do
		if child.Name == "DEBUG_RANTING_KAYU" then child:Destroy() end
	end
end

-- KARINA FIX: Ambil lokasi secara real-time.
local function getLokasiFolderRealTime()
	local folder = {}
	for _, child in ipairs(folderQuest:GetChildren()) do
		if string.match(child.Name, "Lokasi") then
			table.insert(folder, child)
		end
	end
	table.sort(folder, function(a, b) return a.Name < b.Name end)
	return folder
end

local function spawnKayuArray(indices)
	cleanupSisaKayuLokal()

	local lokasiSekarang = getLokasiFolderRealTime()

	-- Anti-Fail: Jika ping pemain sangat tinggi dan part map belum muncul
	if #lokasiSekarang == 0 then
		warn("KARINA DEBUG: Map lokasi belum ter-load sempurna. Menunggu 1 detik...")
		task.wait(1.5)
		lokasiSekarang = getLokasiFolderRealTime()
	end

	for _, index in ipairs(indices) do
		local lokasiTarget = lokasiSekarang[index]

		-- KARINA FIX: Gunakan WaitForChild agar memastikan item tidak nil saat di-load lambat
		local sourceItem = RS:WaitForChild("Ranting Kayu", 5)

		if not lokasiTarget or not sourceItem then 
			warn("KARINA DEBUG: Gagal spawn kayu ke-"..index..". Lokasi atau Item tidak ditemukan di Client.")
			continue 
		end

		local visual = sourceItem:IsA("Tool") and (sourceItem:FindFirstChild("Handle") and sourceItem.Handle:Clone() or sourceItem:Clone()) or sourceItem:Clone()

		for _, v in ipairs(visual:GetDescendants()) do
			if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end
		end

		local partUtama = nil
		for _, v in ipairs(visual:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Anchored = true; v.CanCollide = false
				if not partUtama then partUtama = v end 
			end
		end

		if visual:IsA("BasePart") then visual.Anchored = true; visual.CanCollide = false; partUtama = visual end
		if visual:IsA("Model") and not visual.PrimaryPart then visual.PrimaryPart = partUtama end

		if visual:IsA("Model") or visual:IsA("BasePart") then
			visual:PivotTo(lokasiTarget.CFrame + Vector3.new(0, 4, 0))
			visual.Name = "DEBUG_RANTING_KAYU"
			visual.Parent = folderQuest 
		end

		local pusat = visual:IsA("Model") and visual.PrimaryPart or (visual:IsA("BasePart") and visual or visual:FindFirstChildWhichIsA("BasePart", true))

		if pusat then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ObjectText = "Ranting Kayu"
			prompt.ActionText = "Ambil"
			prompt.HoldDuration = 0.5 
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = 12
			prompt.Parent = pusat

			prompt.Triggered:Connect(function()
				visual:Destroy()
				remote:FireServer("AmbilKayu", index)
			end)
		end
	end
end

local function toggleJembatan(muncul)
	local trans = muncul and 0 or 1

	local partsSekarang = {}
	if jembatan:IsA("Model") then
		for _, v in ipairs(jembatan:GetDescendants()) do
			if v:IsA("BasePart") then table.insert(partsSekarang, v) end
		end
	elseif jembatan:IsA("BasePart") then
		table.insert(partsSekarang, jembatan)
	end

	for _, part in ipairs(partsSekarang) do
		part.Transparency = trans
		part.CanCollide = muncul
	end
end

local function getNPCHead()
	return npcObj:FindFirstChild("Head") or npcObj.PrimaryPart
end

-- =========================================================================
-- KAMERA POV
-- =========================================================================
local function focusCamera()
	local char = player.Character
	local npcHead = getNPCHead()
	local humanoid = char and char:FindFirstChild("Humanoid")
	local playerHead = char and char:FindFirstChild("Head")

	if not playerHead or not npcHead or not humanoid or humanoid.Health <= 0 then return end

	oldWalkSpeed = humanoid.WalkSpeed
	oldJumpPower = humanoid.JumpPower > 0 and humanoid.JumpPower or 50
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	originalCamCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable

	local targetCFrame = CFrame.lookAt(playerHead.Position + (playerHead.CFrame.LookVector * 1.5), npcHead.Position)
	cameraTween = TweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = targetCFrame})
	cameraTween:Play()
end

local function resetCamera()
	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")

	if humanoid and humanoid.Health > 0 then
		humanoid.WalkSpeed = oldWalkSpeed
		humanoid.JumpPower = oldJumpPower
	end

	if cameraTween then cameraTween:Cancel() end

	if originalCamCFrame then
		local returnTween = TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = originalCamCFrame})
		returnTween:Play()
		returnTween.Completed:Connect(function()
			camera.CameraType = Enum.CameraType.Custom
			if humanoid then camera.CameraSubject = humanoid end
			originalCamCFrame = nil
		end)
	else
		camera.CameraType = Enum.CameraType.Custom
		if humanoid then camera.CameraSubject = humanoid end
	end
end

-- =========================================================================
-- UI & VISUAL EFFECTS
-- =========================================================================
local function showExclamation()
	local head = getNPCHead()
	if exclamationModel or not head then return end

	exclamationModel = Instance.new("Model")
	exclamationModel.Name = "QuestIndicator3D"

	local batang = Instance.new("Part")
	batang.Size = Vector3.new(0.15, 0.7, 0.15)
	batang.Color = Color3.fromRGB(255, 215, 0)
	batang.Material = Enum.Material.Neon
	batang.Anchored = true; batang.CanCollide = false
	batang.Parent = exclamationModel

	local titik = Instance.new("Part")
	titik.Size = Vector3.new(0.15, 0.15, 0.15)
	titik.Color = Color3.fromRGB(255, 215, 0)
	titik.Material = Enum.Material.Neon
	titik.Anchored = true; titik.CanCollide = false
	titik.Parent = exclamationModel

	exclamationModel.Parent = npcObj

	local t = 0
	renderConnExclamation = RunService.RenderStepped:Connect(function(dt)
		t += dt
		if head and exclamationModel.Parent then
			local yOffset = math.sin(t * 4) * 0.25 
			local basePos = head.CFrame * CFrame.new(1.2, 1 + yOffset, 0)
			batang.CFrame = basePos
			titik.CFrame = basePos * CFrame.new(0, -0.55, 0)
		end
	end)
end

local function hideExclamation()
	if renderConnExclamation then renderConnExclamation:Disconnect() renderConnExclamation = nil end
	if exclamationModel then exclamationModel:Destroy() exclamationModel = nil end
end

local function showProgressUI()
	local head = getNPCHead()
	if progressGui or not head then return end

	progressGui = Instance.new("BillboardGui")
	progressGui.Size = UDim2.new(0, 100, 0, 40)
	progressGui.StudsOffset = Vector3.new(0, 2.5, 0)
	progressGui.AlwaysOnTop = true

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "0/2"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.5
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextScaled = true
	textLabel.Parent = progressGui
	progressGui.Parent = head
end

local function hideProgressUI()
	if progressGui then progressGui:Destroy() progressGui = nil end
end

local function updateNPCUI(current, max)
	if progressGui and progressGui:FindFirstChild("TextLabel") then
		progressGui.TextLabel.Text = current .. "/" .. max
	end
end

local function showBubble(part, pesan, warna)
	if part then pcall(function() Chat:Chat(part, pesan, Enum.ChatColor.White) end) end
end

-- =========================================================================
-- LISTENER EVENTS & HANDSHAKE
-- =========================================================================
remote.OnClientEvent:Connect(function(action, arg1, arg2, arg3)
	if action == "SpawnKayuMultiple" then spawnKayuArray(arg1)
	elseif action == "BubbleChat" then showBubble(arg1, arg2, arg3)
	elseif action == "BukaJembatanLocal" then toggleJembatan(true)
	elseif action == "HideJembatanLocal" then toggleJembatan(false)
	elseif action == "ShowExclamation" then showExclamation()
	elseif action == "HideExclamation" then hideExclamation()
	elseif action == "ShowProgressUI" then showProgressUI()
	elseif action == "HideProgressUI" then hideProgressUI()
	elseif action == "UpdateNPCUI" then updateNPCUI(arg1, arg2)
	elseif action == "CameraFocus" then focusCamera()
	elseif action == "CameraReset" then resetCamera()
	end
end)

remote:FireServer("ClientReady")

-- =========================================================================
-- ISOLASI SISTEM NPC YARRAA (SAFE LOADING & PHYSICS FIX)
-- =========================================================================
task.spawn(function()
	local humanoid = npcObj:WaitForChild("Humanoid", 10)
	local rootPart = npcObj:WaitForChild("HumanoidRootPart", 10)
	local head = npcObj:WaitForChild("Head", 10)

	if not humanoid or not rootPart or not head then return end

	local animator = humanoid:WaitForChild("Animator", 10) or Instance.new("Animator", humanoid)
	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15

	for _, part in ipairs(npcObj:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = (part.Name == "HumanoidRootPart")
		end
	end

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

	local animObj = Instance.new("Animation")
	animObj.AnimationId = "rbxassetid://507766388"
	local track = animator:LoadAnimation(animObj)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Idle
	track:Play()

	local waveObj = Instance.new("Animation")
	waveObj.AnimationId = isR15 and "rbxassetid://507770239" or "rbxassetid://128777973"
	local waveTrack = animator:LoadAnimation(waveObj)
	waveTrack.Priority = Enum.AnimationPriority.Action
	waveTrack.Looped = false

	local neck = nil
	if isR15 then
		neck = head:WaitForChild("Neck", 10)
	else
		local torso = npcObj:WaitForChild("Torso", 10)
		if torso then neck = torso:WaitForChild("Neck", 10) end
	end

	if not neck then return end

	local originalNeckC0 = neck.C0
	local hasWaved = false
	local LOOK_RADIUS = 15

	RunService.RenderStepped:Connect(function()
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

		local playerRoot = player.Character.HumanoidRootPart
		local playerHead = player.Character:FindFirstChild("Head")
		if not playerHead then return end

		local distance = (rootPart.Position - playerRoot.Position).Magnitude

		if distance <= LOOK_RADIUS then
			if not hasWaved then
				hasWaved = true
				waveTrack:Play()
			end

			local relativeDir = rootPart.CFrame:PointToObjectSpace(playerHead.Position)
			local yaw = math.atan2(-relativeDir.X, -relativeDir.Z) 
			local pitch = math.asin(relativeDir.Y / relativeDir.Magnitude) 

			yaw = math.clamp(yaw, -math.rad(60), math.rad(60))
			pitch = math.clamp(pitch, -math.rad(45), math.rad(45))

			if isR15 then
				neck.C0 = neck.C0:Lerp(originalNeckC0 * CFrame.Angles(pitch, yaw, 0), 0.1)
			else
				neck.C0 = neck.C0:Lerp(originalNeckC0 * CFrame.Angles(0, -yaw, 0) * CFrame.Angles(pitch, 0, 0), 0.1)
			end
		else
			if neck.C0 ~= originalNeckC0 then neck.C0 = neck.C0:Lerp(originalNeckC0, 0.1) end
			hasWaved = false
		end
	end)
end)