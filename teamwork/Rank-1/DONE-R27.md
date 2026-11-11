# DONE-R27 · Rank-1 交付（cmd-20261111-083350-232-A1 / [ROUND=R27] / v0.5.0 完善旧内容）

- 执行 AI：Rank-1（引擎架构与渲染）
- 工程根：`F:/Game/aierdengfahuan`；Godot 工程 `F:/Game/aierdengfahuan/godot`；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
- **结论速览**：五项完善全部落地并真跑实证 —— ① SaveSystem 占位接线，真实场景 `_ready()` 经 `WorldState._load()` 自动读回磁盘，两独立引擎进程「写 → 重启读回」`best_wave=7 / points=1337 / completed=true` 跨进程恢复一致；② 底部战斗 HUD 动作帧从恒 `idle 0/0` 推进到 `attack_light 0/27 → 1/27`；③ 波次 HUD 赐福点数改显示持久化余额 `points - spent_points`（1300 / 1000 / 跨局不归零）；④ 赐福标题读三段式 flag（试炼完成 / 赐福休息）由暗灰 DIM 变亮金 GOLD；⑤ 新 `verify_persistence_hud_v050.gd` **30 PASS / 0 FAIL / RESULT=ALL_PASS**。三段门禁 **33 份 `r27_*.log` `TOTAL_SCRIPT_ERROR=0`**；全回归 **20 / 45 / 53 / 34 / 47 / 19 / 31 / 58 / 37 / 23 / 44 PASS 全不回退**。未完成项见 §8。

---

## 1. 实际交付清单（只写自有文件）

| 文件 | 动作 | 说明 |
|---|---|---|
| `godot/scripts/world/save_system.gd` | **改写** | R8 装配占位 → R27 接线：`_ready()` 经既有 `WorldState._load()` 自动读回；`is_loaded()` 查询；依赖/模式缺失 `push_warning` 降级不崩。不改 `world_state.gd` / `project.godot` autoload 段 / 不新增存档顶层字段 / 不动 `schema_version=3` |
| `godot/scripts/combat/encounter_director.gd` | **改写** | `_request_action()` 接受当帧立即 `_update_hud()`；`_update_hud()` 显式取 `get_current_pose()/get_frame()/get_total()` 三方法显示到底部战斗 HUD。既有 HUD 其它文本 / 四套 HUD 位置一字未动；`debug_*` 签名与既有数值口径不变 |
| `godot/scripts/combat/wave_trial_director.gd` | **改写** | `_refresh_hud()` 的「赐福点数」由本局累计 `_points_total` 改为持久化余额 `grace.trial.points - grace.trial.spent_points`（经 `WorldState.get_flag` 公开入口读真值、Rank-2 未落盘 spent 时默认 0 降级、`maxi(0,·)` 防负）；新增只读常量 `K_SPENT`。HUD 文本格式串 / 状态机 / 3 信号 / `get_snapshot()` 既有 key 逐字不动 |
| `godot/scripts/hud.gd` | **改写** | 新增三段式 flag 来源常量 `LIT_SOURCE_FLAGS`（`dungeon.wave_trial.completed` / `grace.network.last_rest_epoch`）→ 登记 `_bound_keys` → `refresh_label()` 增量分支 → `_read_lit_sources()` 汇总 bool → 既有 `apply_lit_state(lit)` 统一完成 DIM↔GOLD 切换。`refresh_all()` 初始基线计算逐字未动（保护回归） |
| `godot/scripts/combat/verify_persistence_hud_v050.gd` | **新写** | `extends SceneTree`，30 条断言（A 跨进程读回 9 / B 动作帧 HUD 6 / C 点数跨局 5 / D 点亮态 5 / E 依赖缺失降级 5）；支持 `phase=write` / `v050_read phase=read` / 自包含 selftest 三态；输出 PASS/FAIL 与 RESULT |
| `teamwork/Rank-1/DONE-R27.md` | 本文 | 实际交付 / 真跑输出结论 / 未完成项与阻塞 |
| `teamwork/Rank-1/r27_*.log` | 真跑日志 | 33 份：三段门禁 G1×1 / G2×5 / G3×1、探活×4、v050 三态×5、全回归×14、最终两独立进程×2 等 |
| `teamwork/command_center/ai/1/outbox/cmd-20261111-083350-232-A1.json` | 回执 | 严格按任务单 id 写到精确路径 |

