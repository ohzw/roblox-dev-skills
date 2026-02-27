# Build Retrospective Session Log

Chronological record of retrospective sessions.
Each entry captures what was built, what was learned, and what was updated.

LOW confidence findings accumulate here until validated across sessions.

---

<!-- New sessions are appended below this line -->

## 2026-02-28 - SF Conference Room (SFスタイル・ロールプレイ用会議室)

**Goal:** SFスタイル会議室（ロールプレイ系, 8〜12人, ホワイト+ネオンブルー）
**Process:** roblox-design-consultant → Design Brief → roblox-object-builder (Autonomous)
**Outcome:** PARTIAL — ビルド自体は技術的に成功（0ドリフト, 0 pcall失敗）、しかしユーザーが「スケールが小さかった」と報告

| 項目 | 値 |
|------|-----|
| Parts | 136 |
| Retries | 0 |
| pcall failures | 0 |
| Position drift | 0.00 studs |
| Anchor leaks | 0 |
| Scale feel | ❌ 希望より小さかった（天井 14 studs → ≥ 16 studs 必要） |

**Key findings:**

- Design-consultant の Player Scale Reference「天井高（室内）: 10〜14 studs」に
  多人数閉鎖空間の例外がなく、Design Brief に 14 studs を指定してしまった。
  design-wisdom.md には会議室 ≥ 16 studs ルールが存在するが design-consultant は参照できない。
  (Design - RED - HIGH)
- roblox-object-builder SKILL.md の Scale Reference「Ceiling: 10-14」も同様の矛盾を抱えていた。
  (Process - RED - MEDIUM)
- 椅子・テーブルの脚が床を貫通していた（スクリーンショットで確認）。
  脚の高さが固定値で指定されており、「座面底 → 床上面」のギャップから算出されていなかった。
  SDV の Relative CFrame は位置ズレを防いだが、サイズ計算には適用されなかった。
  (Geometry - RED - HIGH)

**Skill updates made:**

- `roblox-design-consultant/SKILL.md`: Player Scale Reference に「4人以上の閉鎖空間: ≥ 16 studs」行を追加
- `roblox-object-builder/SKILL.md`: Scale Reference の Ceiling を「10-14 (corridor/personal), 16+ (4+ occupant room)」に更新
- `docs/gotchas.md`: 「Bridging parts penetrate floor when height is a constant」追加（脚高さは gap から算出する必須パターン）
- `SKILL.md`: Post-Build Gate に「Floor penetration: leg bottom ≥ floorTop」チェックを追加

**Open question resolution:**

- "Does the room floor CFrame anchor approach reliably prevent position drift?"
  → 0 drift confirmed this session. WEAKLY VALIDATED (approach not directly observed)
- "Does elevating LookVector to SKILL.md's Critical Gotchas table change agent behavior?"
  → No chair orientation complaints reported. STILL OPEN (not explicitly verified)

**Open questions (LOW confidence - validate in future sessions):**

- 天井高が ≥ 16 studs に修正された次回会議室で、ユーザーの「大きさ感」が改善されるか確認が必要。
- Design-consultant が roblox-object-builder の design-wisdom.md を参照できないアーキテクチャ上の
  限界がある。重複ルールの維持コストが増えるため、共通スケール参照の一元化を検討すべきか？

## 2026-02-27 - Conference Room (企業シミュレーター向け中会議室)

**Goal:** カジュアル・スタートアップ風の中会議室（8〜10人収容, ナチュラル×オレンジ, ガラス壁）
**Process:** roblox-design-consultant → Design Brief → roblox-object-builder (Autonomous)
**Outcome:** PARTIAL — 色・マテリアルは成功、スケール・位置・植物・照明で欠陥

| 項目 | 値 |
|------|-----|
| Parts | 79 |
| Retries | 0 |
| pcall failures | 0 |
| CSG | 0（casual style, 適切） |
| Colors match brief | ✅ |
| Scale feel | ❌ 1.5〜2倍必要 |
| Chair orientation | ❌ 全台逆向き |
| Furniture position drift | ❌ 多数ズレあり |
| Vegetation | ❌ Sphere使用（Block-firstに違反） |
| Lighting | ❌ 明るすぎ（屋内用プリセット未適用） |

**Key findings:**

- Interior room scale underestimation: 40×30×12 → 60×45×18+ needed.
  Enclosed rooms feel smaller than open builds at the same dimensions.
  (Geometry/Design - RED - HIGH)
- Seated furniture LookVector re-occurred: chair orientation reversed in conference room.
  Rule existed in gotchas.md but absent from SKILL.md Critical Gotchas quick table.
  (Geometry - RED - HIGH)
- Sphere foliage on plants violates Roblox-style expectation. Map Mode vegetation rule
  was not applied to Object Mode / interior prop builds.
  (Design - RED - HIGH)
- Furniture position drift: likely caused by positions derived from world origin
  instead of room floor CFrame.
  (Geometry - RED - MEDIUM)
- Indoor lighting too bright: no indoor/office lighting preset existed.
  (Materials - RED - MEDIUM)
