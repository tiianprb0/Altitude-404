--[[
    KariCompass Module (Standalone OOP Architecture)
    Versi: Ultra-Compact dengan UI Penggaris (Ruler) Pipih dan Presisi 5 Derajat
]]

local KariCompass = {}
KariCompass.__index = KariCompass

local RunService = game:GetService("RunService")
local Players = game.Players

-- Konfigurasi Utama
local GUI_NAME = "TianKari_CompassUI"
local COMPASS_FOV = 90
local COMPASS_WIDTH = 250 
local Y_POSITION = 10

-- CONSTRUCTOR
function KariCompass.new()
	local self = setmetatable({}, KariCompass)

	self.IsVisible = true
	self.RenderConnection = nil
	self.DirectionLabels = {}
	self.ScreenGui = nil
	self.Container = nil

	self:_buildUI()
	self:Start()

	return self
end

-- METHOD (PRIVATE): Membangun UI secara mandiri
function KariCompass:_buildUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	if playerGui:FindFirstChild(GUI_NAME) then
		playerGui[GUI_NAME]:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = GUI_NAME
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	self.ScreenGui = screenGui

	local container = Instance.new("Frame")
	container.Name = "CompassContainer"
	container.Size = UDim2.new(0, COMPASS_WIDTH, 0, 24) -- Tinggi dipangkas ekstra (sangat pipih)
	container.Position = UDim2.new(0.5, 0, 0, Y_POSITION)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1
	container.ClipsDescendants = true
	container.Parent = screenGui
	self.Container = container

	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0),
		NumberSequenceKeypoint.new(0.85, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	gradient.Parent = container

	-- Penunjuk statis di tengah (Jarum kuning)
	local centerMark = Instance.new("Frame")
	centerMark.Name = "CenterMark"
	centerMark.Size = UDim2.new(0, 2, 0, 14) -- Ketinggian jarum dikurangi menyesuaikan container
	centerMark.Position = UDim2.new(0.5, 0, 0, 0)
	centerMark.AnchorPoint = Vector2.new(0.5, 0)
	centerMark.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
	centerMark.BorderSizePixel = 0
	centerMark.ZIndex = 10
	centerMark.Parent = container

	local directions = {
		[0] = "N", [45] = "NE", [90] = "E", [135] = "SE",
		[180] = "S", [225] = "SW", [270] = "W", [315] = "NW"
	}

	-- Membuat deretan angka dan garis penggaris (Interval per 5 derajat)
	for angle = 0, 359, 5 do
		local tickGroup = Instance.new("Frame")
		tickGroup.Size = UDim2.new(0, 40, 0, 24)
		tickGroup.AnchorPoint = Vector2.new(0.5, 0)
		tickGroup.BackgroundTransparency = 1
		tickGroup.Parent = container

		-- Hierarki Ketebalan dan Panjang Garis
		local isMajor = (angle % 45 == 0)
		local isMedium = (angle % 15 == 0 and not isMajor)
		local isMinor = (not isMajor and not isMedium)

		local tickLine = Instance.new("Frame")
		tickLine.AnchorPoint = Vector2.new(0.5, 0)
		tickLine.Position = UDim2.new(0.5, 0, 0, 0)
		tickLine.BorderSizePixel = 0
		tickLine.Parent = tickGroup

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 12)
		lbl.Position = UDim2.new(0, 0, 0, 10) -- Posisi teks persis di bawah garis terpanjang
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.Parent = tickGroup

		if isMajor then
			-- Arah Mata Angin (Garis panjang)
			tickLine.Size = UDim2.new(0, 2, 0, 8) 
			tickLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

			lbl.Text = directions[angle]
			lbl.TextSize = 12
			lbl.TextColor3 = Color3.fromRGB(255, 255, 255)

		elseif isMedium then
			-- Teks Angka 15 Derajat (Garis sedang)
			tickLine.Size = UDim2.new(0, 2, 0, 5) 
			tickLine.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

			lbl.Text = tostring(angle)
			lbl.TextSize = 10
			lbl.TextColor3 = Color3.fromRGB(150, 150, 150)

		else
			-- Garis Kosong per 5 derajat (Garis pendek)
			tickLine.Size = UDim2.new(0, 1, 0, 3) 
			tickLine.BackgroundColor3 = Color3.fromRGB(130, 130, 130)

			lbl.Text = "" -- Tanpa teks agar desain tetap clean
		end

		table.insert(self.DirectionLabels, {Label = tickGroup, TargetAngle = angle})
	end
end

-- METHOD: Memulai loop kompas
function KariCompass:Start()
	if self.RenderConnection then return end

	local camera = workspace.CurrentCamera

	self.RenderConnection = RunService.RenderStepped:Connect(function()
		if not self.IsVisible then return end

		local look = camera.CFrame.LookVector
		local currentHeading = math.deg(math.atan2(look.X, -look.Z))
		if currentHeading < 0 then
			currentHeading = currentHeading + 360
		end

		for _, data in ipairs(self.DirectionLabels) do
			local group = data.Label
			local labelAngle = data.TargetAngle

			local diff = labelAngle - currentHeading
			while diff < -180 do diff = diff + 360 end
			while diff > 180 do diff = diff - 360 end

			if math.abs(diff) <= (COMPASS_FOV / 2) + 15 then
				group.Visible = true
				local xOffset = (diff / COMPASS_FOV) * COMPASS_WIDTH
				group.Position = UDim2.new(0.5, xOffset, 0, 0)
			else
				group.Visible = false
			end
		end
	end)
end

function KariCompass:Stop()
	if self.RenderConnection then
		self.RenderConnection:Disconnect()
		self.RenderConnection = nil
	end
end

function KariCompass:SetVisible(state)
	self.IsVisible = state
	if self.Container then
		self.Container.Visible = state
	end
end

function KariCompass:Destroy()
	self:Stop()
	if self.ScreenGui then self.ScreenGui:Destroy() end
	table.clear(self.DirectionLabels)
	self.Container = nil
end

return KariCompass