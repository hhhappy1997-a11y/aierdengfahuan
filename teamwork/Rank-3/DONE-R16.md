# DONE-R16.md · R16 完成标志

> 命令 `cmd-20261109-085736-027-A3` · `[ROUND=R16]` · Rank-3（RPG / 世界 / 存档）
> 状态：**done** · 中文 UTF-8 · 零付费 · 默认不刺探 · 不伪造输出 · Godot 4.7.2 合法语法
> 引擎实测：`D:/Godot/Godot_v4.7.2-stable_win64.exe --version` → `4.7.2.stable.official.ed1daf0bf`

---

## ① 交付清单

| # | 交付件 | 动作 | 内容 |
|---|---|---|---|
| 1 | `godot/scripts/hud.gd` | **新建** | 独立 HUD 脚本，`extends CanvasLayer`（与 `hud.tscn` 根节点 `Hud` 类型一致）。含 4 信号 + 草案 §3.3 全部 15 个方法 + `grace_fast_travel` + `request_rest` + `set_fast_travel_committer`（共 18 个公开方法，另有 6 个私有工具）。详见 §1.1 |
| 2 | `godot/scenes/hud.tscn` | **编辑（追加式）** | 追加 1 条 `ext_resource` 指向 `res://scripts/hud.gd`，根节点 `Hud` 加 `script = ExtResource("1_hud")`。其余 `StyleBoxFlat_toqtt` / `HudPanel` / `TitleLabel` 逐字未动，场景仍 3 节点。详见 §1.2 |
| 3 | `teamwork/Rank-3/r16_verify_hud.gd` | **新建** | R16 实例化回读校验载体（`extends SceneTree`，`CACHE_MODE_IGNORE` 强制从磁盘重读 → `instantiate()`，只读、不 pack / 不 save）。以绝对路径 `--script` 配合 `--path godot` 真跑 |
| 4 | `teamwork/Rank-3/DONE-R16.md` | **新建** | 本件：①交付清单 ②自检（含真跑实际输出）③未完成项与阻塞 |
| 5 | `teamwork/command_center/ai/3/outbox/receipt_cmd-20261109-085736-027-A3.json` | **新建** | 回执 JSON，按本轮派单 id |

### 1.1 `hud.gd` 落地要点（对应任务书 1~4）

