\# Mutant Reign - 2D Strategic Game



\## Game Overview

Mutant Reign is a \*\*2D top-down strategic management game\*\* set on the ruined supercontinent of Gressta. You lead a mobile faction from your DNA-locked Bus, managing economics, diplomacy, territory, and combat through strategic decision-making and auto-resolved battles.



\## Core Pillars

1\. \*\*Commander mindset\*\* - Strategic planning and logistics matter

2\. \*\*Relationships\*\* - Leaders remember aid and betrayal

3\. \*\*Logistics\*\* - Supply, upkeep, and trade routes decide success

4\. \*\*Focused scale\*\* - 15-20 locations with depth over breadth



\## Critical Development Rules



\### ALWAYS Use Godot 4.5 Stable Syntax

\- ✅ `@export`, `@onready`, `@export\_group`

\- ✅ `class\_name` for all reusable scripts (never use preload for scripts)

\- ✅ Typed variables: `var health: int = 100`

\- ✅ Signal syntax: `signal player\_died`, `enemy\_defeated.emit()`

\- ✅ `get\_node()` or `$NodeName` (both valid in 4.5)

\- ✅ `CharacterBody2D.velocity` (not `.move\_and\_slide()` with argument)

\- ✅ `Input.get\_vector()` for 2D movement

\- ❌ NEVER use Godot 3.x syntax - if unsure, verify against Godot 4.5 docs



\### Prefer class\_name Over preload()

\*\*Why:\*\* Future-proofing, clean refactoring, global accessibility, type safety

```gdscript

\# ✅ CORRECT - Use class\_name

class\_name Hub

extends Node2D



\# ✅ CORRECT - Reference the class

var hub: Hub = Hub.new()



\# ❌ WRONG - Don't preload scripts

var hub = preload("res://Hub/Hub.gd").new()



\# ✅ Exception: PackedScenes still need preload

@export var caravan\_scene: PackedScene = preload("res://Actors/Caravan.tscn")

```



\### Always Use Typed Variables

```gdscript

\# ✅ CORRECT

var health: int = 100

var player: CharacterBody2D

var items: Array\[StringName] = \[]

var state: HubStates



\# ❌ WRONG - No type hints

var health = 100

var player

var items = \[]

```



\## Project Architecture



\### Folder Structure (Sort-by-Feature)

```

mutanic-reign/

├── Actors/

│   ├── Bus.tscn / bus.gd (class\_name Bus)

│   ├── Caravan.tscn / Caravan.gd (class\_name Caravan)

│   └── PlayerCamera.tscn

├── Buildings/

│   ├── ProducerBuilding.gd (class\_name ProducerBuilding) - BASE CLASS

│   ├── ProcessorBuilding.gd (class\_name ProcessorBuilding) - BASE CLASS

│   ├── WheatFarm.tscn / WheatFarm.gd (extends ProducerBuilding)

│   ├── FishFarm.gd (extends ProducerBuilding)

│   ├── StoneQuarry.tscn

│   └── Bakery.tscn (processor)

├── Hub/

│   ├── Hub.tscn / Hub.gd (class\_name Hub)

│   ├── ClickAndFade.gd (class\_name ClickAndFade)

│   └── BuildSlots.gd (class\_name BuildSlots)

├── Economy/

│   ├── HubEconomy.gd (class\_name HubEconomy)

│   ├── EconomyConfig.gd (class\_name EconomyConfig)

│   └── InventoryUtil.gd (static utility class)

├── data/

│   ├── HubState.gd (class\_name HubStates) - Resource

│   ├── BuildSlotState.gd (class\_name BuildSlotState) - Resource

│   ├── CaravanState.gd (class\_name CaravanState) - Resource

│   ├── Items/ItemsCatalog.tres (ItemDB Resource)

│   └── Hubs/ (Oakmill.tres, Stonegrove.tres)

├── Singletons/ (Autoloads)

│   ├── Timekeeper.gd (controls game time)

│   └── EventBus.gd (global events - if needed)

└── overworld.tscn / overworld.gd (main scene)

```



\### Key Patterns



\#### 1. Resource-Based Configuration

All persistent data uses Resources (.tres files):

```gdscript

\# HubStates.gd

extends Resource

class\_name HubStates



@export var hub\_id: StringName

@export var display\_name: String = "Settlement"

@export var money: int = 0

@export var inventory: Dictionary = {}

@export var base\_population\_cap: int = 100

```



\#### 2. Engine Separation Pattern

