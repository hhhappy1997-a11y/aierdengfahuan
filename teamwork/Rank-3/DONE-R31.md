# DONE-R31.md — R31 / v0.9.0 交付报告（Rank-3）

> 任务单：`teamwork/Rank-3/调度任务单-latest.json`，`id = cmd-20261111-133549-886-A3`，`[ROUND=R31]`，派单方总指挥 / 调度中枢。
> 工程：`F:/Game/aierdengfahuan/godot`｜引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）。
> 本文件如实记录**实际交付清单 / 真跑输出结论 / 未完成项与阻塞 / 待总指挥裁决项**；不伪造产物、不谎报成功、未自行 git（总指挥收尾）。

---

## 1. 实际交付清单（本轮 Rank-3 授权范围内）

| # | 文件 | 动作 | 内容 |
|---|---|---|---|
| 1 | `teamwork/00-协作契约.md` §3.3 | **只追加** R31 说明段 | 登记 `grace.trial.modifier_active`（String / 非单调·局内翻转）与 `grace.codex_full_wish.notified`（bool / false→true 单向）；写明严格三段式正则 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`、只作 `flags` 字典新 key、十字段与 `schema_version=3` 冻结、不写 `removals`、不新增顶层字段、旧档缺 key 回落基线、`commit(reason)` 强制落盘点、先落盘顺序、读写边界。**未改** §3.3 既有登记表任何行、R25~R30 七组历史说明段、I-1~I-6 接口表、§3.1 / §3.2 缺号、§9 及其余历史条款。 |
| 2 | `teamwork/Rank-3/存档与flag规范.md` §3.3 | **追加** 全局登记表 2 行 + R31 注记 1 段 | 两行登记表（String `""` / bool `false` 基线、写入时机、单调性、真源链）+ R31 注记（十字段冻结 / LWW 合法性 / commit reason / 机器判定载体）。§3.1 / §3.2 / §4.x 历史条款未改。 |
| 3 | `godot/scripts/rpg/verify_v090_save_readback.gd` | **新写**（只读验证脚本） | `extends SceneTree`，三进程三态 `write` / `load` / `assert`（+ 单进程 `all` 自检）；独立 `user://saves/verify_v090_<RUN>/` 临时槽隔离；不修改 `world_state.gd` / `save_system.gd` 生产逻辑、不碰生产 `slot_01`；输出逐条 PASS/FAIL + SUMMARY + RESULT。 |
| 4 | `teamwork/Rank-3/V090-GDD.md` | **新写** | game-development-pro 六项齐全（purpose / player experience goal / inputs / outputs / edge cases / failure states）+ B1~B6 broken 判据 + 空间节奏影响 + `[PLACEHOLDER]` 数值表与 rationale + 三段式 flag / 存档口径 + 校对清单 V-1~V-8。 |
| 5 | `teamwork/Rank-3/WAVE-TRIAL-GDD.md` | **只追加** 末尾 R31 状态段 | §0~§10.9 全部历史章节未改。 |
| 6 | `teamwork/Rank-3/CODEX-GDD.md` | **只追加** 末尾 R31 状态段 | §1~§12 全部历史章节未改。 |
| 7 | 工程根 `README.md` | **只追加** 顶部 R31 / v0.9.0 状态段 | 「一、已做了什么」/「二、还差什么」/ 资产表 / 中枢 done 轮次表等历史行按「只追加、不改历史条款」保留未动。 |
| 8 | `teamwork/Rank-3/R31-*.log` | **新写** 7 份真跑日志（实际 stdout） | `R31-G1-import.log` / `R31-G2-checkonly.log` / `R31-G3-quit.log` / `R31-G3-quit-retry.log` / `R31-write.log` / `R31-load.log` / `R31-assert.log`。 |
| 9 | `teamwork/Rank-3/DONE-R31.md` | **新写** | 本文件。 |
| 10 | `teamwork/command_center/ai/3/outbox/cmd-20261111-133549-886-A3.json` | **新写** 回执（写入后由调度中枢自动消费归档，见 §5） | `{"task_id":"cmd-20261111-133549-886-A3","ai":3,"status":"done","result":"引用 DONE-R31.md 实际结论"}`。 |

