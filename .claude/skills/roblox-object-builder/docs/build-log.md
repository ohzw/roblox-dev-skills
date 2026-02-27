# Build Log

Specific failure incidents from past builds. This file is for **human review only** —
AI does not read this directly. When a pattern recurs or generalizes, promote the
abstract rule to `gotchas.md`.

---

## How to use

- `roblox-build-retrospective` skill outputs go here
- Each entry: date, build subject, what happened, what was learned
- Tag with the gotcha category it relates to (if any)
- If multiple entries point to the same new rule → promote to gotchas.md

---

## Entries

### Fountain: Cylinder Size.X vs Size.Y confusion

**Build**: Park fountain with cylindrical basin
**Category**: Cylinder axis
**Incident**: Entire debug session produced wrong top/bottom values. Every calculation
was off by ~8× because `Size.Y` (diameter) was used instead of `Size.X` (height) for
an upright Z-rotated cylinder.
**Promoted to**: gotchas.md "Cylinder axis = X" with corollary.

### Park bench: LookVector verification reversed correct benches

**Build**: Pastel park with benches facing central fountain
**Category**: LookVector
**Incident**: Bench orientation check used `LookVector.Dot(toCenter) > 0` to verify
benches face the center. But LookVector = backrest direction. The check was inverted,
and the "fix" reversed all correctly-placed benches.
**Promoted to**: gotchas.md "LookVector = backrest direction".

### Desk setup: Keyboard/mouse/monitor orientation errors (~80% failure rate)

**Build**: Gaming desk with peripherals
**Category**: Multi-component orientation
**Incident**: Keyboard faced backward, mouse buttons pointed away from player.
Prompt-level fixes (comments, constants) did not help. Only structural fix
(anchor CFrame inheritance) achieved zero orientation errors across 5 test rounds.
**Orientation reference for desk items**:
```
Player at -Z, looking toward +Z
Monitor:   LookVector ≈ (0,0,-1), screen on -Z face
Keyboard:  long axis = X, keys face +Y, front edge at -Z
Mouse:     long axis = Z, buttons at -Z, cable at +Z
PC Tower:  front panel faces -Z or -X
Speakers:  driver cone faces -Z
```
**Promoted to**: gotchas.md "relative CFrame" pattern (abstract). Desk-specific
orientation table stays here as reference.

### Ship: Sail panels all faced fore-aft

**Build**: Pirate ship with mast and sails
**Category**: Flat panel orientation
**Incident**: All sails on a ship faced fore-aft instead of port-starboard.
`Size = (0.3, H, W)` has wide face in Y-Z plane by default. Sails needed
`CFrame.Angles(0, math.pi/2, 0)` to face X-Y.
**Promoted to**: gotchas.md "Flat panel default face = Y-Z plane".

### Ship: Shrouds ran fore-aft instead of diagonally

**Build**: Pirate ship rigging
**Category**: CFrame.lookAt for beams
**Incident**: `CFrame.lookAt(mid, endPoint)` aligns -Z with direction, but rope
Block's long axis is Y. Without `* CFrame.Angles(math.pi/2, 0, 0)` correction,
all rigging pointed the wrong way.
**Promoted to**: gotchas.md "CFrame.lookAt for beams/ropes" with helper function.

### Ship: Fix cascade on rigging rope

**Build**: Pirate ship rigging repair
**Category**: Fix cascade
**Incident**: Correcting `Size.Y` of a rigging rope left `Size.Z = 35` from old
code. A thin rope became a "flying wooden plank". The incremental fix script set
only the target property without reading/verifying all axes.
**Promoted to**: gotchas.md "Fix cascade" with read-before-write pattern.

### Meeting room: Block-only chairs unrecognizable

**Build**: Silicon Valley meeting room
**Category**: Shape quality
**Incident**: All 10 chairs were rectangular block compositions (seat block +
back block + post block). No armrests, no curvature, no CSG. 138 total parts but
only 1 CSG operation (door cutout). Root cause: SKILL.md "Block-first" rule and
CSG avoidance framing suppressed the AI's object knowledge.
**Promoted to**: SKILL.md anti-pattern "Don't build block-only compositions" and
"Don't avoid CSG". Block-first rule removed entirely.
