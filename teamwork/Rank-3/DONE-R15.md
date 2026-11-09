# DONE-R15.md · R15 完成标志

> 命令 `cmd-20261109-083628-784-A3` · `[ROUND=R15]` · Rank-3（RPG / 世界 / 存档）
> 状态：**done（按边界只交付方案）** · 中文 UTF-8 · 零付费 · 默认不刺探 · 不伪造输出

---

## ① 交付清单

| # | 交付件 | 动作 | 内容 |
|---|---|---|---|
| 1 | `teamwork/Rank-3/HUD-BINDING.md` | **新建** | 方案文档，覆盖任务书 4 点：<br>§1 金色 `TitleLabel` 与 `WorldState` 三段式 flag（如 `grace.limgrave_gatefront.lit`）绑定映射、`get_flag(key, default)` 的 4 个调用时机与「事件驱动 + 一次全量、禁止每帧轮询」刷新策略；<br>§2 赐福菜单用 `grace_network.tres` 8 节点 / 7 边数据驱动（文本 / 分组 / 排序 / 门控全取自 `.tres`），并给出 `grace_fast_travel` 强制落盘口径（先 `commit` 后发 `travel_requested`、不进 0.5 s 合并窗口、I-1 边界）；<br>§3 `hud.gd` 接口草案（4 个信号 + 16 个方法签名，只给草案不实现）；<br>§4 接入主场景时机与依赖（R15 由 Rank-1 挂 HUD、R16 再绑数据，附 6 项前置依赖与冲突规避）；<br>§5 口径对齐自检、§6 未完成项与阻塞 |
| 2 | `teamwork/Rank-3/DONE-R15.md` | **新建** | 本件：①交付清单 ②自检 ③未完成项与阻塞 |
| 3 | `teamwork/command_center/ai/3/outbox/receipt_cmd-20261109-083628-784-A3.json` | **新建** | 回执 JSON：`{"task_id":"cmd-20261109-083628-784-A3","ai":3,"status":"done","result":"引用 DONE-R15.md 实际结论"}` |

**明确未产出 / 未改动（按边界）**：

- 未改 `godot/scenes/courtyard.tscn`（Rank-1 本轮独占）；
- 未改 `godot/scenes/hud.tscn`（R16 才挂脚本 / 加菜单容器）；
- 未落盘 `hud.gd`（只给接口草案，不实现）；
- 未运行 Godot、未真跑 `--script` / `pack()`、未贴任何本轮运行期 stdout；
- 未自行 git（commit / push 均未执行）；
- 未追加 / 修改 `00-群聊总线.md`（本件非接口变更 / 里程碑交付 / 阻塞求助 / 回应 @ 四类事件，按协议不追加）。

---

## ② 自检

### 2.1 任务点覆盖

| 任务书要求 | 落点 | 结论 |
|---|---|---|
| ① 金色 Label ↔ 三段式 flag 绑定，给 `get_flag(key, default)` 调用时机与刷新策略 | `HUD-BINDING.md §1`（映射表 §1.3 / 时机 §1.4 / 策略 §1.5） | ✅ 覆盖 |
| ② 赐福菜单用 8 节点 / 7 边数据驱动，`grace_fast_travel` 强制落盘口径 | `HUD-BINDING.md §2`（§2.2 构建 / §2.3 边校验 / §2.4 落盘顺序与 I-1） | ✅ 覆盖 |
| ③ `hud.gd` 接口草案（方法签名、信号，只给草案不实现） | `HUD-BINDING.md §3`（§3.2 信号 / §3.3 签名 / §3.4 边界） | ✅ 覆盖，未写函数体 |
| ④ 接入主场景时机与依赖（R15 Rank-1 挂 HUD，R16 再绑数据） | `HUD-BINDING.md §4`（§4.1 时间线 / §4.2 六项依赖 / §4.3 冲突规避） | ✅ 覆盖 |

### 2.2 口径与依据自检