**零写入**：任何素材 PNG / `.tres`（含 Rank-2 的 `grace_upgrades.tres` / `wave_trial.tres`）、两份 SpriteFrames、`project.godot`、`courtyard.tscn`、契约 / README / `presentation.gd`、`world_state.gd`、`save_delta_writer.gd`、任何其它 `.tscn` / `.gd`、其它 Rank 目录既有文件。

---

## 2. ① SaveSystem 接线方式

### 2.1 实现

```gdscript
var _loaded: bool = false
func _ready() -> void:
    _loaded = false
    if not _readback_allowed():
        push_warning("[SaveSystem] --script 工具模式…跳过自动读回（降级，不崩，保护回归基线）")
        return
    var ws := get_node_or_null("/root/WorldState")
    if ws == null:                      push_warning(…降级…); return
    if not ws.has_method("_load"):       push_warning(…降级…); return
    ws.call("_load")                     # 既有 I-1 回放加载入口
    _loaded = true
    print("[SaveSystem] 自动读回完成 | best_wave=%d | points=%d | completed=%s" % …)
func is_loaded() -> bool: return _loaded
```

- **入口**：`WorldState._load()`（既有 I-1 权威实现，`delta.json` schema_version=3 逐级迁移 → `delta.log` 回放 → flags 合并进内存），SaveSystem 自己不 `FileAccess` / 不 `set_flag` / 不 `commit` / 不构造或解析 SaveDelta 十字段 / 不用 `removals`。
- **边界**：`_loaded` 只是 SaveSystem 实例运行期状态，**不是存档顶层字段**；未改 `world_state.gd`、未改 `project.godot [autoload]`、未动 `schema_version=3`。
- **降级**：`WorldState` 取不到 / 无 `_load()` → `push_warning` 降级、`is_loaded()=false`、不崩。

### 2.2 `--script` 工具模式降级的取舍（如实说明，非隐藏）

实测 Godot 4.7.2：`--script` 模式下 autoload 全部实例化（`/root children` 含 6 个单例），且 **autoload 的 `SaveSystem._ready()` 里 `/root/WorldState` 绝对路径可解析**（与 `SaveDeltaWriter._ready()` 的 `writer._ws_probe=false` 时机不同）。若在此模式无条件 `_load()`，会把磁盘里已有的 `grace.*.lit=true` / `grace.network.last_grace_id=grace_siofra_well` 等演示 flag 灌进验证进程，直接使既有回归 `verify_hud_binding.gd` 的 A2（`grace.limgrave_gatefront.lit` 期望 false→true 增量）因幂等而 **pass=10 fail=1**（实测 `r27_probe_script_degrade.log` 记录）。

故 `SaveSystem._ready()` 用引擎命令行判据：**无 `--script`（真实游戏 / 纯场景 / 三段门禁 G3）恒自动读回；`--script` 工具进程仅当 `--` 之后显式带用户标记 `v050_read` 时才读回**，其余如实 `push_warning` 降级。这样 11 组既有回归的 WorldState 基线与 R26B 完全一致、全不回退；标记机制等价于 `verify_wave_persist_v040.gd` 既有「一次性测试装配修正」口径。三态实测：

| 跑法 | 结果 | 日志 |
|---|---|---|
| 纯场景 `--headless --quit-after 5 res://scenes/courtyard.tscn` | `[SaveSystem] 自动读回完成 \| …=3 / 450 / true`，EXIT=0 | `r27_probe_scene_readback.log` |
| `--script verify_hud_binding.gd`（无标记） | 降级 warning + **11 PASS / 0 FAIL** | `r27_probe_script_degrade2.log` |
| `--script … -- v050_read`（带标记） | 启用自动读回 | `r27_probe_tagged.log` |

> 踩坑对齐：验证脚本侧一律用 `Engine.get_main_loop()` + `root.get_node_or_null()` 相对探活；`add_child` 不 flush `_ready`（v050 内所有注入实例显式 `call("_ready")`，并挂 `process_frame` 等 3 帧让 autoload SaveSystem 自动读回在断言前真实发生）；注入在 `_ready` 之后。

### 2.3 跨进程读回证据（两个独立引擎进程）

