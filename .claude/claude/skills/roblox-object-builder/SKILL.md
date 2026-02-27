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

MCP executions are stateless — redeclare helpers and re-acquire references every call.

---

## Code Patterns

These patterns apply to **every build** regardless of project strategy or scale.

### Relative CFrame Pattern (mandatory for 2+ related parts)

All sub-component positions MUST be computed relative to a parent part's CFrame.
Never hardcode absolute world coordinates for sub-components.

```lua
-- WRONG: absolute coordinates — breaks when parent moves or resizes
local doorCF = CFrame.new(10, 3.5, 5)

-- CORRECT: relative to parent
local wall = model:FindFirstChild("Wall_Front")
local doorCF = wall.CFrame * CFrame.new(0, -wall.Size.Y/4, 0)
```

This is non-negotiable. A 10-part gate and a 200-part lobby prop both use this pattern.

### Skeleton-Detail-Verify (SDV) Pattern (recommended for 10+ part objects)

Three-phase build pattern validated across 5 rounds of A/B testing. The only approach
that achieved zero orientation errors.

**Phase 1 — Skeleton (ONE `run_code` call)**

Create all major anchor parts with correct positions, sizes, AND orientations.
Include an axis convention comment:

```
-- Player at -Z | Monitor faces -Z | Keyboard long axis = X | Mouse long axis = Z, buttons -Z
```

**Phase 2 — Detail (multiple `run_code` calls)**

Read existing anchors via `FindFirstChild`, position relative to them:

```lua
local anchor = model:FindFirstChild("Desk_Top")
local kbCF = anchor.CFrame * CFrame.new(-1.5, anchor.Size.Y/2 + 0.15, -1.0)
```

**Phase 3 — Verification (ONE `run_code` call)**

Run automated checks. See [docs/verification.md](docs/verification.md) for template.
Checks: position drift, leaked cutters, orientation, overlap, anchoring, part counts.

**Why SDV works where other approaches fail:**

| Approach | Spatial | Detail | Orientation |
|----------|---------|--------|-------------|
| OneShot (1 call) | Best | Shallow | Unreliable |
| Stepwise (6+) | Worst | Deep | Unreliable |
| **SDV** | **Good** | **Good** | **Reliable** |

### CSG Pattern

For any build involving Union/Subtract operations:

1. **Y-stack plan first**: Write full height stack as comments BEFORE any code
2. **pcall + TriangleCount**: Always check `TriangleCount > 0` after CSG ops
3. **CFrame copy**: `result.CFrame = originalPart.CFrame` — never position-only
4. **Color fix**: `result.UsePartColor = true` + `result.Color = desiredColor`

```lua
-- Y-stack plan (REQUIRED before coding tiered structures)
-- Plaza top: Y = PLAZA_TOP | Basin walls: top = PLAZA_TOP + WALL_H (keep <= 0.5)
-- Water: Y = PLAZA_TOP + WALL_H * 0.75 | Rim: Y = PLAZA_TOP + WALL_H + 0.5
```

See [docs/csg-guide.md](docs/csg-guide.md) for full CSG decision flow.

---

## Project Strategy

Choose based on **user intent**, not part count. Both strategies use the same Code Patterns above.

### Interactive

When: design is uncertain, user wants to iterate, visual feedback is needed.

1. Verbalize shape decomposition (and CSG plan if applicable) before coding
2. Place base shapes → ask user for visual confirmation
3. Apply details, materials, finishing → confirm again

Pause for user confirmation at each major step. You cannot visually verify 3D space.

### Autonomous

When: design is clear, user wants a complete result without interruption.

1. **Declare full design** — zone layout, flow, color palette
2. **Style reference sheet** (if style-heavy) — silhouette keywords, material rules, accent ratio, contrast anchors
3. **Build without pausing** — report briefly per area, then continue
4. **Verify and report** at end

Do NOT pause for user confirmation at every phase.

---

## Scale Practices

Supplementary guidance based on build size. Combine with any Project Strategy.

