# fitness_system

> **Demo Resource** — This is a portfolio/code sample intended to demonstrate architecture, code quality, and FiveM/ESX development practices. It is not a production-ready feature release. The focus was mainly on Backend / Logic. UI is just a simplified version

---

## What it does

Players train at stations placed in the world (dumbbells, bench press, pull-ups, sit-ups). Each session awards XP toward two stats: **Stamina** and **Strength**. Reaching enough XP advances the player to the next level, up to a configured cap.

- **Stamina** has a real effect: higher levels passively restore stamina faster via `RestorePlayerStamina`
- **Strength** is tracked and levelled but has no gameplay effect in this demo
- Stats are persisted per player in the database and visible via `/fitness`

---

## Architecture

The resource follows a layered architecture:

```
shared/
  helpers.lua          # Shared logic accessible on both client and server
  class_types.lua      # EmmyLua type definitions for all data structures
  config.lua           # All configuration (training spots, XP tables, cooldowns)

server/
  fitness_repository.lua   # Database layer only — no business logic
  fitness_service.lua      # Business logic, cooldown management, XP calculation
  fitness_events.lua       # Net event handlers — thin wiring layer only

client/
  main.lua             # Player stat state management
  stamina.lua          # Stamina effect thread
  training.lua         # Training loop, animations, server interaction
  nui.lua              # NUI messaging and command registration

web/
  index.html / style.css / script.js   # NUI frontend
```
---

## What a production version would add

- Strength gameplay effect (melee modifier, carry weight, etc.)
- Server-side player stats cache to reduce DB reads
- DB migration versioning for schema updates
- Anticheat punishment for Networking Exploits