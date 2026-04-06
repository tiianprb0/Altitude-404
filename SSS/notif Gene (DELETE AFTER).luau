--[[
    KARINA - NOTIFICATION GUI GENERATOR (DELETED AFTER)
    Simpan script ini di ServerScriptService.
    Fungsi: Men-generate GUI dengan tema Cinematic agar bisa kamu Copy ke StarterGui.
]]

local Players = game:GetService("Players")

local THEME = {
	MainBG = Color3.fromRGB(30, 59, 103),
	SidebarBG = Color3.fromRGB(20, 45, 85),
	CardBG = Color3.fromRGB(40, 75, 125),
	Accent = Color3.fromRGB(247, 173, 175),
	TextMain = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(175, 195, 225)
}
local FONT_GLOBAL = Enum.Font.Montserrat
local FONT_BOLD = Enum.Font.Montserrat

local function BuildNotifUI(player)
	local pGui = player:WaitForChild("PlayerGui", 20)
	if not pGui then return end

	if pGui:FindFirstChild("Notification Bar") then pGui["Notification Bar"]:Destroy() end

	local notifGui = Instance.new("ScreenGui")
	notifGui.Name = "Notification Bar"
	notifGui.ResetOnSpawn = false
	notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	notifGui.DisplayOrder = 1000
	-- Enabled = true agar kamu bisa lihat saat Play dan mencopynya.
	notifGui.Enabled = true 
	notifGui.Parent = pGui

	local bg = Instance.new("Frame", notifGui)
	bg.Name = "Background"
	bg.Size = UDim2.new(0, 380, 0, 80)
	bg.AnchorPoint = Vector2.new(0.5, 0)
	-- Posisi sengaja ditaruh di tengah layar (Y: 40) agar terlihat jelas saat di-Play
	bg.Position = UDim2.new(0.5, 0, 0, 40)
	bg.BackgroundColor3 = THEME.MainBG
	bg.Visible = true
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", bg)
	stroke.Color = THEME.SidebarBG
	stroke.Thickness = 2

	local icon = Instance.new("ImageLabel", bg)
	icon.Name = "imageProfile"
	icon.Size = UDim2.new(0, 50, 0, 50)
	icon.Position = UDim2.new(0, 15, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundColor3 = THEME.CardBG
	icon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0) 

	local nameLabel = Instance.new("TextLabel", bg)
	nameLabel.Name = "name"
	nameLabel.Size = UDim2.new(0.6, 0, 0, 20)
	nameLabel.Position = UDim2.new(0, 80, 0, 15)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = FONT_BOLD
	nameLabel.Text = "Name"
	nameLabel.TextColor3 = THEME.TextMain
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left

	local typeLabel = Instance.new("TextLabel", bg)
	typeLabel.Name = "typeANN"
	typeLabel.Size = UDim2.new(0.4, -15, 0, 20)
	typeLabel.Position = UDim2.new(0.6, 0, 0, 15)
	typeLabel.BackgroundTransparency = 1
	typeLabel.Font = FONT_GLOBAL
	typeLabel.Text = "NOW"
	typeLabel.TextColor3 = THEME.Accent
	typeLabel.TextSize = 12
	typeLabel.TextXAlignment = Enum.TextXAlignment.Right

	local contentLabel = Instance.new("TextLabel", bg)
	contentLabel.Name = "isi"
	contentLabel.Size = UDim2.new(1, -95, 0, 35)
	contentLabel.Position = UDim2.new(0, 80, 0, 35)
	contentLabel.BackgroundTransparency = 1
	contentLabel.Font = FONT_GLOBAL
	contentLabel.Text = "Isi pengumuman di sini..."
	contentLabel.TextColor3 = THEME.TextMuted
	contentLabel.TextSize = 13
	contentLabel.TextWrapped = true
	contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	contentLabel.TextYAlignment = Enum.TextYAlignment.Top

	print("[KARINA] Notification Bar GUI Generated! Silakan copy dari PlayerGui.")
end

for _, p in pairs(Players:GetPlayers()) do task.spawn(BuildNotifUI, p) end
Players.PlayerAdded:Connect(BuildNotifUI)