| 任务书要求 | 落点 | 实现 |
|---|---|---|
| `extends CanvasLayer`，与 `hud.tscn` 根节点一致 | `godot/scripts/hud.gd:1` | ✅ 回读 ① `root_is_CanvasLayer PASS=true` |
| ① `_ready()` 全量刷新 `TitleLabel`，`get_flag(key, default)` **显式传 default，不依赖 null** | `godot/scripts/hud.gd:52`（`_ready` → `refresh_all()`）、`godot/scripts/hud.gd:106`（`_flag` 唯一读取入口）、`godot/scripts/hud.gd:113`（`refresh_all`） | 所有读取统一经 `_flag(key, default)`，调用 `WorldState.get_flag(key, default)` 时**显式**传业务默认值：String → `""`（`LAST_GRACE_KEY`）、bool → `false`（8 节点 `lit_flag` / `unlocked_flag`、7 条边 `requires_flags`）。全文件**无一处**省略 default 依赖 `null` 形参默认（`world_state.gd:51` 的 `default: Variant = null` 不被使用） |
| ② 订阅 `flag_changed` 做增量刷新，事件驱动、禁止每帧轮询 | `godot/scripts/hud.gd:151`（`_on_flag_changed`）、`godot/scripts/hud.gd:132`（`refresh_label`）、`godot/scripts/hud.gd:157`（`_on_delta_committed`）、`bind_world_state()` | `_ready` → `bind_world_state()` 连 `flag_changed`（命中 `_bound_keys` 才 `refresh_label(key)` 增量）与 `delta_committed`（回放 / 注入兜底 `refresh_all()`）。**脚本内无 `_process()` / `_physics_process()`**，无任何每帧 `get_flag` 轮询 |
| ③ `grace_fast_travel` 接口：先 `SaveDeltaWriter.commit(reason)` 原子落盘、后发 `travel_requested` 信号，HUD 自己不 `commit`（I-1） | `godot/scripts/hud.gd:289`（`grace_fast_travel`）、`godot/scripts/hud.gd:323`（`_delegate_commit`）、`godot/scripts/hud.gd:279`（`set_fast_travel_committer`）、`godot/scripts/hud.gd:34`（常量） | ① 校验 `unlocked` + `edges[*].requires_flags`（只读 `_flag(k, false)`）→ ② **先落盘**：`_delegate_commit(reason)` 委托 3 号内部 `SaveDeltaWriter.commit(reason)`（可注入 `Callable` 或解析 `/root/SaveDeltaWriter`）→ ③ **后发信号**：`travel_confirmed.emit()` + `GameEvents.travel_requested`。HUD **不构造 / 解析 SaveDelta、不 `FileAccess` 读写 `user://saves/`、不 `ResourceLoader` 加载存档、不 `JSON.parse` 存档、不调 `WorldState._commit_delta` 等内部方法**；`reason` 常量 `"grace_fast_travel"` 与 `chunk_world_bridge.gd:43` 对齐 |
| ④ 4 个信号 + 草案里可落地的方法（缺的如实登记） | `godot/scripts/hud.gd:20-23`（4 信号）、全文件 | 4 信号全落地：`grace_selected` / `travel_confirmed` / `rest_requested` / `hud_refreshed`。草案 §3.3 的 15 个签名**全部实现**（`_ready` / `bind_world_state` / `load_grace_network` / `refresh_all` / `refresh_label` / `_on_flag_changed` / `_on_delta_committed` / `set_title_from_grace` / `apply_lit_state` / `build_grace_menu` / `is_grace_unlocked` / `are_flags_satisfied` / `get_reachable_targets` / `on_grace_selected` / `request_travel`），另补 `grace_fast_travel` / `request_rest` / `set_fast_travel_committer`。回读 ⑤ `total=17 missing=[]`（17 = 草案 15 − `_ready` 引擎回调 + `grace_fast_travel` + `request_rest` + `set_fast_travel_committer`）。**无缺失方法**，故本项无需「缺的登记」；边界外项见 ③ |

补充：赐福菜单 8 节点 / 7 边全部取自 `res://data/rpg/grace_network.tres`（`load_grace_network()` 用 `CACHE_MODE_IGNORE` 加载、不硬编码赐福名 / 边）；`build_grace_menu()` `godot/scripts/hud.gd:191` 返回数据快照；`set_title_from_grace()` `godot/scripts/hud.gd:166` 空值回退静态占位 `"赐福 · 宁姆格福"`；`apply_lit_state()` `godot/scripts/hud.gd:179` 运行期改 `font_color`、不改 `.tscn` 落盘金色。

### 1.2 `hud.tscn` 改动（追加式，逐字核对）

改动前（`R13` 落盘）为 3 节点 + 1 `sub_resource`、**无 `ext_resource`**。本轮仅两处追加：

```diff
 [gd_scene format=3]
+
+[ext_resource type="Script" path="res://scripts/hud.gd" id="1_hud"]

 [sub_resource type="StyleBoxFlat" id="StyleBoxFlat_toqtt"]
 ...
 [node name="Hud" type="CanvasLayer" unique_id=1276405765]
+script = ExtResource("1_hud")

 [node name="HudPanel" type="Panel" parent="." unique_id=1292641255]
 ...  （offset / theme_override_styles 逐字未动）
 [node name="TitleLabel" type="Label" parent="." unique_id=1414552291]
 ...  （font_size / font_color / text = "赐福 · 宁姆格福" 逐字未动）
```

**回执投递注记（如实登记）**：本轮回执首次写入 `command_center/ai/3/outbox/receipt_cmd-20261109-085736-027-A3.json` 后，被中枢自动化**即时消费并归档**到 `command_center/dispatcher/receipts/receipt_cmd-20261109-085736-027-A3.json`（归档内容与本轮写入逐字一致，已读回核对）。已再次在 outbox 写入同内容一份并即时 `json.load` 解析通过（`task_id` / `ai` / `status` 三项校验均为 True、写入瞬间 `EXISTS_AFTER_WRITE=True`）。中枢在扫描间隙会再次消费，故 outbox 的最终快照可能为空，但 `dispatcher/receipts/` 归档件与 dispatcher ledger 即送达凭据；此为中枢既有消费行为，非伪造、非重复派单。

