# React-Lua Custom Hooks for Roblox

This guide provides a collection of production-ready custom hooks for React-Lua in Roblox. All hooks are written in strict Luau and follow best practices for performance and memory management.

## Hook Index

| Name | Purpose | Returns |
| :--- | :--- | :--- |
| `useRBXSignal` | Generic RBXScriptSignal integration with auto-cleanup | `void` |
| `useSignalValue` | Track a signal's value in state | `T` |
| `useClientEvent` | Subscribe to a RemoteEvent.OnClientEvent | `void` |
| `useInterval` | Stable interval using Heartbeat | `void` |
| `useTimeout` | Stable timeout with cancel function | `() -> ()` (cancel) |
| `useCharacter` | Track local player character and health | `{ character: Model?, isAlive: boolean, health: number, maxHealth: number }` |
| `useCooldown` | Smooth 0→1 progress tracking for abilities | `(isActive: boolean, progress: Binding<number>, trigger: () -> ())` |
| `usePrevious` | Store value from previous render | `T?` |
| `useDebounce` | Debounce state updates | `T` |
| `useActionButton` | High-level hook composing cooldown and RemoteEvent into a game action button | `(canAct: boolean, progress: Binding<number>, onAction: () -> ())` |

---

## 1. useRBXSignal
Generic integration for any Roblox signal. Automatically disconnects on unmount. Uses `useRef` for the callback to avoid reconnecting the signal when the callback changes.

### Implementation
```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function useRBXSignal(signal: RBXScriptSignal, callback: (...any) -> ())
    local callbackRef = React.useRef(callback)
    
    React.useEffect(function()
        callbackRef.current = callback
    end, {callback})

    React.useEffect(function()
        local connection = signal:Connect(function(...)
            callbackRef.current(...)
        end)
        return function()
            connection:Disconnect()
        end
    end, {signal})
end

return useRBXSignal
```

### Usage
```lua
useRBXSignal(game:GetService("RunService").Heartbeat, function(dt: number)
    print("Tick:", dt)
end)
```

---

## 2. useSignalValue
Returns the current value of a signal and updates state whenever the signal fires.

### Implementation
```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function useSignalValue<T>(signal: RBXScriptSignal, initialValue: T): T
    local value, setValue = React.useState(initialValue)
    
    React.useEffect(function()
        local connection = signal:Connect(function(newValue: T)
            setValue(newValue)
        end)
        return function()
            connection:Disconnect()
        end
    end, {signal})

    return value
end

return useSignalValue
```

---

## 3. useClientEvent
Subscribes to a `RemoteEvent.OnClientEvent`. Accepts the `RemoteEvent` instance directly for maximum portability.

### Implementation

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function useClientEvent(remote: RemoteEvent, handler: (...any) -> ())
    local handlerRef = React.useRef(handler)
    React.useEffect(function()
        handlerRef.current = handler
    end, {handler})
    React.useEffect(function()
        local connection = remote.OnClientEvent:Connect(function(...)
            handlerRef.current(...)
        end)
        return function()
            connection:Disconnect()
        end
    end, {remote})
end

return useClientEvent
```

### Usage

```lua
-- Pass the RemoteEvent directly, obtained however your project exposes remotes:
local myRemote = ReplicatedStorage.Remotes.SomeEvent
useClientEvent(myRemote, function(data: string)
    print("Received:", data)
end)
```

## 4. useInterval
A stable interval hook using `RunService.Heartbeat`. Uses `useRef` to ensure the callback is always current without reconnecting the loop.

### Implementation
```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)

local function useInterval(callback: (dt: number) -> (), seconds: number)
    local callbackRef = React.useRef(callback)
    
    React.useEffect(function()
        callbackRef.current = callback
    end, {callback})

    React.useEffect(function()
        local accumulator = 0
        local connection = RunService.Heartbeat:Connect(function(dt: number)
            accumulator += dt
            if accumulator >= seconds then
                accumulator -= seconds
                callbackRef.current(dt)
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, {seconds})
end

return useInterval
```

---

## 5. useTimeout
A stable timeout hook using `task.delay`. Returns a cancel function.

### Implementation
```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function useTimeout(callback: () -> (), seconds: number): () -> ()
    local callbackRef = React.useRef(callback)
    local threadRef = React.useRef(nil :: thread?)
    
    React.useEffect(function()
        callbackRef.current = callback
    end, {callback})

    local cancel = React.useCallback(function()
        if threadRef.current then
            task.cancel(threadRef.current)
            threadRef.current = nil
        end
    end, {})

    React.useEffect(function()
        threadRef.current = task.delay(seconds, function()
            callbackRef.current()
        end)
        return cancel
    end, {seconds, cancel})

    return cancel
end

return useTimeout
```

---

## 6. useCharacter
Tracks the local player's character, health, and alive status. Watches `CharacterAdded`, `CharacterRemoving`, and `Humanoid.HealthChanged`.

### Implementation
```lua
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

type CharacterState = {
    character: Model?,
    isAlive: boolean,
    health: number,
    maxHealth: number,
}

local function useCharacter(): CharacterState
    local player = Players.LocalPlayer
    local state, setState = React.useState({
        character = player.Character,
        isAlive = if player.Character then true else false,
        health = 100,
        maxHealth = 100,
    } :: CharacterState)

    React.useEffect(function()
        local connections: {RBXScriptConnection} = {}

        local function updateCharacter(char: Model?)
            -- Clear old connections when character changes
            for _, conn in connections do
                conn:Disconnect()
            end
            table.clear(connections)

            if not char then
                setState({
                    character = nil,
                    isAlive = false,
                    health = 0,
                    maxHealth = 100,
                })
                return
            end

            local humanoid = char:WaitForChild("Humanoid") :: Humanoid
            
            local function updateHealth()
                setState({
                    character = char,
                    isAlive = humanoid.Health > 0,
                    health = humanoid.Health,
                    maxHealth = humanoid.MaxHealth,
                })
            end

            table.insert(connections, humanoid.HealthChanged:Connect(updateHealth))
            table.insert(connections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth))
            updateHealth()
        end

        local charAddedConn = player.CharacterAdded:Connect(updateCharacter)
        local charRemovingConn = player.CharacterRemoving:Connect(function()
            updateCharacter(nil)
        end)

        if player.Character then
            updateCharacter(player.Character)
        end

        return function()
            charAddedConn:Disconnect()
            charRemovingConn:Disconnect()
            for _, conn in connections do
                conn:Disconnect()
            end
        end
    end, {})

    return state
