--[[
    ALTITUDE EQUIP SERVER V3.1 (RAW & ABSOLUTE WELD SYSTEM + MORPH REFRESH LISTENER)
    Lokasi: ServerScriptService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local aurasFolder = ReplicatedStorage:WaitForChild("Auras")

local equipRemote = ReplicatedStorage:FindFirstChild("EquipRemote")
if not equipRemote then
	equipRemote = Instance.new("RemoteEvent")
	equipRemote.Name = "EquipRemote"
	equipRemote.Parent = ReplicatedStorage
end

local AURA_SECURITY_MAP = {
	["Godoflight"] = "HasGodoflight", ["Blossom"] = "HasBlossom", ["Glitch"] = "HasGlitch",
	["Rare"] = "HasRare", ["Rich"] = "HasRich", ["SwordMaster"] = "HasSwordMaster",
	["Chained"] = "HasChained", ["Cosmic"] = "HasCosmic", ["Cubic"] = "HasCubic",
	["DualSwords"] = "HasDualSwords", ["Frost"] = "HasFrost", ["Love"] = "HasLove",
	["Poison"] = "HasPoison", ["Powerless"] = "HasPowerless", ["SandDemon"] = "HasSandDemon",
	["SoundNinja"] = "HasSoundNinja", ["ThunderGod"] = "HasThunderGod"
}

local function RemoveCurrentAura(character)
	if not character then return end
	local oldAura = character:FindFirstChild("ActiveCosmeticAura")
	if oldAura then oldAura:Destroy() end
end

local function AttachAuraToCharacter(character, auraModelName)
	local auraPrefab = aurasFolder:FindFirstChild(auraModelName)
	if not auraPrefab then return end

	-- Menggunakan Torso agar jarak ketinggian sama dengan Dummy di Studio (Untuk aura utama/pedang)
	local rootTarget = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
	if not rootTarget then return end

	local newAura = auraPrefab:Clone()
	newAura.Name = "ActiveCosmeticAura"

	-- Cari Inti Aura
	local auraRoot = newAura:FindFirstChild("AuraPart") or newAura.PrimaryPart or newAura:FindFirstChild("HumanoidRootPart")
	if not auraRoot then
		newAura:Destroy()
		return
	end

	newAura.PrimaryPart = auraRoot

	-- 1. KUNCI MATI SEMUA PART KE INTI SEBELUM PINDAH LOKASI
	local bawahParts = {}
	local bawahAttachments = {} 

	-- Memisahkan part yang bernama "bawah" untuk perlakuan khusus
	for _, obj in pairs(newAura:GetDescendants()) do
		if string.lower(obj.Name) == "bawah" then
			if obj:IsA("BasePart") and obj ~= auraRoot then
				table.insert(bawahParts, obj)
			elseif obj:IsA("Attachment") then
				table.insert(bawahAttachments, obj)
			end
		elseif obj:IsA("BasePart") and obj ~= auraRoot then
			local autoWeld = Instance.new("WeldConstraint")
			autoWeld.Part0 = auraRoot
			autoWeld.Part1 = obj
			autoWeld.Parent = obj
		end
	end

	-- 2. BERSIHKAN PENGGANGGU FISIKA
	local dummyAnimate = newAura:FindFirstChild("Animate")
	if dummyAnimate then dummyAnimate:Destroy() end
	local dummyHum = newAura:FindFirstChildOfClass("Humanoid")
	if dummyHum then dummyHum:Destroy() end

	for _, part in pairs(newAura:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Massless = true
			part.Anchored = false

			-- Sembunyikan balok sisa dummy
			local name = string.lower(part.Name)
			if (name == "head" or name == "torso" or name == "humanoidrootpart" or string.find(name, "arm") or string.find(name, "leg")) and name ~= "aurapart" then
				part.Transparency = 1
			end
		end
	end

	-- 3. PINDAHKAN SECARA PAKSA LALU LAS KE PEMAIN (Aura Utama)
	newAura:PivotTo(rootTarget.CFrame)
	newAura.Parent = character

	-- Gunakan settingan jarak buatan Tian di Studio untuk aura utama (contoh: pedang)
	local builtInWeld = auraRoot:FindFirstChildOfClass("Weld") or auraRoot:FindFirstChildOfClass("ManualWeld")
	if builtInWeld then
		builtInWeld.Part0 = rootTarget
		builtInWeld.Part1 = auraRoot
	else
		local fallbackWeld = Instance.new("WeldConstraint")
		fallbackWeld.Part0 = rootTarget
		fallbackWeld.Part1 = auraRoot
		fallbackWeld.Parent = auraRoot
	end

	-- 4. EKSEKUSI PART & ATTACHMENT "BAWAH" (YANG KAKU & TENANG)
	if #bawahParts > 0 or #bawahAttachments > 0 then
		local trueRoot = character:FindFirstChild("HumanoidRootPart") or rootTarget
		local legTarget = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg") or trueRoot

		-- Kalkulasi: Posisi X dan Z di tengah trueRoot, Y (tinggi) turun ke level kaki.
		local bottomCFrame = CFrame.new(trueRoot.Position.X, legTarget.Position.Y, trueRoot.Position.Z) * trueRoot.CFrame.Rotation

		-- Buat jangkar transparan agar "Bawah" tidak menjadi yatim piatu
		local bawahAnchor = Instance.new("Part")
		bawahAnchor.Name = "BawahAnchor"
		bawahAnchor.Transparency = 1
		bawahAnchor.CanCollide = false
		bawahAnchor.Massless = true
		bawahAnchor.Anchored = false
		bawahAnchor.Size = Vector3.new(1, 1, 1)
		bawahAnchor.CFrame = bottomCFrame
		bawahAnchor.Parent = newAura -- Simpan di dalam aura agar ikut hancur saat unequip

		local weldAnchor = Instance.new("WeldConstraint")
		weldAnchor.Part0 = trueRoot
		weldAnchor.Part1 = bawahAnchor
		weldAnchor.Parent = bawahAnchor

		for _, part in ipairs(bawahParts) do
			part.CFrame = bottomCFrame

			-- Ikat ke jangkar, bukan ke badan langsung
			local weldBawah = Instance.new("WeldConstraint")
			weldBawah.Part0 = bawahAnchor
			weldBawah.Part1 = part
			weldBawah.Parent = part
		end

		for _, att in ipairs(bawahAttachments) do
			-- Induk ke jangkar
			att.Parent = bawahAnchor
			att.WorldCFrame = bottomCFrame
		end
	end
end

equipRemote.OnServerEvent:Connect(function(player, category, itemID)
	if category ~= "Aura" then return end
	if itemID == "" then
		player:SetAttribute("ActiveAura", "")
		RemoveCurrentAura(player.Character)
		return
	end
	local requiredAttribute = AURA_SECURITY_MAP[itemID]
	if not requiredAttribute then return end 

	if player:GetAttribute(requiredAttribute) == true then
		player:SetAttribute("ActiveAura", itemID)
		local character = player.Character
		if character then
			RemoveCurrentAura(character)
			AttachAuraToCharacter(character, itemID)
		end
	end
end)

-- SINKRONISASI DATA ABSOLUT (ANTI HILANG)
local function onCharacterSpawned(player, character)
	if not player:GetAttribute("DataLoaded") then
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	end

	if not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:Wait()
	end

	task.wait(0.5)

	local activeAura = player:GetAttribute("ActiveAura")
	if activeAura and activeAura ~= "" then
		local reqAttr = AURA_SECURITY_MAP[activeAura]
		if reqAttr and player:GetAttribute(reqAttr) == true then
			AttachAuraToCharacter(character, activeAura)
		end
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacterSpawned, player, character)
	end)

	-- [KARINA FIX] Listener untuk menerima sinyal re-render (misal: habis Morph)
	player:GetAttributeChangedSignal("RefreshAura"):Connect(function()
		local activeAura = player:GetAttribute("ActiveAura")
		if activeAura and activeAura ~= "" and player.Character then
			local reqAttr = AURA_SECURITY_MAP[activeAura]
			if reqAttr and player:GetAttribute(reqAttr) == true then
				RemoveCurrentAura(player.Character)
				AttachAuraToCharacter(player.Character, activeAura)
			end
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
	if player.Character then
		task.spawn(onCharacterSpawned, player, player.Character)
	end
end