# React-Lua Performance Optimization Reference

> **Scope**: Roblox UI performance for React-Lua (jsdotlua/react). All examples use `--!strict`.
> Frame advice as "when you hit N items/updates" — avoid premature optimization.

---

## Performance Checklist

Before profiling, verify these first:

- [ ] Components that receive stable props are wrapped in `React.memo`
- [ ] Expensive calculations (filter/sort/count) are inside `useMemo`
- [ ] Callbacks passed to memo'd children use `useCallback`
- [ ] High-frequency values (health bars, timers) use `Binding` instead of `useState`
- [ ] Lists with 50+ items use conditional rendering or virtual scrolling
- [ ] Hidden UI uses `return nil` (unmount) not just `Visible = false` when rarely shown
- [ ] No `CanvasGroup` used unless you need group transparency (expensive)
- [ ] `UIStroke` count is below 50 simultaneously
- [ ] `ViewportFrame` count is 3–5 max
- [ ] `debug.profilebegin/profileend` wraps any suspected hot path before optimizing

---

## Practical Limits Table

| Element | Recommended Max | Notes |
|---|---|---|
| `TextLabel` (active/updating) | 200–300 | Static labels are cheaper; updating text every frame is expensive |
| `TextLabel` (static) | 500–800 | No per-frame cost once rendered |
| `ImageLabel` (static) | 500–1000 | Cached after first render; avoid changing `Image` property frequently |
| `ImageLabel` (animated/changing) | 50–100 | Each `Image` property change invalidates the render cache |
| Simultaneous `TweenService` tweens | 50–100 | Engine-level; cheaper than Heartbeat loops |
| `UIStroke` instances | 50 | Each stroke adds a render pass |
| `CanvasGroup` instances | 10–20 | Forces a separate render target per group |
| `ViewportFrame` instances | 3–5 | Each is a full 3D render; extremely expensive |
| React components re-rendering per frame | < 20 | Profile with MicroProfiler if more |

---

## 1. React.memo — Prevent Unnecessary Re-renders

**When to use**: When a component receives the same props frequently but its parent re-renders often. Effective at 10+ list items or any component that renders on every state tick.

### Basic Usage

```lua
--!strict
local React = require(ReplicatedStorage.Packages.React)

type PlayerRowProps = {
    playerName: string,
    score: number,
    rank: number,
}

-- Without memo: re-renders every time parent state changes, even if props are identical
local PlayerRow = React.memo(function(props: PlayerRowProps)
    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
    }, {
        NameLabel = React.createElement("TextLabel", {
            Text = string.format("#%d  %s", props.rank, props.playerName),
            Size = UDim2.new(0.7, 0, 1, 0),
            TextColor3 = Color3.fromRGB(255, 255, 255),
        }),
        ScoreLabel = React.createElement("TextLabel", {
            Text = tostring(props.score),
            Size = UDim2.new(0.3, 0, 1, 0),
            TextColor3 = Color3.fromRGB(200, 200, 100),
        }),
    })
end)
```

### Custom Comparison Function

`React.memo` uses **shallow comparison** by default: it compares each prop with `==`. This means:
- Primitive values (`string`, `number`, `boolean`) compare correctly
- Tables/functions compare by **reference** — a new table `{}` passed each render will always be "different" even if contents are identical

Provide a custom comparator when props contain tables:

```lua
--!strict
type AbilityCardProps = {
    abilityName: string,
    cooldown: number,
    -- Table prop: shallow compare would always see this as changed
    iconConfig: { imageId: string, tintColor: Color3 },
}

local AbilityCard = React.memo(
    function(props: AbilityCardProps)
        return React.createElement("Frame", {
            Size = UDim2.new(0, 80, 0, 80),
        }, {
            Icon = React.createElement("ImageLabel", {
                Image = props.iconConfig.imageId,
                ImageColor3 = props.iconConfig.tintColor,
                Size = UDim2.fromScale(1, 1),
            }),
        })
    end,
    -- Custom comparator: return true = props are equal = skip re-render
    function(prevProps: AbilityCardProps, nextProps: AbilityCardProps): boolean
        if prevProps.abilityName ~= nextProps.abilityName then return false end
        if prevProps.cooldown ~= nextProps.cooldown then return false end
        -- Deep compare the table fields manually
        if prevProps.iconConfig.imageId ~= nextProps.iconConfig.imageId then return false end
        if prevProps.iconConfig.tintColor ~= nextProps.iconConfig.tintColor then return false end
        return true
    end
)
```

