# DONE-R37.md · R37 / v0.14.0「元素瓶与死亡轮回 · 画面补齐」交付报告（Rank-3）

> 轮次：`R37 / v0.14.0` ｜ 任务单 id：`cmd-20261112-184157-088-A3` ｜ 执行 AI：`3（Rank-3 RPG / 世界 / 存档）`
> 真源：`teamwork/Rank-3/调度任务单-latest.json`（`task` 全文 + 公共契约 + A48 硬要求 + 目录所有权）
>   + `teamwork/Rank-2/DONE-R37.md` §3（FlaskService / DeathService 信号签名）
>   + `teamwork/Rank-1/DONE-R37.md`（生产链路现状）+ `teamwork/00-协作契约.md` §3.3（历史条款 / 裁决 A39~A69）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
> **一句话结论**：R37 六块任务全部真跑完成 —— 编排层订阅 7 个新信号（A48① 生产运行时订阅者）登记 11 个三段式 flag（A70 元素瓶 / A71 死亡轮回独立单向 flag），**绝不回退 `grace.trial.points`、绝不写 `removals`、回收绝不二次入账**；两份新验证脚本 `verify_v140_save_commit.gd`（83 PASS / 三进程三态 97 PASS）与 `verify_life_production_v140.gd`（A48③ 真实可达 58 PASS，不加载 `presentation.gd`、不在验证脚本内模拟编排）合计 **238 PASS / 0 FAIL**、全 `RESULT=ALL_MATCH`；三段门禁 10 份日志全 `EXIT=0`、`TOTAL_SCRIPT_ERROR_LINES=0`；契约 §3.3 **只追加** R37 说明段（**A69 补登** / **`focus_rejected` 策略裁决** / **A70~A73**），规范 §3.3 补 11 行，迭代文档 + README §八 + 本 DONE + 回执落地并**中枢归档确认**。
> 如实登记：GATE-2b 真实可达日志含 **1 条非 `SCRIPT ERROR` 的引擎 `ERROR` 行**（`boss_controller.gd:86` 绝对路径，Rank-1 既有代码在 `--script` 模式下由重生链触发、非本轮引入、非 `SCRIPT ERROR`、不影响 `EXIT=0` 与断言），见 §3.6；`focus_rejected` 落盘策略与 R36 既有口径冲突，本轮不擅改、列入待裁决项（§6 / §9）。

---

## 1. 交付清单（实际落地文件）

### 1.1 代码（3 件，均归 Rank-3 / `godot/scripts/rpg/`）

| 文件 | 类型 | 作用 |
|---|---|---|
| `godot/scripts/rpg/points_commit_orchestrator.gd` | **修改**（A56 生产编排层 autoload，Rank-3 唯一写入，58,350 B） | 文件末尾追加 R37 段 + 5 处最小插入：`FLASK_SIGNALS` / `DEATH_SIGNALS` + 11 个三段式 flag 常量 / 6 个运行时态变量 / `_ready()` 加 `call_deferred("_deferred_bind_life")` / `_release()` 加 `_release_life()` / `get_status()` 追加 13 个观测字段；新增 `_deferred_bind_life()` / `_find_life_services()` / `_scan_life_node()` / `bind_life_services()` / `_flask_read_max()` / `_release_life()` / `_life_disk_flags()` / `_commit_life()` + **7 个生产回调**。既有 A55/A57/A59/A66 逻辑**逐字未改** |
| `godot/scripts/rpg/verify_v140_save_commit.gd` | **新写**（39,729 B） | 存档 commit 三态只读验证：`all` 83 PASS / 三进程三态 `write 22 + load 11 + assert 64 = 97` PASS；十字段 / `schema_version=3` / `removals` 恒空 / 原子写 / 先落盘后改实例 / 重启读回一致 / 旧档缺 11 key 回落基线 / **单向 flag 不回退 points**（反例 250 / 750 / 2 被拒）/ 拒绝事件不写盘 / 生产 `slot_01` md5 前后一致 |
| `godot/scripts/rpg/verify_life_production_v140.gd` | **新写**（36,966 B） | ★ A48③ 真实可达回归：**不加载 `presentation.gd`**（B00 运行时树零 presentation 节点）、**不在验证脚本内模拟编排**；实例化主场景 → 复用 A54 唯一真实 FlaskService / DeathService → 生产编排层 `bind_life_services()` 显式入口 → 生产真实驱动口注入输入 → 读磁盘断言「元素瓶扣减 → 落盘 → 死亡掉落 → 重生回满 → 一次性回收 → 重启读回一致 → 重复回收被拒」。58 PASS / 0 FAIL |

### 1.2 文档 / 契约 / 规范 / README / 日志 / 回执

| 文件 | 类型 | 作用 |
|---|---|---|
| `teamwork/00-协作契约.md` §3.3 | **只追加 R37 说明段**（107,860 B） | 11 flag 登记 + **A69 补登** + **`focus_rejected` 落盘策略裁决** + **A70~A73 裁决登记** + 未动声明；历史条款 / I-1~I-6 接口表 / §3.1 §3.2 缺号一律未改 |
| `teamwork/Rank-3/存档与flag规范.md` §3.3 | **补 11 行 + R37 注记**（48,559 B） | 全局 flag 登记表同步 5 个 `combat.flask.*` + 6 个 `grace.death.*`，历史行未删 |
| `teamwork/迭代-v0.14.0-元素瓶与死亡轮回.md` | **新写**（39,563 B） | 玩法拆解表 / 漏洞识别 P0~P2 / GDD 六项 / 三栏清单 / 节点信号链 / 真跑数字 / 验收三态 / 风险回滚 / **只列零付费零外部依赖增量的 backlog** / 裁决登记 / 硬约束声明 |
| `README.md` §八 | **追加状态段** | v0.14.0 状态表 / 资产表增量（`os.path.getsize` 实测字节数）/ 「已做了什么」增量 / 「还差什么」第 22 项 + 复核；历史行一律保留未动，未代写「总指挥定稿」段 |
| `teamwork/Rank-3/R37-*.log`（10 份） | **新写**（合计 62,169 B） | 三段门禁真跑 stdout 原文留档：G1 / G2a×3 / G2b×5 / G3；逐份 `SCRIPT ERROR=0` |
| `teamwork/Rank-3/DONE-R37.md` | **新写** | 本交付报告（交付清单 / 真跑输出原文 / 验收三态 / **单向 flag 不回退 points 实证** / A69 补登与 `focus_rejected` 策略结论 / 未完成项 / 待裁决项 / 归档确认） |
| `teamwork/command_center/ai/3/outbox/cmd-20261112-184157-088-A3.json` | **新写 → 中枢归档** | 四字段回执 `{"task_id","ai":3,"status":"done","result"}`；写后中枢移入 `dispatcher/receipts/`，归档确认见 §11 |

