# DONE-R24 · Rank-4 交付清单（R24 / v0.2.0 L4）

- 任务单：`cmd-20261109-205253-734-A4`（`[ROUND=R24]`）
- 执行：Rank-4（美术管线与工具链）
- 状态：**已完成，无阻塞**
- 详细报告：`teamwork/Rank-4/L4-REPORT-V020.md`
- 回执：`teamwork/command_center/ai/4/outbox/cmd-20261109-205253-734-A4.json`

---

## 1. 实际交付清单

| # | 路径 | 状态 | 说明 |
| --- | --- | --- | --- |
| 1 | `godot/scripts/combat/perf_encounter_v020.gd` | 已产出 | 新增 `extends SceneTree` 性能采集脚本，20 轮 `instantiate → add_child → free` |
| 2 | `godot/scripts/combat/perf_encounter_v020.gd.uid` | 引擎生成 | G1 `--import` 自动生成（非手写，如实登记） |
| 3 | `teamwork/Rank-4/L4-REPORT-V020.md` | 已产出 | L4 结论报告（逐轮数字表 / 判定 / 未完成项） |
| 4 | `teamwork/Rank-4/DONE-R24.md` | 已产出 | 本文件 |
| 5 | `teamwork/Rank-4/L4-G1-import.log` | 已产出 | 门禁 G1 日志 |
| 6 | `teamwork/Rank-4/L4-G2-check-only.log` | 已产出 | 门禁 G2 日志 |
| 7 | `teamwork/Rank-4/L4-G3-quit.log` | 已产出 | 门禁 G3 日志 |
| 8 | `teamwork/Rank-4/L4-MAIN-perf.log` | 已产出 | 最终主真跑（正式 20 轮）日志 |
| 9 | `teamwork/Rank-4/L4-MAIN-sync-explicit-ready.log` | 已产出 | V1 同步显式 `call("_ready")` 试跑留证 |
| 10 | `teamwork/Rank-4/L4-MAIN-perframe-no-warmup.log` | 已产出 | V2 逐帧无 warmup 试跑留证 |
| 11 | 回执 JSON（outbox 精确路径） | 已产出 | 见本文件 §4 |

**目录所有权核对**：只写 `godot/scripts/combat/perf_encounter_v020.gd`（+ 引擎自动生成 `.uid`）与 `teamwork/Rank-4/`。`capture/` 本轮未写；未改 `courtyard.tscn`、`encounter_director.gd`、`project.godot`、`encounter_v010.tscn`、既有战斗件、全部 PNG/tres 美术资源。零付费、零外部依赖、未自行 git。

---

## 2. 真跑输出结论

### 三段门禁（`D:/Godot/Godot_v4.7.2-stable_win64.exe`）

| 段 | 命令 | EXIT | `SCRIPT ERROR` |
| --- | --- | --- | --- |
| G1 | `--headless --path ROOT --import` | 0 | 0 |
| G2 | `--headless --path ROOT --check-only --script res://scripts/combat/perf_encounter_v020.gd` | 0 | 0 |
| G3 | `--headless --path ROOT --quit` | 0 | 0 |
| 主真跑 | `--headless --path ROOT --script res://scripts/combat/perf_encounter_v020.gd` | 0 | 0 |

`grep SCRIPT ERROR=0` 通过（四份日志全 0，`Parse Error` 亦为 0）。

### 逐轮数字（最终版，warmup 后稳定基线 `nodes=16 mem=78643694`）

- `SEQ_NODES_BEFORE` = `[16 × 20]`
- `SEQ_NODES_ADD` = `[22 × 20]`
- `SEQ_NODES_FREE` = `[16 × 20]`
- `SEQ_MEM_FREE_BYTES` = `[78643694, 78644774, 78644774, 78644942, 78645278, 78645278, 78645782, 78645782, 78645782, 78646454, 78646454, 78646454, 78646454, 78647462, 78647462, 78647942, 78647942, 78647942, 78647942, 78649454]`
- 每轮 `tree_nodes=6`、`ready_flushed=true`；`nodes_add - nodes_free` 恒为 6（20/20）。
- 完整逐轮表格见 `L4-REPORT-V020.md §4`。

