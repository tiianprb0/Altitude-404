-- =========================
-- CLIENT: KABUT SYSTEM (STAY)
-- =========================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local kabutFolder = ReplicatedStorage:WaitForChild("kabut")
local event = kabutFolder:WaitForChild("ShowFogEvent")

local activeFog = nil

event.OnClientEvent:Connect(function()
	if activeFog then return end

	-- container
	local container = Instance.new("Folder")
	container.Name = "kabutClient"
	container.Parent = workspace

	activeFog = container

	-- clone efek
	for _,v in pairs(kabutFolder:GetChildren()) do
		if not v:IsA("RemoteEvent") then
			local clone = v:Clone()
			clone.Parent = container

			-- fade in particle
			if clone:IsA("ParticleEmitter") then
				clone.Enabled = true
				clone.Rate = 0

				TweenService:Create(clone, TweenInfo.new(2), {
					Rate = 30
				}):Play()
			end
		end
	end
end)