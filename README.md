# Ghost Katana: Duel Shift — Version 8 / Level 1

Godot 4 / Xogot project for iPad.

## Canonical game structure

Story-driven 2D exploration and combat → artifact and technique choice → ordinary melee and ranged enemies → elite Duel Shift → return to the same persistent 2D state → upper court → two-phase boss duel → level exit.

## 2D systems

The 2D mode is the main story and exploration mode. It contains:

- movement, jumping and dash;
- katana quick and strong attacks;
- ordinary firearm combat with magazine and reload;
- Blade and Breaker techniques as a separate additional system;
- Focus time slowdown;
- ordinary melee and ranged enemies;
- destructible weak and reinforced structures;
- persistent destruction, enemy defeat and checkpoint state;
- the Zero Seal Fragment artifact and protective seal.

The firearm does not replace the katana. Techniques do not replace the firearm. All three systems coexist in 2D.

## Duel Shift rules

Duel Shift is a dedicated katana-only mastery test.

Available actions:

- quick attack;
- heavy attack;
- guard;
- perfect parry;
- dodge.

Not available in Duel Shift:

- firearm;
- Focus;
- Blade or Breaker techniques;
- destructible-level combat systems.

A clean hit is lethal. The Zero Seal Fragment grants one protective seal that absorbs one lethal hit. Boss duels use multiple clean-hit phases.

## Controls

Desktop:

- A / D or arrows — movement;
- Space — jump;
- J — katana attack;
- I — firearm;
- K — dash / Focus;
- L — technique;
- R — restart.

Mobile controls must expose separate Katana, Firearm, Technique and Dash/Focus actions.

## Main scene

`res://scenes/levels/Level2D.tscn`

## Visual replacement

Enemy, environment, artifact and 3D meshes remain placeholders. Replace visual child nodes without changing scripts, root node names or collision nodes. See `docs/visual/asset_manifest.md`.
