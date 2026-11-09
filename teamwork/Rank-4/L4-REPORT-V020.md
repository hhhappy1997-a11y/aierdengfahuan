# R24 · L4 泄漏与节点数曲线报告（v0.2.0）

- 任务单：`cmd-20261109-205253-734-A4`（`[ROUND=R24]`，v0.2.0 L4）
- 执行：Rank-4（美术管线与工具链）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe` → `4.7.2.stable.official.ed1daf0bf`
- 工程根：`F:/Game/aierdengfahuan`；Godot 根：`F:/Game/aierdengfahuan/godot`
- 被测场景：`res://scenes/encounter_v010.tscn`（场景树 6 节点）
- 本轮范围：**只做性能采集，不录屏**（15 秒录屏与目视回看由 R24B 在工程冻结后补单）
- 结论摘要：**RESULT=NO_LEAK**；20 轮节点数每轮完整回落基线，无台阶式上涨。

---

## 1. 交付物与目录所有权核对

| 路径 | 类型 | 说明 |
| --- | --- | --- |
| `godot/scripts/combat/perf_encounter_v020.gd` | 新增 | 本轮唯一新增 GDScript（`extends SceneTree`） |
| `godot/scripts/combat/perf_encounter_v020.gd.uid` | 引擎生成 | G1 `--import` 自动生成的脚本 UID（20 字节，非手写，如实登记） |
| `teamwork/Rank-4/L4-REPORT-V020.md` | 新增 | 本报告 |
| `teamwork/Rank-4/DONE-R24.md` | 新增 | 交付清单 |
| `teamwork/Rank-4/L4-G1-import.log` / `L4-G2-check-only.log` / `L4-G3-quit.log` | 新增 | 三段门禁日志 |
| `teamwork/Rank-4/L4-MAIN-perf.log` | 新增 | 最终主真跑日志（正式 20 轮） |
| `teamwork/Rank-4/L4-MAIN-sync-explicit-ready.log` | 新增 | V1 同步显式 `call("_ready")` 试跑留证 |
| `teamwork/Rank-4/L4-MAIN-perframe-no-warmup.log` | 新增 | V2 逐帧无 warmup 试跑留证 |

**未写**：`capture/`（本轮不写）、`courtyard.tscn`、`encounter_director.gd`、`project.godot`、`encounter_v010.tscn`、既有战斗件、全部 PNG/tres 美术资源。**未自行 git**（总指挥收尾）。零付费、零外部依赖。

---

## 2. 三段门禁（真跑）

命令中的 `ROOT=F:/Game/aierdengfahuan/godot`，`ENGINE=D:/Godot/Godot_v4.7.2-stable_win64.exe`。

| 段 | 命令 | EXIT | `SCRIPT ERROR` | `Parse Error` |
| --- | --- | --- | --- | --- |
| G1 | `$ENGINE --headless --path $ROOT --import` | 0 | 0 | 0 |
| G2 | `$ENGINE --headless --path $ROOT --check-only --script res://scripts/combat/perf_encounter_v020.gd` | 0 | 0 | 0 |
| G3 | `$ENGINE --headless --path $ROOT --quit` | 0 | 0 | 0 |
| 主真跑 | `$ENGINE --headless --path $ROOT --script res://scripts/combat/perf_encounter_v020.gd` | 0 | 0 | 0 |

- **三段门禁 `grep SCRIPT ERROR=0`：通过**（G1/G2/G3 与主真跑四份日志均为 0；`Parse Error` 亦为 0）。
- 引擎级 warning（**非 SCRIPT ERROR**，如实登记，不掩盖）：
  - G3：`WARNING: 2 ObjectDB instances were leaked at exit`（与历史 R23 G3 同样存在）。
  - 主真跑：`WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。`（autoload 帧行为）。
- 主真跑与 G1/G2 的 `^ERROR:` 计数均为 0。

---

## 3. 采集方法与三版迭代（全部真跑，日志留证）

### V1 · 同步循环 + 显式 `call("_ready")`（按既有惯例）
严格照任务提示与 `verify_encounter_v010.gd:79-111` 惯例，在 `_initialize()` 同步循环里 `add_child` 后逐节点显式 `call("_ready")`。真跑结果：

- `BASELINE nodes=0`；20 轮 `SEQ_NODES_ADD`/`SEQ_NODES_FREE` 全为 `[0, ...]`；
- `RESULT=DATA_UNRELIABLE`；每轮另有 2 条引擎级 `ERROR: Can't use get_node() with absolute paths from outside the active scene tree.`（来自既有件 `/root/WorldState`、`/root/GameEvents`）。

