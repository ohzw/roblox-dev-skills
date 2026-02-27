# Roblox React-Lua Responsive UI
Roblox UI must run on the same codebase across devices ranging from phones in portrait mode to 4K desktop monitors. This document covers device detection, scaling, safe area handling, and layout calculation using the **ResponsiveUI utility** and **useResponsive / useViewportScale hooks**.

---

## 1. Architecture Overview

```
ResponsiveUI.luau              — Pure function utility (React-independent)
  └─ hooks/useResponsive.luau  — React wrapper (auto re-renders on viewport change)
```

**ResponsiveUI**: Reads `workspace.CurrentCamera.ViewportSize` and provides stateless pure functions for device detection, scale calculation, and layout math.

**useResponsive / useViewportScale**: React hooks that watch `ViewportSize` via `GetPropertyChangedSignal` and trigger component re-renders when the viewport changes.

---

## 2. Device Detection

```lua
local ResponsiveUI = require(--[[ your/project/ResponsiveUI ]])
ResponsiveUI.deviceTier()  --> "phone" | "tablet" | "desktop" | "console"
ResponsiveUI.isLandscape() --> boolean  width > height
```

### deviceTier() Logic

```
1. GuiService.IsTenFootInterface == true  → "console"
2. isMobile() == true
   ├─ shortSide < 600px  → "phone"
   └─ shortSide >= 600px → "tablet"
3. Otherwise (PC/Mac)    → "desktop"  (regardless of window size)
```

> **Note**: Desktop always returns `"desktop"` regardless of resolution. A 1366px laptop and a 4K monitor get the same tier. Width-based fine-tuning is handled inside `getScale()`.

---

## 3. Scale Factor

`getScale()` is the core of the responsive system. It uses phone portrait as the **1.0 baseline** and returns a multiplier for each device context.

```lua
ResponsiveUI.getScale() --> number  (0.55 – 1.0)
```

| Device | Orientation | scale |
|--------|------------|-------|
| Phone | Portrait | **1.0** (baseline) |
| Phone | Portrait (tiny <350px) | 0.9 |
| Phone | Landscape | 0.55–0.85 (dynamic, based on height ratio) |
| Tablet | Portrait | 0.95 |
| Tablet | Landscape | 0.9 |
| Desktop | Width >1920px | 0.85 |
| Desktop | Width >1280px | 0.9 |
| Desktop | Width ≤1280px | 0.95 |
| Console | — | 0.8 |
**Phone landscape calculation:**
```lua
-- shortSide ≈ 393px (iPhone 14 landscape height)
ratio = shortSide / 844         -- MOBILE_BASE_HEIGHT = 844 (iPhone 14 portrait)
scale = clamp(ratio + 0.18, 0.55, 0.85)
-- Example: 393/844 + 0.18 ≈ 0.65
```

---

## 4. Core Scaling Functions

### 4-1. scaleValue — Number Scaling (most common)

```lua
-- For font sizes, padding, margins, etc.
ResponsiveUI.scaleValue(value: number): number
-- → math.round(value * getScale())
```

```lua
TextSize = ResponsiveUI.scaleValue(24)  -- phone portrait: 24, phone landscape: 16, desktop: 22
Size = UDim2.fromOffset(
    ResponsiveUI.scaleValue(200),
    ResponsiveUI.scaleValue(50)
)
```

### 4-2. scaleUDim2 — UDim2 Offset Scaling

```lua
-- Scales only the offset component (Scale component is unchanged)
ResponsiveUI.scaleUDim2(udim2: UDim2): UDim2
```

```lua
Size = ResponsiveUI.scaleUDim2(UDim2.new(0, 160, 0, 50))
-- → UDim2.new(0, 160*scale, 0, 50*scale)
```

### 4-3. scaleValues — Batch Scaling

```lua
-- Scales all number and UDim2 values in a table
ResponsiveUI.scaleValues(values: { [string]: any }): { [string]: any }
```

```lua
local dims = ResponsiveUI.scaleValues({
    padding = 12,
    iconSize = 28,
    headerHeight = UDim2.new(1, 0, 0, 48),
})
-- dims.padding, dims.iconSize, dims.headerHeight are all scaled
```

---

## 5. useResponsive / useViewportScale Hooks

### 5-1. useViewportScale — Lightweight (scale only)

```lua
local useViewportScale = require(--[[ your/hooks/useResponsive ]]).useViewportScale
    local _scale = useViewportScale()  -- triggers re-render on viewport change
    local btnSize = ResponsiveUI.scaleValue(100)
        Size = UDim2.fromOffset(btnSize, btnSize),
    })
end
```

