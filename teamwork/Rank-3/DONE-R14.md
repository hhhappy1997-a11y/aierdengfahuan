# DONE-R14.md · Rank-3 完成标志

> 命令 `cmd-20261109-082141-610-A3` · `[ROUND=R14]` · Rank-3（RPG / 世界 / 存档）
> 引擎 `D:\Godot\Godot_v4.7.2-stable_win64.exe`（`v4.7.2.stable.official.ed1daf0bf`）
> 依据：`teamwork/Rank-3/HUD-SPEC.md`（R13）、`teamwork/Rank-3/DONE-R13.md`（R13）、
> `godot/scenes/hud.tscn`、`teamwork/00-群聊总线.md`（开工只读一次）。
> 本件所有 `stdout` 均为本机真跑实际输出，未伪造、未改写。

## ① 交付清单

| # | 文件 | 类型 | 说明 |
|---|---|---|---|
| 1 | `godot/scripts/attach_hud.gd` | 新增 | `extends SceneTree` HUD 接入件：courtyard 实例化 → `hud.tscn` 以实例挂到 `SubViewportContainer/SubViewport/FXLayer` → 只给新节点及其子节点设 `owner` → `PackedScene.pack()` 前后按 `get_state().get_node_count()` 比对 22→23 → `CACHE_MODE_IGNORE` 回读校验 HUD 存在 |
| 2 | `teamwork/Rank-3/HUD-ATTACH.md` | 新增 | 执行时机（R15 串行改场景）、命令、节点数预期与口径、回退方式 |
| 3 | `teamwork/Rank-3/DONE-R14.md` | 新增 | 本件 |
| 4 | `teamwork/command_center/ai/3/outbox/cmd-20261109-082141-610-A3.json` | 新增 | 回执 JSON |

> 回执投递记录（如实）：本件写入 `ai/3/outbox/` 后，被调度中枢于 `2026-11-09 08:30` 消费至
> `command_center/dispatcher/receipts/cmd-20261109-082141-610-A3.json`（同名、内容逐字一致，
> 513 字节），`ai/3/status.json` 同步为 `state=idle / completed=14`。终态 `ai/3/outbox/` 为空、
> 正式回执稳定落在 `dispatcher/receipts/`（复核 `JSON_OK task_id=cmd-20261109-082141-610-A3
> / ai=3 / status=done`）。此为中枢自动回收的正常闭环，非本工位重复派单或伪造回执；
> 参照 `DONE-R13.md` §① 口径，本工位不再重复投递以免干扰中枢状态机。

**只读、未改动（守边界）**：`godot/scenes/courtyard.tscn`（哈希前后一致，见 §2.2）、
`godot/scenes/Main.tscn`、`player.tscn`、`boss_01_margit.tscn` 及 `godot/scenes/world/` 全部主场景；
`godot/scripts/` 下其它 `.gd`（仅只读参考 `build_hud.gd`、`combat/attach_boss_to_courtyard.gd`、
`render/attach_hd2d_placeholder.gd`、`render/hd2d_placeholder_attach.gd`，用于对齐 Godot 4 合法写法）；
其它工位 `Rank-1 / Rank-2 / Rank-4`；`teamwork/00-*.md`（总纲 / 契约 / 群聊总线 / 台账 / 汇总）；
`command_center/ai/3/inbox/` 任务单。
**未接入任何主场景**（任务书硬边界）。**未自行 git**（commit / push 均未执行）。

## ② 自检（含 `--check-only` 实际输出）

### 2.1 真跑命令与 `--check-only` 实际输出

命令：

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --check-only --script "res://scripts/attach_hud.gd"
```

第 1 次真跑实际 stdout（完整）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

GODOT_EXIT=0
```

