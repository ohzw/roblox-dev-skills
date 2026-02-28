# CSG (Constructive Solid Geometry) Patterns

Use these patterns to safely execute `SubtractAsync` and `UnionAsync`.

## 1. CSG Construction Heuristics (Keep it Shallow)

Do not create overly complex, deeply nested CSG trees. Follow this priority order:
1. **Dominant Volume**: Start with the largest simple convex shape (e.g., a big Block).
2. **Subtractions (Holes)**: Apply necessary cuts/holes using `SubtractAsync`.
3. **Additions (Protrusions)**: Add details. Do not use `UnionAsync` for everything; if parts share the same material/color and don't need complex intersections, just group them in a Model.
4. **Shallow Trees**: Avoid subtracting from a part that was already unioned multiple times.

## 2. The EPSILON Rule for Clean Cuts

When subtracting a part (the "cutter") from a base part, the cutter MUST slightly overlap the boundaries it intends to cut through. If surfaces are perfectly coplanar, Z-fighting or a microscopic skin of material will remain.

```lua
local EPSILON = 0.05 -- Small overlap margin

-- We want a hole 2x2 through a 1-stud thick wall
local wall = Instance.new("Part")
wall.Size = Vector3.new(10, 10, 1)

local holeCutter = Instance.new("Part")
-- Add EPSILON * 2 to the axis passing through the wall (Z-axis here)
holeCutter.Size = Vector3.new(2, 2, 1 + (EPSILON * 2))
holeCutter.CFrame = wall.CFrame -- Centered
```

## 3. Safe Execution Wrapper

CSG operations are asynchronous and can fail based on geometry limits. You MUST wrap them in a `pcall`, verify the result is a `BasePart`, and explicitly clean up the cutters.

```lua
-- Safe CSG Execution
local success, result = pcall(function()
    return basePart:SubtractAsync({cutterPart})
end)

if success and result and result:IsA("BasePart") then
    -- CRITICAL: Copy exact CFrame and re-apply color/material
    result.CFrame = basePart.CFrame
    result.UsePartColor = true
    result.Color = basePart.Color
    result.Material = basePart.Material
    
    result.Name = basePart.Name
    result.Anchored = true
    result.Parent = basePart.Parent
    
    -- Cleanup original
    basePart:Destroy()
else
    warn("CSG Operation failed or returned nil")
end

-- Always cleanup cutters regardless of success
cutterPart:Destroy()
```
