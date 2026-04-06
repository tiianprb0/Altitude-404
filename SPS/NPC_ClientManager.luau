--[[
    KARINA - CLIENT-SIDED NPC MANAGER (ADVANCED)
    Tempatkan script ini di: StarterPlayer -> StarterPlayerScripts
    
    Fitur Baru:
    - Head Tracking: Leher NPC menoleh halus ke pemain dalam radius tertentu.
    - One-time Wave: NPC melambai 1 kali saat pemain masuk radius (tidak looping).
    - Quest Marker: Tanda seru merah di sisi kiri kepala (nyerong), hilang saat interaksi pertama.
]]

local ChatService = game:GetService("Chat")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local npcFolder = Workspace:WaitForChild("InteractiveNPCs", 10)

if not npcFolder then
	warn("Karina: Folder 'InteractiveNPCs' tidak ditemukan di Workspace!")
	return
end

-- ================= KONFIGURASI UMUM ================= --
local ANIMATION_ID = "rbxassetid://507766388"
local WAVE_ANIM_ID = "rbxassetid://507770239" -- Animasi Melambai R15 Default
local LOOK_RADIUS = 15 -- Jarak radius deteksi untuk menoleh & melambai
local PROMPT_TEXT = "Bicara"
local KEY_CODE = Enum.KeyCode.E
local COOLDOWN_TIME = 3 

-- ================= LOGIKA PROGRAM ================= --

local function setupNPC(npc)
	local humanoid = npc:WaitForChild("Humanoid", 5)
	local rootPart = npc:WaitForChild("HumanoidRootPart", 5)
	local head = npc:WaitForChild("Head", 5)

	if not humanoid or not rootPart or not head then return end

	local animator = humanoid:WaitForChild("Animator", 5) or Instance.new("Animator", humanoid)
	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15

	-- Optimasi Dasar
	rootPart.Anchored = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

	-- Setup Animasi Idle
	local animObj = Instance.new("Animation")
	animObj.AnimationId = ANIMATION_ID
	local track = animator:LoadAnimation(animObj)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Idle
	track:Play()

	-- Setup Animasi Melambai
	local waveObj = Instance.new("Animation")
	waveObj.AnimationId = WAVE_ANIM_ID
	local waveTrack = animator:LoadAnimation(waveObj)
	waveTrack.Priority = Enum.AnimationPriority.Action
	waveTrack.Looped = false -- Memaksa animasi agar tidak berulang terus-menerus

	-- Setup UI Tanda Seru (!)
	local questMarker = Instance.new("BillboardGui")
	questMarker.Name = "QuestMarker"
	questMarker.Size = UDim2.new(1.5, 0, 1.5, 0)
	-- Menggunakan ExtentsOffset: X = -1.2 (Kiri NPC), Y = 1.5 (Atas), Z = -0.5 (Agak ke depan)
	questMarker.ExtentsOffset = Vector3.new(-1.2, 1.5, -0.5) 
	questMarker.AlwaysOnTop = true

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "!"
	textLabel.TextColor3 = Color3.new(1, 0, 0.1) -- Merah
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.Rotation = -15 -- Membuat tanda seru miring (nyerong)
	textLabel.Parent = questMarker
	questMarker.Parent = head

	-- Setup ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = npc.Name
	prompt.ActionText = PROMPT_TEXT
	prompt.KeyboardKeyCode = KEY_CODE
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = rootPart

	-- Variabel State
	local isTalking = false
	local hasWaved = false

	-- Mencari Sendi Leher (Motor6D) untuk dimanipulasi
	local neck = head:FindFirstChild("Neck")
	if not neck and npc:FindFirstChild("Torso") then
		neck = npc.Torso:FindFirstChild("Neck") -- Fallback R6
	end
	local originalNeckC0 = neck and neck.C0 or CFrame.identity

	-- Loop Per-Frame untuk Head Tracking
	local renderConnection
	renderConnection = RunService.RenderStepped:Connect(function()
		if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

		local playerRoot = localPlayer.Character.HumanoidRootPart
		local playerHead = localPlayer.Character:FindFirstChild("Head")
		if not playerHead then return end

		local distance = (rootPart.Position - playerRoot.Position).Magnitude

		-- Jika pemain masuk dalam radius
		if distance <= LOOK_RADIUS then
			-- 1. Picu animasi melambai HANYA SEKALI per kunjungan
			if not hasWaved then
				hasWaved = true
				waveTrack:Play()
			end

			-- 2. Logika Kepala Melihat Pemain (Trigonometri Vektor)
			if neck then
				-- Konversi posisi pemain ke posisi relatif dari badan NPC
				local relativeDir = rootPart.CFrame:PointToObjectSpace(playerHead.Position)
				local yaw = math.atan2(-relativeDir.X, -relativeDir.Z) 
				local pitch = math.asin(relativeDir.Y / relativeDir.Magnitude) 

				-- Batasi putaran leher agar tidak berputar 360 derajat (maks 60 derajat)
				yaw = math.clamp(yaw, -math.rad(60), math.rad(60))
				pitch = math.clamp(pitch, -math.rad(45), math.rad(45))

				-- Lerp digunakan agar pergerakan leher sangat mulus (tidak patah-patah)
				if isR15 then
					local targetC0 = originalNeckC0 * CFrame.Angles(pitch, yaw, 0)
					neck.C0 = neck.C0:Lerp(targetC0, 0.1)
				else
					local targetC0 = originalNeckC0 * CFrame.Angles(0, -yaw, 0) * CFrame.Angles(pitch, 0, 0)
					neck.C0 = neck.C0:Lerp(targetC0, 0.1)
				end
			end
		else
			-- Jika pemain menjauh, kembalikan posisi leher ke posisi Idle perlahan
			if neck and neck.C0 ~= originalNeckC0 then
				neck.C0 = neck.C0:Lerp(originalNeckC0, 0.1)
			end

			-- Reset state melambai agar NPC bisa menyapa lagi jika pemain datang kembali
			hasWaved = false
		end
	end)

	-- Logika saat tombol E ditekan
	prompt.Triggered:Connect(function(player)
		if player ~= localPlayer then return end
		if isTalking then return end
		isTalking = true

		prompt.Enabled = false

		-- Hapus Tanda Seru (!) secara permanen setelah NPC dibuka pertama kali
		if questMarker then
			questMarker:Destroy()
			questMarker = nil
		end

		local dialogText = npc:GetAttribute("Dialog") or "Halo! Aku belum diberikan dialog oleh Tian."
		ChatService:Chat(npc.Head, dialogText, Enum.ChatColor.Blue)

		task.wait(COOLDOWN_TIME)
		prompt.Enabled = true
		isTalking = false
	end)

	-- Bersihkan memori jika NPC dihapus dari map
	npc.AncestryChanged:Connect(function(_, parent)
		if not parent and renderConnection then
			renderConnection:Disconnect()
		end
	end)
end

-- Inisialisasi
for _, child in ipairs(npcFolder:GetChildren()) do
	if child:IsA("Model") then
		task.spawn(function()
			setupNPC(child)
		end)
	end
end

npcFolder.ChildAdded:Connect(function(child)
	if child:IsA("Model") then
		task.spawn(function()
			setupNPC(child)
		end)
	end
end)