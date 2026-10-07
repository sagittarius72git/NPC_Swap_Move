--[[
  Swap Places by Default - main.lua

  味方NPCに向かって移動したときの既定の動作を「位置の入れ替え」にする。

  本体(BN)の作り:
    * avatar_action::move() は、移動先に敵でないNPCが居ると game::npc_menu() を呼ぶ
    * game::npc_menu() は、メニューを組み立てる前に Lua フック
      "on_try_npc_interaction" を実行し、false が返るとメニューを出さずに終了する
    * 本体の「Swap positions」は game::swap_critters() で、
      NPC を setpos した後、プレイヤーを walk_move() で送り込み、移動力を200消費する

  このMODの動作:
    フックで接触を横取りし、条件を満たせば自前で入れ替えて false を返す。
    プレイヤー側の移動には gapi.place_player_local_at()（= game::place_player()）を使う。
    これは本体が swap_critters() の内部で通る処理と同じで、
    マップのずらし直し・乗り物への搭乗・罠の判定まで面倒を見てくれる。

  入れ替えない条件（本体のメニューがそのまま開く）:
    * 相手が味方でない、または眠っている
    * 自分か相手が騎乗中
    * 隣接していない（同じ高さの隣マスでない）
    * 相手のマスに罠がある
    * どちらかのマスが搭乗可能な乗り物の上にある
      （NPCの搭乗状態を設定する関数がLuaに無いため）
    * 「次の1回だけメニューを開く」を使った直後

  設定は下の mod.cfg で変更でき、「Reload Lua Code」で即反映される。
]]

gdebug.log_info("NSM: main.")

local mod = game.mod_runtime[game.current_mod]

----------------------------------------------------------------------
-- 設定
----------------------------------------------------------------------

mod.cfg = {
  -- 入れ替えに使う移動力。本体の「Swap positions」と同じ200が既定。
  move_cost = 200,

  -- 味方(is_player_ally)だけを対象にする。
  -- false にすると敵対していないNPC全員と入れ替わる（本体では許可されていない挙動）。
  require_ally = true,

  -- 相手のマスに罠があるときは入れ替えず、通常のメニューを開く。
  avoid_traps = true,

  -- どちらかのマスが搭乗可能な乗り物の上にあるときは入れ替えない。
  avoid_vehicles = true,

  -- 自動移動（移動先を指定して歩く）の途中で味方が道をふさいだら、入れ替わって進む。
  -- 本体に on_auto_move_blocked_by_npc フックがある場合だけ働く。現状無意味
  swap_on_auto_move = true,

  -- 入れ替えたときにメッセージを出す。
  announce = true,

  -- 詳細をデバッグログに出す。
  debug = false,
}

----------------------------------------------------------------------
-- 定数・補助関数
----------------------------------------------------------------------

local EFF_SLEEP = EffectTypeId.new("sleep")

local function log(fmt, ...)
  if mod.cfg.debug then
    gdebug.log_info("NSM: " .. string.format(fmt, ...))
  end
end

-- 隣接（同じ高さの、周囲8マスのいずれか）かどうか
local function is_adjacent(a, b)
  if a.z ~= b.z then
    return false
  end
  local dx = math.abs(a.x - b.x)
  local dy = math.abs(a.y - b.y)
  return dx <= 1 and dy <= 1 and (dx + dy) > 0
end

local function has_trap(map, pos)
  local ok, id = pcall(function()
    return map:get_trap_at(pos):str_id():str()
  end)
  if not ok or not id then
    return false
  end
  return id ~= "tr_null" and id ~= ""
end

local function has_boardable_vehicle(map, pos)
  local ok, res = pcall(function()
    return map:has_vehicle_part_with_feature_at(pos, "BOARDABLE")
  end)
  return ok and res == true
end

-- 入れ替えてよいか。駄目な場合は理由を返す（ログ用）。
local function can_swap(u, np)
  if mod.cfg.require_ally and not np:is_player_ally() then
    return false, "not an ally"
  end
  if np:has_effect(EFF_SLEEP) then
    return false, "asleep"
  end
  if u:is_mounted() or np:is_mounted() then
    return false, "mounted"
  end

  local u_pos = u:get_pos_ms()
  local np_pos = np:get_pos_ms()
  if not is_adjacent(u_pos, np_pos) then
    return false, "not adjacent"
  end

  local map = gapi.get_map()
  if not map then
    return false, "no map"
  end
  if mod.cfg.avoid_traps and has_trap(map, np_pos) then
    return false, "trap"
  end
  if mod.cfg.avoid_vehicles and
      (has_boardable_vehicle(map, u_pos) or has_boardable_vehicle(map, np_pos)) then
    return false, "vehicle"
  end

  return true
end

----------------------------------------------------------------------
-- 「次の1回だけメニューを開く」
----------------------------------------------------------------------

mod.bypass_once = false

mod.bypass_once_action = function()
  mod.bypass_once = true
  gapi.add_msg(locale.gettext("The next NPC you touch will open the usual menu."))
end

----------------------------------------------------------------------
-- 本体
----------------------------------------------------------------------

-- 位置を入れ替える
local function swap(u, np)
  local u_pos = u:get_pos_ms()
  local np_pos = np:get_pos_ms()

  -- 本体の swap_critters() と同じ順序: 先にNPCを自分のマスへ、次に自分を送り込む
  np:set_pos(u_pos)
  gapi.place_player_local_at(np_pos)
  u:mod_moves(-mod.cfg.move_cost)

  if mod.cfg.announce then
    gapi.add_msg(string.format(locale.gettext("You swap places with %s."), np:get_name()))
  end
  log("swapped with %s", np:get_name())
end

local function handle(np)
  -- 直前に解除スイッチが使われていれば、今回だけ本体に任せる
  if mod.bypass_once then
    mod.bypass_once = false
    log("bypass")
    return nil
  end

  local u = gapi.get_avatar()
  if not u then
    return nil
  end

  local ok, why = can_swap(u, np)
  if not ok then
    log("no swap (%s)", why)
    return nil
  end

  swap(u, np)

  -- false を返すと npc_menu() がメニューを出さずに終了する
  return false
end

mod.on_try_npc_interaction = function(params)
  local np = params and params.npc
  if not np then
    return nil
  end
  local ok, res = pcall(handle, np)
  if not ok then
    gdebug.log_info("NSM: on_try_npc_interaction failed: " .. tostring(res))
    -- 失敗したときは本体のメニューに任せる
    return nil
  end
  return res
end

-- 自動移動（移動先を指定して歩く）の途中で、次のマスに味方がいたとき。
-- 入れ替われば本体はそのまま自動移動を続ける。入れ替えなければ従来どおり止まる。
-- （このフックがある本体でだけ呼ばれる。preload.lua 参照）
mod.on_auto_move_blocked_by_npc = function(params)
  local np = params and params.npc
  if not np or not mod.cfg.swap_on_auto_move then
    return
  end
  local ok, err = pcall(function()
    local u = gapi.get_avatar()
    if not u then
      return
    end
    local can, why = can_swap(u, np)
    if not can then
      log("auto-move: no swap (%s)", why)
      return
    end
    swap(u, np)
  end)
  if not ok then
    gdebug.log_info("NSM: on_auto_move_blocked_by_npc failed: " .. tostring(err))
  end
end
