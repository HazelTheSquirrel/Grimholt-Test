# Grimholt – Seamless World Asset Pack

Original, project-authored 256 × 256 SVG textures. Every texture is a repeating vector pattern with no external image dependencies. The SVGs tile seamlessly by design and remain crisp when imported at different resolutions.

## Textures

| File | Intended use |
|---|---|
| `grass_meadow.svg` | Meadow ground and open grassland |
| `forest_moss.svg` | Shaded forest floor |
| `rock_slate.svg` | Mountain rock and cliff faces |
| `earth_dirt.svg` | Soil, paths and exposed earth |
| `gravel_sand.svg` | River banks, dry ground and gravel |
| `snow_ice.svg` | Alpine snow and ice |
| `bark_wood.svg` | Tree trunks and wood props |
| `leaves_canopy.svg` | Foliage and canopy detail |

## Materials

Reusable Godot 4 StandardMaterial3D resources are in `../materials`. The terrain material uses triplanar projection to avoid stretched UVs across steep slopes; vertex colors from the procedural biome system tint the grass texture. Bark and canopy materials are assigned to the instanced trees.

## Import

Open the project in Godot 4.7.2 and allow the SVG importer to finish. Do not move the textures without updating their material resource paths. All source textures are vector SVG files; no third-party textures are included.
