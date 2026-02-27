# React-Lua Animation Reference

This document covers animation techniques for React-Lua in Roblox, focusing on performance and best practices.

## Which animation approach to use?

| Requirement | Recommended Approach |
| :--- | :--- |
| Simple UI transitions (Scale, Position, Color) | **react-spring** (`useSpring`) |
| Staggered list animations | **react-spring** (`useSprings`) |
| Continuous looping effects (Pulse, Glow) | **Heartbeat + Binding** (`usePulse`) |
| Complex Roblox-specific easing (Elastic, Bounce) | **Binding + TweenService** (`useTweenBinding`) |
| Multi-property synchronization | **joinBindings** |
| Derived property updates (Number -> UDim2) | **Binding.map()** |
| Entry/Exit animations | **Mount/unmount pattern** (`useAnimatedMount`) |

## Common Animation Configs

| Config | Tension | Friction | Behavior |
| :--- | :--- | :--- | :--- |
| `gentle` | 120 | 14 | Smooth, natural movement |
| `snappy` | 180 | 12 | Fast, responsive, minimal overshoot |
| `bouncy` | 210 | 20 | Playful, noticeable bounce |
| `stiff` | 210 | 20 | Very fast, no bounce |

---

## 1. Binding + TweenService (useTweenBinding)

Use this when you need `TweenService`'s specific easing styles (e.g., `Elastic`, `Bounce`) while maintaining React's declarative structure.

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)

type TweenConfig = {
	time: number,
	easingStyle: Enum.EasingStyle,
	easingDirection: Enum.EasingDirection,
}

local function useTweenBinding(targetValue: number, config: TweenConfig): React.Binding<number>
	local binding, setBinding = React.useBinding(targetValue)
	
	-- Use a dummy object to host the tweenable property
	local internalValue = React.useMemo(function()
		return Instance.new("NumberValue")
	end, {})

	React.useEffect(function()
		internalValue.Value = binding:getValue()
		
		local tween = TweenService:Create(internalValue, TweenInfo.new(
			config.time,
			config.easingStyle,
			config.easingDirection
		), { Value = targetValue })

		-- Update the binding on every frame while the tween is running
		local connection = RunService.Heartbeat:Connect(function()
			setBinding(internalValue.Value)
		end)

		tween:Play()

		return function()
			tween:Cancel()
			connection:Disconnect()
		end
	end, { targetValue, config.time, config.easingStyle, config.easingDirection } :: { any })

	return binding
end

-- Usage Example
local function TweenButton()
	local isHovered, setHovered = React.useState(false)
	local scale = useTweenBinding(if isHovered then 1.2 else 1, {
		time = 0.5,
		easingStyle = Enum.EasingStyle.Elastic,
		easingDirection = Enum.EasingDirection.Out,
	})

	return React.createElement("TextButton", {
		Size = scale:map(function(v: number)
			return UDim2.fromScale(v * 0.2, v * 0.1)
		end),
		Text = "Hover Me",
		[React.Event.MouseEnter] = function() setHovered(true) end,
		[React.Event.MouseLeave] = function() setHovered(false) end,
	})
end
```

## 2. Heartbeat + Binding (usePulse)

Ideal for frame-by-frame animations like sine-wave pulsing for UIStroke glow or constant scaling.

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)

local function usePulse(speed: number, min: number, max: number): React.Binding<number>
	local binding, setBinding = React.useBinding(min)

	React.useEffect(function()
		local startTime = os.clock()
		local connection = RunService.Heartbeat:Connect(function()
			local elapsed = os.clock() - startTime
			local alpha = (math.sin(elapsed * speed) + 1) / 2
			local value = min + (max - min) * alpha
			setBinding(value)
		end)

		return function()
			connection:Disconnect()
		end
	end, { speed, min, max } :: { any })

	return binding
end

-- Usage Example
local function GlowingIcon()
	local transparency = usePulse(5, 0.2, 0.8)

	return React.createElement("ImageLabel", {
		Image = "rbxassetid://123456",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(64, 64),
	}, {
		Glow = React.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 255, 0),
			Transparency = transparency,
			Thickness = 2,
		})
	})
end
```

## 3. react-spring (useSpring, useSprings)

The standard for physics-based animations in Roblox React-Lua projects.

### useSpring (Declarative)
```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactSpring = require(ReplicatedStorage.Packages.ReactSpring)

local function SpringBox()
	local active, setActive = React.useState(false)
	
	local styles = ReactSpring.useSpring({
		to = {
			size = if active then 200 else 100,
			color = if active then Color3.fromRGB(255, 0, 0) else Color3.fromRGB(0, 0, 255),
		},
		config = { tension = 170, friction = 26 }
	})

	return React.createElement("TextButton", {
		Size = styles.size:map(function(v: number) return UDim2.fromOffset(v, v) end),
		BackgroundColor3 = styles.color,
		Text = "Click Me",
		[React.Event.Activated] = function() setActive(not active) end,
	})
end
```