> **Shallow comparison behavior**: `React.memo` iterates the props table and checks `prevProps[k] == nextProps[k]` for each key. For `Color3`, `Vector2`, `UDim2` — Roblox datatypes use value equality, so they compare correctly. For plain Lua tables `{}`, comparison is by reference.

---

## 2. useMemo — Cache Expensive Calculations

**When to use**: When a calculation depends on props/state and is called on every render. Effective when the calculation involves iteration over 20+ items, sorting, or string formatting.

```lua
--!strict
local React = require(ReplicatedStorage.Packages.React)

type LeaderboardProps = {
    -- Raw unsorted player data
    players: { { name: string, score: number, isAlive: boolean } },
    showOnlyAlive: boolean,
    searchQuery: string,
}

local Leaderboard = function(props: LeaderboardProps)
    -- Without useMemo: filter + sort runs on EVERY render, even unrelated state changes
    -- With useMemo: only recalculates when `players`, `showOnlyAlive`, or `searchQuery` changes
    local filteredAndSorted = React.useMemo(function()
        local result: { { name: string, score: number, isAlive: boolean } } = {}

        -- Filter step
        for _, player in ipairs(props.players) do
            local passesAliveFilter = not props.showOnlyAlive or player.isAlive
            local passesSearch = props.searchQuery == ""
                or string.find(string.lower(player.name), string.lower(props.searchQuery), 1, true) ~= nil
            if passesAliveFilter and passesSearch then
                table.insert(result, player)
            end
        end

        -- Sort step (descending score)
        table.sort(result, function(a, b)
            return a.score > b.score
        end)

        return result
    end, { props.players, props.showOnlyAlive, props.searchQuery } :: { any })

    -- Cached count — avoids re-counting on every render
    local aliveCount = React.useMemo(function(): number
        local count = 0
        for _, player in ipairs(props.players) do
            if player.isAlive then
                count += 1
            end
        end
        return count
    end, { props.players } :: { any })

    local rows = {}
    for i, player in ipairs(filteredAndSorted) do
        rows["row_" .. i] = React.createElement("TextLabel", {
            LayoutOrder = i,
            Text = string.format("%d. %s — %d pts", i, player.name, player.score),
            Size = UDim2.new(1, 0, 0, 36),
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
    }, {
        Header = React.createElement("TextLabel", {
            Text = string.format("Alive: %d", aliveCount),
            Size = UDim2.new(1, 0, 0, 32),
        }),
        List = React.createElement("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, -32),
        }, rows),
    })
end
```

> **Dependency array**: React compares each element with `==`. Pass every value the memo'd function reads. Missing a dependency = stale cached value. Extra dependencies = unnecessary recalculation (acceptable).

---

## 3. useCallback — Stabilize Function References

**When to use**: When passing a callback as a prop to a `React.memo` child. Without `useCallback`, a new function is created each render, breaking memo's reference equality check.

