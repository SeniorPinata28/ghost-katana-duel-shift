# Ghost Katana: Duel Shift

Minimal runnable Godot/Xogot prototype for the first gameplay loop.

## Launch

Open the repository folder in Godot/Xogot and run the project.

Main scene:

`res://scenes/levels/Level2D.tscn`

Autoload:

`GameManager → res://scripts/GameManager.gd`

## Implemented prototype cycle

`Level2D → Enemy2D → DuelArena3D → Win/Lose → Level2D`

On victory, the defeated enemy disappears. On defeat, the player returns to the saved 2D position. The restart button clears the current run.

## Controls

Desktop:

- Left / Right arrows — movement
- Space / Enter — jump

Mobile/Xogot:

- LEFT / RIGHT — movement
- JUMP — jump
- RESTART — reset the run
- ATTACK / GUARD — duel actions

## 3D duel rules

The player and enemy now use the same combat parameters:

- HP: 3
- DEF: 3
- Damage: 1
- Identical capsule size and attack-lunge distance

Enemy phases:

- preparing attack — guard before the timer expires;
- guarding — attacks remove enemy DEF first;
- open — attacks damage enemy HP.

A successful player guard consumes one DEF point instead of HP. When DEF reaches zero, later enemy attacks damage HP. Attacking while the enemy prepares an attack triggers a counterattack.

## Current files

- `project.godot`
- `scenes/levels/Level2D.tscn`
- `scenes/duel/DuelArena3D.tscn`
- `scripts/GameManager.gd`
- `scripts/Level2D.gd`
- `scripts/Player2D.gd`
- `scripts/Enemy2D.gd`
- `scripts/DuelArena3D.gd`
- `scripts/player_3d_marker.gd`
- `docs/level_1_plan.md`

## Prototype status

This is a functional baseline made from temporary geometric visuals. It is intended for verifying the scene transition, movement, jump, duel loop, symmetric player/enemy stats, defense, victory, defeat, enemy removal and mobile input before adding final art or expanding gameplay.
