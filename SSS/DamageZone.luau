local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Konfigurasi
local folderName = "DamageZones"
local defaultDamage = 10 -- Damage bawaan kalau lupa kasih Attribute
local hitCooldown = 0.5 -- Jeda waktu antar damage (detik) biar gak instan mati

local damageFolder = Workspace:WaitForChild(folderName)

-- Tabel untuk menyimpan waktu terakhir kena damage (biar tidak spam hit dalam 0.001 detik)
-- Format: [Humanoid] = tick()
local lastHitTable = {}

-- Fungsi untuk membersihkan tabel (Memory Management)
-- Kalau Humanoid mati/hilang, hapus dari catatan biar server gak berat
local function cleanUpTable(humanoid)
	lastHitTable[humanoid] = nil
end

-- Fungsi Utama Jebakan
local function setupTrap(part)
	if not part:IsA("BasePart") then return end

	-- Ambil nilai damage dari Attribute part tersebut
	-- Kalau gak ada attribute, pakai nilai default
	local damageAmount = part:GetAttribute("Damage") or defaultDamage

	print("?? Zona Bahaya Aktif: " .. part.Name .. " (Damage: " .. damageAmount .. ")")

	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character:FindFirstChild("Humanoid")

		if humanoid and humanoid.Health > 0 then
			-- Cek Cooldown (Debounce per Player)
			-- Ini mencegah Player A kena damage gara-gara Player B nyentuh part yang sama
			local now = tick()
			local lastHit = lastHitTable[humanoid] or 0

			if (now - lastHit) >= hitCooldown then
				-- Catat waktu kena hit
				lastHitTable[humanoid] = now

				-- BERIKAN DAMAGE
				humanoid:TakeDamage(damageAmount)

				-- Efek visual/suara (Opsional, biar kerasa sakitnya)
				-- Kita ubah warna HumanoidRootPart jadi merah sebentar (feedback visual)
				local rootPart = character:FindFirstChild("HumanoidRootPart")

				-- Debug print
				-- print(character.Name .. " kena air panas! Sisa darah: " .. humanoid.Health)

				-- Hook untuk bersih-bersih kalau mati
				if humanoid.Health <= 0 then
					cleanUpTable(humanoid)
				end
			end
		end
	end)
end

-- --- INISIALISASI ---
print("--- DAMAGE SYSTEM STARTED ---")

-- 1. Pasang jebakan untuk part yang sudah ada
for _, part in pairs(damageFolder:GetChildren()) do
	setupTrap(part)
end

-- 2. Pasang jebakan untuk part yang baru dimasukkan (misal hasil copy paste saat main)
damageFolder.ChildAdded:Connect(function(child)
	setupTrap(child)
end)

-- Pembersihan berkala (Garbage Collection sederhana)
-- Menghapus data humanoid yang sudah tidak ada di game
game:GetService("RunService").Heartbeat:Connect(function()
	if tick() % 10 == 0 then -- Cek setiap 10 detik (kurang lebih)
		for hum, _ in pairs(lastHitTable) do
			if not hum.Parent then
				lastHitTable[hum] = nil
			end
		end
	end
end)