### useSprings (Staggered List)
```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactSpring = require(ReplicatedStorage.Packages.ReactSpring)

local ITEMS = { "Home", "Shop", "Settings" }

local function StaggeredMenu()
	local visible, setVisible = React.useState(false)

	local springs = ReactSpring.useSprings(#ITEMS, function(index: number)
		return {
			to = {
				opacity = if visible then 1 else 0,
				xOffset = if visible then 0 else -50,
			},
			delay = index * 0.1,
			config = ReactSpring.config.gentle,
		}
	end, { visible } :: { any })

	local children = {}
	for i, spring in springs do
		children["Item" .. i] = React.createElement("TextLabel", {
			Text = ITEMS[i],
			TextTransparency = spring.opacity:map(function(v: number) return 1 - v end),
			Position = spring.xOffset:map(function(v: number) return UDim2.new(0, v, 0, (i - 1) * 40) end),
			Size = UDim2.new(1, 0, 0, 30),
		})
	end

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(200, 300),
		BackgroundTransparency = 1,
		[React.Event.Activated] = function() setVisible(not visible) end,
	}, children)
end
```

## 4. Mount/Unmount Animation (useAnimatedMount)

Pattern for handling "Entering" and "Leaving" states before removing a component from the tree.

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

type AnimState = "hidden" | "entering" | "visible" | "leaving"

local function useAnimatedMount(isVisible: boolean, duration: number): (boolean, AnimState)
	local shouldRender, setShouldRender = React.useState(isVisible)
	local animState, setAnimState = React.useState(if isVisible then "visible" else "hidden")

	React.useEffect(function()
		if isVisible then
			setShouldRender(true)
			setAnimState("entering")
			-- Small delay to allow "entering" state to be processed before "visible"
			local thread = task.delay(0.03, function()
				setAnimState("visible")
			end)
			return function()
				task.cancel(thread)
			end
		else
			setAnimState("leaving")
			local thread = task.delay(duration, function()
				setAnimState("hidden")
				setShouldRender(false)
			end)
			return function()
				task.cancel(thread)
			end
		end
	end, { isVisible, duration } :: { any })

	return shouldRender, animState
end

-- Usage Example
local function Modal({ isVisible }: { isVisible: boolean })
	local shouldRender, animState = useAnimatedMount(isVisible, 0.3)

	if not shouldRender then return nil end

	return React.createElement("Frame", {
		BackgroundTransparency = if animState == "visible" then 0.5 else 1,
		Size = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})
end
```

## 5. joinBindings

Combines multiple bindings into a single derived value. Useful for X/Y coordinate synchronization.

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function Joystick()
	local x, setX = React.useBinding(0)
	local y, setY = React.useBinding(0)

	-- Combine X and Y bindings into a single UDim2 binding
	local position = React.joinBindings({ x = x, y = y }):map(function(values: { x: number, y: number })
		return UDim2.fromOffset(values.x, values.y)
	end)

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(100, 100),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	}, {
		Knob = React.createElement("Frame", {
			Size = UDim2.fromOffset(20, 20),
			Position = position,
			BackgroundColor3 = Color3.fromRGB(200, 200, 200),
		})
	})
end
```

## 6. Binding.map()

Transforms a raw animation value into a UI property.

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function HealthBar({ healthAlpha }: { healthAlpha: number })
	local binding, setBinding = React.useBinding(healthAlpha)

	React.useEffect(function()
		setBinding(healthAlpha)
	end, { healthAlpha } :: { any })

	return React.createElement("Frame", {
		Name = "Background",
		Size = UDim2.new(0, 200, 0, 20),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	}, {
		Fill = React.createElement("Frame", {
			Name = "Fill",
			-- Number -> UDim2 mapping
			Size = binding:map(function(v: number)
				return UDim2.fromScale(v, 1)
			end),
			-- Number -> Color3 mapping (Red to Green)
			BackgroundColor3 = binding:map(function(v: number)
				return Color3.new(1 - v, v, 0)
			end),
		})
	})
end
```

### Pitfalls & Warnings
- **Binding vs State**: Always prefer Bindings for high-frequency updates (animations). Updating State triggers a full component re-render, which is expensive and can cause stuttering.
- **Cleanup**: Always disconnect `RunService` connections and cancel Tweens/Tasks in the `useEffect` cleanup function to prevent memory leaks and unexpected behavior.
- **Binding.map() Performance**: Keep the mapping function lightweight. It runs every time the binding value changes (potentially 60+ times per second).
- **Initial Values**: Ensure bindings are initialized with a sensible default value to avoid layout jumps on the first frame.