### 明确未产出 / 未改动（按边界）

- **未写 / 未改 `godot/scenes/courtyard.tscn`（Rank-1 本轮独占）**：本轮复核其已含 `[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="4_6e1c7"]`（R15 Rank-1 已挂 HUD 实例），故改 `hud.tscn` 脚本挂载后实例自动继承、无需触碰主场景。其 sha256 记录为 `709f05bd1e754e0999bfe8a933828c52a3974b83c0643d43476aaa6970642fc6`（本轮未写入）。
- 未新增赐福菜单容器节点（如实登记，见 ③ 第 1 项）。
- 未运行任何付费 API / 云服务 / 外部服务 / GPU job；未启动第二个 qwen / ComfyUI 任务。
- 未自行 git（commit / push 均未执行）。
- 未追加 / 修改 `00-群聊总线.md`：按协议开工只读一次（已读）；本件非「接口变更 / 里程碑交付 / 阻塞求助 / 回应 @」四类必发事件，不追加。
- 未写 `godot/scripts/` 下除 `hud.gd` 外的任何文件；验证载体落在可写范围 `Rank-3/` 内。

---

## ② 自检（含真跑实际输出）

### 2.1 `--check-only --script hud.gd` 真跑（语法门禁）

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --check-only --script "res://scripts/hud.gd"
```

实际 stdout（完整）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_EXIT=0
```

> 只有引擎 banner、无任何脚本内 `print` / `SCRIPT ERROR` / `Parse Error` / `ERROR` —— `--check-only` 只解析脚本、不执行，证明 `hud.gd` 为 Godot 4.7.2 合法语法。（任务书写作 `--check-only --script hud.gd`，按工程根 `res://` 路径等价展开为 `res://scripts/hud.gd`。）

### 2.2 实例化 `hud.tscn` 回读确认脚本已挂、Label 可寻址（真跑）

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --script "F:/Game/aierdengfahuan/teamwork/Rank-3/r16_verify_hud.gd"
```

实际 stdout（完整）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R16_VERIFY] ① root_is_CanvasLayer PASS=true | name=Hud class=CanvasLayer
[R16_VERIFY] ② script_attached PASS=true | path=res://scripts/hud.gd
[R16_VERIFY] ③ TitleLabel PASS=true | class=Label text=赐福 · 宁姆格福
[R16_VERIFY] ④ four_signals PASS=true
[R16_VERIFY] ⑤ methods PASS=true | total=17 missing=[]
[R16_VERIFY] ⑥ ready_refresh PASS=true | TitleLabel.text=赐福 · 宁姆格福
[R16_VERIFY] VERIFY_SUMMARY pass=6 fail=0 ok=true
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
       GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
VERIFY_EXIT=0
```

要点：

- 用 `ResourceLoader.load(..., CACHE_MODE_IGNORE)` **强制忽略缓存、从磁盘重读**刚改的 `hud.tscn` 后 `instantiate()`；② 确认根节点 `get_script().resource_path == "res://scripts/hud.gd"`，③ 确认 `TitleLabel` 可寻址且为 `Label`。
- ⑥ 把实例加入场景树真实触发 `_ready()`：全量刷新后 `TitleLabel.text` 仍为可显示内容（空 flag 回退占位），`PASS=true`。
- 两条 WARNING（`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`）为**工程既有现象**（`DONE-R13.md §2.4` / `GATE-FINAL.md` 已登记 `ObjectDB leaked` 为非 ERROR），与本轮 `hud.gd` / `hud.tscn` 无关，如实保留、未隐藏、未宣称零 WARNING。

### 2.3 三段门禁复跑（`00-工具链接入说明.md` §4.2 / `DONE-R13.md §2.2` 口径）

三段均以工程根 `F:/Game/aierdengfahuan/godot` 为 `--path`：

- **G1**：`godot --headless --path <工程根> --import`
- **G2**：`godot --headless --path <工程根> --check-only --script res://scripts/hud.gd`
- **G3**：`godot --headless --path <工程根> --quit`