```lua
--!strict
local React = require(ReplicatedStorage.Packages.React)

-- Memo'd child — only re-renders when props change
type ActionButtonProps = {
    label: string,
    onPress: () -> (),
}

local ActionButton = React.memo(function(props: ActionButtonProps)
    return React.createElement("TextButton", {
        Text = props.label,
        Size = UDim2.new(0, 120, 0, 44),
        [React.Event.Activated] = props.onPress,
    })
end)

-- Parent component
local GameHUD = function()
    local score, setScore = React.useState(0)
    local combo, setCombo = React.useState(0)

    -- BAD: new function reference every render → ActionButton always re-renders
    -- local handleBump = function() setScore(score + 10) end

    -- GOOD: stable reference, only changes when `combo` changes
    local handleBump = React.useCallback(function()
        -- Reads `combo` from closure — must be in dependency array
        local bonus = combo * 5
        setScore(function(prev: number): number
            return prev + 10 + bonus
        end)
    end, { combo } :: { any })

    -- This callback has no dependencies — created once for the component lifetime
    local handleReset = React.useCallback(function()
        setScore(0)
        setCombo(0)
    end, {} :: { any })

    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 100),
    }, {
        ScoreLabel = React.createElement("TextLabel", {
            Text = "Score: " .. score,
            Size = UDim2.new(1, 0, 0, 40),
        }),
        BumpButton = React.createElement(ActionButton, {
            label = "BUMP",
            onPress = handleBump,
        }),
        ResetButton = React.createElement(ActionButton, {
            label = "Reset",
            onPress = handleReset,
        }),
    })
end
```

> **Rule of thumb**: `useCallback` is only useful when the function is passed to a `React.memo` component or used as a `useEffect`/`useMemo` dependency. Wrapping every function in `useCallback` adds overhead with no benefit.

---

## 4. Binding Fast-Lane — Skip the React Reconciler

**Why Binding is faster**: When you call `setValue` on a `React.Binding`, the new value is applied **directly to the Roblox instance property** without going through React's reconciler (no virtual DOM diff, no component re-render). This makes Bindings ideal for values that change every frame.

**When to use Binding vs State**:

| Scenario | Use |
|---|---|
| Health bar that updates every 0.1s | `Binding` |
| Cooldown timer counting down | `Binding` |
| Score that updates on KO events | `useState` (infrequent) |
| Modal open/closed | `useState` |
| Smooth position animation | `Binding` + `TweenService` |
| Tab selection | `useState` |

```lua
--!strict
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

-- Health bar using Binding — zero reconciler overhead on updates
local function createHealthBar(maxHealth: number)
    -- Binding holds the current value and a setter
    local healthBinding, setHealth = React.createBinding(maxHealth)

    local component = function()
        return React.createElement("Frame", {
            Name = "HealthBarContainer",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundColor3 = Color3.fromRGB(60, 20, 20),
        }, {
            Fill = React.createElement("Frame", {
                -- Binding maps directly to the Size property — no re-render on change
                Size = healthBinding:map(function(hp: number): UDim2
                    local fraction = math.clamp(hp / maxHealth, 0, 1)
                    return UDim2.new(fraction, 0, 1, 0)
                end),
                BackgroundColor3 = Color3.fromRGB(80, 200, 80),
            }),
            Label = React.createElement("TextLabel", {
                -- Binding can also map to text
                Text = healthBinding:map(function(hp: number): string
                    return string.format("%d / %d", math.floor(hp), maxHealth)
                end),
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            }),
        })
    end

    -- Return both the component and the setter so external code can update health
    return component, setHealth
end

-- Usage: update health from a RemoteEvent without triggering React reconciliation
local HealthBar, setPlayerHealth = createHealthBar(100)

-- This call bypasses React entirely — direct property write on the Roblox instance
game:GetService("RunService").Heartbeat:Connect(function()
    -- Simulate health drain
    -- setPlayerHealth(currentHp)  -- fast, no reconciler
end)
```

> **Binding limitation**: Bindings cannot trigger conditional rendering or structural changes (adding/removing children). For structural changes, use `useState`. For value interpolation on existing elements, use `Binding`.

---

## 5. Virtual Scrolling — Render Only Visible Items

**When to use**: Lists with 50+ items. At 100+ items, rendering all rows simultaneously causes frame drops on low-end devices. Virtual scrolling renders only the visible rows plus a small buffer.

