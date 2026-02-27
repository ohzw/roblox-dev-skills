# React-Lua Advanced Component Composition Patterns

Reference document for advanced React-Lua component patterns in Roblox. All examples use `--!strict` and proper Luau type annotations. No JSX — only `React.createElement`.

---

## Pattern Selection Guide

| Pattern | Use When | Avoid When |
| :--- | :--- | :--- |
| **Compound Component** | Multiple sub-components share implicit state (Tabs, Accordion, Menu) | Simple parent/child with explicit props is clearer |
| **Slot Pattern** | Component has named regions (header/body/footer) that callers customize | All content is uniform — just use a list |
| **Render Props** | Caller needs injected runtime state (hover, focus, drag) to render custom UI | A hook can expose the same state more cleanly |
| **Portal** | UI must escape its ScreenGui (toasts, overlays, tooltips needing different ZIndex) | The element can live in the same ScreenGui hierarchy |
| **usePortalTarget** | Portal target ScreenGui must be created/found dynamically | Target is a known static instance |
| **HOC** | Wrapping legacy components you can't modify; code-sharing across class-style modules | **Prefer hooks.** HOC is a legacy pattern — use hooks for new code |
| **forwardRef** | Parent needs direct access to the underlying Roblox Instance (focus, measure, animate) | You can pass a callback prop instead |
| **Fragment** | Grouping siblings without adding an extra Frame to the hierarchy | You actually need a container Frame for layout |
| **Stable Keys** | Rendering dynamic lists from arrays/tables | Static, never-reordered children (keys still required but order doesn't matter) |

---

## 1. Compound Component

### Description
Multiple components share implicit state through a React Context. The root component owns the state; sub-components consume it without prop-drilling. Callers compose the pieces declaratively.

**Classic example:** `Tab.Root` / `Tab.List` / `Tab.Panel`

### When to use
- A UI widget has multiple cooperating sub-parts (Tabs, Accordion, Dropdown, Stepper).
- You want callers to control composition order without exposing internal state.

### When NOT to use
- The component is simple enough that a single `activeTab` prop suffices.
- Sub-components are never used independently — just use one component with slots.

### Full Implementation

```lua
--!strict
-- Tab.luau — Compound Component: Tab.Root / Tab.List / Tab.Panel
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local DS = require(ReplicatedStorage.modules.ui.theme.DesignSystem)
local ResponsiveUI = require(ReplicatedStorage.modules.ui.ResponsiveUI)

-- ── Types ──────────────────────────────────────────────────────────────────

export type TabContextValue = {
    activeTab: string,
    setActiveTab: (tab: string) -> (),
}

export type TabRootProps = {
    defaultTab: string,
    children: { [string]: React.ReactElement },
}

export type TabListProps = {
    tabs: { string },
    children: { [string]: React.ReactElement }?,
}

export type TabPanelProps = {
    tabId: string,
    children: { [string]: React.ReactElement },
}

-- ── Context ────────────────────────────────────────────────────────────────

-- Context holds the active tab ID and the setter.
-- Default value is a no-op sentinel; real value is provided by Tab.Root.
local TabContext = React.createContext({
    activeTab = "",
    setActiveTab = function(_tab: string) end,
} :: TabContextValue)

-- ── Tab.Root ───────────────────────────────────────────────────────────────

local function TabRoot(props: TabRootProps): React.ReactElement
    local activeTab, setActiveTab = React.useState(props.defaultTab)

    local contextValue: TabContextValue = {
        activeTab = activeTab,
        setActiveTab = setActiveTab,
    }

    return React.createElement(
        TabContext.Provider,
        { value = contextValue },
        -- Root is a transparent container; layout is the caller's responsibility.
        React.createElement("Frame", {
            Name = "TabRoot",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, props.children)
    )
end

-- ── Tab.List ───────────────────────────────────────────────────────────────

local function TabList(props: TabListProps): React.ReactElement
    local ctx = React.useContext(TabContext)

    -- Build tab buttons from the `tabs` array.
    local buttons: { [string]: React.ReactElement } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, ResponsiveUI.scaleValue(4)),
        }),
    }

    for i, tabId in ipairs(props.tabs) do
        local isActive = ctx.activeTab == tabId
        buttons["Tab_" .. tabId] = React.createElement("TextButton", {
            Name = "Tab_" .. tabId,
            LayoutOrder = i,
            Size = UDim2.new(0, ResponsiveUI.scaleValue(100), 1, 0),
            BackgroundColor3 = if isActive then DS.accent.primary else DS.colors.bgElevated,
            BackgroundTransparency = if isActive then 0 else 0.3,
            BorderSizePixel = 0,
            Text = tabId,
            TextColor3 = DS.colors.text,
            TextSize = DS.fontSize.md(),
            Font = if isActive then DS.font.bold else DS.font.default,
            [React.Event.Activated] = function()
                ctx.setActiveTab(tabId)
            end,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = DS.radius.md }),
        })
    end

    return React.createElement("Frame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 0, ResponsiveUI.scaleValue(40)),
        BackgroundTransparency = 1,
    }, buttons)
end

-- ── Tab.Panel ──────────────────────────────────────────────────────────────

local function TabPanel(props: TabPanelProps): React.ReactElement?
    local ctx = React.useContext(TabContext)

    -- Only render when this panel's tab is active.
    if ctx.activeTab ~= props.tabId then
        return nil
    end

    return React.createElement("Frame", {
        Name = "TabPanel_" .. props.tabId,
        Size = UDim2.new(1, 0, 1, -ResponsiveUI.scaleValue(44)),
        Position = UDim2.new(0, 0, 0, ResponsiveUI.scaleValue(44)),
        BackgroundTransparency = 1,
    }, props.children)
end

-- ── Public API ─────────────────────────────────────────────────────────────

local Tab = {
    Root  = TabRoot,
    List  = TabList,
    Panel = TabPanel,
}

return Tab

-- ── Usage Example ──────────────────────────────────────────────────────────
--[[
local Tab = require(ReplicatedStorage.modules.ui.Tab)

local function SettingsScreen(): React.ReactElement
    return React.createElement(Tab.Root, { defaultTab = "Audio" }, {
        List = React.createElement(Tab.List, { tabs = { "Audio", "Graphics", "Controls" } }),
        AudioPanel = React.createElement(Tab.Panel, { tabId = "Audio" }, {
            Content = React.createElement("TextLabel", {
                Text = "Audio Settings",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                TextColor3 = DS.colors.text,
                TextSize = DS.fontSize.lg(),
                Font = DS.font.bold,
            }),
        }),
        GraphicsPanel = React.createElement(Tab.Panel, { tabId = "Graphics" }, {
            Content = React.createElement("TextLabel", {
                Text = "Graphics Settings",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                TextColor3 = DS.colors.text,
                TextSize = DS.fontSize.lg(),
                Font = DS.font.bold,
            }),
        }),
        ControlsPanel = React.createElement(Tab.Panel, { tabId = "Controls" }, {
            Content = React.createElement("TextLabel", {
                Text = "Controls Settings",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                TextColor3 = DS.colors.text,
                TextSize = DS.fontSize.lg(),
                Font = DS.font.bold,
            }),
        }),
    })
end
]]
```

---

## 2. Slot Pattern

### Description
A component defines named regions (slots) that callers fill with arbitrary `ReactElement` children. The component controls layout and chrome; callers control content. Props accept optional `React.ReactElement` values for each slot.

### When to use
- A Card/Modal/Panel has a fixed structure (header, body, footer) but variable content.
- You want callers to inject any element — not just text strings.

### When NOT to use
- Slots are always the same content — just hardcode them.
- You need more than 3–4 slots; consider Compound Components instead.

### Full Implementation

```lua
--!strict
-- Card.luau — Slot Pattern: header / body / footer slots
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local DS = require(ReplicatedStorage.modules.ui.theme.DesignSystem)
local ResponsiveUI = require(ReplicatedStorage.modules.ui.ResponsiveUI)

-- ── Types ──────────────────────────────────────────────────────────────────

export type CardProps = {
    -- Slot props: callers pass pre-built ReactElements.
    -- All slots are optional; omitted slots are simply not rendered.
    header: React.ReactElement?,
    body: React.ReactElement?,
    footer: React.ReactElement?,
    -- Layout
    width: number?,
    height: number?,
    position: UDim2?,
    anchorPoint: Vector2?,
}

-- ── Component ──────────────────────────────────────────────────────────────

local HEADER_HEIGHT = 48
local FOOTER_HEIGHT = 48

local function Card(props: CardProps): React.ReactElement
    local width  = props.width  or ResponsiveUI.scaleValue(360)
    local height = props.height or ResponsiveUI.scaleValue(300)

    -- Calculate body height based on which slots are present.
    local headerH = if props.header then ResponsiveUI.scaleValue(HEADER_HEIGHT) else 0
    local footerH = if props.footer then ResponsiveUI.scaleValue(FOOTER_HEIGHT) else 0
    local bodyH   = height - headerH - footerH

    -- Build children table; only include slots that were provided.
    local children: { [string]: React.ReactElement } = {
        Corner = React.createElement("UICorner", { CornerRadius = DS.radius.lg }),
        Stroke = React.createElement("UIStroke", {
            Color = DS.colors.border,
            Thickness = 1,
            Transparency = 0.5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
    }

    -- Header slot
    if props.header then
        children.Header = React.createElement("Frame", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, headerH),
            Position = UDim2.fromOffset(0, 0),
            BackgroundColor3 = DS.colors.bgElevated,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, {
            -- Caller's header element fills the slot frame.
            Content = props.header,
            Corner = React.createElement("UICorner", { CornerRadius = DS.radius.lg }),
        })
    end

    -- Body slot
    if props.body then
        children.Body = React.createElement("Frame", {
            Name = "Body",
            Size = UDim2.new(1, 0, 0, bodyH),
            Position = UDim2.fromOffset(0, headerH),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, {
            Content = props.body,
        })
    end

    -- Footer slot
    if props.footer then
        children.Footer = React.createElement("Frame", {
            Name = "Footer",
            Size = UDim2.new(1, 0, 0, footerH),
            Position = UDim2.fromOffset(0, headerH + bodyH),
            BackgroundColor3 = DS.colors.bgElevated,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, {
            Content = props.footer,
            Corner = React.createElement("UICorner", { CornerRadius = DS.radius.lg }),
        })
    end

    return React.createElement("Frame", {
        Name = "Card",
        Size = UDim2.fromOffset(width, height),
        Position = props.position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
        BackgroundColor3 = DS.colors.bgOverlay,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
    }, children)
end

return Card

-- ── Usage Example ──────────────────────────────────────────────────────────
--[[
local Card = require(ReplicatedStorage.modules.ui.Card)

local function PlayerProfileCard(): React.ReactElement
    return React.createElement(Card, {
        width = ResponsiveUI.scaleValue(320),
        height = ResponsiveUI.scaleValue(240),

        header = React.createElement("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "Player Profile",
            TextColor3 = DS.colors.text,
            TextSize = DS.fontSize.lg(),
            Font = DS.font.bold,
        }),

        body = React.createElement("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "KOs: 42  |  Wins: 7",
            TextColor3 = DS.colors.textSecondary,
            TextSize = DS.fontSize.md(),
            Font = DS.font.default,
        }),

        -- footer is omitted — the slot simply won't render.
    })
end
]]
```

---

## 3. Render Props

### Description
A component accepts a `render` function as a prop. It calls that function with runtime state, letting the caller decide what to render. The component owns the behavior; the caller owns the appearance.

### When to use
- You need to inject runtime state (hover, focus, drag position) into caller-controlled UI.
- The injected state is complex enough that a hook alone doesn't capture the full interaction.

### When NOT to use
- A custom hook can expose the same state — **prefer hooks**. Render props add nesting and are harder to read.
- The caller always renders the same thing — just hardcode it.

### Full Implementation

```lua
--!strict
-- Hoverable.luau — Render Props: injects isHovered into caller's render function
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- ── Types ──────────────────────────────────────────────────────────────────

export type HoverableProps = {
    -- The render function receives isHovered and must return a ReactElement.
    -- It is responsible for attaching MouseEnter/MouseLeave to the root element
    -- via the injected callbacks.
    render: (
        isHovered: boolean,
        onEnter: () -> (),
        onLeave: () -> ()
    ) -> React.ReactElement,
    -- Optional: size/position for the invisible hit-detection frame.
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
}

-- ── Component ──────────────────────────────────────────────────────────────

local function Hoverable(props: HoverableProps): React.ReactElement
    local isHovered, setHovered = React.useState(false)

    local onEnter = React.useCallback(function()
        setHovered(true)
    end, {})

    local onLeave = React.useCallback(function()
        setHovered(false)
    end, {})

    -- Delegate rendering entirely to the caller.
    return props.render(isHovered, onEnter, onLeave)
end

return Hoverable

-- ── Usage Example ──────────────────────────────────────────────────────────
--[[
local Hoverable = require(ReplicatedStorage.modules.ui.Hoverable)
local DS = require(ReplicatedStorage.modules.ui.theme.DesignSystem)

local function HoverableButton(): React.ReactElement
    return React.createElement(Hoverable, {
        render = function(
            isHovered: boolean,
            onEnter: () -> (),
            onLeave: () -> ()
        ): React.ReactElement
            return React.createElement("TextButton", {
                Size = UDim2.fromOffset(160, 48),
                BackgroundColor3 = if isHovered
                    then DS.accent.primary
                    else DS.colors.bgElevated,
                Text = if isHovered then "Click me!" else "Hover me",
                TextColor3 = DS.colors.text,
                TextSize = DS.fontSize.md(),
                Font = DS.font.bold,
                BorderSizePixel = 0,
                [React.Event.MouseEnter] = onEnter,
                [React.Event.MouseLeave] = onLeave,
                [React.Event.Activated] = function()
                    print("Clicked!")
                end,
            }, {
                Corner = React.createElement("UICorner", {
                    CornerRadius = DS.radius.md,
                }),
            })
        end,
    })
end

-- NOTE: For new code, prefer a hook instead:
-- local isHovered, onEnter, onLeave = useHover()
-- This avoids the extra nesting and is easier to compose.
]]
```

---

## 4. Portal

### Description
`ReactRoblox.createPortal(element, containerInstance)` mounts a React element into a **different** Roblox Instance than the component's normal parent. The element is still part of the React tree (events, context, state all work normally), but its Roblox Instance lives elsewhere.

**Primary use case:** Toasts, overlays, and tooltips that need a higher `DisplayOrder` or a separate `ScreenGui` to avoid being clipped by parent `ClipsDescendants`.

### When to use
- UI must render above everything else (toasts, modals, tooltips).
- The element would be clipped by a parent `Frame` with `ClipsDescendants = true`.
- You need a different `ZIndexBehavior` or `DisplayOrder` than the host ScreenGui.

### When NOT to use
- The element can live in the same ScreenGui — portals add complexity.
- You just need a higher `ZIndex` — adjust `ZIndex` on the element instead.

### Full Implementation

```lua
--!strict
-- ToastPortal.luau — Portal: mounts toast notifications into a dedicated ScreenGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local DS = require(ReplicatedStorage.modules.ui.theme.DesignSystem)
local ResponsiveUI = require(ReplicatedStorage.modules.ui.ResponsiveUI)

-- ── Types ──────────────────────────────────────────────────────────────────

export type ToastProps = {
    message: string,
    color: Color3?,
    -- The ScreenGui instance to portal into.
    -- Obtain via usePortalTarget (see Pattern 5) or pass directly.
    portalTarget: ScreenGui,
}

-- ── Toast Component (rendered via portal) ─────────────────────────────────

local function ToastContent(props: { message: string, color: Color3? }): React.ReactElement
    return React.createElement("Frame", {
        Name = "Toast",
        Size = UDim2.new(0, ResponsiveUI.scaleValue(280), 0, ResponsiveUI.scaleValue(52)),
        Position = UDim2.new(0.5, 0, 0, ResponsiveUI.scaleValue(24)),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = props.color or DS.accent.success,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = DS.radius.md }),
        Label = React.createElement("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = props.message,
            TextColor3 = DS.colors.text,
            TextSize = DS.fontSize.md(),
            Font = DS.font.bold,
        }),
    })
end

-- ── ToastPortal: wraps ToastContent in a portal ───────────────────────────

local function ToastPortal(props: ToastProps): React.ReactElement
    -- createPortal(element, containerInstance)
    -- The toast renders INTO props.portalTarget (a ScreenGui),
    -- but remains part of this component's React tree.
    return ReactRoblox.createPortal(
        React.createElement(ToastContent, {
            message = props.message,
            color = props.color,
        }),
        props.portalTarget  -- Must be a valid Roblox Instance (ScreenGui, Frame, etc.)
    )
end

return ToastPortal

-- ── Usage Example ──────────────────────────────────────────────────────────
--[[
-- In your root component or a service that manages toasts:
local ToastPortal = require(ReplicatedStorage.modules.ui.ToastPortal)

-- The portalTarget ScreenGui is created once (see usePortalTarget, Pattern 5).
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "ToastLayer"
toastGui.DisplayOrder = 999          -- Above everything else
toastGui.ResetOnSpawn = false
toastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
toastGui.Parent = Players.LocalPlayer.PlayerGui

local function App(): React.ReactElement
    local showToast, setShowToast = React.useState(false)

    return React.createElement(React.Fragment, {}, {
        -- Normal UI lives in the main ScreenGui (managed by ReactRoblox.createRoot).
        MainUI = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
        }),

        -- Toast is portaled into toastGui, which has DisplayOrder = 999.
        Toast = showToast and React.createElement(ToastPortal, {
            message = "KO! +50 coins",
            color = DS.accent.success,
            portalTarget = toastGui,
        }),
    })
end
]]
```

---

## 5. usePortalTarget Hook

### Description
A custom hook that dynamically creates (or finds an existing) `ScreenGui` to use as a portal target. Cleans up the ScreenGui on unmount. Avoids creating duplicate ScreenGuis if the hook is called multiple times with the same name.

### When to use
- You need a portal target but don't want to manage ScreenGui lifecycle manually.
- Multiple components might request the same overlay layer — the hook deduplicates.

### When NOT to use
- The ScreenGui is created once at app startup and never destroyed — just create it imperatively.

### Full Implementation

```lua
--!strict
-- usePortalTarget.luau — Hook: dynamically create/find a ScreenGui for portal mounting
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)

-- ── Types ──────────────────────────────────────────────────────────────────

export type PortalTargetOptions = {
    name: string,
    displayOrder: number?,
    resetOnSpawn: boolean?,
    zIndexBehavior: Enum.ZIndexBehavior?,
}

-- ── Hook ───────────────────────────────────────────────────────────────────

--[[
    usePortalTarget(options)

    Returns a ScreenGui instance suitable for use as a ReactRoblox.createPortal target.
    - If a ScreenGui with `options.name` already exists in PlayerGui, reuses it.
    - Otherwise, creates a new one with the given options.
    - The ScreenGui is NOT destroyed on unmount (it may be shared).
      Pass `owned = true` if this hook should own and destroy the ScreenGui.

    Returns: ScreenGui? (nil on the first render frame before PlayerGui is ready)
]]
local function usePortalTarget(options: PortalTargetOptions): ScreenGui?
    local target, setTarget = React.useState(nil :: ScreenGui?)

    React.useEffect(function()
        local player = Players.LocalPlayer
        if not player then
            return function() end
        end

        local playerGui = player:WaitForChild("PlayerGui", 10) :: PlayerGui?
        if not playerGui then
            warn("[usePortalTarget] PlayerGui not found for player:", player.Name)
            return function() end
        end

        -- Reuse existing ScreenGui if present (avoids duplicates).
        local existing = playerGui:FindFirstChild(options.name)
        if existing and existing:IsA("ScreenGui") then
            setTarget(existing)
            return function() end
        end

        -- Create a new ScreenGui.
        local gui = Instance.new("ScreenGui")
        gui.Name = options.name
        gui.DisplayOrder = options.displayOrder or 500
        gui.ResetOnSpawn = if options.resetOnSpawn ~= nil then options.resetOnSpawn else false
        gui.ZIndexBehavior = options.zIndexBehavior or Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = false
        gui.Parent = playerGui

        setTarget(gui)

        -- Cleanup: only destroy if we created it.
        return function()
            if gui and gui.Parent then
                gui:Destroy()
            end
        end
    end, {})  -- Empty deps: run once on mount.

    return target
end

return usePortalTarget

-- ── Usage Example ──────────────────────────────────────────────────────────
--[[
local usePortalTarget = require(ReplicatedStorage.modules.ui.hooks.usePortalTarget)
local ToastPortal = require(ReplicatedStorage.modules.ui.ToastPortal)

local function AppWithToasts(): React.ReactElement
    -- Hook creates (or finds) "ToastLayer" ScreenGui with DisplayOrder 999.
    local toastTarget = usePortalTarget({
        name = "ToastLayer",
        displayOrder = 999,
    })

    local showToast, setShowToast = React.useState(false)

    return React.createElement(React.Fragment, {}, {
        MainContent = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
        }),

        -- Only render the portal once the target ScreenGui exists.
        Toast = (showToast and toastTarget ~= nil) and React.createElement(ToastPortal, {
            message = "Match starting!",
            portalTarget = toastTarget :: ScreenGui,
        }),
    })
end
]]
```

---

## 6. Higher-Order Component (HOC)

### Description
A function that takes a component and returns a new component with additional props or behavior injected. In React-Lua this is a function `(InnerComponent) -> OuterComponent`.

> ⚠️ **Legacy Pattern Warning:** HOCs are a legacy pattern inherited from React JS. In React-Lua, **prefer custom hooks** for sharing logic. HOCs are useful when wrapping components you cannot modify (e.g., third-party or generated components), or when integrating with an existing Module-Class pattern.

### When to use
- Wrapping a component you cannot modify to inject theme or responsive props.
- Code-sharing across many components when refactoring to hooks is not feasible.

### When NOT to use
- **New code:** Use a custom hook instead. Hooks compose better, are easier to test, and don't add wrapper layers to the instance tree.
- When the wrapped component is already a hook-based function component — just call the hook directly.

### Full Implementation

```lua
--!strict
-- withTheme.luau — HOC: injects DesignSystem tokens as `theme` prop
-- withResponsive.luau — HOC: injects ResponsiveState as `responsive` prop
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local DS = require(ReplicatedStorage.modules.ui.theme.DesignSystem)
local useResponsive = require(ReplicatedStorage.modules.ui.hooks.useResponsive).useResponsive

-- ── Types ──────────────────────────────────────────────────────────────────

export type ThemeProps = {
    theme: typeof(DS),
}

export type ResponsiveProps = {
    responsive: {
        scale: number,
        isMobile: boolean,
        isLandscape: boolean,
        viewportSize: Vector2,
        deviceTier: string,
        safeInsets: {
            top: number,
            bottom: number,
            left: number,
            right: number,
        },
    },
}

-- ── withTheme HOC ──────────────────────────────────────────────────────────

--[[
    withTheme(Component)
    Injects `props.theme = DS` into the wrapped component.
    The wrapped component must accept a `theme` prop.

    PREFER: calling `local DS = require(...)` directly in the component.
    Use withTheme only when you cannot modify the inner component.
]]
local function withTheme<TProps>(
    Component: (props: TProps & ThemeProps) -> React.ReactElement?
): (props: TProps) -> React.ReactElement?
    local function WrappedComponent(props: TProps): React.ReactElement?
        -- Merge theme into props. In Luau we must build a new table.
        local mergedProps = table.clone(props :: { [string]: any })
        mergedProps.theme = DS
        return Component(mergedProps :: TProps & ThemeProps)
    end

    -- Preserve display name for debugging.
    -- (React-Lua does not have displayName, but we can name the function.)
    return WrappedComponent
end

-- ── withResponsive HOC ─────────────────────────────────────────────────────

--[[
    withResponsive(Component)
    Injects `props.responsive` (ResponsiveState) into the wrapped component.
    Re-renders the wrapped component on viewport changes.

    PREFER: calling `useResponsive()` directly inside the component.
    Use withResponsive only when you cannot modify the inner component.
]]
local function withResponsive<TProps>(
    Component: (props: TProps & ResponsiveProps) -> React.ReactElement?
): (props: TProps) -> React.ReactElement?
    local function WrappedComponent(props: TProps): React.ReactElement?
        local responsive = useResponsive()
        local mergedProps = table.clone(props :: { [string]: any })
        mergedProps.responsive = responsive
        return Component(mergedProps :: TProps & ResponsiveProps)
    end

    return WrappedComponent
end

return {
    withTheme = withTheme,
    withResponsive = withResponsive,
}

-- ── Usage Example ──────────────────────────────────────────────────────────
--[[
local HOC = require(ReplicatedStorage.modules.ui.HOC)

-- A legacy component that expects theme/responsive injected (cannot be modified).
local function LegacyButton(props: { label: string } & ThemeProps & ResponsiveProps)
    return React.createElement("TextButton", {
        Size = UDim2.fromOffset(
            math.round(160 * props.responsive.scale),
            math.round(48 * props.responsive.scale)
        ),
        BackgroundColor3 = props.theme.accent.primary,
        Text = props.label,
        TextColor3 = props.theme.colors.text,
        TextSize = props.theme.fontSize.md(),
        Font = props.theme.font.bold,
        BorderSizePixel = 0,
    })
end

-- Wrap once; use the wrapped version everywhere.
local ThemedResponsiveButton = HOC.withResponsive(HOC.withTheme(LegacyButton))

-- Caller only passes `label`; theme and responsive are injected automatically.
local function MyScreen(): React.ReactElement
    return React.createElement(ThemedResponsiveButton, { label = "Start Game" })
end

-- ✅ PREFERRED alternative for new code — no HOC needed:
local function ModernButton(props: { label: string }): React.ReactElement
    local responsive = useResponsive()  -- hook directly in component
    return React.createElement("TextButton", {
        Size = UDim2.fromOffset(
            math.round(160 * responsive.scale),
            math.round(48 * responsive.scale)
        ),
        BackgroundColor3 = DS.accent.primary,
        Text = props.label,
        TextColor3 = DS.colors.text,
        TextSize = DS.fontSize.md(),
        Font = DS.font.bold,
        BorderSizePixel = 0,
    })
end
]]
```

---

## 7. forwardRef

### Description
`React.forwardRef` lets a parent component obtain a direct reference to the underlying Roblox Instance created by a child component. The child component receives the ref as a second argument alongside props.

> ⚠️ **Deprecation Note:** `React.forwardRef` may be deprecated in a future version of React-Lua (following React 19's direction). Prefer callback refs or exposing imperative handles via `React.useImperativeHandle` where possible. Use `forwardRef` when you genuinely need the raw Instance (e.g., for `TweenService`, `GuiService:Select`, or measuring bounds).

### When to use
- Parent needs to call `TweenService:Create(instance, ...)` on a child's Instance.
- Parent needs to call `GuiService:Select(instance)` for gamepad focus.
- Parent needs to measure `instance.AbsoluteSize` / `AbsolutePosition`.

### When NOT to use
- You just need to trigger an action — expose a callback prop or use a ref to a state setter.
- The child can manage its own animation/focus internally.

### Full Implementation

```lua
--!strict
-- FocusableInput.luau — forwardRef: exposes the underlying TextBox Instance to parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local DS = require(ReplicatedStorage.modules.ui.theme.DesignSystem)
local ResponsiveUI = require(ReplicatedStorage.modules.ui.ResponsiveUI)

-- ── Types ──────────────────────────────────────────────────────────────────

export type FocusableInputProps = {
    placeholder: string?,
    onTextChanged: ((text: string) -> ())?,
    size: UDim2?,
    position: UDim2?,
}

-- ── Component ──────────────────────────────────────────────────────────────

-- React.forwardRef wraps the render function.
-- The second argument `ref` is the forwarded ref from the parent.
local FocusableInput = React.forwardRef(
    function(props: FocusableInputProps, ref: React.Ref<TextBox>?): React.ReactElement
        return React.createElement("TextBox", {
            Name = "FocusableInput",
            ref = ref,  -- Attach the forwarded ref to the Roblox Instance.
            Size = props.size or UDim2.new(1, 0, 0, ResponsiveUI.scaleValue(40)),
            Position = props.position or UDim2.fromScale(0, 0),
            BackgroundColor3 = DS.colors.bgElevated,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            PlaceholderText = props.placeholder or "Type here...",
            PlaceholderColor3 = DS.colors.textDisabled,
            Text = "",
            TextColor3 = DS.colors.text,
            TextSize = DS.fontSize.md(),
            Font = DS.font.default,
            ClearTextOnFocus = false,
            [React.Change.Text] = function(instance: TextBox)
                if props.onTextChanged then
                    props.onTextChanged(instance.Text)
                end
            end,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = DS.radius.md }),
            Stroke = React.createElement("UIStroke", {
                Color = DS.colors.border,
                Thickness = 1,
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            Padding = React.createElement("UIPadding", {
                PaddingLeft = UDim.new(0, ResponsiveUI.scaleValue(8)),
                PaddingRight = UDim.new(0, ResponsiveUI.scaleValue(8)),
            }),
        })
    end
)

return FocusableInput

-- ── Usage Example ──────────────────────────────────────────────────────────
--[[
local FocusableInput = require(ReplicatedStorage.modules.ui.FocusableInput)

local function SearchBar(): React.ReactElement
    -- Create a ref to hold the TextBox Instance.
    local inputRef = React.createRef() :: React.Ref<TextBox>

    React.useEffect(function()
        -- Auto-focus the input on mount by accessing the raw Instance.
        local instance = inputRef.current
        if instance then
            instance:CaptureFocus()
        end
    end, {})

    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
    }, {
        Input = React.createElement(FocusableInput, {
            ref = inputRef,
            placeholder = "Search abilities...",
            onTextChanged = function(text: string)
                print("Searching:", text)
            end,
        }),
    })
end
]]
```

---

## 8. Fragment

### Description
`React.Fragment` groups multiple sibling elements without adding an extra Roblox Instance to the hierarchy. In React-Lua, Fragments are especially useful when a component must return multiple top-level elements (e.g., an overlay + a modal) without wrapping them in a Frame.

**Example usage:** A selector component uses `React.Fragment` to return both an overlay `TextButton` and a modal `Frame` as siblings without a wrapper Frame.

### When to use
- A component logically returns multiple siblings (overlay + modal, label + input).
- Adding a wrapper Frame would break layout (e.g., inside a `UIListLayout` container).
- You want to avoid unnecessary Instance depth.

### When NOT to use
- You actually need a container Frame for layout, background, or clipping.
- There is only one root element — Fragment adds no value.

### Full Implementation

```lua
--!strict
-- OverlayModal.luau — Fragment: overlay + modal as siblings without a wrapper Frame
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local DS = require(ReplicatedStorage.modules.ui.theme.DesignSystem)
local ResponsiveUI = require(ReplicatedStorage.modules.ui.ResponsiveUI)

-- ── Types ──────────────────────────────────────────────────────────────────

export type OverlayModalProps = {
    isOpen: boolean,
    onClose: () -> (),
    title: string,
    children: { [string]: React.ReactElement }?,
}

-- ── Component ──────────────────────────────────────────────────────────────

local function OverlayModal(props: OverlayModalProps): React.ReactElement
    -- React.Fragment groups the overlay and modal as siblings.
    -- Neither is a child of the other — both are direct children of the ScreenGui.
    -- The third argument to createElement is the children table with STRING keys.
    return React.createElement(React.Fragment, {}, {

        -- Key "Overlay": full-screen click-catcher.
        -- Rendered conditionally; when isOpen is false, this key maps to nil
        -- and React removes the Instance from the hierarchy.
        Overlay = props.isOpen and React.createElement("TextButton", {
            Name = "Overlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 100,
            [React.Event.Activated] = props.onClose,
        }) or nil,

        -- Key "Modal": the dialog itself.
        Modal = props.isOpen and React.createElement("Frame", {
            Name = "Modal",
            Size = UDim2.fromOffset(
                ResponsiveUI.getResponsiveWidth(400, 0.9),
                ResponsiveUI.getResponsiveHeight(300, 0.6)
            ),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = DS.colors.bgOverlay,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 101,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = DS.radius.lg }),

            Title = React.createElement("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, 0, 0, ResponsiveUI.scaleValue(48)),
                BackgroundTransparency = 1,
                Text = props.title,
                TextColor3 = DS.colors.text,
                TextSize = DS.fontSize.xl(),
                Font = DS.font.bold,
            }),

            Content = React.createElement("Frame", {
                Name = "Content",
                Size = UDim2.new(1, 0, 1, -ResponsiveUI.scaleValue(48)),
                Position = UDim2.fromOffset(0, ResponsiveUI.scaleValue(48)),
                BackgroundTransparency = 1,
            }, props.children),
        }) or nil,
    })
end

return OverlayModal

-- ── Usage Example ──────────────────────────────────────────────────────────
--[[
local OverlayModal = require(ReplicatedStorage.modules.ui.OverlayModal)

local function GameScreen(): React.ReactElement
    local showModal, setShowModal = React.useState(false)

    -- React.Fragment at the top level: GameHUD and OverlayModal are siblings
    -- in the ScreenGui, not nested inside each other.
    return React.createElement(React.Fragment, {}, {
        HUD = React.createElement("Frame", {
            Name = "HUD",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
        }),

        -- OverlayModal itself returns a Fragment (Overlay + Modal).
        -- React flattens nested Fragments correctly.
        Modal = React.createElement(OverlayModal, {
            isOpen = showModal,
            onClose = function() setShowModal(false) end,
            title = "Match Results",
        }, {
            Results = React.createElement("TextLabel", {
                Text = "You won! +100 coins",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                TextColor3 = DS.accent.success,
                TextSize = DS.fontSize.lg(),
                Font = DS.font.bold,
            }),
        }),
    })
end
]]
```

---

## 9. Children Key Naming

### Description
In React-Lua, children are passed as a **table with string keys**, not as an array. The key is used by React's reconciler to identify which Instance corresponds to which element across re-renders. **Stable, unique string keys are critical for correct reconciliation.**

**Why it matters:**
- Unstable keys (e.g., numeric indices from `tostring(i)`) cause React to destroy and recreate Instances on every re-render, losing focus, animation state, and causing visual flicker.
- Duplicate keys within the same children table cause one element to silently overwrite another.
- `nil` values in the children table are valid — React skips them. This is the idiomatic way to conditionally render children.

### Rules
1. **Use stable, data-derived keys** — e.g., `"Item_" .. item.id` or `"Tab_" .. tabName`.
2. **Never use raw numeric indices** as keys for dynamic lists — use `"Row_" .. tostring(rowId)`.
3. **Keys must be unique within the same children table** — siblings only, not globally.
4. **Static children** (UICorner, UIListLayout, etc.) use descriptive names: `"Corner"`, `"Layout"`, `"Stroke"`.
5. **Conditional children** map the key to `nil` or `false` to remove the Instance.

### Full Implementation

```lua
--!strict
-- KeyNamingExamples.luau — Demonstrates correct and incorrect key naming
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local DS = require(ReplicatedStorage.modules.ui.theme.DesignSystem)
local ResponsiveUI = require(ReplicatedStorage.modules.ui.ResponsiveUI)

-- ── Types ──────────────────────────────────────────────────────────────────

export type PlayerEntry = {
    id: number,
    name: string,
    kos: number,
}

-- ── ❌ BAD: Numeric index keys — causes full remount on reorder ─────────────

local function BadLeaderboard(props: { players: { PlayerEntry } }): React.ReactElement
    local rows: { [string]: React.ReactElement } = {}

    for i, player in ipairs(props.players) do
        -- BAD: key is the array index. If players reorder, React sees
        -- "1" → different player and destroys/recreates the Instance.
        rows[tostring(i)] = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, ResponsiveUI.scaleValue(32)),
            BackgroundTransparency = 1,
            Text = player.name .. " — " .. player.kos .. " KOs",
            TextColor3 = DS.colors.text,
            TextSize = DS.fontSize.md(),
            Font = DS.font.default,
            LayoutOrder = i,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, rows)
end

-- ── ✅ GOOD: Stable data-derived keys — survives reorder/insert/delete ──────

local function GoodLeaderboard(props: { players: { PlayerEntry } }): React.ReactElement
    local rows: { [string]: React.ReactElement } = {
        -- Static layout child: descriptive name, never changes.
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, ResponsiveUI.scaleValue(4)),
        }),
    }

    for i, player in ipairs(props.players) do
        -- GOOD: key is derived from the stable player ID.
        -- React correctly maps "Player_42" to the same Instance across re-renders,
        -- even if the player moves from rank 3 to rank 1.
        rows["Player_" .. tostring(player.id)] = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, ResponsiveUI.scaleValue(32)),
            BackgroundTransparency = 1,
            Text = "#" .. i .. " " .. player.name .. " — " .. player.kos .. " KOs",
            TextColor3 = DS.colors.text,
            TextSize = DS.fontSize.md(),
            Font = DS.font.default,
            LayoutOrder = i,  -- LayoutOrder controls visual order; key controls identity.
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, rows)
end

-- ── ✅ GOOD: Conditional children via nil ────────────────────────────────────

local function ConditionalUI(props: { isAdmin: boolean, playerName: string }): React.ReactElement
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, {
        -- Always present: descriptive static key.
        Corner = React.createElement("UICorner", { CornerRadius = DS.radius.md }),

        -- Always present: stable key.
        PlayerLabel = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, ResponsiveUI.scaleValue(32)),
            BackgroundTransparency = 1,
            Text = props.playerName,
            TextColor3 = DS.colors.text,
            TextSize = DS.fontSize.md(),
            Font = DS.font.bold,
        }),

        -- Conditional: maps to nil when isAdmin is false.
        -- React removes the Instance when nil, creates it when non-nil.
        -- The key "AdminBadge" is stable — React knows exactly which slot this is.
        AdminBadge = props.isAdmin and React.createElement("TextLabel", {
            Size = UDim2.new(0, ResponsiveUI.scaleValue(60), 0, ResponsiveUI.scaleValue(20)),
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = DS.accent.warning,
            BackgroundTransparency = 0,
            Text = "ADMIN",
            TextColor3 = DS.colors.text,
            TextSize = DS.fontSize.xs(),
            Font = DS.font.bold,
        }) or nil,
    })
end

-- ── ✅ GOOD: Fragment children also need stable keys ─────────────────────────

local function FragmentWithKeys(props: { items: { PlayerEntry } }): React.ReactElement
    -- When using React.Fragment to return a list, the children table
    -- passed to Fragment also needs stable string keys.
    local elements: { [string]: React.ReactElement } = {}

    for _, item in ipairs(props.items) do
        -- Each element in the Fragment's children table needs a unique key.
        elements["Entry_" .. tostring(item.id)] = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, ResponsiveUI.scaleValue(28)),
            BackgroundTransparency = 1,
            Text = item.name,
            TextColor3 = DS.colors.text,
            TextSize = DS.fontSize.sm(),
            Font = DS.font.default,
        })
    end

    return React.createElement(React.Fragment, {}, elements)
end

return {
    GoodLeaderboard = GoodLeaderboard,
    BadLeaderboard = BadLeaderboard,
    ConditionalUI = ConditionalUI,
    FragmentWithKeys = FragmentWithKeys,
}
```

### Key Naming Quick Reference

```
Static layout children:
  "Corner"    → UICorner
  "Layout"    → UIListLayout / UIGridLayout
  "Stroke"    → UIStroke
  "Gradient"  → UIGradient
  "Padding"   → UIPadding
  "Scale"     → UIScale
  "Aspect"    → UIAspectRatioConstraint

Dynamic list items (use stable ID from data):
  "Player_" .. player.id
  "Tab_" .. tabName
  "Item_" .. item.uuid
  "Row_" .. rowId

Conditional children (key is stable; value is nil to remove):
  AdminBadge = isAdmin and React.createElement(...) or nil
  Overlay    = isOpen  and React.createElement(...) or nil
```

---

## Appendix: React-Lua createElement Syntax Reference

```lua
-- Basic element
React.createElement(
    "Frame",           -- className: Roblox Instance class name OR a component function
    {                  -- props table (or nil)
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        [React.Event.Activated] = function() end,   -- event handler
        [React.Change.Text] = function(inst) end,   -- property change handler
        ref = myRef,                                -- ref attachment
    },
    {                  -- children table: STRING keys → ReactElement values
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Label  = React.createElement("TextLabel", { Text = "Hello" }),
        -- nil values are valid and cause React to remove the Instance
        Badge  = showBadge and React.createElement("Frame", {}) or nil,
    }
)

-- Component element (function component)
React.createElement(MyComponent, { someProp = "value" }, { Child = ... })

-- Fragment
React.createElement(React.Fragment, {}, {
    First  = React.createElement("Frame", {}),
    Second = React.createElement("Frame", {}),
})

-- Context Provider
React.createElement(MyContext.Provider, { value = contextValue }, children)

-- forwardRef component (usage is identical to a normal component)
React.createElement(FocusableInput, { ref = myRef, placeholder = "..." })
```
