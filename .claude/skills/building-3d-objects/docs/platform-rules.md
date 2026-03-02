# Roblox Platform Rules

Crucial behaviors unique to the Roblox engine.

## 1. Cylinder Orientation

A `Cylinder` in Roblox extends along the **X-axis** by default.
To make a cylinder stand upright (like a pillar), you must swap the Y and X dimensions and rotate it 90 degrees around the Z-axis.

```lua
local pillar = Instance.new("Part")
pillar.Shape = Enum.PartType.Cylinder
-- Size = Vector3.new(Length, Diameter, Diameter)
pillar.Size = Vector3.new(10, 2, 2)
-- Rotate 90 degrees around Z to stand it upright
pillar.CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.pi/2)
```

## 2. Neon Material & Lighting

The `Neon` material appears extremely bright and glows, but it **does not cast dynamic light on surrounding objects**.
To create actual illumination, you must parent a `PointLight`, `SpotLight`, or `SurfaceLight` to the neon part.

```lua
local lamp = Instance.new("Part")
lamp.Material = Enum.Material.Neon
lamp.Color = Color3.fromRGB(255, 255, 200)

local light = Instance.new("PointLight")
light.Color = lamp.Color
light.Range = 15
light.Brightness = 2
light.Parent = lamp
```

## 3. Part Base Properties

Always explicitly set these values unless physics interaction is intended:
- `Anchored = true`
- `CanCollide = true` (or `false` for small decorative clutter)
- `CastShadow = true` (or `false` for invisible triggers or purely emissive neon)

## 4. CSG Best Practices for Roblox Engine

- **Origin Processing**: Roblox floating-point precision degrades far from the origin. Perform complex CSG operations near `CFrame.new(0, 0, 0)`, then `PivotTo()` the final Model to its intended location.
- **No MeshPart CSG**: The GeometryService ONLY supports `Part` and `PartOperation`. Do NOT attempt to use `SubtractAsync` or `UnionAsync` on `MeshPart` or `Terrain`.
- **Collision Fidelity**: For decorative Unions that players don't need accurate physics for, explicitly set `CollisionFidelity = Enum.CollisionFidelity.Box` to save performance.

## 5. WedgePart Orientation

A `WedgePart`'s taper direction is NOT axis-aligned by default — it requires explicit CFrame rotation, just like `Cylinder`.

**Default behavior**: The zero-height edge (the "tip") points toward **+Z**. Without rotation, a WedgePart used as a blade tip or roof peak will face sideways, not upward.

**To make the tip point UP** (e.g., blade tip, spear head, roof peak):
```lua
local tip = Instance.new("WedgePart")
tip.Size = Vector3.new(0.3, 1.0, 0.3) -- Width, TaperLength, Depth
-- Rotate -90° around X so the tip points in +Y (upward)
tip.CFrame = baseCFrame * CFrame.new(0, halfBladeHeight + 0.5, 0) * CFrame.Angles(-math.pi/2, 0, 0)
```

**Direction table**:
| Desired tip direction | Required rotation |
|---|---|
| +Y (up) | `CFrame.Angles(-math.pi/2, 0, 0)` |
| -Y (down) | `CFrame.Angles(math.pi/2, 0, 0)` |
| +Z (forward, default) | no rotation needed |
| -Z (backward) | `CFrame.Angles(math.pi, 0, 0)` |

**Anti-pattern**: Placing a WedgePart without setting CFrame rotation and assuming it will taper in the correct direction based on Size alone.
