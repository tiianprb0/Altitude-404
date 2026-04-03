local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

------------------------------------------------
-- SETTINGS & SETUP
------------------------------------------------
local testMode = false
local spawnChance = 0.80 

local bellSoundId = "rbxassetid://133993356800967"

local wsFolder = workspace:WaitForChild("PocongJumpscareWS", 10)
if not wsFolder then return end

local pocongFolder = ReplicatedStorage:WaitForChild("Pocong", 10)
if not pocongFolder then return end

local scareEvent = pocongFolder:WaitForChild("PocongScareEvent", 10)
if not scareEvent then return end

local debounce = {}
local triggerBoxes = {}

for _, child in ipairs(wsFolder:GetChildren()) do
	if child.Name == "JumpscareTrigger" and child:IsA("BasePart") then
		table.insert(triggerBoxes, child)
	end
end

Players.PlayerRemoving:Connect(function(player)
	debounce[player] = nil
end)

------------------------------------------------
-- FUNGSI MATEMATIKA: AREA BOUNDARIES & TERRAIN
------------------------------------------------
local function isInsideBox(position, boxPart)
	local relPos = boxPart.CFrame:PointToObjectSpace(position)
	local halfSize = boxPart.Size / 2

	return math.abs(relPos.X) <= halfSize.X and
		math.abs(relPos.Y) <= halfSize.Y and
		math.abs(relPos.Z) <= halfSize.Z
end

local function clampPointToBox(worldPoint, boxPart)
	local localPos = boxPart.CFrame:PointToObjectSpace(worldPoint)
	local halfSize = boxPart.Size / 2

	local clampedLocal = Vector3.new(
		math.clamp(localPos.X, -halfSize.X, halfSize.X),
		math.clamp(localPos.Y, -halfSize.Y, halfSize.Y),
		math.clamp(localPos.Z, -halfSize.Z, halfSize.Z)
	)

	return boxPart.CFrame:PointToWorldSpace(clampedLocal)
end

local function getGroundY(targetPosition, boxPart, excludeList)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = excludeList

	local boxTopY = boxPart.Position.Y + (boxPart.Size.Y / 2) + 10
	local rayOrigin = Vector3.new(targetPosition.X, boxTopY, targetPosition.Z)
	local rayDirection = Vector3.new(0, -(boxPart.Size.Y + 100), 0) 

	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if rayResult then
		return rayResult.Position.Y
	end
	return targetPosition.Y
end

local function getGroundYTroll(targetPosition, excludeList)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = excludeList

	local rayOrigin = Vector3.new(targetPosition.X, targetPosition.Y + 50, targetPosition.Z)
	local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -150, 0), raycastParams)

	if rayResult then return rayResult.Position.Y end
	return targetPosition.Y
end