> You don't need to use `_scale` directly. Calling the hook is enough to ensure re-renders on viewport changes.

### 5-2. useResponsive — Full State (tier, orientation, safeInsets)

```lua
local useResponsive = require(--[[ your/hooks/useResponsive ]]).useResponsive
    scale: number,
    deviceTier: "phone" | "tablet" | "desktop" | "console",
    isLandscape: boolean,
    isMobile: boolean,
    viewportSize: Vector2,
    safeInsets: { top: number, bottom: number, left: number, right: number },
}
local function AdaptivePanel(props)
    local responsive = useResponsive()
        then ResponsiveUI.getResponsiveWidth(400, 0.95)  -- 95% of screen width
        else ResponsiveUI.getResponsiveWidth(480, 0.6)   -- 60% of screen width

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(panelWidth, ResponsiveUI.scaleValue(300)),
        -- Position accounts for safe area insets
        Position = UDim2.fromOffset(
            responsive.safeInsets.left,
            responsive.safeInsets.top
        ),
    })
end
```

### Which Hook to Use

| Situation | Recommended |
|-----------|-------------|
| Only need scale for sizing/positioning | `useViewportScale` |
| Need orientation, tier, or safeInsets | `useResponsive` |
| Outside React (event handlers, etc.) | Call `ResponsiveUI.*` directly |

---

## 6. UDim2.fromScale vs scaleValue

```
UDim2.fromScale(0.5, 0.3)
  → 50% × 30% of the parent container.
    Best for panels that should occupy a percentage of the screen.
    Not suitable for text, icons, or elements with a physical size feel.
scaleValue(n) / scaleUDim2(...)
  → Base pixels × device scale factor.
    Use for buttons, icons, text, padding — anything where physical size matters.
```

**Decision flow:**

```
Can this element be expressed as "X% of screen"?
  YES → Prefer UDim2.fromScale (responsive by default)
  NO  → Use scaleValue / scaleUDim2 with a pixel base
         ↳ Buttons, text, icons, fixed-width panels
```

> **Anti-pattern**: Using raw pixel values. `Size = UDim2.fromOffset(100, 50)` will be oversized on phone landscape. Always route through `scaleValue`.

---

## 7. Safe Area Insets (Notch / Home Indicator)

```lua
ResponsiveUI.getSafeAreaInsets()
--> { top: number, bottom: number, left: number, right: number }
```

| Device | Portrait | Landscape |
|--------|----------|-----------|
| Phone | top: 36px, bottom: 34px | top: 36px, left/right: 44px, bottom: 21px |
| Tablet | top: 36px, bottom: 20px | top: 36px, bottom: 20px |
| Desktop / Console | all 0 | — |

**ScreenGui consideration**: Setting `ScreenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets` makes Roblox apply automatic padding. **Do not combine this with manual `getSafeAreaInsets()` padding** — it will double-apply.

```lua
-- When using manual safe area padding
local insets = ResponsiveUI.getSafeAreaInsets()
local function SafeFrame(props)
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
    }, {
        Content = React.createElement("Frame", {
            Size = UDim2.new(
                1, -(insets.left + insets.right),
                1, -(insets.top + insets.bottom)
            ),
            Position = UDim2.fromOffset(insets.left, insets.top),
        }, props.children),
    })
end
```

---

## 8. Responsive Dimensions (Overflow Prevention)

```lua
-- min(maxWidth, screenWidth * percent)
ResponsiveUI.getResponsiveWidth(maxWidth: number, percentOfScreen: number): number
-- Landscape: automatically reduces percent by * 0.88
ResponsiveUI.getResponsiveHeight(maxHeight: number, percentOfScreen: number): number
```

```lua
local function Modal(props)
    local width  = ResponsiveUI.getResponsiveWidth(480, 0.9)   -- max 480, 90% of screen
    local height = ResponsiveUI.getResponsiveHeight(600, 0.75) -- max 600, 75% of usable height

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(width, height),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
    })
end
```

---

## 9. Device-Conditional Rendering

```lua
local function GameHUD(props)
    local _scale = useViewportScale()
    local isMobile = ResponsiveUI.isMobile()
        -- Mobile: large touch button
        BumpButton = if isMobile
            then React.createElement(MobileBumpButton, { ... })
            else nil,

        -- Desktop: small cooldown indicator (mouse-centric UI)
        CooldownIndicator = if not isMobile
            then React.createElement(CooldownDisplay, { ... })
            else nil,

        -- Shared: each component handles its own scaleValue() calls internally
    })
end
```