**明确未写**：`godot/` 工程业务代码（`world_state.gd` / `save_system.gd` / `courtyard.tscn` / `hud.gd` / `impact_feedback.gd` / 既有 `.tres` / `project.godot` 等一律只读未改）、其它 Rank 产出、契约 I-1~I-6 接口表、契约 §3.1 / §3.2 缺号、其它历史条款。新写的 `verify_v090_save_readback.gd` 是**只读验证脚本**：只读加载生产脚本、只调用既有 `_ready()` / `_apply_snapshot()` / `get_flag()`，不修改其逻辑；对生产存档只做 `FileAccess.get_md5()` 只读前后对照，从不 `open(..., WRITE)` 写 `slot_01`。

---

## 2. 真跑输出结论（实际 stdout 原文）

### 2.1 三段门禁（串行、一次一个引擎进程）

| 门禁 | 命令 | EXIT |
|---|---|---|
| G1 | `--headless --import` | **0** |
| G2 | `--headless --check-only --script res://scripts/rpg/verify_v090_save_readback.gd` | **0** |
| G2b | `--headless --script <verify> -- write/load/assert <RUN>`（三次独立进程） | **0 / 0 / 0** |
| G3 | `--headless --quit` | **0** |
| G3 定向重跑 1 次 | `--headless --quit` | **0** |

`--version` = `Godot Engine v4.7.2.stable.official.ed1daf0bf`。

### 2.2 三进程三态（RUN = `R31_20705`，共享独立临时槽）

```
[V090] SUMMARY mode=write  pid=31616 slot=user://saves/verify_v090_R31_20705 pass=9  fail=0
[V090] RESULT=PASS
[V090] SUMMARY mode=load   pid=1644  slot=user://saves/verify_v090_R31_20705 pass=6  fail=0
[V090] RESULT=PASS
[V090] A02 三进程真跑（write/load/assert pid 互不相同） PASS=true | write=31616 load=1644 assert=24208
[V090] B00 11 项关键 flag 三方全一致 PASS=true | keys=11
[V090] C01 余额 >= 0（points - spent_points） PASS=true | balance=400
[V090] D01 十字段齐全、无额外顶层字段 PASS=true | top=["baseline", "flags", "inventory", "meta", "quests", "removals", "schema_version", "seq", "slot", "spawns"] extra=[] missing=[]
[V090] D02 schema_version 保持 3、不触发迁移 PASS=true | schema_version=3.0
[V090] D03 removals 为空（口径不启用 removals） PASS=true | removals=[]
[V090] D04 全部落盘 flag key 通过三段式正则 PASS=true | keys=14 bad=[]
[V090] D05 modifier_active 为 String（本轮新 flag 类型） PASS=true | value=frost_bite type=4
[V090] D06 notified 为 bool（本轮新 flag 类型） PASS=true | value=true type=1
[V090] E12 11 项缺 key 全回落基线（不创建 key） PASS=true | keys=11
[V090] E13 旧档 schema_version=3 / removals 空 / 不升级 PASS=true | schema=3.0 removals=[]
[V090] F01 独立槽与生产 slot_01 物理隔离 PASS=true | slot=user://saves/verify_v090_R31_20705 production=user://saves/slot_01/delta.json
[V090] F02 生产 slot_01 md5 前后一致（未碰生产存档） PASS=true | md5 before==after=19d6def81498a1ca8824600befd66d74
[V090] SUMMARY mode=assert pid=24208 slot=user://saves/verify_v090_R31_20705 pass=41 fail=0
[V090] RESULT=PASS
```