------------------------------------------------
-- FUNGSI BANTUAN: VISUAL EFEK
------------------------------------------------
local function setEntityTransparency(entityModel, alpha)
	for _, part in pairs(entityModel:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") then
			if part.Name ~= "GhostRoot" then part.Transparency = alpha end
		elseif part:IsA("PointLight") then
			part.Brightness = (alpha == 1) and 0 or 3
		end
	end
end

local function fadeOutAndDestroy(entityModel, soundObj)
	if soundObj then TweenService:Create(soundObj, TweenInfo.new(1), {Volume = 0}):Play() end

	for _, part in pairs(entityModel:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") then
			if part.Name ~= "GhostRoot" then
				TweenService:Create(part, TweenInfo.new(1), {Transparency = 1}):Play()
			end
		elseif part:IsA("PointLight") then
			TweenService:Create(part, TweenInfo.new(1), {Brightness = 0}):Play()
		end
	end

	task.delay(1.5, function()
		if entityModel then entityModel:Destroy() end
		if soundObj then soundObj:Destroy() end
	end)
end

------------------------------------------------
-- FUNGSI BANTUAN: MEMBUAT ENTITAS POCONG
------------------------------------------------
local function createPocongEntity(playerRoot, offsetX, offsetZ, behavior, excludeList, activeTriggerBox)
	local template = pocongFolder:FindFirstChild("Pocong")
	if not template then return nil end

	local pocong = template:Clone()
	table.insert(excludeList, pocong)

	local modelCFrame, modelSize = pocong:GetBoundingBox()

	local rootPart = Instance.new("Part")
	rootPart.Name = "GhostRoot"
	rootPart.Size = Vector3.new(2, 5, 2)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Anchored = true 
	rootPart.CFrame = modelCFrame 
	rootPart.Parent = pocong
	pocong.PrimaryPart = rootPart

	for _, v in pairs(pocong:GetDescendants()) do
		if v:IsA("BasePart") and v ~= rootPart then
			v.Anchored = false
			v.CanCollide = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rootPart
			weld.Part1 = v
			weld.Parent = rootPart
		end
	end

	local headPart = pocong:FindFirstChild("Head") or pocong:FindFirstChild("head")
	local redLight = Instance.new("PointLight")
	redLight.Name = "PocongGlow"
	redLight.Color = Color3.fromRGB(255, 0, 0)
	redLight.Brightness = 3
	redLight.Range = 8
	redLight.Shadows = true

	if headPart then
		redLight.Parent = headPart
	else
		local lightAttachment = Instance.new("Attachment")
		lightAttachment.Position = Vector3.new(0, (modelSize.Y / 2) - 0.5, 0)
		lightAttachment.Parent = rootPart
		redLight.Parent = lightAttachment
	end

	local finalSpawnPos
	if activeTriggerBox then
		local rawSpawnCFrame = playerRoot.CFrame * CFrame.new(offsetX, 0, offsetZ)
		local clampedPos = clampPointToBox(rawSpawnCFrame.Position, activeTriggerBox)
		local groundY = getGroundY(clampedPos, activeTriggerBox, excludeList)
		finalSpawnPos = Vector3.new(clampedPos.X, groundY + (modelSize.Y / 2), clampedPos.Z)
	else
		local rawSpawnPos = (playerRoot.CFrame * CFrame.new(offsetX, 0, offsetZ)).Position
		local groundY = getGroundYTroll(rawSpawnPos, excludeList)
		finalSpawnPos = Vector3.new(rawSpawnPos.X, groundY + (modelSize.Y / 2), rawSpawnPos.Z)
	end

	pocong:PivotTo(CFrame.lookAt(finalSpawnPos, playerRoot.Position))
	pocong.Parent = workspace

	return {
		model = pocong,
		root = rootPart,
		behavior = behavior,
		active = true,
		heightOffset = modelSize.Y / 2
	}
end

------------------------------------------------
-- MAIN SERVER FUNCTION (NORMAL)
------------------------------------------------
local function spawnPocong(player, activeTriggerBox)
	task.wait(math.random(3, 7))
	if not player.Parent then debounce[player] = nil return end

	local char = player.Character
	if not char then debounce[player] = nil return end

	local playerRoot = char:FindFirstChild("HumanoidRootPart")
	if not playerRoot or not isInsideBox(playerRoot.Position, activeTriggerBox) then
		debounce[player] = nil 
		return 
	end

	local activeEntities = {}
	local excludeList = {char, activeTriggerBox, wsFolder} 
	local scenario = testMode and 1 or math.random(1, 5) 

	if scenario == 1 then
		table.insert(activeEntities, createPocongEntity(playerRoot, math.random(-5, 5), math.random(-35, -25), "CLASSIC", excludeList, activeTriggerBox))
	elseif scenario == 2 then
		table.insert(activeEntities, createPocongEntity(playerRoot, math.random(-5, 5), math.random(-35, -25), "BLINK_STRIKE", excludeList, activeTriggerBox))
	elseif scenario == 3 then
		table.insert(activeEntities, createPocongEntity(playerRoot, math.random(-15, -8), math.random(-35, -25), "STARE", excludeList, activeTriggerBox))
		table.insert(activeEntities, createPocongEntity(playerRoot, math.random(8, 15), math.random(-35, -25), "CHASE_FAST", excludeList, activeTriggerBox))
	elseif scenario == 4 then
		table.insert(activeEntities, createPocongEntity(playerRoot, math.random(-12, -5), math.random(-40, -30), "STARE", excludeList, activeTriggerBox))
		table.insert(activeEntities, createPocongEntity(playerRoot, math.random(5, 12), math.random(-40, -30), "STARE", excludeList, activeTriggerBox))
	elseif scenario == 5 then
		table.insert(activeEntities, createPocongEntity(playerRoot, math.random(-15, -10), math.random(-30, -20), "STARE", excludeList, activeTriggerBox))
		table.insert(activeEntities, createPocongEntity(playerRoot, math.random(10, 15), math.random(-30, -20), "CHASE_CREEP", excludeList, activeTriggerBox))
	end

	local bell
	if #activeEntities > 0 and activeEntities[1].root then
		bell = Instance.new("Sound")
		bell.SoundId = bellSoundId
		bell.Volume = 2
		bell.RollOffMaxDistance = 50
		bell.RollOffMinDistance = 5
		bell.Looped = true
		bell.Parent = activeEntities[1].root
		bell:Play()
	end

	task.wait(1.5)

	if not player.Parent then 
		debounce[player] = nil 
		for _, entity in ipairs(activeEntities) do if entity.model then entity.model:Destroy() end end
		return 
	end

	local hasBlink = false
	for _, entity in ipairs(activeEntities) do
		if entity.behavior == "BLINK_STRIKE" then
			hasBlink = true
			setEntityTransparency(entity.model, 1) 
			if bell then bell.Volume = 0.5 end 
		end
	end

	if hasBlink then
		task.wait(0.8) 
		if not player.Parent or not playerRoot then debounce[player] = nil return end

		for _, entity in ipairs(activeEntities) do
			if entity.behavior == "BLINK_STRIKE" then
				local tpPos = playerRoot.CFrame * CFrame.new(0, 0, -12)
				local clampedTp = clampPointToBox(tpPos.Position, activeTriggerBox)
				local groundTpY = getGroundY(clampedTp, activeTriggerBox, excludeList)
				local finalTp = Vector3.new(clampedTp.X, groundTpY + entity.heightOffset, clampedTp.Z)

				entity.root.CFrame = CFrame.lookAt(finalTp, playerRoot.Position)
				setEntityTransparency(entity.model, 0) 
				if bell then bell.Volume = 2 end
				entity.behavior = "CHASE_FAST" 
			end
		end
		task.wait(0.2) 
	end

	local chasing = true
	local gotJumpscared = false
	local fastSpeed = 18 
	local creepSpeed = 4 
	local catchDistance = 2.5 
	local maxTime = 12 
	local timeElapsed = 0

	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		-- KARINA FIX: Mencegah infinite yield/thread leak jika player mendadak mati/disconnect
		if not chasing or not player.Parent or not playerRoot or not playerRoot.Parent then 
			chasing = false
			return 
		end

		timeElapsed += deltaTime

		if not isInsideBox(playerRoot.Position, activeTriggerBox) or timeElapsed >= maxTime then
			chasing = false
			return
		end

		local allInactive = true
		for _, entity in ipairs(activeEntities) do
			if not entity.active or not entity.root then continue end
			allInactive = false

			local currentPos = entity.root.Position
			local targetPos = playerRoot.Position
			local dist = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(currentPos.X, 0, currentPos.Z)).Magnitude
			local lookVector = Vector3.new(targetPos.X - currentPos.X, 0, targetPos.Z - currentPos.Z).Unit
			local targetY = targetPos.Y + entity.heightOffset - 1

			if entity.behavior == "CHASE_FAST" or entity.behavior == "CLASSIC" then
				if dist <= catchDistance then
					chasing = false
					gotJumpscared = true
					return
				end
				local newPos = currentPos + (lookVector * fastSpeed * deltaTime)
				newPos = Vector3.new(newPos.X, currentPos.Y + (targetY - currentPos.Y) * deltaTime * 2, newPos.Z)
				local clampedMove = clampPointToBox(newPos, activeTriggerBox)
				entity.root.CFrame = CFrame.lookAt(clampedMove, Vector3.new(targetPos.X, clampedMove.Y, targetPos.Z))

			elseif entity.behavior == "CHASE_CREEP" then
				if dist <= catchDistance then
					entity.active = false
					fadeOutAndDestroy(entity.model, nil)
					continue
				end
				local newPos = currentPos + (lookVector * creepSpeed * deltaTime)
				newPos = Vector3.new(newPos.X, currentPos.Y + (targetY - currentPos.Y) * deltaTime * 2, newPos.Z)
				local clampedMove = clampPointToBox(newPos, activeTriggerBox)
				entity.root.CFrame = CFrame.lookAt(clampedMove, Vector3.new(targetPos.X, clampedMove.Y, targetPos.Z))

			elseif entity.behavior == "STARE" then
				entity.root.CFrame = CFrame.lookAt(currentPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z))
			end
		end
		if allInactive then chasing = false end
	end)

	while chasing do task.wait(0.1) end
	if connection then connection:Disconnect() end

	if gotJumpscared then
		if bell then bell:Stop() end
		for _, entity in ipairs(activeEntities) do
			if entity.model and entity.model.Parent then entity.model:Destroy() end
		end
		if player.Parent then scareEvent:FireClient(player) end
		task.delay(8, function() debounce[player] = nil end)
	else
		for _, entity in ipairs(activeEntities) do
			if entity.model and entity.model.Parent and entity.active then
				fadeOutAndDestroy(entity.model, bell)
				bell = nil 
			end
		end
		debounce[player] = nil
	end
