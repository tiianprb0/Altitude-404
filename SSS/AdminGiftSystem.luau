local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage") 
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- [UPDATED]

-- KONFIGURASI DATASTORE
local JETSKI_DS_KEY = "JetskiWhitelist_v1"
local COIL_DS_KEY = "SpeedCoilWhitelist_v1"

-- ID GAMEPASS
local COIL_GAMEPASS_ID = 1607225038
local JETSKI_GAMEPASS_ID = 1601496975

-- KONFIGURASI ASET
local ASSETS_FOLDER_NAME = "VIP" 
local SPEED_COIL_NAME = "Speed Coil" 

local JetskiDataStore = DataStoreService:GetDataStore(JETSKI_DS_KEY)
local CoilDataStore = DataStoreService:GetDataStore(COIL_DS_KEY)

local ADMIN_LIST = {
	"tiianprb", 
}

-- [UPDATED] FUNGSI BROADCAST MENGGUNAKAN REMOTE EVENT
-- Pastikan kamu sudah membuat RemoteEvent "SystemMessageEvent" di ReplicatedStorage!
local function BroadcastSystemMessage(text: string)
	local remote = ReplicatedStorage:FindFirstChild("SystemMessageEvent")
	if remote then
		remote:FireAllClients(text) -- Kirim ke semua pemain agar muncul di chat mereka
	else
		warn("[ADMIN SYSTEM] RemoteEvent 'SystemMessageEvent' tidak ditemukan di ReplicatedStorage! Pesan tidak muncul di chat.")
		-- Buat otomatis kalau lupa (Safety Net)
		local newRemote = Instance.new("RemoteEvent")
		newRemote.Name = "SystemMessageEvent"
		newRemote.Parent = ReplicatedStorage
		newRemote:FireAllClients(text)
	end
	
	-- Tetap print di server console buat log admin
	print("[SYSTEM LOG] " .. text)
end

-- FUNGSI: BERIKAN TOOL KE PEMAIN
local function CheckAndGiveItems(player)
	local character = player.Character
	if not character then return end
	
	if player:GetAttribute("SpeedCoilAccess") == true then
		local backpack = player:FindFirstChild("Backpack")
		local assetsFolder = ServerStorage:FindFirstChild(ASSETS_FOLDER_NAME)
		
		if backpack and assetsFolder then
			if not backpack:FindFirstChild(SPEED_COIL_NAME) and not character:FindFirstChild(SPEED_COIL_NAME) then
				local coilTemplate = assetsFolder:FindFirstChild(SPEED_COIL_NAME)
				if coilTemplate then
					local newCoil = coilTemplate:Clone()
					newCoil.Parent = backpack
					print("[GIFT SYSTEM] Memberikan " .. SPEED_COIL_NAME .. " ke " .. player.Name)
				end
			end
		end
	end
end

-- FUNGSI: MEMBERSIHKAN INVENTORY GANDA (ANTI-CLASH)
local function SanitizeInventory(player)
	task.wait(1) 
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	local foundCoils = {}
	for _, item in pairs(backpack:GetChildren()) do
		if item:IsA("Tool") and item.Name == SPEED_COIL_NAME then
			table.insert(foundCoils, item)
		end
	end

	if player:GetAttribute("SpeedCoilAccess") ~= true then
		for _, tool in pairs(foundCoils) do tool:Destroy() end
		return
	end

	if #foundCoils > 1 then
		for i = 2, #foundCoils do foundCoils[i]:Destroy() end
	end
end

-- FUNGSI UTILITAS
local function isUserAdmin(player)
	if player.UserId == game.CreatorId then return true end
	for _, name in pairs(ADMIN_LIST) do
		if player.Name == name then return true end
	end
	return false
end

local function getUserIdFromUsername(username)
	local success, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)
	return success and userId or nil
end