```lua
--!strict
local React = require(ReplicatedStorage.Packages.React)

local ITEM_HEIGHT = 48 -- pixels per row
local BUFFER_ITEMS = 3 -- extra rows above/below visible area

type VirtualListProps = {
    items: { string }, -- list of 1000+ item labels
    containerHeight: number, -- visible height in pixels
}

local VirtualList = function(props: VirtualListProps)
    -- Track scroll position via Binding for zero-reconciler overhead
    local scrollBinding, setScroll = React.createBinding(0)

    -- Total canvas height needed to represent all items
    local totalHeight = #props.items * ITEM_HEIGHT

    -- Calculate which items are visible based on scroll position
    -- This runs inside useMemo so it only recalculates when scroll changes
    -- NOTE: For true virtual scrolling, connect CanvasPosition.Changed and call setScroll
    local visibleItems = React.useMemo(function()
        -- Read current scroll from binding value (0 on first render)
        -- In practice, update this state via a CanvasPosition Changed connection
        local scrollY = 0

        local firstVisible = math.max(1, math.floor(scrollY / ITEM_HEIGHT) - BUFFER_ITEMS)
        local lastVisible = math.min(
            #props.items,
            math.ceil((scrollY + props.containerHeight) / ITEM_HEIGHT) + BUFFER_ITEMS
        )

        local visible: { { index: number, label: string, yOffset: number } } = {}
        for i = firstVisible, lastVisible do
            table.insert(visible, {
                index = i,
                label = props.items[i],
                yOffset = (i - 1) * ITEM_HEIGHT,
            })
        end
        return visible
    end, { props.items, props.containerHeight } :: { any })

    -- Build only the visible row elements
    local rows: { [string]: React.ReactElement } = {}
    for _, item in ipairs(visibleItems) do
        rows["item_" .. item.index] = React.createElement("TextLabel", {
            -- Absolute position within the canvas
            Position = UDim2.new(0, 0, 0, item.yOffset),
            Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),
            Text = item.label,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = if item.index % 2 == 0
                then Color3.fromRGB(35, 35, 45)
                else Color3.fromRGB(28, 28, 38),
            TextColor3 = Color3.fromRGB(220, 220, 220),
        })
    end

    return React.createElement("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, props.containerHeight),
        -- Canvas is sized for ALL items so the scrollbar is accurate
        CanvasSize = UDim2.new(0, 0, 0, totalHeight),
        ScrollBarThickness = 6,
        -- Connect scroll position changes to update visible range
        [React.Change.CanvasPosition] = function(rbx: ScrollingFrame)
            setScroll(rbx.CanvasPosition.Y)
        end,
    }, rows)
end
```

> **Key insight**: The `ScrollingFrame.CanvasSize` must equal `totalItems * ITEM_HEIGHT` so the scrollbar behaves correctly, even though only ~15–20 rows are actually rendered at any time. On a 1000-item list this reduces rendered elements from 1000 to ~20.

---

## 6. Object Pooling — Reuse Frame Instances

**When to use**: When UI elements are frequently created and destroyed (kill feed entries, floating damage numbers, notification toasts). Creating new Instances has GC overhead; pooling reuses them.

```lua
--!strict

-- UIPool: generic pool for any GuiObject template
local UIPool = {}
UIPool.__index = UIPool

type UIPoolType = {
    _template: GuiObject,
    _parent: GuiObject,
    _available: { GuiObject },
    get: (self: UIPoolType) -> GuiObject,
    release: (self: UIPoolType, item: GuiObject) -> (),
}

function UIPool.new(template: GuiObject, parent: GuiObject): UIPoolType
    local self = setmetatable({}, UIPool) :: any
    self._template = template
    self._parent = parent
    self._available = {} :: { GuiObject }
    return self
end

-- Get an instance from the pool (or create one if pool is empty)
function UIPool:get(): GuiObject
    if #self._available > 0 then
        local item = table.remove(self._available) :: GuiObject
        item.Visible = true
        item.Parent = self._parent
        return item
    end
    -- Pool exhausted — clone the template
    local newItem = self._template:Clone()
    newItem.Parent = self._parent
    return newItem
end

-- Return an instance to the pool for reuse
function UIPool:release(item: GuiObject): ()
    item.Visible = false
    item.Parent = nil -- detach from tree to avoid rendering cost
    table.insert(self._available, item)
end

-- ── Usage: Kill Feed ──────────────────────────────────────────────────────────

-- Setup (once, outside React)
local killFeedTemplate = Instance.new("TextLabel")
killFeedTemplate.Size = UDim2.new(1, 0, 0, 32)
killFeedTemplate.BackgroundTransparency = 0.4
killFeedTemplate.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
killFeedTemplate.TextColor3 = Color3.fromRGB(255, 80, 80)
killFeedTemplate.Font = Enum.Font.GothamBold
killFeedTemplate.TextSize = 14

local killFeedContainer = script.Parent:FindFirstChild("KillFeedContainer") :: Frame
local killFeedPool = UIPool.new(killFeedTemplate, killFeedContainer)

-- Show a kill entry (called from RemoteEvent handler)
local function showKillEntry(killerName: string, victimName: string): ()
    local entry = killFeedPool:get()
    local label = entry :: TextLabel
    label.Text = string.format("⚡ %s KO'd %s", killerName, victimName)
    label.LayoutOrder = -os.clock() -- newest at top

    -- Auto-release after 4 seconds
    task.delay(4, function()
        if entry.Parent ~= nil then
            killFeedPool:release(entry)
        end
    end)
end
```

