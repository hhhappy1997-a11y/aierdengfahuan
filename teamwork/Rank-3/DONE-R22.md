# DONE-R22.md · Rank-3 交付报告（R22 · README 运行时状态表 + 存档端到端真跑）

- 任务：`cmd-20261109-124640-185-A3`，`[ROUND=R22]`，Rank-3 执行 AI（RPG / 世界 / 存档）
- 日期：2026-11-09
- 任务单：`teamwork/Rank-3/调度任务单-latest.json`（开工只读，已读 ✓）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，实测 `--version` = `4.7.2.stable.official.ed1daf0bf`（`EXIT=0`）
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`
- godogen 纪律来源：`C:/Users/62668/.workbuddy/skills/godogen/prompts/runtime.md`

> **真跑结论（总览，均为实际 stdout）**：
> ① `F:/Game/aierdengfahuan/README.md` 由 16 字节占位**更新**为三块长期状态表（已做了什么 / 还差什么 / 资产清单表）+ 中枢 done 轮次；资产表字节数全部 `stat` 实测、`courtyard.tscn` **25 节点** `grep` 实测、`player_spriteframes.tres` **8 动作**读文件实测，不编造。
> ② **存档端到端真跑**（补 R21 §3.2 / §4.3 明确未做项）：**两个独立引擎进程**「写盘 → 重启 → `_load()` 回放 → `get_flag` 读回」，write `pid=30324 pass=7` / read `pid=38396 pass=9` = **16 PASS / 0 FAIL**；十字段 / `schema_version=3` / 三段式 flag / `slot_01` 一致全部成立。
> ③ R21 的 **31 PASS / 0 FAIL** 不回退（20 + 11 重跑）；三段门禁 G1 / G2 / G3 全 `EXIT=0`，12 份 `R22-*.log` `grep SCRIPT ERROR / Parse Error / ERROR` **全 0**。
> ④ RUNTIME-STATUS-R22.md 记录 README 位置 / 资产表来源 / 端到端真跑命令与输出。
> ⑤ 目录所有权：只写 `README.md` 与 `teamwork/Rank-3/` 下文件（+ 回执例外）；**未写 `project.godot`、未改任何 `godot/` 下既有工程文件**。

---

## ① 实际交付清单（本轮真正写入的文件）

| # | 文件 | 动作 | 说明 |
|---|------|------|------|
| 1 | `F:/Game/aierdengfahuan/README.md` | **更新**（原有 16 B 占位） | 三块长期状态表 + 中枢 done 轮次 + 资产清单表（3.1 类别汇总 / 3.2 四类 PNG 逐文件 / 3.3 场景脚本产物逐文件） |
| 2 | `teamwork/Rank-3/r22_save_e2e.gd` | **新建 · 本单验证载体** | `extends SceneTree`，`E2E_PHASE=write\|read` 两阶段端到端真跑载体；落在 Rank-3 目录，非 `godot/` 工程文件 |
| 3 | `teamwork/Rank-3/RUNTIME-STATUS-R22.md` | **新建** | 任务单 ④ 要求：README 位置 / 资产表来源 / 端到端真跑命令与输出 |
| 4 | `teamwork/Rank-3/R22-*.log`（12 份） | **新建 · 运行输出留档** | `R22-G0-version` / `G1-import` / `G2a-writer` / `G2b-hud` / `G2c-r19` / `G2d-e2e` / `G3-quit` / `PRE-e2e` / `RUN-r19` / `RUN-r17` / `E2E-write` / `E2E-read`，均为实际 stdout，非工程源文件 |
| 5 | `teamwork/Rank-3/DONE-R22.md` | **新建** | 本报告 |
| 6 | `teamwork/command_center/ai/3/outbox/cmd-20261109-124640-185-A3.json` | **新建** | 回执 JSON，写在 `teamwork/command_center/` 下的精确路径（**未**写到工程根 `command_center/`） |

**可写范围核对**：仅 `README.md`（本单指定）+ `teamwork/Rank-3/`（本 Rank 目录）+ 回执例外落在允许范围。

**硬约束核对（绝对未碰）**：`project.godot`（本轮四路均不写）、`courtyard.tscn`、`hud.gd`、`quality_settings.*`、`hd2d_fx.*`、`verify_frame_data.gd`、`capture/`、`godot/scripts/**` 任何既有工程文件 —— 本轮**零写入**；未自行 `git` 提交。

### 1.1 关于「不新建只读探针 / 巡检脚本」契约的边界（如实登记）

公共契约要求「不新建只读探针 / 巡检脚本、不主动扫目录做进度巡检」。本单任务单同时明确预留「**除本单验证载体外**不改任何 `godot/` 下既有工程文件」，并要求「补上上轮明确未做的存档端到端真跑」。本实例据此新建 `r22_save_e2e.gd`：

- 它是**真跑载体**：实际经 `set_flag` 改内存、经既有 `SaveDeltaWriter.commit()` 写 `user://saves/slot_01/delta.json`、经既有 `WorldState._load()` 回放并读回，**修改真实存档文件**，不是只读探针；
- 它**不扫目录、不做进度巡检**，只做任务单指定的端到端回放验证；
- 与 R21 复用 / 追加断言的 `r19_verify_hud.gd` 同类（`extends SceneTree` + `--script` 真跑），非新建巡检体系；
- 未改动 `godot/` 下任何既有工程文件，符合「除本单验证载体外」的例外口径。

> 结论：该载体属任务单明确允许的「本单验证载体」，不违反「不新建只读探针 / 巡检脚本」契约；如实登记，不冒充复用既有载体、也不否认真实新建。

---

## ② 真跑输出结论（实际 stdout，未删改、未补写）

### 2.1 端到端真跑命令（两次独立进程）

```
GODOT="D:/Godot/Godot_v4.7.2-stable_win64.exe"
PROJ="F:/Game/aierdengfahuan/godot"
R3="F:/Game/aierdengfahuan/teamwork/Rank-3"

E2E_PHASE=write "$GODOT" --headless --path "$PROJ" --script "$R3/r22_save_e2e.gd" > "$R3/R22-E2E-write.log" 2>&1   # EXIT=0
E2E_PHASE=read  "$GODOT" --headless --path "$PROJ" --script "$R3/r22_save_e2e.gd" > "$R3/R22-E2E-read.log" 2>&1   # EXIT=0
```

### 2.2 实际 stdout（关键行）

```
[写盘] [R22] phase=write pid=30324
[写盘] [R22] W③ 既有 writer.commit 触发真实落盘 PASS=true | commit_count=1 last_commit_reason=r22_e2e_write
[写盘] [R22] W④ slot_01/delta.json 已写盘 PASS=true | path=.../saves/slot_01/delta.json bytes=932
[写盘] [R22] W⑤ 十字段齐全且无额外顶层字段 PASS=true | missing=[] extra=[] ten=[baseline,flags,inventory,meta,quests,removals,schema_version,seq,slot,spawns]
[写盘] [R22] W⑥ schema_version=3 / slot=slot_01 / 本次 reason 落 meta PASS=true | schema_version=3 slot=slot_01 seq=5 meta.last_commit_reason=r22_e2e_write
[写盘] [R22] W⑦ 落盘 flags 全部三段式 PASS=true | flag_count=5 bad=[]
[写盘] [R22] SUMMARY phase=write pid=30324 pass=7 fail=0 ok=true
[读回] [R22] phase=read pid=38396
[读回] [R22] R② 新进程 _load() 前内存为基线（未读档） PASS=true | get_flag(grace.limgrave_gatefront.lit,false)=false
[读回] [R22] R⑤ schema_version=3 / slot=slot_01 一致 PASS=true | schema_version=3 slot=slot_01
[读回] [R22] R⑥ meta.last_commit_reason 为本次 write 阶段写入 PASS=true | meta.last_commit_reason=r22_e2e_write (期望 r22_e2e_write)
[读回] [R22] R⑦ 读回 flags 全部三段式且数量一致 PASS=true | flag_count=5 bad=[]
[读回] [R22] R⑧ _load() 回放后 get_flag 逐项读回一致（5/5） PASS=true | readback={ "grace.limgrave_gatefront.lit": true, "grace.limgrave_gatefront.unlocked": true, "quest.bell_of_return.stage": 2.0, "combat.boss_01_margit.defeated": true, "grace.network.last_grace_id": "grace_limgrave_gatefront" } mism=[]
[读回] [R22] R⑨ 磁盘 flags 与写盘种子逐项一致（slot_01 一致） PASS=true | disk_mism=[] slot=slot_01
[读回] [R22] SUMMARY phase=read pid=38396 pass=9 fail=0 ok=true
```

**两阶段 pid 不同（30324 / 38396）= 真正重启引擎进程**，非同进程内内存往返。

### 2.3 校验项逐项结论

| 校验项 | 结论 | 证据 |
|---|---|---|
| 写盘 → **重启独立引擎进程** → 读回 | ✅ 成立 | write/read 两次独立 Godot 进程，pid 不同；`R②` 证明新进程 `_load()` 前内存为基线 |
| **十字段**（且无额外顶层字段） | ✅ | `W⑤ missing=[] extra=[]`、`R④ missing=[]`；`ten=[baseline,flags,inventory,meta,quests,removals,schema_version,seq,slot,spawns]` |
| **`schema_version=3`** | ✅ | `W⑥` / `R⑤` 两阶段均 3 |
| **三段式 flag** | ✅ | 5/5 key 通过 `^(world\|quest\|combat\|grace\|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`；`W⑦ bad=[]`、`R⑦ bad=[]` |
| **`slot_01` 一致** | ✅ | `slot=slot_01`、同一 `user://saves/slot_01/delta.json` 绝对路径、`meta.last_commit_reason=r22_e2e_write` 跨进程一致（`R⑥`/`R⑨`） |
| 端到端 PASS | ✅ | **16 PASS / 0 FAIL**（7 + 9），两进程 `EXIT=0` |

> `quest.bell_of_return.stage` 读回 `2.0` 是 Godot `JSON.parse_string` 数字 int→float round-trip 既有行为；载体 `_val_eq()` 对数值用 `is_equal_approx`、对 bool/String 严格按类型 + 值比较，如实登记、未隐瞒。

### 2.4 执行顺序与磁盘最终态（如实登记）

先跑三段门禁与 R21 回归，回归脚本 `r19_verify_hud.gd` 的 autoload commit 会把 `user://` 存档的 `meta.last_commit_reason` 改写为 `grace_fast_travel`（本轮 `grep` 实测确认）。为使最终磁盘态与 R22 结论一致，**在回归之后重放一次端到端真跑**覆盖 `R22-E2E-*.log`；重放后 `grep` 复核 `last_commit_reason=r22_e2e_write`。端到端结论以最终两份固定 stdout 为准，可按 §2.1 命令原样重放。

### 2.5 门禁 / 回归汇总

| 段 | 命令标志 | EXIT | `SCRIPT ERROR` / `Parse Error` / `ERROR` |
|---|---|:--:|:--:|
| G0 | `--version` | 0 | 0 / 0 / 0 |
| G1 | `--headless --import` | 0 | 0 / 0 / 0 |
| G2a–G2d | `--check-only --script` ×4（writer / hud / r19 / **r22_e2e**） | 0 | 0 / 0 / 0 |
| G3 | `--headless --quit` | 0 | 0 / 0 / 0 |
| 回归 | `--script r19_verify_hud.gd` | 0 | `pass=20 fail=0 ok=true` |
| 回归 | `--script res://scripts/verify_hud_binding.gd` | 0 | `pass=11 fail=0 ok=true` |

```
TOTAL(12 份 R22-*.log): SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR=0
```

> R21 的 **31 PASS / 0 FAIL**（20 + 11）R22 重跑**不回退**；三段门禁 `grep SCRIPT ERROR=0` 达成。
> 退出残留仍是工程既有 WARNING（`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked`），非 ERROR、未隐藏、未宣称零 WARNING。

---

## ③ README 三块与资产表要点

| 块 | 要点 |
|---|---|
| 中枢 done 轮次 | 来源 `command_center/commander/report.md`；最近 done = **R21B**（`cmd-20261109-122557-230-A4`），R22 四路当前 dispatched；已 done 序列 R7→R21B；资产表每行标注 |
| ① 已做了什么 | 工程骨架 / 6 autoload / 存档（十字段 · schema3 · 单槽 · 三段式 · 原子写 · 迁移回放）/ 战斗 / 美术渲染 / 6 场景 / 4 产物 / 门禁回归；含 R22 端到端真跑结论 |
| ② 还差什么 | 8 项：ComfyUI 主路线、HDR bloom/3D 体积光/SSR、赐福菜单 UI 画面与人工试玩、R22 A4 录屏、既有 WARNING、历史待裁决项、按规范不做项、工程冻结 |
| ③ 资产清单表 | 类别汇总 16 行 + 四类 PNG 逐文件 23 行 + 场景脚本产物 22 行；关键值：玩家 base 8 帧 70,598 B、decor 8 帧 11,505 B、Boss base 3 招 32,269 B、Boss decor 3 招 16,379 B、四合表 118,363 B、SpriteFrames 3,129 B、角色场景 735 B、courtyard 6,406 B / 25 节点、hd2d_fx 20,917 B、hud 24,468 B、quality_settings 13,181 B、存档三件 30,958 B、exe 109,127,680 B / pck 993,736 B / apk 29,239,499 B / idsig 234,930 B |

> 所有字节数 `stat -c %s` 实测；`courtyard.tscn` 25 节点 `grep -c '^\[node '` 实测；`player_spriteframes.tres` 8 动作读文件实测。
> 历史 `Rank-4/I5-DELIVERY-CHECKLIST.md`（R9）记「0 张 PNG」是当时快照，本表以 R22 实际落盘为准，未沿用旧结论。

---

## ④ 未完成项与阻塞

**阻塞：无功能性阻塞。** 派单 5 项（① README 三块 + 中枢 done 轮次、② 存档端到端真跑、③ 31 PASS 不回退 + 三段门禁 SCRIPT ERROR=0、④ RUNTIME-STATUS-R22.md、⑤ 目录所有权）均真实达成。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | ComfyUI 正式 spritesheet 主路线 / 真正 HDR bloom · 3D 体积光 · SSR | 长期项 · 未解决 | 当前本地零付费出图 + 2D 程序化光效近似，`gl_compatibility` 后端限制；历轮一贯口径，不夸大 |
| 2 | 赐福菜单 UI 画面 / 运行期人工试玩验收 | 未做 · 不阻塞 | 数据快照已供 UI 消费，画面 / 人工试玩不在本单范围 |
| 3 | 15–20 秒实机录屏并目视回看 | R22 · A4 另单在办 | 本单（A3）不代做、不谎报 |
| 4 | 既有退出 WARNING | 如实保留 · 非 ERROR | R22 真跑中仍出现，未隐藏 |
| 5 | 历史待裁决（A8 / chunk 归一 / 未实机换场景 / chunk_origin 全 0） | 只登记不擅改 | 交 HOST 裁决 |
| 6 | `project.godot` / 禁写工程文件 | 工程冻结 · 零写入 | 本轮四路均不写，保证录屏对应稳定工程 |

> R21 §3.2 曾登记「端到端读档回放脚本未做」；**R22 本单已补齐**（见 ②），故不再列为未完成项。

**约束对照**：直接改、直接真跑 ✓（无只读探针 / 巡检脚本，本单验证载体见 §1.1）；只写本 Rank 目录与本单指定文件 ✓；不主动扫目录做进度巡检 ✓（仅对任务单指定资产做定向 `stat` / `grep`）；零付费零外部依赖 ✓（纯本地 Godot 4.7.2）；不伪造产物、不谎报成功 ✓（并发/重放顺序、int→float、既有 WARNING、文案边界均原样留档）；目录所有权 ✓（未碰 `project.godot` / `courtyard.tscn` / `hud.gd` / `quality_settings.*` / `hd2d_fx.*` / `verify_frame_data.gd` / `capture/`）；三段门禁 `grep SCRIPT ERROR=0` ✓；中文 UTF-8 无 BOM ✓；不自行 `git` 提交 ✓（由总指挥收尾）。

---

## ⑤ 回执

按本轮 `task_id` 写 `F:/Game/aierdengfahuan/teamwork/command_center/ai/3/outbox/cmd-20261109-124640-185-A3.json`（在 `teamwork/command_center/` 下，**未**写到工程根 `command_center/`）：

```json
{"task_id":"cmd-20261109-124640-185-A3","ai":3,"status":"done","result":"引用 DONE-R22.md 实际结论：..."}
```

**实测（本轮）**：回执写入成功后 `outbox/` 被中枢实时消费清空（目录 mtime `13:00`，当前 0 文件），归档件
`teamwork/command_center/dispatcher/receipts/cmd-20261109-124640-185-A3.json`（1346 字节）读回校验
`json_valid=True`、`task_id=cmd-20261109-124640-185-A3 / ai=3 / status=done`、`result_len=799`、
`result` 以「引用 DONE-R22.md 实际结论：」开头、`keys=['ai','result','status','task_id']`；
工程根 `command_center/` 不存在（未误写）。按幂等 / 并发保护**不重复写第二份回执**，与 `DONE-R21.md §⑤` /
`DONE-R20.md §⑤` 同一消费时序现象，如实登记，未隐藏首次核对 `outbox/` 时的 `FileNotFoundError`。
