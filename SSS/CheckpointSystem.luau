-- ServerScriptService > CheckpointSystem
-- Direvisi oleh Karina & Diperbarui oleh ECA
-- Update: Database dilucuti. Sepenuhnya bergantung pada AltitudeDataManager.
-- Update: Penambahan logika Bonus x2 Koin khusus untuk pengguna VIP.
-- Update: Penambahan Fall Debounce & Fallback Spawn Teleport.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- KONFIGURASI
local SUMMIT_REWARD = 1
local COIN_REWARD_AMOUNT = 1000
local CHECKPOINT_SOUND_ID = "rbxassetid://134378204516784"
local FALL_DEBOUNCE_TIME = 1 -- Detik jeda saat jatuh

local checkpointEvent = ReplicatedStorage:FindFirstChild("CheckpointEvent")
if not checkpointEvent then
	checkpointEvent = Instance.new("RemoteEvent")
	checkpointEvent.Name = "CheckpointEvent"
	checkpointEvent.Parent = ReplicatedStorage
end

----------------------------------------------------
-- SETUP CHECKPOINT PARTS (MENDUKUNG BERCABANG)   --
----------------------------------------------------
local checkpointsFolder = workspace:WaitForChild("Checkpoints")
local checkpointParts = {}

for _, obj in ipairs(checkpointsFolder:GetChildren()) do
	local orderVal = obj:FindFirstChild("Order")
	if orderVal then
		local orderNum = tonumber(orderVal.Value) 
		if orderNum then
			local touchPart = obj
			if obj:IsA("Model") then
				touchPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
			end

			if touchPart and touchPart:IsA("BasePart") then
				if not checkpointParts[orderNum] then
					checkpointParts[orderNum] = {} 
				end
				table.insert(checkpointParts[orderNum], {
					ObjectName = obj.Name,
					Part = touchPart,
					CFrame = touchPart.CFrame
				}) 
			end
		end
	end
end

----------------------------------------------------
-- TELEPORT & VISUAL                              --
----------------------------------------------------
local originalColors = {}

local function flashCheckpointColor(part)
	if not part or not part:IsA("BasePart") then return end
	if not originalColors[part] then originalColors[part] = part.Color end
	part.Color = Color3.fromRGB(255, 182, 193) 
	task.delay(3, function()
		if part and part.Parent then part.Color = originalColors[part] end
	end)
end

local function teleportToCheckpoint(player)
	local char = player.Character
	if not char then return end
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	local cpValue = player:FindFirstChild("Checkpoint")
	if not cpValue then return end

	local targetParts = checkpointParts[cpValue.Value]
	local targetCFrame

	-- Cek apakah data checkpoint tersedia, jika tidak maka gunakan sistem fallback (Cadangan)
	if targetParts and #targetParts > 0 then
		local targetInfo = targetParts[1] 
		local subCpName = player:GetAttribute("SubCp")

		if subCpName and subCpName ~= "" then
			for _, info in ipairs(targetParts) do
				if info.ObjectName == subCpName then
					targetInfo = info
					break
				end
			end
		end
		targetCFrame = targetInfo.CFrame + Vector3.new(0, 5, 0)
	else
		-- SISTEM FALLBACK: Teleportasi ke Base/SpawnLocation jika belum punya checkpoint
		local spawnLoc = workspace:FindFirstChild("SpawnLocation") 

		-- Jika SpawnLocation tidak ada, coba ambil checkpoint 0 atau 1 sebagai tempat fallback
		if not spawnLoc and checkpointParts[0] then spawnLoc = checkpointParts[0][1].Part end 
		if not spawnLoc and checkpointParts[1] then spawnLoc = checkpointParts[1][1].Part end 

		if spawnLoc then
			targetCFrame = spawnLoc.CFrame + Vector3.new(0, 5, 0)
		else
			-- Fallback absolut jika semua referensi hilang
			targetCFrame = CFrame.new(0, 10, 0)
		end
	end

	-- Reset velocity agar momentum jatuh tidak membuat karakter terlempar (fling) setelah teleport
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	char:PivotTo(targetCFrame)
end

----------------------------------------------------
-- EVENT PLAYER JOIN                              --
----------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5) 

		-- Menunggu DataManager selesai me-load data sebelum melakukan teleport (Dilengkapi Timeout)
		local timeout = 0
		while not player:GetAttribute("DataLoaded") and timeout < 100 do
			task.wait(0.1)
			timeout = timeout + 1
			if not player.Parent then return end -- Pemain keburu leave
		end

		local checkpointVal = player:FindFirstChild("Checkpoint")
		if checkpointVal and checkpointVal.Value > 0 then
			teleportToCheckpoint(player)
		end
	end)
