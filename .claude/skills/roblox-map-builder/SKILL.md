---
name: roblox-map-builder
description: >
  Build maps, areas, zones, and large-scale environments in Roblox Studio via MCP.
  Use when: user asks to create a map, battle arena, lobby, hub, town, village, open area,
  game world, level design, or any environment that spans multiple zones or regions.
  Triggers on: "マップを作って", "エリアを作って", "フィールドを作りたい",
  "build a map", "create an arena", "make a lobby", "design a level",
  "make a hub world", "create a town", or any request involving spatial layout,
  zone planning, or multi-area environments.
  Scope boundary: if the request is a single object, prop, or room interior → use roblox-object-builder instead.
---

# Roblox Map Builder

## MCP Tools

| Tool | Purpose |
|------|---------|
| `mcp__roblox__run_code` | Execute Lua code (create, modify, verify) |
| `mcp__roblox__insert_model` | Insert existing models |

`run_code` executions are stateless — redeclare MAP_ROOT and helpers every call.

---

## Phase 1: Layout Planning (Before Writing Any Code)

Always start here. A map built without a layout plan produces spatial incoherence.

### Define before coding:
1. **Boundary** — total map size in studs (e.g., 200×200)
2. **Zones** — named areas and their approximate footprints
3. **Spawn points** — where players enter each zone
4. **Key landmarks** — visual anchors that orient players
5. **Paths** — how zones connect (corridors, open space, bridges)

### Anchor pattern — use this in every `run_code` call:
```lua
local MAP_ROOT = workspace:FindFirstChild("MapName")
  or Instance.new("Model", workspace)
MAP_ROOT.Name = "MapName"

local ORIGIN = MAP_ROOT:FindFirstChild("Origin")
  or Instance.new("Part", MAP_ROOT)
ORIGIN.Name = "Origin"
ORIGIN.Anchored = true
ORIGIN.Transparency = 1
ORIGIN.Size = Vector3.new(1,1,1)
ORIGIN.Position = Vector3.new(0, 0, 0)  -- set once, never change
```

All zone and part positions must be relative to `ORIGIN.CFrame`, never hardcoded world coords.

---

## Scale Reference

```
Player height:     ~5 studs
Path width:        6–8 studs (2 players side-by-side), 10+ for main roads
Battle arena:      80–200 studs per side
Lobby / Hub:       50–120 studs diameter
Village / Town:    200–500 studs
Wall height:       8–16 studs (outdoor), 10–14 studs (indoor)
Boundary wall:     20+ studs (to prevent camera clipping over)
```

---

## Folder Organization

Always organize into a hierarchy. Never dump parts flat in workspace.

```
workspace/
  MapName/                  ← MAP_ROOT (Model)
    Origin                  ← invisible anchor part
    Terrain/                ← ground planes, terrain features
    Zone_A/                 ← named zone (Model)
      Floor
      Walls/
      Props/
    Zone_B/
    Landmarks/              ← major visual anchors
    Lighting/               ← PointLights, SpotLights, ambient sources
    Spawns/                 ← SpawnLocation instances
```

---

## Build Phases

Break the map build into sequential `run_code` calls. Never try to build the whole map in one call.

| Phase | What to build | Parts per call target |
|-------|--------------|----------------------|
| 1. Ground | Floor plane(s), boundary walls | 10–20 |
| 2. Zone shells | Zone floors, major walls, zone boundaries | 20–40 |
| 3. Landmarks | Towers, fountains, trees, key structures | 20–30 per landmark |
| 4. Zone fill | Props, furniture, vegetation per zone | 20–30 per zone |
| 5. Lighting | PointLights, SpotLights, atmospheric sources | 10–20 |
| 6. Spawns | SpawnLocation placement, team assignment | 5–10 |

**Rule**: Verify each phase visually before moving to the next.

---

## Anti-Patterns

### Don't build the whole map in one run_code call
Split by phase and zone. A single call with 200+ parts is fragile — one error discards everything.

### Don't use hardcoded world coordinates for zone positions
All zone offsets must be relative to ORIGIN.CFrame:
```lua
-- WRONG
local zoneA_floor = CFrame.new(50, 0, 30)

-- RIGHT
local zoneA_floor = ORIGIN.CFrame * CFrame.new(50, 0, 30)
```

### Don't make all zones look identical
Each zone needs a distinct visual identity: different primary material, accent color, or silhouette.
Players must be able to orient themselves by looking at the environment.

### Don't neglect path width
Paths narrower than 6 studs force players into single-file movement. Main roads: 10+ studs.

---

## Post-Build Gate

Run before reporting completion.

1. **Traversal**: Every zone reachable from spawn without jumping over walls or going out of bounds.
2. **Path width**: All main paths ≥ 6 studs wide. Verify with a ruler part if uncertain.
3. **Scale check**: Place a 5×5×5 reference block at spawn. Does the environment feel right relative to player size?
4. **Zone clarity**: Each zone visually distinct — different material, color, or landmark density.
5. **Anchoring**: All parts Anchored = true. No floating parts, no ground penetration.
6. **Hierarchy**: All parts parented inside MAP_ROOT folder hierarchy, not loose in workspace.
7. **Lighting sanity**: No zone is completely dark unless intentional. At least 1 light source per enclosed zone.
8. **Spawns**: SpawnLocation instances exist and are positioned on solid ground.

---

## Supplementary Docs

Shared with roblox-object-builder — read when relevant.

| File | When to read |
|------|-------------|
| [../roblox-object-builder/docs/csg-guide.md](../roblox-object-builder/docs/csg-guide.md) | CSG for map landmarks/structures |
| [../roblox-object-builder/docs/gotchas.md](../roblox-object-builder/docs/gotchas.md) | Cylinder axis, CSG color bleed, anchoring |
| [../roblox-object-builder/docs/design-wisdom.md](../roblox-object-builder/docs/design-wisdom.md) | Material/color rendering behavior |
