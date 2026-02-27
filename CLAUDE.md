# Roblox Dev Skills

Roblox における AI モデリング生成の品質を、SKILL / RULE / AGENT の検証・FB・改善を通じて向上させるプロジェクト。

---

## Purpose

AI (Claude) が Roblox Studio MCP で 3D オブジェクトを生成する際の品質を、**Agentic Context Engineering** で継続改善する。

SKILL 定義そのものを実験対象とし、「検証 → FB → 改善」のサイクルで磨く。

---

## A/B Test Procedure

同じお題を **SKILL あり** と **SKILL なし** の 2 サブエージェントで **並列実行** し、結果を比較する。

### Execute

2 つのサブエージェントを同時に Task tool で起動:

- **with-skill**: `roblox-object-builder` エージェント（SKILL / RULE / docs を全て参照）
- **without-skill**: `general-purpose` エージェント（SKILL なし。Roblox MCP のみ）

両者に **同一のプロンプト** を渡す。

### Compare

結果を比較する。評価観点はお題に応じて選択するが、典型例:
空間精度 / デザイン品質 / CSG 使用 / パーツ効率 / MCP リトライ回数 / プロセス品質

### Feedback

- SKILL の弱みを特定 → 該当ドキュメントを改善
- **SKILL あり側が劣っていた場合**: SKILL のルールが **過剰制約** になっていないか検証する。ルール削除も改善の一手段
- `roblox-build-retrospective` を実行して知見を構造化

改善後、再度 A/B テストで効果を確認する。

---

## SKILL 改善の原則

SKILL ドキュメントを編集する際に守るべき判断基準:

- **Litmus test**: 「全く別のオブジェクトを作る AI がこのルールから恩恵を受けるか？」— NO なら抽象度を上げる
- **過剰制約の警戒**: 情報量を増やすほど性能が上がるとは限らない。AI が自力で判断できる内容を書くと、かえって推論を阻害する
- **CLAUDE.md 自体にも適用**: ファイル構造の列挙、各 SKILL の要約、AI が読めば分かる設定情報は書かない
