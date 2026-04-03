--[[
    RAIN SCRIPT CLIENT (INTENSITY AWARE + CUSTOM COLLISION)
    Script ini membaca 'RainType' dari Lighting dan menyesuaikan intensitas Module Rain.
    - UPDATE (KARINA): Menambahkan logika Collision Mode Function.
    - UPDATE (KARINA): String.find digunakan agar partikel visual mendeteksi "Pohon cp 1", dll.
]]

local Lighting = game:GetService("Lighting")
local RainModule = require(script:WaitForChild("Rain"))

-- === CUSTOM COLLISION FILTER (KARINA LOGIC) ===
local function customRainCollisionFilter(part)
	if not part then return false end

	local current = part
	local isPohon = false
	local isGubuk = false

	while current and current ~= workspace do
		if current:GetAttribute("tembusHujan") == true then
			return false 
		end

		local lowerName = string.lower(current.Name)
		-- KARINA FIX: Substring match untuk menyesuaikan dengan penamaan dinamis di Explorer
		if string.find(lowerName, "pohon") then
			isPohon = true
		elseif string.find(lowerName, "gubuk") then
			isGubuk = true
		end

		current = current.Parent
	end

	if isPohon then
		return false 
	end

	if isGubuk then
		return true 
	end

	return true 
end

RainModule:SetCollisionMode(RainModule.CollisionMode.Function, customRainCollisionFilter)

local RainPresets = {
	Drizzle = {
		Intensity = 0.15,
		Speed = 0.5,
		Transparency = 0.6,
		Volume = 0.2
	},
	Normal = {
		Intensity = 0.5,
		Speed = 0.8,
		Transparency = 0.2,
		Volume = 0.5
	},
	Storm = {
		Intensity = 1.0,
		Speed = 1.0,
		Transparency = 0,
		Volume = 1.0
	}
}

local function updateRainParameters(rainType)
	local preset = RainPresets[rainType] or RainPresets.Normal

	RainModule:SetIntensityRatio(preset.Intensity)
	RainModule:SetSpeedRatio(preset.Speed)
	RainModule:SetTransparency(preset.Transparency)
	RainModule:SetVolume(preset.Volume)

	RainModule:SetColor(Color3.fromRGB(script.Color.Value.x, script.Color.Value.y, script.Color.Value.z))
	RainModule:SetDirection(script.Direction.Value)
	RainModule:SetLightInfluence(script.LightInfluence.Value)
	RainModule:SetLightEmission(script.LightEmission.Value)
	RainModule:SetSoundId(script.SoundId.Value)

	RainModule:SetStraightTexture(script.StraightTexture.Value)
	RainModule:SetTopDownTexture(script.TopDownTexture.Value)
	RainModule:SetSplashTexture(script.SplashTexture.Value)
end

local function checkWeather()
	local isRaining = Lighting:GetAttribute("IsRaining")
	local rainType = Lighting:GetAttribute("RainType") or "Normal"

	if isRaining then
		updateRainParameters(rainType)
		RainModule:Enable()
	else
		RainModule:Disable()
	end
end

Lighting:GetAttributeChangedSignal("IsRaining"):Connect(checkWeather)
Lighting:GetAttributeChangedSignal("RainType"):Connect(checkWeather)

task.wait(1)
checkWeather()