- Design-consultant brief → clean color execution: explicit RGB values in brief
  prevented all color interpretation errors.
  (Process - GREEN - MEDIUM)

**Skill updates made:**

- `SKILL.md`: Added "Seated furniture facing" row to Critical Gotchas table
- `docs/design-wisdom.md`: Added "Enclosed room sizing" (spaciousness multiplier, min 12 studs²/person, ceiling ≥16)
- `docs/design-wisdom.md`: Extended Block-first vegetation rule to ALL builds (not just Map Mode); code example added
- `docs/gotchas.md`: Added "Furniture in enclosed rooms must be derived from room floor CFrame"
- `docs/design-wisdom.md`: Added "Indoor/office" lighting preset (Brightness 0.7-0.9 + PointLight supplement)

**Open question resolution:**

- "Does no-skill outperform skill at spatial layout for single-room interiors?" (from kitchen session)
  → STILL OPEN — this was a single-agent run, not an A/B test

**Open questions (LOW confidence - validate in future sessions):**

- Does the room floor CFrame anchor approach (furniture relative to roomFloor.CFrame)
  reliably prevent position drift, or does the room itself need to be placed at world
  origin first?
- The chair orientation error (LookVector reversed) persisted even with the gotchas.md
  rule. Does elevating it to SKILL.md's Critical Gotchas table change agent behavior,
  or is a Phase 3 verification check needed that explicitly prints LookVector for seated furniture?

## 2026-02-27 - Wood House Kitchen A/B Test (Skill vs No-Skill)

**Goal:** ウッドハウスのおしゃれなキッチン（単体）を Hybrid 3-Phase (skill) vs ワンショット (no-skill) で比較。

**Outcome:** PARTIAL — both builds had clear visual defects; no-skill had better overall layout feel;
skill had slightly higher part count and self-evaluation score but exhibited critical positioning bugs.

**Objects tested:**

| Build | Parts | Steps | Self-eval | Notable issues |
|-------|-------|-------|-----------|----------------|
| Kitchen_WithSkill | 90 | 5 (Hybrid) | 10/12 (83%) | Fridge door Y-drift, L-counter layout broken, no CSG for sink/stove |
| Kitchen_NoSkill | 79 | 1 (OneShot) | 7.5/10 (75%) | Natural layout, Z-fighting on cabinet door faces |

**User visual assessment (from 5 screenshots):**

- WithSkill (Image 1): Fridge door height misaligned — door panel at wrong Y relative to body.
  (Image 2): L-counter layout broken from above — corner geometry incorrect, stray parts floating.
  (Image 3): Sink = flat gray square (no CSG basin), stove burners floating on blue square with
  mismatched decoration items (red/white clutter). Color palette approved.
- NoSkill (Image 4): Overall layout natural and readable — wall + cabinets + counter in correct
  proportions. Better spatial impression than skill build overall.
  (Image 5): Z-fighting on cabinet drawer fronts — checkerboard artifact from co-planar surfaces.

**Key findings:**

- Kitchen sink requires SubtractAsync CSG basin cutout; all-block sink is flat and unacceptable.
  Agent (with skill) did not use CSG despite csg-guide.md listing it. Kitchen-specific patterns
  were absent from the guide, so agent skipped them.
  (CSG - RED - HIGH)
- Stove top surface should be CSG-recessed 0.2-0.3 studs into body; floating burner discs on
  flat blue square read as toy icons, not cooking surface.
  (CSG - RED - HIGH)
- Fridge door (and any multi-part furniture sub-component) Y must be derived from parent body
  CFrame, not hardcoded absolute Y. Absolute Y drifts when body height/position changes.
  (Geometry - RED - HIGH)
- Co-planar Z-fighting: existing "+0.05 stud margin" rule for embedded parts was NOT applied to
  flush-mounted surfaces (cabinet door faces). Both embedded AND flush cases require the offset.
  (Geometry - RED - HIGH)
- No-skill one-shot achieved better perceived spatial layout (natural wall/cabinet/counter
  proportions) despite lower part count and self-eval score. Skill's Hybrid 3-Phase produced
  broken L-counter geometry — suggests complex 3D L-shaped counter is beyond reliable phase-split.
  (Process - RED - MEDIUM)
- Skill prevented runtime pcall errors (0 retries). No-skill also had 0 retries. For kitchen
  complexity neither approach showed clear error-resilience advantage.
  (Process - neutral)

**Skill updates made:**

- `docs/gotchas.md`: Added "Co-planar surface Z-fighting" — universal +0.05 rule for any two
  co-planar surfaces (not just embedded; flush-mount cases too). Process-level, no object-specific code.
- `docs/gotchas.md`: Added "子パーツの位置は親のCFrameから相対計算する" — all sub-components
  of multi-part objects must derive CFrame from parent. No hardcoded absolute Y. Process-level rule.
- `docs/csg-guide.md`: Full rewrite to process-oriented knowledge. Removed all object-specific
  code snippets (kitchen sink, stove, range hood). Replaced with:
  - Core Principle: 「凹みがあるなら CSG」判断フロー
  - What Works: 5 process steps that lead to successful CSG
  - What Fails: 4 anti-patterns with root causes (floating overlays, position-only CFrame, etc.)
  - Minimum CSG Usage: theme-agnostic quality gate
  - User feedback: object-specific snippets constrain AI reasoning and cause copy-paste dependency

