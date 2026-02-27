---
name: roblox-build-retrospective
description: >
  Retrospective analysis skill for Roblox 3D object building sessions.
  It analyzes what worked, what failed, and why, then feeds validated
  learnings back into roblox-object-builder docs. Trigger after Roblox
  builds that create or modify Parts, Models, CSG, or map elements via
  mcp__roblox__run_code, and when users request review keywords such as
  "振り返り", "retrospective", "what went wrong", or "analyze the result".
---

# Roblox Build Retrospective

Closes the learning loop for `roblox-object-builder`. Extracts structured knowledge
from build sessions and writes validated findings into the builder skill's docs.

## Trigger Conditions

### Automatic — trigger without user request if ANY apply

- Same operation required >= 2 MCP retries in one session
- Any `pcall` returned `false`
- User expressed negative feedback: "違う", "おかしい", "wrong", "not right"
- Build produced >= 100 parts and completed

### Manual — always trigger when user says

"振り返り", "retrospective", "what went wrong", "analyze the result"

---

## Target Files

```
roblox-object-builder/
├── SKILL.md              ← Code Patterns, Project Strategy, Scale Practices
├── docs/gotchas.md       ← Technical pitfalls
├── docs/design-wisdom.md ← Design knowledge
└── docs/csg-guide.md     ← CSG practices
```

Path: `.claude/skills/roblox-object-builder/`

---

## Retrospective Process

### Phase 1: Context Collection

First, scan `session-log.md` for **Open questions** relevant to this build type.
Note any matches for evaluation in Phase 3.

Then reconstruct from conversation:

1. **Goal**: Object type, scale, style
2. **MCP calls**: Summary of each `run_code` invocation
3. **Corrections & retries**: Where the agent backtracked (richest signal)
4. **Final state**: Complete? User satisfied?

Explicit request → present summary, ask for confirmation.
Proactive trigger → concise summary, ask only targeted questions.

### Phase 2: User Feedback

Short checklist (proactive default):

```
1. Positioning/scale issues?
2. Color/material/neon issues?
3. CSG artifacts or broken geometry?
```

Explicit request → add: 4. Scale feel? 5. Anything else?

If user provides screenshot, analyze carefully for visual issues.

### Phase 3: Structured Analysis

| Domain | Target file |
|--------|-------------|
| Geometry | gotchas.md |
| CSG | csg-guide.md |
| Materials | design-wisdom.md |
| Design | design-wisdom.md |
| Process | SKILL.md |
| Performance | gotchas.md |

Per finding:

```
### [Title] (DOMAIN)
Signal: RED / GREEN
Symptom: [observed]
Root cause: [why]
Fix: [what to do — process-level, not object-specific]
Prevention: [rule to add — must pass Abstraction Check below]
Confidence: HIGH / MEDIUM / LOW
```

#### Abstraction Check (MANDATORY for every finding before writing to skill)

Ask: **"Does this finding still make sense as a rule if I remove all specific object names?"**

- YES → OK to write. It is general process knowledge.
- NO → Raise the abstraction level. Describe the **structural condition**, not the object.

Example:

```
BAD:  "Use SubtractAsync to carve a basin into a kitchen sink"
      → Remove "kitchen sink" and the rule collapses. It is object-dependent.

GOOD: "Any surface that is concave in the real world should be carved with
       SubtractAsync. Placing a block on top of a flat surface does not read
       as a recess."
      → Works regardless of object — sink, bathtub, sofa seat, fountain basin.
```

Only HIGH/MEDIUM → write to skill. LOW → session log only.
Evaluate any Open questions from Phase 1 against this session's evidence.

### Phase 4: Knowledge Integration

For each HIGH/MEDIUM finding:

1. Verify it passes the Phase 3 Abstraction Check
2. Read target file, check for duplicates
3. Duplicate exists → update/strengthen. New → add in appropriate section.
4. Write using Edit tool, show diff to user

