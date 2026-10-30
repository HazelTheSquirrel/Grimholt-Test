# Grimholt Foundation Audit

Status: 2026-10-30  
Engine target: Godot 4.7.2  
Branch policy: all development directly on `main`

## Direction

Grimholt is an original multiplayer arena / military shooter. The design references are Halo 3 and Battlefield: Bad Company 2, not source material to reproduce. The goal is to translate their design principles into original systems, maps, art, audio, names, and interface.

- **Halo 3:** readable combat HUD, strong weapon sandbox, consistent arena rules, concise multiplayer information, clear feedback for damage and threats.
- **Battlefield: Bad Company 2:** grounded military presentation, useful minimap and spotting, meaningful cover, flanking routes, squad/team communication, and environmental combat spaces.

## Current implementation found on main

### Present
- Godot 4.7.2 project and procedural greybox arena.
- First-person player controller, basic rifle, ammo/reload, health, hit marker.
- Free-for-all score and round timer.
- ENet host/join skeleton and server-side combat validation.
- Server-driven bots with basic target acquisition.
- Minimap, kill feed, top-fragger label, scoreboard.
- Headless script validation and a gameplay smoke test.

### Foundation gaps

1. **Application and match state are not separated.** The game controller owns menu construction, match lifecycle, networking, combat, bots, scoreboard and HUD in one large script. The previous cyclic inheritance issue was removed by flattening the systems into one script; that fixed parsing, but it is not the intended long-term architecture.
2. **Pause was missing.** ESC in the player script only released the mouse. There was no actual pause overlay or menu flow.
3. **Pause must be local in multiplayer.** Pausing a client must not freeze the authoritative server or other players. The pause state therefore gates only local input and leaves the shared match simulation running.
4. **Options are incomplete.** The main menu currently exposes only fullscreen and master volume. Graphics, sound, controls and extras need real settings, persistence and validation rather than decorative menu labels.
5. **HUD needs a proper layout pass.** Existing elements are mostly labels positioned with anchors and offsets. There is no responsive HUD specification, scale setting, safe-area treatment or visual acceptance test.
6. **The reported oversized bar is not identifiable from source alone.** The current HUD creates labels, a minimap, a crosshair and a hidden scoreboard panel; it does not create a visible full-width HUD bar. A screenshot is required before changing an unknown visual element.
7. **Multiplayer is prototype-grade.** The server owns damage, score and ammo, but there is no lag compensation, robust reconnect/session flow, packet-loss test, prediction/reconciliation or complete client disconnect handling.
8. **Bots do not navigate cover.** They pursue a target directly and fire; they do not use navigation meshes, tactical cover, squad behavior or difficulty profiles.
9. **Gameplay content is very thin.** One greybox arena, one rifle, one FFA ruleset and placeholder actors are not yet a complete shooter foundation.
10. **Current CI is not visual QA.** Headless import, parse and smoke tests do not prove that a windowed menu is laid out correctly or that mouse interaction works.

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
- A single HUD layout with corner anchoring and resolution-aware scaling.
- Keep the central sight picture clean; show only combat-relevant information.
- Separate persistent status (ammo, health, timer, score) from short-lived events (hit confirmation, damage direction, kill feed).
- Add damage direction only when the damage source and direction are known.
- Build a screenshot-based visual regression checklist at common 16:9 and ultrawide resolutions.

### D. Runtime and multiplayer correctness
- Separate state, presentation and input responsibilities using composition and signals, not cyclic script inheritance.
- Server-authoritative hit, damage, score, ammo, reload and respawn.
- Add host/client tests, disconnect tests, invalid RPC tests, latency and packet-loss scenarios.
- Add a deterministic match lifecycle test suite.

### E. Combat and maps
- Establish one polished rifle loop before adding more weapons.
- Add navigation-aware bots and test their use of cover.
- Design maps around sightlines, cover, flank routes, verticality and readable landmarks.
- Consider spotting, squad/team play and environmental destruction as later systems, not cosmetic promises.

## Reference-derived design principles

- Bungie's Halo 3 HUD specification explicitly treats the HUD as a player dashboard, calls for corner/center anchor points and resolution scaling, and describes directional damage feedback and threat indicators. Grimholt should adopt the information hierarchy and resolution-aware layout principles, not copy Halo artwork.
- The Halo 3 manual describes a HUD that communicates equipment, health/shields, nearby friend/foe information, weapons/ammo and multiplayer status. This is a useful checklist for deciding which information belongs on screen.
- The Bad Company 2 PC manual documents separate settings for on-foot, vehicle and pilot controls, a minimap with friend/enemy/player markers, and combat advice centered on cover and flanking. Grimholt should build settings around actual control contexts and make map/cover gameplay meaningful before adding visual clutter.

## Current change in progress

The local in-match pause menu has been added as a first foundation step. It offers Match verlassen, Optionen, Spiel verlassen and Weiterspielen. The Options page currently exposes the planned categories (Grafik, Sound, Steuerung, Extras), but those categories are navigation placeholders, not completed settings screens. A local pause flag gates local input without globally pausing the match simulation.

Do not call the foundation complete until the state flow, settings persistence, HUD visual QA and multiplayer test coverage above are implemented and verified.
