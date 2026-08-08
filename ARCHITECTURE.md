# Hellscape prototype architecture

The project is intentionally split by responsibility. Keep gameplay rules out of
visual/UI scripts and keep actors independent from the level layout.

```text
main.gd                 Scene coordinator, spawning, and progression state
player.gd               Player movement, camera, combat input, health
enemy.gd                Melee enemy behavior
ranged_enemy.gd         Ranged enemy behavior and projectiles
ally.gd                 Companion follow and support behavior
projectile.gd           Projectile movement and hit detection
player.tscn              Reusable player scene
ally.tscn                Reusable companion scene
melee_enemy.tscn         Reusable melee enemy scene
ranged_enemy.tscn        Reusable ranged enemy scene
projectile.tscn          Reusable projectile scene
mobile_controls.gd      Touch input and touch-only presentation
ui/
└── game_hud.gd         HUD state and presentation
systems/
├── actor_factory.gd    Centralized actor construction
└── feedback_audio.gd   Runtime placeholder sound generation
data/
├── character_data.gd   Shared character-stat resource type
└── default_character.tres Prototype fighter configuration
components/
├── damage_info.gd      Attack payload
└── damageable.gd       Shared health and death handling
level/
└── graybox_level.gd    Static geometry, checkpoints, and exit trigger
```

## Responsibility rules

- `main.gd` owns composition, level progression, spawning, and signals between
  systems. It should not contain reusable actor behavior or level geometry.
- Actor scripts own their movement, combat behavior, and local presentation.
  They communicate with the coordinator through simple methods such as
  `take_damage()` and `enemy_defeated()`.
- `systems/actor_factory.gd` owns construction and visual/collision setup for
  actors. New variants should be added there or promoted to `.tscn` scenes,
  rather than duplicating setup in `main.gd`.
- UI scripts should emit intent (`attack_pressed`, `movement_changed`) rather
  than directly changing gameplay state.
- `ui/game_hud.gd` owns HUD labels and completion presentation. Gameplay code
  sends status updates through its small public API.
- Character balance belongs in `data/*.tres` resources. The player controller
  reads movement, survivability, energy, and ability values from its assigned
  resource, so new characters can reuse the controller with different data.
- Attackers detect hits and send `DamageInfo`; targets expose `take_damage()`
  and delegate health/death behavior to `Damageable`. Targets never poll for
  incoming attacks.
- Procedural graybox construction lives in `level/graybox_level.gd`; replace
  this builder with authored `.tscn` scenes when the layout stabilizes.
- Placeholder audio is isolated behind `FeedbackAudio`; replacing generated
  tones with imported sound assets should not require changes to actors.

## Change guidelines

1. Add new abilities to the player or a dedicated ability component, not to the
   level coordinator.
2. Add enemy variants as separate scripts or scenes instead of adding branches
   to `enemy.gd`.
3. Use signals for UI updates and progression events when a system grows.
4. Prefer `.tscn` scenes for stable actors once their graybox behavior settles.
5. Keep platform-specific input in `mobile_controls.gd` and map desktop input
   through the same player methods.