```
进程1（写）  --script verify_persistence_hud_v050.gd -- phase=write
  [V050][WRITE] pid=14948 落盘完成 | best_wave=7.0 points=1337.0
                 spent_points=37.0 completed=true reason=v050_write
  RESULT=WRITE_OK  EXIT=0
进程2（重启读回，独立引擎进程 pid=23436）
  --script verify_persistence_hud_v050.gd -- v050_read phase=read
  [SaveSystem] 自动读回完成 | best_wave=7 | points=1337 | completed=true
  A8 autoload WorldState 自动读回 == 磁盘三 flag PASS=true | auto_loaded=true
  A9 SaveSystem is_loaded=true PASS=true
  SUMMARY pid=23436 pass=30 fail=0 ok=true | RESULT=ALL_PASS  EXIT=0
```
写进程经 I-1 真实写入口 `set_flag` + `SaveDeltaWriter.commit("v050_write")` 落盘 `user://saves/slot_01/delta.json`（不手改文件、不伪造产物）；读回进程是全新引擎进程、SaveSystem autoload 自动 `_load()` 读回，A5 断言磁盘三 flag == 写进程常量、A6 新建独立 WorldState 实例 `_load()` 读回一致、A8 自动读回一致、A9 接线状态为真。日志 `r27_v050_write_final.log` / `r27_v050_read_final.log`。

---

## 3. ② 动作帧 HUD 推进

- 现状诊断：`encounter_director.gd:_update_hud()` 既有已用 `PlayerActionState` 的 `get_current_pose()/get_frame()/get_total()` 拼进底部战斗 HUD「动作 %s %d/%d」；R25 实机记录 `DONE-R25.md:141` 为 `动作 idle 0/0`（该帧玩家无动作输入的静态快照），被本轮任务单概括为「当前恒 idle 0/0」。
- R27 改动：`_request_action()` 在动作被接受的**当帧**就 `_update_hud()`（原来只在下一 `_physics_process` 的 `_step()` 内刷新），确保动作帧 HUD 立即脱离 idle 0/0；`_update_hud()` 把三方法显式提取为 `pose / frame / total` 局部变量并标注 R27 口径。
- 真跑实证（v050 B 段，`r27_v050_selftest.log`）：
  ```
  B2 初始    … ｜ 动作 idle 0/0 ｜ …
  B4 请求当帧 … ｜ 动作 attack_light 0/27 ｜ …   parsed={pose:attack_light, frame:0, total:27}
  B5 HUD pose/frame 与 get_snapshot() 一致
  B6 debug_step 后 … ｜ 动作 attack_light 1/27 ｜ …  且 玩家 HP / Boss HP / 闪避 / 命中 字段全保留
  ```
- 不改既有 HUD 的其它文本与四套 HUD 位置（赐福标题 / 画质 / 底部战斗 / 波次四套 CanvasLayer·Label 坐标与文本格式串一字未动）。

---

## 4. ③ 赐福点数跨局对齐

- `wave_trial_director.gd:_refresh_hud()` 的「赐福点数」由本局累计 `_points_total` 改为**持久化可用余额**：经 `WorldState.get_flag("grace.trial.points", …)` 与 `get_flag("grace.trial.spent_points", 0)` 读真值，显示 `maxi(0, points - spent_points)`。`spent_points` 由 Rank-2 兑换服务落盘（单调递增），本导演只读、Rank-2 未落盘时按 0 降级；`maxi(0,·)` 防负余额。
- 直接读 `WorldState` 公开入口而非运行时镜像，保证与 Rank-2 消费口径一致；依赖缺失（`bind_persistence(null,null)`）时回退运行时镜像 `_grace_points`、不崩。
- 真跑实证（v050 C 段）：`1337-37=1300` → `1337-337=1000` → 新一局 `points_total=0` 但 HUD 仍 `1300`（跨局不归零）→ `spent>points` clamp 到 `0` → 依赖缺失降级仍刷新。`HUD 文本格式串` 与 `get_snapshot()` 既有 key 逐字不动。

---

## 5. ④ 赐福点亮态

- `hud.gd` 新增三段式 flag 来源常量 `LIT_SOURCE_FLAGS = ["dungeon.wave_trial.completed", "grace.network.last_rest_epoch"]`（试炼完成 bool / 赐福休息 int epoch），登记进 `_bound_keys`，在 `refresh_label()` 增量分支调用 `_read_lit_sources()`（经唯一 `_flag(key, default)` 入口读、bool 取真值 / int `>0`、任一为真即点亮），**颜色切换统一交给既有 `apply_lit_state(lit)`（GOLD / DIM）**，代码内不出现「某 flag → 某颜色」硬编码条件。
- `refresh_all()` 的初始 lit 基线计算逐字未动，故 `verify_hud_binding.gd` 的 A1/A2/A3 与 `r19_verify_hud.gd` 全不回退。
- 真跑实证（v050 D 段）：初始 `DIM(0.45,0.42,0.34,1)` → 试炼完成 `GOLD(0.83,0.68,0.3,1)` → 复位暗灰 → 赐福休息 epoch=1 `GOLD` → `_read_lit_sources()` 随 flag true→false → 来源为登记的两个三段式 key。

