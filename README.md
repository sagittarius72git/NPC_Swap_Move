# Swap Places by Default

Move into an allied NPC and you **swap places** with them instead of opening the menu (costs 200 moves).

- To get the usual menu, choose "Open the NPC menu next time" from the action menu, then interact with the NPC (move into them, or examine them with `E`).
- No swap happens, and the game's menu opens, if the NPC isn't an ally or is asleep, either of you is mounted, the NPC isn't adjacent, there's a trap on their tile, either tile is on a vehicle, or you are auto-moving.

## Settings

`mod.cfg` at the top of `main.lua` sets the move cost (`move_cost`), whether only allies swap (`require_ally`), whether to avoid traps and vehicles (`avoid_traps` / `avoid_vehicles`), and more. Changes apply mid-game with **Reload Lua Code** in the debug menu.

## Notes

- **Requires a Lua-enabled build** (`lua_api_version: 2`).
- You can add or remove it in an existing world. It writes nothing to your save.
- The "next time" switch isn't saved; it resets when you load the game.

## Credits

Author: sagittarius72. This mod was made with the help of Claude (Anthropic).
