# Kill History(`deathlist`)
A mod displaying a colored list of recent kills/deaths and the causes(killer, used item).

## About

Depends on [`modlib`](https://github.com/appgurueu/modlib) and - depending on your configuration - also other mods. If you use the default configuration, it depends on `default` and `fire`.
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