---

## 6. ⑤ 新自测 `verify_persistence_hud_v050.gd`

- `extends SceneTree`，30 条断言，输出 PASS/FAIL 与 RESULT；三态：`phase=write`（独立写进程）/ `v050_read phase=read`（独立读回进程，不写盘）/ 无参 selftest（自包含先写后验）。
- **实测 `SUMMARY pid=23236 pass=30 fail=0 ok=true | RESULT=ALL_PASS | EXIT=0`**（selftest）；read 进程 `pid=27384 / 23436 pass=30 fail=0 RESULT=ALL_PASS`。
- 分组：A 跨进程读回与存档结构 9（十字段齐全无额外顶层字段 / schema_version=3 / 三段式正则 / 落盘值==写进程常量 / 新实例 `_load()` 重启读回一致 / 自动读回 is_loaded / 不回退）；B 动作帧 HUD 6；C 点数跨局 5；D 点亮态 5；E 依赖缺失降级 5。
- `[PLACEHOLDER-验证桩]` 数值 7 / 1337 / 37 / true 仅用于确定性跨进程比对，rationale 写于脚本头，不引入任何设计数值、不改 `.tres` / schema。

---

## 7. 真跑输出结论（三段门禁 + 全回归）

引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--headless --path F:/Game/aierdengfahuan/godot`，串行（一次一个引擎进程）。

| 段 | 命令要点 | EXIT | `SCRIPT ERROR` |
|---|---|---|---|
| G1 | `--headless --import` | 0 | 0 |
| G2 | `--headless --check-only --script` ×5（save_system / hud / encounter_director / wave_trial_director / verify_persistence_hud_v050） | 全 0 | 全 0 |
| G3 | `--headless --quit`（main_scene=courtyard.tscn，SaveSystem 自动读回） | 0 | 0 |

**33 份 `r27_*.log` 逐份 grep `SCRIPT ERROR` / `Parse Error` 全 0，`TOTAL_SCRIPT_ERROR = 0`。**

| 回归组 | 期望 | 实测 | 结论 |
|---|---|---|---|
| `verify_encounter_v010.gd` | 20 | `pass=20 fail=0 RESULT=ALL_MATCH` | 不回退 |
| `verify_encounter_v020.gd` | 45 | `pass=45 fail=0 RESULT=ALL_MATCH` | 不回退 |
| `verify_encounter_v030.gd` | 53 | `pass=53 fail=0 RESULT=ALL_MATCH` | 不回退 |
| `verify_fx_profile.gd` | 34 | `pass=34 fail=0 RESULT=PASS` | 不回退 |
| `verify_fx_mobile.gd` | 47 | `pass=47 fail=0 RESULT=PASS` | 不回退 |
| `verify_quality_interaction.gd` | 19 | `pass=19 fail=0 RESULT=PASS` | 不回退 |
| 31 组合 | 31 | `r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11 | 不回退 |
| `verify_wave_trial_v040.gd` | 58 | `pass=58 fail=0 RESULT=ALL_MATCH` | 不回退 |
| `verify_wave_runtime_v040.gd` | 37 | `pass=37 fail=0 RESULT=ALL_MATCH` | 不回退 |
| `verify_wave_flags_v040.gd` | 23 | selftest 17 + write 3 + read 3（三进程 pid 8156 / 12040 / 25724 全不同） | 不回退 |
| `verify_wave_persist_v040.gd` | 44 | `pid=2176 pass=44 fail=0 RESULT=ALL_PASS` | 不回退 |
| **`verify_persistence_hud_v050.gd`（新）** | — | **`pass=30 fail=0 RESULT=ALL_PASS`** | 本轮新增 |

门禁 / 运行仅有既有 WARNING（`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`）、`--script` 降级 warning、波次降级 / HUD 绑定降级登记，**均非 `SCRIPT ERROR`**，与 R23~R26 日志一致。

---

## 8. 未完成项与如实边界

