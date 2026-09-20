# forever-barber-fix

## 1.0.0

- First release. Sitting in a barber chair on the WoW: Forever beta (1.60.1)
  throws `Blizzard_CharacterCustomize.lua:450: attempt to index global
  'CharacterCreateFrame' (a nil value)` and leaves Accept and Reset disabled,
  so no haircut can be confirmed. The addon replaces the one method that
  indexes that login-screen-only frame with a guard that does nothing in the
  world, which is what the retail version of the same file does. The patch is
  applied by a secure post-hook on `BarberShopFrame_LoadUI`, right after the
  panel's code loads and before it is shown, so the very first chair of a
  session already works. `/barberfix` prints whether the patch is active.
