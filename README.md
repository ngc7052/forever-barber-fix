# ForeverBarberFix

Makes the barber chair usable in the **World of Warcraft: Forever** beta.

Sit down on the beta today and you get a Lua error, the Accept and Reset
buttons stay grey, and there is no way to confirm the haircut. The barber panel
is full-screen and swallows the keyboard, so you cannot even type a `/run` to
get around it. This addon fixes the one broken line before the panel is shown.
It is Blizzard's own "Barber Chairs cause a LUA error" from the beta
known-issues list.

## Install

**[Download the latest release →](../../releases/latest)** and unzip it into
your Forever beta AddOns folder, so that you end up with

```
World of Warcraft\_classic_beta_\Interface\AddOns\ForeverBarberFix\ForeverBarberFix.toc
```

Then log out to the character select screen, tick **Forever Barber Fix** in the
AddOns list, and log back in. A `/reload` is not enough for a new addon folder;
the client only picks new addons up at character select.

## Check that it works

Sit in any barber chair. Chat prints

```
ForeverBarberFix: barber shop patch applied.
```

no error appears, and **Accept** lights up as soon as you change something.

Outside the chair, `/barberfix` reports whether the patch is active.

## What it fixes

The Forever client loads a Forever-specific copy of the character customize
frame that was written for the character-creation screen. One of its methods
indexes `CharacterCreateFrame`, which exists only on the login screens:

```
Blizzard_CharacterCustomize/Camelot/Blizzard_CharacterCustomize.lua:450:
attempt to index global 'CharacterCreateFrame' (a nil value)
```

In the world that global is nil. The throw happens inside the panel's OnShow,
on the way from `SetSelectedCategory` through `UpdateCameraMode` and
`UpdateZoomButtonStates` to `UpdateSmallButtons`, which is before the panel
reaches the code that enables Accept and Reset. Every option you click reruns
the same path and errors again, so the buttons never wake up. Your choices do
reach the server, because the client-side call that records them runs one line
before the failing update; only the button to submit them is dead.

## How it works

The addon replaces `CharCustomizeFrame.UpdateSmallButtons` with a guard that
returns immediately when `CharacterCreateFrame` is nil and otherwise calls the
original. Retail's version of the same file has no `UpdateSmallButtons` at all,
so in the world this is exactly the retail behaviour.

Timing is the only subtle part. The customize frame lives in a load-on-demand
Blizzard addon that is loaded by `BarberShopFrame_LoadUI()` immediately before
`ShowUIPanel(BarberShopFrame)`. A `hooksecurefunc` post-hook on that function
runs after the frame exists and before it is shown, so the first chair of the
session already works. The addon-loaded event and the barber-open event are
hooked as well, as a fallback. The barber UI calls no protected functions, so
the replaced method cannot cause "action blocked" errors elsewhere.

## When to remove it

When "Barber Chairs cause a LUA error" leaves Blizzard's known-issues list.
Leaving it installed after that is harmless: the guard only changes behaviour
where the game would have thrown.

## Build a zip yourself

```bash
tools/package.sh      # dist/ForeverBarberFix-<version>.zip
```

The version comes from `## Version:` in the TOC. History: [CHANGELOG.md](CHANGELOG.md).

## Licence

MIT. World of Warcraft is a trademark of Blizzard Entertainment, Inc.