**合计：write 9 + load 6 + assert 41 = 56 PASS / 0 FAIL，三份 `RESULT=PASS`，三个引擎进程 PID 互不相同（31616 / 1644 / 24208）。** 单进程 `all` 自检另得 `SUMMARY mode=all pid=20628 pass=54 fail=0` / `RESULT=PASS`。

覆盖真实性（逐项 `B[...]` 断言的 11 个 key）：`grace.trial.points` / `grace.trial.spent_points` / `grace.upgrade_hp_max_bonus.unlocked` / `grace.upgrade_roll_iframe_bonus.unlocked` / `grace.upgrade_attack_power_bonus.unlocked` / `grace.codex_tutorial_complete.unlocked` / `grace.codex_wave_trial_clear.unlocked` / `grace.codex_all_grace_upgrades.unlocked` / `grace.codex_best_wave_3.unlocked` / `grace.trial.modifier_active` / `grace.codex_full_wish.notified` —— 均「新进程内存读回 == 磁盘 == 写盘期望」。

### 2.3 `grep SCRIPT ERROR=0`（逐份日志实际统计）

```
R31-G1-import.log     : SCRIPT ERROR=0 Parse Error=0 ERROR_PREFIX=0
R31-G2-checkonly.log  : SCRIPT ERROR=0 Parse Error=0 ERROR_PREFIX=0
R31-G3-quit-retry.log : SCRIPT ERROR=0 Parse Error=0 ERROR_PREFIX=0
R31-G3-quit.log       : SCRIPT ERROR=5 Parse Error=4 ERROR_PREFIX=1
R31-assert.log        : SCRIPT ERROR=0 Parse Error=0 ERROR_PREFIX=0
R31-load.log          : SCRIPT ERROR=0 Parse Error=0 ERROR_PREFIX=0
R31-write.log         : SCRIPT ERROR=0 Parse Error=0 ERROR_PREFIX=0
```

**如实登记（不谎报）**：首次 G3 的 5 条 `SCRIPT ERROR` / 4 条 `Parse Error` / 1 条 `ERROR:` 全部定位到 `res://scripts/render/impact_feedback.gd:201/241` 的 `Function "cosf()" / "sinf()" not found in base self`（连带 `hud.gd:1092` 的 `Nonexistent function 'new' in base 'GDScript'`）。该文件按 R31 任务单**目录所有权归 Rank-1**（本轮并发写入），非 Rank-3 引入、非本轮验证脚本引入；按历轮 R27「定向重跑 1 次」先例重跑 G3 后归零（`R31-G3-quit-retry.log` 全 0），证实为 Rank-1 并发写入的**瞬时半成品**、已由 Rank-1 侧自行稳定。两次 G3 真跑均回读 `courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41`，**A38 断言（节点数 41 与 `uv_groundplate_2` / `uv_terracelow_1` / `uv_terracehigh_1`）未被破坏**。

**自有验证链路（G1 / G2 / 三进程 write·load·assert / G3 重跑）逐份 `SCRIPT ERROR=0`、`Parse Error=0`、`ERROR:` 前缀 = 0，三段门禁 `grep SCRIPT ERROR=0` 达成。**

### 2.4 既有 WARNING（如实保留、非 ERROR）

三态进程各有 3 条：`[SaveSystem] --script 工具模式跳过自动读回（降级，保护回归基线）`、`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`；G3 重跑 1 条 `ObjectDB instances were leaked`。均为历轮既有退出期 WARNING，未隐藏、未宣称零 WARNING。

### 2.5 独立 PID 临时槽隔离口径（如实说明）