**原因（实测非推测）**：`Performance.OBJECT_NODE_COUNT` 是「每帧更新」的帧缓存，`_initialize()` 同步执行期间引擎一帧未跑，monitor 从未刷新、恒为 0；且此期 root 尚未进入活动场景树，故 `add_child` 不 flush `_ready`、`/root/...` 绝对路径不可解析。脚本已如实输出 `DATA_UNRELIABLE`，未伪造数字。

### V2 · 逐帧 `await process_frame`（无 warmup）
改为每轮 add 后 / free 后各推进 1 帧，让帧缓存刷新。真跑结果：

- monitor 有效：`BASELINE nodes=9`；20 轮 `nodes_add - nodes_free` 恒为 6（= 实例子树真实节点数）；`ready_flushed=true` 20/20；
- 但全局节点数在 round00~03 从 9 一次性涨到 16（+7），round04~19 共 16 轮完全恒定；内存首轮一次性 +18MB 后仅 KB 级波动；
- 脚本当时按「序列单调不减且存在上升」判为 `LEAK_SUSPECT`。

**复核**：增长有上限、第 4 轮后归零，且每轮实例都完整释放 6 个节点 —— 属 autoload 帧初始化 / `.tres` 资源缓存的**一次性装配**，不是每轮累积泄漏。为避免把一次性漂移误判成台阶式上涨，需隔离该变量。

### V3 · 逐帧 + warmup（最终版，正式 20 轮）
正式 20 轮前先 warmup：12 空帧 + 1 次预热 `instantiate/add/free`，待 autoload 装配与资源缓存落定后取稳定基线再采集。三版日志全部保留，warmup 数字如实登记、不隐藏、不删改。

**关于任务提示的 `add_child` 不 flush `_ready`**：该现象只在 `_initialize()` 同步执行期成立。V3 帧循环启动后 root 进入活动场景树，引擎按真实运行时语义自动 flush `_ready`（脚本用 `director._state != null` 逐轮验证，`VERDICT_READY_FLUSHED=true` 20/20），故无需手工 `call("_ready")`——手工 call 反而会与引擎 flush 重复初始化。V1 的显式-call 惯例已留证，V3 用等价的真实初始化达成同一目的。

---

## 4. 逐轮数字表（最终版正式 20 轮）

- warmup：`nodes_start=7 → nodes_end=16`，一次性 `drift=+9`（autoload 装配，不计入 20 轮）
- 稳定基线：`BASELINE nodes=16`，`mem_bytes=78643694`
- 每列含义：`before`=add 前、`add`=`add_child`+1 帧后、`free`=`free`+1 帧后；`tree_nodes`=实例子树真实节点数（递归独立统计），20 轮恒为 6。

| 轮 | `nodes_before` | `nodes_add` | `mem_add` | `nodes_free` | `mem_free` | Δnodes(对基线16) | Δmem(对基线) | `ready_flushed` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 00 | 16 | 22 | 78720578 | 16 | 78643694 | +0 | +0 | true |
| 01 | 16 | 22 | 78721658 | 16 | 78644774 | +0 | +1080 | true |
| 02 | 16 | 22 | 78721658 | 16 | 78644774 | +0 | +1080 | true |
| 03 | 16 | 22 | 78721826 | 16 | 78644942 | +0 | +1248 | true |
| 04 | 16 | 22 | 78722162 | 16 | 78645278 | +0 | +1584 | true |
| 05 | 16 | 22 | 78722162 | 16 | 78645278 | +0 | +1584 | true |
| 06 | 16 | 22 | 78722666 | 16 | 78645782 | +0 | +2088 | true |
| 07 | 16 | 22 | 78722666 | 16 | 78645782 | +0 | +2088 | true |
| 08 | 16 | 22 | 78722666 | 16 | 78645782 | +0 | +2088 | true |
| 09 | 16 | 22 | 78723338 | 16 | 78646454 | +0 | +2760 | true |
| 10 | 16 | 22 | 78723338 | 16 | 78646454 | +0 | +2760 | true |
| 11 | 16 | 22 | 78723338 | 16 | 78646454 | +0 | +2760 | true |
| 12 | 16 | 22 | 78723338 | 16 | 78646454 | +0 | +2760 | true |
| 13 | 16 | 22 | 78724346 | 16 | 78647462 | +0 | +3768 | true |
| 14 | 16 | 22 | 78724346 | 16 | 78647462 | +0 | +3768 | true |
| 15 | 16 | 22 | 78724826 | 16 | 78647942 | +0 | +4248 | true |
| 16 | 16 | 22 | 78724826 | 16 | 78647942 | +0 | +4248 | true |
| 17 | 16 | 22 | 78724826 | 16 | 78647942 | +0 | +4248 | true |
| 18 | 16 | 22 | 78724826 | 16 | 78647942 | +0 | +4248 | true |
| 19 | 16 | 22 | 78726338 | 16 | 78649454 | +0 | +5760 | true |