#### Writing Rules

**WHAT TO WRITE — process knowledge that transfers across objects:**

- **Structural conditions:** Under what circumstances does the problem occur?
  (e.g., "When two surfaces share the exact same world-space plane")
- **Root mechanisms:** Why does it fail or succeed?
  (e.g., "The GPU cannot determine draw order for co-planar faces")
- **Process-level remedies:** What steps prevent or fix the issue?
  (e.g., "Offset the decorative part by +0.05 studs along the face normal")
- **Decision criteria:** When to choose one approach over another?
  (e.g., "If the real-world surface is concave → CSG. If flat → Block")

**WHAT NOT TO WRITE — object-specific recipes that limit AI reasoning:**

- **Code snippets for specific objects.** "Sink CSG code", "stove recess code", etc.
  The AI will copy-paste without thinking. When it encounters an object not covered
  by a snippet, it defaults to "no pattern found → skip", degrading general capability.
- **Rules that depend on object names.** "Use CSG for kitchen sinks" fires only in
  kitchens. "Use CSG for concave surfaces" fires everywhere.
- **Hardcoded dimensions.** "Sink cutter should be 3.5 x 2 x 4.2" — the AI can
  determine sizes on its own. Only constrain with **relative rules** like "cutter
  must exceed target by +2 studs on each axis".

**Litmus test when in doubt:**

> "Would an AI reading this entry benefit from it when building a completely
> different object?"
>
> YES → write it.  NO → raise the abstraction level and rewrite.

Additional:
- Match existing file voice/structure
- Frame as what to DO, not just what went wrong
- Contradictions → flag for user review
- Update `last-validated` date on new/updated/confirmed entries

### Phase 5: Session Log

Append to `.claude/skills/roblox-build-retrospective/knowledge/session-log.md`:

```
## [Date] - [Object Name]
Goal: [what] | Outcome: SUCCESS / PARTIAL / FAILURE
Key findings: [finding - domain - signal - confidence]
Skill updates: [file: what changed]
Open question resolution: [VALIDATED / REFUTED / STILL OPEN + evidence]
Open questions: [LOW confidence items for future validation]
```

---

## Signal Detection

### Red Flags (knowledge gaps)

- Multiple MCP retries → missing/incorrect guidance
- Agent self-correcting → approach doesn't work
- User "that's not right" → verification gap
- `pcall` false → unhandled edge case
- Parts at Y=0 or overlapping → positioning formula error

### Green Flags (preserve patterns)

- Clean first-try success → document approach
- Efficient part count → note decomposition
- User praise → capture design choices

---

## Multi-Session Meta-Analysis (after 3+ sessions)

1. **Frequency**: Which domains dominate? Focus skill improvements there.
2. **Recurring LOW**: Same hypothesis 2+ times → elevate to MEDIUM, add to skill.
3. **Contradictions**: Flag for user review.
4. **Bloat check**: docs > 300 lines → consider reorganizing or extracting.
5. **Abstraction audit**: Scan all skill files for object-specific snippets or hardcoded
   dimensions that have crept in. Rewrite to process-level or delete.
6. **Staleness**: `last-validated` > 3 sessions old → report to user (do NOT auto-delete).

---

## Principles

- **Write process, not recipes**: Skills build AI judgment. Teaching how to build a specific
  object makes the AI copy instead of think, degrading its ability to handle novel objects.
  Write "under what conditions, why, and how to decide". Never write "what to build and how".
- **Don't over-generalize**: "CSG fails when overlap < 2 studs" not "CSG always fails"
- **Don't over-specify**: "Use CSG for kitchen sinks" only fires in kitchens.
  "Use CSG for concave surfaces" fires everywhere. Always prefer the latter.
- **Preserve what works**: Document WHY smooth builds went smoothly
- **User drives priority**: Focus on what the user flags
- **Confidence gating**: LOW speculation degrades skill quality — session log holds hypotheses