### 1.3 只读未改（硬约束）

`godot/project.godot`（既有 autoload，**本轮只读**）、`godot/scenes/courtyard.tscn`（节点 **41** / uv **`2/1/1`** / 节点名，A38）、`godot/test/presentation.gd`（**只读**）、`godot/scripts/hud.gd` / `encounter_director.gd` / `wave_trial_director.gd` / `flask_service.gd` / `death_service.gd` / `flask_config.gd` / `death_config.gd` / `impact_feedback.gd`、`godot/data/rpg/flask_rules.tres` / `death_rules.tres`、全部既有 `.tres` / 素材、其它 Rank 产出、契约其它历史条款 —— 一律只读未改。

---

## 2. 落盘编排层实现说明

### 2.1 7 个新信号的生产运行时订阅者（A48①，非验证脚本）

`PointsCommitOrchestrator` autoload 在 `_ready()` 追加 `call_deferred("_deferred_bind_life")`；`_find_life_services()` 相对 root 找 `WaveTrialDirector` → 调 `get_flask_service()` / `get_death_service()` 取 **A54 唯一实例**（绝不 new 第二个）；`bind_life_services(flask, death)` 为确定性显式入口（`--script` 验证进程直接调），`is_connected` 去重 connect：

| 服务 | 信号（签名逐字来自 Rank-2 DONE-R37.md §3.1 / §3.6） | 编排层生产回调 | 真实职责 |
|---|---|---|---|
| FlaskService | `flask_used(flask_before:int, flask_after:int, hp_before:float, hp_after:float, healed:float)` | `_on_flask_used` | 落盘 `combat.flask.remaining / max / use_count` |
| FlaskService | `flask_rejected(reason:String, flask_remaining:int)` | `_on_flask_rejected` | ★ **不写盘**，只 `_life_reject_observed` 观测 + HUD 反馈 |
| FlaskService | `flask_restored(flask_before:int, flask_after:int, policy:String)` | `_on_flask_restored` | 落盘 `combat.flask.remaining / max / restore_count / policy`（上限封顶） |
| DeathService | `death_occurred(dropped_points:int, grace_points_snapshot:int)` | `_on_death_occurred` | 落盘 `grace.death.dropped / reclaimed=false / count / grace_snapshot`（★ 只读记录、不回退 points） |
| DeathService | `respawn_performed(pending_dropped_points:int)` | `_on_respawn_performed` | 落盘 `grace.death.respawn_count`（不重复复位、不二次写瓶数） |
| DeathService | `points_reclaimed(points:int, grace_points_snapshot:int)` | `_on_points_reclaimed` | 落盘 `grace.death.reclaimed=true / reclaim_count`（★ 绝不二次入账） |
| DeathService | `action_rejected(reason:String, action_id:String)` | `_on_action_rejected` | ★ **不写盘**，只 `_life_reject_observed` 观测 + HUD 反馈 |

> `BOUND_SIGNALS` / `CORE_SIGNALS` / `FOCUS_SIGNALS` 等既有常量与既有回调**逐字未改**；`_release()` 追加 `_release_life()`（7 信号 disconnect，不留悬空 Callable）。G3 主场景实证 `[R37][PCO] A70/A71 生产订阅者已绑定 FlaskService + DeathService 唯一实例 | signals=7 ...`（无输入不写盘）；验证脚本 B03 connection_list **7/7** 含编排层回调。

### 2.2 11 个三段式 flag（只作 `flags` 字典新 key）

| # | key | 类型 / 基线 | 单调性 |
|---|---|---|---|
| 1 | `combat.flask.remaining` | int / `flask_max` 回落 | 非单调·只减不增除休息·重生（上限封顶） |
| 2 | `combat.flask.max` | int / `0` | 常量·上限（`remaining <= max`） |
| 3 | `combat.flask.use_count` | int / `0` | 单调递增、只增不减（拒绝不增） |
| 4 | `combat.flask.restore_count` | int / `0` | 单调递增、只增不减 |
| 5 | `combat.flask.policy` | String / `""` | 非单调·最近策略覆盖（`rest_refill` / `rest_keep`） |
| 6 | `grace.death.dropped` | int / `0` | ★ 独立单向·只读记录（非 points 扣减） |
| 7 | `grace.death.reclaimed` | bool / `false` | false→true 单向（一次性回收） |
| 8 | `grace.death.count` | int / `0` | 单调递增、只增不减 |
| 9 | `grace.death.grace_snapshot` | int / `0` | 非单调·最近快照覆盖（只读） |
| 10 | `grace.death.respawn_count` | int / `0` | 单调递增、只增不减 |
| 11 | `grace.death.reclaim_count` | int / `0` | 单调递增·一次性（重复回收被拒不增） |

> 全部严格匹配 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`；只作 `flags` 字典新 key，`SaveDelta` 十字段冻结、`schema_version=3` 不迁移、`removals` 恒空、`grace.trial.points` 单调递增只增不减、`commit(reason)` 原子写（`.tmp → flush → rename_absolute → delta.json + .bak`）、**先落盘再改运行时实例**（`_apply_snapshot` 注入磁盘真值）、重启读回一致、FP 与赐福点数继续分离（A66）。

### 2.3 ★ 单向 flag 不回退 points 机制（`_commit_life()` 显式隔离）

```
func _commit_life(reason: String, life_writes: Dictionary) -> bool:
    # ① 每个 key 必须 combat.flask.* / grace.death.* 前缀 + 三段式正则 + 标量白名单
    # ② ★ 显式排除 K_POINTS / K_SPENT（绝不回退 / 改写 grace.trial.points、绝不二次入账）
    # ③ disk_points = 磁盘 flags["grace.trial.points"] 原值
    # ④ 复用既有 _commit(reason, life_writes, 0, disk_points)：
    #    十字段校验 → 原子写 → 落盘成功后 _runtime_flags = flags.duplicate(true)
    #    + _sync_world_state(delta) → emit（awarded_points=0，points_committed 不误导）
