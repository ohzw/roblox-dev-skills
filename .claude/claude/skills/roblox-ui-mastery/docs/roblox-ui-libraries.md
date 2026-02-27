# Roblox UI Libraries & Frameworks Reference

This document provides a comparison of UI frameworks, animation libraries, and utility tools available for Roblox development as of 2025.

## 1. UI Frameworks Comparison

| Framework | Stars | Status | Key Feature |
|-----------|-------|--------|-------------|
| **React-Lua** (jsdotlua/react) | ~600 | Active | React 17+ port, hooks, familiar API |
| **Fusion 0.3** (dphfox/Fusion) | ~400 | Active | Built-in Spring, reactive state |
| **Vide** (centau-ri/vide) | ~200 | Active | SolidJS-like, no virtual DOM, fastest |
| **Rex** | New 2025 | Experimental | Reactive framework |

### React-Lua
- **Description**: A comprehensive port of React 17 to Luau. It supports functional components, hooks (`useState`, `useEffect`, `useMemo`), and a virtual DOM.
- **When to use**: Large-scale projects requiring complex state management and component reusability. Ideal for teams coming from web development.
- **When NOT to use**: Extremely simple UIs where the overhead of a virtual DOM might be unnecessary, or if you prefer a more "native" Luau feel.

### Fusion 0.3
- **Description**: A reactive UI library designed specifically for Luau. It uses "State" objects and "Computed" values to update the UI without a virtual DOM.
- **When to use**: Projects that prioritize performance and want built-in spring physics and clean Luau syntax.
- **When NOT to use**: If your project is already heavily invested in the React ecosystem or requires specific React-only libraries.

### Vide
- **Description**: A reactive library inspired by SolidJS. It focuses on extreme performance by eliminating the virtual DOM and using fine-grained reactivity.
- **When to use**: Performance-critical UIs where every millisecond counts.
- **When NOT to use**: If you need a mature ecosystem or extensive documentation, as it is newer and more experimental.

### Rex
- **Description**: A new reactive framework emerging in 2025, aiming to provide a modern, high-performance alternative for Luau UI.
- **When to use**: Experimental projects or for developers wanting to stay on the bleeding edge.
- **When NOT to use**: Production environments where stability is paramount.

---

## 2. Animation Libraries

| Library | Spring Physics | React Integration | Stagger | Wally |
|---------|----------------|-------------------|---------|-------|
| **react-spring** | ✅ Yes | ✅ Native | ✅ Yes | ✅ Yes |
| **Flipper** | ✅ Yes | ❌ No | ❌ No | ✅ Yes |
| **Otter** | ✅ Yes | ⚠️ Partial | ❌ No | ✅ Yes |
| **TweenService** | ❌ No | ❌ No | ❌ No | ❌ Native |

### react-spring (chriscerie/react-spring)
- **Description**: A spring-physics based animation library. Provides `useSpring`, `useSprings`, and `useTrail` hooks.
- **Best for**: React-Lua projects. It is the standard for high-quality, interruptible animations in the React-Lua ecosystem.

### Flipper
- **Description**: A standalone motor/spring library. It is framework-independent and manages values over time using physical forces.
- **Best for**: Vanilla Luau projects or custom UI systems that don't use React.

### Otter (jsdotlua/otter)
- **Description**: A spring animation library developed by the same team as React-Lua. It is used internally at Roblox for various UI elements.
- **Best for**: Projects looking for a lightweight, Roblox-official spring solution.

### TweenService (Native)
- **Description**: The built-in Roblox service for interpolating properties.
- **Best for**: Simple A→B transitions where spring physics are not required. It is engine-optimized but lacks the "juice" of physics-based animations.

---

## 3. Utility Libraries

### TopbarPlus (1ForeverHD)
- **Description**: A powerful library for creating custom topbar icons and menus that integrate seamlessly with the Roblox topbar.
- **Common Use**: Displaying persistent UI indicators like coins, mute toggles, or player status.

### UI Labs (pepeeltoro41/ui-labs)
- **Description**: A Storybook-like plugin for Roblox Studio. It allows developers to preview and test UI components in isolation without starting a playtest.
- **Benefit**: Significantly speeds up UI iteration and ensures components work across different screen sizes.

---

## 4. 2025 New Roblox Features

| Feature | Description | Status | Notes |
|---------|-------------|--------|-------|
| **UI Styling System** | Native StyleSheet support with tokens and theme switching. | Full Release (Jan 2025) | Can simplify custom DesignSystem modules. |
| **EditableImage** | Allows dynamic pixel-level drawing and manipulation. | Active | Potential for dynamic UI effects. |
| **UIDragDetector** | Native support for dragging UI elements. | Active | Useful for inventory or shop UI. |
| **UIListLayout Flex** | CSS Flexbox equivalent for UI layouts. | Active | Simplifies complex responsive layouts. |
| **Path2D** | Native vector path drawing support. | Active | Good for custom shapes and progress bars. |

---

## 5. Recommended Stack

### Core Stack
- **Framework**: React-Lua
- **Animation**: react-spring
- **Utilities**: TopbarPlus (for custom topbar icons/menus)
- **Styling**: Custom `DesignSystem` module + design tokens

### Recommended Additions
- **UI Labs**: Integrate for component-driven development and faster UI iteration.
- **react-error-boundary**: Add to wrap major UI sections to prevent a single component error from crashing the entire HUD.
- **UIListLayout Flex**: Adopt for new UI components to improve responsiveness.

### Framework Migration Considerations
- **Switching to Fusion/Vide**: Only consider if starting a new project or if React-Lua's overhead is a measured bottleneck. Migration from React-Lua carries significant refactor cost for large existing codebases. React-Lua remains the most stable and well-supported choice for projects already using it.