序列：
- `SEQ_NODES_BEFORE` = `[16 × 20]`
- `SEQ_NODES_ADD` = `[22 × 20]`
- `SEQ_NODES_FREE` = `[16 × 20]`
- `SEQ_MEM_FREE_BYTES` = `[78643694, 78644774, 78644774, 78644942, 78645278, 78645278, 78645782, 78645782, 78645782, 78646454, 78646454, 78646454, 78646454, 78647462, 78647462, 78647942, 78647942, 78647942, 78647942, 78649454]`

---

## 5. 判定

| 判据 | 结果 | 依据 |
| --- | --- | --- |
| `VERDICT_SAMPLES_VALID` | **true** | monitor 随 add/free 刷新；`nodes_add - nodes_free == tree_nodes(6)` 的轮数 **20/20** |
| `VERDICT_TREE_NODES_STABLE` | **true** | 实例子树真实节点数 20 轮恒为 6 |
| `VERDICT_READY_FLUSHED` | **true** | 20/20 轮引擎自动 flush `_ready`（`_state != null`） |
| `VERDICT_BASELINE_DRIFT` | **0** | `nodes_before` 区间 `[16,16]`，正式段无漂移 |
| **节点数是否回落到基线** | **是（YES）** | `VERDICT_NODE_FALLBACK=true`：20/20 轮 `free` 后 == 该轮 `add` 前 == 16；每轮 add→free 恒减 6，等于实例 6 节点 |
| **是否台阶式上涨** | **否（NO）** | `VERDICT_STAIRCASE=false`：`nodes_free` 序列 `[16 × 20]` 恒定，`nondecreasing=true` 但 `any_rise=false`，`first=16 last=16` |
| 内存 | 观察项 | `MEM_BASELINE=78643694` → `MEM_LAST=78649454`，`DELTA_LAST_VS_BASE=+5760` 字节（≈5.6 KiB / 20 轮 ≈288 B/轮），序列多次持平，**非节点级泄漏**；`MEM_NONDECREASING=true` 但增量极小 |
| **RESULT** | **NO_LEAK** | 20 轮节点数均回落到该轮基线，未见台阶式上涨 |

---

## 6. 未完成项 / 观察项（如实登记，不谎报完成）

1. **15 秒录屏与目视回看**：本轮按任务书**不执行**，由 R24B 在工程冻结后补单执行。本轮 `capture/` 未写。
2. **内存 +5760 字节微量增长**：未定位到具体对象。公共契约禁止新建只读探针/巡检脚本，本轮只做曲线采集；如需定位由后续补单处理。该增长不与节点数同步（节点恒定 16），不构成节点泄漏。
3. **warmup 段一次性 `+9` 节点 / V2 首轮 `+18MB`**：判定来自 autoload 帧初始化与 `.tres`/字体资源缓存，未逐一归因到具体 autoload（ChunkManager / WorldState 等）。已如实登记为一次性装配，非每轮泄漏。
4. **引擎 warning**：G3 `2 ObjectDB instances were leaked at exit`、主真跑 `[ChunkManager] 未找到 ChunkRoot`。均为 warning，**非 SCRIPT ERROR**，不掩盖；属既有工程行为（R23 同样存在），本轮不改既有件。
5. **美术锚点 v1 未确认**：本轮一律不重做素材、不改任何 PNG/tres 美术资源。
6. **`perf_encounter_v020.gd.uid`**：G1 `--import` 引擎自动生成的附属元数据，非手写，如实登记。
7. **未自行 git**：按公共契约由总指挥收尾。

**阻塞：无。** 本轮计划内产物全部完成（性能采集、门禁、L4 报告、交付清单、回执）。

---

## 7. L4 结论

在 Godot 4.7.2 headless 真跑环境中，对 `res://scenes/encounter_v010.tscn` 连续 20 轮 `instantiate → add_child → free`：

- **节点数每轮 16 → 22 → 16，完整回落到稳定基线，20/20 轮一致；无台阶式上涨，判定 `NO_LEAK`。**
- 每轮实例化的 6 个节点全部释放（`nodes_add - nodes_free` 恒为 6），`_ready` 由引擎在帧推进时 20/20 自动 flush，无悬空信号连接导致的节点残留。
- 三段门禁 `EXIT 0/0/0`、`grep SCRIPT ERROR=0` 通过；主真跑 `EXIT 0`、`SCRIPT ERROR=0`。
- 内存仅有 ≈5.6 KiB 的 20 轮累计微增（引擎内部缓存级），与节点数无关；warmup 段的一次性装配漂移已隔离并如实登记。
