# FRONTLINE: Rift Arena

A modular first-person sci-fi arena shooter prototype for Godot 4.7.2.

The gameplay direction combines fast arena combat, regenerating energy shields and weapon swapping with round-based, precision-focused firefights. It uses original placeholder geometry and project naming; no Halo or Counter-Strike assets are included.

## Current demo systems

- First-person mouse look with reliable click-to-capture and Escape release
- WASD movement, sprint and jump using named Godot input actions
- 60 FPS cap and 60 physics ticks per second
- Regenerating energy shields plus health and automatic respawn
- Automatic rifle and heavy sidearm with separate magazines and reserves
- Hitscan damage, headshot bonus, reloading and weapon switching
- Basic hostile AI with simple obstacle steering and melee attacks
- Escalating enemy waves and score tracking
- Pause overlay with resume, restart and quit
- HUD for shields, health, ammo, score and wave
- Procedurally assembled sci-fi arena using primitive meshes and collisions

## Controls

| Input | Action |
|---|---|
| Click inside game window | Capture mouse / begin aiming |
| Mouse | Aim |
| WASD | Move |
| Left mouse | Fire |
| R | Reload current weapon |
| Q | Switch weapon |
| Shift | Sprint |
| Space | Jump |
| Escape | Pause / release mouse; Escape again resumes |

If the mouse is released, click inside the game window to capture it again. If the game window loses focus, the pointer is released intentionally.

## Run

1. Install Godot 4.7.2.
2. Clone or download this repository and open the folder containing project.godot.
3. Press F6/F5 or the Play button.
4. Click inside the game window to capture the mouse.

## Project layout

- scenes/: main.tscn, player.tscn, enemy.tscn
- scripts/game/: main.gd, game_manager.gd
- scripts/player/: player_controller.gd
- scripts/weapons/: weapon_controller.gd
- scripts/enemies/: enemy_ai.gd
- scripts/ui/: hud.gd
- scripts/world/: arena_builder.gd

## Remaining release work

This is a single-player prototype, not a finished multiplayer release. The current AI uses lightweight ray-based obstacle steering rather than a baked navigation mesh. LAN multiplayer, audio, animated character and weapon models, effects, accessibility options, controller support, packaged Windows builds and cross-platform playtesting remain separate release milestones. A successful Godot editor/runtime test is required before calling any downloadable build verified.

## Performance

The project requests a 60 FPS maximum and 60 physics ticks per second. Actual sustained 60 FPS depends on the target PC, graphics driver and display configuration.
