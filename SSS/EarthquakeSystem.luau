--[[
    Altitude 404: Global Earthquake System (Server)
    Refined by Karina
    
    Letakkan script ini di: ServerScriptService
    Tugas: Menghitung mundur dan memicu event gempa ke semua pemain.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Mengambil referensi dari Folder "Gempa" yang sudah Tian buat secara manual
local FolderGempa = ReplicatedStorage:WaitForChild("Gempa")
local SinyalGempa = FolderGempa:WaitForChild("SinyalGempa")

-- === KONFIGURASI WAKTU (INTERVAL DIAM) ===
local waktuMinimal = 20 -- Detik jeda minimal
local waktuMaksimal = 60 -- Detik jeda maksimal

while true do
	-- 1. Efisiensi Server: Cek apakah ada pemain di dalam game.
	-- Jika server kosong, tidak perlu ada gempa yang membebani komputasi.
	if #Players:GetPlayers() == 0 then
		task.wait(5) -- Cek ulang setiap 5 detik
		continue -- Lewati sisa kode di bawah dan ulangi loop dari atas
	end

	-- 2. Timer Jeda Damai
	local waktuTunggu = math.random(waktuMinimal, waktuMaksimal)
	task.wait(waktuTunggu)

	-- 3. Pengecekan Final: Pastikan masih ada pemain sebelum menembakkan sinyal
	if #Players:GetPlayers() > 0 then
		SinyalGempa:FireAllClients()
	end

	-- 4. Durasi Aman (Cooldown): Jeda waktu selama gempa berlangsung
	-- Agar timer jeda damai tidak mulai menghitung sebelum gempa sebelumnya selesai.
	task.wait(15) 
end