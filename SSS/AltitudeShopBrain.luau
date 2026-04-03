--[[
    ALTITUDE SHOP BRAIN (SERVER LOGIC) V4
    Lokasi: ServerScriptService
    
    PERBAIKAN OLEH KARINA:
    1. Sinkronisasi SOP Atribut 'OwnsTool_'.
    2. String Sanitizer pada pemberian tool.
    3. [SECURITY] Anti-Spam Race Condition pada Redeem Code.
    4. [SECURITY] Validasi angka absolut (mencegah input negatif/math.huge).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local SHOP_DATABASE = {
	-- [DEV PRODUCTS: CREDITS]
	["C1"] = {PayType = "Robux", RobuxID = 3558143560, IsDevProduct = true, ActionType = "Currency", Value = 5000, Name = "5.000 Coins"},
	["C2"] = {PayType = "Robux", RobuxID = 3558144127, IsDevProduct = true, ActionType = "Currency", Value = 10000, Name = "10.000 Coins"},
	["C3"] = {PayType = "Robux", RobuxID = 3558144632, IsDevProduct = true, ActionType = "Currency", Value = 25000, Name = "25.000 Coins"},
	["C4"] = {PayType = "Robux", RobuxID = 3558145100, IsDevProduct = true, ActionType = "Currency", Value = 50000, Name = "50.000 Coins"},
	["C5"] = {PayType = "Robux", RobuxID = 3558145329, IsDevProduct = true, ActionType = "Currency", Value = 100000, Name = "100.000 Coins"},
	["C6"] = {PayType = "Robux", RobuxID = 3558145704, IsDevProduct = true, ActionType = "Currency", Value = 500000, Name = "500.000 Coins"},

	-- [TOOLS & PERKS]
	["T1"] = {PayType = "Coins", Price = 5000, ActionType = "Tool", Name = "Umbrella"},
	["T2"] = {PayType = "Robux", RobuxID = 3559900223, IsDevProduct = true, ActionType = "Tool", Name = "Speed Coil"}, 

	["A2"] = {PayType = "Robux", RobuxID = 3559900642, IsDevProduct = true, ActionType = "Perk", AttributeName = "HasVIP", Name = "VIP Access"},
	["P_HA"] = {PayType = "Coins", Price = 100000, ActionType = "Perk", AttributeName = "HasHideAura", Name = "Hide Aura"},

	-- [KENDARAAN YARRA RENTAL]
	["V_JS"] = {PayType = "Coins", Price = 100000, ActionType = "Perk", AttributeName = "HasJetSolo", Name = "JetSolo Access"},

	-- [AURAS]
	["A_CH"] = {PayType = "Coins", Price = 35000, ActionType = "Perk", AttributeName = "HasChained", Name = "Chained Aura"},
	["A_CO"] = {PayType = "Coins", Price = 1500, ActionType = "Perk", AttributeName = "HasCosmic", Name = "Cosmic Aura"},
	["A_CU"] = {PayType = "Coins", Price = 35000, ActionType = "Perk", AttributeName = "HasCubic", Name = "Cubic Aura"},
	["A_DS"] = {PayType = "Robux", RobuxID = 3559898227, IsDevProduct = true, ActionType = "Perk", AttributeName = "HasDualSwords", Name = "Dual Swords"},
	["A_FR"] = {PayType = "Robux", RobuxID = 3559898538, IsDevProduct = true, ActionType = "Perk", AttributeName = "HasFrost", Name = "Frost Aura"},
	["A_LO"] = {PayType = "Coins", Price = 10000, ActionType = "Perk", AttributeName = "HasLove", Name = "Love Aura"},
	["A_PO"] = {PayType = "Coins", Price = 75000, ActionType = "Perk", AttributeName = "HasPoison", Name = "Poison Aura"},
	["A_PL"] = {PayType = "Robux", RobuxID = 3559899136, IsDevProduct = true, ActionType = "Perk", AttributeName = "HasPowerless", Name = "Powerless"},
	["A_SD"] = {PayType = "Coins", Price = 100000, ActionType = "Perk", AttributeName = "HasSandDemon", Name = "Sand Demon"},
	["A_SN"] = {PayType = "Coins", Price = 100000, ActionType = "Perk", AttributeName = "HasSoundNinja", Name = "Sound Ninja"},
	["A_TG"] = {PayType = "Coins", Price = 125000, ActionType = "Perk", AttributeName = "HasThunderGod", Name = "Thunder God"},
}

local REDEEM_CODES = {
	["WELCOME"] = {Type = "Coin", Value = 5000, Quantity = 15, Expiry = "2026-03-25"},
}

-- [KARINA FIX] Sistem Anti-Spam untuk mencegah Race Condition eksploit
local activeRedeems = {}

local ShopRemote = ReplicatedStorage:FindFirstChild("ShopRemote") or Instance.new("RemoteEvent", ReplicatedStorage)
ShopRemote.Name = "ShopRemote"
local GiftRemote = ReplicatedStorage:FindFirstChild("GiftRemote") or Instance.new("RemoteEvent", ReplicatedStorage)
GiftRemote.Name = "GiftRemote"
local RedeemRemote = ReplicatedStorage:FindFirstChild("RedeemRemote") or Instance.new("RemoteEvent", ReplicatedStorage)
RedeemRemote.Name = "RedeemRemote"
local RedeemResult = ReplicatedStorage:FindFirstChild("RedeemResult") or Instance.new("RemoteEvent", ReplicatedStorage)
RedeemResult.Name = "RedeemResult"

local GlobalChatBroadcast = ReplicatedStorage:FindFirstChild("GlobalChatBroadcast") or Instance.new("RemoteEvent", ReplicatedStorage)
GlobalChatBroadcast.Name = "GlobalChatBroadcast"

local ToolsFolder = ServerStorage:FindFirstChild("Tools")

local function logActivity(adminName, deskripsi)
	local logEvent = ServerStorage:FindFirstChild("KarinaLogEvent")
	if logEvent then logEvent:Fire(adminName, deskripsi) end
end

local function FormatNumber(n)
	local formatted = tostring(n)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
		if k == 0 then break end
	end
	return formatted
end

local function HasItem(player, data)
	if data.ActionType == "Currency" then 
		return false
	elseif data.ActionType == "Tool" then
		local safeName = string.gsub(data.Name, "%s+", "")
		if player:GetAttribute("OwnsTool_" .. safeName) then return true end

		if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild(data.Name) then return true end
		if player:FindFirstChild("StarterGear") and player.StarterGear:FindFirstChild(data.Name) then return true end
		return false
	elseif data.ActionType == "Perk" then
		return player:GetAttribute(data.AttributeName) == true
	end
	return false
end

local function GiveItem(player, data)
	if data.ActionType == "Currency" then
		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Coins") then
			ls.Coins.Value = ls.Coins.Value + data.Value
		end
	elseif data.ActionType == "Tool" then
		if ToolsFolder then
			local tool = ToolsFolder:FindFirstChild(data.Name)
			if tool and tool:IsA("Tool") then
				local safeName = string.gsub(data.Name, "%s+", "")
				player:SetAttribute("OwnsTool_" .. safeName, true)

				tool:Clone().Parent = player:FindFirstChild("Backpack")
				local starterGear = player:FindFirstChild("StarterGear")
				if starterGear then tool:Clone().Parent = starterGear end

				if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
					tool:Clone().Parent = player.Character
				end
			end
		end
	elseif data.ActionType == "Perk" then
		player:SetAttribute(data.AttributeName, true)
		if data.AttributeName == "HasVIP" then
			local ls = player:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Coins") then
				ls.Coins.Value = ls.Coins.Value + 10000
			end
		end
	end
end

ShopRemote.OnServerEvent:Connect(function(player, itemID)
	if not player:GetAttribute("DataLoaded") then return end

	if itemID == "EXCHANGE_SUMMIT" then
		local ls = player:FindFirstChild("leaderstats")
		local summits = ls and ls:FindFirstChild("Summits")
		local coins = ls and ls:FindFirstChild("Coins")

		if summits and coins then
			if summits.Value > 0 then
				local exchangeAmount = summits.Value * 500
				local sVal = summits.Value
				summits.Value = 0
				coins.Value = coins.Value + exchangeAmount
				RedeemResult:FireClient(player, "Berhasil menukar Summit menjadi " .. FormatNumber(exchangeAmount) .. " Coins!", true, "BuyCoin")
				logActivity(player.Name, "Menukar " .. tostring(sVal) .. " Summit menjadi " .. FormatNumber(exchangeAmount) .. " Coins")
			else
				RedeemResult:FireClient(player, "Kamu belum memiliki Summit untuk ditukar!", false)
			end
		end
		return
	end

	local data = SHOP_DATABASE[itemID]
	if not data then return end

	if HasItem(player, data) then
		RedeemResult:FireClient(player, "Kamu sudah memiliki item ini!", false)
		return
	end

	if data.PayType == "Robux" then
		if data.IsDevProduct then MarketplaceService:PromptProductPurchase(player, data.RobuxID)
		else MarketplaceService:PromptGamePassPurchase(player, data.RobuxID) end
	elseif data.PayType == "Coins" then
		local ls = player:FindFirstChild("leaderstats")
		local coins = ls and ls:FindFirstChild("Coins")

		if coins and coins.Value >= data.Price then
			coins.Value = coins.Value - data.Price
			GiveItem(player, data)
			RedeemResult:FireClient(player, "Berhasil membeli " .. data.Name, true, "BuyItem")
			logActivity(player.Name, "Membeli " .. data.Name .. " seharga " .. FormatNumber(data.Price) .. " Coins")
		else
			RedeemResult:FireClient(player, "Uang tidak cukup!", false)
		end
	end
end)

GiftRemote.OnServerEvent:Connect(function(player, itemID, targetName)
	if not player:GetAttribute("DataLoaded") then return end

	local data = SHOP_DATABASE[itemID]
	local target = Players:FindFirstChild(targetName)
	if not data or not target or target == player then return end
	if not target:GetAttribute("DataLoaded") then return end

	local senderLevel = player:GetAttribute("RankLevel") or 0
	local targetLevel = target:GetAttribute("RankLevel") or 0
	if targetLevel == 4 and senderLevel < 4 then
		RedeemResult:FireClient(player, "❌ Ditolak: Tidak bisa memberikan gift ke Owner.", false)
		return
	end

	if HasItem(target, data) then return end

	if data.PayType == "Robux" then
		player:SetAttribute("GiftingTo", target.Name) 
		if data.IsDevProduct then MarketplaceService:PromptProductPurchase(player, data.RobuxID)
		else MarketplaceService:PromptGamePassPurchase(player, data.RobuxID) end
	elseif data.PayType == "Coins" then
		local ls = player:FindFirstChild("leaderstats")
		local senderCoins = ls and ls:FindFirstChild("Coins")
		if senderCoins and senderCoins.Value >= data.Price then
			senderCoins.Value = senderCoins.Value - data.Price
			GiveItem(target, data) 
			RedeemResult:FireClient(player, "Berhasil kado ke " .. target.Name, true, "BuyItem")

			local msg = string.format("<font color='#F7ADAF'>[GIFT]</font> <b>%s</b> memberikan <b>%s</b> kepada <b>%s</b>!", player.DisplayName, data.Name, target.DisplayName)
			GlobalChatBroadcast:FireAllClients(msg)

			logActivity(player.Name, "Membelikan Gift (" .. data.Name .. ") kepada " .. target.Name)
		else
			RedeemResult:FireClient(player, "Uang tidak cukup untuk gift!", false)
		end
	end
end)

RedeemRemote.OnServerEvent:Connect(function(player, code)
	if not player:GetAttribute("DataLoaded") then return end

	-- [KARINA FIX] Jika player sedang diproses, tolak permintaan untuk mencegah Race Condition
	if activeRedeems[player.UserId] then return end
	activeRedeems[player.UserId] = true

	code = string.upper(code) 
	local codeData = REDEEM_CODES[code]

	if not codeData then 
		activeRedeems[player.UserId] = nil
		return 
	end

	if player:GetAttribute("ClaimedCode_" .. code) or codeData.Quantity <= 0 then 
		activeRedeems[player.UserId] = nil
		return 
	end

	-- Menanamkan atribut SEGERA sebelum proses apa pun berjalan
	player:SetAttribute("ClaimedCode_" .. code, true)
	codeData.Quantity = codeData.Quantity - 1

	if codeData.Type == "Coin" then
		local ls = player:FindFirstChild("leaderstats")
		local coins = ls and ls:FindFirstChild("Coins")
		if coins then
			coins.Value = coins.Value + codeData.Value
			RedeemResult:FireClient(player, "Berhasil klaim " .. FormatNumber(codeData.Value) .. " Coins!", true, "Redeem")
			logActivity(player.Name, "Klaim Kode Promo '" .. code .. "' (" .. FormatNumber(codeData.Value) .. " Coins)")
		end
	end

	-- Selesai diproses, buka kembali jalur untuk player ini
	activeRedeems[player.UserId] = nil
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gId, purchased)
	local giftTargetName = player:GetAttribute("GiftingTo")
	player:SetAttribute("GiftingTo", nil) 

	if purchased then
		local receiver = (giftTargetName and Players:FindFirstChild(giftTargetName)) or player
		for _, data in pairs(SHOP_DATABASE) do
			if data.PayType == "Robux" and not data.IsDevProduct and data.RobuxID == gId then
				GiveItem(receiver, data)
				RedeemResult:FireClient(player, "Transaksi berhasil diproses!", true, "BuyItem")

				if giftTargetName and receiver then
					local msg = string.format("<font color='#F7ADAF'>[GIFT]</font> <b>%s</b> memberikan <b>%s</b> kepada <b>%s</b>!", player.DisplayName, data.Name, receiver.DisplayName)
					GlobalChatBroadcast:FireAllClients(msg)
					logActivity(player.Name, "Membelikan Gift Robux (" .. data.Name .. ") kepada " .. receiver.Name)
				else
					logActivity(player.Name, "Membeli Item Robux (" .. data.Name .. ") untuk diri sendiri")
				end
				break
			end
		end
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
	if not isPurchased then
		local player = Players:GetPlayerByUserId(userId)
		if player then
			player:SetAttribute("GiftingTo", nil)
		end
	end
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local giftTargetName = player:GetAttribute("GiftingTo")
	local receiver = (giftTargetName and Players:FindFirstChild(giftTargetName)) or player
	player:SetAttribute("GiftingTo", nil)

	for _, data in pairs(SHOP_DATABASE) do
		if data.PayType == "Robux" and data.IsDevProduct and data.RobuxID == receiptInfo.ProductId then
			GiveItem(receiver, data)

			local audioType = (data.ActionType == "Currency") and "BuyCoin" or "BuyItem"
			RedeemResult:FireClient(player, "Transaksi " .. data.Name .. " berhasil!", true, audioType)

			if giftTargetName and receiver then
				local msg = string.format("<font color='#F7ADAF'>[GIFT]</font> <b>%s</b> memberikan <b>%s</b> kepada <b>%s</b>!", player.DisplayName, data.Name, receiver.DisplayName)
				GlobalChatBroadcast:FireAllClients(msg)
				logActivity(player.Name, "Membelikan DevProduct (" .. data.Name .. ") kepada " .. receiver.Name)
			else
				logActivity(player.Name, "Membeli DevProduct (" .. data.Name .. ") untuk diri sendiri")
			end

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end