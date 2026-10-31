# FRONTLINE: Rift Arena

A modular first-person sci-fi arena shooter prototype for Godot 4.7.2.

The gameplay direction combines fast arena combat, regenerating energy shields, weapon swapping and round-based precision firefights. All current visuals and audio are generated from original procedural geometry and synthesized sound at runtime. No third-party or copyrighted game assets are included.

## Implemented prototype systems

- First-person mouse look, click-to-capture and Escape release
- WASD movement, sprint, jump and 60 Hz physics
- Regenerating shields, health, damage feedback, death overlay and automatic respawn
- Automatic rifle and heavy sidearm with independent magazines and reserves
- Hitscan fire, headshot damage bonus, muzzle flash, recoil, hit sparks and hit marker
- Reloading, weapon switching and synthesized weapon/damage/reload/wave sound effects
- Hostile AI with target pursuit, basic obstacle steering and melee attacks
- Enemy armor silhouette, emissive visor and damage flash
- Escalating enemy waves, score and hostile count
- Sci-fi arena blockout with collision, cover, trim lights, environmental glow and lighting
- HUD with anchored shield/health bars, ammo, score, wave, crosshair and pause/death overlays
- Pause, resume, restart and quit actions
- Headless smoke tests for scene startup, player/HUD/weapons, wave spawn, damage and enemy defeat

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

- scenes/: main, player and hostile scenes
- scripts/audio/: runtime synthesized SFX
- scripts/game/: game bootstrap and wave manager
- scripts/player/: FPS controller, shield and health systems
- scripts/weapons/: rifle/sidearm logic and procedural viewmodel
- scripts/enemies/: hostile AI and damage logic
- scripts/ui/: HUD, pause, damage and death overlays
- scripts/world/: procedural arena construction
- tests/: automated gameplay smoke tests

## Known limits before a public release

This is a playable single-player prototype, not a finished commercial-quality game. Character and weapon geometry is still procedural blockout art, not polished authored 3D assets. Enemy movement uses lightweight ray steering rather than a baked navigation mesh. Audio is synthesized placeholder SFX, not a professionally mixed soundscape. There is no multiplayer, controller support, settings menu, accessibility menu, save system, installer or cross-platform QA yet.

The CI workflow checks Godot import/parsing, boots the main scene headlessly and runs gameplay smoke tests. This is not a substitute for a human playtest with mouse/keyboard, audio hardware and a real GPU. Actual sustained 60 FPS depends on the test PC, graphics driver and resolution.
