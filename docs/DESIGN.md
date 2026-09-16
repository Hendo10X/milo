# Milo — Design Document

## 1. Project Overview

Milo is a simple 2D arcade stacking game built with Godot.

The player must help Milo, a small dog trapped at the bottom of an endless
well, escape by stacking rectangular blocks beneath him.

Blocks move horizontally across the screen. The player controls when each
block is dropped. Good placement creates a stable tower and allows Milo to
climb higher. Poor placement makes the tower increasingly unstable.

At the same time, water continuously rises from the bottom of the well.

The objective is simple: **build as high as possible and save Milo before
the water reaches him.**

The game is designed around a very small, repeatable gameplay loop with
increasing difficulty and strong game feel.

## 2. Project Goals

**Primary goals**

- Create a fun and replayable 2D arcade game.
- Keep the controls extremely simple.
- Make the game easy to understand without a tutorial.
- Create tension through the rising water.
- Give Milo personality through simple animation.
- Use minimal visual assets.
- Build the game entirely with simple shapes and procedural/simple graphics.
- Keep the codebase simple enough for a two-person development team.
- Use the project as our first serious Godot game and learning project.

**Non-goals** — the first version will NOT include: multiplayer, online
accounts, complex progression systems, character customization, inventory,
shops, power-ups, in-app purchases, procedural worlds, complex story, large
amounts of content, 3D, advanced enemy systems.

The focus is one excellent gameplay loop.

## 3. Core Gameplay

```
Block appears → Player positions block → Player drops block → Block lands
→ Tower grows → Milo climbs → Water rises → Difficulty increases → Repeat
```

The player continues until:

1. The tower becomes too unstable and collapses, or
2. The water reaches Milo.

After failure, the player can immediately restart.

## 4. Core Game Rules

### 4.1 Blocks

Blocks are rectangular platforms. Each block moves horizontally, can be
dropped by the player, is affected by gravity, collides with other blocks,
and becomes part of the tower when successfully placed.

The first version uses only one block type. Variety can come later.

### 4.2 Block Positioning

The current block moves horizontally across the screen. The player
taps/clicks to drop it. The goal is to overlap the new block with the block
beneath it. The less overlap there is, the more unstable the tower becomes.

## 5. Tower Stability

Every placed block contributes to tower stability. The game calculates how
well the current block overlaps the previous platform.

| Overlap | Rating |
|---------|--------|
| 90%+ | PERFECT |
| 60–89% | STABLE |
| 30–59% | UNSTABLE |
| <30% | CRITICAL |

These values are starting points and should be adjusted during playtesting.

Stability should affect the physical behaviour of the tower rather than
simply displaying a number: slight tower movement, block wobble, Milo
reacting, increased chance of collapse. The player should be able to
visually understand that their tower is becoming dangerous.

## 6. Milo

Milo is the main character with an intentionally very simple visual design:
rectangles, circles, lines, simple shapes, basic animations. No external
character art is required for the MVP.

```
       ┌─────────────┐
       │  •       •  │
       │      ◡      │
       └─────────────┘
        │  │   │  │
```

## 7. Milo Animation

Required animations — small and cheap; the goal is personality, not visual
complexity:

- **Idle** — small breathing/bobbing movement.
- **Looking** — eyes follow the incoming block.
- **Drop** — Milo looks toward the falling block.
- **Successful landing** — a small bounce.
- **Perfect landing** — Milo becomes excited.
- **Unstable tower** — Milo looks worried.
- **Critical stability** — Milo reacts strongly to the tower movement.
- **Game over** — Milo reacts when the player loses.

## 8. Water

Water is the primary pressure mechanic. It starts near the bottom of the
well and gradually rises: slow early, moderate mid-game, fast late. It should
never feel completely unfair — the player should always understand
"I need to build faster."

## 9. Height / Score

