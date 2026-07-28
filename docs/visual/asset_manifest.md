# Visual Asset Manifest

The project logic is complete with greybox visuals. Replace only the visual elements listed below.

## Hero 2D

Current source sheets are stored in Google Drive under `Версия 8/assets/hero/source_sheets`:

- `hero_ready.png` — idle / katana ready.
- `hero_attack.png` — quick attack.
- `hero_heavy.png` — strong attack.
- `hero_jump.png` — jump.
- `hero_dash.png` — dash.
- `hero_death.png` — hit / death.

The repository intentionally uses a geometric placeholder so the project remains independent from final art. Replace the `PlayerVisual` child or rebuild it as `AnimatedSprite2D` without changing the `Player2D` root or collision node.

## Required 2D visual sets

- hero idle, run, jump, dash, quick attack, strong attack, death;
- melee ordinary enemy;
- ranged ordinary enemy;
- elite Rift Guardian;
- Ash Mask Kensei boss;
- Zero Seal Fragment artifact;
- weak wood/earth block;
- reinforced stone/metal support;
- structural level boundaries and gates;
- lower temple background;
- upper court background;
- energy wave and explosive talisman effects;
- protective seal HUD icon;
- technique energy meter;
- hit, break, parry and Duel Shift effects.

## Required 3D visual sets

Replace placeholder children under `PlayerRoot` and `EnemyRoot` with final models or sprite-based 3D representations. Preserve root node names.

Required animation states:

- idle stance;
- quick attack;
- heavy attack;
- guard;
- perfect parry;
- dodge;
- posture break;
- clean-hit finisher;
- boss phase transformation.

## Environment

The level is a gameplay greybox. Final environment art should preserve collision dimensions and route readability unless the scene layout is intentionally redesigned.
