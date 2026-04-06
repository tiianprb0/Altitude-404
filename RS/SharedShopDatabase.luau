--[[
    ESKA - SHARED SHOP DATABASE (SINGLE SOURCE OF TRUTH)
    Lokasi: ReplicatedStorage > SharedShopDatabase (ModuleScript)
    
    DESKRIPSI:
    Pangkalan data terpusat untuk seluruh item toko dan kode tebusan (Redeem).
    Dapat dibaca oleh Server (AltitudeShopBrain) untuk validasi, dan oleh 
    Client (AltitudeCatalogUI) untuk pembuatan UI secara dinamis.
]]

local SharedShopDatabase = {}

SharedShopDatabase.Items = {
	-- [DEV PRODUCTS: CREDITS]
	["C1"] = {Category = "Coins", PayType = "Robux", RobuxID = 3558143560, IsDevProduct = true, ActionType = "Currency", Value = 5000, Name = "5.000 Coins"},
	["C2"] = {Category = "Coins", PayType = "Robux", RobuxID = 3558144127, IsDevProduct = true, ActionType = "Currency", Value = 10000, Name = "10.000 Coins"},
	["C3"] = {Category = "Coins", PayType = "Robux", RobuxID = 3558144632, IsDevProduct = true, ActionType = "Currency", Value = 25000, Name = "25.000 Coins"},
	["C4"] = {Category = "Coins", PayType = "Robux", RobuxID = 3558145100, IsDevProduct = true, ActionType = "Currency", Value = 50000, Name = "50.000 Coins"},
	["C5"] = {Category = "Coins", PayType = "Robux", RobuxID = 3558145329, IsDevProduct = true, ActionType = "Currency", Value = 100000, Name = "100.000 Coins"},
	["C6"] = {Category = "Coins", PayType = "Robux", RobuxID = 3558145704, IsDevProduct = true, ActionType = "Currency", Value = 500000, Name = "500.000 Coins"},

	-- [TOOLS]
	["T1"] = {Category = "Tools", PayType = "Coins", Price = 5000, ActionType = "Tool", Name = "Umbrella"},
	["T2"] = {Category = "Tools", PayType = "Robux", RobuxID = 3559900223, IsDevProduct = true, ActionType = "Tool", Name = "Speed Coil"}, 

	-- [PERKS & KENDARAAN]
	["A2"]   = {Category = "Perks", PayType = "Robux", RobuxID = 3559900642, IsDevProduct = true, ActionType = "Perk", AttributeName = "HasVIP", Name = "VIP Access"},
	["P_HA"] = {Category = "Perks", PayType = "Coins", Price = 100000, ActionType = "Perk", AttributeName = "HasHideAura", Name = "Hide Aura"},
	["V_JS"] = {Category = "Vehicles", PayType = "Coins", Price = 100000, ActionType = "Perk", AttributeName = "HasJetSolo", Name = "JetSolo Access"},

	-- [AURAS]
	["A_CH"] = {Category = "Auras", PayType = "Coins", Price = 35000, ActionType = "Perk", AttributeName = "HasChained", Name = "Chained Aura"},
	["A_CO"] = {Category = "Auras", PayType = "Coins", Price = 1500, ActionType = "Perk", AttributeName = "HasCosmic", Name = "Cosmic Aura"},
	["A_CU"] = {Category = "Auras", PayType = "Coins", Price = 35000, ActionType = "Perk", AttributeName = "HasCubic", Name = "Cubic Aura"},
	["A_DS"] = {Category = "Auras", PayType = "Robux", RobuxID = 3559898227, IsDevProduct = true, ActionType = "Perk", AttributeName = "HasDualSwords", Name = "Dual Swords"},
	["A_FR"] = {Category = "Auras", PayType = "Robux", RobuxID = 3559898538, IsDevProduct = true, ActionType = "Perk", AttributeName = "HasFrost", Name = "Frost Aura"},
	["A_LO"] = {Category = "Auras", PayType = "Coins", Price = 10000, ActionType = "Perk", AttributeName = "HasLove", Name = "Love Aura"},
	["A_PO"] = {Category = "Auras", PayType = "Coins", Price = 75000, ActionType = "Perk", AttributeName = "HasPoison", Name = "Poison Aura"},
	["A_PL"] = {Category = "Auras", PayType = "Robux", RobuxID = 3559899136, IsDevProduct = true, ActionType = "Perk", AttributeName = "HasPowerless", Name = "Powerless"},
	["A_SD"] = {Category = "Auras", PayType = "Coins", Price = 100000, ActionType = "Perk", AttributeName = "HasSandDemon", Name = "Sand Demon"},
	["A_SN"] = {Category = "Auras", PayType = "Coins", Price = 100000, ActionType = "Perk", AttributeName = "HasSoundNinja", Name = "Sound Ninja"},
	["A_TG"] = {Category = "Auras", PayType = "Coins", Price = 125000, ActionType = "Perk", AttributeName = "HasThunderGod", Name = "Thunder God"},
}

SharedShopDatabase.RedeemCodes = {
	["WELCOME"] = {Type = "Coin", Value = 5000, Quantity = 15, Expiry = "2026-03-25"},
}

return SharedShopDatabase