复跑 2 轮 × 3 段，实际 stdout（完整）：

```
########## ROUND 1 ##########
===== G1 (ROUND 1) =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

G1_R1_EXIT=0
G1_R1_SCRIPT_ERROR_COUNT=0
G1_R1_PARSE_ERROR_COUNT=0
G1_R1_ERROR_COUNT=0
G1_R1_WARNING_COUNT=0
===== G2 (ROUND 1) =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_R1_EXIT=0
G2_R1_SCRIPT_ERROR_COUNT=0
G2_R1_PARSE_ERROR_COUNT=0
G2_R1_ERROR_COUNT=0
G2_R1_WARNING_COUNT=0
===== G3 (ROUND 1) =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_R1_EXIT=0
G3_R1_SCRIPT_ERROR_COUNT=0
G3_R1_PARSE_ERROR_COUNT=0
G3_R1_ERROR_COUNT=0
G3_R1_WARNING_COUNT=1
########## ROUND 2 ##########
===== G1 (ROUND 2) =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

G1_R2_EXIT=0
G1_R2_SCRIPT_ERROR_COUNT=0
G1_R2_PARSE_ERROR_COUNT=0
G1_R2_ERROR_COUNT=0
G1_R2_WARNING_COUNT=0
===== G2 (ROUND 2) =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_R2_EXIT=0
G2_R2_SCRIPT_ERROR_COUNT=0
G2_R2_PARSE_ERROR_COUNT=0
G2_R2_ERROR_COUNT=0
G2_R2_WARNING_COUNT=0
===== G3 (ROUND 2) =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_R2_EXIT=0
G3_R2_SCRIPT_ERROR_COUNT=0
G3_R2_PARSE_ERROR_COUNT=0
G3_R2_ERROR_COUNT=0
G3_R2_WARNING_COUNT=1
```

汇总表：

| 段 | ROUND 1 EXIT | ROUND 2 EXIT | SCRIPT ERROR | Parse Error | ERROR: |
|---|---|---|---|---|---|
| G1 `--import` | 0 | 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| G2 `--check-only --script` | 0 | 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| G3 `--quit` | 0 | 0 | 0 / 0 | 0 / 0 | 0 / 0 |

整体汇总复跑（第 2 次独立确认，实际 stdout）：

```
ROUND1 G1 EXIT=0
ROUND1 G2 EXIT=0
ROUND1 G3 EXIT=0
ROUND2 G1 EXIT=0
ROUND2 G2 EXIT=0
ROUND2 G3 EXIT=0
GATE_OVERALL_EXIT=0
```

- 按契约 §4.2「运行期 `SCRIPT ERROR` 只中断当前函数、退出码仍为 0，必须 grep 日志才算通过」：6 段 `SCRIPT ERROR` / `Parse Error` / `ERROR:` 计数**全部为 0**。
- G3 两轮各 1 条 `WARNING: 2 ObjectDB instances were leaked at exit`（工程既有，非 ERROR），如实保留。
- **如实登记一条工具层 stderr**：第一次复跑脚本末尾 `rm -rf "$LOGDIR"` 清理系统临时日志目录时被工具安全钩子拦截，报 `[safe-delete][SAFE_DELETE_INVALID_PATH] embedded drive prefix is not allowed`、该次 Bash 调用 `Exit Code 1`；这**只影响临时日志目录清理，不影响 6 段门禁命令**（每段 `EXIT=0` 已逐条打印），随后用不带 `rm` 的独立汇总命令复跑得到 `GATE_OVERALL_EXIT=0`。未隐藏、未伪装成全绿。

### 2.4 UTF-8 / BOM 与文件哈希（真跑）

```
=== UTF-8 / BOM 检查 ===
hud.gd | bytes=16740 | BOM=False | utf8=True
hud.tscn | bytes=903 | BOM=False | utf8=True
r16_verify_hud.gd | bytes=3903 | BOM=False | utf8=True
=== 文件哈希 / 大小 ===
113065a2da786feb24a65f9bfa26e4074bcbdfc767b9120a67bef5634712b226 *F:/Game/aierdengfahuan/godot/scripts/hud.gd
0c9670ae77865027627d9bfdccac4e487352abc004aac1fca4446b2cf116c764 *F:/Game/aierdengfahuan/godot/scenes/hud.tscn
709f05bd1e754e0999bfe8a933828c52a3974b83c0643d43476aaa6970642fc6 *F:/Game/aierdengfahuan/godot/scenes/courtyard.tscn
```