---

## 10. Dynamic Layout Calculation (getSidebarLayout)

Pattern for auto-shrinking a vertical button stack when it doesn't fit the screen.

```lua
-- Calculates button size and gap to fit available screen height
ResponsiveUI.getSidebarLayout(
    buttonCount: number,
    startY: number?          -- optional; auto-calculated if omitted
): { buttonSize: number, gap: number, startY: number }
```

```lua
local function SidebarContainer()
    local layout = ResponsiveUI.getSidebarLayout(4)  -- 4 buttons
    local containerH = 4 * layout.buttonSize + 3 * layout.gap
    return React.createElement("Frame", {
        Size = UDim2.fromOffset(layout.buttonSize + 20, containerH),
        Position = UDim2.fromOffset(10, layout.startY),
    }, {
        Layout = React.createElement("UIListLayout", {
            Padding = UDim.new(0, layout.gap),
            FillDirection = Enum.FillDirection.Vertical,
        }),
        -- button elements...
    })
end
```

**Shrink logic**: If the default `scaleValue(60) × n` doesn't fit, button size shrinks down to `scaleValue(30)` minimum and gap shrinks to `scaleValue(4)` minimum.

---

## 11. Native Flex Layout (2024+)

`UIListLayout.HorizontalFlex` with `UIFlexItem` provides CSS Flexbox-equivalent behavior. Elements can fill remaining space without manual size calculations.

```lua
-- Horizontal flex container
React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
}, {
    Layout = React.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Wraps = true,  -- wrap to next line
    }),

    -- Fixed-size item
    Icon = React.createElement("Frame", {
        Size = UDim2.fromOffset(ResponsiveUI.scaleValue(40), ResponsiveUI.scaleValue(40)),
    }),

    -- Item that fills remaining width
    Label = React.createElement("TextLabel", {
        Size = UDim2.fromOffset(0, ResponsiveUI.scaleValue(40)),
    }, {
        Flex = React.createElement("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Fill,
        }),
    }),
})
```

> Use Flex for stretching/filling space. Use `scaleValue` to control the physical size feel of individual elements. Combining both is the best practice.

---

## 12. Anti-Patterns

| ❌ Anti-Pattern | ✅ Correct Approach |
|----------------|-------------------|
| `Size = UDim2.fromOffset(100, 50)` (raw pixels) | Use `scaleValue(100)` or `scaleUDim2(...)` |
| Calling `getScale()` once outside the component | Call `useViewportScale()` inside the component (handles viewport changes) |
| Caching `isMobile()` outside of render | Evaluate per render (handles orientation changes) |
| Using `useResponsive()` in every component | Use `useViewportScale()` when only scale is needed (lighter) |
| `ScreenGui.DeviceSafeInsets` + manual `getSafeAreaInsets()` together | Pick one approach and stick to it |
| Hardcoding device-specific values (`if isMobile then 150 else 100`) | Use `getButtonSize()` / `scaleValue()` for centralized management |

---

## 13. Quick Reference

```lua
-- Device detection
ResponsiveUI.isMobile()                   --> boolean
ResponsiveUI.deviceTier()                 --> "phone" | "tablet" | "desktop" | "console"
ResponsiveUI.isLandscape()                --> boolean
-- Scaling
ResponsiveUI.getScale()                   --> number (0.55–1.0)
ResponsiveUI.scaleValue(n)                --> math.round(n * scale)
ResponsiveUI.scaleUDim2(udim2)            --> UDim2 with offsets scaled
ResponsiveUI.scaleValues(tbl)             --> table with all number/UDim2 values scaled

-- Dimensions
ResponsiveUI.getViewportSize()            --> Vector2
ResponsiveUI.getUsableViewportHeight()    --> number (excludes topbar inset)
ResponsiveUI.getResponsiveWidth(max, %)   --> min(max, viewport.X * %)
ResponsiveUI.getResponsiveHeight(max, %)  --> min(max, usable * %) — landscape-adjusted

-- Safe area
ResponsiveUI.getSafeAreaInsets()          --> { top, bottom, left, right }
-- Device-specific sizing
ResponsiveUI.getButtonSize()              --> number (device-optimized)
ResponsiveUI.getSidebarLayout(n, startY?) --> { buttonSize, gap, startY }
-- React hooks
local { useResponsive, useViewportScale } = require(--[[ hooks/useResponsive ]])
useViewportScale()  --> number          (scale only, re-renders on viewport change)
useResponsive()     --> ResponsiveState (full state, re-renders on viewport change)
```
