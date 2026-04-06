-- Location & Weather HUD System (Overlapping Icon Edition) -- StarterPlayerScripts --

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DETECTION_RADIUS = 400 

-- Konfigurasi Warna
local COLORS = {
	BackgroundDark = Color3.fromRGB(12, 28, 55),
	Text = Color3.fromRGB(245, 245, 250),
	TextDim = Color3.fromRGB(150, 175, 205),
	Accent = Color3.fromRGB(247, 173, 175)
}

-- Hapus UI lama jika ada
local uiName = "LocationWeatherHUD"
local oldUi = playerGui:FindFirstChild(uiName)
if oldUi then oldUi:Destroy() end

-- ==========================================
-- PEMBUATAN GUI
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = uiName
gui.IgnoreGuiInset = true 
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Container Utama
local container = Instance.new("Frame")
container.Name = "HUDContainer"
container.Size = UDim2.new(0, 0, 0, 0)
container.AutomaticSize = Enum.AutomaticSize.XY
container.AnchorPoint = Vector2.new(0, 1)
-- Digeser ke X:35 agar ikon yang keluar batas tidak menabrak pinggir layar
container.Position = UDim2.new(0, 35, 1, -25) 
container.BackgroundColor3 = COLORS.BackgroundDark
container.BorderSizePixel = 0
container.ZIndex = 1
container.Parent = gui

Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

-- UIGradient untuk efek fade out ke kanan
local gradient = Instance.new("UIGradient")
gradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.1),
	NumberSequenceKeypoint.new(0.6, 0.4),
	NumberSequenceKeypoint.new(1, 1)
})
gradient.Parent = container

-- ==========================================
-- STRUKTUR TEKS (Dipisah dari Ikon)
-- ==========================================
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.BackgroundTransparency = 1
contentFrame.Size = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticSize = Enum.AutomaticSize.XY
contentFrame.ZIndex = 2
contentFrame.Parent = container

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = contentFrame

-- Padding khusus untuk teks, memberi ruang kosong di sebelah kiri untuk ikon
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 32) -- Ruang untuk ikon
padding.PaddingRight = UDim.new(0, 60)
padding.Parent = contentFrame

-- Teks Cuaca (Fokus Utama)
local weatherText = Instance.new("TextLabel")
weatherText.Name = "WeatherText"
weatherText.Size = UDim2.new(0, 0, 0, 16)
weatherText.AutomaticSize = Enum.AutomaticSize.X
weatherText.BackgroundTransparency = 1
weatherText.Text = "Memeriksa..."
weatherText.Font = Enum.Font.GothamBold
weatherText.TextColor3 = COLORS.Text
weatherText.TextSize = 14
weatherText.TextXAlignment = Enum.TextXAlignment.Left
weatherText.LayoutOrder = 1
weatherText.Parent = contentFrame

-- Teks Wilayah (Subteks)
local locText = Instance.new("TextLabel")
locText.Name = "LocationText"
locText.Size = UDim2.new(0, 0, 0, 12)
locText.AutomaticSize = Enum.AutomaticSize.X
locText.BackgroundTransparency = 1
locText.Text = "Mencari Lokasi..."
locText.Font = Enum.Font.GothamMedium
locText.TextColor3 = COLORS.TextDim
locText.TextSize = 11
locText.TextXAlignment = Enum.TextXAlignment.Left
locText.LayoutOrder = 2
locText.Parent = contentFrame

-- ==========================================
-- IKON POP-OUT (Elemen yang menembus kontainer)
-- ==========================================
local mainIcon = Instance.new("ImageLabel")
mainIcon.Name = "MainIcon"
mainIcon.Size = UDim2.new(0, 48, 0, 48) -- Ukuran sangat besar
-- Titik tengah ikon ditempatkan persis di garis tepi kiri kontainer
mainIcon.Position = UDim2.new(0, 0, 0.5, 0) 
mainIcon.AnchorPoint = Vector2.new(0.5, 0.5) 
mainIcon.BackgroundTransparency = 1
mainIcon.Image = "rbxassetid://74819650801508"
mainIcon.ImageColor3 = COLORS.Accent
mainIcon.ZIndex = 3 -- Tampil di atas kontainer
mainIcon.Parent = container

-- ==========================================
-- LOGIKA FORMATTING TEKS
-- ==========================================
local function formatLocationName(str)
	local words = string.split(str, " ")
	for i, word in ipairs(words) do
		words[i] = string.upper(string.sub(word, 1, 1)) .. string.lower(string.sub(word, 2))
	end
	return table.concat(words, " ")
end

-- ==========================================
-- LOGIKA CUACA & ANIMASI IKON
-- ==========================================
local function updateWeatherStatus()
	local isRaining = Lighting:GetAttribute("IsRaining")
	local isFoggy = Lighting:GetAttribute("IsFoggy")
	local rainType = Lighting:GetAttribute("RainType")
	local isAcid = Lighting:GetAttribute("IsAcidRain")

	local status = "Cerah"
	local iconId = "rbxassetid://74819650801508"

	if isFoggy then
		status = "Kabut Tebal"
		iconId = "rbxassetid://79699329921146"
	elseif isRaining then
		if rainType == "Drizzle" then
			status = "Gerimis Ringan"
			iconId = "rbxassetid://127973785546727"
		elseif rainType == "Normal" then
			status = "Hujan Turun"
			iconId = "rbxassetid://84879520979447"
		elseif rainType == "Storm" then
			status = isAcid and "Badai Petir & Hujan Asam" or "Badai Petir"
			iconId = "rbxassetid://126180105058763"
		end
	end

	weatherText.Text = status
	mainIcon.Image = iconId

	-- Efek animasi memantul saat cuaca berganti
	mainIcon.Size = UDim2.new(0, 25, 0, 25) -- Mengecil sementara
	TweenService:Create(mainIcon, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 48, 0, 48)
	}):Play()
end

Lighting:GetAttributeChangedSignal("IsRaining"):Connect(updateWeatherStatus)
Lighting:GetAttributeChangedSignal("IsFoggy"):Connect(updateWeatherStatus)
Lighting:GetAttributeChangedSignal("RainType"):Connect(updateWeatherStatus)
updateWeatherStatus()

-- ==========================================
-- LOGIKA LOKASI & ANIMASI TRANSISI
-- ==========================================
local soundFolder = workspace:WaitForChild("Sound", 10)
local lastLocation = ""

local function updateLocationUI(newLocation)
	if newLocation == lastLocation then return end
	lastLocation = newLocation

	TweenService:Create(locText, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()

	task.delay(0.3, function()
		locText.Text = newLocation
		TweenService:Create(locText, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	end)
end

local function checkPlayerLocation()
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not soundFolder then return end

	local closestPart = nil
	local shortestDistance = DETECTION_RADIUS

	for _, part in ipairs(soundFolder:GetChildren()) do
		if part:IsA("BasePart") then
			local distance = (hrp.Position - part.Position).Magnitude
			if distance < shortestDistance then
				shortestDistance = distance
				closestPart = part
			end
		end
	end

	local currentLocation = closestPart and formatLocationName(closestPart.Name) or "Wilayah Terbuka"
	updateLocationUI(currentLocation)
end

task.spawn(function()
	while true do
		checkPlayerLocation()
		task.wait(1)
	end
end)