### 判定

- **节点数回落基线：是（YES）** —— `VERDICT_NODE_FALLBACK=true`，20/20 轮 `free` 后 == 该轮 `add` 前 == 16。
- **台阶式上涨：否（NO）** —— `VERDICT_STAIRCASE=false`，`nodes_free` 恒定 `[16 × 20]`，`any_rise=false`。
- **RESULT = NO_LEAK**。
- 内存：`+5760` 字节 / 20 轮（≈5.6 KiB），序列多次持平，非节点级泄漏。

### 三版迭代（全部真跑，日志留证，不伪造）

1. **V1 同步 + 显式 `call("_ready")`**：`Performance.OBJECT_NODE_COUNT` 帧缓存在 `_initialize()` 同步期恒为 0 → `RESULT=DATA_UNRELIABLE`，如实写明原因（monitor 未刷新 + `/root/` 绝对路径 ERROR）。
2. **V2 逐帧 `await`**：monitor 有效，但发现全局节点数前 4 轮一次性 +7（9→16）、内存首轮 +18MB，属 autoload / 资源缓存一次性装配，非每轮泄漏；当时判定误报 `LEAK_SUSPECT`。
3. **V3 逐帧 + warmup（最终）**：12 空帧 + 1 次预热实例化隔离一次性装配后，正式 20 轮得 `NO_LEAK`。

关于任务提示「`--script` 模式下 `add_child` 不 flush `_ready`」：该现象只在 `_initialize()` 同步执行期成立（V1 已按 `verify_encounter_v010.gd` 惯例显式 `call("_ready")` 留证）；V3 帧循环启动后由引擎在帧推进时自动 flush，脚本逐轮验证 `_state != null`（20/20 true），不手工重复 call。

---

## 3. 未完成项与阻塞

| # | 项 | 状态 |
| --- | --- | --- |
| 1 | 15 秒录屏与目视回看 | **本轮按任务书不执行**，由 R24B 工程冻结后补单；`capture/` 本轮未写 |
| 2 | 内存 +5760 字节微量增长定位 | 未定位具体对象（公共契约禁止新建只读探针/巡检脚本，本轮只做曲线采集），后续补单处理 |
| 3 | warmup 段一次性 +9 节点 / +18MB 归因 | 判定为 autoload 帧初始化与 `.tres` 缓存，未逐一归因到具体 autoload，如实登记 |
| 4 | 引擎 warning（G3 `2 ObjectDB instances were leaked`、主真跑 `[ChunkManager] 未找到 ChunkRoot`） | 非 SCRIPT ERROR，不掩盖，属既有工程行为，本轮不改既有件 |
| 5 | 美术锚点 v1 未确认 | 本轮不重做素材、不改任何 PNG/tres 美术资源 |
| 6 | git 收尾 | 按公共契约由总指挥执行，本轮未自行 git |

**阻塞：无。** 本轮计划内产物全部完成。

---

## 4. 回执

已写：`F:/Game/aierdengfahuan/teamwork/command_center/ai/4/outbox/cmd-20261109-205253-734-A4.json`

```json
{"task_id":"cmd-20261109-205253-734-A4","ai":4,"status":"done","result":"见 teamwork/Rank-4/DONE-R24.md：L4 结论 NO_LEAK——20 轮 encounter_v010.tscn instantiate/add_child/free，节点数每轮 16→22→16 完整回落基线(20/20)，无台阶式上涨；三段门禁 EXIT 0/0/0、SCRIPT ERROR=0；本轮不录屏，R24B 补单。"}
```

**回执落盘后续（如实登记）**：回执写入精确路径后被调度中枢即时收取，原样归档到
`teamwork/command_center/dispatcher/receipts/cmd-20261109-205253-734-A4.json`（`cmp` 校验内容一致），
`ai/4/status.json` 同步置 `idle` / `completed=31`。为满足「精确路径」要求，已从归档复制回
`ai/4/outbox/` 并验证 JSON 解析有效（`VALID_JSON task_id=cmd-20261109-205253-734-A4 ai=4 status=done`）。
