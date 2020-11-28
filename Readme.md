# Kill History (`deathlist`)

A mod displaying a colored list of recent kills/deaths and the causes(killer, used item).

## About

Depends on [`modlib`](https://github.com/appgurueu/modlib) and `fire`.
**Note: If there are other mods registering `on_punchplayer` or `on_hp_change` handlers, add them to the dependency list to make sure they execute before `deathlist`.**
Licensed under MIT.

## Screenshot

![Screenshot](https://raw.githubusercontent.com/appgurueu/deathlist/master/screenshot.png)

## API

`deathlist` provides a few internal functions, but the most common way to trigger a custom message is passing a custom type to `set_hp`:

```lua
-- example, kills player
player:set_hp(0, {
    -- killer, required
    killer = {
        -- name, required
        name = "singleplayer",
        -- color, optional integer, will be completed if valid playername
        color = 0xFFFFFF
    },
    -- method, required
    method = {
        -- image of used method, required
        image = "blank.png",
        -- name for logging, optional
        name = "blank"
    }
    -- victim, optional overrides
    victim = {
        -- name, optional
        name = "singleplayer",
        -- color, optional
        color = 0xFFFFFF
    }
})
```

## Configuration

### Default Configuration

```json
{
  "max_messages":5,
  "mode":"list",
  "autoremove_interval":30,
  "hud_pos":{"x":0.75,"y":1},
  "hud_base_offset": {"x":0,"y":-122},
  "enable_environmental": true,
  "enable_unknown": false,
  "enable_forbidden_playernames": true,
  "environmental_reasons": {
    "falling":{
      "name":"Falling",
      "color":{"r": 255, "g": 255, "b":  255},
      "method":"deathlist_tombstone.png"
    },
    "unknown":{
      "name":"Something",
      "color":{"r": 255, "g": 255, "b":  255},
      "method":"deathlist_tombstone.png"
    },
    "drowning":{
      "color":{"r": 105, "g": 201, "b":  231},
      "method":"bubble.png",
      "nodes": {
        "default:water_flowing" : { "name" : "Water" }
      }
    },
    "node_damage":{
      "color":{"r": 255, "g": 255, "b":  255},
      "method":"generate",
      "nodes": {
        "default:lava_flowing" : { "name" : "Lava", "color" : {"r": 244, "g": 114, "b": 9}, "method" : "fire_basic_flame.png" },
        "default:lava_source" : { "color" : {"r": 244, "g": 114, "b": 9}, "method" : "fire_basic_flame.png" }
      }
    }
  }
}
```

### Usage

#### `max_messages`

Maximum amount of messages to be displayed. Number > 0.

#### `mode`

String, either `"stack"` or `"list"`. Specifies message orientation. A stack means that the most recent message is always on the top, while list means exactly the opposite.

#### `autoremove_interval`

Can be set to `false` or a positive number in seconds. Specifies how often messages are removed despite having enough space left for the purpose of not cluttering the HUD.

#### `hud_pos`

X- and Y-Coordinate, numbers, position on HUD.

#### `hud_base_offset`

X- and Y-Offset, numbers in pixels(?).

#### `enable_environmental`

Boolean, whether to enable environmental reasons inside kill history.

#### `enable_unknown`

Boolean, whether to enable unknown (none of `falling`, `drowning` or `node_damage`) reasons inside kill history.

#### `enable_forbidden_playernames`

Boolean, whether to disallow certain playernames in order to reduce confusion(such as "Lava", "Water", "Falling" or "Something")

#### `environmental_reasons`

Table/Dictionairy of possible deaths due to environment.

##### Basic structure of a kill message

* `name` of killing thing, colorized using a `color`(table/dictionairy, r/g/b)
* `method` used by the killing thing, a texture. If `"generate"` is specified and a node is responsible, the node texture will be used.

##### `falling` / `unknown`

Player died through falling or an unknown reason; no node responsible. One definition of `name`, `color` and `method`.

##### `drowning` / `node_damage`

Player died by drowning node or by taking node damage. A node *must* be responsible.
Using the `nodes` table/dictionairy, you can specify overrides for each specific node concerning `name`, `color`, and `method`. If not specified, default values are taken.