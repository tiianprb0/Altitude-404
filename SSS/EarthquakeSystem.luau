--[[
    Altitude 404: Global Earthquake System (Server)
    Refined by ESKA
    
    PERBAIKAN ECA:
    1. SINKRONISASI WAKTU: Durasi gempa kini ditentukan oleh server secara absolut
       dan dikirimkan ke klien melalui FireAllClients(durasi).
    2. DYNAMIC COOLDOWN: Server menunggu sesuai durasi gempa yang spesifik,
       ditambah sedikit buffer aman (2 detik) untuk mencegah siklus tumpang tindih.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FolderGempa = ReplicatedStorage:WaitForChild("Gempa")
local SinyalGempa = FolderGempa:WaitForChild("SinyalGempa")

-- === KONFIGURASI WAKTU (INTERVAL DIAM) ===
local waktuMinimal = 20 -- Detik jeda minimal
local waktuMaksimal = 60 -- Detik jeda maksimal

while true do
	-- 1. Efisiensi Server: Cek apakah ada pemain di dalam game.
	if #Players:GetPlayers() == 0 then
		task.wait(5)
		continue 
	end

	-- 2. Timer Jeda Damai
	local waktuTunggu = math.random(waktuMinimal, waktuMaksimal)
	task.wait(waktuTunggu)

	-- 3. Pengecekan Final: Pastikan masih ada pemain sebelum menembakkan sinyal
	if #Players:GetPlayers() > 0 then
		-- [ECA FIX] Server menentukan durasi gempa secara terpusat
		local durasiGempa = math.random(10, 20)

		-- Kirimkan durasi ke seluruh klien agar 100% sinkron
		SinyalGempa:FireAllClients(durasiGempa)

		-- Server ikut menunggu selama durasi gempa tersebut + 2 detik jeda aman
		task.wait(durasiGempa + 2)
	end
end