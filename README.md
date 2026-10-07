# Swap Places by Default

This mod changes what happens when you move into an allied NPC: instead of opening the menu, you **swap places** with them.
No more opening the menu and pressing "s" every time you pass a companion in a narrow corridor.

## How to use

- **Move into an ally** → you JUST SWAP places on the spot (costs 200 moves).
- **When you want the usual menu** → choose "Open the NPC menu next time" from the action menu,
  then interact with the NPC (move into them, or examine them with `E`) and the usual menu opens.
  You can bind this entry to any key in the keybindings.

## When no swap happens

In any of these cases the mod does nothing and the game's usual menu opens:

- The NPC is not an ally (traders, strangers, etc.), or is asleep
- You or the NPC is mounted
- The NPC is not adjacent (e.g. when you use `E` on someone farther away)
- There is a trap on the NPC's tile
- Either tile is on a boardable vehicle
- You are auto-moving

Traps and vehicles are avoided for safety. The game's own "Swap positions" asks for confirmation about dangers before swapping,
but that check can't be called from Lua. There is also no Lua function to set an NPC's boarded state,
so swapping on a vehicle can't be handled correctly. In both cases the mod avoids the problem by opening the menu instead of swapping.

## Settings

Edit `mod.cfg` at the top of `main.lua`. If you edit it while playing,
run **Reload Lua Code** from the debug menu to apply the change right away.

```lua
mod.cfg = {
  move_cost = 200,      
  require_ally = true,  
  avoid_traps = true,
  avoid_vehicles = true,
  announce = true,
  debug = false,
}
```

## Notes

- **Requires a Lua-enabled build** (`lua_api_version: 2`). The official Windows release supports it.
- You can add or remove this mod in an existing world at any time. It writes nothing to your save.
- The "next time" switch is not saved. It is reset when you load the game again.
