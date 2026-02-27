---
name: roblox-object-builder
description: >
  Build 3D objects, props, and room-scale structures in Roblox Studio via MCP.
  Use when: user asks to create, build, or place a single physical object —
  furniture, animals, vehicles, gates, towers, decorations, street props,
  room interiors, or any individual tangible structure.
  Triggers on: "○○を作って", "○○を置いて", "build me a ___", "create a ___",
  "make a ___" in the context of Roblox Studio.
  Also use when user mentions CSG, Union, Subtract, Part placement, or 3D modeling
  in Roblox. If the user is in a Roblox project and asks to "make" or "build"
  something physical, this skill should trigger even without explicit mention of
  "3D" or "Roblox".
  Scope boundary: for full maps, arenas, lobbies, hubs, or multi-zone environments → use roblox-map-builder instead.
---

# Roblox Object Builder

## MCP Tools

| Tool | Purpose |
|------|---------|
| `mcp__roblox__run_code` | Execute Lua code (create, modify, verify) |
| `mcp__roblox__insert_model` | Insert existing models |

`run_code` executions are stateless — redeclare helpers and re-acquire references every call.

---

## Anti-Patterns

Known failure modes. Avoid these on every build.

### Don't hardcode absolute coordinates for sub-components

All sub-component positions MUST be relative to a parent part's CFrame.
Hardcoded world coordinates break when the parent moves or resizes, and
cause cumulative drift across multiple `run_code` calls.

```lua
-- WRONG
local doorCF = CFrame.new(10, 3.5, 5)

-- RIGHT
local doorCF = wall.CFrame * CFrame.new(0, -wall.Size.Y/4, 0)
```

### Don't build block-only compositions

If the real-world object has curves, recesses, or holes — represent them.
Before coding, list: "Where in this object are curves, recesses, or holes?"
Use CSG (SubtractAsync/UnionAsync), Cylinders, or Spheres to represent them.

A chair needs seat curvature or armrest shape. A planter needs a rim.
A light fixture needs a shade profile. Flat rectangular blocks for everything
reads as placeholder geometry, not a finished build.

### Don't avoid CSG

CSG is essential for quality. Use it freely with these safety rules:

```lua
local ok, result = pcall(function()
    return base:SubtractAsync({cutter})
end)
if ok and result:IsA("BasePart") then
    result.CFrame = base.CFrame  -- copy FULL CFrame, never position-only
    result.UsePartColor = true
    result.Color = desiredColor
    result.Anchored = true
    result.Name = base.Name
    result.Parent = base.Parent
    base:Destroy()
end
cutter:Destroy()  -- always clean up cutters
```

See [docs/csg-guide.md](docs/csg-guide.md) for decision flow and details.

### Don't mass-produce before quality-checking one instance

When placing multiple copies (chairs, lights, trees), build one exemplar first.
Verify its shape reads as the intended object. Then clone with variation.

### Don't forget anchoring

`Anchored` defaults to `false`. Set `true` on all structural and decorative parts.

---

## Roblox-Specific Gotchas

Things AI training data won't reliably cover.

| Gotcha | Rule |
|--------|------|
| Cylinder axis | `Size = (length, dia, dia)`. Upright: `Angles(0, 0, π/2)`. Height = `Size.X` after rotation. |
| Position = BB center | Floor at Y=0 → `Pos.Y = Size.Y / 2` |
| CSG silent failure | `pcall` + verify result is BasePart with geometry |
| CSG color bleed | `UsePartColor = true` + `Color` after every CSG op |
| CSG CFrame reset | Copy full `CFrame` — `CFrame.new(x,y,z)` resets rotation to identity |
| SpawnLocation | Auto-detected for respawning. Set `Neutral = false` or `Transparency = 1`. |
| Neon emits no light | Pair with `PointLight` / `SpotLight` for actual illumination |
| MCP stateless | Redeclare helpers & re-acquire references every `run_code` call |

Full details with code examples: [docs/gotchas.md](docs/gotchas.md)

---

## Scale Reference

```
Player: ~5 studs | Door: 4w × 7h | Ceiling: 10-14 (small), 16+ (4+ person room) | Hall: 20-35
Corridor: 6-8w | Neon thickness: 0.1-0.4
```

---

## Post-Build Gate

Run before reporting completion.

1. **Shape quality**: Every placed object recognizable at a glance. No object is just rectangular blocks if the real-world version has curves, recesses, or distinctive silhouette features.
2. **CSG check**: At least 1 intentional CSG feature for any build with furniture, architecture, or decorative elements. If zero, list where curves/recesses were skipped and reconsider.
3. **Technical**: All parts anchored. No leaked CSG cutters in workspace. No floor penetration (`bottom_Y >= floor surface`).
4. **Color/material**: Adjacent large surfaces differ visibly. No large surface has all RGB channels > 225.
5. **Vegetation** *(4th-session recurring failure)*: Foliage = **`Enum.PartType.Block` parts only**. Sphere AND Cylinder are both banned as primary foliage — they produce rounded blobs that look wrong in Roblox's block-style world. Use stacked flat rectangular Blocks (tiered layer cake). Cylindrical planters must be upright (`CFrame.Angles(0, 0, math.pi/2)`).
6. **Seated furniture orientation** *(MANDATORY — recurring failure)*: For every chair/bench placed, verify the person faces the focal point (table, screen, stage). Person faces `-LookVector`. Run this check before reporting done:
   ```lua
   -- Paste into a verification run_code call; adjust model/part names
   local model = workspace:FindFirstChild("ConferenceRoom")
   local focal = model and model:FindFirstChild("Table_Top", true)
   for _, p in ipairs(model:GetDescendants()) do
     if p:IsA("BasePart") and (p.Name:lower():find("seat") or p.Name:lower():find("chair")) then
       local dot = (-p.CFrame.LookVector):Dot((focal.Position - p.Position).Unit)
       print(p.Name, math.floor(dot*100)/100, dot > 0 and "OK" or "REVERSED")
     end
   end
   ```
   Any REVERSED result must be fixed before reporting done.
7. **Seated furniture Y position** *(recurring failure)*: Every seat part's bottom face must be at or above the floor surface. Run this check:
   ```lua
   local model = workspace:FindFirstChild("ConferenceRoom")
   local floor = model and model:FindFirstChild("Floor", true)
   local floorTop = floor.Position.Y + floor.Size.Y / 2
   for _, p in ipairs(model:GetDescendants()) do
     if p:IsA("BasePart") and p.Name:lower():find("seat") then
       local bottom = p.Position.Y - p.Size.Y / 2
       print(p.Name, "bottom:", math.floor(bottom*100)/100,
         bottom >= floorTop - 0.1 and "OK" or ("BELOW FLOOR (floorTop=" .. math.floor(floorTop*10)/10 .. ")"))
     end
   end
   ```
   Any BELOW FLOOR result means `Position.Y = floorTop + Size.Y/2 + legHeight` was not used.

---

## Supplementary Docs

Read when relevant, not every time.

| File | When to read |
|------|-------------|
| [docs/csg-guide.md](docs/csg-guide.md) | CSG decisions, safe practices |
| [docs/gotchas.md](docs/gotchas.md) | Debugging or preventive reference |
| [docs/design-wisdom.md](docs/design-wisdom.md) | Roblox-specific rendering/material behavior |
| [docs/verification.md](docs/verification.md) | Post-build verification code template |
| [reference.md](reference.md) | Style-heavy builds (pastel/cute/sci-fi) |