end

------------------------------------------------
-- TROLL SYSTEM LOGIC
------------------------------------------------
local function executeTrollSpawn(targetPlayer)
	local char = targetPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local minRange = 15
	local maxRange = 35

	local randomAngle = math.random() * math.pi * 2
	local randomDist = math.random(minRange, maxRange)

	local offsetX = math.cos(randomAngle) * randomDist
	local offsetZ = math.sin(randomAngle) * randomDist

	local entity = createPocongEntity(root, offsetX, offsetZ, "CHASE_FAST", {char}, nil)
	if not entity then return end

	local bell = Instance.new("Sound")
	bell.SoundId = bellSoundId
	bell.Volume = 2
	bell.RollOffMaxDistance = 50
	bell.RollOffMinDistance = 5
	bell.Looped = true
	bell.Parent = entity.root
	bell:Play()

	local stareDuration = math.random(2, 5)
	task.wait(stareDuration)

	if not targetPlayer.Parent or not targetPlayer.Character or not root or not root.Parent then
		fadeOutAndDestroy(entity.model, bell)
		return
	end

	local chasing = true
	local connection

	connection = RunService.Heartbeat:Connect(function(deltaTime)
		-- KARINA FIX: Cegah thread leak
		if not chasing or not targetPlayer.Parent or not root or not root.Parent then
			chasing = false
			return
		end

		local targetPos = root.Position
		local currentPos = entity.root.Position
		local dist = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(currentPos.X, 0, currentPos.Z)).Magnitude
		local lookVector = Vector3.new(targetPos.X - currentPos.X, 0, targetPos.Z - currentPos.Z).Unit

		if dist <= 2.5 then
			chasing = false
			if bell then bell:Stop() end
			entity.model:Destroy()
			scareEvent:FireClient(targetPlayer)
			return
		end

		local newPos = currentPos + (lookVector * 18 * deltaTime)
		local targetY = targetPos.Y + entity.heightOffset - 1
		newPos = Vector3.new(newPos.X, currentPos.Y + (targetY - currentPos.Y) * deltaTime * 2, newPos.Z)

		entity.root.CFrame = CFrame.lookAt(newPos, Vector3.new(targetPos.X, newPos.Y, targetPos.Z))
	end)

	task.delay(20, function()
		if chasing then
			chasing = false
			fadeOutAndDestroy(entity.model, bell)
			if connection then connection:Disconnect() end
		end
	end)
