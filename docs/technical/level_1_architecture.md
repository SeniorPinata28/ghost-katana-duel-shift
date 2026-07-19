# Level 1 Technical Architecture

## Autoloads

- `GameManager.gd` — transient run state, persistent 2D destruction, duel context and scene transitions.
- `SaveManager.gd` — permanent completion state in `user://ghost_katana_save.cfg`.
- `SfxManager.gd` — procedural placeholder sound cues requiring no external audio files.

## 2D scene

`Level2D.tscn` contains the complete first-level greybox:

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

The following values survive 2D → 3D → 2D scene reloads:

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

## Damage types

- `slash` — damages weak objects and enemies.
- `dash` — damages weak objects and enemies.
- `heavy` — damages weak and reinforced objects.
- `energy` — player technique projectile.
- `explosive` — area damage and reinforced destruction.

## 3D duel

The 3D duel is real Node3D geometry with placeholder meshes. Combat is posture-based:

- quick attack: low posture damage;
- heavy attack: high posture damage;
- normal guard: consumes one player posture segment;
- perfect parry: damages enemy posture;
- dodge: avoids the strike and damages enemy posture;
- broken enemy posture: temporary clean-hit window;
- clean hit: ends an elite duel or advances/ends the boss phase;
- clean hit on player: lethal unless a seal is available.

## Safe visual replacement rule

Visual children may be replaced. Keep these node names and types:

- `Player2D`, `CollisionShape2D`, `PlayerVisual`, `Camera2D`;
- enemy root nodes and their `CollisionShape2D`;
- destructible root nodes and child `Visual`;
- `PlayerRoot`, `EnemyRoot`, `ArenaDebris` in the 3D arena;
- all UI button and label names referenced by scripts.