Separate \*\*presentation\*\* (Hub.gd) from \*\*logic\*\* (HubEconomy.gd):

```gdscript

\# Hub.gd - Presentation layer

class\_name Hub

extends Node2D



var \_engine: HubEconomy = HubEconomy.new()



func \_on\_timekeeper\_tick(dt: float) -> void:

&nbsp;   var result: Dictionary = \_engine.tick(dt, cap, state.inventory, buildings)

&nbsp;   \_apply\_inventory\_delta(result.get("delta", {}))

```

```gdscript

\# HubEconomy.gd - Pure logic, no scene dependencies

class\_name HubEconomy

extends RefCounted



func tick(dt: float, cap: int, inventory: Dictionary, buildings: Array\[Node]) -> Dictionary:

&nbsp;   # Pure calculation, returns data only

&nbsp;   return {"delta": {}, "food\_level": 0.0}

```



\#### 3. Inheritance for Buildings

```gdscript

\# ProducerBuilding.gd - BASE CLASS

class\_name ProducerBuilding

extends Node2D



@export var product\_item\_id: StringName = StringName()

@export var base\_amount\_per\_tick: float = 0.5

@export var level: int = 1



func produce\_tick() -> Dictionary:

&nbsp;   if not enabled or product\_item\_id == StringName():

&nbsp;       return {}

&nbsp;   var mult: float = pow(1.5, float(level - 1))

&nbsp;   return {product\_item\_id: base\_amount\_per\_tick \* mult}

```

```gdscript

\# WheatFarm.gd - SPECIFIC BUILDING

class\_name WheatFarm

extends ProducerBuilding



func \_ready() -> void:

&nbsp;   product\_item\_id = \&"Wheat"

&nbsp;   super.\_ready()

```



\## Game Systems



\### 1. Timekeeper System (Autoload)

The Timekeeper singleton controls ALL game time:

```gdscript

\# Timekeeper.gd (Autoload as /root/Timekeeper)

signal tick(dt: float)



var game\_time: float = 0.0

var time\_scale: float = 1.0

var is\_paused: bool = false



func \_process(delta: float) -> void:

&nbsp;   if is\_paused:

&nbsp;       return

&nbsp;   var dt: float = delta \* time\_scale

&nbsp;   game\_time += dt

&nbsp;   tick.emit(dt)

```



\*\*CRITICAL:\*\* Time only advances when Bus is moving. When Bus stops, pause Timekeeper.



\### 2. Hub Economy System

Three-stage pipeline:

1\. \*\*Producers\*\* → Generate raw goods (WheatFarm produces Wheat)

2\. \*\*Processors\*\* → Refine goods (Bakery: Wheat → Bread)

3\. \*\*Consumption\*\* → Population consumes food and infrastructure

```gdscript

\# Economy tick flow

func \_on\_timekeeper\_tick(dt: float) -> void:

&nbsp;   var buildings: Array\[Node] = slots.iter\_buildings()

&nbsp;   var result: Dictionary = \_engine.tick(dt, population\_cap, state.inventory, buildings)

&nbsp;   

&nbsp;   # Update inventory with production/consumption

&nbsp;   \_apply\_inventory\_delta(result\["delta"])

&nbsp;   

&nbsp;   # Update surplus/deficit levels

&nbsp;   food\_level = result\["food\_level"]

&nbsp;   infrastructure\_level = result\["infrastructure\_level"]

```



\### 3. Caravan Trading System

Caravans are autonomous agents that:

\- Spawn from hubs with surplus goods

\- Navigate using Navigation2D to other hubs

\- Buy/sell goods based on supply/demand

\- Can be taxed, protected, or raided by player

\- Use threshold multipliers to prevent spawn spam

```gdscript

\# Caravan spawning logic

func \_check\_caravan\_spawns(all\_hubs: Array\[Hub]) -> void:

&nbsp;   for home\_hub in all\_hubs:

&nbsp;       for caravan\_type in caravan\_types:

&nbsp;           var threshold\_mult: float = caravan\_threshold\_multipliers.get(key, 1.0)

&nbsp;           if \_hub\_has\_surplus\_for\_type(home\_hub, caravan\_type, threshold\_mult):

&nbsp;               \_spawn\_caravan(home\_hub, caravan\_type, all\_hubs)

&nbsp;               caravan\_threshold\_multipliers\[key] \*= 1.5  # Increase threshold

```



\### 4. Combat Resolution (Auto-Calculated)