### Small (< ~30 parts)

- 1-3 `run_code` calls sufficient
- SDV Pattern optional but recommended if the object has distinct sub-assemblies
- Simple folder hierarchy (one Model with PrimaryPart)

### Medium (~30-150 parts)

- SDV Pattern strongly recommended
- **Data tables + `makePart` helpers** for repetitive elements
- **Sub-folder hierarchy** per object type (Trees/, Benches/, Lamps/)
- Redeclare helpers every `run_code` call (MCP is stateless)

### Large (> ~150 parts)

All Medium practices, plus:

- **Build by area** — Foundation → Buildings → Zones → Details → Atmosphere
- **Exemplar-then-clone** — build one high-quality instance per prop type, verify, replicate with variation. Prevents "Lost in the Middle" quality degradation.
- **Use SDV for individual hero props within the map** — a fountain inside a lobby gets its own skeleton-detail-verify cycle
- **Free addition slots** (2-3) — room for thematically appropriate elements discovered during build
- **Uniform quality audit** — category <70% of max category's per-prop part count → rebuild
- **Performance budget** — target <1000 parts for lobby; use `CastShadow = false` on decorative parts

---

## Primitive Selection Default

**Block-first** unless user requests rounded/organic forms.

Block → WedgePart/CornerWedgePart → limited Cylinder → Sphere (accent-only)

Exception: Japanese temple/pagoda/shrine roofs require WedgePart eaves (see [docs/design-wisdom.md](docs/design-wisdom.md)).
If relaxing Block-first, state why explicitly.

---

## Critical Gotchas

Full details with code examples: [docs/gotchas.md](docs/gotchas.md)

| Gotcha | Rule |
|--------|------|
| Cylinder axis | `Size = (length, dia, dia)`. Upright: `Angles(0, 0, π/2)`. Height = `Size.X` after rotation. |
| Position = BB center | Floor at Y=0 → `Pos.Y = Size.Y / 2` |
| CSG silent failure | `pcall` + check `TriangleCount > 0` |
| CSG color | `UsePartColor = true` + `Color` after every CSG op |
| CSG CFrame | Copy `originalPart.CFrame` — never reconstruct from position alone |
| Anchored | Defaults to `false`. Set `true` on all structural parts. |
| SpawnLocation | Auto-detected for respawning. Set `Neutral = false` or `Transparency = 1`. |
| Constraints | Cannot meet user constraint → ask, never silently break |

---

## Scale Reference

```
Player: ~5 studs | Door: 4w × 7h | Ceiling: 10-14 | Hall: 20-35
Corridor: 6-8w | Neon thickness: 0.1-0.4
Map: 10p ~150² | 20p ~250² | 30p ~350² | Buildings: 30-90h (vary for skyline)
```

---

## Post-Build Gate

Run before reporting completion on **every build**, regardless of strategy or scale.

1. **Geometry**: Paths >= 90% of ground size. Furniture facing: `-LookVector · toCenter > 0`. No large surface all RGB > 225. Adjacent surfaces differ >= 30 in one channel.
2. **Readability**: Hero props recognizable in <1s at oblique view. Layered anatomy (base + body + accent), not symbolic primitives.
3. **CSG quota** (rounded/ornamental themes): >= 1 intentional CSG feature. Log reason if skipped.
4. **Verification**: Run [docs/verification.md](docs/verification.md) checks (position drift, leaked cutters, orientation, overlap, anchoring, part counts).

---

## Supplementary Docs

Read when relevant, not every time.

| File | When to read |
|------|-------------|
| [reference.md](reference.md) | Style-heavy builds (pastel/cute/sci-fi) |
| [docs/design-wisdom.md](docs/design-wisdom.md) | Map layouts, color rules, detail patterns |
| [docs/csg-guide.md](docs/csg-guide.md) | CSG decisions, safe practices, minimums |
| [docs/gotchas.md](docs/gotchas.md) | Debugging or preventive reference |
| [docs/verification.md](docs/verification.md) | Post-build verification code template |
