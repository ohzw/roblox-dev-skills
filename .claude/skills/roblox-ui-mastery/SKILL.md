---
name: roblox-ui-mastery
description: >
  Advanced Roblox UI engineering with React-Lua. Use when creating, modifying,
  or debugging any React-Lua UI component for Roblox games.

  Triggers: React-Lua, Roact, UI component, createElement, useState, useEffect,
  useSpring, Binding, animation, tween, spring, modal, panel, selector, tooltip,
  dropdown, tab, toast, notification, cooldown display, health bar, leaderboard,
  inventory UI, shop UI, HUD, overlay, popup, fade, slide, bounce, glow effect,
  shadow effect, gradient, responsive layout, mobile UI, gamepad UI,
  DesignSystem, tokens, theme, UI performance, memo, virtual scroll,
  Context API, useReducer, custom hook, BillboardGui, SurfaceGui, ViewportFrame,
  EditableImage, UIListLayout, UIGridLayout, UIFlexItem, UIDragDetector, Path2D,
  RichText, ScreenGui, CanvasGroup, UIStroke, UIGradient, UICorner.

  Tech stack: jsdotlua/react, ReactRoblox, react-spring (chriscerie/react-spring),
  Luau --!strict, Rojo, Wally.
metadata:
  internal: true
---

# Roblox UI Mastery Skill

React-Lua による本番品質の Roblox UI コンポーネント構築スキル。

---

## Core Rules

1. **`--!strict` 必須** — 全ファイル先頭に記載。関数引数・戻り値に型注釈。`export type` でProps定義
2. **Binding = アニメーション、State = ロジック** — 毎フレーム変化する視覚値は Binding（再レンダーなし）、構造に影響する値は State
3. **DesignSystem トークン使用** — 色・スペーシング・フォントサイズ・角丸をハードコードしない
4. **ResponsiveUI で全サイズ指定** — 生のピクセル値禁止。`scaleValue()` / `scaleUDim2()` を通す
5. **useEffect は必ず cleanup** — 接続・Tween・spawn したタスクは return 関数で切断
6. **React.memo でリストアイテム** — ループ内コンポーネントは必ず memo でラップ
7. **useCallback でイベントハンドラ** — memo された子に渡すコールバックは useCallback
8. **実装前に制限を確認** — `docs/roblox-ui-limitations.md` を読んでから着手

---

## Binding vs State 判断

```
値が毎秒1回以上変化する?
├── YES → 純粋に視覚的（位置/サイズ/透明度）?
│   ├── YES → Binding + Heartbeat/Tween
│   └── NO  → State（throttle検討）
└── NO  → State
```

---

## Reference Docs

実装前に該当 doc を **Read** すること。推測で実装しない。

| Doc | いつ読む |
|-----|---------|
| `docs/react-lua-animation.md` | アニメーション・トランジション |
| `docs/react-lua-state-management.md` | State > 2フィールド、共有State |
| `docs/react-lua-custom-hooks.md` | 再利用ロジック、Robloxシグナル統合 |
| `docs/react-lua-component-patterns.md` | 複合コンポーネント、Portal、Render Props |
| `docs/react-lua-performance.md` | リスト > 20件、頻繁な更新、ジャンク |
| `docs/roblox-ui-limitations.md` | **新規UI作業前に必ずスキム** |
| `docs/roblox-ui-libraries.md` | ライブラリ評価・依存追加時 |
| `docs/roblox-ui-responsive.md` | マルチデバイスUI、サイズ・位置 |

docs パスは `.claude/skills/roblox-ui-mastery/` 配下。

---

## プラットフォーム制約（クイックリファレンス）

```
NATIVE（そのまま使える）
  UIListLayout Flex, UIDragDetector, EditableImage, Path2D,
  カスタムフォント, RichText, タッチジェスチャー, ViewportFrame

WORKAROUND（docs参照）
  ドロップシャドウ → offset dark Frame
  グロー → UIStroke + 拡大半透明Frame
  放射グラデーション → EditableImage
  仮想スクロール → 手動Visible切替

IMPOSSIBLE（試みない）
  要素別ブラー、UIGradient on ScrollingFrame/TextBox、
  放射/円錐UIGradient、React.Suspense/lazy、回転要素のClipDescendants
```