### 2.5 任务点覆盖

| # | 任务书要求 | 结论 |
|---|---|---|
| 1 | 独立 `godot/scripts/hud.gd`，`extends CanvasLayer`，与 `hud.tscn` 根节点一致 | ✅ §1.1 / 回读 ① |
| 2 | `_ready()` 全量刷新 `TitleLabel`，`get_flag(key, default)` 显式传 default，不依赖 null | ✅ §1.1 / 回读 ⑥ |
| 3 | 订阅 `flag_changed` 增量刷新，事件驱动、禁止每帧轮询 | ✅ §1.1，无 `_process` |
| 4 | `grace_fast_travel`：先 commit 原子落盘、后发 `travel_requested`，HUD 不 commit（I-1） | ✅ §1.1（口径张力如实登记，见 ③ 第 3 项） |
| 5 | 4 个信号 + 草案可落地方法（缺的如实登记） | ✅ 4 信号 + 15 草案方法全落地，无缺失；边界外项见 ③ |
| 6 | 挂脚本到 `hud.tscn`；`--check-only --script hud.gd` 真跑；实例化回读确认脚本已挂、Label 可寻址 | ✅ §1.2 / §2.1 / §2.2（6 项全 PASS） |
| 7 | 不写 `courtyard.tscn`（Rank-1 独占） | ✅ 未触碰，sha256 已记录 |
| 8 | 三段门禁复跑 | ✅ §2.3，2 轮 × 3 段，`GATE_OVERALL_EXIT=0` |

### 2.6 硬约束自检

| 约束 | 结论 |
|---|---|
| 默认不刺探 | ✅ 只目的性读取必读件（`HUD-BINDING.md` / `hud.tscn` / `world_state.gd` / `00-群聊总线.md` 开工只读一次）与本任务点名依赖（`save_delta_writer.gd` / `chunk_world_bridge.gd` / `game_events.gd` / `grace_network.tres` / `grace_node.gd` / `00-工具链接入说明.md` / `DONE-R13.md` / `HUD-ATTACH.md` / `project.godot`），未跨工位翻查 |
| 零付费 | ✅ 无付费 API / 云服务 / 外部服务；无 GPU job |
| 三段门禁复跑 | ✅ §2.3 两轮 + 独立汇总，`GATE_OVERALL_EXIT=0` |
| 不伪造输出 | ✅ 全部 stdout 为真跑实际输出；既有 WARNING 与工具层 `rm -rf` 拦截如实登记；既有轮次结论（W7 / R15）均标注非本轮 |
| 中文 UTF-8 | ✅ §2.4 三件均 `utf8=True` / `BOM=False` |
| Godot 4 合法语法 | ✅ `--check-only` `EXIT=0`、6 段门禁 `SCRIPT ERROR=0`、实例化回读通过 |
| 可写范围 | ✅ 仅 `Rank-3/`、`godot/scripts/hud.gd`、`godot/scenes/hud.tscn`、`command_center/ai/3/outbox/`；未自行 git |
| 回执 `task_id` 取本轮派单 id | ✅ `cmd-20261109-085736-027-A3` |

---

## ③ 未完成项与阻塞

> 下列项均为**按边界不做 / 装配层未就绪 / 跨工位 / 待裁决**，不影响本轮「脚本实现 + 挂场景 + 语法门禁 + 实例化回读」的完成判定；一律如实登记、不擅自裁决、不伪造完成。

### 3.1 未完成项（边界外 / 后续轮次）