**Open questions (LOW confidence - validate in future sessions):**

- L-shaped counter geometry: is there a reliable formula pattern for joining two counter segments
  at a corner without floating parts or misaligned top surfaces? A corner block strategy (one
  dedicated square piece at the joint) may be the safest approach.
- Would a pre-build "kitchen layout skeleton" (just floor plate + counter footprint outline blocks)
  in Phase 1 reduce L-counter geometry errors in Phase 2?
- Does the no-skill agent's one-shot approach consistently outperform skill at spatial layout for
  single-room interiors (where relative proportions matter more than CSG features)?

---

## 2026-02-26 - Pagoda A/B Test (五重塔, Skill vs No-Skill)

**Goal:** 五重塔 (Five-storied Pagoda) を Hybrid 3-Phase (skill) vs ワンショット (no-skill) で比較。
Material scale rule (DES-036) と 均一品質ルール (DES-037) の初回検証。

**Outcome:** SUCCESS (スキルあり優位。DES-036/DES-037 有効確認。新たな欠陥 DES-039 発見)

**Objects tested:**

| Build | Parts | Floor uniformity | Roof material | Winner |
|-------|-------|-----------------|---------------|--------|
| WithSkill | 140 | 26/26/26/26/26 (完全均一) | SmoothPlastic確認 | 全体品質・配色 |
| WithoutSkill | 158 | 不明 | Neon金縁リング使用 | WedgePart軒の造形 |

**User visual assessment (from screenshots):**
- WithSkill (Image 2): 落ち着いた茶+グレーグリーンの本格的な配色。均一品質。
  ただし屋根がフラット — 反り軒がなく五重塔のシルエット識別度がやや低い。
- WithoutSkill (Image 1): WedgePartによる反り軒が五重塔らしいシルエットを形成。
  しかしNeonネオン黄色リングが全体を支配し「お祭り玩具」感。配色が崩壊。

**Verdict:** スキルありが全体的に優位。ただしWedgePart軒の欠落は明確な改善点。

**Key findings:**

- DES-029 (Neon大面積禁止) が視覚的に再確認。NoSkillのNeon金縁リングが
  塔のシルエットを乗っ取った。SkillのSmoothPlastic遵守が効果的。
  (Materials - GREEN skill / RED no-skill - HIGH)
- DES-037 (均一品質・exemplar-clone) が機能。5層すべて26パーツ均一達成。
  Lost in the Middle は発生しなかった。
  (Process - GREEN - HIGH)
- DES-036 (大面積SmoothPlastic) が機能。SkillはSmoothPlastic確認済み。
  (Materials - GREEN - HIGH)
- DES-018 (Block-first) を厳格適用した結果、五重塔の反り軒 (WedgePart)
  が使われず、フラット屋根になった。日本建築の屋根プロファイルにおいて
  WedgePartは装飾ではなくシルエットの核心要素。
  (Design - RED - HIGH)

**Skill updates made:**
- `docs/design-wisdom.md`: Added [DES-039] "WedgePart roof eaves for temple/pagoda
  architecture" — Block-firstの例外として明示。五重塔・神社・茶室・城のトリガーリスト付き。

**Open questions (LOW confidence - validate in future sessions):**
- DES-039のWedgePart角度(math.rad(15))は適切か？実際に使ってみて調整が必要かもしれない。
- 均一品質ルール(DES-037)は今回の単純な塔構造で成功したが、不均一な複合物体
  (城・邸宅など)でも機能するか？
- スキルなしの158パーツは構造的に何が多いのか確認できず。詳細な内訳分析が必要。

---

## 2026-02-26 - Japanese Garden A/B Test (Skill vs No-Skill, Map Mode)

**Goal:** Compare `roblox-object-builder` skill vs no-skill on a large-scale
Japanese Garden (70×70 studs) to measure Map Mode effectiveness.

**Outcome:** PARTIAL — skill showed structural advantages but visual quality
was inferior overall; no-skill produced more Roblox-appropriate aesthetics.

**Objects tested:**

| Build | Parts | Sub-folders | CSG | Winner aspect |
|-------|-------|-------------|-----|---------------|
| WithSkill | 400 | 8 (organized) | 0 (stone lantern had CSG from prior session) | Structure, Torii, Bridge detail |
| WithoutSkill | 368 | N/A | 0 | Overall aesthetics, creative variety |

**User visual assessment (from screenshots):**
- WithSkill: Torii gate + bridge are well-crafted, but pine/bamboo are rough
  ("Lost in the Middle"). Material choices (Sandstone/Slate on large surfaces)
  create GModっぽい dated look. Color palette too muted.
- WithoutSkill: Block-style cube trees feel more Roblox-appropriate. Cultural
  elements richer (karesansui, tsukubai, cherry blossoms, azaleas). Some
  overlap issues but overall resolution/aesthetic is better.

**Key findings:**

