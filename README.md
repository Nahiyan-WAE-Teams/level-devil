# LEVEL DEVIL

An original, mobile-first 2D trap platformer built with **Godot 4.4 / GDScript 2.0**.

The game takes inspiration from the broad trap-platformer genre: deceptively simple rooms, readable controls, surprising hazards, quick retries, and levels that teach players through discovery. Code, level layouts, visuals, and presentation are original.

## Open the project

1. Install Godot 4.4 or newer.
2. Clone this repository.
3. Open the repository folder in Godot Project Manager.
4. Run the project (F6/F5).

## Controls

| Action | Desktop | Android |
|---|---|---|
| Move left | A / Left Arrow | Left touch button |
| Move right | D / Right Arrow | Right touch button |
| Jump | Space / W / Up Arrow | Jump touch button |
| Restart | R | Pause menu → Restart |
| Pause | Escape | Pause button |

The game uses a landscape 960×540 logical viewport. Touch controls are drawn in-game. No account, API, or network connection is required.

## Current gameplay

- Two themed worlds with ten levels each (20 playable levels total).
- World and level selection with progression locks.
- Player movement, jump buffering and coyote-time assistance.
- Hidden spikes, collapsing platforms and falling blocks.
- Moving saws, reverse controls, gravity-flip zones and moving platforms.
- Fake exits, death counter, instant respawn and restart.
- Pause menu and level-completion flow.
- Local progress saving.
- Animated procedural character with running, airborne poses, blinking, squash-and-stretch, and trap-effect colors.
- Original generated ambient music loop and jump, trap, death, and completion sound effects.
- Simultaneous multi-finger movement and jump input on Android.
- Animated trap artwork, moving saw blades, death/exit particle bursts, and subtle screen shake.
- Layered industrial backdrops, framed HUD, and larger mobile control zones.
- Procedural visuals with no downloaded asset dependency.

## Project structure

```
project.godot
scenes/
  main.tscn
scripts/
  game.gd
  player.gd
  trap.gd
  level_catalog.gd
tests/
  smoke_test.gd
  catalog_test.gd
.github/workflows/
  godot-check.yml
```

## Validate

With Godot 4.4.1 available on PATH:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tests/catalog_test.gd --quit-after 180
godot --headless --path . --script tests/smoke_test.gd --quit-after 180\ngodot --headless --path . --script tests/audio_test.gd --quit-after 180
```

GitHub Actions runs import, catalog, gameplay, and audio checks on pushes and pull requests to `main`.

## Android APK\n\nAn Android debug export preset is included in `export_presets.cfg`. The `Android debug APK` workflow exports an arm64 APK for device testing and uploads it as the `level-devil-android-debug` artifact. Run it from the Actions tab with **Run workflow**, or push a game change to `main`. The build uses a CI-generated debug signing key and is for testing, not Play Store release signing.\n\nThe game requests no Internet permission and keeps progress locally on the device. Android export is landscape-only.\n\n## Adding levels

Edit `scripts/level_catalog.gd`. Add a level dictionary to a world's `levels` array. Each level supports:

- `name` and `hint`
- `platforms`: Array of `Rect2` floor/platform rectangles
- `moving_platforms`: rectangles with `distance` and `speed`
- `traps`: `spikes`, `collapse`, `falling`, `reverse`, `gravity`, `saw`, or `fake_exit`

## Design principles

- Offline-first: no mandatory network services.
- Data-driven level progression: add content without rewriting the game manager.
- Fast failure loop: traps teach through quick, readable consequences.
- Mobile readability: landscape playfield and large touch targets.
- Expandable systems: levels, hazards, UI, audio and saves can evolve independently.

## Release status

The project is a playable development build, not a finished commercial release. Android APK export and real-device testing are still required before calling it device-verified. Further polish should include hand-authored sprite sheets, accessibility settings, improved trap telegraphs, and real-device performance testing.
