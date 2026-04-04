local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- --- KONFIGURASI ---
local skyAssetsFolder = ReplicatedStorage:WaitForChild("SkyAssets", 10)
local triggerFolder = workspace:WaitForChild("SkyZones", 10)
local atmosphere = Lighting:WaitForChild("Atmosphere", 10)

if not skyAssetsFolder or not triggerFolder or not atmosphere then
	warn("CRITICAL: Aset, Folder Zone, atau Atmosphere belum lengkap!")
	return
end

local transitionTime = 0.8 
local checkInterval = 0.3 

local defaultSkyTemplate = skyAssetsFolder:WaitForChild("CurrentSky", 5)

if not defaultSkyTemplate then
	warn("ALTITUDE 404 ERROR: 'CurrentSky' tidak ditemukan di dalam ReplicatedStorage.SkyAssets!")
	defaultSkyTemplate = Instance.new("Sky")
	defaultSkyTemplate.Name = "EmergencyBlankSky"
end

local currentActiveZone = "Default" 
local isTransitioning = false
local defaultDensity = atmosphere.Density
local maxDensity = 0.9 

local activeSky = Lighting:FindFirstChildOfClass("Sky")
if not activeSky and defaultSkyTemplate then
	defaultSkyTemplate:Clone().Parent = Lighting
end

-- KARINA FIX: Deklarasi OverlapParams dipindah ke luar fungsi.
-- Dibuat 1x di memori untuk menghemat pemakaian CPU karena fungsi dipanggil tiap 0.3 detik.
local zoneOverlapParams = OverlapParams.new()
zoneOverlapParams.FilterDescendantsInstances = {triggerFolder}
zoneOverlapParams.FilterType = Enum.RaycastFilterType.Include

-- --- FUNGSI TRANSISI ---
local function performSkySwitch(targetSkyTemplate)
	if isTransitioning then return end
	isTransitioning = true

	local tweenInfo = TweenInfo.new(transitionTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local fadeOut = TweenService:Create(atmosphere, tweenInfo, {Density = maxDensity, Haze = 5, Offset = 0})
	fadeOut:Play()
	fadeOut.Completed:Wait()

	local oldSky = Lighting:FindFirstChildOfClass("Sky")
	if oldSky then oldSky:Destroy() end

	local newSky = targetSkyTemplate:Clone()
	newSky.Parent = Lighting

	task.wait(0.2) 

	local fadeIn = TweenService:Create(atmosphere, tweenInfo, {Density = defaultDensity, Haze = 0})
	fadeIn:Play()

	task.wait(transitionTime)
	isTransitioning = false
end

-- --- FUNGSI PENGECEKAN POSISI ---
local function checkPlayerZone()
	local player = Players.LocalPlayer
	if not player or not player.Character then return end

	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Menggunakan parameter yang sudah dibuat di luar fungsi
	local partsInZone = workspace:GetPartsInPart(rootPart, zoneOverlapParams)
	local foundZoneAttribute = nil

	for _, part in pairs(partsInZone) do
		local attr = part:GetAttribute("TargetSky")
		if attr then
			foundZoneAttribute = attr
			break 
		end
	end

	if foundZoneAttribute then
		if currentActiveZone ~= foundZoneAttribute then
			local targetTemplate = skyAssetsFolder:FindFirstChild(foundZoneAttribute)
			if targetTemplate then
				currentActiveZone = foundZoneAttribute
				performSkySwitch(targetTemplate)
			end
		end
	else
		if currentActiveZone ~= "Default" then
			currentActiveZone = "Default"
			if defaultSkyTemplate then
				performSkySwitch(defaultSkyTemplate)
			end
		end
	end
end

-- --- LOOP MONITORING ---
task.spawn(function()
	while true do
		checkPlayerZone()
		task.wait(checkInterval)
	end
end)