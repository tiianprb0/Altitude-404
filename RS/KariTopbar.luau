--[[
    KariTopbar Module (OOP Architecture)
    Terinspirasi dari inti logika TopbarPlus.
    Setiap tombol adalah Objek yang memiliki state Selected/Deselected independen.
]]

local KariTopbar = {}
KariTopbar.__index = KariTopbar

-- Private Variables untuk Controller
local GUI_NAME = "TianKari_TopbarUI"
local TopbarContainer = nil
local ActiveIcon = nil -- Menyimpan referensi objek ikon yang sedang 'Selected'

-- Fungsi Internal: Membangun kontainer utama jika belum ada
local function GetOrCreateContainer()
	if TopbarContainer then return TopbarContainer end

	local player = game.Players.LocalPlayer
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

	local container = Instance.new("Frame")
	container.Name = "CenterContainer"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 0, 48) 
	container.Position = UDim2.new(0, 0, 0, 40) 
	container.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10) 
	layout.Parent = container

	TopbarContainer = container
	return TopbarContainer
end

-- CONSTRUCTOR: Membuat Objek Tombol Baru (Sama seperti Icon.new() di TopbarPlus)
function KariTopbar.new(decalId)
	local self = setmetatable({}, KariTopbar)

	-- State
	self.IsSelected = false

	-- Callback Functions (kosong secara default)
	self.OnSelect = nil
	self.OnDeselect = nil

	-- Membangun UI
	local container = GetOrCreateContainer()

	local button = Instance.new("ImageButton")
	button.Name = "TopbarBtn_" .. tostring(decalId)
	button.Size = UDim2.new(0, 40, 0, 40) 
	button.BackgroundColor3 = Color3.fromRGB(16, 44, 87) 
	button.BackgroundTransparency = 0.2 -- Default opacity 80%
	button.AutoButtonColor = true 

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	local icon = Instance.new("ImageLabel")
	icon.Name = "DecalIcon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(0.75, 0, 0.75, 0) 
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)

	local parsedId = tostring(decalId)
	if not string.match(parsedId, "rbxassetid://") then
		parsedId = "rbxassetid://" .. parsedId
	end
	icon.Image = parsedId
	icon.Parent = button

	button.Parent = container
	self.Instance = button

	-- Menghubungkan klik dengan sistem Toggle internal
	self.Instance.Activated:Connect(function()
		self:Toggle()
	end)

	return self
end

-- METHOD: Mengikat fungsi saat tombol dipilih (Open) dan tidak dipilih (Close)
function KariTopbar:Bind(onSelectFunc, onDeselectFunc)
	self.OnSelect = onSelectFunc
	self.OnDeselect = onDeselectFunc
	return self -- Mengembalikan self agar bisa di-chaining (method chaining)
end

-- METHOD: Logika Toggle
function KariTopbar:Toggle()
	if self.IsSelected then
		self:Deselect()
	else
		self:Select()
	end
end

-- METHOD: Memilih tombol (Buka Menu)
function KariTopbar:Select()
	if self.IsSelected then return end

	-- SISTEM ANTI-BENTROK: Jika ada ikon lain yang sedang aktif, paksa Deselect ikon tersebut
	if ActiveIcon and ActiveIcon ~= self then
		ActiveIcon:Deselect()
	end

	self.IsSelected = true
	ActiveIcon = self

	-- UX Feedback: Saat aktif, tombol menjadi 100% solid (Opacity 100% / Transparency 0)
	-- Ini agar pemain tahu menu mana yang sedang terbuka.
	self.Instance.BackgroundTransparency = 0 

	if self.OnSelect then
		self.OnSelect()
	end
end

-- METHOD: Membatalkan pilihan tombol (Tutup Menu)
function KariTopbar:Deselect()
	if not self.IsSelected then return end

	self.IsSelected = false

	if ActiveIcon == self then
		ActiveIcon = nil
	end

	-- UX Feedback: Kembali ke opacity 80% (Transparency 0.2)
	self.Instance.BackgroundTransparency = 0.2 

	if self.OnDeselect then
		self.OnDeselect()
	end
end

return KariTopbar