# Design Wisdom

Non-obvious design knowledge that determines map/scene quality.
Focuses on what code alone cannot tell you.

## Contents

- [Zone Layout](#zone-layout) — Hub & Spoke, height variation, anti-square-box
- [Navigation & Flow](#navigation--flow) — Floor guide paths, queue zones
- [Color Palette](#color-palette) — Ratios, material assignment, scale rules
- [Building Facades](#building-facades) — Neon stripes, windows, base and cap
- [Ceilings & Overhead](#ceilings--overhead) — Beams, pipes, pendant lights
- [Detail Objects](#detail-objects) — Style sheet, shape vocabulary, detail budgets, prop rules
- [Atmosphere & PostEffects](#atmosphere--posteffects) — Lighting presets, pastel rules
- [Service Integration](#service-integration) — Trigger volumes, spawn paths

---

## Zone Layout

### Enclosed room sizing (CRITICAL for interiors)

Architectural minimums produce rooms that feel cramped once furnished and occupied.
Closed walls reduce perceived size — apply a spaciousness premium.

| Room type | Floor (studs²/person) | Ceiling height |
|-----------|----------------------|----------------|
| Meeting / conference | 12–16 / person | ≥ 16 studs |
| Office (open plan) | 10–14 / person | ≥ 14 studs |
| Corridor / hallway | — | 10–12 studs |

Rule: for any room holding 4+ occupants, verify `floorArea / maxOccupants >= 12`
and `ceilingHeight >= 16` before finalizing dimensions.

### Hub & Spoke

Best layout for game lobbies. Central plaza as hub, zones radiating outward.

```
Center: Plaza (open sightlines, landmark centerpiece)
North:  Departure (queue/gate)
South:  Arrival (spawn) — opposite from departure so players cross hub
East/West: Feature zones (shop, leaderboard, social)
```

### Height variation for enclosure

Surround hub with **varied height** buildings. Same-height walls = prison yard.

- Back (north): Tallest (60-90 studs)
- Sides: Medium (40-70 studs)
- Front (south/entry): Shortest (30-50 studs) — preserves openness

### Elevated walkways

Y=4-8 elevated paths above ground. Connect via ramps at corners. Neon railings
double as visual guides. Creates vertical layering cheaply.

### Breaking the "square box" trap (CRITICAL)

AI defaults to axis-aligned rectangles. Apply **at least 3** per map:

1. **Non-square central plaza**: Octagonal, circular (Cylinder floor), or sunken stepped
2. **Diagonal elements**: 45° walkways, angled buildings, diamond patterns
3. **Aggressive height variation**: Sunken (-2), raised (+4-8), elevated walkways, tiered rings
4. **Broken outlines**: Offset buildings from grid by 5-15 studs. Alternate alleys and plazas
5. **Organic curves**: Cylinder/Sphere arc walls, circular platforms
6. **CSG cutouts**: Arch openings, circular floor holes, rounded edges

---

## Navigation & Flow

### Floor guide paths

Thin neon lines (thickness 0.1, Transparency 0.3-0.5) guide players without UI.
Main route: prominent color. Sub route: subtle color. Width: 0.3-0.5 studs.

### Queue zone visual differentiation

Match entry areas must be clearly distinct:

- Different floor material/color (dark metal) + neon border lines
- Gate structure (pillars + crossbar) with PointLights
- Transparent trigger volume covering entire platform

---

## Color Palette

### Base-to-accent ratio

**Base 90-95% : accent 5-10%** regardless of theme.

```
Sci-fi:    Muted white/gray + neon red-pink/purple/green
Cyberpunk: Dark gray/black + neon cyan/red
Fantasy:   Stone/wood + magical glow (purple/gold)
```

### Material assignment

- `SmoothPlastic`: Large base surfaces (floor, wall, ceiling)
- `Metal`: Structural elements (pillars, beams, rails)
- `Concrete`: Darkest base elements
- `Neon`: Accent LINES only (minimize area)

### Material scale rule (CRITICAL)

High-detail materials show repetitive tiling on large surfaces ("GMod look").

| Surface size | Allowed materials |
|-------------|-------------------|
| Large (>20 studs) | `SmoothPlastic` or `Grass` only |
| Medium (5-20 studs) | + `Sandstone`, `Wood` |
| Small (<5 studs) | Any material |

Exception: `Wood`/`WoodPlanks` scale to ~30 studs (coarse grain).

```lua
-- WRONG: large ground with Sandstone → tiling artifacts
ground.Material = Enum.Material.Sandstone

-- CORRECT: SmoothPlastic + color for texture feel
ground.Material = Enum.Material.SmoothPlastic
ground.Color = Color3.fromRGB(195, 190, 180)  -- warm gray = stone feel
```

---

## Building Facades

### Vertical neon stripe

1-2 vertical neon lines (width 0.3-0.5, thickness 0.15) at 30% of building width.

### Horizontal accent band

Neon band at 60-70% of building height. Creates visual "waist."

### Window panels

Dark rectangles (4x5) + thin glow panels (Neon, Transparency 0.3-0.5).
Even rows: cool blue. Odd rows: warm white. Suggests "various rooms."

### Base and cap

- Base: 2 studs wider, dark color (visual stability)
- Cap: 1 stud wider, metal (clean silhouette)
- 60+ studs: antenna/spire with Neon + PointLight tip

---

## Ceilings & Overhead

### Ceiling beam grid

X/Z beams (width 2-3, height 1-2) in grid. Add diagonal trusses for industrial aesthetic.

### Hanging pipes

Horizontal Cylinders (dia 1-1.5) at varying heights. 2-3 vertical hangers per pipe.

### Pendant lights

Cable (0.3 × 12h × 0.3) → fixture (3×1.5×3) → glow panel (Neon).
PointLight (Brightness 0.8, Range 30-35, Shadows=true). 9-12 in grid.

---

## Detail Objects

### Style reference sheet (CRITICAL for style-heavy scenes)

Define before generating parts for pastel/cute/ornamental/cozy requests:

```markdown
Theme: [name]
Silhouette keywords: [e.g., layered, soft, readable at distance]
Material rules: [e.g., SmoothPlastic main, Neon tiny accents only]
Color anchors: [e.g., warm cream paths + saturated mint/peach accents]
Hero props: [which props must be focal and non-symbolic]
```

Use as hard constraint during generation and verification.

### Minimum shape vocabulary

Each decoration type needs >= 2 distinct shapes for visual legibility:

| Object | Min parts | Shapes |
|--------|-----------|--------|
| Flower | 3 | Stem (Cylinder) + Petals (flat Cylinder) + Center (Sphere) |
| Stone | 1-2 | Flattened Sphere (Size.Y < Size.X) — vary sizes |
| Mushroom | 2 | Stem (Cylinder) + Cap (wider Sphere) |
| Bush | 2-3 | Base Sphere + offset Sphere blobs |

Anti-pattern: same-size spheres in a ring = abstract art. Always include a non-sphere anchor.

### Block-first silhouette rule

Default: Block massing → Wedge trims → Cylinder for curves → Sphere accent-only
(< 20% visible parts per prop). Sphere-heavy only when explicitly requested.

**Vegetation / foliage**: This rule applies to ALL builds, not just Map Mode.
Roblox-style tree canopy = stacked/offset **Block** shapes, not Sphere clusters.
Sphere foliage reads as "abstract blob" in block-based worlds and breaks visual style.

```lua
-- WRONG: Sphere canopy (looks out of place in Roblox block world)
canopy.Shape = Enum.PartType.Ball

-- CORRECT: Block canopy (matches Roblox visual language)
canopy.Size = Vector3.new(4, 3, 4)  -- flat Block for low canopy
-- or stacked Blocks of decreasing size for layered look
```

Override only when brief explicitly requests "rounded" or "organic" style.

### WedgePart roof eaves (temple/pagoda architecture)

**Exception to Block-first**: For Japanese temple, pagoda, shrine, or castle roofs,
WedgePart eaves are architecturally required — the roof profile defines identity.

Standard eave per floor:

```
Roof_Base:   Block — flat roof deck
Roof_Eave×4: WedgePart — one per side, angled outward
Roof_Ridge:  Thin Block — ridge cap
```

```lua
-- Eave on +Z side, sloping outward:
eave.CFrame = bodyTop * CFrame.new(0, 0, halfBody + eaveDepth/2)
            * CFrame.Angles(math.rad(15), 0, 0)
```

Triggers: 五重塔, 神社/寺院, 鳥居, 茶室, 城

### Readability-first detail budget (CRITICAL)

Minimum parts per hero prop (park-style scenes):

| Hero prop | Min parts | Required structure |
|-----------|-----------|-------------------|
| Bench | 12+ | Seat slats + back slats + legs/frame + arm detail |
| Flower cluster | 12+ | Planter/soil + stems + petals + core |
| Arch | 14+ | Base/plinth + layered columns + top profile + center accent |
| Fountain | 10+ | Basin wall + inner basin + water + vertical core + crown |

Build one exemplar first, then clone.

### Arch recognizability

Required: clear through-opening with negative space, distinct base/shaft/cap layers,
top profile thicker at center, optional center badge. If opening isn't obvious from
player-oblique view → redesign.

### Fountain water placement (CRITICAL)

Water surface in **top 25% of basin wall height**:

```lua
waterY = basinBottom + wallHeight * 0.75  -- NOT basin floor
```

Preferred: shallow basin (wall <= 0.5 studs) — water always visible.

### Path length (CRITICAL)

Main axis: `length >= groundSize - 10` (5-stud margin per edge).
Always verify: `pathLength / groundSize >= 0.9`.

### Build approach trade-off

| Approach | Spatial | Detail | Orientation |
|----------|---------|--------|-------------|
| OneShot (1 call) | Best | Shallow | Unreliable |
| Stepwise (6+) | Worst | Deep | Unreliable |
| Hybrid 3-Phase | Good | Good | Reliable |

Use Hybrid for production builds. See SKILL.md for workflow.

### Map Mode uniform quality (CRITICAL)

LLM context degrades mid-sequence generation ("Lost in the Middle").

- Define single exemplar per prop category with explicit shape decomposition
- Clone with position variation — do NOT re-generate each instance
- Post-build: compare per-category part counts. Category <70% of max → rebuild

### Map Mode vegetation (Roblox-likeness)

Match vegetation complexity to scene resolution:

- **Block-style scene**: Trees = 2-3 parts (trunk + 1-2 canopy Blocks)
- **Detailed scene**: Trees = 4-8 parts (trunk + layered canopy + accents)

```lua
-- Block-style tree (2 parts — matches Roblox aesthetic)
local trunk = makePart("Trunk", Vector3.new(1, 5, 1), CFrame.new(x, 2.5, z),
    Color3.fromRGB(100, 70, 40), Enum.Material.SmoothPlastic)
local canopy = makePart("Canopy", Vector3.new(5, 5, 5), CFrame.new(x, 6.5, z),
    Color3.fromRGB(60, 120, 50), Enum.Material.SmoothPlastic)
```

### Addition order

Large (floors, walls, buildings) → Medium (booths, gates, benches) → Small (panels, vents, glows).

### Effective detail patterns

- **Tech panel**: Dark 6×4×0.5 + 3 indicator dots (Neon, 0.4×0.4)
- **Vent grate**: Dark metal 4×0.2×4 + 3 internal slats
- **Holographic display**: Thin post + translucent Neon panel (Transparency 0.5)
- **Glow cubes**: 1-1.5 Neon (Transparency 0.3) on metal pedestals
- **Stanchions**: Metal posts + horizontal Neon barrier line

---

## Atmosphere & PostEffects

### Standard trio

1. **Atmosphere**: Density 0.2-0.4, Haze 1-3
2. **BloomEffect**: Intensity 0.4-0.8, Size 15-25, Threshold 0.7-0.9
3. **ColorCorrectionEffect**: Overall tone control

### Theme-specific Lighting

**Sci-fi**: ClockTime 6-7, Brightness 0.7-0.9, Ambient ~RGB(45, 43, 55), Saturation -0.1 to -0.2

**Cyberpunk**: ClockTime 0-2, Brightness 0.3-0.5, Ambient ~RGB(15, 15, 25), Bloom 0.8-1.0

**Bright/casual**: ClockTime 12-14, Brightness 1.5-2.0, Saturation 0.1-0.2

**Pastel/cute**: ClockTime 12-13, Brightness 1.0-1.2 (NEVER >1.3), Saturation 0.15-0.25,
Bloom threshold >= 0.95, intensity 0.2-0.3

**Indoor/office**: ClockTime 12, Brightness 0.7-0.9, Ambient ~RGB(50, 50, 55),
Saturation 0.0-0.1, Bloom threshold 0.97, intensity 0.1-0.2
→ Supplement with PointLight inside the room (Brightness 1.0-1.5, Range 30-40, Shadows=false)
→ Avoid global Brightness > 1.0 for enclosed rooms — bright sky bleeds through glass and over-exposes

### Pastel color saturation floor (CRITICAL)

Near-white colors (RGB > 220) cause white-out on large surfaces regardless of Bloom.

Rules for large surfaces (> 5 studs):

- Max RGB channel: **225**
- Min one channel <= **180** (saturation anchor)
- Adjacent surfaces differ >= **30** in one channel
- Prefer warm-shifted pastels over cold-shifted

Proven palette:

```
Ground:     RGB(155, 205, 155)  -- yellow-green
Plaza:      RGB(170, 195, 225)  -- soft blue
Paths:      RGB(225, 200, 160)  -- warm golden cream
Basin:      RGB(155, 190, 220)  -- clear blue
Fountain:   RGB(220, 155, 180)  -- warm pink
Gate:       RGB(230, 170, 195)  -- pastel pink
```

### Neon large surfaces cause white-out (CRITICAL for pastel)

Large Neon (> 5 studs) + any Bloom = severe over-exposure.

- Water → `SmoothPlastic` with `Transparency 0.3-0.5`, NOT Neon
- Neon only for: accent lines (< 0.4 studs), small glows (< 2 studs), lamp globes
- If Neon area > 20 studs² → replace with SmoothPlastic + PointLight

### Ground fog

SmoothPlastic at Y=0.2-0.5, Transparency 0.9-0.95, CanCollide=false.

---

## Service Integration

### Trigger volumes and spawn paths (CRITICAL)

Game code references objects via `WaitForChild` / `FindFirstChild`.

- Trigger volumes: name and path must match game code expectations
- SpawnLocation: hierarchy placement matters for auto-spawn
- Key objects at expected paths: e.g., `Workspace.Lobby.InQueueButton` must be direct child

Post-build: print key element positions, cross-reference game code paths.
