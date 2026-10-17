# surviving-mars-relaunched-mods
Collection of mods for Surviving Mars Relaunched.

## Quick Setup / Auto-Linking Windows (For Developers)

Instead of manually copying mod folders into the game's directory, you can use the included `link_mods.bat` script.
It creates Windows directory junctions (folder links) from `Mods Konsti` directly into your `%AppData%\Surviving Mars Relaunched\Mods` folder.

### How to use:
1. Clone or download this repository anywhere on your PC.
2. Double-click **`link_mods.bat`**
3. All mods inside `Mods Konsti` will appear inside your game's `Mods` folder and stay automatically in sync whenever you pull updates or edit files.
To unlink a mod, simply delete its shortcut folder inside `%AppData%\Surviving Mars Relaunched\Mods`.
