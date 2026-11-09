extends SceneTree

## R17 · HUD ↔ WorldState 绑定真跑验证（Rank-3，cmd-20261109-093050-719-A3，[ROUND=R17]）
## extends SceneTree：配合 --headless --path <工程根> --script res://scripts/verify_hud_binding.gd 真跑。
## 只读：CACHE_MODE_IGNORE 强制从磁盘重读 hud.tscn → instantiate()，不改 hud.tscn 结构、
##   不碰 courtyard.tscn、不 pack / 不 save / 不写任何工程文件。
##
## 时序修正：在 _initialize() 里 add_child 时 _ready() 不会同步 flush（实测 hud_refreshed_count=0、
##   flag_changed 未连接）。故实例化 / 静态检查 / 信号连接在 _initialize() 完成，随后挂
##   process_frame 帧状态机，等第 3 帧（_ready 已在帧循环中 flush）再做绑定链路验证。
##
## 分支（如实判定，不伪造、不冒充）：
##   MODE=AUTOLOAD_OK : /root/WorldState 可访问 + get_flag/set_flag/flag_changed 齐全 +
##                      「flag 链路已连通」(ws.flag_changed 已连 hud._on_flag_changed) →
##                      用 WorldState.set_flag 发三段式 flag，验证 TitleLabel 经 flag_changed
##                      「增量」刷新（text / 点亮态 font_color），打印逐条 PASS/FAIL。
##   MODE=DEGRADED    : autoload 不可访问 或 flag 链路不通 → 如实登记降级（明确声明未验证
##                      flag→TitleLabel 增量链路、未冒充 autoload 可访问/链路通过），至少验证
##                      4 信号可连接 + 关键方法 has_method 且实际 call。
##
## 增量 vs 全量判据：hud_refreshed 信号仅由 refresh_all() emit；flag_changed 增量走
##   refresh_label() 不 emit。_ready() 的全量刷新令计数基线=1；此后 set_flag 期间若
##   「计数不变」且「TitleLabel 属性变化」，即为增量刷新成立。
## 中文 UTF-8 · Godot 4.7.2 全静态类型 · 零付费 · 零外部依赖。

const HUD_PATH: String = "res://scenes/hud.tscn"
const HUD_SCRIPT_PATH: String = "res://scripts/hud.gd"
const LAST_GRACE_KEY: String = "grace.network.last_grace_id"        # 三段式，hud.gd 已登记常量
const LIT_FLAG: String = "grace.limgrave_gatefront.lit"              # 三段式，任务书举例
const UNRELATED_FLAG: String = "world.verify_probe.changed"          # 三段式，故意不在 _bound_keys 中
const GRACE_ID_A: String = "grace_limgrave_gatefront"                # grace_network.tres 节点 01
const GOLD: Color = Color(0.83, 0.68, 0.3, 1.0)                     # 对齐 hud.gd / hud.tscn 金色
const DIM: Color = Color(0.45, 0.42, 0.34, 1.0)                      # 对齐 hud.gd 未点亮暗色
const WAIT_FRAMES: int = 3                                           # 等 _ready() 在帧循环 flush

var _refresh_count: int = 0
var _pass: int = 0
var _fail: int = 0
var _frame: int = 0
var _hud: Node = null
var _label: Label = null


func _on_hud_refreshed() -> void:
    _refresh_count += 1


func _probe_str(_s: String) -> void:
    pass


func _check(tag: String, ok: bool, detail: String) -> void:
    print("[R17] %s PASS=%s | %s" % [tag, str(ok), detail])
    if ok:
        _pass += 1
    else:
        _fail += 1


