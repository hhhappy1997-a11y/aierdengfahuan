# RUNTIME-STATUS-R22.md · Rank-3 运行时状态记录（R22）

- 任务：`cmd-20261109-124640-185-A3`，`[ROUND=R22]`，Rank-3 执行 AI（RPG / 世界 / 存档）
- 日期：2026-11-09
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`--version` = `4.7.2.stable.official.ed1daf0bf`，`EXIT=0`）
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`
- 纪律来源：`C:/Users/62668/.workbuddy/skills/godogen/prompts/runtime.md`
  第 3 行「Keep durable project status in `README.md`: what is built, what is left, and an asset table.」

---

## 1. README 位置

| 项 | 值 |
|---|---|
| 路径 | `F:/Game/aierdengfahuan/README.md`（工程根，非 `teamwork/` 下） |
| 开工前状态 | 已存在，仅 16 字节占位 `# aierdengfahuan` |
| 本轮动作 | **更新**（未新建）：写入三块长期状态表 + 中枢 done 轮次 |
| 三块 | ① 已做了什么（含 R22 端到端真跑结论）｜② 还差什么（8 项长期 / 登记项）｜③ 资产清单表（3.1 类别汇总 / 3.2 四类 PNG 逐文件 / 3.3 场景脚本产物逐文件） |
| 中枢 done 轮次 | README 顶部专节 + 资产表「中枢 done 轮次」列 |

---

## 2. 资产表来源（依据实际落盘文件，不编造）

| 数据 | 取数方式（本轮实测） |
|---|---|
| 所有字节数 | `stat -c %s` 对 `F:/Game/aierdengfahuan/godot/...` 与 `build/...` **逐文件**实测；合计在 README §3.1 末逐项核算 |
| I-5 四类 PNG | `godot/assets/generated/chars/player_*.png`（玩家 base 8 动作）、`decor/player_decor_*.png`（decor 8 帧）、`boss/boss_{dagger_slash,holy_hammer,staff_slam}.png`（Boss base 3 招）、`boss/boss_decor_*.png`（Boss decor 3 招） |
| SpriteFrames 动作数 | **读文件实测**：`chars/player_spriteframes.tres` 的 `[resource] animations` 恰 8 个 `name`（attack_heavy / attack_light / death / hitstun / idle / roll / run / walk）；`boss/boss_spriteframes.tres` 对应 3 招 |
| courtyard 主场景 25 节点 | `grep -c '^\[node ' godot/scenes/courtyard.tscn` = **25**（实测，非引用历史文档） |
| player/boss 角色场景 / hd2d_fx / hud / quality_settings / save_delta_writer / 存档三件 | `godot/scenes/*.tscn` + `godot/scripts/*.gd` + `scripts/rpg/{world_state,save_delta}.gd` 逐文件 `stat` |
| exe / pck / apk / idsig | `build/Aierdengfahuan.{exe,pck,apk,apk.idsig}` 逐文件 `stat`（R21B 重导产物） |
| 中枢 done 轮次 | `teamwork/command_center/commander/report.md` 逐 ROUND 的 done 记录：最近 done = **R21B**（`cmd-20261109-122557-230-A4`，2026-11-09 12:37:03）；R22 四路（A1/A2/A3/A4）当前 dispatched；已 done 序列 R7→R21B |

> 资产表「中枢 done 轮次」列按 report.md 各 ROUND 任务标题归类（非逐文件精确溯源），README 已注明；
> 逐文件原始落位轮次见各 `teamwork/Rank-N/DONE-R*.md`。历史 `Rank-4/I5-DELIVERY-CHECKLIST.md`（R9）记「0 张 PNG」是当时快照，
> 本表以 R22 实际落盘文件为准，未沿用旧结论、未编造。

---

## 3. 端到端真跑命令与输出（补 R21 §3.2 明确未做项）

### 3.1 验证载体

`F:/Game/aierdengfahuan/teamwork/Rank-3/r22_save_e2e.gd`（`extends SceneTree`，本单验证载体）。
用既有 `SaveDeltaWriter.commit(reason)` / `world_state.gd._load()` / `save_delta.gd` 十字段口径，
**不改任何 `godot/` 下既有工程文件**；两阶段用环境变量 `E2E_PHASE=write|read` 区分，落在 Rank-3 目录。

### 3.2 命令（两次**独立** Godot 进程）

```
GODOT="D:/Godot/Godot_v4.7.2-stable_win64.exe"
PROJ="F:/Game/aierdengfahuan/godot"
R3="F:/Game/aierdengfahuan/teamwork/Rank-3"

# 阶段一 · 写盘（独立进程）
E2E_PHASE=write "$GODOT" --headless --path "$PROJ" --script "$R3/r22_save_e2e.gd" \
  > "$R3/R22-E2E-write.log" 2>&1

# 阶段二 · 重启引擎进程 → _load() 回放 → 读回（独立进程）
E2E_PHASE=read  "$GODOT" --headless --path "$PROJ" --script "$R3/r22_save_e2e.gd" \
  > "$R3/R22-E2E-read.log" 2>&1
```

> 执行顺序如实登记：先跑三段门禁与 R21 回归，回归脚本的 autoload commit 会把 `user://` 存档的
> `meta.last_commit_reason` 改写为 `grace_fast_travel`（本轮 `grep` 实测确认）；为使最终磁盘态与 R22 结论一致，
> **在回归之后重放一次端到端真跑**覆盖上述两份日志，最终磁盘 `last_commit_reason=r22_e2e_write`（`grep` 复核）。
> 两阶段均为独立进程，pid 不同即「重启」实证。

### 3.3 实际 stdout（未删改、未补写）