- Map Mode "build by area" causes Lost in the Middle: mid-sequence props
  (pine, bamboo) get less attention than first (ground, pond) and last
  (atmosphere) areas. Exemplar-then-clone pattern needed.
  (Process - RED - HIGH)
- Sandstone/Slate/Marble on surfaces >20 studs creates tiling repetition
  that looks dated (GMod-like). SmoothPlastic with color variation is
  Roblox-appropriate at large scale.
  (Materials - RED - HIGH)
- Skill's pre-declared design plan restricts creative additions. WithoutSkill
  agent freely added karesansui, tsukubai, cherry blossoms — culturally
  richer result. Need "free addition slots" in Map Mode.
  (Process - RED - MEDIUM)
- Block-style vegetation (cube trees) matches Roblox world better than
  layered disc canopy in Map Mode scenes. Vegetation detail should match
  scene resolution, not hero prop budget.
  (Design - RED - HIGH)
- Individual object quality (Torii, bridge, stone lantern) remains clearly
  superior with skill — the advantage is concentrated in structure, not scale.
  (Design - GREEN - HIGH)
- Sub-folder organization (8 named folders) significantly better with skill.
  (Process - GREEN - HIGH)

**Skill updates made:**
- `docs/design-wisdom.md`: Added [DES-036] "Material scale rule" — large surfaces
  (>20 studs) must use SmoothPlastic/Grass, detailed materials only for <5 stud parts
- `docs/design-wisdom.md`: Added [DES-037] "Map Mode uniform quality rule" — exemplar-
  then-clone pattern, uniform quality audit (70% threshold)
- `docs/design-wisdom.md`: Added [DES-038] "Map Mode vegetation should match scene
  resolution" — block-style trees for block-style scenes
- `SKILL.md`: Map Mode steps 5-7 added (exemplar-clone, free addition slots,
  uniform quality audit)

**Open questions (LOW confidence - validate in future sessions):**
- Does the exemplar-then-clone pattern actually get followed by sub-agents,
  or do they still re-generate each instance? Test with explicit instruction.
- Would a "scene resolution declaration" at the top of Map Mode (e.g., "block-style"
  vs "detailed") help agents calibrate prop complexity automatically?
- Is the 70% uniform quality threshold the right number, or too strict/lenient?
- The skill's strength appears to be Object Mode / Hybrid 3-Phase for individual
  props. Should Map Mode be re-thought as "orchestrate multiple Object Mode builds"
  rather than a monolithic generation pass?

---

## 2026-02-26 - Skill vs No-Skill A/B Test (Fountain + Triumphal Arch, CSG focus)

**Goal:** Compare `roblox-object-builder` skill vs no-skill performance on two objects:
1. Decorative Fountain (噴水) — medium complexity, CSG donut basin
2. Triumphal Arch (凱旋門) — CSG-heavy, semicircular arch opening + oculus window

**Outcome:** PARTIAL — both builds required post-hoc correction; key gaps identified in
Phase 3 verification template and CSG arch pattern documentation.

**MCP calls (approximate):**
- Fountain/WithSkill: 5 calls (P1 skeleton → P2a/b/c → P3)
- Fountain/NoSkill: 3 calls (single-pass + verification)
- Arch/WithSkill: 5 calls (P1 → P2a CSG → P2b oculus → P2c decor → P3)
- Arch/NoSkill: 4 calls (base → CSG → decor → verify)
- Self-verification round: 2 calls each

**Corrections & retries:**
- Arch/WithSkill Phase 2a: full-circle arch → semicircle (1 redo)
- Arch/NoSkill Phase 2a: rectangular opening → semicircle (1 redo)
- Both arches: X-axis position drift discovered only via external screenshot feedback
- Both arches: residual/misplaced cutter parts required cleanup

**Key findings:**

- Semicircular arch CSG requires cylinder center at spring line, NOT spring line + radius;
  placing at spring line + radius produces full circle opening
  (CSG - RED - HIGH)
- Phase 3 template missing absolute position verification; both agents drifted 130-165 studs
  on X-axis without detection (Process - RED - HIGH)
- CSG cutter parts leak into workspace when parented to workspace instead of model;
  model:GetDescendants() scan misses them (CSG - RED - HIGH)
- Cylinder rotation direction undocumented for Z-axis tunnel/arch use case;
  correct rotation is Angles(0, math.pi/2, 0) not Angles(0, 0, math.pi/2)
  (Geometry - RED - HIGH)
- Sample code in skill documentation/prompts is treated as authoritative and adopted
  without verification; mathematically wrong samples reproduce bugs reliably
  (Process - RED - HIGH)
- Skill reduced reactive error discovery (no-skill: 3 bugs discovered at runtime;
  skill: 0 runtime bugs, but inherited one from wrong sample code)
  (Process - GREEN - HIGH)
- Hybrid 3-Phase + CSG combination is viable for arch-type objects; Phase 1 skeleton
  establishes wall position for Phase 2 CSG targeting (Process - GREEN - HIGH)

**Skill updates made:**
- `docs/gotchas.md`: Extended "Cylinder long axis = X" with 3-direction rotation table
  (Y-axis upright, Z-axis tunnel, X-axis default)