```

- **掉落**：`death_occurred(dropped_points, snapshot)` 的 `dropped_points` 是 DeathService 按 `drop_ratio` / `drop_cap` 算出的**只读记录值**，**不是从 `grace.trial.points` 扣除**；`grace.death.dropped` / `.grace_snapshot` 只是独立单向 flag 叙事记录。
- **回收**：`points_reclaimed(points, snapshot)` 的 `points` **原样不采信、不加进磁盘 points**；回收点数已由 Rank-2 导演层 `_on_points_reclaimed()` 累计到 `_death_reclaim_acc` → `_clear_wave()` 并入 `base_for_combo` → `combo.settle()` → HUD `points_awarded` **一次入账**（A55/A57）。编排层只登记「已回收」这一单向事实，**绝不二次入账、绝不回退 points、绝不写 `removals`**。
- **重生**：Rank-2 复位 FP / 瓶 / 连击 / 弹反窗口、清本波累计；Rank-1 `EncounterDirector` 既有赐福休息链路回满真实 HP；编排层只记 `grace.death.respawn_count`，不重复复位、不二次写瓶数（重生回满瓶由 Rank-2 调 `flask.on_grace_rest()` → `flask_restored` 信号 → 编排层 `_on_flask_restored` 落盘）。

### 2.4 拒绝事件不写盘策略（避免无效 commit 膨胀）

`_on_flask_rejected` / `_on_action_rejected` **只增 `_life_reject_observed` 运行时观测计数**，不改任何 flag、不调用 `_commit`、不写盘；HUD 反馈由 Rank-1 / Rank-4 承担。机器判定：三态夹具 `commit_count=5`（5 次成功事件、2 次拒绝不产生 commit）、真实可达满血拒绝 `use_count 1→1 / commit 3→3`、重复回收被拒 `commit 8→8`。

### 2.5 安全降级 / 唯一实例 / 独立临时槽

- **惰性初始化 / 安全降级**：`_deferred_bind_life()` 最多 `MAX_BIND_RETRY=6` 次重试，无 `WaveTrialDirector` 的纯 `--headless --import` / `--check-only` / 无 HUD 场景耗尽后仅 `push_warning` 降级：不订阅、不写盘、不报错、不 null 解引用（G1 / G2a / 无主场景日志实证）。`_commit()` 既有惰性初始化（正则 / 运行时镜像就地补齐）沿用。
- **A54 唯一实例**：`_find_life_services()` 经 `wave.get_flask_service()` / `get_death_service()` 复用，验证 P06 两次 getter 各返回同一 Object。
- **独立 PID 临时槽**：`configure_slot(user://saves/verify_v140_life_<pid>)` / `user://saves/verify_v140_<RUN>`，只改落盘目标路径、不改十字段结构 / 不改 `project.godot`；生产 `slot_01` 全程不 open WRITE、md5 前后一致。
- **Godot `--script` 纪律**：`extends SceneTree` 用 `Engine.get_main_loop() as SceneTree` 取 root（不用 `get_tree()` / 不用 `/root/...` 绝对路径）、`add_child` 后显式 `call("_ready")`、资源 `CACHE_MODE_IGNORE` 回读、connect 去重、验证结束 `_release()` 兜底释放。

---

## 3. 真跑输出原文（三段门禁，10 份日志留档 `teamwork/Rank-3/R37-*.log`）

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；引擎版本行 `Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org`。

### 3.1 GATE-1 `--import` / GATE-2a `--check-only --script`（原文）

```
g1_import EXIT=0
g2a_pco EXIT=0                 # points_commit_orchestrator.gd
g2a_v140c EXIT=0               # verify_v140_save_commit.gd
g2a_v140lp EXIT=0              # verify_life_production_v140.gd
```

### 3.2 GATE-2b `--headless --script <verify>`：两份验证 SUMMARY / RESULT（原文）

```
[V140-C] SUMMARY mode=all pid=38680 slot=user://saves/verify_v140_38680 pass=83 fail=0 total=83
[V140-C] OVERALL=PASS
[V140-C] RESULT=ALL_MATCH
[V140-LP] SUMMARY pid=38464 slot=user://saves/verify_v140_life_38464 pass=58 fail=0 total=58
[V140-LP] OVERALL=PASS
[V140-LP] RESULT=ALL_MATCH
```

关键断言逐条原文（★ 为单向 flag / 拒绝策略实证）：

```
[V140-C] W14 ★ A71 单向 flag 不回退 points：points==500 / spent==15 全程不变 PASS=true | points=500 spent=15
[V140-C] W15 ★ 拒绝事件不写盘：commit_count==5（5 次成功事件，2 次拒绝不产生 commit） PASS=true | commit_count=5 reject_observed=2
[V140-C] C01 ★ 磁盘 grace.trial.points 保持 500（死亡掉落不回退 points） PASS=true | points=500
[V140-C] C02 ★ 反例：落盘 points != 掉落真扣值 250 PASS=true | disk=500 wrong=250
[V140-C] C03 ★ 反例：落盘 points != 回收二次入账值 750 PASS=true | disk=500 wrong=750.0
[V140-C] C05 ★ 磁盘 removals 恒空（A71 绝不写 removals） PASS=true | removals=[]
[V140-C] F05 ★ grace.death.reclaim_count == 1（回收一次性，重复回收被拒不增） PASS=true | reclaim_count=1.0
[V140-C] F06 ★ 反例：reclaim_count != 重复回收也累加的 2 PASS=true | disk=1.0 wrong=2.0
[V140-C] G05 ★ 拒绝事件不写盘：commit_count==5 / reject_observed==2 PASS=true | commit_count=5.0 reject_observed=2.0
[V140-C] L04 新进程内存读回逐项 == 磁盘（重启读回一致） PASS=true | flags=13 项，逐项 get_flag 比对
[V140-C] D02 schema_version 保持 3、不触发迁移 PASS=true | schema_version=3.0
[V140-C] E10 11 项缺 key 全回落基线（不创建 key） PASS=true | keys=11
[V140-C] H02 生产 slot_01 md5 前后一致（未碰生产存档） PASS=true | md5 before==after=884fe86be2ad98720010f59900f38b25

[V140-LP] B00 ★ A48③：运行时树零 presentation.gd 脚本节点 PASS=true | found=false
[V140-LP] B03 ★ A48① 生产订阅者存在性（运行时）：7 信号 connection_list 均含编排层回调 PASS=true | subs={ "flask_used": true, "flask_rejected": true, "flask_restored": true, "death_occurred": true, "respawn_performed": true, "points_reclaimed": true, "action_rejected": true }
[V140-LP] P06 A54：两次 getter 各返回同一实例（绝不自建第二个） PASS=true | flask_same=true death_same=true
[V140-LP] R03 ★ 元素瓶扣减 → 落盘：磁盘 combat.flask.remaining 减少且与真实服务一致 PASS=true | disk_remaining=2 service_remaining=2 flask_max=3
[V140-LP] R07 ★ flask_rejected 拒绝事件不写盘：use_count / remaining / commit_count 全不变 PASS=true | use 1→1 rem=2 commit=3→3
[V140-LP] R09 ★ 落盘 grace.death.dropped == 真实服务 get_dropped_points()（独立单向记录、非扣减） PASS=true | disk_dropped=250 service_dropped=250
[V140-LP] R11 ★★ 死亡掉落绝不回退 points：磁盘 grace.trial.points == 前置基线 500 PASS=true | points=500==500
[V140-LP] R14 ★ 重生回满：磁盘 combat.flask.remaining == flask_max（生产链 flask_restored → 编排层落盘） PASS=true | disk_remaining=3 service_remaining=3 flask_max=3
[V140-LP] R17 ★ 第一次回收成功（生产真实驱动口 reclaim_dropped_points() → ok=true） PASS=true | reason=ok
[V140-LP] R18 ★ 落盘 grace.death.reclaimed == true（false→true 单向） PASS=true | reclaimed=true
[V140-LP] R20 ★★ 回收绝不二次入账 / 不回退 points：磁盘 grace.trial.points == 前置基线 500 PASS=true | points=500==500（回收点数由 Rank-2 经 points_awarded 一次入账，编排层不二次加工）
[V140-LP] R24 schema_version=3、removals 恒空（A71 绝不写 removals） PASS=true | schema=3.0 removals=[]
[V140-LP] R27 ★ 第二次回收被拒（already_reclaimed，生产 DeathService 一次性） PASS=true | ok=false reason=already_reclaimed
[V140-LP] R28 ★★ 重复回收被拒不写盘：reclaim_count / reclaimed / points 全不变 PASS=true | reclaim_count 1→1 reclaimed=true points=500→500
[V140-LP] R29 ★ action_rejected 拒绝事件不写盘：commit_count 不增 PASS=true | commit_count=8→8
[V140-LP] R31 ★★ A71 全链单向 flag 不回退 points 实证：points 全程 == 500 / spent 全程 == 15 PASS=true | points=500 spent=15（元素瓶/死亡/重生/回收/重复回收全链逐字不变）
[V140-LP] X02 ★ 重启读回一致：新 WorldState 逐项 get_flag == 磁盘 PASS=true | flags=16 项逐项比对
[V140-LP] X05 生产 slot_01 md5 前后一致（全程不写 slot_01） PASS=true | md5=884fe86be2ad98720010f59900f38b25
[V140-LP] Y01 真实 G 输入已注入（Input.parse_input_event，物理键码 71） PASS=true | key=G(71) pressed/released
```

### 3.3 三进程三态（3 个独立 PID，共享 `RUN=R37` 临时槽，原文）

```
[V140-C] SUMMARY mode=write pid=30108 slot=user://saves/verify_v140_R37 pass=22 fail=0 total=22
[V140-C] OVERALL=PASS
[V140-C] RESULT=ALL_MATCH
[V140-C] SUMMARY mode=load pid=37104 slot=user://saves/verify_v140_R37 pass=11 fail=0 total=11
[V140-C] OVERALL=PASS
[V140-C] RESULT=ALL_MATCH
[V140-C] SUMMARY mode=assert pid=41920 slot=user://saves/verify_v140_R37 pass=64 fail=0 total=64
[V140-C] OVERALL=PASS
[V140-C] RESULT=ALL_MATCH
[V140-C] A02 三进程真跑（write/load/assert pid 互不相同） PASS=true | write=30108 load=37104 assert=41920
```

### 3.4 GATE-3 `--headless --quit` 主场景实证（原文，不加载 `presentation.gd`）

```
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=41（R20 登记 25，如实回读不冒充）
[R37][WaveTrial] 元素瓶生产订阅者已装配：FlaskService 唯一实例 + 3 信号 connect（A48①/A54）
[R37][WaveTrial] 死亡轮回生产订阅者已装配：DeathService 唯一实例 + 4 信号 connect（A48①/A54）
[R37][PCO] A70/A71 生产订阅者已绑定 FlaskService + DeathService 唯一实例 | signals=7 slot=user://saves/slot_01（元素瓶 / 死亡轮回单向 flag 落盘，绝不回退 points）
[R37][HUD] 生产装配 | flask_unique=true death_unique=true grace_subscribed=true（A48①/A54，不自建第二实例）
[R37][ENC] 生产装配 | flask_unique=true death_unique=true flask_signal_subscribed=true（A48① 生产运行时订阅者，A54 不自建第二实例）
G3_EXIT=0   SCRIPT ERROR=0（无输入不写盘）
```

### 3.5 最终统一三段门禁 `grep SCRIPT ERROR=0`（原文）

```
===== SCRIPT ERROR 逐日志统计 =====
R37_g1_import.log: SCRIPT_ERROR=0
R37_g2a_pco.log: SCRIPT_ERROR=0
R37_g2a_v140c.log: SCRIPT_ERROR=0
R37_g2a_v140lp.log: SCRIPT_ERROR=0
R37_g2b_v140c_all.log: SCRIPT_ERROR=0
R37_g2b_v140c_assert.log: SCRIPT_ERROR=0
R37_g2b_v140c_load.log: SCRIPT_ERROR=0
R37_g2b_v140c_write.log: SCRIPT_ERROR=0
R37_g2b_v140lp.log: SCRIPT_ERROR=0
R37_g3_quit.log: SCRIPT_ERROR=0
TOTAL_SCRIPT_ERROR_LINES=0
```

**PASS/FAIL 汇总**：`83 + 97 + 58 = 238 PASS / 0 FAIL`，全 `RESULT=ALL_MATCH`，10 份日志全 `EXIT=0`、`SCRIPT ERROR=0`。

### 3.6 非 `SCRIPT ERROR` 的引擎 `ERROR` 行（如实登记，不冒充全绿）

```
teamwork/Rank-3/R37_g2b_v140lp.log:64:ERROR: Can't use get_node() with absolute paths from outside the active scene tree.
   at: get_node_or_null (scene/main/node.cpp:1910)
   GDScript backtrace: [0] _ready (res://scripts/combat/boss_controller.gd:86)
                       [1] _respawn_boss (res://scripts/combat/encounter_director.gd:359)
                       [2] _grace_rest  (res://scripts/combat/encounter_director.gd:300)
                       [3] trial_grace_rest (res://scripts/combat/encounter_director.gd:792)
                       [4] _on_respawn_performed (res://scripts/combat/wave_trial_director.gd:1369)
                       [5] on_grace_respawn (res://scripts/combat/death_service.gd:318)
                       [6] on_grace_respawn (res://scripts/combat/wave_trial_director.gd:1407)
                       [7] _t_real_chain (res://scripts/rpg/verify_life_production_v140.gd:537)
```

> 归属核验：`at:` / backtrace 全部指向 **Rank-1 既有代码**（`boss_controller.gd` / `encounter_director.gd`）+ Rank-2 `wave_trial_director.gd` / `death_service.gd`，**无一条指向本轮 Rank-3 的 3 个文件**。由本轮真实重生链在 `--script` 工具模式下触发 `/root/...` 绝对路径探活；属 Rank-1 既有降级问题、**非本轮引入、非 `SCRIPT ERROR`、不影响 `EXIT=0` 与任何断言**（后续 `[BossController] 阶段装载 -> phase_index=1 ... 招式数=2` 成功）。按「不改其它 Rank 产出 / 不越界」如实登记，清理列入 §9 待裁决项 / 迭代文档 §9 backlog。
> 其余尾部 WARNING（`[SaveSystem] --script 工具模式跳过自动读回` / `[ChunkManager] 未找到 ChunkRoot` / `[R34C]/[R36]/[R37][PCO] 绑定降级` / `2 ObjectDB instances were leaked at exit`）均为无主场景 / 无 HUD 纯工具模式安全降级，非本轮引入、非 `SCRIPT ERROR`、不影响门禁。
> **另如实登记**：真实可达 `R15` 观测 `restore_count=2`（重生时 Rank-2 导演层 + Rank-1 HUD `grace_rested` 重入各触发一次 `flask_restored`，沿用 Rank-1 DONE-R37 §8 待裁决项 3 的二次广播现象）；断言用 `remaining == flask_max`（确定回满）+ `restore_count >= 1`（鲁棒），不误判 FAIL、未放宽任何核心断言。

---

## 4. ★ 单向 flag 不回退 points 实证（交付·重点）

> 任务单硬要求「掉落 / 回收用独立单向 flag 表达，**绝不回退 points、绝不写 removals**」。以下为**读磁盘**的机器判定 + 真实生产链路双重实证，非纸面设计。

### 4.1 磁盘真值（真实可达回归 `verify_life_production_v140.gd`，独立 PID 临时槽）

| 阶段 | 磁盘 `grace.trial.points` | 磁盘 `grace.trial.spent_points` | `removals` | 单向 flag 变化 |
|---|---|---|---|---|
| 前置（生产 HUD `points_awarded` + `boon_draft_applied` 落盘） | `500` | `15` | `[]` | — |
| ① 元素瓶扣减 `flask_used` | `500` | `15` | `[]` | `combat.flask.remaining 3→2`、`use_count=1` |
| 满血拒绝 `flask_rejected` | `500` | `15` | `[]` | **不写盘**（`use_count 1→1`、`commit 3→3`） |
| ③ 死亡掉落 `death_occurred` | `500` | `15` | `[]` | `grace.death.dropped=250`、`grace_snapshot=500`、`count=1`、`reclaimed=false` |
| ④ 重生回满 `respawn_performed` + `flask_restored` | `500` | `15` | `[]` | `combat.flask.remaining→3`、`respawn_count=1` |
| ⑤ 一次性回收 `points_reclaimed` | `500` | `15` | `[]` | `grace.death.reclaimed=true`、`reclaim_count=1` |
| ⑦ 重复回收被拒 `action_rejected` | `500` | `15` | `[]` | **不写盘**（`reclaim_count 1→1`、`commit 8→8`） |
| 重启读回（新 WorldState `_apply_snapshot`） | `500` | `15` | `[]` | 16 项逐项一致 |

### 4.2 反例（broken 判据，任一命中即 FAIL，全部被拒）

| 反例 | 期望（若违规） | 实际落盘 | 判定 |
|---|---|---|---|
| 死亡掉落真扣 points | `250`（`500 − 250`） | `500` | `C02` / `R11` PASS（不回退） |
| 回收二次入账 | `750`（`500 + 250`） | `500` | `C03` / `R20` PASS（不二次入账） |
| 重复回收累加计数 | `reclaim_count=2` | `1` | `F06` / `R28` PASS（一次性） |
| 写 `removals` | 非空 | `[]` | `C05` / `R12` / `R21` / `R24` PASS（绝不写 removals） |

### 4.3 机制层实证（代码断言，非纸面）

- `_commit_life()` 前置校验：`life_writes` 只允许 `combat.flask.*` / `grace.death.*` 前缀，**显式排除 `K_POINTS` / `K_SPENT`**（`S06` 静态证据）；`awarded_points=0`、`new_total=磁盘 points 原值` → `points_committed` 不误导。
- 唯一实例 / 生产订阅者：`R26` 断言 11 个 life flag 全为独立前缀、绝不混用 `points` / `spent_points`；`B03` 7/7 connection_list；`GATE-3` 主场景 `signals=7` 自动绑定。
- 全链结论：`R31 ★★ A71 全链单向 flag 不回退 points 实证：points 全程 == 500 / spent 全程 == 15 PASS=true`。

> **结论**：掉落 / 回收**只用 6 个 `grace.death.*` 独立单向 flag 表达**（`dropped` 只读记录 / `reclaimed` false→true 单向 / `count` / `grace_snapshot` / `respawn_count` / `reclaim_count`），**磁盘 `grace.trial.points` 全链逐字不变、`removals` 恒空**；回收点数由 Rank-2 经 `points_awarded` 一次入账（A55/A57），Rank-3 编排层订阅 `points_reclaimed` 只写单向 flag，**绝不二次入账、绝不回退 points**。三态夹具（13 项三方一致）与真实可达回归（16 项重启读回一致）双重机器判定。

---

## 5. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 编排层 R37 段落地：7 信号生产订阅者（A48①）+ 11 个三段式 flag + `_commit_life` 显式隔离 + 惰性初始化 / 安全降级 + `bind_life_services` 显式入口 + `get_status` 13 个观测字段；既有逻辑逐字未改。② 两份新验证脚本（83 + 58 PASS）+ 三进程三态（97 PASS）= **238 PASS / 0 FAIL**、全 `RESULT=ALL_MATCH`。③ 三段门禁 10 份日志全 `EXIT=0`、`TOTAL_SCRIPT_ERROR_LINES=0`。④ **单向 flag 不回退 points / 不写 removals / 不二次入账** 机器判定 + 反例全被拒（§4）。⑤ 真实输入链全链读磁盘断言：元素瓶扣减 → 落盘 → 死亡掉落 → 重生回满 → 一次性回收 → 重启读回一致 → 重复回收被拒。⑥ 拒绝事件不写盘（`flask_rejected` / `action_rejected`）实证。⑦ 契约 §3.3 只追加 R37 段（A69 补登 / 策略裁决 / A70~A73）、规范 §3.3 补 11 行、迭代文档 + README §八 + 本 DONE + 回执。⑧ A38 节点 41 / uv `2/1/1`、A48③ 不加载 `presentation.gd`、A48① 7/7、A54 唯一实例、生产 `slot_01` md5 前后一致。⑨ 回执写入并**中枢归档确认**（§11）。 |
| **失败** | 无（Rank-3 自有交付无失败项）。如实另记：1 条非 `SCRIPT ERROR` 的引擎 `ERROR` 行（`boss_controller.gd:86` 绝对路径，Rank-1 既有、非本轮引入、不影响 `EXIT=0` 与断言），见 §3.6。 |
| **需用户确认** | ① 全部 `[PLACEHOLDER]` 数值待人工试玩校准（只改表 / 常量）；② **`focus_rejected` 落盘策略冲突**（建议「不写盘」vs R36 既有「写盘」）——本轮新增拒绝信号按建议落地、既有口径不擅改，是否统一收口待裁决；③ 15~20 秒定稿录屏目视（元素瓶 HUD /「你死了」/ 狮子斩暖金弧 A72 / HD-2D 全绿 A73）由总指挥亲自回看，代码断言不算画面验收；④ 死亡与重生演示覆盖 / 连击 D→A·S 级演示覆盖；⑤ HD-2D 全绿（A73）、`128bit` 歧义（A53）、真机 exe/apk 手感、既有 WARNING / 绝对路径 ERROR 清理；⑥ 重生 `restore_count=2` 二次广播是否需在 Rank-2 / Rank-1 侧收敛。 |

---

## 6. A69 契约补登与 `focus_rejected` 策略结论（交付·重点）

### 6.1 A69 补登结论（R36 遗留 P0）

- **冲突识别**：R36B / v0.13.x 已在 Rank-1 `hud.gd` / `encounter_director.gd` 落地「**R 键战技切换**」（物理键码 82，辉石魔砾 ↔ 狮子斩），工程根 README §七 R36 定稿段亦已写「R 切换 / Q 释放（A69）」，但 `00-协作契约.md` §3.3 历轮说明段（R25~R36）**未登记该键位口径** —— 属 R36 遗留 P0 契约未同步。
- **本轮处置**：契约 §3.3 **只追加** R37 说明段补登 A69 —— ① `R`(82) 战技切换 / `Q`(81) 释放当前战技 / `G`(71) 元素瓶使用（R37 新增，A70）；② 死亡态下 G/Q/K/F 被 HUD / ENC 门禁拒绝、R 消费不转发（沿用 Rank-1 DONE-R37.md §3 键位表，既有 Q/J/K/R/E/1/2/3/Tab 判定逐字不动）；③ 归属 Rank-1 输入层 / Rank-2 数据表，Rank-3 只登记不写业务代码；④ 键位 / 多战技循环顺序若需调整列入待裁决项。
- **边界**：只追加、不改历史条款 / I-1~I-6 接口表 / §3.1 §3.2 缺号；未改 `hud.gd` / `encounter_director.gd` / `project.godot` 输入映射（Rank-1 授权范围）。

### 6.2 `focus_rejected` 落盘策略结论（★ 裁决登记 + 冲突待裁决）

- **建议口径**（任务单）：拒绝事件不写盘、只走 HUD 反馈，避免无效 commit 膨胀。
- **既有口径冲突（如实登记）**：R36 / A66 契约 §3.3 已登记 `combat.focus.last_reject`（String）由 `focus_rejected` 信号写盘（`commit("focus_rejected_<reason>")` 原子写），生产编排层 `points_commit_orchestrator.gd::_on_focus_rejected()` 亦已实现该写盘路径；若改为「不写盘」需同时改 R36 历史条款 / 既有生产实现 / `verify_v130_save_commit.gd` + `verify_focus_production_v130.gd` 回归期望值，**超出本轮「只追加、不改历史条款 / 不改其它 Rank 产出」授权边界**。
- **本轮裁决结论（三段）**：
  1. **本轮新增拒绝信号按建议落地**：`flask_rejected`（FlaskService）/ `action_rejected`（DeathService，含重复回收被拒 / 死亡期间行动被拒 / 异常输入）在编排层只做 `_life_reject_observed` 运行时观测 + HUD 反馈（Rank-1 / Rank-4），**绝不产生 commit、绝不改任何 flag、绝不写盘**（机器判定 `W15 / G05 / R07 / R29`）；避免无效 commit 膨胀。
  2. **`focus_rejected` 既有 R36 口径本轮不擅改**：维持「写 `combat.focus.last_reject`」口径，不改 R36 历史条款、不改既有生产回调、不放宽既有回归。
  3. **口径冲突列入待总指挥裁决**：是否把 `focus_rejected` 也统一改为「拒绝事件不写盘、只走 HUD 反馈」（需同步改契约 §3.3 R36 段 / 编排层 `_on_focus_rejected` / `combat.focus.last_reject` flag 登记 / 两份 R36 验证脚本期望值），以及是否连带清理 `combat.focus.last_reject` 已落盘历史值，均列入 §9 待裁决项与迭代文档 §9 backlog（零付费零外部依赖增量），由总指挥裁决后统一收口；**本轮 Rank-3 不擅自改动**。

---

## 7. 裁决登记 A70~A73（契约 §3.3 R37 说明段同步）

| 裁决 | 结论 | 落地证据 |
|---|---|---|
| **A70** | 元素瓶唯一实例（Rank-2 `FlaskService`，A54 `get_flask_service()` 复用、绝不 new 第二个）+ 落盘唯一写入方 = Rank-3 编排层 autoload（I-1 / A50）+ **G 键**（71，HUD/ENC 双接幂等）+ **赐福休息补满瓶**（唯一允许瓶数增加出口）；5 个 `combat.flask.*` 与 `grace.trial.points` / `spent_points` / `combat.focus.*` 分离（A66 延续，FP 与赐福点数继续分离） | 编排层 5 flag + `R02~R05 / R14 / G01~G04` / `P06` / G3 `flask_unique=true` |
| **A71** | 死亡轮回：**不回退 points / 不写 removals**、6 个 `grace.death.*` **独立单向 flag 表达掉落与回收**、**重生重置范围**（Rank-2 复位 FP/瓶/连击/窗口、Rank-1 回满 HP、Rank-3 只记 `respawn_count`）、**回收一次性**（`reclaimed` false→true、`reclaim_count` 恒 1、重复回收 `already_reclaimed` + `action_rejected` 不写盘） | §4 全章 + `R08~R31` / `C01~C05` / `F01~F07`，反例 `250 / 750 / 2` 全被拒 |
| **A72** | 狮子斩暖金弧可辨识度**沿用 A67 由总指挥目视验收，代码断言不算画面验收**：只在 15~20 秒定稿录屏关键帧由总指挥亲自目视确认；代码断言 / 逻辑真跑 / headless 帧计数 / 日志实证均不构成画面验收 | 如实登记为需用户确认（Rank-1 DONE-R37.md §4.6 已记「视觉可辨识度未过验收」） |
| **A73** | HD-2D 全绿仍按 **A41/A52/A61/A68** 三判据（J1/J2/J3）判定、不据单路自评宣称全绿，**如实记「未达全绿」**；`128bit` 歧义**继续保留 A53**（不消歧、不编码进任何期望值） | §5 需用户确认 / §8 未完成项 / README §8.1「❌ 未达」 |

---

## 8. 未完成项 / 阻塞

- **A72 定稿录屏目视**：元素瓶 HUD /「你死了」/ 狮子斩暖金弧可辨识度 / HD-2D 全绿按公共契约由总指挥本轮亲自重跑并目视；Rank-3 headless 真跑无帧缓冲，**不含新 MP4 / 抽帧 / 目视结论**，不冒充可玩交付（A48④）。
- **死亡与重生演示覆盖**：450 帧演示内 HP 未归零（Rank-1 DONE-R37.md §6 如实登记「链路已接线但演示未覆盖」）；本轮 Rank-3 的真实可达由 V140-LP D/R 组承担，不冒充演示覆盖。
- **`[PLACEHOLDER]` 试玩校准**：`flask_rules.tres` / `death_rules.tres` 6 字段 + `COST_TO_POINTS_*` 常量 + G 键手感，待人工试玩；调参唯一入口 = 数据表 / 常量段（只改表不改代码），Rank-3 不静默改数、不代做手感判断。
- **`focus_rejected` 落盘策略统一收口**：待总指挥裁决后同步改契约 R36 段 / 编排层既有回调 / 两份 R36 验证脚本（§6.2 / §9）。
- **重生二次广播 / `restore_count=2`**：Rank-2 `trial_grace_rest()` → `grace_rested` 二次广播（Rank-1 已加重入守卫），是否源头收敛沿用 Rank-1 DONE-R37.md §8 待裁决项 3。
- **`--script` 模式 `boss_controller.gd:86` 绝对路径 ERROR 清理**：属 Rank-1 授权范围，本轮只读登记不越界改（§3.6）。
- **HD-2D 全绿（A73）/ `128bit` 歧义（A53）/ 连击 D→A·S 级演示覆盖 / 真机 exe·apk 手感与移动端触控 / 既有 WARNING 清理 / GitHub 补推**：沿用前序未完成项，由总指挥收尾（不自行 git）。
- 无阻塞；所有硬约束内工作已完成。

---

## 9. 待总指挥裁决项（只登记、不擅改）

1. **`focus_rejected` 落盘策略冲突（P0）**：是否把 `focus_rejected` 统一改为「拒绝事件不写盘、只走 HUD 反馈」（需同步改契约 §3.3 R36 段 / 编排层 `_on_focus_rejected` / `combat.focus.last_reject` 登记 / 两份 R36 验证脚本期望值），以及是否清理 `combat.focus.last_reject` 已落盘历史值。
2. **数值校准**：`flask_max=3` / `heal_amount=50.0` / `rest_refill=true` / `drop_ratio=0.5` / `drop_cap=500` / `invalid_input_policy="reject"` 全部 `[PLACEHOLDER]`，待人工试玩校准；调参唯一入口 `flask_rules.tres` + `death_rules.tres`，同步 `EXPECT_*` 与迭代文档数值表。
3. **死亡掉落语义口径**：本轮「掉落 = 叙事层只读记录 + 独立 dropped / reclaimed 单向 flag」，磁盘 `grace.trial.points` 绝不回退、绝不写 `removals`（A59/A71）；若需改为「真正扣除再捡回」口径，与 A59/A71 直接冲突，需先裁决口径再改代码 + 表 + 回归。
4. **A72 定稿录屏目视 / A73 HD-2D 全绿 / `128bit` 歧义**：按 A41/A52/A61/A67/A68/A73/A53 判定，headless 不代做画面与手感判断。
5. **`reclaim_dropped()` 触发点 / 回收点数入账链归属**：Rank-1 DONE-R37.md §8 待裁决项 2（一次性回收与 `points_awarded` 一次入账触发链）；本轮 Rank-3 编排层只订阅 `points_reclaimed` 写单向 flag，不擅自新增入账。
6. **重生二次广播收敛 / Rank-2 侧 `restore_count=2` 口径**：是否需在 Rank-2 / Rank-1 侧收敛（沿用 Rank-1 §8 待裁决项 3）。
7. **`--script` 模式绝对路径 ERROR / 既有 WARNING 清理**：Rank-1 授权后把 `/root/...` 绝对路径改为 `Engine.get_main_loop() as SceneTree` 相对查找；是否纳入后续清理由总指挥裁决。
8. **A69 键位 / 多战技循环顺序 / 元素瓶 HUD 形态**：G 键最终实机手感、「元素瓶 N/M」常驻文本与「你死了」节点位置、是否需瓶图标 / 死亡遮罩 / 重生特效（Rank-4），请裁决归属与避让断言同步。
9. **信号命名口径**：Rank-1 HUD 4 信号（`flask_used / flask_rejected / player_died / player_respawned`）与 Rank-2 FlaskService 3 信号 / DeathService 4 信号分属不同对象、签名不同，是否需统一命名 / 合并（沿用 Rank-1 §8 待裁决项 6）；本轮编排层订阅的是 Rank-2 服务信号，不与 HUD 信号混连。
10. **四路全部收尾后最终统一复跑**：三段门禁取最终全绿（沿用 Rank-2 §7 裁决项 10）。

---

## 10. 硬约束遵守声明

- **唯一写入方**：只写 `godot/scripts/rpg/points_commit_orchestrator.gd`、`godot/scripts/rpg/verify_v140_save_commit.gd`、`godot/scripts/rpg/verify_life_production_v140.gd`、`teamwork/00-协作契约.md` §3.3 追加段、`teamwork/Rank-3/存档与flag规范.md` §3.3、`teamwork/迭代-v0.14.0-元素瓶与死亡轮回.md`、`README.md` 状态段、`teamwork/Rank-3/`（10 份门禁日志 + 本 DONE）、回执。
- **只读未改**：`godot/project.godot`（既有 autoload 不动）、`godot/scenes/courtyard.tscn`（节点 41 / uv `2/1/1`，G3 实证）、`godot/test/presentation.gd`（只读，V140-LP B00 零 presentation 节点）、`godot/scripts/hud.gd` / `encounter_director.gd` / `wave_trial_director.gd` / `flask_service.gd` / `death_service.gd` / `impact_feedback.gd`、全部既有 `.tres` / 素材、其它 Rank 产出、契约其它历史条款。
- **不改既有口径**：SaveDelta 十字段冻结 / `schema_version=3` / 不写 `removals` / `grace.trial.points` 单调递增只增不减 / `commit(reason)` 原子写 / **先落盘再改运行时实例** / 重启读回一致 / FP 与赐福点数分离（A66）；编排层既有 A55/A57/A59/A66 分支逐字未改（只在文件末尾追加 R37 段 + 5 处最小插入）。
- **Godot 真跑纪律**：`Engine.get_main_loop() as SceneTree` 取 root（不用 `get_tree()` / `/root/...` 绝对路径）、`add_child` 后显式 `call("_ready")`、资源 `CACHE_MODE_IGNORE`、connect 去重、`_release()` 兜底释放；三进程三态 / 生产验证用独立 PID 临时槽、不碰生产 `slot_01`；编排层 autoload 在无 HUD 的纯工具模式惰性初始化 / 安全降级、不报错不写盘。
- **零付费、零外部依赖、不启 GPU job**；不伪造产物、不谎报成功、不自行 git（总指挥收尾）；未删除 `.workbuddy` 目录。
- **默认不刺探**：未扫目录做进度巡检、未新建只读探针 / 巡检脚本、不反复核对文件状态；仅按任务单要求读必做文件 / 目标文件 / 上游 DONE，按真跑输出判断进度，并在写回执后按任务单要求确认中枢归档结构。

---

## 11. 回执与中枢归档确认（写后实测，如实登记）

- **回执写入授权路径**（**`teamwork/command_center/`，非工程根**）：`teamwork/command_center/ai/3/outbox/cmd-20261112-184157-088-A3.json`，四字段 `{"task_id":"cmd-20261112-184157-088-A3","ai":3,"status":"done","result":"引用 DONE-R37.md 实际结论"}`。
- **中枢归档回读确认（写后实测）**：
  - `ai/3/outbox/` 写后已被中枢移走（`outbox_exists=False`，回执移入 `dispatcher/receipts/`，属中枢正常处理），不重放、不伪造。
  - **归档副本**：`teamwork/command_center/dispatcher/receipts/cmd-20261112-184157-088-A3.json` 存在（**2,723 字节**），回读 **VALID_JSON**，`keys=['ai','result','status','task_id']` 四字段齐全，`task_id=cmd-20261112-184157-088-A3` / `ai=3` / `status=done` / `result_len=1560`，与 outbox 回执逐字一致。
  - `teamwork/command_center/ai/3/status.json` 更新为 `{"ai":3,"state":"idle","current_task":"","completed":42,"last_seen":"2026-11-12 19:50:43"}`（`completed` 由 **41 → 42**、`current_task` 清空、`state` working → idle）。
  - `dispatcher/ledger.jsonl` 本任务行回读 **VALID_JSON**：`id=cmd-20261112-184157-088-A3 / ai=3 / status=done / issued_at=2026-11-12 18:41:58 / finished_at=2026-11-12 19:50:43`（`result_len` 字段本行为 `None`，如实登记、不编造）。派单 `issued_at` 与任务单 `issued_at=2026-11-12 18:41:58` 一致。
  - `dispatcher/dispatcher.log` 尾部原文：`[2026-11-12 19:50:43] ← 3 号 AI 回执 <cmd-20261112-184157-088-A3> 完成：R37/v0.14.0 Rank-3 交付完成，实际结论见 teamwork/Rank-3/DONE-R37.md：① `，确认 id 与派单一致、中枢已回收验证 `done`。
- **结论**：回执已写、**中枢已归档**，四字段齐全、`status=done`，与 `dispatcher/receipts/` 归档副本 / `ledger.jsonl` / `dispatcher.log` / `ai/3/status.json` 一致（写后回读实测，不伪造）。

---

## 12. 交付·缺一不可 对照

| # | 要求 | 落地 |
|---|---|---|
| 1 | 实际文件 + 真跑输出原文 | §1 交付清单（10 类实际文件，含字节数）+ §3 真跑输出原文（10 份日志留档 `teamwork/Rank-3/R37-*.log`，关键行逐条贴原文） |
| 2 | `teamwork/Rank-3/DONE-R37.md` | 本文件：交付清单 / 真跑输出 / 验收三态 / **单向 flag 不回退 points 实证**（§4） / A69 契约补登与 `focus_rejected` 策略结论（§6） / 未完成项（§8） / 待裁决项（§9） |
| 3 | 回执 `teamwork/command_center/ai/3/outbox/<id>.json` + 写后确认中枢归档 | §11 实测（receipts 副本 VALID_JSON / status idle / completed 42 / ledger done / dispatcher.log 回收） |