Combat is resolved via stat comparison + dice rolls:

```gdscript

\# Combat resolution (when implemented)

func resolve\_combat(attacker: Army, defender: Army) -> CombatResult:

&nbsp;   # Compare stats, equipment, morale

&nbsp;   var attacker\_strength: float = calculate\_army\_strength(attacker)

&nbsp;   var defender\_strength: float = calculate\_army\_strength(defender)

&nbsp;   

&nbsp;   # Add randomness

&nbsp;   var attacker\_roll: float = randf\_range(0.8, 1.2)

&nbsp;   var defender\_roll: float = randf\_range(0.8, 1.2)

&nbsp;   

&nbsp;   # Determine winner and casualties

&nbsp;   return calculate\_outcome(attacker\_strength \* attacker\_roll, 

&nbsp;                           defender\_strength \* defender\_roll)

```



\### 5. Dynamic Pricing System

Prices adjust based on consumption patterns:

```gdscript

\# Hub.gd

func \_update\_item\_prices() -> void:

&nbsp;   for item\_id: StringName in \_consumption\_ema.keys():

&nbsp;       var consumption\_rate: float = \_consumption\_ema\[item\_id]

&nbsp;       var stock: int = state.inventory.get(item\_id, 0)

&nbsp;       

&nbsp;       # Higher consumption + lower stock = higher price

&nbsp;       var base\_price: float = 100.0

&nbsp;       var price: float = base\_price \* (1.0 + consumption\_rate \* 0.1) \* (1.0 + max(0, 100 - stock) \* 0.01)

&nbsp;       item\_prices\[item\_id] = price

```



\## Performance Targets (2D Overworld)



\### Frame Rate \& Draw Calls

\- \*\*Target:\*\* 60 FPS at 1080p

\- \*\*Max Draw Calls:\*\* ≤300 for 2D overworld

\- \*\*CPU Script Time:\*\* ≤1 ms/frame

\- \*\*Navigation Updates:\*\* Stagger expensive pathfinding across frames



\### Optimization Techniques

1\. \*\*Object Pooling\*\* - Reuse nodes for caravans, UI elements

2\. \*\*Chunk Streaming\*\* - Load/unload map chunks based on camera position

3\. \*\*Batch Rendering\*\* - Use TextureAtlases for icons, use CanvasLayers wisely

4\. \*\*Staggered Updates\*\* - Don't update all caravans every frame

5\. \*\*NavMesh Caching\*\* - Rebuild navigation only when map changes

```gdscript

\# Example: Staggered caravan updates

var \_caravan\_update\_index: int = 0



func \_process(\_delta: float) -> void:

&nbsp;   if active\_caravans.is\_empty():

&nbsp;       return

&nbsp;   

&nbsp;   # Update only 1 caravan per frame

&nbsp;   var caravan: Caravan = active\_caravans\[\_caravan\_update\_index]

&nbsp;   caravan.update\_navigation()

&nbsp;   

&nbsp;   \_caravan\_update\_index = (\_caravan\_update\_index + 1) % active\_caravans.size()

```



\## Code Style \& Best Practices



\### Naming Conventions

```gdscript

\# Classes: PascalCase

class\_name ProducerBuilding



\# Constants: SCREAMING\_SNAKE\_CASE

const MAX\_POPULATION: int = 1000



\# Private variables: \_leading\_underscore

var \_inventory\_float: Dictionary = {}



\# Public variables: snake\_case

var food\_level: float = 0.0



\# Functions: snake\_case

func apply\_inventory\_delta(delta: Dictionary) -> void:

```



\### Signal Usage

```gdscript

\# Define with type hints

signal caravan\_arrived(caravan: Caravan, hub: Hub)

signal resource\_depleted(resource\_id: StringName, hub\_id: StringName)



\# Emit with proper types

caravan\_arrived.emit(my\_caravan, destination\_hub)



\# Connect in \_ready()

func \_ready() -> void:

&nbsp;   caravan.caravan\_arrived.connect(\_on\_caravan\_arrived)



func \_on\_caravan\_arrived(caravan: Caravan, hub: Hub) -> void:

&nbsp;   print("Caravan arrived at %s" % hub.state.display\_name)

```



\### Error Handling