- `docs/gotchas.md`: New entry "Semicircular arch: cylinder center must be at spring line"
  with two-cutter pattern and Y cross-section comment template
- `docs/gotchas.md`: New entry "CSG cutter parts leak into workspace when parented outside model"
  with fix (parent to model) and Phase 3 workspace scan snippet
- `SKILL.md`: Extended Phase 3 template with absolute position check and workspace cutter scan
  (2 new checklist items added before existing orientation audit)

**Open questions (LOW confidence - validate in future sessions):**
- What causes the consistent X-axis drift in Bumper Battle world? Is there a world-space
  offset, a Studio camera-based default placement, or an MCP execution quirk?
  → Mitigation: add a Phase 1 "test part placement + position print" step to verify
    coordinate system before committing to skeleton build.
- Do agents reliably execute the new Phase 3 absolute position check, or does the
  "don't pause in Map Mode" instruction cause them to skip it?
- Would a pre-build coordinate calibration step (place test part, verify actual vs intended
  position) prevent world offset issues across all build types?

## 2026-02-26 - Skill vs No-Skill A/B Test (Modeling Performance)

**Goal:** Compare `roblox-object-builder` skill vs no-skill (pre-trained knowledge only)
across 6 objects of increasing complexity to measure impact on build quality.

**Outcome:** PARTIAL — skill showed clear qualitative difference at 300+ part scale;
repair process exposed new failure modes around constraint compliance and fix cascades.

**Objects tested:**

| Object | Parts (no-skill / skill) | Winner |
|--------|--------------------------|--------|
| Park Bench | ~10 / ~10 | N/A (too simple to judge) |
| Hexagonal Gazebo | ~25 / ~25 | Skill (Cylinder orientation correct) |
| Ferris Wheel | ~49 / ~39 | Skill (fewer parts, cleaner) |
| Ancient Temple Ruins | ~18 / ~18 | Skill (relative CFrame math explicit) |
| Stone Arch Bridge | ~60 / ~50 | Skill (autonomous CSG selection) |
| Pirate Ship | 321 / 391→416 | Contested (skill: more detail; both: ~30+ orientation errors) |

**Key findings:**

- Skill reduces fundamental orientation errors (masts lying flat, cannons facing wrong
  direction) but does NOT eliminate subtle angle errors at 300+ part scale
  (Process - RED - MEDIUM)
- Error "quality" differs: no-skill = structural collapses; skill = subtle axis plane
  confusion on rigging/sails (Geometry - RED - HIGH)
- Flat sail panels (Size.thin × H × W) default to Y-Z plane facing — need explicit
  CFrame.Angles(0, math.pi/2, 0) when sail must face bow/stern (Geometry - RED - HIGH)
- CFrame.lookAt for rope parts aligns -Z axis; Block long dim (Y) needs pi/2 correction
  (Geometry - RED - HIGH)
- Fix cascade: correcting Size.Y of a rope accidentally left Size.Z=35, creating a
  "flying plank" — every fix needs before/after property print verification
  (Process - RED - HIGH)
- Agent violated "do not add parts" constraint when it judged quality required it;
  on challenge, honestly admitted prioritizing output quality over user constraint
  (Process - RED - HIGH)
- Agent cannot visually verify orientation without user-provided screenshots or
  explicit part name callouts — self-reported "fixed" ≠ visually correct
  (Process - RED - HIGH)
- Prompt design matters: giving detailed specs (sizes, CFrame formulas) to both agents
  collapsed the difference between skill/no-skill — user correctly identified and corrected
  this mid-session (Process - GREEN - HIGH)

**Skill updates made:**
- `docs/gotchas.md`: Added "Flat panel default orientation is Y-Z plane" (sail/window/board)
- `docs/gotchas.md`: Added "CFrame.lookAt axis confusion for rope/beam parts" + helper function
- `docs/gotchas.md`: Added "Fix cascade introduces new bugs" under new "Repair & Iteration" section
- `SKILL.md`: Added "Constraint compliance: cannot meet → ask, never silently break" to Critical Gotchas

**Open questions (LOW confidence - validate in future sessions):**
- Does Hybrid 3-Phase scale to 300+ part builds if subsystem anchors are used per
  major assembly (hull / masts / rigging / sails)? Test with explicit subsystem Phase 1.
- Does providing a ship-specific orientation reference table (like the desk reference)
  reduce sail/rigging orientation errors? Add and test.
- Would a "visual verification checklist" (print LookVector of all Sail_*, Rig_*,
  Mast_* parts) allow the agent to self-catch orientation errors without user screenshots?

## 2026-02-26 - Build Architecture A/B Test (OneShot vs Stepwise vs Hybrid)

**Goal:** Systematically compare `run_code` call patterns (OneShot, Stepwise, Hybrid)
across multiple subjects (car, park, PC desk) to determine optimal build architecture.
5 rounds of testing with user scoring.

**Outcome:** SUCCESS — Hybrid 3-Phase identified as optimal pattern

