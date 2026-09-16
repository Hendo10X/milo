# Milo

A small 2D arcade stacking game built in **Godot 4.7**.

Milo is a dog trapped at the bottom of an endless well. Blocks slide across
the screen; tap to drop them and build a tower under him. Stack cleanly and
he climbs. Stack badly and the tower sways, wobbles, and eventually falls.
All the while, the water is rising.

**Build as high as you can before the water reaches Milo.**

The full design document lives in [docs/DESIGN.md](docs/DESIGN.md). This
README covers how the code is put together.

## Running it

1. Install [Godot 4.7](https://godotengine.org/download).
2. Open `project.godot` and press **Play** (F5).

Controls: **click / tap / Space** to drop, **Esc / P** to pause.

## What's in the MVP

- Endless brick well, ground, rising water with catch-up
- Milo: primitive-drawn dog with idle bob, eye tracking, hops, squash &
  stretch, moods (idle → worried → scared) driven by tower stability
- One block type: slides, drops under gravity, lands, stacks
- Overlap → rating (PERFECT / STABLE / UNSTABLE / CRITICAL / miss)
- Stability score that sways the tower, shakes the camera, and collapses it
  at zero
- Difficulty curve (block speed, block width, water speed) by blocks placed
- Height score, saved best, PERFECT popup
- Menu → playing → paused → game over → instant restart

## Project layout

```
scenes/
  main/Main.tscn        root scene: World, Milo, BlockSpawner, UI
  blocks/Block.tscn     RigidBody2D block
  player/Milo.tscn
  world/Well.tscn       brick walls + ground collider
  world/Water.tscn
  ui/HUD.tscn  MainMenu.tscn  GameOver.tscn  PauseMenu.tscn
scripts/
  game/game.gd          game manager: state machine, wiring, score
  game/game_state.gd    autoload: State enum, best height, save/load
  game/difficulty.gd    every difficulty knob, as functions of blocks placed
  game/dev_tools.gd     command-line autoplay / screenshot helper
  blocks/block.gd       MOVING → FALLING → PLACED | MISSED
  blocks/block_spawner.gd
  world/tower.gd        placed blocks, overlap, stability, sway, collapse
  world/water.gd
  world/well.gd
  world/game_camera.gd
  player/milo.gd
  ui/hud.gd  main_menu.gd  game_over.gd  pause_menu.gd
```

## How the pieces talk

`game.gd` wires everything in `_ready()` so scenes contain no cross-node
paths. Systems communicate with signals:

```
BlockSpawner.block_spawned/block_dropped  ─▶  Milo (look at it / hop)
Block.landed                              ─▶  BlockSpawner ─▶ Tower.try_place()
Tower.block_placed(block, overlap, rating)─▶  Game ─▶ HUD, Milo, Camera
Tower.block_missed / stability_changed    ─▶  Game ─▶ Milo, HUD
Tower.collapsed                           ─▶  Game.game_over()
Water.reached_target                      ─▶  Game.game_over()
```

### Coordinates

The world origin is the centre of the ground surface. The tower grows into
negative y. `Tower` is the pivot the whole stack rotates around when it
sways; placed blocks are its children. `BlockSpawner` shares the origin so a
block's local x is its distance from the well centre.

### Block physics

A block is a `RigidBody2D` the whole way through:

- **MOVING**: frozen in kinematic mode, the spawner sets its x each tick.
- **FALLING**: unfrozen, gravity ×2.6 for a snappy drop.
- **PLACED**: on first contact the tower measures overlap, freezes the block
  in static mode, and snaps it flush on top of the stack.
- **MISSED**: overlap under `miss_threshold` — left dynamic so physics tips
  it off the edge and it splashes away.

On collapse, the top 12 blocks are released and shoved sideways.

## Tuning

| What | Where |
|------|-------|
| Block speed, width, water speed curves | `scripts/game/difficulty.gd` |
| Overlap thresholds, stability gains/losses, sway, jolt | exports/consts at the top of `scripts/world/tower.gd` |
| Water catch-up | `CATCH_UP_GAP` / `CATCH_UP_RATE` in `water.gd` |
| Camera framing and smoothing | exports in `game_camera.gd` |
| Milo's moods vs stability | `Milo.set_stability()` |

## Dev tools

`scripts/game/dev_tools.gd` reads user args after `--`:

```bash
Godot_v4.7-stable_win64_console.exe --path . -- --autoplay --frames=3000 --error=200
```

- `--autoplay` starts a game and drops blocks automatically (random error
  `--error=N` px, default 70) and logs every placement.
- `--frames=N` quits after N frames; add `--screenshot=path.png` to capture
  the last frame. Works with `--headless` (minus the screenshot).

Delete the `DevTools` node from `Main.tscn` to remove the feature.

## Roadmap

See [docs/DESIGN.md](docs/DESIGN.md) §22–24: v0.2 adds combos, sound,
milestones and richer reactions; v0.3 adds block variety; 1.0 is the
polished release.