---

## 7. Conditional Rendering — Unmount vs Hide

**Two strategies for hiding UI**:

| Strategy | Roblox cost | React cost | Use when |
|---|---|---|---|
| `return nil` | Instance destroyed | Component unmounted | Rarely shown (shop, settings) |
| `Visible = false` | Instance exists, not drawn | Component stays mounted | Frequently toggled (HUD elements) |

```lua
--!strict
local React = require(ReplicatedStorage.Packages.React)

-- ── Strategy A: Unmount (return nil) ─────────────────────────────────────────
-- Best for: Shop UI, tutorial overlays, end-of-match screens
-- Cost: React must re-create the full subtree on next open (acceptable for rare opens)

type ShopPanelProps = {
    isOpen: boolean,
}

local ShopPanel = function(props: ShopPanelProps)
    -- Completely removes all Roblox Instances from the tree when closed
    -- No rendering cost while closed
    if not props.isOpen then
        return nil
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(0.8, 0.8),
        Position = UDim2.fromScale(0.1, 0.1),
        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
    }, {
        -- ... hundreds of shop items
    })
end

-- ── Strategy B: Visible = false ───────────────────────────────────────────────
-- Best for: Cooldown bar, ability icons, HUD elements toggled frequently
-- Cost: Instances remain in memory; Roblox skips drawing but still processes them

type CooldownBarProps = {
    isVisible: boolean,
    progress: number, -- 0 to 1
}

local CooldownBar = function(props: CooldownBarProps)
    -- Instance stays mounted; only Visible property changes
    -- Avoids re-mount cost on frequent show/hide
    return React.createElement("Frame", {
        Visible = props.isVisible,
        Size = UDim2.new(1, 0, 0, 8),
        BackgroundColor3 = Color3.fromRGB(40, 40, 60),
    }, {
        Fill = React.createElement("Frame", {
            Size = UDim2.new(props.progress, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(100, 200, 255),
        }),
    })
end
```

> **Decision rule**: If the UI is shown < 10% of the time, use `return nil`. If it toggles multiple times per minute, use `Visible = false`.

---

## 8. Roblox Rendering Cache

Roblox caches the rendered appearance of each `GuiObject`. The cache is **invalidated** (forcing a re-draw) when:
- A property on the object changes (`BackgroundColor3`, `Text`, `Size`, etc.)
- A child is added or removed
- A child's property changes (propagates up to the parent's layout)

**Implication for animations**:

```lua
--!strict
-- BAD: Manual Heartbeat loop — invalidates cache every frame via Luau
-- Each property write triggers a cache invalidation + re-draw
local RunService = game:GetService("RunService")

local function animateWithHeartbeat(frame: Frame): ()
    local startTime = os.clock()
    local connection: RBXScriptConnection

    connection = RunService.Heartbeat:Connect(function()
        local t = (os.clock() - startTime) % 1
        -- This write invalidates the render cache every single frame
        frame.BackgroundTransparency = math.sin(t * math.pi)
    end)
end

-- GOOD: TweenService — engine-level interpolation, bypasses Luau overhead
-- The engine interpolates the property internally without Luau script involvement
local TweenService = game:GetService("TweenService")

local function animateWithTween(frame: Frame): ()
    local tweenInfo = TweenInfo.new(
        1,                          -- duration
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1,                         -- repeat count (-1 = infinite)
        true                        -- reverses
    )
    local tween = TweenService:Create(frame, tweenInfo, {
        BackgroundTransparency = 1,
    })
    tween:Play()
end
```

