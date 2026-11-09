# DONE-R20B · 修复 wire_r19.gd 节点数门槛回归

- 补单 id：`cmd-20261109-113331-243-A1`（[ROUND=R20B]）
- 角色：Rank-1 执行 AI（引擎架构与渲染）
- 总指挥裁决：A10（R20 实例化 QualitySettings 后 courtyard.tscn 节点数 24→25，导致 R19 遗留 `const EXPECTED_NODES: int = 24` 在 STEP3 硬门槛 EXIT=1）
- 日期：2026-11-09
- 结论：**PASS**（真跑 EXIT=0、VERIFY_SUMMARY fail=0、三段门禁 SCRIPT ERROR=0）

---

## 一、改动点（仅改 `godot/scripts/wire_r19.gd`，行号为改动后文件行号）

| 行号 | 改动 |
| --- | --- |
| 18–21 | 顶部注释：原「节点数硬门槛：pack 前 24 → pack 后 24」改为「节点数动态基线门槛」——以 STEP3 CACHE_MODE_IGNORE 磁盘读回的 before_nodes 为本次复核基线，断言 pack 前/后节点数相等，并追加下限 `before_nodes >= MIN_NODES(24)` |
| 32 | `const EXPECTED_NODES: int = 24` → `const MIN_NODES: int = 24`（语义由「固定相等门槛」改为「下限」，不再是判等目标值） |
| 39 | 新增成员变量 `var _baseline_nodes: int = -1`（保存 STEP3 磁盘读回的 before_nodes 动态基线，供 _verify ② 使用） |
| 89–95 | STEP3：新增 `_baseline_nodes = before_nodes`；print 增 `baseline=%d (dynamic)`；原 `if before_nodes != EXPECTED_NODES:`（文案「!= 24」）改为下限断言 `if before_nodes < MIN_NODES:`，文案改「< 下限 %d，场景结构可能被破坏」 |
| 142 | STEP7 注释：原「硬门槛 24→24」改为「动态基线：after==before 不增删节点」 |
| 150–153 | STEP7：`count_ok` 由 `(before_nodes==EXPECTED_NODES) and (after_nodes==EXPECTED_NODES) and (after_nodes==before_nodes)` 改为 `(before_nodes >= MIN_NODES) and (after_nodes == before_nodes)`（下限定 + pack 前/后相等）；print 去掉写死 `expected=%d`，改为 `baseline=%d min=%d`，仍打印 `NODE_COUNT before/after` |
| 232–233 | _verify ②：标签 `SceneState_node_count_24` → `SceneState_node_count_stable`；判断 `disk_nodes == EXPECTED_NODES` → `disk_nodes == _baseline_nodes and disk_nodes >= MIN_NODES`；文案 `expected=%d` → `baseline=%d min=%d` |

**写死值清理**：改后全文已无 `EXPECTED_NODES`、`24→24`、`!= 24`、`SceneState_node_count_24`、`pack 前 24`、`expected=24`；唯一保留的 `24` 是 `MIN_NODES=24` 下限，唯一残留的 `expected=%d` 是 ④ layer=10 既有断言文案（与节点数无关，逐字保留）。

**逐字保留、一条不删不放宽**（未在以上 7 处之列）：
- pack 探针（STEP7 `probe` / `PACK_PROBE` 的 script_ok / instance / children_ok / runtime_nodes）
- controller 脚本挂载（STEP5 `set_script` / `get_script()` 回读 / attach_ok）
- _verify ①③④⑤⑥⑦ 全部断言（含 ④ layer=10、⑥ controller_script_attached、⑦ switch_profile_method_available）
- ⑧ R18 6 项接线表 for 循环（fx_profile_source / active / desktop_preset / mobile_preset / desktop_value / mobile_value）
- ⑨ 4 个 FX 子节点脚本 hd2d_fx.gd 断言
- ⑩ _ready desktop 4/4、⑪ switch_profile(mobile) 4/4、⑫ switch_profile(desktop) 4/4
- STEP1 备份、STEP2 preset 判档、STEP4 结构校验、STEP6 owner 链、STEP8 保存、STEP9 回读，及 `_backup/_read_profiles/_profiles_match/_fmt_profiles/_check/_reset_owner/_count/_free_tree`
- 未改任何其它工程文件：`courtyard.tscn` / `quality_settings.gd|tscn` / `fx_profile_controller.gd` / `project.godot` / `hud.gd` / `hd2d_fx.*` 全部未触碰

---

## 二、真跑 stdout 关键行

命令：
```
D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/wire_r19.gd
```

