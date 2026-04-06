-- Ini adalah LocalScript. 
-- Letakkan script ini di StarterPlayer -> StarterPlayerScripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- PENTING: Pastikan ModuleScript "KariCompass" milikmu diletakkan di dalam ReplicatedStorage
local compassModulePath = ReplicatedStorage:WaitForChild("KariCompass")
local KariCompass = require(compassModulePath)

-- Memanggil constructor untuk membangun UI dan memulai loop
local myCompass = KariCompass.new()

-- Catatan tambahan: Jika sewaktu-waktu kamu ingin menyembunyikannya, 
-- kamu bisa memanggil: myCompass:SetVisible(false)