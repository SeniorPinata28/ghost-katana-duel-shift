# Ghost Katana: Duel Shift — Version 8 / Level 1

Godot 4 / Xogot project for iPad.

## Main loop

Fast destructible 2D level → artifact and technique choice → ordinary enemies → elite 3D duel → return to the same persistent 2D state → upper court → two-phase boss duel → level exit.

## Launch

Open the folder containing `project.godot` in Xogot and run the project.

Main scene:

`res://scenes/levels/Level2D.tscn`

## Mobile controls

- Left / Right — movement.
- Jump — jump with coyote time and jump buffer.
- Attack tap — quick katana strike.
- Attack hold — strong strike.
- Dash/Focus tap — dash.
- Dash/Focus hold — slow enemies while draining technique energy.
- Technique — Blade energy wave or Breaker explosive talisman.

## Duel controls

- Quick — fast posture damage.
- Heavy — stronger posture damage.
- Guard — block; press close to impact for perfect parry.
- Dodge — short invulnerability window.

## Combat rule

A clean hit is lethal. The Zero Seal Fragment grants one protective seal that absorbs one lethal hit.

## Visual replacement

All enemy, environment, artifact and 3D meshes are placeholders. Replace their visual child nodes without changing scripts, node names or collision nodes. See `docs/visual/asset_manifest.md`.