The primary score is the height reached by Milo (`HEIGHT 127m`). The game
also stores `BEST 214m`. The score increases whenever Milo successfully
climbs to another block.

## 10. Perfect Drops

A highly accurate placement triggers `PERFECT!`. Feedback should be short
and satisfying: small text animation, Milo reaction, subtle camera movement,
small sound effect, tiny particle effect. Avoid excessive visual effects.

## 11. Combo System

Consecutive perfect placements build a combo (`PERFECT x2`, `x3`, …).
Missing a perfect resets it. It is primarily a psychological/replayability
mechanic encouraging increasingly accurate drops.

## 12. Difficulty Progression

Difficulty increases naturally with height.

- **Stage 1 — Learning** (first ~10–20 blocks): slow block movement, wide
  blocks, slow water, forgiving placement. Teaches the game without
  instructions.
- **Stage 2 — Building**: faster blocks, slightly smaller blocks, increasing
  water speed, stability becomes important. Player actively thinks about
  placement.
- **Stage 3 — Pressure**: faster blocks, narrower blocks, faster water, more
  tower movement. Creates tension.
- **Stage 4 — Panic**: very fast blocks, difficult positioning, rapidly
  rising water, unstable towers. Creates the "one more block" feeling.

## 13. Milestones

Height milestones: 10m, 25m, 50m, 100m, 250m, 500m, 1000m. Milestones can
introduce subtle visual changes (background, well pattern, lighting, water
behaviour, ambient effects) that do not require new artwork.

## 14. Camera

The camera follows Milo upward smoothly rather than snapping; the lower
well gradually disappears. When the tower is unstable the camera can shake
very subtly. Avoid excessive camera effects.

## 15. Controls

One primary action. Mobile: tap = DROP. Desktop: mouse click = DROP;
optional Space.

## 16. Game States

```
MENU → PLAYING → PAUSED → PLAYING → GAME_OVER → RESTART → PLAYING
```

Possible future states: SETTINGS, TUTORIAL.

## 17. Main Scenes

```
Main.tscn
├── World
│   ├── Well
│   ├── Tower
│   ├── Water
│   └── Camera2D
├── Milo
├── BlockSpawner
└── UI
```

## 18. Recommended Project Structure

```
milo/
├── project.godot
├── scenes/
│   ├── main/Main.tscn
│   ├── player/Milo.tscn
│   ├── blocks/Block.tscn
│   ├── world/Well.tscn, Water.tscn
│   └── ui/HUD.tscn, MainMenu.tscn, GameOver.tscn
├── scripts/
│   ├── game/game.gd, game_state.gd
│   ├── player/milo.gd
│   ├── blocks/block.gd, block_spawner.gd
│   ├── world/tower.gd, water.gd
│   └── ui/hud.gd
├── assets/audio, fonts, textures
├── resources/
└── README.md
```

## 19. Technical Architecture

Keep it simple. Main systems: Game Manager → Block Spawner, Tower, Milo,
Water, UI.

- **Game Manager**: starting/restarting games, game states, score, best
  score, difficulty progression, game over.
- **Block Spawner**: creating blocks, block movement, size, speed.
- **Tower**: tracking placed blocks, overlap, stability, collapse, height.
- **Milo**: movement, climbing, animations, reactions.
- **Water**: rising, tracking Milo, triggering game over.
- **UI**: height, best, combo, pause, game over, restart.

## 20. MVP

The first playable version contains only:

- **World**: endless well, background, water.
- **Milo**: simple rectangle dog, four legs, eyes, idle animation, basic
  climbing movement.
- **Blocks**: one rectangular block; horizontal movement, drop, gravity,
  collision, stacking.
- **Gameplay**: height calculation, water rising, game over, restart.
- **UI**: current height, best height, restart button.

That's it.

## 21. MVP Success Criteria

