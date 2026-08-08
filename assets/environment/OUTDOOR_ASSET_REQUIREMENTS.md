# Outdoor environment asset requirements

The current project contains Kenney Factory Kit and City Industrial Kit assets.
Those remain available for later industrial side areas, but the main route now
uses a procedural outdoor foundation so traversal and encounter spacing can be
validated before importing a new pack.

## Required outdoor pack

- Stylized low-poly modular cliff and mountain wall pieces.
- Warm soil or path ground pieces.
- Grass clumps, dry grass, shrubs, and small plants.
- Small rocks and large boulders with simple collision proxies.
- Stone or wooden stair segments and landings.
- Bridges, shrine/checkpoint props, banners, gates, and barricades.
- Side-boss arena dressing and a final boss arena kit.

## Effects and audio

- Portal/rune spawn effect for ambush enemies.
- Dust, projectile trails, hit sparks, and boss telegraphs.
- Wind particles and a looping outdoor wind ambience.
- Portal, sniper warning, wave-clear, boss-phase, and extraction cues.

## Integration rules

- Prefer CC0 packs with a consistent stylized low-poly look.
- Decorative meshes must not define gameplay collision.
- Each imported prop should receive a small authored scene wrapper with explicit
  collision, navigation, and visual children.
- Keep shared materials and texture sizes mobile-friendly.
