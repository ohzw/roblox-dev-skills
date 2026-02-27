# Gotchas

Non-obvious Roblox-specific pitfalls encountered in practice.

## Contents

- [CSG](#csg) — Silent empty mesh, color inheritance, CFrame rotation loss, CollisionFidelity
- [Positioning & Orientation](#positioning--orientation) — BB center, Cylinder axis, LookVector, flat panels, rope CFrame, overlaps, child orientation, embedded decorations
- [Repair & Iteration](#repair--iteration) — Fix cascade bugs
- [Performance](#performance) — Part count limits, PointLight limits
- [Neon Accents](#neon-accents) — Thickness rules, light pairing
- [Folder vs Model](#folder-vs-model) — Container choice, PrimaryPart
- [Large-Scale Build Practices](#large-scale-build-practices) — Helper redefine, data tables, sub-folders
- [Luau API Gotchas](#luau-api-gotchas) — Color3 floats, Vector3/boolean print

---

## CSG

### UnionAsync / SubtractAsync silent empty mesh

Returns `TriangleCount == 0` without throwing an error.
Always: pcall for error + check `TriangleCount > 0`.

Common causes of empty mesh:
- Insufficient overlap (touching alone fails — parts must intersect)
- Non-manifold geometry (self-intersecting shapes)
- Too many parts in one operation (>20 is unstable)

Fix: Make cutter parts **+2 studs larger** than the target on each axis.

### Union flattens materials/colors

Unioning parts with different colors applies the first part's color to all.
Keep differently-colored sections as separate parts — do NOT union them.

### SubtractAsync preserves cutter color on cut surfaces

`SubtractAsync` result (UnionOperation) defaults to `UsePartColor = false`.
Cut surfaces inherit the cutter part's color — if the cutter was red (debug),
the arch interior renders red.

Fix: Always set BOTH properties after any CSG operation:
```lua
result.UsePartColor = true
result.Color = desiredColor
```

This applies to both `SubtractAsync` and `UnionAsync`. Set these immediately
after parenting the result, before destroying the cutter.

### CSG result CFrame loses rotation when overriding (CRITICAL)

**Symptom:** A horizontal cylinder (flat disc) CSG result renders as a vertical arch
after `result.CFrame = CFrame.new(0, y, 0)`.

**Root cause:** `SubtractAsync` returns the result with the base part's CFrame
(including rotation). Overriding with a position-only CFrame silently strips the
rotation — a flat disc snaps back to its default vertical orientation.

**Fix:** Always copy the full CFrame from the original part, not just position:
```lua
-- WRONG: loses rotation
result.CFrame = CFrame.new(0, BASIN_Y + 1, 0)

-- CORRECT: preserves orientation
result.CFrame = outerPart.CFrame
-- OR if you must reconstruct:
result.CFrame = CFrame.new(0, BASIN_Y + 1, 0) * CFrame.Angles(0, 0, math.pi/2)
```

**Prevention:** After any CSG operation on a rotated part, use
`result.CFrame = originalPart.CFrame` as the default. Only override
if you explicitly need to move or re-orient the result.

### CollisionFidelity

Union results default to `Default`. Explicitly set:
- `Box` for decorative objects (best performance)
- `PreciseConvexDecomposition` for complex shapes players touch (best accuracy)

---

## Positioning & Orientation

### Part.Position = bounding box center

Floor at Y=0 → `Position.Y = Size.Y / 2`.
Wall on ground → `Position.Y = WallHeight / 2`.

Forgetting this buries parts halfway into surfaces. Automate in helper functions.

### Cylinder long axis = X

`Part.Shape = Enum.PartType.Cylinder`:
- `Size.X` = length (long axis)
- `Size.Y` = diameter
- `Size.Z` = diameter

Stand upright: `CFrame.Angles(0, 0, math.pi/2)` with `Size = Vector3.new(height, diameter, diameter)`.

Counter-intuitive — verify on every Cylinder placement.

**Corollary for rotated cylinders: Size.X = world height, NOT Size.Y**

After rotating Z 90° (to stand upright), the world-space dimensions flip:
- World-space height = `Size.X`  ← use this for top/bottom calculations
- World-space diameter = `Size.Y` (= `Size.Z`)

```lua
-- WRONG: Size.Y is the diameter, not the height
local top = p.Position.Y + p.Size.Y / 2  -- returns radius, not half-height!

-- CORRECT: Size.X is the height for an upright (Z-rotated) cylinder
local top = p.Position.Y + p.Size.X / 2
local bottom = p.Position.Y - p.Size.X / 2
```

This caused an entire fountain debug session to produce wrong values —
every top/bottom was off by 8× (diameter/2 instead of height/2).
Always use `Size.X` when computing heights of rotated cylinders.

### LookVector = backrest direction for seated furniture (CRITICAL)

**Symptom:** Bench orientation verification reports "facing center" but benches
visually face outward. Fix attempt reverses the correct benches, making all wrong.

**Root cause:** `CFrame.LookVector` = the **-Z local axis** = the direction the
Part's "front face" points. For a bench with backrest at `local Z = -0.72`,
the backrest is in the -Z direction = **LookVector direction**.

The person sitting faces **-LookVector** (opposite), not LookVector.

```lua
-- WRONG: checking if LookVector points toward center
local dot = seat.CFrame.LookVector:Dot(toCenter)
-- This checks if the BACKREST faces center, not the person

-- CORRECT: person faces -LookVector
local personFaces = -seat.CFrame.LookVector
local dot = personFaces:Dot(toCenter)
-- dot > 0.5 means person faces center
```

**When building benches:** To make a bench face a target point, use
`CFrame.lookAt(benchPos, targetPos)` — this orients LookVector toward target,
meaning the backrest faces the target. So for "person faces center":
```lua
-- Person faces center → backrest faces AWAY from center
bench.CFrame = CFrame.lookAt(benchPos, awayFromCenter)
-- OR equivalently:
bench.CFrame = CFrame.lookAt(benchPos, center) * CFrame.Angles(0, math.pi, 0)
```

### Orientation errors on multi-component props (keyboard, mouse, etc.) (CRITICAL)

**Symptom:** Keyboard faces backward, mouse buttons point away from player, or
similar orientation errors on detailed props. Occurs in ~80% of builds when using
OneShot or Stepwise alone. Injecting orientation comments/constants into code does
NOT reliably fix it.

**Root cause:** LLM spatial reasoning does not reliably map Roblox axes to
real-world "front/back" when generating CFrame values in a single pass. The model
may understand the rule ("mouse buttons face -Z") but still generate coordinates
that violate it.

**Fix:** Use the Hybrid 3-Phase pattern (see SKILL.md):
1. Phase 1 skeleton establishes each component's CFrame as spatial truth
2. Phase 2 reads anchor CFrames via `FindFirstChild()` — orientation propagates
   automatically through relative positioning
3. Phase 3 verifies LookVector directions and auto-corrects

**Orientation reference for common desk/room items:**
```
Player sits at -Z, looking toward +Z (into the scene)

Monitor:   screen on -Z face, LookVector ≈ (0,0,-1)
Keyboard:  long axis = X, keys face +Y, front edge at -Z, NO Y-rotation
Mouse:     long axis = Z, buttons at -Z end, cable at +Z, NO Y-rotation
PC Tower:  front panel faces -Z or -X
Speakers:  driver cone faces -Z (toward player)
```

**Key insight from testing:** Prompt-level fixes (comments, constants, reference
tables) alone are insufficient. Only structural fixes (skeleton anchors + CFrame
inheritance + verification loop) achieved zero orientation errors across 5 test rounds.

### Stepwise coordinate drift causes overlap and scale distortion (CRITICAL)

**Symptom:** Multi-step builds produce overlapping parts, disproportionate sizes,
and spatial incoherence that worsens with each step. Desk might be 2x too large,
or keyboard might clip through the monitor stand.

**Root cause:** Each `run_code` call re-declares base coordinates from the LLM's
memory of previous code. No mechanism reads actual part positions. Small errors
in memorized offsets accumulate across steps, compounding into visible distortion.

**Fix:** Never hardcode absolute coordinates in follow-up steps. Always read
existing part positions:
```lua
-- WRONG: hardcoding from memory
local x0, y0, z0 = 420, 6, 0  -- "I remember the desk is here"
local kbPos = Vector3.new(x0 + 3.2, y0 + 0.85, z0 - 2.35)

-- CORRECT: reading actual positions
local model = workspace:FindFirstChild("MyModel")
local deskTop = model:FindFirstChild("Desk_Top")
local topCF = deskTop.CFrame
local topSize = deskTop.Size
local kbCF = topCF * CFrame.new(-1.5, topSize.Y/2 + 0.15, -1.0)
```

**Prevention:** Use Hybrid 3-Phase pattern. Phase 1 establishes spatial truth,
Phase 2 inherits it via FindFirstChild reads.

### Flat panel default orientation is Y-Z plane (sails, windows, flat boards)

**Symptom:** All sails on a ship face fore-aft instead of port-starboard.
Multiple flat panels pile on top of each other and appear as one thick slab.

**Root cause:** A `Block` with `Size = (thin, H, W)` has its wide face in the **Y-Z plane**
by default. For a sail hanging from a yard that spans the X axis, the face must instead
span X — requiring a 90° Y-rotation that is easy to forget when generating many panels
in a loop.

**Fix:** Always declare the intended facing direction before placing flat panels:
```lua
-- PLAN: Sail face should be visible from bow (+Z) and stern (-Z)
-- → wide face must span X-Y → apply CFrame.Angles(0, math.pi/2, 0)
local sail = makePart(Size.new(0.3, sailH, sailW))
sail.CFrame = yardCF * CFrame.new(0, -sailH/2, 0)
            * CFrame.Angles(0, math.pi/2, 0)  -- REQUIRED: face spans X, not Z
```

**Prevention:** When building any flat panel (sail, door, window, sign), write a one-line
comment stating which axis the face should be visible from BEFORE writing the CFrame.
Review it during Phase 3 verification.

### CFrame.lookAt axis confusion for rope/beam parts between two points

**Symptom:** Shrouds run fore-aft instead of diagonally port-to-starboard.
Ratlines run along the ship's length instead of across it.

**Root cause:** `CFrame.lookAt(mid, endPoint)` orients the part's **-Z local axis** along
the direction `mid → endPoint`. For a `Block` used as a rope, the long dimension is
`Size.Y` by default. Unless the part's Y axis is aligned with the rope direction, the
rope will point sideways.

**Fix:** Use the following helper for any rope or beam between two points:
```lua
local function makeRope(p0, p1, thickness, parent)
    local mid = (p0 + p1) / 2
    local len = (p1 - p0).Magnitude
    local part = Instance.new("Part")
    part.Size = Vector3.new(thickness, len, thickness)
    -- lookAt gives -Z = direction, but we need Y = direction for a Block
    part.CFrame = CFrame.lookAt(mid, p1) * CFrame.Angles(math.pi/2, 0, 0)
    part.Parent = parent
    return part
end
```

**Prevention:** Never use `CFrame.lookAt` directly on a rope part without the
`* CFrame.Angles(math.pi/2, 0, 0)` correction. Encode this in a shared helper
function at the top of every ship/rigging script.

### Surface-sibling overlap on shared planes (desk items, shelf items)

**Symptom:** Items placed on the same surface (e.g., keyboard, mouse, speakers
on a desk top) slightly overlap each other despite correct global positioning.

**Root cause:** Phase 2 detail additions (key rows extending beyond keyboard body,
speaker cones protruding forward) can intrude into neighboring anchor zones. No
bounding-box check between sibling items sharing the same surface.

**Fix:** Add overlap detection to Phase 3 verification for items on shared surfaces:
```lua
-- Collect all items within 2 studs of desk surface Y
local deskY = deskTop.Position.Y + deskTop.Size.Y / 2
local surfaceItems = {}
for _, part in ipairs(model:GetChildren()) do
    if part:IsA("BasePart") and math.abs(part.Position.Y - deskY) < 2 then
        table.insert(surfaceItems, part)
    end
end
-- Check pairwise XZ bounding box overlap and nudge if needed
```

**Prevention:** In Phase 1 skeleton, leave explicit spacing margins between anchor
positions. Rule of thumb: gap between adjacent anchors ≥ largest expected detail
protrusion (typically 1-2 studs).

### CFrame.Angles application order

`CFrame.Angles(rx, ry, rz)` applies X → Y → Z (Euler angles).
Order matters when multiple axes rotate. For complex rotations, prefer `CFrame.lookAt` or `CFrame.fromMatrix`.

### Child object orientation mismatch (FREQUENT)

**Symptom:** Decorations (neon stripes, windows, tech panels) on buildings face the wrong direction or clip through at wrong angles. Especially when parent structures are rotated or placed off-axis.

**Root cause:** Child positions calculated as `Vector3.new(parentX + offset, ...)` in world coordinates. When the parent is rotated, world-space offsets don't align with the parent's local space.

**Fix:**
- ALWAYS compute child CFrame relative to parent: `child.CFrame = parent.CFrame * CFrame.new(localOffset)`
- When batch-generating buildings via data tables, compute ALL decorations relative to `Body.CFrame`, never from `Body.Position`
- Any building placed off-axis (non-axis-aligned rotation) requires ALL children to use CFrame-relative placement
- Build this pattern into your `makePart` helper: accept a `baseCFrame` parameter for parent-relative positioning

### Decoration parts embedded inside walls (FREQUENT)

**Symptom:** Thin decorations (neon strips, window panels, tech panels) placed on walls are invisible because they're inside the wall volume.

**Root cause:** Decoration Position set equal to wall Position (= center of bounding box). A 0.15-thick neon strip placed at the center of a 3-thick wall is completely hidden.

**Fix:**
- Wall surface position = `wall center + normal direction * (wall thickness / 2)`
- Decoration position = `wall surface + normal direction * (decoration thickness / 2 + 0.05)`
- The 0.05 stud margin prevents z-fighting
- For rotated walls, use CFrame-relative calculation:
  `decoration.CFrame = wall.CFrame * CFrame.new(0, yOffset, -(wallThickness/2 + decoThickness/2 + 0.05))`

### Co-planar surface Z-fighting (CRITICAL)

**Symptom:** Two parts whose faces share the exact same world-space plane produce a
checkerboard / flickering artifact.

**Why it happens:** The GPU cannot determine draw order for co-planar opaque surfaces.
This applies to **both** embedded parts (center inside a wall) and flush-mounted parts
(face exactly on the wall face).

**Rule:** When two BaseParts share a face at the same world-space position, offset the
decorative one by **+0.05 studs** along the face normal. No exceptions.

### Bridging parts penetrate floor when height is a constant (CRITICAL)

**Symptom:** Chair legs, table legs, or columns visibly penetrate below the floor surface.
Camera angle makes it obvious — the bottom of the leg disappears into the floor mesh.

**Root cause:** The part's `Size.Y` (height) is set as a hardcoded constant (e.g., `legHeight = 3`).
If the actual gap between the seat bottom and the floor top is smaller than that constant,
the leg overflows below the floor.

**Fix:** Compute bridging-part height from the two reference surfaces, never from a constant:

```lua
local floorTop   = roomFloor.Position.Y + roomFloor.Size.Y / 2
local seatBottom = seat.Position.Y      - seat.Size.Y / 2

local legHeight  = seatBottom - floorTop            -- exact gap, no overflow
local legCenterY = (seatBottom + floorTop) / 2      -- midpoint between the two surfaces

leg.Size   = Vector3.new(legThickness, legHeight, legThickness)
leg.CFrame = CFrame.new(legX, legCenterY, legZ)
```

**Prevention:** Any part that spans between two horizontal reference surfaces (legs, risers,
columns, support struts) must derive its height from the actual gap. The pattern is:

```
height  = upper_reference_Y  - lower_reference_Y
centerY = lower_reference_Y  + height / 2
```

Apply this to all four legs of every chair/table in a single data-table loop so the
constraint is never bypassed by copy-paste.

---

### Furniture in enclosed rooms must be derived from room floor CFrame (CRITICAL)

**Symptom:** Chairs, tables, and other furniture appear significantly offset from their
intended positions inside an enclosed room (floor + walls + ceiling).

**Root cause:** The room itself is placed at a non-zero world position. Furniture
positions were calculated relative to world origin (0,0,0) instead of the room floor.
The offset between world origin and room floor propagates to every piece of furniture.

**Fix:** In Phase 1, establish the room floor as the spatial anchor. Derive all
furniture positions from `roomFloor.CFrame`:

```lua
local roomFloor = model:FindFirstChild("Floor")
-- Correct: furniture relative to room floor
local tableCF = roomFloor.CFrame * CFrame.new(0, roomFloor.Size.Y/2 + tableHeight/2, 0)
local chairCF = tableCF * CFrame.new(chairOffset.X, 0, chairOffset.Z)
```

**Prevention:** Interior room builds follow the same Relative CFrame Pattern as
multi-component props. Treat the room floor as "parent" — never hardcode world-space
X/Z coordinates for furniture.

### Sub-component positions must be derived from parent CFrame (CRITICAL)

**Symptom:** Sub-parts of a multi-part object appear at the wrong position relative
to the parent body — shifted up, down, or to the side.

**Why it happens:** The sub-component's Y (or other axis) is hardcoded as an absolute
world coordinate. When the parent body's height or position changes, the sub-part
stays at the old absolute position.

**Rule:** In any multi-part object, compute all sub-component CFrames as
`parentBody.CFrame * CFrame.new(localOffset)`. Never hardcode absolute Y.

**Why it works:** When the parent is moved or resized, children maintain their relative
position. In Hybrid 3-Phase, moving a Phase 1 skeleton part automatically propagates
to Phase 2 children.

---

## Repair & Iteration

### Fix cascade introduces new bugs (CRITICAL)

**Symptom:** Fixing one part's property accidentally corrupts another property
on the same part. e.g., correcting `Size.Y` of a rigging rope leaves `Size.Z = 35`
from old code, creating a "flying wooden plank" that wasn't there before the fix.

**Root cause:** Incremental fix scripts that set only the target property without
reading back and verifying all properties of the modified part. A previous script's
leftover value on a different axis goes undetected.

**Fix:** Before any fix script modifies a part, read and print ALL its properties first:
```lua
local part = model:FindFirstChild("Rig_Stay_Fore")
-- ALWAYS read before writing:
print("BEFORE:", part.Name, tostring(part.Size), tostring(part.CFrame))
-- Apply only the specific fix needed:
part.Size = Vector3.new(0.4, part.Size.Y, 0.4)  -- keep Y (length), fix X and Z only
print("AFTER: ", part.Name, tostring(part.Size), tostring(part.CFrame))
```

**Prevention:** Every fix script must end with a verification `print` of the
modified part's `Size` and `CFrame`. If the output shows unexpected values on
any axis, treat that as a new bug to fix before reporting completion.

---

## Performance

### Part count guidelines

- Lobby/hub: 500-1000 parts (practical ceiling)
- Arena: 200-500 parts
- Above 1000: noticeable frame drops on low-end devices

Mitigations for high part counts:
- `CastShadow = false` on decorative parts
- Skip interior detail on distant buildings (exterior only)
- Union same-material/color static parts to reduce count

### PointLight limits

10-15 PointLights/SpotLights per area is the practical maximum.
Mass lights with shadows tank frame rate. Use `Shadows = false` to reduce cost (visual quality trade-off).

---

## Neon Accents

### Thickness golden rule

Neon part thickness: **0.1 - 0.4 studs**

- 0.1-0.15: Floor lines, accent stripes
- 0.2-0.3: Rails, borders
- 0.3-0.4: Sign panel glow surfaces

At 0.5+ neon reads as a "surface" instead of a "line" — looks cheap.
At 1.0+ avoid entirely (small decorative cubes are the only exception).

### Neon doesn't cast light

`Neon` material glows visually but emits zero actual light.
Pair with `PointLight` or `SpotLight` on the same or nearby part to illuminate surroundings.

Neon + PointLight is the standard combo.

---

## Folder vs Model

| Use case | Container |
|----------|-----------|
| Area grouping (Buildings, Decorations) | Folder |
| Movable/clonable structures (ShopBooth, Gate) | Model + PrimaryPart |
| Game logic element storage | Folder |

Always set PrimaryPart on Models. Without it, `:GetPivot()` and `SetPrimaryPartCFrame` produce incorrect results.

---

## Large-Scale Build Practices

### Redefine helpers every script

`mcp__roblox__run_code` does NOT persist state between calls.
Every script must redeclare helper functions and color palettes at the top.

### Drive creation from data tables

Don't hand-code each building/decoration. Define an array of `{name, x, z, width, height, color, accent}` and loop over it. Adding/modifying is a one-line table change.

### Re-acquire folder references

Previous-phase folders must be re-fetched: `workspace:FindFirstChild("Lobby")`.
MCP executions are stateless.

### Batch verification at the end

Count parts via `GetDescendants`, print key element positions.
Per-phase verification is inefficient for large builds.

### Sub-folder hierarchy per object type (CRITICAL for usability)

**Symptom:** All 100+ parts dumped in one root Folder — impossible to select/edit individual trees or benches in Studio Explorer.

**Root cause:** Using `Parent = rootFolder` for every part regardless of type.

**Fix:** Before building each category, create a named sub-folder:
```lua
local treesFolder = Instance.new("Folder")
treesFolder.Name = "Trees"
treesFolder.Parent = park
-- then: Parent = treesFolder for all tree parts
```
Standard sub-structure for parks/hubs:
`Paths / Fountain / Trees / Benches / FlowerBeds / Lamps / Stones / Atmosphere`

This is essential for Studio usability — verify hierarchy after every build.

---

## Luau API Gotchas

### Color3.R/G/B are 0-1 floats, not 0-255 integers

**Symptom:** `Color3.fromRGB(color.R * 255 + 15, ...)` → "attempt to call nil value" error.

**Root cause:** `Color3.R`, `.G`, `.B` return values in `[0, 1]` range.
Multiplying by 255 first, then adding, still works numerically, but chaining
`Color3` object methods like `.__index` does not exist.

**Fix:** When color arithmetic is needed, store colors as integer triplets in data tables:
```lua
-- WRONG
{ color = Color3.fromRGB(160, 220, 170) }
-- then: color.R * 255 + 15  ← wrong

-- CORRECT
{ cr = {160, 220, 170} }
-- then: Color3.fromRGB(math.min(255, t.cr[1] + 15), ...)
```

### Vector3 values in print() cause concat errors

**Symptom:** `print("Size:", part.Size)` → "invalid value (Vector3) at index 2 in table for 'concat'".

**Root cause:** Same as boolean — MCP output processing cannot auto-convert Vector3.

**Fix:** Always wrap with `tostring()`:
```lua
-- WRONG
print("Part size:", part.Size)

-- CORRECT
print("Part size: " .. tostring(part.Size))
```

### Boolean values in print() cause concat errors

**Symptom:** `print("CSG success:", result ~= nil)` → "invalid value (boolean) at index 2 in table for 'concat'".

**Root cause:** MCP output processing concatenates print arguments; boolean is not auto-converted.

**Fix:** Always wrap booleans with `tostring()`:
```lua
-- WRONG
print("Basin present:", basin ~= nil)

-- CORRECT
print("Basin present: " .. tostring(basin ~= nil))
```
