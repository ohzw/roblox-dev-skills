# Plan: Finalize `building-3d-objects` and `building-maps` SKILLs

## Goal
Integrate the specific, high-value countermeasures identified in the research report (`ai-primitive-modeling-csg-countermeasures.md`) into the newly created SKILL document ecosystem, ensuring that AI agents can effectively utilize them to mitigate known limitations of LLMs and CSG operations in Roblox.

## Context & Justification
The SKILL architecture (using a main `SKILL.md` and progressive disclosure via a `docs/` folder) was successfully established. However, a self-review by the general subagent revealed that while the skeleton is sound, several critical patterns from the research report were not explicitly codified in the auxiliary documentation. Specifically:
1. **Context Loss (L1-3)**: The "Geometric Manifest" pattern missed the "Summary Header" aspect, which is vital for preventing the AI from forgetting spatial coordinates across chunks.
2. **Float Drift (L1-2)**: The integer grid recommendation was too weak, suggesting small fractions instead of enforcing integer alignment where possible.
3. **CSG Non-Uniqueness (L2-5)**: The CSG patterns missed the heuristic to "Keep CSG trees shallow," which is necessary to prevent runaway boolean complexity.
4. **Platform Limitations (L3)**: Roblox-specific CSG limitations (MeshPart incompatibility, floating-point precision loss far from the origin) were missing from the platform rules.

## Proposed Modifications

The following exact text additions should be applied to the `.claude/skills/` directory.

### 1. Update `building-3d-objects/docs/spatial-patterns.md`

**Current State**: Explains Geometric Manifest but doesn't mention summary headers. Recommends snapping to fractional grids like `0.125`.
**Proposed Change**: 
- Rename section 1 to "Geometric Manifest & Summary Header".
- Add instructions to include a commented summary of existing parts when continuing from a previous run.
- Update section 3 to "Integer Grid Preference", emphasizing that floating-point numbers compound tokenization errors and integer studs (1, 2, 5) should be used whenever strict alignment is not required.

### 2. Update `building-3d-objects/docs/csg-patterns.md`

**Current State**: Covers the EPSILON rule and safe `pcall` execution.
**Proposed Change**:
- Prepend a new section "CSG Construction Heuristics (Keep it Shallow)".
- Define the priority order: 1. Dominant Volume, 2. Subtractions, 3. Additions (Protrusions).
- Add the rule: "Avoid subtracting from a part that was already unioned multiple times."

### 3. Update `building-3d-objects/docs/platform-rules.md`

**Current State**: Covers Cylinder orientation, Neon lighting, and SpawnLocations.
**Proposed Change**:
- Append a new section "CSG Best Practices for Roblox Engine".
- Add the "Origin Processing" rule: Perform complex CSG operations near `CFrame.new(0, 0, 0)`, then `PivotTo()` the final Model to its intended location.
- Add the "No MeshPart CSG" rule: Explicitly state that `GeometryService` ONLY supports `Part` and `PartOperation`.
- Add the "Collision Fidelity" rule: For decorative Unions, set `CollisionFidelity = Enum.CollisionFidelity.Box` to save performance.

## Execution Steps

Once out of plan mode, the following commands/edits will be executed:
1. Apply the text replacements defined above to the respective markdown files in `.claude/skills/building-3d-objects/docs/`.
2. Review the resulting files to ensure the markdown formatting is unbroken.
3. Consider the SKILL refinement process complete, allowing the user to proceed to empirical A/B testing as recommended by the CLAUDE.md guidelines.