**写盘进程 `R22-E2E-write.log`**（`E2E_WRITE_EXIT=0`）：
```
[R22] phase=write pid=30324
[R22] user_delta_abs=C:/Users/62668/AppData/Roaming/Godot/app_userdata/艾尔登法环 · HD-2D/saves/slot_01/delta.json
[R22] W① /root/WorldState 与 /root/SaveDeltaWriter 就绪 PASS=true | ws=true writer=true
[R22] W② set_flag 注入 5 个三段式 flag PASS=true | keys=["grace.limgrave_gatefront.lit", ...]
[R22] W③ 既有 writer.commit 触发真实落盘 PASS=true | commit_count=1 last_commit_reason=r22_e2e_write
[R22] W④ slot_01/delta.json 已写盘 PASS=true | path=.../saves/slot_01/delta.json bytes=932
[R22] W⑤ 十字段齐全且无额外顶层字段 PASS=true | missing=[] extra=[] ten=[baseline,flags,inventory,meta,quests,removals,schema_version,seq,slot,spawns]
[R22] W⑥ schema_version=3 / slot=slot_01 / 本次 reason 落 meta PASS=true | schema_version=3 slot=slot_01 seq=5 meta.last_commit_reason=r22_e2e_write
[R22] W⑦ 落盘 flags 全部三段式 PASS=true | flag_count=5 bad=[] keys=[...]
[R22] SUMMARY phase=write pid=30324 pass=7 fail=0 ok=true
```

**读回进程 `R22-E2E-read.log`**（`E2E_READ_EXIT=0`）：
```
[R22] phase=read pid=38396
[R22] R② 新进程 _load() 前内存为基线（未读档） PASS=true | get_flag(grace.limgrave_gatefront.lit,false)=false
[R22] R③ 与 write 阶段同一 slot_01/delta.json 仍在盘 PASS=true | path=.../saves/slot_01/delta.json
[R22] R④ 读回十字段齐全 PASS=true | missing=[] ten=[...]
[R22] R⑤ schema_version=3 / slot=slot_01 一致 PASS=true | schema_version=3 slot=slot_01
[R22] R⑥ meta.last_commit_reason 为本次 write 阶段写入 PASS=true | meta.last_commit_reason=r22_e2e_write (期望 r22_e2e_write)
[R22] R⑦ 读回 flags 全部三段式且数量一致 PASS=true | flag_count=5 bad=[] keys=[...]
[R22] R⑧ _load() 回放后 get_flag 逐项读回一致（5/5） PASS=true | readback={ "grace.limgrave_gatefront.lit": true, "grace.limgrave_gatefront.unlocked": true, "quest.bell_of_return.stage": 2.0, "combat.boss_01_margit.defeated": true, "grace.network.last_grace_id": "grace_limgrave_gatefront" } mism=[]
[R22] R⑨ 磁盘 flags 与写盘种子逐项一致（slot_01 一致） PASS=true | disk_mism=[] slot=slot_01
[R22] SUMMARY phase=read pid=38396 pass=9 fail=0 ok=true
```

> `quest.bell_of_return.stage` 读回为 `2.0` 是 Godot `JSON.parse_string` 对数字的 int→float round-trip 既有行为，
> 载体 `_val_eq()` 对数值用 `is_equal_approx` 比较、对 bool/String 严格按类型 + 值比较，如实登记、未隐瞒、未伪造。

### 3.4 结论

| 校验项 | 结论 |
|---|---|
| 写盘 → **重启独立引擎进程** → 读回 | ✅ 成立（write pid=30324 / read pid=38396，不同 PID） |
| 十字段（且无额外顶层字段） | ✅ 两阶段均 `missing=[] extra=[]` |
| `schema_version=3` | ✅ 两阶段均 3 |
| 三段式 flag | ✅ 5/5 key 通过 `^(world\|quest\|combat\|grace\|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$` |
| `slot_01` 一致 | ✅ `slot=slot_01`、同一 `user://saves/slot_01/delta.json` 绝对路径、`meta.last_commit_reason` 跨进程一致 |
| 端到端 PASS | **16 PASS / 0 FAIL**（7 + 9），两进程 `EXIT=0` |

---

## 4. 门禁与回归（保持 R21 不回退）

| 段 | 命令标志 | EXIT | `SCRIPT ERROR` / `Parse Error` / `ERROR` |
|---|---|:--:|:--:|
| G0 | `--version` | 0 | 0 / 0 / 0 |
| G1 | `--headless --import` | 0 | 0 / 0 / 0 |
| G2a | `--check-only --script res://scripts/save_delta_writer.gd` | 0 | 0 / 0 / 0 |
| G2b | `--check-only --script res://scripts/hud.gd` | 0 | 0 / 0 / 0 |
| G2c | `--check-only --script r19_verify_hud.gd` | 0 | 0 / 0 / 0 |
| G2d | `--check-only --script r22_save_e2e.gd`（本单载体） | 0 | 0 / 0 / 0 |
| G3 | `--headless --quit` | 0 | 0 / 0 / 0 |
| 回归 | `--script r19_verify_hud.gd` → `pass=20 fail=0 ok=true` | 0 | — |
| 回归 | `--script res://scripts/verify_hud_binding.gd` → `pass=11 fail=0 ok=true` | 0 | — |

> 12 份 `R22-*.log` 逐份 `grep`：`TOTAL SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR=0`。
> R21 的 **31 PASS / 0 FAIL**（20 + 11）R22 重跑**不回退**；三段门禁 `grep SCRIPT ERROR=0` 达成。
> 退出残留仍是工程既有 WARNING（`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked`），非 ERROR、未隐藏。
