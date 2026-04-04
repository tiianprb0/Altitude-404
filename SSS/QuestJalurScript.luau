--[[
    QUEST SERVER SYSTEM (Pindahkan ke ServerScriptService)
    REVISI KARINA: 
    1. Menambahkan perlindungan Server (Guard Clause) agar mayat pemain yang mati
       tidak bisa memicu quest.
    2. Menambahkan "State Fallback" untuk mencegah Race Condition ketika client
       selesai loading lebih cepat dari event PlayerAdded di server.
       
    PENYEMPURNAAN ECA:
    1. Menambahkan Validasi Multi-Layer pada event "AmbilKayu" (Anti-Exploit).
    2. Magnitude Check untuk mencegah eksploitasi pengambilan jarak jauh.
]]

local NAMA_ITEM = "Ranting Kayu" 
local NAMA_NPC = "Yarraa"
local MAX_KAYU = 2 
local MAX_INTERACTION_DISTANCE = 20 -- Toleransi jarak maksimal untuk mengambil item

local FOLDER_QUEST = workspace:WaitForChild("QuestArea1") 
local npc = FOLDER_QUEST:WaitForChild(NAMA_NPC)
local jembatan = FOLDER_QUEST:WaitForChild("Jembatan")

local RS = game:GetService("ReplicatedStorage")
local questFolderRS = RS:WaitForChild("QuestSystem")
local remote = questFolderRS:WaitForChild("QuestRemote")

local statusPemain = {} 

local lokasiFolder = {}
for _, child in ipairs(FOLDER_QUEST:GetChildren()) do
	if string.match(child.Name, "Lokasi") then
		table.insert(lokasiFolder, child)
	end
end
table.sort(lokasiFolder, function(a, b) return a.Name < b.Name end)

for _, partLokasi in ipairs(lokasiFolder) do
	if partLokasi:IsA("BasePart") then
		partLokasi.Transparency = 1; partLokasi.CanCollide = false
	end
end

local function setJembatanServerState()
	if jembatan:IsA("Model") then
		for _, v in ipairs(jembatan:GetDescendants()) do
			if v:IsA("BasePart") then v.Transparency = 1; v.CanCollide = false end
		end
	elseif jembatan:IsA("BasePart") then
		jembatan.Transparency = 1; jembatan.CanCollide = false
	end
end
setJembatanServerState() 

-- === SETUP NPC YARRAA ===
local function setupNPC()
	local head = npc:FindFirstChild("Head") or npc.PrimaryPart

	if head then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = NAMA_NPC
		prompt.ActionText = "Bicara"
		prompt.HoldDuration = 1 
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 10
		prompt.Parent = head

		prompt.Triggered:Connect(function(player)
			local state = statusPemain[player.UserId]
			if not state or state.isInteracting then return end

			if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then return end

			state.isInteracting = true 

			if not state.hasInteracted then
				state.hasInteracted = true
				remote:FireClient(player, "HideExclamation")
				remote:FireClient(player, "ShowProgressUI")
				remote:FireClient(player, "UpdateNPCUI", state.kayuTerkumpul, MAX_KAYU)
			end

			remote:FireClient(player, "CameraFocus")

			if state.questSelesai then
				remote:FireClient(player, "BubbleChat", head, "Jalurnya aman sekarang. Silakan lewat!", Color3.fromRGB(255, 255, 255))
				task.wait(2)
				remote:FireClient(player, "CameraReset")
				state.isInteracting = false 
				return
			end

			local kayuDitemukan = 0
			for _, item in ipairs(player.Backpack:GetChildren()) do
				if item.Name == NAMA_ITEM then item:Destroy(); kayuDitemukan += 1 end
			end
			for _, item in ipairs(player.Character:GetChildren()) do
				if item.Name == NAMA_ITEM then item:Destroy(); kayuDitemukan += 1 end
			end

			if kayuDitemukan > 0 then
				state.kayuTerkumpul += kayuDitemukan
				if state.kayuTerkumpul > MAX_KAYU then state.kayuTerkumpul = MAX_KAYU end

				remote:FireClient(player, "UpdateNPCUI", state.kayuTerkumpul, MAX_KAYU)

				if state.kayuTerkumpul >= MAX_KAYU then
					state.questSelesai = true
					remote:FireClient(player, "BubbleChat", head, "Wah! Terima kasih rantingnya!", Color3.fromRGB(85, 255, 127))

					task.wait(2)
					remote:FireClient(player, "HideProgressUI")
					remote:FireClient(player, "BukaJembatanLocal") 
					remote:FireClient(player, "BubbleChat", head, "Jalurnya sudah kubuka untukmu.", Color3.fromRGB(255, 255, 255))

					task.wait(1.5)
					remote:FireClient(player, "CameraReset")
					state.isInteracting = false
				else
					remote:FireClient(player, "BubbleChat", head, "Terima kasih! Tapi aku masih butuh " .. (MAX_KAYU - state.kayuTerkumpul) .. " kayu lagi.", Color3.fromRGB(255, 255, 0))
					task.wait(2.5)
					remote:FireClient(player, "CameraReset")
					state.isInteracting = false
				end
			else
				if state.kayuTerkumpul > 0 then
					remote:FireClient(player, "BubbleChat", head, "Kamu baru mengumpulkan " .. state.kayuTerkumpul .. " kayu. Tolong carikan " .. (MAX_KAYU - state.kayuTerkumpul) .. " lagi ya!", Color3.fromRGB(255, 255, 0))
				else
					remote:FireClient(player, "BubbleChat", head, "Jembatan ini rusak... Bisa carikan " .. MAX_KAYU .. " Ranting Kayu?", Color3.fromRGB(255, 255, 255))
				end

				task.wait(2.5)
				remote:FireClient(player, "CameraReset")
				state.isInteracting = false
			end
		end)
	end
