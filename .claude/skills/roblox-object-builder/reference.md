# Visual Reference System

Use this file before coding style-heavy builds (pastel/cute/cozy/stylized).
It translates vague taste requests into concrete constraints.

---

## How To Use In This Skill

1. Pick one `Reference Preset` (or duplicate and customize).
2. Copy `Identity`, `Palette`, `Shape Language`, `Lighting Signature` into build plan.
3. Build one hero prop first (fountain/arch/flower/bench).
4. Run `Acceptance Gates` before large-scale cloning.
5. Score with `Rubric` (minimum pass: 8/12).

If the score is below pass, revise palette/shape/composition before finalizing.

---

## Schema (Template)

```markdown
# Visual Reference: [Theme Name]

## 1. Identity
| Field | Value |
|---|---|
| Theme | [name] |
| Tone | [cozy/cheerful/magical/etc.] |
| Primary refs | [IDs from Source Bank] |
| Anti-refs | [styles to avoid] |

## 2. Palette
| Role | Hex | Roblox approx | Notes |
|---|---|---|---|
| Ground | | | |
| Path | | | |
| Foliage dark | | | |
| Foliage mid | | | |
| Foliage light | | | |
| Accent A | | | |
| Accent B | | | |
| Shadow tint | | | |

Rules:
- Max 6 colors per object
- No pure black/white on large surfaces
- Keep adjacent large-surface contrast >= 30 RGB on at least one channel

## 3. Shape Language
- [ ] Silhouette readable from top + oblique view
- [ ] Hero props use layered anatomy (base/body/accent)
- [ ] Avoid symbolic primitives (single sphere/box pretending to be complex props)

## 4. Lighting Signature
| Property | Value |
|---|---|
| Ambient | |
| Brightness | |
| Shadow tint | |
| Bloom threshold/intensity | |

## 5. Composition Rules
- Tree spacing:
- Path width:
- Height variation ratio (low/mid/high):
- Focal points:

## 6. Acceptance Gates
- [ ] All major props are recognizable in under 1 second at oblique camera angle
- [ ] At least 3 height levels exist in scene
- [ ] At least one intentional CSG feature used (for rounded/ornamental themes)
- [ ] Palette and material rules followed

## 7. Scoring Rubric (0-3 each)
| Axis | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| Palette fidelity | Off-theme | Mixed | Mostly aligned | Fully aligned + harmonious |
| Shape language | Generic | Some identity | Clear style | Distinct + memorable |
| Composition | Flat | Basic | Good rhythm | Strong focal flow |
| Lighting mood | Harsh/flat | Acceptable | Cohesive | Signature mood |

Pass score: 8/12
```

---

## Source Bank (10)

Use these as visual anchors when converting user intent into concrete style.

| ID | Reference | URL | Category | Roblox application |
|---|---|---|---|---|
| R1 | mulfok32 palette | https://lospec.com/palette-list/mulfok32 | Palette | Soft pastel base with controlled saturation |
| R2 | Vanilla Milkshake palette | https://lospec.com/palette-list/vanilla-milkshake | Palette | Warm cream/sand tones for paths and props |
| R3 | Pastel QT palette | https://lospec.com/palette-list/pastel-qt | Palette | Tight 7-color constraint to prevent color drift |
| R4 | Fairydust 8 palette | https://lospec.com/palette-list/fairydust-8 | Palette/Lighting | Warm light + cool shadow pairing |
| R5 | Iridescent Crystal palette | https://lospec.com/palette-list/iridescent-crystal | FX palette | Magical accent colors for small focal props |
| R6 | Hydrangea 11 palette | https://lospec.com/palette-list/hydrangea-11 | Seasonal palette | Floral park theming and foliage hierarchy |
| R7 | A Short Hike | https://ashorthike.com | Shape/Environment | Rounded low-poly forms + readable silhouettes |
| R8 | Animal Crossing: New Horizons | https://www.animal-crossing.com/new-horizons/ | Composition | Friendly spacing, path rhythm, prop scale |
| R9 | Kirby's Return to Dream Land Deluxe | https://www.nintendo.com/en-US/games/detail/kirbys-return-to-dream-land-deluxe-switch/ | Shape language | Puffy/cute object grammar |
| R10 | Yoshi's Crafted World | https://yoshiscraftedworld.nintendo.com | Material language | Handmade, playful form and color blocking |

---

## Reference Preset: Pastel Studs Park

## 1. Identity

| Field | Value |
|---|---|
| Theme | Pastel Studs Park |
| Tone | Cheerful, cozy, child-friendly |
| Primary refs | R1, R2, R7, R8, R9 |
| Anti-refs | Industrial gray, cyberpunk neon, hard-edged brutalist forms |

## 2. Palette

| Role | Hex | Roblox approx | Notes |
|---|---|---|---|
| Ground | #B7DFAE | Medium green | Keep saturation soft, not gray |
| Path | #F3DFC8 | Brick yellow / custom | Warm cream anchor |
| Foliage dark | #8FCF9A | Bright green | Leaf shadow mass |
| Foliage mid | #AEE7B8 | Light green | Main canopy tone |
| Foliage light | #D8F2DF | Mint tint | Highlight blobs only |
| Accent pink | #F4B8C9 | Pink | Benches, floral props |
| Accent blue | #B9DDF6 | Pastel blue | Fountain/water accents |
| Shadow tint | #C5CAE9 | Custom Color3 | Avoid neutral black shadows |

Rules:
- Max 6 colors per object
- No large-surface pure white (`#FFFFFF`) or pure black (`#000000`)
- Prefer warm-cool pairings: cream + mint/pink

## 3. Shape Language

- [x] Hero props use layered structure (base/body/accent)
- [x] Arch must show clear through-opening (negative space)
- [x] Flower must include planter or stem, not sphere ring only

## 4. Lighting Signature

| Property | Value |
|---|---|
| Ambient | Warm daylight tint |
| Brightness | 1.0-1.2 |
| Shadow tint | Soft lavender-blue |
| Bloom | Threshold >= 0.95, Intensity 0.2-0.3 |

## 5. Composition Rules

- Tree spacing: 4-8 studs, with mild irregularity
- Path width: 20+ studs for main cross in plaza-style park
- Height ratio: low/mid/high = 50/30/20
- Focal points: center fountain + 4 gateway anchors + repeating flower clusters

## 6. Acceptance Gates

- [ ] Oblique camera view: fountain/flower/arch readable instantly
- [ ] At least 3 height bands (ground props / seating / trees-lamps)
- [ ] At least one intentional CSG feature (ring basin or arch cutout)
- [ ] Studs usage visible on key walkable surfaces

## 7. Scoring Rubric Target

| Axis | Target |
|---|---|
| Palette fidelity | 3 |
| Shape language | 3 |
| Composition | 2+ |
| Lighting mood | 2+ |

Minimum pass: 8/12
