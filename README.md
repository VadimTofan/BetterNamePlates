# BetterNamePlates

![BetterNamePlates icon](icon-readme.png)

BetterNamePlates is a lightweight, opinionated nameplate addon for World of
Warcraft Retail. It recreates the combat clarity of a focused Plater profile
without requiring Plater or its broader collection of features.

The addon is designed primarily for Mythic and Mythic+ combat, but its
nameplates remain active everywhere. There are no settings, profiles, or
configuration screens: BetterNamePlates has one carefully tuned presentation.

## Features

- Role-aware threat colors for tanks, healers, and damage dealers
- Distinct colors for casters, minibosses, bosses, and neutral enemies
- Castbars with spell icons and clear interruptible and protected states
- Interrupt cooldown markers showing when your interrupt becomes available
- Player-owned debuffs with compact timers and reversed cooldown progress
- Target borders, target arrows, mouseover borders, and raid target markers
- Compact nameplate stacking and a fixed 40-yard nameplate distance
- Health values, shortened names, and a layout tuned for crowded combat
- Seasonal rules for important casts, auras, and NPC classifications

## Fixed by Design

BetterNamePlates does not include an options panel or profile import system.
The appearance and behavior are part of the addon itself. If you want a highly
customizable nameplate framework, Plater remains the better choice; this addon
is for players who want this specific setup with a smaller, focused codebase.

## Installation

### CurseForge

Install BetterNamePlates from its
[CurseForge project page](https://www.curseforge.com/projects/1664307)
using the CurseForge app or a compatible addon manager.

### Manual installation

1. Download a packaged release from
   [GitHub Releases](https://github.com/VadimTofan/BetterNamePlates/releases).
2. Extract the archive into your Retail addon directory:
   `World of Warcraft/_retail_/Interface/AddOns/`.
3. Confirm that the resulting folder is named `BetterNamePlates`.
4. Restart World of Warcraft or run `/reload` if the addon was already copied
   before launching the game.

## Usage

BetterNamePlates enables itself automatically. No setup is required.

Run the following command in chat to inspect its current runtime and stacking
state:

```text
/bnp debug
```

The command reports whether the addon is enabled, how many nameplates it is
tracking, the latest plate admission result, and the active overlap values.

## Development

The runtime is written in Lua. Automated tests use
[Fengari](https://fengari.io/) to exercise the addon logic outside the game,
with an additional Node.js test for the release configuration.

```powershell
npm install
npm test
```

For an in-game smoke test, copy or clone the repository into the Retail
`Interface/AddOns/BetterNamePlates` directory, enable the addon, and run
`/reload`. Combat behavior still needs to be verified in World of Warcraft
because Blizzard's protected and secret-value APIs cannot be reproduced fully
by the automated test harness.

## Releases

Pushing a version tag matching `v*`, such as `v0.1.0`, runs the test suite and
packages the addon through GitHub Actions. Successful builds are published to
GitHub Releases and CurseForge.

## Status and Compatibility

BetterNamePlates is under active development and currently targets World of
Warcraft Retail. It is intentionally focused on dungeon and Mythic+ combat and
does not aim to replace every feature available in general-purpose nameplate
addons.

## Support

Report bugs and compatibility problems through
[GitHub Issues](https://github.com/VadimTofan/BetterNamePlates/issues). Include
the output of `/bnp debug`, the activity or dungeon where the problem occurred,
and any captured Lua error.

## Credits

BetterNamePlates began as a standalone recreation of a focused Plater profile.
Plater inspired the visual and combat-information goals, but BetterNamePlates
is an independent addon and does not require Plater to run.

Maintained by [Vadim Tofan](https://github.com/VadimTofan).
