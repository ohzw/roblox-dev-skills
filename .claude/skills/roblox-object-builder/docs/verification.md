# Post-Build Verification Template

Automated checks to run before reporting any build as complete.
Run as ONE `run_code` call at the end of every build, regardless of project strategy or scale.

## Checklist

1. **Absolute position check**: Model center within 2 studs of target. Drift > 10 = coordinate system offset.
2. **Workspace cutter scan**: Find leaked cutter parts near build site (parented to workspace, not model).
3. **Orientation audit**: Check LookVector of orientable parts. Auto-fix by rotating CFrame.
4. **Overlap detection**: For items on shared surface planes, check pairwise bounding box intersections.
5. **Anchor check**: All parts `Anchored = true`.
6. **Count verification**: Print part counts by prefix category.

## Template Code

Customize `TARGET`, model name, and orientation checks per build:

```lua
local model = workspace:FindFirstChild("MyModel")
local TARGET = Vector3.new(TARGET_X, 0, TARGET_Z)

-- 1. Absolute position check
local center = model:GetPivot().Position
local drift = (Vector3.new(center.X, 0, center.Z) - TARGET).Magnitude
print("Model center: " .. string.format("(%.1f, %.1f, %.1f)", center.X, center.Y, center.Z))
if drift > 2 then
    print("WARNING: drift = " .. string.format("%.1f", drift) .. " studs from target")
end

-- 2. Workspace cutter scan
for _, child in ipairs(workspace:GetChildren()) do
    if child:IsA("BasePart") and not child:IsDescendantOf(model) then
        if (child.Position - TARGET).Magnitude < 40 then
            print("LEAKED PART: " .. child.Name)
        end
    end
end

-- 3. Orientation check (customize per build)
-- Example: verify monitor faces -Z
local monitor = model:FindFirstChild("Monitor_Bezel")
if monitor and monitor.CFrame.LookVector.Z > -0.5 then
    monitor.CFrame = CFrame.new(monitor.Position) * CFrame.Angles(0, math.pi, 0)
    print("FIXED: Monitor_Bezel orientation")
end

-- 4. Surface overlap detection
-- Collect items within 2 studs of shared surface Y, check pairwise XZ bounds

-- 5. Anchor check + 6. Count verification
local counts = {}
for _, part in ipairs(model:GetDescendants()) do
    if part:IsA("BasePart") then
        if not part.Anchored then
            part.Anchored = true
            print("FIXED anchor: " .. part.Name)
        end
        local prefix = part.Name:match("^(%a+)") or "Other"
        counts[prefix] = (counts[prefix] or 0) + 1
    end
end
for prefix, count in pairs(counts) do
    print(prefix .. ": " .. tostring(count))
end
```