func _initialize() -> void:
    print("[R17] ==== verify_hud_binding 真跑开始 ====")
    print("[R17] extends SceneTree | 只读实例化 hud.tscn，不改任何场景文件")

    # -- ⓪ 打印 root 现有子节点，如实记录 autoload 是否已就绪（时序证据）--
    var root_names: Array = []
    for c in get_root().get_children():
        root_names.append(str(c.name))
    print("[R17] ⓪ /root children = %s" % str(root_names))

    # -- ① 实例化 hud.tscn（CACHE_MODE_IGNORE 强制从磁盘重读）--
    var packed: PackedScene = ResourceLoader.load(HUD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if packed == null:
        print("[R17] ① scene_load FAIL | 无法加载 %s" % HUD_PATH)
        print("[R17] SUMMARY mode=ABORT pass=0 fail=1 ok=false")
        quit(1)
        return
    var hud: Node = packed.instantiate()
    _hud = hud
    _check("① scene_instantiate", hud != null, "class=%s name=%s" % [hud.get_class(), str(hud.name)])

    # -- ② 取 hud.gd 实例（脚本挂载校验）--
    var scr: Script = hud.get_script() as Script
    var scr_path: String = "<null>"
    if scr != null:
        scr_path = scr.resource_path
    _check("② hud.gd 实例", scr != null and scr_path == HUD_SCRIPT_PATH, "script=%s" % scr_path)

    # -- ③ TitleLabel 可寻址 --
    var label: Label = hud.get_node_or_null("TitleLabel") as Label
    _label = label
    var init_text: String = ""
    if label != null:
        init_text = label.text
    _check("③ TitleLabel", label != null, "text=%s" % init_text)

    # -- ④ 4 个信号存在 --
    var signals_ok: bool = true
    var sig_names: Array[String] = ["grace_selected", "travel_confirmed", "rest_requested", "hud_refreshed"]
    for s in sig_names:
        if not hud.has_signal(s):
            signals_ok = false
            print("[R17] ④ signal MISSING %s" % s)
    _check("④ 4 信号存在", signals_ok, "signals=%s" % str(sig_names))

    # -- ⑤ 4 信号可实际连接（connect 返回 OK 且 is_connected=true）--
    var conn_ok: bool = true
    var c1: Error = hud.connect("grace_selected", Callable(self, "_probe_str"))
    var c2: Error = hud.connect("travel_confirmed", Callable(self, "_probe_str"))
    var c3: Error = hud.connect("rest_requested", Callable(self, "_probe_str"))
    var c4: Error = hud.connect("hud_refreshed", Callable(self, "_on_hud_refreshed"))
    var conn_errs: Array = [c1, c2, c3, c4]
    for e in conn_errs:
        if int(e) != OK:
            conn_ok = false
    if not hud.is_connected("hud_refreshed", Callable(self, "_on_hud_refreshed")):
        conn_ok = false
    _check("⑤ 4 信号可连接", conn_ok,
        "connect_errs=%s hud_refreshed_is_connected=%s" % [str(conn_errs), str(hud.is_connected("hud_refreshed", Callable(self, "_on_hud_refreshed")))])

    # -- ⑥ 关键方法可寻址 --
    var methods: Array[String] = [
        "bind_world_state", "load_grace_network", "refresh_all", "refresh_label",
        "_on_flag_changed", "_on_delta_committed", "set_title_from_grace", "apply_lit_state",
        "build_grace_menu", "is_grace_unlocked", "are_flags_satisfied", "get_reachable_targets",
        "on_grace_selected", "request_travel", "grace_fast_travel", "request_rest",
        "set_fast_travel_committer"
    ]
    var miss: Array = []
    for m in methods:
        if not hud.has_method(m):
            miss.append(m)
    _check("⑥ 关键方法可寻址", miss.is_empty(), "total=%d missing=%s" % [methods.size(), str(miss)])

    # -- 加入场景树；_ready() 由帧循环 flush，故挂 process_frame 状态机等待 --
    get_root().add_child(hud)
    print("[R17] 已 add_child(hud) | 等待 _ready() 在帧循环 flush（WAIT_FRAMES=%d）" % WAIT_FRAMES)
    process_frame.connect(_on_frame)


## 帧状态机：跳过前 WAIT_FRAMES-1 帧，第 WAIT_FRAMES 帧执行绑定链路验证。
func _on_frame() -> void:
    _frame += 1
    if _frame < WAIT_FRAMES:
        return
    process_frame.disconnect(_on_frame)
    _verify_after_ready()


func _verify_after_ready() -> void:
    var hud: Node = _hud
    var label: Label = _label

    # -- ⑦ _ready() 全量刷新已在帧循环执行（hud_refreshed 计数基线=1）--
    var base_refresh: int = _refresh_count
    var ready_text: String = ""
    if label != null:
        ready_text = label.text
    _check("⑦ _ready 全量刷新", base_refresh == 1 and not ready_text.is_empty(),
        "frames_waited=%d hud_refreshed_count=%d TitleLabel.text=%s" % [_frame, base_refresh, ready_text])

    # -- ⑧ 真实检测 /root/WorldState autoload --
    var ws: Node = get_root().get_node_or_null("WorldState")
    var ws_exists: bool = ws != null
    var ws_script: String = "<null>"
    if ws != null:
        var ws_scr: Script = ws.get_script() as Script
        if ws_scr != null:
            ws_script = ws_scr.resource_path
    var ws_api: bool = ws != null and ws.has_method("get_flag") and ws.has_method("set_flag") and ws.has_signal("flag_changed")
    print("[R17] ⑧ autoload 实测 | /root/WorldState exists=%s script=%s api(get_flag/set_flag/flag_changed)=%s" % [str(ws_exists), ws_script, str(ws_api)])

    # -- ⑧b flag 链路连通性：ws.flag_changed 是否已连到 hud._on_flag_changed --
    var chain_linked: bool = ws != null and ws.is_connected("flag_changed", Callable(hud, "_on_flag_changed"))
    print("[R17] ⑧b flag 链路连通 | ws.flag_changed -> hud._on_flag_changed connected=%s" % str(chain_linked))

    # -- 分支判定：autoload 不可访问 或 flag 链路不通 → 一律如实降级（任务书第 2 条）--
    var mode: String = "DEGRADED"
    if ws_exists and ws_api and chain_linked and label != null:
        mode = "AUTOLOAD_OK"

    if mode == "AUTOLOAD_OK":
        _run_full_chain(ws, hud, label, base_refresh)
    else:
        _run_degraded(hud, label, base_refresh)

    print("[R17] ==== verify_hud_binding 真跑结束 ====")
    if mode == "AUTOLOAD_OK":
        print("[R17] SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=%d fail=%d ok=%s" % [_pass, _fail, str(_fail == 0)])
    else:
        print("[R17] SUMMARY mode=DEGRADED degraded=true flag_chain_verified=false pass=%d fail=%d ok=%s" % [_pass, _fail, str(_fail == 0)])
    quit(0 if _fail == 0 else 1)


## 情形 A：autoload 可访问且 flag 链路连通，真实走 set_flag → flag_changed → HUD 增量刷新。
func _run_full_chain(ws: Node, hud: Node, label: Label, base_refresh: int) -> void:
    print("[R17] ---- MODE=AUTOLOAD_OK：验证 flag→TitleLabel 增量刷新 ----")

    # A0：确认 flag_changed 已连 hud（mode 判据已要求，此处留作运行期记录）
    var bound: bool = ws.is_connected("flag_changed", Callable(hud, "_on_flag_changed"))
    _check("A0 flag_changed 已连 HUD", bound,
        "ws.flag_changed -> hud._on_flag_changed connected=%s" % str(bound))

    # A1：三段式 last_grace_id → TitleLabel.text 增量（经 flag_changed）
    var t0: String = label.text
    ws.call("set_flag", LAST_GRACE_KEY, GRACE_ID_A)
    var t1: String = label.text
    var a1: bool = t1 != t0 and t1.contains("关卡前") and _refresh_count == base_refresh
    _check("A1 text 增量(flag_changed)", a1,
        "flag=%s before=[%s] after=[%s] display_name命中=%s hud_refreshed=%d(基线=%d)"
        % [LAST_GRACE_KEY, t0, t1, str(t1.contains("关卡前")), _refresh_count, base_refresh])

    # A2：三段式 lit flag → TitleLabel 点亮态 font_color 增量（经 flag_changed，仅当前赐福命中）
    var col_before: Color = label.get_theme_color("font_color", "Label")
    ws.call("set_flag", LIT_FLAG, true)
    var col_after: Color = label.get_theme_color("font_color", "Label")
    var a2: bool = col_before.is_equal_approx(DIM) and col_after.is_equal_approx(GOLD) and _refresh_count == base_refresh
    _check("A2 点亮态增量(flag_changed)", a2,
        "flag=%s before=%s after=%s GOLD命中=%s hud_refreshed=%d(基线=%d)"
        % [LIT_FLAG, str(col_before), str(col_after), str(col_after.is_equal_approx(GOLD)), _refresh_count, base_refresh])

    # A3：三段式但不在绑定集合的 flag → 不误刷（验证增量命中判定，非全量）
    var t_before: String = label.text
    var c_before: Color = label.get_theme_color("font_color", "Label")
    ws.call("set_flag", UNRELATED_FLAG, 1)
    var a3: bool = label.text == t_before and label.get_theme_color("font_color", "Label").is_equal_approx(c_before) and _refresh_count == base_refresh
    _check("A3 无关 flag 不误刷(增量命中)", a3,
        "flag=%s text不变=%s color不变=%s hud_refreshed=%d(基线=%d)"
        % [UNRELATED_FLAG, str(label.text == t_before), str(label.get_theme_color("font_color", "Label").is_equal_approx(c_before)), _refresh_count, base_refresh])

    print("[R17] A4 关键方法经 flag_changed 链路实际调用：refresh_label -> set_title_from_grace / apply_lit_state 均已被 A1/A2 间接触发")


## 情形 B：autoload 不可访问或 flag 链路不通 → 如实登记降级，不伪造 PASS、不冒充链路通过。
func _run_degraded(hud: Node, label: Label, base_refresh: int) -> void:
    print("[R17] ---- MODE=DEGRADED：如实登记降级 ----")
    print("[R17] DEGRADED 原因 | /root/WorldState autoload 不可访问 或 get_flag/set_flag/flag_changed API 不齐 或 flag 链路未连通 或 TitleLabel 缺失")
    print("[R17] DEGRADED 声明 | 未进行 flag→TitleLabel 增量刷新验证；下列 PASS 不代表 flag 链路通过；不伪造输出、不冒充 autoload 可访问 / 链路通过")
    print("[R17] DEGRADED 下限 | 至少验证 4 信号可连接（见 ⑤）+ 关键方法可调用（下 D1）")
    print("[R17] DEGRADED hud_refreshed_count=%d（基线，降级分支不触发额外全量）" % base_refresh)

    # D1：关键方法「实际 call」（只读 / 仅内存态，非 flag 链路；不依赖 _ready/_net 的业务结果）
    var call_ok: bool = true
    var details: Array = []
    if hud.has_method("build_grace_menu"):
        var menu: Variant = hud.call("build_grace_menu")
        details.append("build_grace_menu->type=%d" % typeof(menu))
        if typeof(menu) != TYPE_ARRAY:
            call_ok = false
    else:
        call_ok = false
    if hud.has_method("get_reachable_targets"):
        var reach: Variant = hud.call("get_reachable_targets", "")
        details.append("get_reachable_targets->type=%d" % typeof(reach))
        if typeof(reach) != TYPE_ARRAY:
            call_ok = false
    else:
        call_ok = false
    if hud.has_method("are_flags_satisfied"):
        var sat: Variant = hud.call("are_flags_satisfied", {})
        details.append("are_flags_satisfied({})->%s" % str(sat))
        if typeof(sat) != TYPE_BOOL:
            call_ok = false
    else:
        call_ok = false
    if hud.has_method("set_title_from_grace") and label != null:
        var before: String = label.text
        hud.call("set_title_from_grace", GRACE_ID_A)
        var after: String = label.text
        details.append("set_title_from_grace->[%s]->[%s]" % [before, after])
    else:
        call_ok = false
    if hud.has_method("apply_lit_state") and label != null:
        hud.call("apply_lit_state", true)
        var col: Color = label.get_theme_color("font_color", "Label")
        details.append("apply_lit_state(true)->font_color=%s" % str(col))
    else:
        call_ok = false
    _check("D1 关键方法实际 call", call_ok, str(details))