- **EXIT=0**
- 关键输出（原样摘录）：
```
[R19] === WIRE R19 START (cmd-20261109-102334-086-A1) ===
[R19] STEP2 controller load OK path=res://scripts/fx_profile_controller.gd class=GDScript
[R19] STEP2 PRESET desktop.low_resolution_size=(640, 360) mobile=(480, 270) desktop_gt_mobile=true
[R19] STEP3 CACHE_MODE_IGNORE load OK, SceneState node_count(before)=25 baseline=25 (dynamic)
[R19] STEP5 ALREADY_ATTACHED=true，controller 已挂载，跳过写盘（复核模式）
[R19] STEP5 get_script()=res://scripts/fx_profile_controller.gd attach_ok=true
[R19] STEP7 NODE_COUNT before=25 after=25 baseline=25 min=24 pack_err=0 count_ok=true
[R19] STEP7 PACK_PROBE script_ok=true instance=true children_ok=true runtime_nodes=31 probe_ok=true
[R19] STEP8 SKIP_SAVE（复核模式，不写盘）
[R19_VERIFY] readback class=PackedScene resource_path=res://scenes/courtyard.tscn SceneState_nodes=25
[R19_VERIFY] ② SceneState_node_count_stable PASS=true | nodes=25 baseline=25 min=24
[R19_VERIFY] ⑨ child_script_hd2d_fx_all_4 PASS=true | FXReflection:script=res://scripts/hd2d_fx.gd | FXGodRays:... | FXMotes:... | FXBloom:...
[R19_VERIFY] ⑩ _ready 自动判档 desktop 4/4 四项全开 PASS=true
[R19_VERIFY] ⑪ switch_profile(mobile) 4/4 四项全关 PASS=true
[R19_VERIFY] ⑫ switch_profile(desktop) 4/4 四项全开 PASS=true
[R19_VERIFY] VERIFY_SUMMARY pass=17 fail=0 OK=true
[R19] === WIRE R19 END verify_ok=true ===
```
- **NODE_COUNT before=25 after=25 baseline=25 min=24 count_ok=true**（动态基线为 STEP3 磁盘读回值 25，pack 后不变）
- **VERIFY_SUMMARY pass=17 fail=0 OK=true**
- 主脚本 `grep SCRIPT ERROR` = **0**

---

## 三、PASS 数字（如实登记）

- 本轮 R20B **本次真跑实测**：`VERIFY_SUMMARY pass=17 fail=0 OK=true`，EXIT=0。
- 这 17 条来自本次命令 stdout 的 17 条 `_check`：①②③④⑤⑥⑦（7）+ ⑧ 6 项接线表（6）+ ⑨（1）+ ⑩⑪⑫（3）= 17。
- **声明**：17 是本轮 R20B 真跑输出的实测值，**不是**引用/冒充 R19 的历史「17 PASS」结论；本轮 ② 虽按裁决改了标签/判断/文案，但断言条数未删未减，全部 17 条既有断言逐字保留。

---

## 四、三段门禁（各段独立 CLI 真跑，grep SCRIPT ERROR）

| 段 | 命令 | EXIT | SCRIPT ERROR |
| --- | --- | --- | --- |
| GATE1 | `--headless --path <root> --import` | 0 | 0 |
| GATE2 | `--headless --path <root> --check-only --script res://scripts/fx_profile_controller.gd` | 0 | 0 |
| GATE3 | `--headless --path <root> --quit` | 0 | 0 |
| 附加自检 | `--headless --path <root> --check-only --script res://scripts/wire_r19.gd`（本轮改动文件语法自检，非任务要求三段之一） | 0 | 0 |

- 四段日志合并 `grep -c "SCRIPT ERROR"` = **0**，`GATES_SCRIPT_ERROR_ZERO=YES`。
- 说明：汇总 shell 末条 `grep -c` 因 0 匹配返回退出码 1，是 grep 语义（无匹配），**非门禁失败**；各 Godot 段 EXIT 均为 0，已用干净汇总命令复核 Exit=0。

---

## 五、未完成项 / 非失败观察

- **未完成项：无。** 本轮 5 项要求（动态基线、下限断言、文案清理、既有断言逐字保留、只改 wire_r19.gd）全部达成，真跑与三段门禁全部通过。
- 非失败观察（如实登记，均不影响裁决项、EXIT 仍为 0）：
  - 主脚本与 `--quit` 段尾部有引擎既有告警：`WARNING: [ChunkManager] 未找到 ChunkRoot` 与 `WARNING: 2 ObjectDB instances were leaked at exit`，属 autoload/退出期告警，非 `SCRIPT ERROR`。
  - 本次为「复核模式」（STEP5 `ALREADY_ATTACHED=true`），STEP8 `SKIP_SAVE` 不写盘，尊重并发约定。
  - R20 引入的第 25 个节点（QualitySettings 实例）按裁决 A10 保留，未改 `courtyard.tscn`；下限断言 `25 >= 24` 通过，场景结构未被破坏。
- 回执（精确投递路径）：`F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261109-113331-243-A1.json`，含 `task_id / ai=1 / status=done / result` 四字段，JSON 合法性已校验通过。
- 回执路由实情（如实，不谎报）：`ai/1/outbox/` 是调度中枢**实时监控的投递口**。首次写入精确路径后，调度中枢于 `2026-11-09 11:44:01` 消费该回执（`ai/1/status.json` 显示 `state:idle`、`current_task:""`、`completed:27`），并归集到 `teamwork/command_center/dispatcher/receipts/cmd-20261109-113331-243-A1.json`（同在 `command_center/` 下，1039 字节，内容与精确路径一致，JSON 解析 `RECEIPTS_OK ... ai=1 done`）。为验证精确路径可写，曾再次 Write 及用真实文件系统层 `cp` 复位到精确路径，两者均在「同一条命令内立即 `ls` / `cat` / JSON 校验通过」（11:49 文件系统层确认 1039 字节、`JSON_OK`）；但下一条命令（11:50）复查时精确 outbox 路径又为空——确认是调度器实时消费（搬移）所致，**非写错路径、非写入失败、非内容错误**。结论：回执已按精确路径投递且被调度中枢成功接收，持久副本稳定在 `dispatcher/receipts/`；两处均在 `teamwork/command_center/` 下，回执路径正确。