end)

----------------------------------------------------
-- LOGIKA SENTUH PART (Gameplay)                  --
----------------------------------------------------
local debounceCache = {} 

local function connectCheckpoint(info, order)
	info.Part.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player then return end

		-- Abaikan jika data belum dimuat oleh DataManager
		if not player:GetAttribute("DataLoaded") then return end

		if debounceCache[player.UserId] and tick() - debounceCache[player.UserId] < 0.5 then
			return
		end
		debounceCache[player.UserId] = tick()

		local cpVal = player:FindFirstChild("Checkpoint")
		local sumVal = player:FindFirstChild("Summits")
		local coinsVal = player:FindFirstChild("Coins")

		if not cpVal or not sumVal or not coinsVal then return end

		local oldCp = cpVal.Value
		local lastSubCp = player:GetAttribute("SubCp")

		local isDifferentPart = (info.ObjectName ~= lastSubCp)

		if order > oldCp or (order == oldCp and isDifferentPart) then
			if order > oldCp then
				cpVal.Value = order

				if string.match(info.ObjectName, "Summit") then
					sumVal.Value = sumVal.Value + SUMMIT_REWARD

					-- [KARINA] Logika x2 Koin untuk VIP
					local finalCoinReward = COIN_REWARD_AMOUNT
					if player:GetAttribute("HasVIP") then
						finalCoinReward = finalCoinReward * 2
					end

					coinsVal.Value = coinsVal.Value + finalCoinReward
					checkpointEvent:FireClient(player, "Summit Tercapai!", "+Rp" .. finalCoinReward, CHECKPOINT_SOUND_ID)
				else
					checkpointEvent:FireClient(player, "Checkpoint " .. order, "", CHECKPOINT_SOUND_ID)
				end
			elseif order == oldCp and isDifferentPart then
				checkpointEvent:FireClient(player, "Jalur Diperbarui", "", CHECKPOINT_SOUND_ID)
			end

			player:SetAttribute("SubCp", info.ObjectName)
			flashCheckpointColor(info.Part)
		end
	end)
end

for order, partsList in pairs(checkpointParts) do
	for _, info in ipairs(partsList) do
		connectCheckpoint(info, order)
	end
end

----------------------------------------------------
-- FITUR TAMBAHAN (Reset & Fall)                  --
----------------------------------------------------
local returnPart = checkpointsFolder:FindFirstChild("ReturnToCamp")
if returnPart then
	returnPart.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)

		if player and player:FindFirstChild("Checkpoint") and player.Character then
			player.Checkpoint.Value = 0 
			player:SetAttribute("SubCp", nil)
			checkpointEvent:FireClient(player, "Kembali ke Base", "")

			local targetCFrame = CFrame.new(0, 10, 0)
			local spawnLoc = workspace:FindFirstChild("SpawnLocation") 

			if not spawnLoc and checkpointParts[0] then spawnLoc = checkpointParts[0][1].Part end 
			if not spawnLoc and checkpointParts[1] then spawnLoc = checkpointParts[1][1].Part end 

			if spawnLoc then
				targetCFrame = spawnLoc.CFrame + Vector3.new(0, 5, 0)
			end

			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end

			player.Character:PivotTo(targetCFrame)
		end
	end)
end

-- Sistem Fall Zones yang telah ditambahkan Debounce
local fallDebounceCache = {}
local fallFolder = workspace:FindFirstChild("FallZones")
if fallFolder then
	for _, part in ipairs(fallFolder:GetChildren()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if player and player:GetAttribute("DataLoaded") then

					-- Mencegah spam event saat R15 jatuh menabrak part
					if fallDebounceCache[player.UserId] and tick() - fallDebounceCache[player.UserId] < FALL_DEBOUNCE_TIME then
						return
					end
					fallDebounceCache[player.UserId] = tick()

					teleportToCheckpoint(player)
				end
			end)
		end
	end
end

----------------------------------------------------
-- PEMBERSIHAN MEMORI (MEMORY LEAK PREVENTION)    --
----------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	-- Menghapus data cache pemain yang keluar agar tidak menumpuk di memori server
	if debounceCache[player.UserId] then
		debounceCache[player.UserId] = nil
	end
	if fallDebounceCache[player.UserId] then
		fallDebounceCache[player.UserId] = nil
	end
end)