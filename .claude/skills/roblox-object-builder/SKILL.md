---
name: roblox-object-builder
description: >
  Build 3D objects, buildings, and maps in Roblox Studio via MCP.
  Handles single objects through large-scale hubs.
  Use when: user asks to create, build, or place ANY physical object in Roblox —
  furniture, animals, vehicles, gates, towers, arenas, lobbies, hubs, decorations,
  terrain features, or any tangible in-game structure.
  Triggers on casual requests like "○○を作って", "○○を置いて", "Lobbyを作りたい",
  "build me a ___", "create a ___", "make a ___" in the context of Roblox Studio.
  Also use when user mentions CSG, Union, Subtract, Part placement, or 3D modeling
  in Roblox. If the user is in a Roblox project and asks to "make" or "build"
  something physical, this skill should trigger even without explicit mention of
  "3D" or "Roblox".
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
