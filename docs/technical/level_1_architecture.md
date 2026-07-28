# Level 1 Technical Architecture

## Canonical mode boundary

### Main 2D mode

The 2D mode owns story progression, exploration, platforming, ordinary combat and environmental interaction.

Available systems:

- katana quick and strong attacks;
- ordinary firearm with magazine, fire cooldown and reload;
- Blade and Breaker techniques using technique energy;
- Focus slowdown using technique energy;
- dash;
- destructible weak and reinforced structures;
- melee and ranged ordinary enemies;
- Zero Seal Fragment artifact;
- protective seal;
- checkpoints and persistent world state.

The firearm and techniques are independent systems. Neither replaces the other or the katana.

### Duel Shift

Duel Shift is a katana-only combat scene. It must not read or expose the 2D firearm, Focus or technique actions.

Available duel actions:

- quick attack;
- heavy attack;
- guard;
- perfect parry;
- dodge.

Forbidden in Duel Shift:

- firearm;
- Focus;
- Blade technique;
- Breaker technique;
- ordinary 2D destruction systems.

## Autoloads

- `GameManager.gd` — transient run state, persistent 2D destruction, duel context and scene transitions.
- `SaveManager.gd` — permanent completion state in `user://ghost_katana_save.cfg`.
- `SfxManager.gd` — procedural placeholder sound cues.

## 2D scene

`Level2D.tscn` contains:

- one player;
- weak and reinforced destructible objects;
- melee and ranged ordinary enemies;
- artifact chamber;
- elite Duel Shift trigger;
- persistent gate;
- upper court checkpoint;
- two-phase boss Duel Shift trigger;
- final exit;
- mobile HUD and story panels.

## Persistent state

The following values survive 2D → Duel Shift → 2D scene reloads:

- destroyed object IDs;
- defeated ordinary enemy IDs;
- defeated elite and boss IDs;
- artifact collection;
- selected technique;
- protective seal count;
- technique energy;
- alarm state;
- destroyed support / arena debris state;
- player return and checkpoint positions.

Firearm ammunition is a local 2D combat state and is refilled when the player instance is rebuilt.

## Damage types

- `slash` — weak objects and enemies;
- `dash` — weak objects and enemies;
- `heavy` — weak and reinforced objects;
- `bullet` — ordinary firearm damage in 2D;
- `energy` — Blade technique projectile;
- `explosive` — Breaker area damage and reinforced destruction.

## Duel combat

The duel uses real Node3D geometry with placeholder meshes. Combat is posture-based:

- quick attack: low posture damage;
- heavy attack: high posture damage;
- normal guard: consumes player posture;
- perfect parry: damages enemy posture;
- dodge: avoids the strike and damages enemy posture;
- broken enemy posture: temporary clean-hit window;
- clean hit: ends an elite duel or advances/ends the boss phase;
- clean hit on player: lethal unless a seal is available.

`GameManager.start_duel()` clears `focus_active` before scene transition. Duel scripts must not call `world_time_factor()`.

## Safe visual replacement rule

Visual children may be replaced. Preserve:

- `Player2D`, `CollisionShape2D`, `PlayerVisual`, `Camera2D`;
- enemy root nodes and their `CollisionShape2D`;
- destructible root nodes and child `Visual`;
- `PlayerRoot`, `EnemyRoot`, `ArenaDebris` in the duel arena;
- all UI button and label names referenced by scripts.