```gdscript

\# Always validate critical references

func \_on\_timekeeper\_tick(dt: float) -> void:

&nbsp;   if slots == null:

&nbsp;       push\_warning("BuildSlots not found on Hub %s" % name)

&nbsp;       return

&nbsp;   

&nbsp;   if state == null:

&nbsp;       push\_error("HubStates is null on Hub %s" % name)

&nbsp;       return

&nbsp;   

&nbsp;   # Safe to proceed

&nbsp;   var buildings: Array\[Node] = slots.iter\_buildings()

```



\### Documentation

```gdscript

\# Document complex functions

\## Spawns a caravan from the home hub with starting money based on population.

\## Returns the spawned Caravan instance or null if spawning failed.

func \_spawn\_caravan(home\_hub: Hub, caravan\_type: CaravanType, all\_hubs: Array\[Hub]) -> Caravan:

&nbsp;   if caravan\_scene == null:

&nbsp;       return null

&nbsp;   

&nbsp;   var caravan: Caravan = caravan\_scene.instantiate() as Caravan

&nbsp;   # ... implementation

```



\## Common Patterns



\### Pattern: StringName for IDs

Use `StringName` for item IDs, hub IDs, etc. for performance:

```gdscript

\# ✅ CORRECT

@export var product\_item\_id: StringName = StringName()

var hub\_id: StringName = \&"oakmill"



\# ❌ WRONG

var product\_item\_id: String = ""

var hub\_id: String = "oakmill"

```



\### Pattern: Dictionary Key Safety

Always cast dictionary keys to proper type:

```gdscript

\# When iterating dictionaries with StringName keys

func \_apply\_delta(delta: Dictionary) -> void:

&nbsp;   for k in delta.keys():

&nbsp;       var key: StringName = (k if k is StringName else StringName(str(k)))

&nbsp;       state.inventory\[key] = state.inventory.get(key, 0) + int(delta\[k])

```



\### Pattern: Node Reference with Validation

```gdscript

\# Use @onready and validate

@onready var slots: BuildSlots = get\_node\_or\_null("BuildSlots") as BuildSlots



func \_ready() -> void:

&nbsp;   if slots == null:

&nbsp;       push\_error("BuildSlots node not found!")

&nbsp;       return

```



\### Pattern: Safe Type Casting

```gdscript

\# Always cast and validate

var caravan: Caravan = caravan\_scene.instantiate() as Caravan

if caravan == null:

&nbsp;   push\_error("Failed to instantiate caravan!")

&nbsp;   return

```



\## Navigation \& Pathfinding



\### Navigation2D Setup

```gdscript

\# Overworld navigation

@onready var nav\_agent: NavigationAgent2D = $NavigationAgent2D



func setup\_navigation(target: Vector2) -> void:

&nbsp;   nav\_agent.target\_position = target



func \_physics\_process(\_delta: float) -> void:

&nbsp;   if nav\_agent.is\_navigation\_finished():

&nbsp;       return

&nbsp;   

&nbsp;   var next\_pos: Vector2 = nav\_agent.get\_next\_path\_position()

&nbsp;   var direction: Vector2 = global\_position.direction\_to(next\_pos)

&nbsp;   velocity = direction \* speed

&nbsp;   move\_and\_slide()

```



\### Pathfinding Best Practices

\- Use `NavigationAgent2D.path\_desired\_distance` to prevent jittering

\- Set `path\_max\_distance` for smoother paths

\- Enable `avoidance\_enabled` for caravan collision avoidance

\- Await navigation ready: `await get\_tree().physics\_frame`



\## Inspector Best Practices



\### Export Groups

```gdscript

@export\_group("Production")

@export var product\_item\_id: StringName = StringName()

@export var base\_amount\_per\_tick: float = 0.5



@export\_group("Economics")

@export var build\_cost: int = 100

@export var build\_time: int = 100



@export\_group("State")

@export var level: int = 1

@export var enabled: bool = true

```



\### Export Hints

```gdscript

@export\_range(0.1, 10.0, 0.1) var speed\_multiplier: float = 1.0

@export\_enum("Food", "Material", "Luxury") var resource\_type: String = "Food"

@export\_file("\*.tres") var config\_path: String = ""

@export\_color\_no\_alpha var faction\_color: Color = Color.WHITE

```



\## Testing \& Debugging



\### Debug Prints

```gdscript

\# Use structured debug output

func \_spawn\_caravan(home\_hub: Hub, caravan\_type: CaravanType) -> void:

&nbsp;   print("\[Caravan System] Spawning %s caravan at %s" % \[caravan\_type.type\_id, home\_hub.name])

&nbsp;   print("    Starting money: %d" % starting\_money)

&nbsp;   print("    Home tax rate: %.1f%%" % (home\_tax\_rate \* 100))

```



