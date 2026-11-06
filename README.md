# LEVEL DEVIL

An original, mobile-first 2D precision platformer built with **Godot 4.4 / GDScript 2.0**.

This project takes inspiration from the broad trap-platformer genre: deceptively simple rooms, readable controls, surprising hazards, fast retries, and levels that teach players through discovery. All code, level layouts, visuals, and presentation in this repository are original.

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
| Restart | R | Reopen/retry from a future pause menu |
| Pause | Escape | Tap while paused |

The game is designed for landscape orientation and a 960×540 logical viewport. Touch controls are drawn into the game and do not require a network connection.

## Current playable foundation

- Five original short levels.
- Character movement, jump buffering, and coyote-time assistance.
- Hidden spike trigger, collapsing platform, and falling-block traps.
- Quick respawn and death counter.
- Exit door progression and local save data.
- Mobile touch controls and keyboard input.
- Procedural primitive visuals, so the project runs without downloaded assets.

## Project structure

```
project.godot
scenes/
  main.tscn
scripts/
  game.gd
  player.gd
  trap.gd
tests/
  smoke_test.gd
.github/workflows/
  godot-check.yml
```

## Run the smoke test

With Godot available on your PATH:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tests/smoke_test.gd
```

## Design principles

- Offline-first: no API, account, or network dependency.
- Data-driven level progression: new rooms can be added to the level definitions.
- Fast failure loop: hazards should restart quickly and teach the player something.
- Mobile readability: large touch targets and a fixed logical landscape canvas.
- Expandable systems: traps, levels, presentation, audio, and save data can evolve independently.

## Current scope

This is the first playable foundation, not a finished commercial release. The next development passes should add a full level-select flow, additional trap families, proper animated character art, sound/music, accessibility settings, and device-tested Android export.