**Subjects tested:**
- Round 1: Block-style car (simple, ~8-15 parts)
- Round 2: Small park with fountain/benches/trees (~64-83 parts)
- Round 3: PC desk setup v1 (~99-147 parts)
- Round 4: PC desk setup v2, 3 approaches (~82-164 parts)
- Round 5: PC desk setup v3, 3 improved approaches (~82-164 parts)

**Key findings:**

- Hybrid 3-Phase (skeleton → detail → verify) is the only approach that achieved
  zero orientation errors across all test rounds (Process - GREEN - HIGH)
- OneShot produces best spatial coherence (4.75/5) but shallowest detail (3/5)
  due to single-call token constraints (Design - GREEN - HIGH)
- Stepwise produces deepest detail (3.8/5) but worst spatial coherence (3.75/5)
  due to coordinate drift between calls (Geometry - RED - HIGH)
- Orientation errors (keyboard/mouse facing wrong) occur in ~80% of OneShot and
  Stepwise builds regardless of prompt-level mitigations (Geometry - RED - HIGH)
- Injecting orientation comments/constants into OneShot code does NOT fix orientation
  errors — structural fix (CFrame inheritance) required (Process - RED - HIGH)
- Stepwise coordinate drift is caused by re-declaring base coords from memory;
  reading actual CFrames via FindFirstChild eliminates drift (Geometry - RED - HIGH)
- Surface-sibling overlap (desk items clipping each other) occurs even in Hybrid
  when Phase 1 anchor spacing is too tight (Geometry - RED - MEDIUM)

**User scoring summary (Round 4, 5-point scale):**

| Category | OneShot | Stepwise | Hybrid |
|----------|---------|----------|--------|
| Spatial coherence | 4.75 | 3.75 | 4.38 |
| Orientation | 3.00 | 4.00 | 3.00 |
| Scale/proportion | 4.75 | 3.13 | 3.38 |
| Detail depth | 3.00 | 3.80 | 4.00 |

**User scoring (Round 5, qualitative):**
- Hybrid+Fix: "かなり良い。向き間違いゼロ。重なりは一部あるが致命的ではない"
- OneShotOrient: "Detailsが少なく簡素。向き間違いあり"
- OneShotPlus: "全体的に悪化した印象。向き間違いあり"

**Skill updates made:**
- `SKILL.md`: Added "Hybrid 3-Phase Mode" as new Build Mode with full workflow
- `docs/gotchas.md`: Added "Orientation errors on multi-component props" (structural fix)
- `docs/gotchas.md`: Added "Stepwise coordinate drift causes overlap and scale distortion"
- `docs/gotchas.md`: Added "Surface-sibling overlap on shared planes"
- `docs/design-wisdom.md`: Added "Build approach affects spatial quality vs detail depth" with scoring table

**Open questions (LOW confidence - validate in future sessions):**
- Does the Hybrid pattern scale to 500+ part builds (full lobbies/maps)?
- Should Phase 3 overlap detection auto-nudge parts, or just report for manual fix?
- Is the orientation reference table useful as a Phase 1 code comment even if it
  doesn't fix OneShot alone? (may reinforce correct skeleton placement)
- How does Hybrid perform with CSG-heavy builds (arches, rounded platforms)?

## 2026-02-26 - Primitive Bias Feedback (Sphere vs Block)

**Goal:** Reflect user feedback that default Roblox decorative style should feel
"studs-built" and avoid unnecessary sphere-heavy compositions.

**Outcome:** SUCCESS (design/process policy updated)

**Key findings:**
- Current builder tendency can drift toward sphere-heavy props when style is unspecified (Design - RED - HIGH)
- Block-first decomposition better matches expected Roblox visual language (Design - GREEN - HIGH)
- Sphere remains valid as accent or when user explicitly requests rounded style (Process - GREEN - HIGH)

**Skill updates made:**
- `roblox-object-builder/SKILL.md`: Added default primitive selection policy (Block-first, Sphere accent-only)
- `roblox-object-builder/docs/design-wisdom.md`: Added "Block-first silhouette rule" with actionable decomposition order

**Open questions:**
- Should the build verifier include an automatic "sphere ratio" check for hero props?

## 2026-02-26 - PastelStudsPark (Detail Retrofit)

**Goal:** RobloxらしいStudsスタイルのパステル公園を、近景でも判読できる装飾品質まで改善する（木・ベンチ・噴水・花・アーチ）。

**Outcome:** PARTIAL (位置/スケールは解消、装飾の可読性と表現密度で追加改善が必要)

**MCP calls:** 8 (initial build -> geometry fix attempt -> bench/tree/fountain checks -> detail rebuild -> bench rebuild)

**User-validated checks:**
- Positioning: 問題なし（修正後）
- Lighting: 問題なし
- Scale: 問題なし
- Remaining readability concerns: 噴水・花・アーチ
- Process concern: CSGを避けた印象（実質CSGなし）

**Key findings:**

- Geometry fixes worked once explicit grounding/rebuild was used (Geometry - GREEN - HIGH)
- Style drift occurred because no pre-build style reference sheet was defined (Process - RED - HIGH)
- Decorative props were under-detailed despite correct placement (Design - RED - HIGH)
- CSG usage guide existed in docs but was not enforced in completion gate (Process - RED - HIGH)
- Pastel palette was technically valid but visually flat due to weak contrast anchors (Materials - RED - MEDIUM)

