--[[
    ALTITUDE DATA MANAGER V2.11 (CINEMATIC, SANITIZER, DEADLOCK FIX, & PLAYTIME INTEGRATION)
    Lokasi: ServerScriptService
    
    PERBAIKAN OLEH KARINA (V2.11):
    1. Menghapus LoadCharacter() paksa.
    2. Menyerahkan otoritas penempatan posisi spawn pertama kepada CinematicLoader.
    3. SANITIZER: Mencegah privilese Tool Admin tersimpan ke database secara permanen.
    4. HOTFIX: Memperbaiki DEADLOCK dengan CinematicLoader (menghapus WaitForChild Backpack).
    5. INTEGRASI: Memasukkan sistem PlayTime ke DataStore (Tersembunyi, bukan di Leaderstats).
    6. OPTIMASI: Loop PlayTime dimatikan total jika IS_BETA_ACTIVE bernilai false.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local BadgeService = game:GetService("BadgeService")

local PlayerData = DataStoreService:GetDataStore("AltitudeData_V2")

--// CONFIG PLAYTIME BADGE
local IS_BETA_ACTIVE = true -- [KARINA] Ubah ke false jika masa event Beta sudah selesai (Loop akan mati otomatis)
local TIME_REQUIRED = 300 -- [KARINA] 300 detik = 5 menit.
local BADGE_ID = 2616197412534465 -- GANTI dengan badge kamu

local DEFAULT_DATA = {
	Coins = 0,
	Summits = 0,
	Checkpoint = 0,
	SubCp = "",
	OwnedTools = {},
	OwnedPerks = {},
	ClaimedCodes = {},

	ActiveAura = "",
	ActiveTitle = "",

	PlayTime = 0 -- Data waktu bermain (Tersembunyi dari layar pemain)
}

----------------------------------------------------
-- FUNGSI MEMUAT DATA (SAAT PEMAIN JOIN)
----------------------------------------------------
local function LoadData(player)
	-- Folder leaderstats: Hanya yang ada di sini yang muncul di layar (pojok kanan atas)
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

	-- Item Leaderstats (Terlihat di layar)
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

	-- [KARINA] Waktu bermain diatur sebagai Attribute tersembunyi, bukan Leaderstats
	player:SetAttribute("PlayTime", data.PlayTime or 0)
	player:SetAttribute("PlayTimeBadgeAwarded", false)

	local toolsFolder = ServerStorage:FindFirstChild("Tools")
	if toolsFolder and data.OwnedTools then
		for _, toolName in pairs(data.OwnedTools) do
			local safeToolName = string.gsub(toolName, "%s+", "")
			player:SetAttribute("OwnsTool_" .. safeToolName, true) 
		end

		task.spawn(function()
			local starterGear = player:WaitForChild("StarterGear", 10)
			if starterGear then
				for _, toolName in pairs(data.OwnedTools) do
					local toolPrefab = toolsFolder:FindFirstChild(toolName)
					if toolPrefab and not starterGear:FindFirstChild(toolName) then
						toolPrefab:Clone().Parent = starterGear
					end
				end
			end
		end)
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
		ActiveTitle = player:GetAttribute("ActiveTitle") or "",

		PlayTime = player:GetAttribute("PlayTime") or 0 -- Simpan data waktu tersembunyi
	}

	local ls = player:FindFirstChild("leaderstats")
	local lsCoins = ls and ls:FindFirstChild("Coins")
	local lsSummits = ls and ls:FindFirstChild("Summits")
	local lsCp = ls and ls:FindFirstChild("Checkpoint")

	dataToSave.Coins = lsCoins and lsCoins.Value or 0
	dataToSave.Summits = lsSummits and lsSummits.Value or 0
	dataToSave.Checkpoint = lsCp and lsCp.Value or 0

	local starterGear = player:FindFirstChild("StarterGear")
	local isAdmin = player:GetAttribute("IsAdmin") == true

	if starterGear then
		for _, tool in pairs(starterGear:GetChildren()) do
			if tool:IsA("Tool") then
				if isAdmin and (tool.Name == "Umbrella" or tool.Name == "Speed Coil") then
					-- Lewati penyimpanannya
				else
					table.insert(dataToSave.OwnedTools, tool.Name)
				end
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
-- PLAYTIME TIMER & BADGE CHECKER
----------------------------------------------------
-- [KARINA] Loop ini HANYA akan diciptakan jika IS_BETA_ACTIVE = true.
-- Jika false, script ini sama sekali tidak memakan resource loop.
if IS_BETA_ACTIVE then
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				if player:GetAttribute("DataLoaded") then
					local currentPlayTime = (player:GetAttribute("PlayTime") or 0) + 1
					player:SetAttribute("PlayTime", currentPlayTime)

					if currentPlayTime >= TIME_REQUIRED and not player:GetAttribute("PlayTimeBadgeAwarded") then
						player:SetAttribute("PlayTimeBadgeAwarded", true)

						task.spawn(function()
							local success, hasBadge = pcall(function()
								return BadgeService:UserHasBadgeAsync(player.UserId, BADGE_ID)
							end)

							if success and not hasBadge then
								local awardSuccess = pcall(function()
									BadgeService:AwardBadge(player.UserId, BADGE_ID)
								end)
								if not awardSuccess then
									player:SetAttribute("PlayTimeBadgeAwarded", false)
								end
							end
						end)
					end
				end
			end
		end
	end)
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