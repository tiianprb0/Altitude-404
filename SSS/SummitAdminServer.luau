-- ServerScriptService.SummitAdminServer
-- Sistem admin untuk mengubah nilai Summits player
-- UPDATED BY KARINA: Menggunakan Attribute System (No Hardcoded IDs)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Level minimal untuk akses Summit Admin
local MIN_ACCESS_LEVEL = 2 -- 2 = Admin, 3 = HeadAdmin, 4 = Owner

local function isAdmin(player)
	local level = player:GetAttribute("RankLevel") or 0
	return level >= MIN_ACCESS_LEVEL
end

----------------------------------------------------
-- RemoteEvent untuk komunikasi Client <-> Server  --
----------------------------------------------------

local requestEvent = ReplicatedStorage:FindFirstChild("SummitAdminRequest")
if not requestEvent then
	requestEvent = Instance.new("RemoteEvent")
	requestEvent.Name = "SummitAdminRequest"
	requestEvent.Parent = ReplicatedStorage
end

local responseEvent = ReplicatedStorage:FindFirstChild("SummitAdminResponse")
if not responseEvent then
	responseEvent = Instance.new("RemoteEvent")
	responseEvent.Name = "SummitAdminResponse"
	responseEvent.Parent = ReplicatedStorage
end

local function sendMessage(player, text)
	responseEvent:FireClient(player, text)
end

----------------------------------------------------
-- Fungsi helper untuk ambil IntValue Summits     --
----------------------------------------------------

local function getSummitsValueObject(targetPlayer)
	if not targetPlayer then return nil end

	local rootVal = targetPlayer:FindFirstChild("Summits")
	if rootVal and rootVal:IsA("IntValue") then
		return rootVal
	end

	local ls = targetPlayer:FindFirstChild("leaderstats")
	if ls then
		local stat = ls:FindFirstChild("Summits")
		if stat and stat:IsA("IntValue") then
			return stat
		end
	end

	return nil
end

----------------------------------------------------
-- Handler permintaan dari admin                   --
----------------------------------------------------

requestEvent.OnServerEvent:Connect(function(sender, action, targetName, amount)
	if not isAdmin(sender) then
		sendMessage(sender, "? Akses Ditolak: Rank kamu tidak cukup.")
		return
	end

	if typeof(action) ~= "string" or typeof(targetName) ~= "string" then
		sendMessage(sender, "? Data permintaan tidak valid.")
		return
	end

	local targetPlayer = Players:FindFirstChild(targetName)
	if not targetPlayer then
		sendMessage(sender, "? Player '" .. targetName .. "' tidak ditemukan (harus sedang online).")
		return
	end

	local summitsVal = getSummitsValueObject(targetPlayer)
	if not summitsVal then
		sendMessage(sender, "? Player ini tidak punya nilai 'Summits'.")
		return
	end

	amount = tonumber(amount) or 1
	if amount < 0 then amount = -amount end 

	local before = summitsVal.Value
	local after = before

	if action == "add" then
		after = before + amount
	elseif action == "sub" then
		after = before - amount
	elseif action == "reset" then
		after = 0
	else
		sendMessage(sender, "? Aksi tidak dikenal: " .. tostring(action))
		return
	end

	if after < 0 then after = 0 end

	summitsVal.Value = after

	local msg
	if action == "add" then
		msg = ("? %s: +%d summit (sekarang %d)"):format(targetPlayer.Name, amount, after)
	elseif action == "sub" then
		msg = ("? %s: -%d summit (sekarang %d)"):format(targetPlayer.Name, amount, after)
	elseif action == "reset" then
		msg = ("? %s: summit di-reset ke 0"):format(targetPlayer.Name)
	end

	sendMessage(sender, msg)
end)