**Skill updates made:**

- `SKILL.md`: Map Mode now requires a pre-build style reference sheet for style-heavy requests
- `SKILL.md`: Added "Post-Build Readability & CSG Gate" (silhouette check + detail budget + CSG quota)
- `docs/design-wisdom.md`: Added style reference sheet pattern and readability-first detail budget
- `docs/design-wisdom.md`: Added explicit arch recognizability rule

**Open questions:**

- Should park scenes require a hard CSG minimum (e.g. >=2 CSG features) instead of "at least one"?
- Should a dedicated `reference.md` template be added to the skill package for repeatable style briefing?

---

## 2026-02-26 - Sci-Fi Arch Gate

**Goal:** CSGを含むSci-Fiスタイルのアーチゲート（柱2本 + クロスバー + アーチ穴あけ + Neonアクセント）

**Outcome:** PARTIAL (修正1回で完成)

**MCP calls:** 4 (base shapes -> CSG subtract -> neon accents -> UsePartColor fix)

**Key findings:**

- SubtractAsync result inherits cutter color (UsePartColor=false default) (CSG - RED - HIGH)
- Neon surface offset formula works correctly (wallThickness/2 + neonThickness/2 + 0.05) (Geometry - GREEN - HIGH)
- CSG subtract with +4 stud cutter overlap produces clean mesh (CSG - GREEN - HIGH)
- Base shape positioning (center-based) correct on first attempt (Geometry - GREEN - HIGH)

**Skill updates made:**

- `docs/gotchas.md`: Added "SubtractAsync preserves cutter color on cut surfaces" entry
- `SKILL.md`: Added "CSG result inherits cutter color" to Critical Gotchas

**Open questions:**

- (none this session)

---

## 2026-02-26 - PastelPark (3rd attempt)

**Goal:** Studs-style park (120x120 studs) with pastel colors - fountain, 6 trees,
4 benches, flower beds, lamp posts, entrance gate, bushes, stepping stones. 414 parts.

**Outcome:** PARTIAL -> Fixed post-build (4 corrections needed)

**What worked:**
- Y-stack planning for fountain - water Y correct on first try (session 2 fix effective)
- Sub-folder hierarchy - 10 named folders (session 1 fix effective)
- Flower 3-shape vocabulary (stem + petal disc + center sphere) - recognizable
- SmoothPlastic water surface - no Neon white-out on water itself
- Trees (trunk + root flare + 3-sphere canopy + top accent) - good shape
- Diagonal paths for anti-square layout

**What failed:**
- Color palette: all surfaces near-white (RGB 200-255 range) -> white-out despite
  correct Bloom/Brightness settings. Root cause: no minimum saturation rule.
  Fixed by darkening all surfaces 40-60 RGB points.
- Path length: 50 studs on 120 stud ground (41%) - should be >= 90%. Simple arithmetic oversight.
- Bench orientation: LookVector interpreted as person-facing direction, but it's actually
  backrest direction. First fix attempt reversed the 2 correct benches, making all 4 wrong.
  Second fix (rotate all 4 by 180 deg) succeeded.
- Vector3 concat error in diagnostic print (same class as boolean concat)

**Validated colors (post-fix, user approved with caveat "green slightly too dark"):**
```
Ground:          RGB(140, 195, 140)  -- user preferred yellow-green shift
Plaza:           RGB(170, 195, 225)  -- good soft blue
Paths:           RGB(225, 200, 160)  -- warm golden cream
Basin/column:    RGB(155, 190, 220) / RGB(220, 155, 180)
Brightness:      1.1
Bloom:           threshold 0.96, intensity 0.25
```

**Key findings:**

- Near-white SmoothPlastic (RGB > 225) causes bloom-like white-out even without Neon (Materials - RED - HIGH)
- LookVector = backrest direction for seated furniture; person faces -LookVector (Geometry - RED - HIGH)
- Path length must be computed relative to ground size, not arbitrary (Geometry - RED - HIGH)
- Vector3 concat error in MCP print - same as boolean, need tostring() (Gotcha - RED - HIGH)
- Previous retrospective's avoidance-heavy rules created fear-cascade overcorrection (Process - RED - MEDIUM)

**Skill updates made:**

- `design-wisdom.md`: Added "Pastel color saturation floor" with proven RGB palette
- `design-wisdom.md`: Updated pastel lighting preset (Brightness 1.0-1.2, Bloom thr 0.95+)
- `design-wisdom.md`: Added "Path length must match ground size" rule
- `gotchas.md`: Added "LookVector = backrest direction for seated furniture"
- `gotchas.md`: Added "Vector3 values in print() cause concat errors"
- `SKILL.md`: Added "Post-Build Geometric Sanity Check" checklist
- `SKILL.md`: Added "Retrospective Rule Quality" - pair Don't with Do

**Meta-analysis (3 sessions accumulated):**