end

local function getPlayerFromString(str)
	str = string.lower(str)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(string.sub(p.Name, 1, #str)) == str or string.lower(string.sub(p.DisplayName, 1, #str)) == str then
			return p
		end
	end
	return nil
end

local function onPlayerAdded(player)
	player.Chatted:Connect(function(message)
		if not player:GetAttribute("IsAdmin") then return end

		local args = string.split(message, " ")
		local command = string.lower(args[1])
		local targetName = args[2]

		if not targetName then return end

		local targetPlayer = getPlayerFromString(targetName)
		if not targetPlayer then return end

		if command == ";jumpscare" then
			scareEvent:FireClient(targetPlayer)
		elseif command == ";spawnpocong" then
			task.spawn(function()
				executeTrollSpawn(targetPlayer)
			end)
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

------------------------------------------------
-- AREA BOX DETECTOR
------------------------------------------------
task.spawn(function()
	while task.wait(0.5) do
		for _, player in ipairs(Players:GetPlayers()) do
			if debounce[player] then continue end

			local char = player.Character
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")

				if root then
					local activeTrigger = nil
					for _, box in ipairs(triggerBoxes) do
						if box.Parent and isInsideBox(root.Position, box) then
							activeTrigger = box
							break
						end
					end

					if activeTrigger then
						debounce[player] = true 

						local doSpawn = testMode
						if not testMode and (math.random() <= spawnChance) then
							doSpawn = true
						end

						if doSpawn then
							task.spawn(function() spawnPocong(player, activeTrigger) end)
						else
							task.delay(3, function() debounce[player] = nil end)
						end
					end
				end
			end
		end
	end
end)