end

return useCharacter
```

---

## 7. useCooldown
Manages a cooldown state with a smooth 0→1 progress binding using `Heartbeat`.

### Implementation
```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)

local function useCooldown(duration: number): (boolean, React.Binding<number>, () -> ())
    local isActive, setIsActive = React.useState(false)
    local progress, setProgress = React.useBinding(0)
    local startTime = React.useRef(0)

    local trigger = React.useCallback(function()
        if isActive then return end
        setIsActive(true)
        setProgress(0)
        startTime.current = os.clock()
    end, {isActive})

    React.useEffect(function()
        if not isActive then return end

        local connection = RunService.Heartbeat:Connect(function()
            local elapsed = os.clock() - startTime.current
            local alpha = math.clamp(elapsed / duration, 0, 1)
            setProgress(alpha)

            if alpha >= 1 then
                setIsActive(false)
            end
        end)

        return function()
            connection:Disconnect()
        end
    end, {isActive, duration})

    return isActive, progress, trigger
end

return useCooldown
```

---

## 8. usePrevious
Stores the value from the previous render using `useRef`. Useful for detecting changes in props or state.

### Implementation
```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function usePrevious<T>(value: T): T?
    local ref = React.useRef(nil :: T?)
    
    React.useEffect(function()
        ref.current = value
    end, {value})

    return ref.current
end

return usePrevious
```

---

## 9. useDebounce
Returns a debounced version of a value that only updates after a specified delay.

### Implementation
```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function useDebounce<T>(value: T, delay: number): T
    local debouncedValue, setDebouncedValue = React.useState(value)

    React.useEffect(function()
        local thread = task.delay(delay, function()
            setDebouncedValue(value)
        end)

        return function()
            task.cancel(thread)
        end
    end, {value, delay})

    return debouncedValue
end

return useDebounce
```

---

## 10. Hook Composition: useActionButton
Example of composing `useCooldown` and `useClientEvent` into a single high-level hook for a game action.

### Implementation

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
-- Assuming these hooks are in the same project:
local useCooldown = require(script.Parent.useCooldown)
local useClientEvent = require(script.Parent.useClientEvent)
--[[
    useActionButton(actionRemote, confirmRemote, cooldownDuration)

    - actionRemote: the RemoteEvent to fire when the player presses the button
    - confirmRemote: (optional) a RemoteEvent the server fires to confirm the action
    - cooldownDuration: seconds

    Returns:
    - canAct: true when the cooldown has expired
    - progress: Binding<number> 0→1 for cooldown bar display
    - onAction: call this on button press
]]
local function useActionButton(
    actionRemote: RemoteEvent,
    confirmRemote: RemoteEvent?,
    cooldownDuration: number
): (boolean, React.Binding<number>, () -> ())
    local isActive, progress, trigger = useCooldown(cooldownDuration)
    -- Optionally sync UI with server confirmation
    if confirmRemote then
        useClientEvent(confirmRemote, function()
            if not isActive then
                trigger()
            end
        end)
    end

    local onAction = React.useCallback(function()
        if not isActive then
            trigger()
            actionRemote:FireServer()
        end
    end, {isActive, trigger, actionRemote} :: {any})

    return not isActive, progress, onAction
end

return useActionButton
```

### Usage Example
```lua
-- In a game with an action button (e.g. ability, attack, interact):
local Remotes = ReplicatedStorage.Remotes
local canAct, actionProgress, onAction = useActionButton(
    Remotes.RequestAction,   -- fire on press
    Remotes.ActionConfirmed, -- optional server confirmation
    3                        -- 3 second cooldown
)
```
### Notes
- **Stable Callbacks**: Always use `useRef` for callbacks passed to `useEffect` with signals/loops to avoid unnecessary reconnections.
- **Cleanup**: Every signal connection and `task` thread must be cleaned up in the `useEffect` return function to prevent memory leaks.
- **Bindings**: Use `useBinding` for high-frequency updates (like progress bars) to avoid React re-render overhead.
- **Type Safety**: Use `--!strict` and generic types (`<T>`) to ensure hooks are reusable and type-safe.