- A player understands the objective without explanation.
- A player can start playing immediately.
- Blocks can be positioned and dropped; blocks stack correctly.
- Milo moves upward as the tower grows.
- Water creates pressure. The player can lose. The player can restart
  immediately. The player wants to try again.

**The game should be fun before adding content.**

## 22. Version 0.2

After the MVP is fun: perfect drops, combo system, Milo reactions, better
animations, sound effects, camera movement, tower wobble, improved water,
difficulty progression, milestones.

## 23. Version 0.3

Introduce block variety (Normal, Small, Wide, Fast, Heavy, Bouncy,
Slippery) — only if playtesting shows the game needs it.

## 24. Version 1.0

A polished small arcade game: polished core gameplay, multiple block
behaviours, difficulty progression, combo, milestones, sound, music,
animations, responsive UI, settings, saved high score, polished game-over
screen, mobile and desktop controls, performance optimisation.

No feature should be added simply to make the feature list longer.

## 25. Two-Person Team Structure

**Developer A — Gameplay & Systems**: block physics, spawning, tower system,
overlap, stability, water, difficulty, game state, scoring. Secondary:
tuning, debugging, optimisation.

**Developer B — Character, UI & Game Feel**: Milo, animations, reactions,
camera, HUD, menus, game-over screen, audio integration, visual feedback,
effects. Secondary: gameplay testing, difficulty tuning, QA.

## 26. Shared Responsibilities

Both developers participate in game design, playtesting, code reviews, bug
fixing, balancing, Git management and release preparation. Neither developer
should become the only person who understands a major system.

## 27. Development Workflow

```
Idea → Task → Branch → Implementation → Playtest → Pull Request → Review
→ Merge → Playtest again
```

Feature branches: `feature/block-system`, `feature/milo-animation`,
`feature/water-system`, `feature/tower-stability`, `feature/game-over`,
`feature/hud`.

## 28–30. First Three Weeks

- **Week 1 — Core Prototype.** A: project setup, main scene, block
  movement/spawning/dropping, physics, collision. B: Milo prototype, eyes,
  legs, basic movement, camera, basic HUD. → Milo + blocks + physics +
  camera, no polish.
- **Week 2 — Game Loop.** A: tower management, overlap, stability, water,
  height, game-over detection. B: Milo climbing and reactions, HUD,
  game-over screen, restart, basic animations. → a complete playable game.
- **Week 3 — Game Feel.** Both: tune block/water speed and difficulty,
  improve physics and Milo animation, add sound, perfect drops, combo,
  subtle camera effects, test repeatedly. Make the existing game feel good.

## 31. Playtesting

Give the first playable build to people without explaining it. Watch: do
they understand what to do, when to drop, why they lost? Do they notice
Milo, care about the water, immediately restart, play more than once? Where
do they get bored or frustrated? Do not immediately implement every
suggestion — watch what players actually do.

## 32. Design Principles

Simple controls. Immediate feedback. Increasing tension. Short sessions.
Personality without complexity. Minimal UI. No unnecessary systems.

## 33. Core Metrics

Average run duration, average height, best height, number of restarts,
first-game completion rate, average blocks placed, where players usually
fail. Manual playtesting is enough for the first version.

## 34. Definition of Done

Works + feels good + doesn't break other systems + has been playtested + has
been reviewed.

## 35. Studio Learning Goals

**Godot**: nodes, scenes, signals, resources, GDScript, physics, collision,
animation, Camera2D, UI, audio, particles, save systems, scene management.
**Game development**: game loops, game feel, physics, difficulty curves,
player feedback, game states, balancing, playtesting, production, shipping.
**Team**: Git workflows, code reviews, task planning, scope management,
production, releases.

## 36. The Golden Rule

Do not expand the game because we are excited about ideas. Every new
feature must answer: *does this make the core game more fun?* If not, it
goes into the backlog.

The objective is to prove that two developers can take an idea from
Idea → Prototype → Playable → Polished → Released.

Milo is our first shipped game.
