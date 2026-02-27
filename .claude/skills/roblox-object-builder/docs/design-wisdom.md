# Roblox-Specific Design Knowledge

Non-obvious Roblox engine behaviors that affect visual quality.
Only covers things AI training data won't reliably get right.

---

## Room Sizing in Studs

Roblox studs ≠ real-world meters. These proportions are validated for Roblox scale:

| Room type | Floor area (studs²/person) | Ceiling height |
|-----------|---------------------------|----------------|
| Meeting / conference | 12-16 / person | >= 16 studs |
| Office (open plan) | 10-14 / person | >= 14 studs |
| Corridor / hallway | — | 10-12 studs |

Enclosed walls reduce perceived size. For 4+ occupant rooms, verify
`floorArea / maxOccupants >= 12` and `ceilingHeight >= 16`.

---

## Material Tiling on Large Surfaces

High-detail materials show repetitive tiling on large surfaces ("GMod look").

| Surface size | Safe materials |
|-------------|----------------|
| Large (> 20 studs) | `SmoothPlastic`, `Grass` |
| Medium (5-20 studs) | + `Sandstone`, `Wood` |
| Small (< 5 studs) | Any material |

Exception: `WoodPlanks` scales acceptably to ~30 studs (coarse grain).

```lua
-- Tiling artifact on large ground:
ground.Material = Enum.Material.Sandstone  -- avoid

-- Use SmoothPlastic + color instead:
ground.Material = Enum.Material.SmoothPlastic
ground.Color = Color3.fromRGB(195, 190, 180)  -- warm gray = stone feel
```

---

## Lighting & Atmosphere

### Theme presets

| Theme | ClockTime | Brightness | Ambient | Notes |
|-------|-----------|------------|---------|-------|
| Sci-fi | 6-7 | 0.7-0.9 | RGB(45, 43, 55) | Saturation -0.1 to -0.2 |
| Cyberpunk | 0-2 | 0.3-0.5 | RGB(15, 15, 25) | Bloom 0.8-1.0 |
| Bright/casual | 12-14 | 1.5-2.0 | — | Saturation 0.1-0.2 |
| Pastel/cute | 12-13 | 1.0-1.2 | — | Bloom threshold >= 0.95, intensity 0.2-0.3. NEVER Brightness > 1.3 |
| Indoor/office | 12 | 0.7-0.9 | RGB(50, 50, 55) | Supplement with PointLight inside (Brightness 1.0-1.5, Range 30-40) |

### Indoor rooms: avoid high global Brightness

For enclosed rooms, global `Brightness > 1.0` causes bright sky to bleed through
glass walls and over-expose the interior. Use interior PointLights instead.

### Standard post-processing trio

1. **Atmosphere**: Density 0.2-0.4, Haze 1-3
2. **BloomEffect**: Intensity 0.4-0.8, Size 15-25, Threshold 0.7-0.9
3. **ColorCorrectionEffect**: Overall tone control

---

## Small Prop Readability

A prop that cannot be identified in one second at player eye level is visual noise — it
degrades the scene's perceived quality rather than adding to it.

**Recognition threshold**: If the prop requires > 2 parts to be distinguishable from
a random blob, and the scale forces each part to < 0.5 studs, omit the prop instead.

**Rule: table dressing props (glasses, pitchers, cups, notepads)**

| Real object | Minimum recognizable shape | Skip if... |
|-------------|---------------------------|------------|
| Drinking glass | Cylinder body (H ≈ 1.2) + flat base disc | diameter < 0.4 studs |
| Pitcher / jug | Cylinder body + handle arc (WedgePart × 2) | if handle can't fit, use glass |
| Notepad | Flat rectangle + thin color band (cover edge) | always renderable |
| Cup | Cylinder body + saucer disc below | diameter < 0.4 studs |

Single cylinder = unrecognizable. Two cylinders (body + base) = recognizable as cup/glass.
If the real-world version would need > 3 parts AND fits inside a 0.5-stud cube: **omit it**.

Do NOT place decorative props for completeness if they cannot be recognized.
A bare table reads better than a table covered in unidentifiable cylinders.

---

## Rendering Gotchas

### Light-colored upholstered furniture causes room white-out

Chair seats and backrests are repeated many times in a room. If their color is near-white
(all RGB channels > 200), the room reads as over-exposed even when global Brightness is
within range. This is because the human eye integrates many similar-colored surfaces.

**Rule for upholstered furniture (chairs, sofas, benches)**:
- At least one RGB channel must be ≤ 150 (sufficient contrast anchor)
- Near-white (`RGB > 200` on all channels) is only acceptable if the floor and walls
  are significantly darker (difference ≥ 80 on at least one channel)

```lua
-- WRONG (all channels high → white-out in groups of 6+)
chair.Color = Color3.fromRGB(245, 240, 238)

-- RIGHT (espresso: dark, provides contrast against light walls)
chair.Color = Color3.fromRGB(50, 45, 42)

-- RIGHT (navy: mid-dark, still warm)
chair.Color = Color3.fromRGB(40, 55, 80)
```

Always follow the Design Brief color specification exactly.
Do NOT substitute lighter colors "for visibility" — the brief was designed for contrast.

### Pastel colors wash out on large surfaces

Near-white colors (all RGB channels > 220) cause white-out regardless of Bloom settings.

For large surfaces (> 5 studs):
- Max any RGB channel: **225**
- At least one channel <= **180** (saturation anchor)
- Adjacent surfaces differ >= **30** in one channel

### Neon material causes white-out on large areas

Large Neon (> 5 studs) + any Bloom = severe over-exposure.

- Neon only for: accent lines (< 0.4 studs wide), small glows (< 2 studs), lamp elements
- If Neon area > 20 studs²: replace with `SmoothPlastic` + `PointLight`
- Water surfaces: use `SmoothPlastic` with `Transparency 0.3-0.5`, not Neon

### Neon emits no actual light

`Neon` material glows visually but emits zero illumination.
Always pair with `PointLight` or `SpotLight` for actual light.

### Co-planar Z-fighting

Two opaque faces at the same world-space plane flicker. Offset the decorative
surface by **+0.05 studs** along the face normal.
