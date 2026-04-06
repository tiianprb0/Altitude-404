--[[
    ALTITUDE SHOP BRAIN (SERVER LOGIC) V4.4 (SHARED DATABASE INTEGRATION)
    Lokasi: ServerScriptService
    
    PEMBARUAN ESKA:
    - Data item hardcode dihapus sepenuhnya.
    - Sistem kini membaca data secara terpusat dari modul SharedShopDatabase.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerRoleAPI = require(ServerScriptService:WaitForChild("ServerRoleAPI"))
local AltitudeDataAPI = require(ServerScriptService:WaitForChild("AltitudeDataAPI"))

-- Memuat pangkalan data terpusat
local SharedShopDatabase = require(ReplicatedStorage:WaitForChild("SharedShopDatabase"))
local SHOP_DATABASE = SharedShopDatabase.Items
local REDEEM_CODES = SharedShopDatabase.RedeemCodes

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
		AltitudeDataAPI.AddCoins(player, data.Value)
	elseif data.ActionType == "Tool" then
		if ToolsFolder then
			local tool = ToolsFolder:FindFirstChild(data.Name)
			if tool and tool:IsA("Tool") then
				local safeName = string.gsub(data.Name, "%s+", "")
				player:SetAttribute("OwnsTool_" .. safeName, true)

				local hasItemFisik = false
				if player.Character and player.Character:FindFirstChild(data.Name) then hasItemFisik = true end
				if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild(data.Name) then hasItemFisik = true end

				if not hasItemFisik then
					if player:FindFirstChild("Backpack") then
						tool:Clone().Parent = player.Backpack
					end
				end
			end
		end
	elseif data.ActionType == "Perk" then
		player:SetAttribute(data.AttributeName, true)
		if data.AttributeName == "HasVIP" then
			AltitudeDataAPI.AddCoins(player, 10000)
		end
	end
end

ShopRemote.OnServerEvent:Connect(function(player, itemID)
	if not player:GetAttribute("DataLoaded") then return end

	if itemID == "EXCHANGE_SUMMIT" then
		local summits = AltitudeDataAPI.GetSummits(player)

		if summits > 0 then
			local exchangeAmount = summits * 500
			local sVal = summits

			if AltitudeDataAPI.DeductSummits(player, sVal) then
				AltitudeDataAPI.AddCoins(player, exchangeAmount)
				RedeemResult:FireClient(player, "Berhasil menukar Summit menjadi " .. FormatNumber(exchangeAmount) .. " Coins!", true, "BuyCoin")
				logActivity(player.Name, "Menukar " .. tostring(sVal) .. " Summit menjadi " .. FormatNumber(exchangeAmount) .. " Coins")
			end
		else
			RedeemResult:FireClient(player, "Kamu belum memiliki Summit untuk ditukar!", false)
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
		if AltitudeDataAPI.GetCoins(player) >= data.Price then
			if AltitudeDataAPI.DeductCoins(player, data.Price) then
				GiveItem(player, data)
				RedeemResult:FireClient(player, "Berhasil membeli " .. data.Name, true, "BuyItem")
				logActivity(player.Name, "Membeli " .. data.Name .. " seharga " .. FormatNumber(data.Price) .. " Coins")
			end
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

	if not ServerRoleAPI.CanTarget(player, target) then
		RedeemResult:FireClient(player, "? Ditolak: Otoritas tidak mencukupi untuk mengirimkan hadiah ke pemain ini.", false)
		return
	end

	if HasItem(target, data) then return end

	if data.PayType == "Robux" then
		player:SetAttribute("GiftingTo", target.Name) 
		if data.IsDevProduct then MarketplaceService:PromptProductPurchase(player, data.RobuxID)
		else MarketplaceService:PromptGamePassPurchase(player, data.RobuxID) end
	elseif data.PayType == "Coins" then
		if AltitudeDataAPI.GetCoins(player) >= data.Price then
			if AltitudeDataAPI.DeductCoins(player, data.Price) then
				GiveItem(target, data) 
				RedeemResult:FireClient(player, "Berhasil kado ke " .. target.Name, true, "BuyItem")

				local msg = string.format("<font color='#F7ADAF'>[GIFT]</font> <b>%s</b> memberikan <b>%s</b> kepada <b>%s</b>!", player.DisplayName, data.Name, target.DisplayName)
				GlobalChatBroadcast:FireAllClients(msg)

				logActivity(player.Name, "Membelikan Gift (" .. data.Name .. ") kepada " .. target.Name)
			end
		else
			RedeemResult:FireClient(player, "Uang tidak cukup untuk gift!", false)
		end
	end
end)

RedeemRemote.OnServerEvent:Connect(function(player, code)
	if not player:GetAttribute("DataLoaded") then return end

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

	player:SetAttribute("ClaimedCode_" .. code, true)
	codeData.Quantity = codeData.Quantity - 1

	if codeData.Type == "Coin" then
		if AltitudeDataAPI.AddCoins(player, codeData.Value) then
			RedeemResult:FireClient(player, "Berhasil klaim " .. FormatNumber(codeData.Value) .. " Coins!", true, "Redeem")
			logActivity(player.Name, "Klaim Kode Promo '" .. code .. "' (" .. FormatNumber(codeData.Value) .. " Coins)")
		end
	end

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