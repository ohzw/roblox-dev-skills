# CSG Guide

CSG (SubtractAsync / UnionAsync) is how you represent recesses, holes, and curves
in Roblox. Without it, everything looks like rectangular placeholders.

## When to Use CSG

For each surface of the object, ask:

```
Is this surface flat in the real world?
├─ YES → Block / WedgePart is fine
└─ NO  → Is it concave, perforated, or curved?
          ├─ Concave (basin, bowl, recess, channel) → SubtractAsync
          ├─ Perforated (window, arch, doorway)     → SubtractAsync
          ├─ Curved (pillar, pipe, round tabletop)  → Cylinder / Sphere / UnionAsync
          └─ Compound (rounded edge, pipe bend)     → UnionAsync
```

This applies to every object regardless of theme.

## Safe Practices

### Before coding: list all curves and recesses

Enumerate "where in this object are curves, recesses, or holes?" before writing
any code. Retrofitting CSG after the fact leads to coordinate mismatches.

### Cutter size: +2 studs minimum overlap

Cutters that merely touch surfaces produce empty meshes (`TriangleCount == 0`).
Make cutters clearly penetrate through the target.

### Always wrap in pcall and validate

```lua
local ok, result = pcall(function()
    return base:SubtractAsync({cutter})
end)
if ok and result:IsA("BasePart") then
    result.CFrame = base.CFrame       -- FULL CFrame, never position-only
    result.UsePartColor = true
    result.Color = desiredColor
    result.Anchored = true
    result.Name = base.Name
    result.Parent = base.Parent
    base:Destroy()
end
cutter:Destroy()  -- always clean up
```

### Properties to set on every CSG result

- `UsePartColor = true` — without this, cutter color bleeds onto cut surfaces
- `Color = desiredColor` — set explicitly
- `CFrame = originalPart.CFrame` — never reconstruct from position alone (resets rotation)
- `CollisionFidelity`: `Box` for decorative, `PreciseConvexDecomposition` for functional

### Keep differently-colored sections separate

UnionAsync applies the first part's color to the entire result.
Don't union parts that need different colors — keep them as separate parts.

### Destroy cutters immediately

Leftover cutter parts render as visible garbage in the workspace.

### Max ~10 parts per single CSG call

Large operations are unstable. Split into multiple calls if needed.

## Common Failures

| Failure | Cause | Fix |
|---------|-------|-----|
| Empty mesh (no error) | Insufficient cutter overlap | Make cutter +2 studs larger |
| Cut surfaces wrong color | `UsePartColor` not set | Set `UsePartColor = true` + `Color` |
| Rotated part snaps upright after CSG | Position-only CFrame override | Copy full `originalPart.CFrame` |
| `FindFirstChild` returns nil after CSG | CSG converts Part → UnionOperation | Name the result, or run CSG at end of phase |

## Union Limitations

Prefer parts over Union when either of these applies.

### RenderFidelity = Performance is unavailable on Union

`RenderFidelity = Performance` (distance-based LOD) is a MeshPart-only feature.
UnionOperation always renders at full fidelity regardless of camera distance.
For objects that will be replicated many times across a scene, prefer MeshPart
import over Union.

### Property changes trigger full geometry recalculation

Modifying any property on a UnionOperation at runtime (Color, Material, etc.)
causes the engine to recalculate its entire geometry. Avoid Union for objects
that change properties at runtime — keep them as separate Parts instead.
