--!strict

# React-Lua State Management

## State Management Selection Guide

| Pattern | Scope | Frequency | Best For |
| :--- | :--- | :--- | :--- |
| **useState** | Local | Low/Medium | Simple toggles, form inputs, local UI state |
| **useReducer** | Local/Complex | Low/Medium | Complex state logic, multiple related fields |
| **Bindings** | Local/Visual | High (60fps) | Animations, position/size updates, transparency |
| **Context API** | Tree-wide | Low | Themes, user data, global settings, game phase |
| **Rodux** | Global | Low/Medium | Persistent game data, inventory, cross-screen state |
| **BindableEvent** | Cross-tree | Low | Decoupled systems, external triggers (e.g. HUD vs Menu) |

---

## 1. useState Best Practices

`useState` is the primary hook for managing local component state.

### Initializer Function Pattern
Use an initializer function for expensive computations to ensure they only run once during the initial mount.

```lua
--!strict
local React = require(ReplicatedStorage.Packages.React)

local function ExpensiveComponent()
    local state, setState = React.useState(function()
        print("Expensive calculation running...")
        local result = 0
        for i = 1, 10000 do
            result += math.sqrt(i)
        end
        return result
    end)

    return React.createElement("TextLabel", {
        Text = "Result: " .. tostring(state)
    })
end
```

### Functional Updates
Always use the functional update pattern when the new state depends on the previous state to avoid race conditions and stale closures.

```lua
--!strict
local function Counter()
    local count, setCount = React.useState(0)

    local increment = function()
        -- Correct: Uses previous state
        setCount(function(prevCount: number)
            return prevCount + 1
        end)
    end

    return React.createElement("TextButton", {
        Text = "Count: " .. tostring(count),
        [React.Event.Activated] = increment
    })
end
```

### Batch Updates
React-Lua batches state updates within event handlers. Multiple `setState` calls will result in a single re-render.

```lua
--!strict
local function MultiUpdate()
    local x, setX = React.useState(0)
    local y, setY = React.useState(0)

    local handleClick = function()
        -- These two updates will trigger only ONE re-render
        setX(function(prev) return prev + 1 end)
        setY(function(prev) return prev + 1 end)
    end

    return React.createElement("TextButton", {
        Text = string.format("Pos: %d, %d", x, y),
        [React.Event.Activated] = handleClick
    })
end
```

---

## 2. useReducer for Complex State

`useReducer` is preferred when state logic involves multiple sub-values or when the next state depends on the previous one in complex ways.

```lua
--!strict
local React = require(ReplicatedStorage.Packages.React)

type ShopItem = {
    id: string,
    name: string,
    price: number
}

type ShopState = {
    items: {ShopItem},
    cart: {string}, -- IDs
    total: number,
    isProcessing: boolean
}

type ShopAction = 
    { type: "ADD_TO_CART", itemId: string, price: number }
    | { type: "REMOVE_FROM_CART", itemId: string, price: number }
    | { type: "SET_PROCESSING", value: boolean }

local function shopReducer(state: ShopState, action: ShopAction): ShopState
    if action.type == "ADD_TO_CART" then
        local newCart = table.clone(state.cart)
        table.insert(newCart, action.itemId)
        
        -- Luau spread pattern: table.clone + override
        local newState = table.clone(state)
        newState.cart = newCart
        newState.total = state.total + action.price
        return newState
        
    elseif action.type == "REMOVE_FROM_CART" then
        local newCart = {}
        local removed = false
        for _, id in state.cart do
            if not removed and id == action.itemId then
                removed = true
            else
                table.insert(newCart, id)
            end
        end
        
        return {
            items = state.items,
            cart = newCart,
            total = state.total - action.price,
            isProcessing = state.isProcessing
        } :: ShopState
        
    elseif action.type == "SET_PROCESSING" then
        -- Inline cast pattern for partial updates
        return (table.freeze({
            items = state.items,
            cart = state.cart,
            total = state.total,
            isProcessing = action.value
        }) :: any) :: ShopState
    end
    
    return state
end

local initialState: ShopState = {
    items = {},
    cart = {},
    total = 0,
    isProcessing = false
}

local function ShopComponent()
    local state, dispatch = React.useReducer(shopReducer, initialState)

    local onAddItem = function(item: ShopItem)
        dispatch({ type: "ADD_TO_CART", itemId = item.id, price = item.price })
    end

    -- Render logic...
end
```

---

## 3. Context API

Context provides a way to pass data through the component tree without having to pass props down manually at every level.

### Implementation Pattern