Recurring domains: Geometry (3/3 sessions), Process (3/3), Materials (2/3).
Geometry issues are always "didn't verify the math" - the sanity check should help.
Process issues evolve: flat folders -> missing Y-plan -> fear cascade.
The skill docs are becoming comprehensive but need balance between Do and Don't.

**Open questions (LOW confidence - validate in future sessions):**

- Is the "proven palette" above truly good, or just "acceptable after fixing worse"?
  Need a clean build using these colors from the start to validate.
- Does the geometric sanity check actually get executed during builds, or does
  the agent skip it under Map Mode's "don't pause every phase" instruction?

---

## 2026-02-26 - PastelPark (2nd attempt)

**Goal:** Roblox Studs-style pastel park (dia 110 studs) - fountain with CSG basin,
10 trees, 4 benches, flowers, lamp posts, hedges. 252 parts total.

**Outcome:** FAILURE (fountain water never visible; user stopped iteration)

**What worked:**
- Foundation (grass disc + cross/diagonal paths) - clean first try
- Trees (trunk cylinder + sphere cluster foliage) - looked great
- Benches (slat seat + angled backrest + armrests) - well received
- Flowers (stem + petal disc + center sphere) - clearly recognizable
- Lamp posts with PointLight - good
- Atmosphere (Bloom threshold 0.93, ColorCorrection, DOF) - correct
- Overall pastel aesthetic - user praised it

**Key findings:**

- CSG result CFrame loses rotation when overriding with position-only CFrame (CSG - RED - HIGH)
- Size.Y returns diameter for rotated cylinders; world-height = Size.X (Geometry - RED - HIGH)
- Fountain water at basin bottom invisible from side views; must be at 75% of wall height (Design - RED - HIGH)
- No Y-stack pre-plan -> iterative fix loop that compounds rather than converges (Process - RED - HIGH)

**Skill updates made:**

- `gotchas.md`: New entry "CSG result CFrame loses rotation when overriding"
- `gotchas.md`: Added Size.X vs Size.Y corollary to "Cylinder long axis = X"
- `design-wisdom.md`: New entry "Fountain water must be near the TOP of basin walls"
- `SKILL.md`: Added "CSG result CFrame - always copy from original part" gotcha
- `SKILL.md`: Added "Tiered structures require a written Y-stack plan before coding"

**Root cause of failure (meta-level):**

Two compounding errors locked the fountain in a bad state:
1. First CSG override removed rotation -> arch shape
2. Debug used wrong Size property -> all subsequent Y fixes were based on wrong numbers
3. No Y-stack plan -> each fix was a guess, not a derivation

Neither error was caught by existing skill rules. Both are now documented.

**Open questions (LOW confidence - validate in future sessions):**

- Does `result.CFrame = outerPart.CFrame` reliably work even after
  `outerPart` has been moved to `workspace.CurrentCamera` for temp placement?
  (outerPart.CFrame would reflect Camera-relative position, not world position)
  -> Safer pattern: store `local savedCF = outerPart.CFrame` BEFORE reparenting.

---

## 2026-02-26 - PastelPark

**Goal:** Studs-style park (130x130 studs) with pastel colors - trees, benches, fountain, flower beds, lamp posts

**Outcome:** PARTIAL
- Structure and scale complete (188 parts)
- CSG fountain donut basin: SUCCESS (first try)
- Visual issues: over-exposure, unrecognizable decorations, flat hierarchy

**Key findings:**

- Bench positioning off - floated/misaligned relative to ground (Geometry - RED - HIGH)
- Diagonal paths don't meet cross paths at center - gap at intersections (Geometry - RED - HIGH)
- Brightness 2.0 + Bloom + large Neon water surface -> severe white-out (Materials - RED - HIGH)
- Sphere-cluster flower beds not recognizable as flowers (Design - RED - HIGH)
- All 188 parts flat in one folder - Studio Explorer unusable (Process - RED - HIGH)
- `Color3.R * 255` arithmetic error -> need integer triplet data tables (Gotcha - RED - HIGH)
- `print("label:", boolValue)` concat error -> need `tostring()` (Gotcha - RED - HIGH)

**Skill updates made:**

- `gotchas.md`: Added "Sub-folder hierarchy per object type" section
- `gotchas.md`: Added "Color3.R/G/B are 0-1 floats" entry
- `gotchas.md`: Added "Boolean values in print() cause concat errors" entry
- `design-wisdom.md`: Added "Pastel/cute" lighting preset with Brightness <= 1.4 rule
- `design-wisdom.md`: Added "Neon large surfaces cause white-out" warning
- `design-wisdom.md`: Added "Minimum shape vocabulary per decoration type" table

**What worked well:**

- CSG donut basin (SubtractAsync) succeeded first try - 2+ stud overlap rule effective
- Tree crown + blob dual-sphere pattern -> good puffiness
- Bench backrest tilt angle (math.rad(-10)) felt natural
- Pastel color selection was well-received

**Open questions (LOW confidence - validate in future sessions):**

- Does bench CFrame offset logic reliably land benches on path surfaces, or does it need per-position Y tuning?
- Is path gap caused by diagonal length math, or by CFrame rotation origin?