\### Performance Monitoring

```gdscript

\# Add performance overlay in debug builds

if OS.is\_debug\_build():

&nbsp;   var perf\_label: Label = Label.new()

&nbsp;   add\_child(perf\_label)

&nbsp;   

&nbsp;   func \_process(\_delta: float) -> void:

&nbsp;       perf\_label.text = "FPS: %d\\nDraw Calls: %d\\nActive Caravans: %d" % \[

&nbsp;           Engine.get\_frames\_per\_second(),

&nbsp;           RenderingServer.get\_rendering\_info(RenderingServer.RENDERING\_INFO\_TOTAL\_DRAW\_CALLS\_IN\_FRAME),

&nbsp;           active\_caravans.size()

&nbsp;       ]

```



\## Forbidden Patterns



\### ❌ Don't Use get\_tree().root

```gdscript

\# ❌ WRONG - Brittle, breaks if hierarchy changes

var hub = get\_tree().root.get\_node("Overworld/Hub")



\# ✅ CORRECT - Use proper references

@export var hub: Hub

```



\### ❌ Don't Use Magic Numbers

```gdscript

\# ❌ WRONG

if food\_level < 50:

&nbsp;   morale -= 10



\# ✅ CORRECT

const LOW\_FOOD\_THRESHOLD: float = 50.0

const MORALE\_PENALTY: float = 10.0



if food\_level < LOW\_FOOD\_THRESHOLD:

&nbsp;   morale -= MORALE\_PENALTY

```



\### ❌ Don't Modify Exported Resources Directly

```gdscript

\# ❌ WRONG - Modifies the .tres file!

economy\_config.servings\_per\_10\_pops = 2.0



\# ✅ CORRECT - Duplicate first

func \_ensure\_unique\_config() -> void:

&nbsp;   if economy\_config.resource\_path != "":

&nbsp;       economy\_config = economy\_config.duplicate(true)

```



\## Git \& Version Control



\### .gitignore Essentials

```

.godot/

.import/

\*.translation

export\_presets.cfg

```



\### Commit Message Style

```

feat: Add caravan threshold multiplier system

fix: Correct inventory delta application for processors

refactor: Separate HubEconomy logic from Hub presentation

perf: Stagger caravan navigation updates

docs: Add BuildSlots API documentation

```



\## Quick Reference



\### Must-Have Autoloads

1\. \*\*Timekeeper\*\* - Controls game time, emits tick signal

2\. \*\*EventBus\*\* - Global events (optional, use sparingly)



\### Common Node Types

\- \*\*CharacterBody2D\*\* - Bus, Caravans (moving entities)

\- \*\*Area2D\*\* - Hub click detection, encounter triggers

\- \*\*NavigationAgent2D\*\* - Pathfinding for bus and caravans

\- \*\*Sprite2D\*\* - Visual representation

\- \*\*CollisionShape2D\*\* - Physics interactions

\- \*\*TileMap\*\* - World map terrain



\### Key Resources

\- \*\*HubStates\*\* - Hub save data

\- \*\*EconomyConfig\*\* - Economy rules

\- \*\*ItemDB\*\* - Item catalog with tags

\- \*\*CaravanType\*\* - Caravan configuration

\- \*\*BuildSlotState\*\* - Building placement data



\## Development Philosophy



1\. \*\*Separation of Concerns\*\* - Logic (RefCounted) separate from Presentation (Node2D)

2\. \*\*Resource-Driven\*\* - Configuration in .tres files, not hardcoded

3\. \*\*Performance-Conscious\*\* - Always consider frame budget

4\. \*\*Type-Safe\*\* - Strong typing prevents bugs

5\. \*\*Future-Proof\*\* - Use class\_name for clean refactoring



\## When in Doubt



1\. Check Godot 4.5 docs: https://docs.godotengine.org/en/4.5/

2\. Verify syntax against uploaded Godot 4.5 guide

3\. Use `class\_name` for scripts, `preload()` only for scenes

4\. Type everything explicitly

5\. Test with performance overlay enabled

6\. Document complex systems with ## comments

7\. DON't OVER DEBUG PRINT INTO THE EDITOR OUPUT BOX

---



\*\*Remember:\*\* This is a strategic management game. Combat is auto-resolved. Focus on economy, logistics, and strategic decision-making. Quality over quantity. Keep systems modular and future-proof.

