# Spatial Patterns

When building complex objects (multi-call or >5 parts), use these patterns to maintain spatial consistency and prevent coordinate drift.

## 1. Geometric Manifest Header

At the start of your script, declare all dimensions as named variables. Do NOT use magic numbers in the instantiation code.

```lua
-- 1. Geometric Manifest
local DeskDef = {
    Width = 6.0,
    Depth = 3.0,
    Height = 2.8,
    TopThickness = 0.2,
    LegSize = 0.3,
    LegOffset = 0.1 -- Inset from edges
}
```

## 2. Relative Positioning (The Anchor Pattern)

Choose one part to be the structural anchor (usually the largest central piece or the base). Calculate all other positions relative to this anchor's `CFrame`.

```lua
-- 2. Anchor Part
local top = Instance.new("Part")
top.Size = Vector3.new(DeskDef.Width, DeskDef.TopThickness, DeskDef.Depth)
-- Position the top so the desk sits flush on the floor (Y=0)
top.Position = Vector3.new(0, DeskDef.Height - (DeskDef.TopThickness/2), 0)

-- 3. Relative Sub-components
local legHeight = DeskDef.Height - DeskDef.TopThickness
local leg = Instance.new("Part")
leg.Size = Vector3.new(DeskDef.LegSize, legHeight, DeskDef.LegSize)

-- Calculate position relative to the Top's CFrame
local offsetX = (DeskDef.Width/2) - (DeskDef.LegSize/2) - DeskDef.LegOffset
local offsetZ = (DeskDef.Depth/2) - (DeskDef.LegSize/2) - DeskDef.LegOffset
local offsetY = -(DeskDef.TopThickness/2) - (legHeight/2)

leg.CFrame = top.CFrame * CFrame.new(offsetX, offsetY, offsetZ)
```

## 3. Integer/Fractional Grid

Snap all dimensions in your manifest to a consistent grid (e.g., multiples of 0.125, 0.25, or 0.5 studs).
Avoid arbitrary decimals like `0.333333` or `1.17`, as these compound into visible gaps when parts are aligned.