- 三态共享一次 run 的独立槽 `user://saves/verify_v090_R31_20705/`（token `R31_20705` 取编排进程 PID），与生产 `user://saves/slot_01/` **物理隔离**；三个 Godot 子进程 PID 各自不同（A02 机器判定）。
- 写盘 / 读回 / 断言的全部文件（`delta.json` / `expected.json` / `readback.json` / `legacy.json`）都落在该独立槽，避免并发共享 `user://saves/slot_01/delta.json` 造成回归抖动。
- 生产存档只做 `get_md5` 只读前后对照（before == after == `19d6def81498a1ca8824600befd66d74`），证明本轮未碰生产存档。

### 2.6 「新进程 load」为何走 `_apply_snapshot` 而非 `_load()`（如实登记，不伪造）

`world_state.gd` 的 `_load()` 从 `const DELTA_PATH = "user://saves/slot_01/delta.json"`（生产存档）读取；本轮「不碰生产存档」约束下不能把测试快照写进 `slot_01`。`_load()` 对 `schema_version=3` 且无 `delta.log` 的干净 delta 的实质动作是 `_migrate()`（恒等）→ `_replay_log([])`（恒等）→ `_apply_snapshot(state)`，故新进程改走「自读独立槽 `delta.json` → 新建空内存 WorldState（显式 `call("_ready")`）→ `call("_apply_snapshot", delta)`」，语义等价于 `_load()` 的注入段、数据源指向独立槽；磁盘为唯一权威，读回值只经 `get_flag` 取得。这是不改生产逻辑前提下的必要工程取舍，列为待总指挥裁决项（§4 第 4 条）。

---

## 3. 未完成项与阻塞

**本轮授权范围内无阻塞，①②③ 三项任务全部完成并真跑通过。** 以下为跨 Rank / 用户侧长期项（Rank-3 不代做、不冒充完成，沿用工程根 `README.md`「二、还差什么」口径）：

| # | 项 | 状态 / 归属 |
|---|---|---|
| 1 | Rank-2 `trial_modifiers.tres` / `trial_modifier_config.gd` / `trial_modifier_service.gd` 词条表落地校对（引用键名 / `[PLACEHOLDER]` 数值 / rationale / broken 定义） | **待 Rank-2 并发产出落地后校对**，Rank-3 不代验；不一致改 `V090-GDD.md` 引用段、不改数据表（`V090-GDD.md` §12 V-1） |
| 2 | Rank-1 `impact_feedback.gd` / `hud.gd` / `presentation.gd` 打击反馈与满愿演出运行时接线、词条 HUD、15~20 秒演示序列 | **属 Rank-1 并发实现**，Rank-3 不代验、不宣称已接通（§12 V-2 / V-8） |
| 3 | 15~20 秒实机录屏目视回看（B1 词条不可辨 / B3 反馈遮蔽判据） | **属 Rank-4 / 用户侧**，headless 真跑无真实帧缓冲、WorkBuddy 不替人做手感与审美判断（§12 V-3） |
| 4 | 全部 `[PLACEHOLDER]` 数值（词条条数 / 倍率 / 波间选择窗口 / 反馈时长 / 震屏幅度 / 满愿演出时长 / 夹具 1000·600·400）人工试玩校准 | **属用户侧**，校准同步清单见 `V090-GDD.md` §10，不静默改数（§12 V-4） |
| 5 | HD-2D 全绿（真 HDR bloom / 3D 体积光 / SSR / Boss 可见像素形象 / 地面平铺与马赛克）、人工试玩（裁决 A17）、`128bit` 词义歧义（裁决 A15 保留） | **长期未达**，工程根 `README.md`「二、还差什么」第 2 / 10 / 11 / 12 项，v0.9.0 仍未达 |
| 6 | 首次 G3 的 5 条 `SCRIPT ERROR`（Rank-1 `impact_feedback.gd` 的 `cosf()/sinf()`） | **定向重跑已归零**，属 Rank-1 本轮并发瞬时半成品、Rank-3 不代修、不谎报「首次即全 0」（见 §2.3） |
| 7 | 两个新 flag 的运行时写入接线（词条编排 / 满愿编排实际调用 `set_flag` + `commit`） | **属 Rank-1 / Rank-2 并发运行时**，Rank-3 本轮只登记口径 + 只读回读验证脚本，未写 `godot/` 业务代码（契约 §3.3 R31 说明段「读写边界」） |

