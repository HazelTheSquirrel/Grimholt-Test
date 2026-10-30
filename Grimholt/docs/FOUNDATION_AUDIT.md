# Grimholt Foundation Audit

Status: 2026-10-30
Engine target: Godot 4.7.2
Branch policy: all development directly on `main`

## Direction

Grimholt is an original multiplayer arena shooter. Its sole design reference is the gameplay and presentation quality of Halo 3. This is a principles-level reference only: Grimholt must use original code, names, worldbuilding, maps, weapons, characters, models, textures, animation, sound, music, interface artwork and visual identity. No Bungie or Microsoft game assets, trademarks, distinctive copied layouts, audio, story elements or other protected content may be included.

The goal is to translate broad design lessons into a distinct Grimholt identity:

- **Readable arena combat:** clear sightlines, fair engagements, consistent movement and weapon rules, and strong spatial readability.
- **Focused player dashboard:** a restrained HUD hierarchy that communicates health/shields (if a shield system is implemented), ammunition, equipment, match time, score and immediate combat events without obscuring the sight picture.
- **Distinct weapon sandbox:** weapons with deliberate roles, recognizable handling, meaningful trade-offs and reliable feedback.
- **Strong combat feedback:** original hit confirmation, damage direction when known, clear kill/respawn communication and readable state changes.
- **Polished multiplayer flow:** concise lobby, match start, scoreboard, round result and rematch transitions.
- **Original science-fiction identity:** Grimholt-specific silhouettes, materials, symbols, typography, palette, soundscape and environmental storytelling.

## Current implementation found on main

### Present
- Godot 4.7.2 project and procedural greybox arena.
- First-person player controller, basic rifle, ammo/reload, health, hit marker.
- Free-for-all score and round timer.
- ENet host/join skeleton and server-side combat validation.
- Server-driven bots with target acquisition, engagement-distance control, strafing, short-range obstacle steering and line-of-sight-gated fire.
- Minimap, kill feed, top-fragger label, scoreboard.
- Headless script validation and a gameplay smoke test.

### Foundation gaps

1. **Application and match state are not separated.** The game controller owns menu construction, match lifecycle, networking, combat, bots, scoreboard and HUD in one large script. The previous cyclic inheritance issue was removed by flattening the systems into one script; that fixed parsing, but it is not the intended long-term architecture.
2. **Pause is present but needs runtime verification.** ESC opens a local pause overlay. It must not freeze the network authority or other players.
3. **Options are incomplete.** The main menu currently exposes only fullscreen and master volume. Graphics, sound, controls and extras need real settings, persistence and validation rather than decorative menu labels.
4. **HUD needs a proper layout pass.** Existing elements are mostly labels positioned with anchors and offsets. There is no responsive HUD specification, scale setting, safe-area treatment or visual acceptance test.
5. **The reported oversized bar is not identifiable from source alone.** A screenshot is required before changing an unknown visual element.
6. **Multiplayer is prototype-grade.** The server owns damage, score and ammo, but there is no lag compensation, robust reconnect/session flow, packet-loss test, prediction/reconciliation or complete client disconnect handling.
7. **Bot navigation is still prototype-grade.** Bots now manage engagement distance, strafe, probe nearby obstacles and require a clear line of sight before firing. They still do not use navigation meshes, multi-step pathfinding, tactical cover selection or difficulty profiles.
8. **Gameplay content is very thin.** One greybox arena, one rifle, one FFA ruleset and placeholder actors are not yet a complete shooter foundation.
9. **Current CI is not visual QA.** Headless import, parse and smoke tests do not prove that a windowed menu is laid out correctly or that mouse interaction works.

## Required foundation order

### A. Application and match flow
- Explicit states: boot, main menu, lobby, loading, playing, local pause, match result, disconnect/error.
- One owner for transitions; no ad-hoc visibility toggles scattered through gameplay code.
- ESC opens the in-match pause menu: **Match verlassen**, **Optionen**, **Spiel verlassen**, and **Weiterspielen**.
- Leaving a match tears down the peer and actors cleanly; it must not silently leave a host session running.
- Local pause must not pause the network authority or other clients.

### B. Settings
- Graphics: window mode, resolution, VSync, quality presets.
- Sound: master, effects, music and voice buses (only as those buses are implemented).
- Controls: remapping, mouse sensitivity, invert look, crouch behavior.
- Extras: HUD scale/visibility, subtitles/accessibility and gameplay preferences.
- Settings must be saved, loaded, range-checked and applied consistently.

### C. HUD and presentation
- Treat the HUD as a player dashboard, not decoration.
- Keep the central sight picture clean; use deliberate corner/edge anchoring and resolution-aware scaling.
- Separate persistent status (ammo, health/shields where applicable, timer, score) from short-lived events (hit confirmation, damage direction, kill feed).
- Add damage direction only when the damage source and direction are known.
- Build a screenshot-based visual regression checklist at common 16:9 and ultrawide resolutions.
- All icons, typography, shapes, colors and panel compositions must be designed specifically for Grimholt.

### D. Runtime and multiplayer correctness
- Separate state, presentation and input responsibilities using composition and signals, not cyclic script inheritance.
- Server-authoritative hit, damage, score, ammo, reload and respawn.
- Add host/client tests, disconnect tests, invalid RPC tests, latency and packet-loss scenarios.
- Add a deterministic match lifecycle test suite.

### E. Combat and maps
- Establish one polished rifle loop before adding more weapons.
- Expand the current short-range steering into navigation-aware pathfinding, tactical cover selection and difficulty profiles; test movement and line-of-sight behavior.
- Design maps around sightlines, controlled engagement distances, cover, verticality and readable original landmarks.
- Build weapon and equipment roles around a coherent sandbox; avoid copying any specific game's weapon roster or balance values.

## Reference-derived design principles

Halo 3 is useful as a high-level study of readable combat, a compact player information hierarchy, deliberate weapon roles, clear multiplayer communication and polished match presentation. These are general design lessons, not permission to reproduce Bungie's expression. Grimholt must create its own interface geometry, iconography, typography, color system, assets, terminology, sound and gameplay content.

Do not use Halo names, logos, character or faction designs, map layouts, weapon designs, UI artwork, sounds, music, extracted assets or recognizable copied compositions. Use only original Grimholt implementations.

## Current implementation status

The local in-match pause menu has been added. It offers Match verlassen, Optionen, Spiel verlassen and Weiterspielen. The Options page currently exposes the planned categories (Grafik, Sound, Steuerung, Extras), but those categories are navigation placeholders, not completed settings screens. A local pause flag gates local input without globally pausing the match simulation.

Do not call the foundation complete until the state flow, settings persistence, HUD visual QA and multiplayer test coverage above are implemented and verified.
