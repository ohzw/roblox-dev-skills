# Gotchas

Non-obvious Roblox-specific pitfalls. Every item here has caused real bugs.

---

## CSG

### Silent empty mesh

`SubtractAsync` / `UnionAsync` can return `TriangleCount == 0` without error.

Causes: insufficient overlap, self-intersecting geometry, >20 parts in one op.

Fix: `pcall` + verify result, make cutters **+2 studs larger** than target.

### Color bleed on cut surfaces

CSG results default to `UsePartColor = false`. Cut surfaces inherit the cutter's color.

```lua
result.UsePartColor = true
result.Color = desiredColor
```

### CFrame rotation loss

`result.CFrame = CFrame.new(x, y, z)` resets rotation to identity — a horizontal
disc snaps upright. Always: `result.CFrame = originalPart.CFrame`.

### Union flattens colors

Unioning parts with different colors applies the first part's color to all.
Keep differently-colored sections as separate parts.

### CollisionFidelity

Set explicitly: `Box` for decorative, `PreciseConvexDecomposition` for functional.

---

## Positioning & Orientation

### Position = bounding box center

Floor at Y=0 → `Position.Y = Size.Y / 2`. Forgetting this buries parts into surfaces.

### Cylinder axis = X

`Size = (length, diameter, diameter)`. Upright: `CFrame.Angles(0, 0, math.pi/2)`.

After rotation, **world-space height = `Size.X`**, not `Size.Y`:

```lua
-- WRONG: Size.Y is diameter after Z-rotation
local top = p.Position.Y + p.Size.Y / 2

-- CORRECT
local top = p.Position.Y + p.Size.X / 2
```

### LookVector = backrest direction (not person-facing direction)

`CFrame.LookVector` = the -Z local axis. For seated furniture, the person faces
**-LookVector**. To make a person face a target:

```lua
seat.CFrame = CFrame.lookAt(seatPos, target) * CFrame.Angles(0, math.pi, 0)
```

### Flat panel default face = Y-Z plane

A thin Block `Size = (0.3, H, W)` has its wide face in Y-Z. To face a different
direction, rotate. Comment the intended facing direction before writing CFrame.

### CFrame.lookAt for beams/ropes between two points

`CFrame.lookAt` aligns -Z with direction, but Block's long axis is Y. Correct:

```lua
local function makeBeam(p0, p1, thickness, parent)
    local mid = (p0 + p1) / 2
    local len = (p1 - p0).Magnitude
    local part = Instance.new("Part")
    part.Size = Vector3.new(thickness, len, thickness)
    part.CFrame = CFrame.lookAt(mid, p1) * CFrame.Angles(math.pi/2, 0, 0)
    part.Parent = parent
    return part
end
```

### CFrame.Angles order

Applies X → Y → Z (Euler). Order matters with multi-axis rotation. Prefer
`CFrame.lookAt` or `CFrame.fromMatrix` for complex cases.

### Decorations embedded inside walls

Thin parts placed at `wall.Position` are invisible (inside the wall volume).
Offset to wall surface + decoration half-thickness + 0.05:

```lua
deco.CFrame = wall.CFrame * CFrame.new(0, yOff, -(wallT/2 + decoT/2 + 0.05))
```

### Co-planar Z-fighting

Two faces at the same plane flicker. Offset decorative surface by **+0.05 studs**.

### Bridging parts penetrate floor

Legs/columns with hardcoded height overflow below floor. Derive from actual gap:

```lua
local legH = seatBottom - floorTop
leg.Size = Vector3.new(t, legH, t)
leg.CFrame = CFrame.new(x, (seatBottom + floorTop) / 2, z)
```

### Surface-sibling overlap

Items on a shared surface can overlap when details extend beyond bounds.
Leave spacing margins between adjacent items (>= 1-2 studs).

---

## Repair

### Fix cascade

Fixing one property can corrupt another on the same part. Always read+print
all properties before modifying, and verify after:

```lua
print("BEFORE:", part.Name, tostring(part.Size), tostring(part.CFrame))
part.Size = Vector3.new(0.4, part.Size.Y, 0.4)  -- keep Y, fix X and Z
print("AFTER: ", part.Name, tostring(part.Size), tostring(part.CFrame))
```

---

## Performance

- Part budget: lobby 500-1000, arena 200-500. Above 1000 → frame drops.
- `CastShadow = false` on decorative parts to save budget.
- PointLight/SpotLight: max 10-15 per area. Use `Shadows = false` on mass lights.

---

## Neon

- Thickness: **0.1-0.4 studs**. At 0.5+ it reads as "surface", not "line".
- Neon emits zero actual light. Pair with `PointLight` / `SpotLight`.

---

## Containers

| Use case | Container |
|----------|-----------|
| Area grouping | Folder |
| Movable/clonable object | Model + PrimaryPart |

Always set `PrimaryPart` on Models. Without it, `GetPivot()` is unreliable.

For large builds, create sub-folders per category (Trees/, Benches/, etc.)
to keep Studio Explorer navigable.

---

## MCP / Luau

### Stateless execution

`run_code` does NOT persist state. Every call must redeclare helpers and
re-acquire references via `FindFirstChild`.

### Color3.R/G/B are 0-1 floats

Not 0-255. For color arithmetic, store as integer triplets:

```lua
{ cr = {160, 220, 170} }
Color3.fromRGB(math.min(255, t.cr[1] + 15), ...)
```

### print() concat errors with Vector3/boolean

MCP output processing can't auto-convert. Wrap with `tostring()`:

```lua
print("Size: " .. tostring(part.Size))
print("OK: " .. tostring(result ~= nil))
```