---

## 4. 待总指挥裁决项

1. **非单调 String flag 口径**：`grace.trial.modifier_active` 登记为「String / 非单调·局内翻转」，与既有登记表多数「单调递增 / 单向」flag 不同；本轮按 §4.4「LWW 后写覆盖」判其合法（同 R25 `grace.encounter_01.retry_active` 先例）。是否需规范 §3.3 补「非单调 flag 白名单」小节，或维持按说明段逐条登记，请裁决。
2. **两个新 flag 的运行时写入责任 Rank**：契约 §3.3 登记写方为「Rank-3（I-1 `set_flag` 权威定义方）+ 编排层触发」，但 Rank-3 本轮按硬约束未写 `godot/` 业务代码；实际词条 / 满愿编排由 Rank-1 / Rank-2 并发实现。请明确写入责任 Rank 与接线验收归属（避免「登记已落地」被误读为「运行时已接通」）。
3. **首次 G3 的 Rank-1 `impact_feedback.gd` 解析错误**：是否需作为 Rank-1 本轮遗留登记 / 追责（定向重跑已归零、A38 未破坏）；Rank-3 只如实登记、不代修。
4. **「新进程 load 走 `_apply_snapshot`」等价口径**：不改 `world_state.gd` 的前提下无法让 `_load()` 指向独立临时槽（其 `DELTA_PATH` 常量写死生产 `slot_01`）。请裁决该等价口径是否被接受；若要求必须走 `_load()` 本身，需授权改生产逻辑或改验证策略（本轮均未越界）。
5. **`[PLACEHOLDER]` 数值校准同步清单**：`V090-GDD.md` §10 表 + `verify_v090_save_readback.gd` 的 `FIX_*` 常量（1000 / 600 / 400 / `frost_bite`） + `DONE-R31.md` + 三段门禁；试玩校准后需同步，不静默改数。
6. **README 表格行**：本轮按「只追加、不改历史条款」只在工程根 `README.md` 顶部追加 R31 状态段，「一、已做了什么」/「二、还差什么」历史表格行未动（v0.9.0 增量以顶部段与本文件为准）。若要求下一轮补 `v0.9.0 条目` / `第 18 项` 表格行，请裁决授权。

---

## 5. 收尾声明

- 零付费、零外部依赖、未启 GPU job；未新建只读探针 / 巡检脚本（`verify_v090_save_readback.gd` 是正式自测件，非探针）；未主动扫目录做进度巡检；未谎报成功；**未自行 git**（总指挥收尾）。
- 未删除 `.workbuddy` 目录。
- 回执 JSON：按任务单写入 `teamwork/command_center/ai/3/outbox/cmd-20261111-133549-886-A3.json`（严格四字段 `task_id / ai / status / result`，`result` 全文引用本文件 §2 实际结论，`json.load` 校验通过）。**如实登记中枢收件机制（非交付缺失）**：回执写入 outbox 后由调度中枢自动消费归档到 `teamwork/command_center/dispatcher/receipts/cmd-20261111-133549-886-A3.json`（14:09:51、1113 B、内容逐字一致），outbox 随之清空 —— 历轮 dispatcher/receipts 均逐 ROUND 归档、outbox 不留实体文件，属正常流水线。本轮共写入 2 次（Write 工具 1 次 + Bash/python 1 次，均在写入的同一命令内以 `os.path.isfile` / `ls -la` 实证 outbox 文件存在），均被中枢消费；**回执已被成功接收**（归档件 `status=done`）。若总指挥要求 outbox 最终状态仍保留实体文件，请裁决。
- 真跑日志原文留档 `teamwork/Rank-3/R31-*.log`（7 份）。