```lua
--!strict
local React = require(ReplicatedStorage.Packages.React)

type GamePhase = "INTERMISSION" | "RUNNING" | "RESULT"

type GameContextType = {
    phase: GamePhase,
    coins: number,
    setPhase: (phase: GamePhase) -> (),
}

local GameContext = React.createContext({
    phase = "INTERMISSION",
    coins = 0,
    setPhase = function() end,
} :: GameContextType)

-- Provider Component
local function GameProvider(props: { children: React.ReactNode })
    local phase, setPhase = React.useState("INTERMISSION" :: GamePhase)
    local coins, setCoins = React.useState(0)

    local value = React.useMemo(function()
        return {
            phase = phase,
            coins = coins,
            setPhase = setPhase,
        }
    end, {phase, coins} :: {any})

    return React.createElement(GameContext.Provider, {
        value = value
    }, props.children)
end

-- Deep Child Component
local function HUD()
    local game = React.useContext(GameContext)

    return React.createElement("TextLabel", {
        Text = "Phase: " .. game.phase .. " | Coins: " .. tostring(game.coins)
    })
end
```

### ⚠️ Performance Warning
**Do NOT use Context for high-frequency updates.**
When a Context value changes, **all** components that call `useContext(MyContext)` will re-render. For high-frequency data (like character positions or countdown timers), use **Bindings** or a specialized store.

---

## 4. Binding vs State Decision Tree

Bindings are specialized for high-frequency visual updates that bypass the React reconciliation cycle.

### Decision Tree
```text
Is the update high-frequency (e.g., every frame)?
├── YES: Is it a visual property (Position, Size, Transparency)?
│   ├── YES: Use useBinding()
│   └── NO: Re-evaluate if it needs to be high-frequency.
└── NO: Does it affect component structure (adding/removing children)?
    ├── YES: Use useState() or useReducer()
    └── NO: Use useState()
```

### Binding Example
```lua
--!strict
local function PulsingCircle()
    local size, setSize = React.useBinding(UDim2.fromOffset(100, 100))

    React.useEffect(function()
        local connection = RunService.RenderStepped:Connect(function(dt)
            local scale = 1 + math.sin(tick() * 5) * 0.2
            setSize(UDim2.fromOffset(100 * scale, 100 * scale))
        end)
        return function()
            connection:Disconnect()
        end
    end, {})

    return React.createElement("Frame", {
        Size = size, -- Directly accepts the binding
        BackgroundColor3 = Color3.new(1, 0, 0)
    })
end
```

---

## 5. Rodux Integration

Rodux is the standard Redux implementation for Roblox. Use it for global state that persists across different UI trees.

```lua
--!strict
local Rodux = require(ReplicatedStorage.Packages.Rodux)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

-- 1. Create Store
local reducer = function(state, action)
    -- ...
end
local store = Rodux.Store.new(reducer)

-- 2. Wrap Root with StoreProvider
local root = React.createElement(RoactRodux.StoreProvider, {
    store = store
}, {
    MainUI = React.createElement(MainApp)
})

-- 3. Connect Component (Legacy Pattern)
-- Note: React-Lua hooks for Rodux (useSelector) are available in newer wrappers
local function Profile(props)
    return React.createElement("TextLabel", {
        Text = "User: " .. props.username
    })
end

Profile = RoactRodux.connect(function(state)
    return {
        username = state.profile.username
    }
end)(Profile)
```

---

## 6. BindableEvent Pattern (External State)

Use `BindableEvent` to communicate between React components and external non-React systems, or between decoupled UI trees.

```lua
--!strict
-- SelectorStateManager.luau (Shared Module)
local SelectorStateManager = {}
SelectorStateManager.Changed = Instance.new("BindableEvent")
local currentSelector = nil

function SelectorStateManager.open(name: string)
    currentSelector = name
    SelectorStateManager.Changed:Fire(currentSelector)
end

return SelectorStateManager

-- React Component
local function SelectorButton(props: { name: string })
    local isOpen, setIsOpen = React.useState(false)

    React.useEffect(function()
        local connection = SelectorStateManager.Changed.Event:Connect(function(activeName)
            setIsOpen(activeName == props.name)
        end)
        return function()
            connection:Disconnect()
        end
    end, {})

    return React.createElement("TextButton", {
        Text = props.name .. (isOpen and " (Open)" or ""),
        [React.Event.Activated] = function()
            SelectorStateManager.open(props.name)
        end
    })
end
```

### When to use
- When the state needs to be accessed by non-React scripts (e.g., a legacy Tool script).
- When you have multiple `ReactRoblox.createRoot` calls that need to sync.
- For simple "singleton" state that doesn't justify a full Rodux store.
