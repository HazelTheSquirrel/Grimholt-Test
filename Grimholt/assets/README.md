# Grimholt – Seamless World Asset Pack

Original, project-authored SVG textures. The ground surfaces use seamless repeating vector patterns; the sky is a 2:1 panoramic SVG designed for Godot's PanoramaSkyMaterial.

## Textures

| File | Intended use |
|---|---|
| `grass_meadow.svg` | Meadow ground and open grassland |
| `forest_moss.svg` | Shaded forest floor |
| `rock_slate.svg` | Mountain rock and steep slopes |
| `earth_dirt.svg` | Soil and subtle ground variation |
| `gravel_sand.svg` | River banks, dry ground and gravel |
| `snow_ice.svg` | Alpine snow and ice |
| `bark_wood.svg` | Tree trunks and wood props |
| `leaves_canopy.svg` | Foliage and canopy detail |
| `sky_dawn_panorama.svg` | Custom dawn sky panorama with sun glow and layered clouds |

## Materials

`materials/terrain_grass.tres` is a ShaderMaterial using `terrain_blend.gdshader`. It triplanarly projects grass, moss, rock, dirt and snow maps in world space; steep slopes transition to rock and high elevations to snow. Existing biome vertex colors tint the surface. This avoids relying on a single grass image across every biome.

`environment/world_environment.tres` now uses the custom panoramic sky texture through PanoramaSkyMaterial. The other reusable StandardMaterial3D resources cover rock, bark and foliage.

## Import

Open the project in Godot 4.7.2 and allow the SVG importer to finish. Do not move textures without updating their resource paths. All source textures are project-authored SVG files; no third-party textures are included. A headless resource-load test checks the shader parameters and panorama resource, but final appearance still requires an in-editor GPU review.
