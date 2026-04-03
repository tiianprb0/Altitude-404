local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local GROUP_NAME = "PlayerGroup"

-- 1. Membuat Grup Kolisi Baru
local function setupCollisionGroup()
	local success, err = pcall(function()
		-- Cek apakah grup sudah ada, kalau belum bikin baru
		-- Catatan: RegisterCollisionGroup adalah cara baru (modern) di Roblox
		PhysicsService:RegisterCollisionGroup(GROUP_NAME)
	end)

	if not success then
		warn("Gagal membuat collision group: " .. tostring(err))
	end

	-- 2. ATURAN PENTING: Grup ini TIDAK BOLEH bertabrakan dengan dirinya sendiri
	-- Artinya: Pemain (Grup A) vs Pemain (Grup A) = Tembus
	PhysicsService:CollisionGroupSetCollidable(GROUP_NAME, GROUP_NAME, false)
end

setupCollisionGroup()

-- 3. Fungsi untuk memasukkan bagian tubuh ke dalam grup
local function setCollisionGroup(object)
	if object:IsA("BasePart") then
		object.CollisionGroup = GROUP_NAME
	end
end

-- 4. Event Listener saat Pemain Masuk
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Tunggu sebentar biar karakternya loading sempurna
		character:WaitForChild("HumanoidRootPart")
		character:WaitForChild("Head")

		-- Masukkan semua bagian tubuh yang sudah ada ke grup
		for _, part in pairs(character:GetDescendants()) do
			setCollisionGroup(part)
		end

		-- Jaga-jaga kalau ada aksesoris/tools yang baru muncul belakangan
		character.DescendantAdded:Connect(setCollisionGroup)
	end)
end)