| # | 项 | 性质 | 说明 |
|---|---|---|---|
| 1 | 赐福菜单容器节点未新增 | 按边界 / 待裁决 | `hud.tscn` 仍为 3 节点（`Hud` / `HudPanel` / `TitleLabel`）。`HUD-BINDING.md §3.4` / `§4.2` 把菜单容器类型（`ItemList` / `VBoxContainer`）与 `class_name` 是否注册**留 R16 裁决**，本轮不擅自定死、不新增节点；`build_grace_menu()` 已在数据层返回 8 节点快照（含 `id` / `text` / `group` / `is_dungeon` / `order` / `scene_path` / `spawn_marker`）供后续 UI 消费。本轮只做任务书明列的「挂脚本」 |
| 2 | `grace_fast_travel` 运行期原子落盘未端到端真跑 | 装配层未就绪 | `project.godot` 的 5 个 autoload（WorldState / GameEvents / SaveSystem / ChunkManager / SceneRouter）**不含 `SaveDeltaWriter`**，而 `chunk_world_bridge.gd:52` 期望 `/root/SaveDeltaWriter`。当前工程根下 `_delegate_commit()` 解析不到该单例 → 返回 `false` → 按设计只发信号 + `push_warning` 兜底登记。本轮真跑范围是 `--check-only` 语法门禁 + 实例化回读（含 `_ready()`），**未谎报落盘真跑**；严格「先落盘后发信号」由 `set_fast_travel_committer()` 注入点保证，装配层注册 `SaveDeltaWriter` 后生效 |
| 3 | 「先 commit 后发信号」与既有 I-1 链路的口径张力 | **待 HOST 裁决（不擅自裁决）** | 任务书要求 `grace_fast_travel` 先 `SaveDeltaWriter.commit(reason)` 原子落盘、后发 `travel_requested`，且「HUD 自己不 commit（I-1）」；但 `HUD-BINDING.md §2.4` 既有实证链路为 `ChunkWorldBridge._on_travel_requested → SaveDeltaWriter.commit("grace_fast_travel")`（**信号触发落盘**），且 I-1 字面列有「不调用 `SaveDeltaWriter.commit()`」。本实现把 commit **委托**给 3 号内部件（HUD 不实现落盘逻辑、不构造 SaveDelta、不写盘），编排上先委托后发信号；若桥接层同时订阅 `GameEvents.travel_requested`，存在二次 commit 可能。两种口径并存且属跨模块，按「不擅自裁决跨模块争议」如实登记，交 HOST / 总指挥裁定；本轮未改 `chunk_world_bridge.gd`、未改 `project.godot` |
| 4 | 金色 Label 点亮态、菜单与 `WorldState` / `GameEvents` 的端到端联调未做 | 跨工位 / 后续轮次 | 依赖 R15 HUD 实例挂载稳定（本轮复核 `courtyard.tscn` 已含 `hud.tscn` ExtResource）+ 菜单 UI 容器 + `SaveDeltaWriter` 注册；本轮只验证 `_ready()` 全量刷新不报脚本错误 |
| 5 | `last_grace_id` 空值具体回退文案、边校验范围 | 简化实现，如实登记 | 回退沿用 `.tscn` 静态占位 `"赐福 · 宁姆格福"`（草案 §1.5 第 4 条允许）；`grace_fast_travel` 的边校验按「当前赐福的**直接可达边**」实现（`.tres` 的 7 条边均为直接相邻），未做多级路径搜索；`current_id` 为空（尚无落点）时跳过边校验、改以目标节点自身 `requires_flags` 判定 |

### 3.2 阻塞

- **本轮无硬阻塞**：5 件交付全部落地；`--check-only` `EXIT=0`、实例化回读 `pass=6 fail=0 ok=true`、三段门禁复跑 `GATE_OVERALL_EXIT=0`，全部真跑通过。
- **下游依赖（非本轮阻塞）**：③ 第 2/3/4 项需装配层注册 `SaveDeltaWriter`、HOST 裁决 I-1 与落盘时序口径、以及菜单 UI 容器落地后方可端到端联调；③ 第 1 项需总指挥裁决容器类型。若 R15 Rank-1 对 `courtyard.tscn` 仍在改动，本轮对 `hud.tscn` 的脚本挂载因其为独立场景、以 `instance=ExtResource` 被引用，不产生写冲突。
- **既有 WARNING（非本轮引入）**：`ChunkManager 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`，历轮已登记为 WARNING / 非 ERROR，本轮未处理、未冒充全绿。
