# Ghost Katana: Duel Shift

Godot/Xogot game prototype.

## Current repository status

The actual Godot/Xogot project has not yet been uploaded to this repository. At present, gameplay, scenes, scripts, resources and project settings cannot be verified from source files.

## Required baseline upload

Upload the complete existing project directory containing at minimum:

- `project.godot`
- all existing `.tscn` / `.scn` scene files
- all existing `.gd` scripts
- all referenced textures, sprites, models, audio and resources

Do not reorganize, rename, delete or rewrite project files before the first complete upload. The first upload must preserve the factual current state of the project for technical audit.

## Repository workflow

- `main` — stable, verified project state
- `development` or feature branches — work in progress
- changes should enter `main` through reviewed pull requests

## Technical documentation

- [`docs/project_state.md`](docs/project_state.md) — verified repository state and mandatory next step
- [`docs/scene_map.md`](docs/scene_map.md) — scene hierarchy based only on actual scene files
- [`docs/mechanics_status.md`](docs/mechanics_status.md) — mechanics verification table

## Current restriction

Do not add replacement gameplay systems, a new GameManager, Autoload configuration, substitute scenes or speculative architecture until the complete existing project is uploaded and audited.
