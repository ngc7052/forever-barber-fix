-- ForeverBarberFix
--
-- WoW: Forever beta (1.60.1) loads a Camelot-specific copy of Blizzard_CharacterCustomize
-- that was written for the character-creation screen. Its UpdateSmallButtons() indexes the
-- glue-only global CharacterCreateFrame:
--
--   Blizzard_CharacterCustomize/Camelot/Blizzard_CharacterCustomize.lua:450
--   attempt to index global 'CharacterCreateFrame' (a nil value)
--
-- In the world that global is nil, so the call chain
--   BarberShopFrame:OnShow -> UpdateCharCustomizationFrame -> SetCustomizations
--   -> SetSelectedCategory -> UpdateCameraMode -> UpdateZoomButtonStates -> UpdateSmallButtons
-- throws before BarberShopFrame:UpdateButtons() runs, and the Accept / Reset buttons
-- never get enabled. Retail's version of the file has no UpdateSmallButtons at all, so
-- making it a no-op outside the glue screen restores retail behaviour.
--
-- Timing: Blizzard_CharacterCustomize is LoadOnDemand and is loaded by
-- BarberShopFrame_LoadUI() right before ShowUIPanel(BarberShopFrame). A secure post-hook on
-- BarberShopFrame_LoadUI therefore runs after the frame exists and before OnShow fires.

local ADDON_NAME = ...
local BLIZZ_ADDON = "Blizzard_CharacterCustomize"
local PREFIX = "|cff33ff99ForeverBarberFix|r: "

local function GuardedUpdateSmallButtons(self, ...)
	-- Only the character-creation (glue) screen has CharacterCreateFrame. In the world, do nothing.
	if not CharacterCreateFrame then
		return
	end
	local orig = self.ForeverBarberFix_OrigUpdateSmallButtons
	if orig then
		return orig(self, ...)
	end
end

local function PatchTable(t)
	if not t or t.UpdateSmallButtons == GuardedUpdateSmallButtons then
		return false
	end
	t.ForeverBarberFix_OrigUpdateSmallButtons = t.UpdateSmallButtons
	t.UpdateSmallButtons = GuardedUpdateSmallButtons
	return true
end

local announced = false

local function Patch()
	local changed = false
	-- The live frame (methods were copied from the mixin at frame creation).
	changed = PatchTable(CharCustomizeFrame) or changed
	-- The mixin, for any frame created from it later.
	changed = PatchTable(CharCustomizeMixin) or changed

	if changed and not announced then
		announced = true
		print(PREFIX .. "barber shop patch applied.")
	end
	return changed
end

local function IsPatched()
	return CharCustomizeFrame ~= nil and CharCustomizeFrame.UpdateSmallButtons == GuardedUpdateSmallButtons
end

-- 1) Primary hook: runs after Blizzard_BarberShopUI (and its dependency) are loaded,
--    before BarberShopFrame is shown.
if type(BarberShopFrame_LoadUI) == "function" then
	hooksecurefunc("BarberShopFrame_LoadUI", Patch)
end

-- 2) Backup: patch whenever Blizzard_CharacterCustomize loads for any other reason,
--    or if it is already loaded when this addon loads.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("BARBER_SHOP_OPEN")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == BLIZZ_ADDON then
			Patch()
		end
	elseif event == "BARBER_SHOP_OPEN" then
		Patch()
	end
end)

if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(BLIZZ_ADDON) then
	Patch()
end

-- 3) /barberfix : status and manual re-apply (usable outside the chair).
SLASH_FOREVERBARBERFIX1 = "/barberfix"
SlashCmdList.FOREVERBARBERFIX = function()
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(BLIZZ_ADDON)
	if not loaded then
		print(PREFIX .. BLIZZ_ADDON .. " not loaded yet; the patch is applied automatically when you sit in a barber chair.")
		return
	end
	Patch()
	print(PREFIX .. (IsPatched() and "patch is active." or "patch could NOT be applied (CharCustomizeFrame missing?)."))
end