> **Why TweenService is faster**: The interpolation runs in the engine's C++ render loop. Luau `Heartbeat` callbacks run in the Luau VM, which adds script scheduling overhead and forces a property-write cache invalidation path through the Luau→C++ bridge on every frame. TweenService skips the Luau layer entirely.

**Minimize cache invalidations in React**:
- Avoid passing new `Color3`/`UDim2` literals as props on every render — they look equal but may trigger property writes if React doesn't short-circuit
- Use `React.memo` to prevent re-renders that would write unchanged properties
- Prefer `Binding` for animated values so React never touches the property

---

## 9. MicroProfiler — Measure Before Optimizing

Use `debug.profilebegin` / `debug.profileend` to measure specific code paths. Results appear in the Roblox MicroProfiler (`Ctrl+F6` in Studio).

```lua
--!strict
local React = require(ReplicatedStorage.Packages.React)

type ProfiledListProps = {
    items: { string },
}

local ProfiledList = function(props: ProfiledListProps)
    -- Wrap the expensive calculation in profile markers
    debug.profilebegin("ProfiledList: filter+sort")
    local processed = React.useMemo(function(): { string }
        debug.profilebegin("useMemo: filter")
        local filtered: { string } = {}
        for _, item in ipairs(props.items) do
            if #item > 3 then
                table.insert(filtered, item)
            end
        end
        debug.profileend() -- end filter

        debug.profilebegin("useMemo: sort")
        table.sort(filtered)
        debug.profileend() -- end sort

        return filtered
    end, { props.items } :: { any })
    debug.profileend() -- end filter+sort

    -- Measure render time of the list
    debug.profilebegin("ProfiledList: createElement loop")
    local elements: { [string]: React.ReactElement } = {}
    for i, item in ipairs(processed) do
        elements["item_" .. i] = React.createElement("TextLabel", {
            LayoutOrder = i,
            Text = item,
            Size = UDim2.new(1, 0, 0, 32),
        })
    end
    debug.profileend() -- end createElement loop

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
    }, elements)
end
```

**Reading MicroProfiler output**:
1. Press `Ctrl+F6` in Studio during Play mode
2. Look for your label names in the timeline
3. Bars wider than **2ms** on the render thread are worth optimizing
4. `useMemo` overhead itself is ~0.01ms — only use it when the calculation exceeds ~0.5ms

**Practical thresholds**:
- `createElement` loop over 50 items: ~0.3ms (acceptable)
- `createElement` loop over 500 items: ~3ms (optimize with virtual scrolling)
- Filter+sort of 1000 items without `useMemo`: ~2–5ms per render (add `useMemo`)

---

## Quick Reference: Optimization Decision Tree

```
Component re-renders too often?
  └─ Does it receive the same props frequently?
       └─ YES → React.memo
            └─ Props contain tables/functions?
                 └─ YES → Custom comparator or useCallback/useMemo on the parent

Expensive calculation on every render?
  └─ useMemo with correct dependency array

Callback passed to memo'd child always changes?
  └─ useCallback

Value changes every frame (health, timer, position)?
  └─ Binding (not useState)
       └─ Need animation? → TweenService (not Heartbeat)

List has 50+ items?
  └─ 50–200 items → React.memo on row component
  └─ 200+ items → Virtual scrolling

UI element created/destroyed frequently?
  └─ Object pooling (UIPool.get / UIPool.release)

UI shown rarely vs frequently toggled?
  └─ Rarely (< 10% of time) → return nil (unmount)
  └─ Frequently toggled → Visible = false (keep mounted)
```
