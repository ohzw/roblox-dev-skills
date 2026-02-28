**[English](./README.md) | [日本語](./README.ja.md)**

# Roblox Agent Skills

A collection of AI agent skills for building 3D objects and maps in Roblox Studio via MCP.

## Installation

```bash
npx skills add <owner>/roblox-dev-skills
```

## Skills

### roblox-design-consultant

Interactive design consultant that extracts clear requirements through dialogue **before** any implementation begins. Use this when the request is abstract or lacks structural detail.

**Use when:**
- "Make a kitchen", "Build something cool" — vague requests without structure
- You want to define style, scale, and components before building
- `building-3d-objects` detects ambiguity and needs clarification

**How it works:**
1. Asks focused questions (one at a time, max 3–4 turns)
2. Offers concrete style/concept options instead of open-ended questions
3. Outputs a structured **Design Brief** ready to hand off to `building-3d-objects`

---

### building-3d-objects

Builds 3D objects, props, and room-scale structures in Roblox Studio via `mcp__roblox__run_code`.

**Use when:**
- "Build me a ___", "Create a ___", "Make a ___"
- Working with furniture, vehicles, gates, towers, decorations, room interiors
- The result fits within a single `Model`

**What it covers:**
- 4-phase build process: Assess → Plan → Build → Verify
- CSG (Union/Subtract) patterns for curves, holes, and hollow shapes
- Spatial coordinate management across multiple MCP calls
- Post-build validation script to catch unanchored parts and geometry errors
- Multi-variant set support (e.g. "5 sword types")

---

### building-maps

Builds maps, arenas, lobbies, and large-scale multi-zone environments in Roblox Studio.

**Use when:**
- "Build a map", "Create an arena", "Make a lobby", "Design a level"
- The request spans multiple zones or regions
- Spatial layout and zone planning are needed

**What it covers:**
- 6-phase build process: Layout → Ground → Zone Shells → Landmarks → Fill → Environment
- Origin-relative coordinate system to prevent floating-point drift
- Folder hierarchy for organized workspace structure
- Lighting and atmosphere configuration (Lighting service, Atmosphere, SpawnLocation)
- Post-build validation script

## License

MIT
