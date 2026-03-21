--[[
    ALTITUDE DATA MANAGER V2.5 (KARINA STRING SANITIZER HOTFIX)
    Lokasi: ServerScriptService
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local PlayerData = DataStoreService:GetDataStore("AltitudeData_V2")

local DEFAULT_DATA = {
	Coins = 0,
	Summits = 0,
	Checkpoint = 0,
	SubCp = "",
	OwnedTools = {},
	OwnedPerks = {},
	ClaimedCodes = {},

	ActiveAura = "",
	ActiveTitle = ""
}

----------------------------------------------------
-- FUNGSI MEMUAT DATA (SAAT PEMAIN JOIN)
----------------------------------------------------
local function LoadData(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local success, data
	local retries = 3

	repeat
		success, data = pcall(function()
			return PlayerData:GetAsync(tostring(player.UserId))
		end)
		if not success then task.wait(1) end
		retries = retries - 1
	until success or retries == 0

	if not success then
		warn("[ALTITUDE DATA] CRITICAL ERROR: Gagal memuat data untuk " .. player.Name)
		player:Kick("\nAltitude System ⚠️\n\nGagal memuat datamu karena gangguan server Roblox.\nMohon rejoin ulang agar data lamamu tidak hilang.")
		return
	end

	data = data or DEFAULT_DATA

	local coins = Instance.new("NumberValue")
	coins.Name = "Coins"
	coins.Value = data.Coins or DEFAULT_DATA.Coins
	coins.Parent = leaderstats

	local summits = Instance.new("IntValue")
	summits.Name = "Summits"
	summits.Value = data.Summits or DEFAULT_DATA.Summits
	summits.Parent = leaderstats

	local checkpoint = Instance.new("IntValue")
	checkpoint.Name = "Checkpoint"
	checkpoint.Value = data.Checkpoint or DEFAULT_DATA.Checkpoint
	checkpoint.Parent = leaderstats

	local pCoins = coins:Clone()
	pCoins.Parent = player
	local pSummits = summits:Clone()
	pSummits.Parent = player
	local pCheckpoint = checkpoint:Clone()
	pCheckpoint.Parent = player

	pCoins.Changed:Connect(function(val) if coins.Value ~= val then coins.Value = val end end)
	coins.Changed:Connect(function(val) if pCoins.Value ~= val then pCoins.Value = val end end)

	pSummits.Changed:Connect(function(val) if summits.Value ~= val then summits.Value = val end end)
	summits.Changed:Connect(function(val) if pSummits.Value ~= val then pSummits.Value = val end end)

	pCheckpoint.Changed:Connect(function(val) if checkpoint.Value ~= val then checkpoint.Value = val end end)
	checkpoint.Changed:Connect(function(val) if pCheckpoint.Value ~= val then pCheckpoint.Value = val end end)

	if data.SubCp then player:SetAttribute("SubCp", data.SubCp) end
	if data.ActiveAura then player:SetAttribute("ActiveAura", data.ActiveAura) else player:SetAttribute("ActiveAura", "") end
	if data.ActiveTitle then player:SetAttribute("ActiveTitle", data.ActiveTitle) else player:SetAttribute("ActiveTitle", "") end

	local toolsFolder = ServerStorage:FindFirstChild("Tools")
	if toolsFolder and data.OwnedTools then
		for _, toolName in pairs(data.OwnedTools) do
			local toolPrefab = toolsFolder:FindFirstChild(toolName)
			if toolPrefab then
				toolPrefab:Clone().Parent = player:WaitForChild("Backpack")
				toolPrefab:Clone().Parent = player:WaitForChild("StarterGear")

				-- [KARINA FIX] Hapus spasi dari nama tool agar Roblox Attribute tidak crash
				local safeToolName = string.gsub(toolName, "%s+", "")
				player:SetAttribute("OwnsTool_" .. safeToolName, true) 
			end
		end
	end

	if data.OwnedPerks then
		for _, perkName in pairs(data.OwnedPerks) do
			player:SetAttribute(perkName, true)
		end
	end

	if data.ClaimedCodes then
		for _, code in pairs(data.ClaimedCodes) do
			player:SetAttribute("ClaimedCode_" .. code, true)
		end
	end

	player:SetAttribute("DataLoaded", true)
	print("[ALTITUDE DATA] Data berhasil dimuat untuk " .. player.Name)
end

----------------------------------------------------
-- FUNGSI MENYIMPAN DATA (SAAT PEMAIN LEAVE)
----------------------------------------------------
local function SaveData(player)
	if not player:GetAttribute("DataLoaded") then 
		warn("[ALTITUDE DATA] Data " .. player.Name .. " dilewati karena tidak ada status DataLoaded.")
		return false
	end

	local dataToSave = {
		Coins = 0,
		Summits = 0,
		Checkpoint = 0,
		SubCp = player:GetAttribute("SubCp") or "",
		OwnedTools = {},
		OwnedPerks = {},
		ClaimedCodes = {},

		ActiveAura = player:GetAttribute("ActiveAura") or "",
		ActiveTitle = player:GetAttribute("ActiveTitle") or ""
	}

	local ls = player:FindFirstChild("leaderstats")
	local lsCoins = ls and ls:FindFirstChild("Coins")
	local lsSummits = ls and ls:FindFirstChild("Summits")
	local lsCp = ls and ls:FindFirstChild("Checkpoint")

	dataToSave.Coins = lsCoins and lsCoins.Value or 0
	dataToSave.Summits = lsSummits and lsSummits.Value or 0
	dataToSave.Checkpoint = lsCp and lsCp.Value or 0

	local starterGear = player:FindFirstChild("StarterGear")
	if starterGear then
		for _, tool in pairs(starterGear:GetChildren()) do
			if tool:IsA("Tool") then
				table.insert(dataToSave.OwnedTools, tool.Name)
			end
		end
	end

	for attrName, attrValue in pairs(player:GetAttributes()) do
		if attrValue == true then
			if string.sub(attrName, 1, 3) == "Has" then
				table.insert(dataToSave.OwnedPerks, attrName)
			elseif string.sub(attrName, 1, 12) == "ClaimedCode_" then
				local codeOnly = string.sub(attrName, 13)
				table.insert(dataToSave.ClaimedCodes, codeOnly)
			end
		end
	end

	local success, err
	local retries = 3

	repeat
		success, err = pcall(function()
			PlayerData:SetAsync(tostring(player.UserId), dataToSave)
		end)
		if not success then task.wait(1) end
		retries = retries - 1
	until success or retries == 0

	if success then
		print("[ALTITUDE DATA] Data berhasil disimpan untuk " .. player.Name)
		return true
	else
		warn("[ALTITUDE DATA] FATAL: Gagal menyimpan data " .. player.Name .. " - " .. tostring(err))
		return false
	end
end

----------------------------------------------------
-- EVENTS BINDING
----------------------------------------------------
Players.PlayerAdded:Connect(LoadData)

Players.PlayerRemoving:Connect(function(player)
	SaveData(player)
end)

game:BindToClose(function()
	print("[ALTITUDE DATA] Server ditutup. Menyimpan semua data pemain...")
	local activePlayers = Players:GetPlayers()
	local totalPlayers = #activePlayers
	local savedCount = 0

	for _, player in ipairs(activePlayers) do
		task.spawn(function()
			SaveData(player)
			savedCount = savedCount + 1
		end)
	end

	local timeout = RunService:IsStudio() and 5 or 25 
	local elapsedTime = 0

	while savedCount < totalPlayers and elapsedTime < timeout do
		task.wait(1)
		elapsedTime = elapsedTime + 1
	end

	print(string.format("[ALTITUDE DATA] Selesai menyimpan %d/%d data pemain sebelum shutdown.", savedCount, totalPlayers))
end)