# Roblox Model Naming Style

## Core Principles

### Use PascalCase for All Instances
All Roblox instances (objects) MUST use **PascalCase** naming convention.

```lua
-- CORRECT
Workspace.PlayerSpawnPoint
ReplicatedStorage.WeaponModels
ServerStorage.NPCTemplates

-- INCORRECT
workspace.player_spawn_point
ReplicatedStorage.weapon-models
ServerStorage.npc_templates
```

## Naming Rules by Category

### Models
```lua
-- Singular, descriptive names
CarModel
TreeModel
HouseModel
PlayerCharacter
BumperCar
PowerUp

-- Plural for containers
WeaponModels (folder containing multiple weapon models)
NPCModels
EffectModels
```

### Parts
```lua
-- Clear role description
Floor
Wall
Ceiling
Hitbox
SpawnPoint

-- Add number or position for multiples
Wall1, Wall2, Wall3
LeftDoor, RightDoor
FrontWheel, BackWheel
```

### Attachments
```lua
-- Always suffix with "Attachment"
GripAttachment
MuzzleAttachment
HandleAttachment
BarrelAttachment
```

### Folders
```lua
-- Plural to indicate grouping
Weapons
Effects
Tools
NPCs
Buildings

-- Or clear purpose
PlayerData
GameSettings
MapObjects
ArenaElements
```

### MeshParts & Unions
```lua
-- Specific descriptions
CarBody
WheelMesh
GunBarrel
TreeTrunk
BumperFrame
```

## Hierarchy Structure Example

```
Workspace
├── Map
│   ├── Buildings
│   │   ├── House1
│   │   ├── House2
│   │   └── Shop
│   ├── Terrain
│   │   ├── Ground
│   │   └── WaterArea
│   └── SpawnPoints
│       ├── PlayerSpawn1
│       └── PlayerSpawn2
├── Effects
│   ├── ExplosionEffect
│   └── SparkEffect
└── NPCs
    ├── ZombieModel
    └── GuardModel
```

## Anti-Patterns (DO NOT USE)

```lua
-- ❌ Too vague
Part
Model
Thing
Object

-- ❌ Inconsistent casing
player_spawn  -- snake_case
PlayerModel   -- PascalCase
weaponmodel   -- lowercase

-- ❌ Special characters
Player@Spawn
Weapon#1
Model-2023

-- ❌ Default names left unchanged
"Part" (default name)
"Model" (default name)
"   " (empty/whitespace)
```

## Project-Specific Conventions (bumper-battle)

### Game Elements
```lua
-- Core gameplay
BumperCar
Arena
PowerUpModel
ObstacleModel
SpawnPlatform

-- Effects
ExplosionEffect
SparkEffect
TrailEffect
ImpactEffect

-- UI-related models
ShopDisplay
RewardPreview
EffectPreview
```

### Service Organization
```lua
ServerScriptService
├── Services
│   ├── MatchService
│   ├── RewardService
│   └── ShopService

ReplicatedStorage
├── Models
│   ├── BumperCars
│   ├── Effects
│   └── PowerUps
```

## Checklist Before Creating/Renaming Models

- [ ] Uses PascalCase
- [ ] Name is descriptive and specific
- [ ] Consistent with existing naming patterns
- [ ] Not using default names (Part, Model, etc.)
- [ ] No special characters or spaces in inappropriate places
- [ ] Hierarchy is logical and organized

## Team Standards

1. **PascalCase** for all instances
2. **Descriptive** names that explain purpose
3. **Consistency** across the project
4. **Hierarchy** structure for grouping
5. Never leave default names unchanged
6. **Document** any project-specific conventions

These naming conventions improve code readability, maintainability, and team collaboration.
