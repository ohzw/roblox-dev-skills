-- Roblox Object Validation Script
-- Usage: Execute this script via mcp__roblox__run_code after completing a build.

local TARGET_MODEL_NAME = "YourModelNameHere" -- AI: Update this before running

local model = workspace:FindFirstChild(TARGET_MODEL_NAME)
if not model then
    print("[ERROR] Model '" .. TARGET_MODEL_NAME .. "' not found in workspace.")
    return
end

local errors = 0
local warnings = 0
local partCount = 0

print("--- Validating Model: " .. TARGET_MODEL_NAME .. " ---")

-- 1. Check Model Hierarchy & Types
for _, desc in ipairs(model:GetDescendants()) do
    if desc:IsA("BasePart") then
        partCount = partCount + 1
        
        -- 2. Anchored Check
        if not desc.Anchored then
            print("[ERROR] Part '" .. desc.Name .. "' is not Anchored.")
            errors = errors + 1
        end
        
        -- 3. Floor Penetration Check (Assuming floor is roughly at Y=0)
        -- Calculates the lowest point of the bounding box
        local lowestPoint = desc.Position.Y - (desc.Size.Y / 2)
        if lowestPoint < -0.1 then
            print("[WARN] Part '" .. desc.Name .. "' penetrates the floor (Lowest Y: " .. math.floor(lowestPoint*100)/100 .. ")")
            warnings = warnings + 1
        end
        
        -- 4. Magic Number Color Check (Default grey)
        if desc.Color == Color3.new(163/255, 162/255, 165/255) and desc.Material == Enum.Material.Plastic then
            print("[WARN] Part '" .. desc.Name .. "' uses default Plastic/Grey color.")
            warnings = warnings + 1
        end
    end
end

if partCount == 0 then
    print("[ERROR] Model contains no BaseParts.")
    errors = errors + 1
end

print("--- Validation Complete ---")
print("Parts: " .. partCount .. " | Errors: " .. errors .. " | Warnings: " .. warnings)

if errors > 0 then
    print("ACTION REQUIRED: You MUST fix the errors above.")
end