- 6 份必读件**开工一次性读完**：`hud.tscn`、`HUD-SPEC.md`、`HUD-ATTACH.md`、`grace_network.tres`、`SAVE-SPEC-FINAL.md`、`00-群聊总线.md`；本工位既有件只读核对（`grace_network.md`、`RPG系统设计.md` §4.2、`chunk_world_bridge.gd`、`world_state.gd`），未跨工位刺探。
- 三段式 flag 采用 `grace.limgrave_gatefront.lit`，与 `MSG-20261109-0400-HOST` 裁决 A6（A8 两段式示例回改严格三段式）一致；未沿用 `SAVE-SPEC-FINAL.md §2` 中标注「待裁决」的两段式示例。
- `grace_fast_travel` 口径取自 `chunk_world_bridge.gd:43` 常量 + `grace_network.md §4.3` + `RPG系统设计.md §4.2`；引用的 `W7 PASS` / `T3_COMMIT_REASON` 为**既有轮次结论**，已标注「非本轮真跑」，未冒充本轮输出。
- 8 节点 / 7 边、字段名、边条件与 `godot/data/rpg/grace_network.tres` 逐字对齐；运行期数据源明确为 `res://data/rpg/grace_network.tres`，未误用工位内 R2 快照。

### 2.3 硬约束自检

| 约束 | 结论 |
|---|---|
| 只写文档，不改 `courtyard.tscn` / `hud.tscn` | ✅ |
| 不自行 git | ✅ |
| 零付费（无付费 API / 云服务 / 外部服务） | ✅ |
| 默认不刺探（仅本工位 + 中枢派单/回执约定只读核对） | ✅ |
| 不伪造输出（无本轮真跑数据；既有实证均标注来源与非本轮） | ✅ |
| 中文 UTF-8 | ✅ |
| 回执 `task_id` 取本轮派单 id `cmd-20261109-083628-784-A3`（经 `inbox/task_cmd-20261109-083628-784-A3.json` 核对） | ✅ |

---

## ③ 未完成项与阻塞

> **按边界只交付方案**：本轮任务书限定「方案文档，不写场景」、`hud.gd`「只给草案不实现」、R15 由 Rank-1 挂 HUD、R16 再绑数据。下列项均属**方案边界外 / 下游轮次**，不是本轮遗漏，也不是本轮阻塞，一律如实登记、不擅自推进、不伪造完成。

### 3.1 未完成项（边界外，交后续轮次）

| # | 项 | 归属轮次 / 工位 | 说明 |
|---|---|---|---|
| 1 | `hud.gd` 实现、落盘、`--check-only` 语法门禁 | R16 / Rank-3 | 本轮仅 §3 签名与信号草案 |
| 2 | `hud.tscn` 挂 `hud.gd` 脚本、新增赐福菜单容器节点 | R16 / Rank-3 | 当前场景只有 `Hud` / `HudPanel` / `TitleLabel` 3 节点 |
| 3 | 金色 Label 点亮态、菜单与 `WorldState` / `GameEvents` 端到端联调 | R16 / Rank-3 | 需 R15 HUD 挂载完成后才有载体 |
| 4 | `last_grace_id` 空值回退文案、菜单容器类型、`hud.gd` 是否注册 `class_name` | R16 裁决 | 本轮只给默认 `""` + 占位文本回退口径，不擅自定死 |
| 5 | HUD 实例挂入 `courtyard.tscn`（22→23、回读校验、执行前后哈希） | R15 / **Rank-1** | 本轮 Rank-1 独占该场景，Rank-3 不碰 |

### 3.2 阻塞

- **本轮无阻塞**：方案文档、`DONE-R15.md`、回执三件均已产出，任务书 4 点全部覆盖并自检通过。
- **下游依赖（非本轮阻塞）**：R16 绑数据的前置条件为 ① Rank-1 完成 R15 串行挂 HUD 且场景稳定；② `WorldState` autoload、`res://data/rpg/grace_network.tres`、`GameEvents`、`travel_requested → commit("grace_fast_travel")` 链路就绪（详见 `HUD-BINDING.md §4.2` 六项）。若 R15 Rank-1 挂载未成，R16 数据绑定无载体，需按 `HUD-ATTACH.md §2` 等场景稳定后串行推进。
- **待裁决沿用**：A8 两段式示例已由总指挥裁决回改三段式（本件已按裁决执行）；无新增待裁决项。