第 2 次复核（同命令，附主场景哈希前后对比与错误计数）实际 stdout（完整）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
GODOT_EXIT=0
COURTYARD_SHA256_BEFORE=d70ae5b76992a5f3552bee851cca7b701608e676ebb7938d78b75de92758f395
COURTYARD_SHA256_AFTER=d70ae5b76992a5f3552bee851cca7b701608e676ebb7938d78b75de92758f395
COURTYARD_UNCHANGED=true
SCRIPT_ERROR_COUNT=0
PARSE_ERROR_COUNT=0
ERROR_COUNT=0
```

结论：`GODOT_EXIT=0`；`SCRIPT ERROR` / `Parse Error` / `ERROR:` 计数均为 **0**
（按契约 §4.2 口径对实际输出逐行核对，计数由 shell 纯内建 `case` 匹配得出）。
输出中**只有引擎 banner、没有任何脚本内 `print` 日志**，证明 `--check-only` 只解析脚本、
未调用 `_initialize()`，即**未执行写入逻辑**（与 `DONE-R13.md` §2.2 的 G2 口径一致）。

### 2.2 主场景未被写入（哈希实证）

`courtyard.tscn` 在 `--check-only` 前后 sha256 同为
`d70ae5b76992a5f3552bee851cca7b701608e676ebb7938d78b75de92758f395`，
`COURTYARD_UNCHANGED=true` → **按边界未写入主场景**成立。

### 2.3 脚本逻辑与任务项逐条核对（静态核对，非真跑结论）

| 任务项 | 落点 | 状态 |
|---|---|---|
| `extends SceneTree` | `attach_hud.gd` 首行 + `func _initialize()` | 语法经 `--check-only` 验证 |
| `load("res://scenes/courtyard.tscn")` → `instantiate()` | `_initialize()` | 已写 |
| `load("res://scenes/hud.tscn").instantiate()` 挂到 `FXLayer` 下 | `fx.add_child(hud)`，`FXLAYER_PATH` 常量 | 已写 |
| 设 owner（只给新节点及其子节点） | `_assign_owner_added(hud, root)` 递归；既有 22 节点 owner 不动 | 已写 |
| `PackedScene.pack()` 前后比对节点数（预期 22→23） | `src.get_state().get_node_count()` → `packed.get_state().get_node_count()`，常量 `EXPECTED_NODES_BEFORE=22` / `AFTER=23` | 已写断言；**本轮未真跑** |
| `CACHE_MODE_IGNORE` 回读校验 HUD 存在 | `_verify_hud_exists()` | 已写；**本轮未真跑** |

> 口径说明（详见 `HUD-ATTACH.md` §4）：22→23 统计的是 `.tscn` 内 `[node]` 段数
> （`SceneState.get_node_count()`），HUD 以 `instance=ExtResource(...)` 挂入只占 1 段；
> 运行期 `instantiate()` 会展开实例，整树递归节点数为 25，属正常实例展开，不是错误。

### 2.4 未真跑的部分（如实登记）

本轮**只跑 `--check-only`**，按任务书硬边界「不要调用这个脚本把 HUD 写进 courtyard.tscn」，
**未执行** `--script`（不带 `--check-only`）真跑，因此：

- 未取得 `NODE_COUNT` / `PROBE` / `SAVE_OK` / `VERIFY_SUMMARY` 等脚本内实际 stdout；
- 未产生 `courtyard.tscn` 的任何改动（§2.2 哈希实证）；
- pack 节点数 22→23、`CACHE_MODE_IGNORE` 回读校验均为**脚本内设计与断言**，未取得运行期验证输出。

## ③ 未完成项与阻塞

| # | 项 | 性质 | 说明 |
|---|---|---|---|
| 1 | **按边界未写入主场景** | **按任务书硬边界，预期未完成** | R14 只 `--check-only` 验证语法，`courtyard.tscn` sha256 前后一致、零改动；HUD 接入动作整体顺延 **R15 串行改场景**（Rank-1 本轮并发改同一场景，避免写冲突）。执行时机 / 命令 / 回退见 `HUD-ATTACH.md` §2 / §3 / §6 |
| 2 | 未真跑 pack / 节点数 22→23 / `CACHE_MODE_IGNORE` 回读 | 按边界未执行 | 属脚本内设计预期与断言，R14 未取得实际输出；R15 真跑后以 stdout 的 `NODE_COUNT` 实际行为准，不符则脚本如实 `quit(1)`、不伪造 |
| 3 | 实例标记 `scene_file_path` 的运行期效果未经真跑验证 | 待 R15 | 若引擎未把 HUD 写成 `instance=ExtResource`，真实 `get_node_count()` 会是 25；脚本会如实报错退出，交调度裁决，不擅自改预期值 |
| 4 | 未做运行期可见性 / 截图验收 | 本轮范围外 | 未把 HUD 挂进主场景渲染，不宣称主画面已出现 UI |
| 5 | 既有 WARNING 未处理 | 跨工位 | `ChunkManager` / `ObjectDB leaked` 属历轮登记的工程既有现象；本轮 `--check-only` 实际输出未出现 WARNING / ERROR |

> **无本轮硬阻塞**：命令要求的交付物（`attach_hud.gd`、`HUD-ATTACH.md`、`DONE-R14.md`、
> 回执 JSON）全部落地；`--check-only` 真跑 `GODOT_EXIT=0` 且 `SCRIPT ERROR` /
> `Parse Error` / `ERROR` 计数全 0，主场景哈希前后一致证明零写入。上述项均为
> 「按边界不做 / 顺延 R15 / 后续迭代 / 跨工位登记」，不影响本轮完成判定。
