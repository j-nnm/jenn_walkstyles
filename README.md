# jenn_walkstyles

Walking Styles with **KVP Persistence** & **Statebag Sync** for RedM.

A RedM port of [xt-walkingstyles](https://github.com/xT-Development/xt-walkingstyles).

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)

## Features

- ✅ **KVP Persistence** - Walk styles saved client-side, survives restarts
- ✅ **Statebag Sync** - Other players see your walk style
- ✅ **Per-Character Storage** - Each character can have their own walk style
- ✅ **No Database** - Zero SQL, zero server-side storage
- ✅ **Export API** - Easy integration with other scripts

## Commands

| Command | Description |
|---------|-------------|
| `/walkstyle` | Open the walk style menu |
| `/resetwalk` | Reset to default walk style |
| `/setwalk [number]` | Set walk style by number (no menu) |

## Exports

```lua
exports['jenn_walkstyles']:SetWalkStyle(style)
exports['jenn_walkstyles']:GetWalkStyle()
exports['jenn_walkstyles']:ResetWalkStyle()
exports['jenn_walkstyles']:OpenMenu()
```

## Credits

- Persistence approach from [xt-walkingstyles](https://github.com/xT-Development/xt-walkingstyles) by xT-Development