end
setupNPC()

-- === LOGIKA PLAYER ===
game.Players.PlayerAdded:Connect(function(player)
	statusPemain[player.UserId] = {
		kayuTerkumpul = 0,
		questSelesai = false,
		lokasiDiambil = {}, 
		hasInteracted = false,
		isInteracting = false
	}
end)

game.Players.PlayerRemoving:Connect(function(player)
	statusPemain[player.UserId] = nil
end)

-- === KOMUNIKASI DARI CLIENT ===
remote.OnServerEvent:Connect(function(player, action, lokasiIndex)
	local state = statusPemain[player.UserId]

	-- KARINA FIX: Race Condition Fallback. 
	if not state then
		statusPemain[player.UserId] = {
			kayuTerkumpul = 0,
			questSelesai = false,
			lokasiDiambil = {}, 
			hasInteracted = false,
			isInteracting = false
		}
		state = statusPemain[player.UserId]
	end

	if action == "ClientReady" then
		if not state.questSelesai then
			if not state.hasInteracted then
				remote:FireClient(player, "ShowExclamation")
			else
				remote:FireClient(player, "ShowProgressUI")
				remote:FireClient(player, "UpdateNPCUI", state.kayuTerkumpul, MAX_KAYU)
			end

			local kayuYangAkanDispawn = {}
			for i = 1, #lokasiFolder do
				if not state.lokasiDiambil[i] then 
					table.insert(kayuYangAkanDispawn, i) 
				end
			end

			if #kayuYangAkanDispawn > 0 then
				local limitDispawn = math.min(#kayuYangAkanDispawn, 3)
				local finalSpawn = {}
				for i = 1, limitDispawn do
					table.insert(finalSpawn, kayuYangAkanDispawn[i])
				end
				remote:FireClient(player, "SpawnKayuMultiple", finalSpawn)
			end
		end

		if state.questSelesai then
			remote:FireClient(player, "BukaJembatanLocal")
		else
			remote:FireClient(player, "HideJembatanLocal")
		end

	elseif action == "AmbilKayu" then
		-- [PERBAIKAN ECA] 1. Validasi Tipe Data dan Batas Indeks
		if type(lokasiIndex) ~= "number" or lokasiIndex < 1 or lokasiIndex > #lokasiFolder then
			warn("[ESKA Security] Peringatan: Pemain " .. player.Name .. " mencoba memanipulasi indeks kayu.")
			return
		end

		-- [PERBAIKAN ECA] 2. Validasi Duplikasi (Mencegah eksploitasi spam klik)
		if state.questSelesai or state.lokasiDiambil[lokasiIndex] then return end

		-- [PERBAIKAN ECA] 3. Validasi Jarak (Magnitude Check)
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local lokasiTarget = lokasiFolder[lokasiIndex]

		if not hrp or not lokasiTarget then return end

		local distance = (hrp.Position - lokasiTarget.Position).Magnitude
		if distance > MAX_INTERACTION_DISTANCE then
			warn("[ESKA Security] Peringatan: Pemain " .. player.Name .. " mencoba mengambil kayu dari jarak tidak wajar (" .. math.floor(distance) .. " studs).")
			return
		end

		-- Eksekusi pengambilan yang sah
		local sourceItem = RS:FindFirstChild(NAMA_ITEM)
		if sourceItem then
			sourceItem:Clone().Parent = player.Backpack
			state.lokasiDiambil[lokasiIndex] = true 

			if character and character:FindFirstChild("Head") then
				remote:FireClient(player, "BubbleChat", character.Head, "Dapat 1 Ranting!", Color3.fromRGB(255, 255, 0))
			end
		end
	end
end)