# FRONTLINE: Rift Arena

A modular first-person sci-fi arena shooter prototype for Godot 4.7.2.

The gameplay direction combines fast arena combat, regenerating energy shields and weapon swapping with round-based, precision-focused firefights. It uses original placeholder geometry and project naming; no Halo or Counter-Strike assets are included.

## Playable prototype

- First-person mouse look and WASD movement
- Sprint, jump and mouse capture
- 60 FPS cap and 60 physics ticks per second
- Regenerating energy shields plus health
- Automatic rifle and heavy sidearm
- Reloading, ammo reserves, weapon switching and hitscan damage
- Basic hostile AI, melee attacks and escalating waves
- Score, wave, remaining-hostiles, shield, health and ammo HUD
- Procedurally assembled sci-fi arena using primitive meshes and collisions

## Controls

| Input | Action |
|---|---|
| WASD | Move |
| Mouse | Aim |
| Left mouse | Fire |
| R | Reload |
| Q | Switch weapon |
| Shift | Sprint |
| Space | Jump |
| Escape | Release mouse |

## Run

1. Install Godot 4.7.2.
2. Clone or download this repository and open the folder containing project.godot.
3. Press F6/F5 or the Play button.
4. Click the game window to capture the mouse.

## Project layout

- scenes/: main.tscn, player.tscn, enemy.tscn
- scripts/game/: main.gd, game_manager.gd
- scripts/player/: player_controller.gd
- scripts/weapons/: weapon_controller.gd
- scripts/enemies/: enemy_ai.gd
- scripts/ui/: hud.gd
- scripts/world/: arena_builder.gd

## Prototype limitations

This is the first playable gameplay slice, not a release-ready multiplayer game. Enemy navigation is direct steering rather than navmesh pathfinding. LAN multiplayer, audio, polished weapon models, animation, menus, accessibility options, packaging and cross-platform testing remain follow-up work. Test the project in the target Godot editor before distributing builds.

## Performance

The project requests a 60 FPS maximum and 60 physics ticks per second. Actual sustained 60 FPS depends on the target PC, graphics driver and display configuration.
