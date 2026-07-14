# Ghost Katana: Duel Shift

Godot/Xogot prototype.

## Current repository state

The `development` branch contains the currently provided project files:

- `scenes/levels/Level2D.tscn`
- `scripts/Level2D.gd`
- `scripts/Player2D.gd`
- `scripts/Enemy2D.gd`
- `scripts/DuelArena3D.gd`
- `scripts/player_3d_marker.gd`
- `docs/level_1_plan.md`

## Important missing files

The repository is not yet a complete runnable Godot project. The following required files were not provided and are not present:

- `project.godot`
- `scripts/GameManager.gd`
- `scenes/duel/DuelArena3D.tscn`

Because these files are missing, the project cannot yet be verified by launching it from GitHub.

## Intended prototype cycle

`Level2D → Enemy2D → DuelArena3D → Win → Level2D → defeated enemy disappears`

See `docs/level_1_plan.md` for the current level plan.