1. **Rank-4 并发改 `courtyard.tscn` 视觉属性的中间态**：本轮工作中途实测 `verify_wave_runtime_v040.gd` 曾出现 `uv_terracehigh_1 PASS=false`（`uv1_scale` 由 `(1,1,1)` 被并发改成 `(4,4,1)`，Rank-4 R27 任务①明确在改三波空间节奏的地面色调，`courtyard.tscn` 视觉属性归 Rank-4 独占）。Rank-1 未写 `courtyard.tscn`、未改该验证脚本断言；Rank-4 稳定后（`uvhigh` 回到 `(1,1,1)`）复跑 **37 PASS / 0 FAIL 全不回退**。如实登记该中间态，不隐瞒、不冒称自修。
2. **未做 15~20 秒实机录屏 / 目视回看**：本轮约束「不启 GPU job」；进度判断依据为三段门禁 + v050 30 条运行时断言 + 11 组全回归 + 两独立引擎进程日志。HUD 视觉观感（字号 / 与画面重叠 / 亮金对比度）待人工试玩目视校准。
3. **`--script` 工具模式 SaveSystem 默认降级**（不加载玩家存档）：为保护 11 组回归基线做的取舍，见 §2.2；跨 exe 自动读回由纯场景运行 / 带标记读回进程实证，非「未接线」。
4. **`grace.trial.spent_points` 由 Rank-2 落盘**：本导演只读、带默认 0 降级；Rank-2 的兑换服务 / `grace_upgrades.tres` / 幂等防重复扣点不在本轮所有权内，未代验、未伪造生效。
5. **存档磁盘状态为测试态**：写进程 / `verify_wave_persist_v040.gd` 经 I-1 真实写入口多次落盘覆盖 `user://saves/slot_01/delta.json`（当前三 flag 为写进程确定性值）；均为真实 `set_flag` + `commit`，非手改文件、非伪造产物。
6. **动作帧 HUD 的 pose/frame/total 显示本体在既有 `_update_hud()` 内**：R27 的实质改动是「请求当帧立即刷新」的推进修复 + 显式三方法提取；R25 实机 `idle 0/0` 是无动作输入帧的静态快照，非代码缺失显示字段。
7. 未自行 `git`（总指挥收尾）；零付费、零外部依赖、未启 GPU job；未新建只读探针 / 巡检脚本（新 v050 是任务单 ⑤ 明确要求的正式验证载体）。

---

## 9. 契约与所有权遵守

- 目录所有权：只写 `scripts/world/save_system.gd` / `scripts/hud.gd`（Rank-4 不得写）/ `scripts/combat/wave_trial_director.gd` 的 HUD 数值 / `scripts/combat/encounter_director.gd`（两份导演脚本 Rank-2 不得写）/ `scripts/combat/verify_persistence_hud_v050.gd` / `teamwork/Rank-1/`；**未写**任何素材 PNG / `.tres` / SpriteFrames / `project.godot` / `courtyard.tscn` / 契约 / README / `presentation.gd` / `world_state.gd` / `save_delta_writer.gd` / 其它 `.tscn` / 其它 Rank 目录。
- 公共契约：直接改直接真跑；`--script` 模式不用 `/root/...` 绝对路径（用 `Engine.get_main_loop()` + `root.get_node_or_null()` 相对探活）、`add_child` 显式 `call("_ready")`、注入在 `_ready` 之后；零付费、零外部依赖；不伪造产物、不谎报成功、不自行 git。
- 回执 JSON 按任务单 id 写到精确路径 `F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261111-083350-232-A1.json`（`status=done`，`result` 引用本文实际结论），不写到工程根 `command_center/`。
- **写后实测（如实登记）**：回执写入成功后 `outbox/` 被中枢**实时消费清空**（目录现 0 文件，直接读精确路径 `exists=False`，与 `DONE-R26B.md §⑤` / `DONE-R26.md §⑤` 同一消费时序现象），未隐藏。归档件 `teamwork/command_center/dispatcher/receipts/cmd-20261111-083350-232-A1.json`（2005 字节）读回校验：`json_valid=True`、`keys=['ai','result','status','task_id']`、`task_id=cmd-20261111-083350-232-A1` / `ai=1` / `status=done`、`result_len=1255`、`result` 引用 `DONE-R27.md` 且含 `30 PASS` / `pid=14948` / `pid=23436` / `TOTAL_SCRIPT_ERROR=0`。按幂等 / 并发保护**不重复写第二份回执**。