local function OnAttributeChanged(player, attributeName)
	if attributeName == "SpeedCoilAccess" then
		if player:GetAttribute("SpeedCoilAccess") == true then
			CheckAndGiveItems(player) 
		else
			SanitizeInventory(player) 
		end
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if wasPurchased then
		if passId == COIL_GAMEPASS_ID then
			BroadcastSystemMessage(player.Name .. " baru saja membeli Speed Coil! 🎉")
			player:SetAttribute("SpeedCoilAccess", true) 
		elseif passId == JETSKI_GAMEPASS_ID then
			BroadcastSystemMessage(player.Name .. " baru saja menyewa Jetski VIP! 🚤")
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	local userIdStr = tostring(player.UserId)

	player.AttributeChanged:Connect(function(attr)
		OnAttributeChanged(player, attr)
	end)

	if isUserAdmin(player) then
		print("[ADMIN SYSTEM] Mengenali Owner/Admin: " .. player.Name)
		player:SetAttribute("SpeedCoilAccess", true) 
		player:SetAttribute("JetskiExpiry", -1)      
	else
		task.spawn(function()
			local successCoil, coilData = pcall(function() return CoilDataStore:GetAsync(userIdStr) end)
			if successCoil and coilData then
				if coilData == true then 
					player:SetAttribute("SpeedCoilAccess", true)
				elseif type(coilData) == "table" and coilData.Expiry then 
					if coilData.Expiry == -1 or os.time() < coilData.Expiry then
						player:SetAttribute("SpeedCoilAccess", true)
					else
						CoilDataStore:RemoveAsync(userIdStr)
					end
				end
			end
		end)

		task.spawn(function()
			local successJet, jetData = pcall(function() return JetskiDataStore:GetAsync(userIdStr) end)
			if successJet and jetData and jetData.Expiry then
				if jetData.Expiry == -1 or os.time() < jetData.Expiry then
					player:SetAttribute("JetskiExpiry", jetData.Expiry)
				else
					JetskiDataStore:RemoveAsync(userIdStr)
				end
			end
		end)
	end

	player.CharacterAdded:Connect(function(character)
		SanitizeInventory(player) 
		CheckAndGiveItems(player) 
	end)

	player.Chatted:Connect(function(msg)
		if not isUserAdmin(player) then return end

		local args = msg:split(" ")
		local cmd = args[1]:lower()

		if cmd == ";giftjetski" or cmd == ";givejetski" then
			local days = tonumber(args[2])
			local targetName = days and args[3] or args[2] 

			if targetName then
				local targetId = getUserIdFromUsername(targetName)
				if targetId then
					local expiryTime = days and (os.time() + (days * 86400)) or -1
					pcall(function()
						JetskiDataStore:SetAsync(tostring(targetId), {Expiry = expiryTime, Gifter = player.Name})
					end)
					local targetPlayer = Players:GetPlayerByUserId(targetId)
					if targetPlayer then targetPlayer:SetAttribute("JetskiExpiry", expiryTime) end

					local durasi = days and (days .. " hari") or "Permanen"
					BroadcastSystemMessage("Admin memberikan akses Jetski kepada " .. targetName .. " (" .. durasi .. ")! 🚤")
				end
			end

		elseif cmd == ";removejetski" then
			local targetName = args[2]
			local targetId = getUserIdFromUsername(targetName)
			if targetId then
				JetskiDataStore:RemoveAsync(tostring(targetId))
				local targetPlayer = Players:GetPlayerByUserId(targetId)
				if targetPlayer then targetPlayer:SetAttribute("JetskiExpiry", nil) end
				BroadcastSystemMessage("Akses Jetski " .. targetName .. " telah dicabut oleh Admin.")
			end

		elseif cmd == ";giftcoil" or cmd == ";givecoil" then
			local days = tonumber(args[2])
			local targetName = days and args[3] or args[2]

			if targetName then
				local targetId = getUserIdFromUsername(targetName)
				if targetId then
					local expiryTime = days and (os.time() + (days * 86400)) or -1
					pcall(function()
						CoilDataStore:SetAsync(tostring(targetId), {Expiry = expiryTime, Gifter = player.Name})
					end)
					local targetPlayer = Players:GetPlayerByUserId(targetId)
					if targetPlayer then targetPlayer:SetAttribute("SpeedCoilAccess", true) end

					local durasi = days and (days .. " hari") or "Permanen"
					BroadcastSystemMessage("⚡ Admin memberikan Speed Coil kepada " .. targetName .. " (" .. durasi .. ")! ⚡")
				end
			end

		elseif cmd == ";removecoil" then
			local targetName = args[2]
			local targetId = getUserIdFromUsername(targetName)
			if targetId then
				CoilDataStore:RemoveAsync(tostring(targetId))
				local targetPlayer = Players:GetPlayerByUserId(targetId)
				if targetPlayer then targetPlayer:SetAttribute("SpeedCoilAccess", nil) end
				BroadcastSystemMessage("Akses Speed Coil " .. targetName .. " telah dicabut oleh Admin.")
			end
		end
	end)
end)