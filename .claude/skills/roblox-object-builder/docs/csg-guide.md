# CSG Usage Guide

AI tends to avoid CSG, defaulting to all-rectangular compositions. CSG is essential
for professional-quality scenes.

## Core Principle: CSG = recesses, holes, and curves

The decision to use CSG is simple: **if the real-world surface has a recess, a hole,
or a curve, represent it with CSG in Roblox too.**

Placing a block on top of a flat surface does not read as a recess — it reads as a
block sitting on a surface. Humans instantly perceive the difference.

## Decision Flow

For each part of the object, ask:

```
Is this surface flat in the real world?
├─ YES → Block / WedgePart is sufficient
└─ NO  → Is it concave, perforated, or curved?
          ├─ Concave (basin, bowl, recess, well) → SubtractAsync
          ├─ Perforated (window, arch, passage)  → SubtractAsync
          ├─ Curved (pillar, pipe, round table)   → Cylinder / Sphere
          └─ Compound curve (pipe bend, rounded edge) → UnionAsync
```

**This decision applies regardless of theme.** It is not tied to any specific object
type — it fires on the structural shape, not the object name.

## What Works

### 1. List all recesses and holes before building

Before writing any code, enumerate "where in this object are there recesses, holes,
or curves?" Attempting to add CSG after the fact leads to coordinate mismatches and
higher failure rates.

### 2. Generate CSG target parts as standalone pieces

The SubtractAsync target should be a fresh, standalone part — not already unioned
with other geometry. Subtracting from an existing union is fragile and often produces
broken meshes.

### 3. Make cutters significantly larger than the target (+2 studs minimum)

Merely touching surfaces can produce empty meshes (TriangleCount == 0).
Cutters must clearly penetrate through the target.

### 4. Always set properties on the CSG result

```lua
result.UsePartColor = true
result.Color = desiredColor
result.CollisionFidelity = Enum.CollisionFidelity.Box  -- Box for decorative
```

Without this, the cutter's color bleeds onto cut surfaces and collision is inaccurate.

### 5. Destroy cutters immediately after the operation

Leftover cutter parts render as visible garbage in the workspace.
Always call `:Destroy()` on every cutter after the CSG operation succeeds.

## What Fails

### Substituting a recess with a block placed on top

**Symptom:** A surface that should be concave looks like a flat slab with a box on it.

**Why it fails:** Real-world recesses have a rim and a floor. A block placed on a flat
surface has neither. Humans recognize this instantly as "wrong" even at Roblox scale.

**What to do instead:** Use SubtractAsync to carve the recess. Even a shallow cut
(0.3 studs) reads as concave.

### Overriding CSG result CFrame with position-only values

**Symptom:** A horizontally-oriented cylinder CSG result suddenly snaps upright.

**Why it fails:** `result.CFrame = CFrame.new(x, y, z)` resets rotation to identity.
SubtractAsync preserves the base part's rotation in its result, but a position-only
override silently strips it.

**What to do instead:** Copy the original part's full CFrame:
`result.CFrame = originalPart.CFrame`. If you need to move it, use
`originalPart.CFrame + Vector3.new(dx, dy, dz)`.

### Unioning parts with different colors

**Symptom:** A two-tone component renders as a single color.

**Why it fails:** UnionAsync applies the first part's color to the entire result.

**What to do instead:** Keep differently-colored sections as separate parts.

### Running CSG mid-phase and expecting FindFirstChild to find the original Part

**Symptom:** `FindFirstChild("PartName")` returns nil in a later phase.

**Why it fails:** CSG converts Parts into UnionOperations. The original Part name is
gone unless you explicitly name the result.

**What to do instead:** Run CSG at the end of a phase or in a dedicated CSG phase.
Always assign a clear name to the result so later phases can find it.

## Minimum CSG Usage

Regardless of theme, a build with zero recesses, holes, or curves does not meet
quality standards.

- **Buildings**: >= 1 of: window cutout, door arch, rounded edge
- **Furniture / appliances**: Every concave surface must use CSG
- **Outdoor structures**: >= 1 of: arch opening, circular floor, curved wall

Verification: Count UnionOperation descendants in Phase 3. If zero, reconsider.

## Safe Practices Checklist

- [ ] Cutter overlap: intersects target by **+2 studs** minimum
- [ ] Max **10 parts** per single Union/Subtract call
- [ ] Verify `TriangleCount > 0` after every operation (0 = silent failure)
- [ ] Set `UsePartColor = true` + `Color = desiredColor`
- [ ] Set `CollisionFidelity`: `Box` (decorative) / `PreciseConvexDecomposition` (functional)
- [ ] Perform CSG **after** positioning is finalized
- [ ] `:Destroy()` all cutter parts
- [ ] Copy `originalPart.CFrame` to result — never reconstruct from position alone
