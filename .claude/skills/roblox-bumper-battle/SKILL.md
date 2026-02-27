---
name: bumper-battle-design-system
description: >
  DesignSystem tokens and ResponsiveUI scaling rules for Bumper Battle.
  Use when creating or modifying UI components that need design tokens (colors, spacing,
  font sizes, radius) or responsive scaling (Dynamic Offset Scaling).

  Triggers: DesignSystem, DS.colors, DS.spacing, DS.fontSize, DS.radius, DS.font, DS.accent,
  ResponsiveUI, scaleValue, scaleUDim2, getScale, isMobile, getResponsiveWidth,
  Dynamic Offset Scaling, mobile UI size, button too small, text too small, notch overlap,
  IgnoreGuiInset, hardcoded pixel, UDim2 scaling.
---

# Bumper Battle Development Skill

Bumper Battle プロジェクト専用のアシスタントスキル。
プロジェクトの CLAUDE.md にアーキテクチャ・サービス構成・ファイルパスの詳細がある。

---

## Dynamic Offset Scaling（UIの核心設計）

このプロジェクトは `Scale`（%指定）ではなく **Dynamic Offset Scaling** を採用。
「リファレンスピクセル × ScaleFactor」でデバイス間の物理的一貫性を保つ。

- `ResponsiveUI.getScale()` → 現在のスケール倍率
- `ResponsiveUI.scaleValue(n)` → n × scale（整数に丸め）
- `ResponsiveUI.scaleUDim2(udim2)` → Offset成分をスケール
- `ResponsiveUI.isMobile()` → タッチ有効 & キーボード無効
- `ResponsiveUI.getResponsiveWidth(max, pct)` → `min(max, ScreenWidth * pct)`

---

## DesignSystem トークン（クイックリファレンス）

**全UI値はDesignSystemトークンを使う。ハードコード禁止。**

| カテゴリ | アクセサ例 | 値 |
|---------|-----------|-----|
| Colors | `DS.colors.text`, `DS.accent.primary` | Color3 |
| Spacing | `DS.spacing.md()` | Scaled number |
| Radius | `DS.radius.md` | UDim(0, 8) |
| FontSize | `DS.fontSize.lg()` | Scaled number |
| Font | `DS.font.bold` | Enum.Font |

Font sizes: xs(12) sm(14) md(18) lg(24) xl(32) xxl(48)
Spacing: xs(4) sm(8) md(16) lg(24) xl(32)

---

## よくある落とし穴

| 問題 | 原因 | 修正 |
|------|------|------|
| モバイルで文字が小さい | 生の数値 `TextSize = 14` | `DS.fontSize.md()` を使う |
| ノッチにUIが重なる | `IgnoreGuiInset = true` | `false` に変更 or padding適用 |
| モーダルが画面外 | 固定 500px | `ResponsiveUI.getResponsiveWidth(500, 0.9)` |
| ボタンが押しにくい | サイズ < 44px | 最低 `scaleValue(44)` 以上 |
