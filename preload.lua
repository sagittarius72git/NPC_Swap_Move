--[[
  Swap Places by Default - preload.lua

  フックとアクションメニュー項目の登録だけを行う。
  実装は main.lua 側（「Reload Lua Code」で差し替えられるように）。
]]

gdebug.log_info("NSM: preload.")

local mod = game.mod_runtime[game.current_mod]

-- 味方NPCへの接触を横取りする。
-- game::npc_menu() の先頭で呼ばれ、false を返すとメニューが開かない。
game.add_hook("on_try_npc_interaction", function(...)
  if mod.on_try_npc_interaction then
    return mod.on_try_npc_interaction(...)
  end
end)

-- 自動移動の途中で味方が道をふさいだとき（新しい本体だけにあるフック）。
-- 古い本体ではフックが無いので登録しない（登録するとエラーになる）。
if game.hooks and game.hooks["on_auto_move_blocked_by_npc"] then
  game.add_hook("on_auto_move_blocked_by_npc", function(...)
    if mod.on_auto_move_blocked_by_npc then
      mod.on_auto_move_blocked_by_npc(...)
    end
  end)
end

-- 「次の1回だけ、いつものNPCメニューを開く」スイッチ。
-- アクションメニューから選べるほか、キー設定で好きなキーに割り当てられる。
gapi.register_action_menu_entry({
  id = "npc_swap_bypass_once",
  name = locale.gettext("Open the NPC menu next time"),
  category = "misc",
  fn = function(...)
    if mod.bypass_once_action then
      return mod.bypass_once_action(...)
    end
  end,
})
