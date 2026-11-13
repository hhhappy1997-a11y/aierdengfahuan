# DONE-R38.md · R38 / v0.15.0「大地图 · 2.5D 尺度重构」赐福网络与大地图存档交付报告（Rank-3）

> 轮次：`R38` ｜ 任务单 id：`cmd-20261112-234238-656-A3` ｜ 执行 AI：`3（Rank-3 RPG / 世界 / 存档执行 AI）`
> 真源：`teamwork/Rank-3/调度任务单-latest.json`（task 全文 + 公共契约 + 大改特别条款 + A48 硬要求 + 目录所有权·R38 冻结，HOST 裁决 A74~A78 由 Rank-3 登记）
>   + `teamwork/Rank-1/DONE-R38.md`（A74 新基线 54 / uv 16-8-8、大地图 4096×2304、人物 40%）
>   + `teamwork/Rank-2/DONE-R38.md` §3（野外遭遇 4 信号 / 分区 id 真源 / A77 既有三波入口不废）
>   + `teamwork/00-协作契约.md` §3.3（历史条款 / I-1~I-6 / 裁决 A39~A73）
> 工程：`F:/Game/aierdengfahuan/godot` ｜ 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`Godot Engine v4.7.2.stable.official.ed1daf0bf`）
>
> **一句话结论**：R38 五块任务全部真跑完成 —— ① **赐福网络**：新写 `godot/data/rpg/grace_sites.tres`（4 个赐福点 × 5 字段、全部 `[PLACEHOLDER]` + rationale、与 Rank-1 大地图 4 个分区 id 逐字对齐）+ 新写 `godot/scripts/rpg/world_map_service.gd`（`extends Resource` / `class_name WorldMapService`，既是表脚本又是纯逻辑服务：区域发现 / 赐福激活 / 快旅 / 迷雾揭开 / 地图进度，**重复激活拒绝、未解锁快旅拒绝、异常输入拒绝、进度单调递增**，4 个公开信号）；② **落盘**：`points_commit_orchestrator.gd` 末尾追加 R38 段订阅 4 信号（A48① 生产订阅者 / A54 唯一实例），登记 **11 个三段式 flag**，遵守 SaveDelta 十字段 / `schema_version=3` 冻结 / 不写 `removals` / `grace.trial.points` 只增不减 / `commit(reason)` 原子写 / 先落盘再改运行时实例 / 重启读回一致；③ 新写 `verify_v150_save_commit.gd`（三态 85 PASS / 三进程 105 PASS）与 `verify_world_production_v150.gd`（A48③ 真实可达 53 PASS，不加载 `presentation.gd`、不在验证脚本内模拟编排、读磁盘断言「区域发现 → 赐福激活 → 快旅 → 重启读回一致 → 重复激活被拒」），合计 **243 PASS / 0 FAIL**、全 `RESULT=ALL_MATCH`；④ **契约 §3.3 只追加 R38 说明段**（登记 HOST 裁决 A74~A78，不改历史条款 / I-1~I-6 / §3.1 §3.2 缺号）+ `存档与flag规范.md` §3.3 补 11 行 + R38 注记；⑤ 新写 `teamwork/迭代-v0.15.0-大地图与2.5D.md`（玩法拆解表 / P0~P2 / GDD 六项 / 三栏 / 架构图与数据流 / 真跑数字 / 验收三态 / 风险回滚 / 零付费 backlog）+ README §九 追加 v0.15.0 状态表 / 资产表 / 已做与还差（只追加、不删历史行）；⑥ **三段门禁 11 份日志全 `EXIT=0`、`SCRIPT ERROR=0` / `PARSE_ERROR=0` / 其它 `ERROR=0`**，G3 主场景实证 `node_count=54`（A74 新基线）+ `[R38][PCO] … signals=4` 生产订阅者自动装配、无输入不写盘。**如实登记**：A74 后既有 5 份回归 8 条 A38 旧基线（41 / 2-1-1）过期断言 FAIL 属 Rank-1 并行断言同步工作（用户口径称 A79 授权；Rank-1 `DONE-R38.md` §10 待裁决 #1），Rank-3 不越权改别人的脚本，本轮真实可达回归不实例化 `courtyard.tscn`、不含节点数断言，故未遇到该 FAIL；G3 回读已是 `node_count=54`。

---

## 1. 交付清单（实际落地文件）

| # | 文件 | 类型 | 本轮改动 |
|---|---|---|---|
| ① | `godot/data/rpg/grace_sites.tres` | **新建** | 赐福点唯一数据表：`region_ids` 4 分区（逐字取既有 `m6_area_bindings.tres` 的 `region` 字段） + 4 个赐福点 × 5 字段 `site_id / region_id / position / display_name / unlock_condition` + `invalid_input_policy="reject"`；全部 `[PLACEHOLDER]` + 逐字段 rationale + **调参唯一入口 = 本表（只改表不改代码）** |
| ② | `godot/scripts/rpg/world_map_service.gd` | **新建** | `extends Resource` / `class_name WorldMapService`：既是 `grace_sites.tres` 的表脚本，又是纯逻辑服务（授权清单只允许 1 个新脚本、不授权单独 config 脚本）。4 个公开信号 + `is_valid()` 表校验 + `discover_region()` / `light_site()` / `fast_travel()` / `reset()` / `get_snapshot()`；I-1 纯逻辑边界（不读写存档 / 不碰场景树 / 不碰渲染 / 不落盘）；数值全部来自表、代码不写死设计值 |
| ③ | `godot/scripts/rpg/points_commit_orchestrator.gd` | 修改（Rank-3 唯一写入） | **末尾追加 R38 段 + 6 处最小插入**（常量 / 变量 / `_ready` / `_release` / `get_status` / 文件尾）：订阅 4 信号、A54 唯一实例装配与 getter、11 个三段式 flag、`_commit_world_map()` 显式隔离、惰性初始化 / 安全降级、`bind_world_map_service()` 显式入口、`_release_world_map()` 释放、`get_status` 追加 6 个观测字段；**既有 A55/A57/A59/A66/A70/A71 逻辑逐字未改（A77）** |
| ④ | `godot/scripts/rpg/verify_v150_save_commit.gd` | **新建** | 三进程三态存档验证件：`all` 85 PASS / `write 25 + load 14 + assert 66 = 105 PASS`；口径 + 磁盘一致性 + 重启读回 + 旧档缺 key 回落基线 + 生产订阅者静态证据 |
| ⑤ | `godot/scripts/rpg/verify_world_production_v150.gd` | **新建** | A48③ 真实可达回归（**不加载 `presentation.gd`、不在验证脚本内模拟编排、不实例化 `courtyard.tscn`**）53 PASS：真实生产服务方法 → 生产编排层订阅 → 读磁盘断言 |
| ⑥ | `teamwork/00-协作契约.md`（§3.3 追加 R38 段） | 修改（只追加） | 追加 R38 说明段：11 flag 逐条登记 + 四段示意→三段式收敛口径 + `commit(reason)` / 先落盘再改实例 / A48① 生产订阅者 / **HOST 裁决 A74~A78**；历史条款 / I-1~I-6 / §3.1 §3.2 缺号一律未动 |
| ⑦ | `teamwork/Rank-3/存档与flag规范.md`（§3.3） | 修改 | 全局登记表补 11 行 + R38 注记，历史行未删 |
| ⑧ | `teamwork/迭代-v0.15.0-大地图与2.5D.md` | **新建** | 迭代收口文档：玩法拆解表 / 漏洞识别 P0~P2（含 6 项画面风险）/ GDD 六项 / 三栏清单 / 节点·架构图与数据流 / 自测与真跑数字 / 验收三态 / 风险回滚 / 零付费 backlog / A74~A78 裁决登记 |
| ⑨ | `README.md` §九 | 修改（只追加） | v0.15.0 状态表 / 资产表（字节数实测）/「已做了什么」增量 /「还差什么」增量；历史行一律保留未动 |
| ⑩ | `teamwork/Rank-3/R38_*.log`（11 份） | **新建** | G1 import / 4 份 G2a / 5 份 G2b / G3 quit 真跑 stdout 原文留档，逐份 `SCRIPT ERROR=0` |
| ⑪ | `teamwork/Rank-3/DONE-R38.md` | **新建** | 本交付报告 |
| ⑫ | `teamwork/command_center/ai/3/outbox/cmd-20261112-234238-656-A3.json` | **新建** | 本轮回执（**`teamwork/command_center/`**，非工程根），写后经中枢归档（§10） |

**只读未改（硬约束）**：`godot/project.godot`（既有 autoload / `run/main_scene` / `gl_compatibility`）/ `godot/scenes/courtyard.tscn`（Rank-1 A74 后节点 54 / uv 16-8-8）/ `godot/scripts/hud.gd` / `godot/test/presentation.gd` / `godot/data/render/world_scale.tres`（Rank-1）/ Rank-2 `wave_trial_director.gd` / `world_encounters.tres` / Rank-4 产出 / 全部既有 `.tres` 数值 / 素材 / 既有 5 份 `verify_*` 回归脚本 / 契约其它历史条款 / 其它 Rank 产出。

---

## 2. 五块任务实现说明

### 2.1 任务① 赐福网络（数据表 + 纯逻辑服务）

**为什么是 Resource（既是配置表脚本又是纯逻辑服务）**：本轮【目录所有权·R38 冻结】只允许 Rank-3 新写 1 个脚本（`world_map_service.gd`）+ 1 张表（`grace_sites.tres`），**不授权单独的 `grace_sites_config.gd`**。故本类 `extends Resource` + `class_name WorldMapService`：`@export` 字段即数据表结构（`grace_sites.tres` 挂本脚本、`script_class=WorldMapService`），信号与纯逻辑方法同在本类；加载 `.tres` 得到的那一个 Resource 实例就是 **A54 唯一实例**（由生产编排层持有、`get_world_map_service()` 复用，验证脚本绝不 new / load 第二个）。`_init()` 调 `reset()`，且 `reset()` 不预填任何依赖 `@export` 字段的状态（加载期 `_init()` 先于属性赋值执行）。

**4 个公开信号**（签名稳定，见 §3）：
```
signal region_discovered(region_id: String, discovered_count: int, progress: int)
signal grace_site_lit(site_id: String, region_id: String, lit_count: int, progress: int)
signal fast_travel_performed(site_id: String, region_id: String, travel_count: int, progress: int)
signal map_action_rejected(reason: String, action_id: String)
```

**规则逐条**：
- `discover_region`：表非法 `no_config` / 非 String·空 `invalid_input` / 未注册 `unknown_region` / 已发现 `already_discovered`（幂等拒绝）；成功置发现态、`_discovered_count+1`、`_progress+1`、发 `region_discovered`。
- `light_site`：**★ 重复激活 `already_lit` 拒绝**；`unlock_condition="region_discovered"` 时要求所属区域已发现（否则 `region_not_discovered`）；成功 `_lit_count+1`、`_progress+1`、发 `grace_site_lit`。
- `fast_travel`：**★ 未解锁 `not_lit` 拒绝**（目标未点亮）/ `region_not_discovered`（所属区域未发现）；成功置最近落点、`_travel_count+1`、`_progress+1`、发 `fast_travel_performed`。
- **★ 进度单调递增**：`_progress = _discovered_count + _lit_count + _travel_count`，仅成功动作 +1（每个恰好 +1），拒绝一律不改，除显式 `reset()` 外只增不减。
- **★ 异常输入拒绝**：null / 非 String / 空串 / 未注册 id / config 非法全拒绝且不改状态；`invalid_input_policy` 首版唯一合法值 `"reject"`。
- **迷雾揭开**：区域发现即揭开该区迷雾；编排层落 `world.map.fog_revealed`（int 单调递增）。
- `is_valid()`：分区集合非空无重复、每行 5 字段、`site_id` 唯一且全小写 snake_case（保证拼出的三段式 flag key 合法）、`region_id ∈ region_ids`、`position` 为有限非负 Vector2、`unlock_condition ∈ {none, region_discovered}`、policy==reject；异常一律 false（不崩）。

### 2.2 任务② 落盘（编排层 R38 段 + 两份验证脚本）

**11 个三段式 flag**（严格匹配 `^(world|quest|combat|grace|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`）：

| # | key | 类型 / 基线 | 单调性 |
|---|---|---|---|
| 1~4 | `world.region_<region_id>.discovered` ×4 | bool / `false` | false→true 单向 |
| 5~8 | `grace.site_<site_id>.lit` ×4 | bool / `false` | false→true 单向（重复激活被拒不回写） |
| 9 | `world.map.progress` | int / `0` | 单调递增、只增不减（`max(磁盘旧值, payload)`） |
| 10 | `world.map.fog_revealed` | int / `0` | 单调递增、只增不减 |
| 11 | `world.map.last_fast_travel` | String / `""` | 非单调·最近落点覆盖 |

> **★ 四段示意 → 三段式收敛（如实登记，不隐瞒）**：任务单示意 `world.map.region_<id>.discovered` 为**四段**，与冻结三段式正则冲突；R38 落盘收敛为 `world.region_<id>.discovered`（域 `world` / 对象 `region_<id>` / 属性 `discovered`），`<id>` 逐字保留、语义不变、机器正则全 PASS（`W08 / D04 / T04`）。示意中 `grace.site_<id>.lit` / `world.map.progress` 本身即三段、原样采用。是否保留四段字面列入 §9 待裁决。

**既有口径遵守**：`_commit_world_map()` 显式隔离（`world_writes` 只允许 `world.map.*` / `world.region_*` / `grace.site_*` 前缀，显式排除 `K_POINTS` / `K_SPENT`）→ 复用既有 `_commit()`：十字段冻结 / `schema_version=3` / `removals=[]` / `.tmp→flush→rename→delta.json+.bak` 原子写 / **落盘成功后才 `_apply_snapshot(delta)` 注入 WorldState 运行时实例并 emit** / 失败则不改内存、如实告警；磁盘为唯一权威、重启读回一致；**拒绝事件 `map_action_rejected` 不写盘**（沿用 R37 策略，只 `_world_map_reject_observed` 运行时观测 + HUD 反馈）。

**A48① / A54 / 安全降级**：4 信号生产订阅者 = `PointsCommitOrchestrator` autoload 的 `bind_world_map_service()`（connect 在生产脚本内，非验证脚本）；唯一实例由 `_ensure_world_map_service()` 以 `CACHE_MODE_IGNORE` 只加载一次并持有，`get_world_map_service()` 复用、`bind_world_map_service()` 显式拒绝替换、`_world_map_bind_done` 标记使退出阶段 flush 的 deferred 不重复 load 第二个；无 HUD / 无主场景的纯 `--headless --quit` / `--import` / `--check-only` 场景重试耗尽仅 `push_warning` 降级（不订阅 / 不写盘 / 不报错 / 不 null 解引用）。

**两份验证脚本分工（如实登记，不冒充）**：
- `verify_v150_save_commit.gd`：**三态口径确定性夹具**（`extends SceneTree`，三进程 `write/load/assert` + 单进程 `all`），只验证**落盘口径 + 磁盘一致性**，文内 `_sig_*` 是自包含夹具、**不冒充真实可达**。
- `verify_world_production_v150.gd`：**A48③ 真实可达回归** —— 不加载 `presentation.gd`（B00 运行时树零 presentation 节点）、**不在验证脚本内模拟编排**（编排全在生产脚本，本件一行未写发现 / 去重 / 落盘 / 累加逻辑）、不实例化 `courtyard.tscn`（WorldMapService 由编排层 autoload 自身装配、链路不依赖主场景节点；此设计同时避免踩 A74 旧基线 41 断言）。链路：取生产 autoload → `configure_slot(独立 PID 临时槽)` → `bind_world_map_service()` → 调 A54 唯一真实服务的公开方法 → 服务发信号 → 生产编排层订阅落盘 → **读磁盘断言**「区域发现 → 赐福激活 → 快旅 → 重启读回一致 → 重复激活被拒」。

### 2.3 任务③ 契约 §3.3 + 规范 §3.3 登记

契约 §3.3 **只追加** R38 说明段（11 flag 逐条登记 + 四段示意收敛 + `commit(reason)` 五步顺序 + A48① 生产订阅者 + A74~A78 逐条如实登记 + 未动声明），**不改历史条款 / I-1~I-6 接口表 / §3.1 §3.2 缺号**；`存档与flag规范.md` §3.3 全局登记表补 11 行 + R38 注记，历史行未删。

**A74~A78 登记摘要**：A74 放开 `courtyard.tscn` 节点 41 / uv 2-1-1 冻结（新基线 54 / 16-8-8 由 Rank-1 真跑回读同步 `verify_wave_runtime_v040.gd`，**不删断言、不放宽判定**）；A75 人物 `1.6 × 0.40 = 0.64`（`world_scale.tres` 唯一调参入口）；A76 大地图 4096×2304 / 分区 id / 相机边界数据驱动；A77 野外遭遇与既有三波并存、既有闭环不废；A78 HD-2D 全绿仍按 A41/A52/A61/A68/A73 判定、`128bit` 继续保留 A53、零付费不变。

### 2.4 任务④ 迭代文档 + README

`迭代-v0.15.0-大地图与2.5D.md` 按既有体例含：玩法拆解表（需求 → 机制 → 数值 → 状态 → 验收）、漏洞识别 P0/P1/P2（**大地图空旷无目标 / 角色过小不可读 / 相机跟随晕眩 / 视差层错位 / 区域触发误触 / 既有三波入口被遮蔽** 6 项逐项处置）、GDD 六项、三栏清单、**节点 / 架构图与数据流**、自测与真跑数字、验收三态、风险与回滚方案、下一版 backlog（**只列零付费零外部依赖增量**）、A74~A78 裁决登记、硬约束声明、未完成项。README §九 追加 v0.15.0 状态表 / 资产表（字节数 `os.path.getsize` 实测）/ 已做与还差增量，**只追加、不删历史行**。

### 2.5 任务⑤ 三段门禁

见 §4 真跑输出原文。G1 `--import` 注册 `WorldMapService` 全局类；G2a `--check-only --script` ×4；G2b `--headless --script` ×5；G3 `--headless --quit` 主场景实证；全 11 份日志 `SCRIPT ERROR=0`。

---

## 3. 供 Rank-1 / Rank-2 使用的公开方法与信号完整签名（稳定、不再改动）

> `WorldMapService` 是 `Resource`（Object 级能力），**信号与实例经生产编排层 `PointsCommitOrchestrator` 复用**：Rank-1 输入层 / Rank-2 / Rank-4 直接 `get_world_map_service()` 拿 A54 唯一实例并 `connect` 即可，无需场景树、无需 `add_child`、无需 `/root/...`。
> **A54 唯一实例**：由编排层 autoload 装配（本轮 Rank-3 不依赖 Rank-2 `wave_trial_director.gd`，因其本轮已冻结）；绝不 new 第二个。

### 3.1 公开信号（4 个，见 §2.1 签名）

### 3.2 `WorldMapService` 公开方法（全静态类型）
```
class_name WorldMapService (extends Resource)
_init()                                   # 自动 reset()
reset() -> void                           # 回构造初始态（每场新一局）
is_valid() -> bool                        # 全表合法性（异常一律 false、不崩）
is_config_valid() -> bool                 # = is_valid()
get_region_ids() -> PackedStringArray
get_sites() -> Array[Dictionary]          # 深拷贝，★ 绝不写回表
get_region_count() -> int / get_site_count() -> int
get_invalid_input_policy() -> String
has_region(region_id: String) -> bool / has_site(site_id: String) -> bool
get_site_region(site_id: String) -> String
is_discovered(region_id: String) -> bool / is_lit(site_id: String) -> bool
get_discovered_count() / get_lit_count() / get_fast_travel_count() / get_progress() -> int
get_last_fast_travel() -> String / get_reject_count() -> int
get_last_result() -> Dictionary / get_last_reject_reason() -> String
get_snapshot() -> Dictionary              # 全状态只读快照

discover_region(region_id: Variant) -> Dictionary
light_site(site_id: Variant) -> Dictionary
fast_travel(site_id: Variant) -> Dictionary
```

### 3.3 返回 Dictionary 字段
```
成功 : {ok, reason, region_id|site_id, discovered_count|lit_count|travel_count, progress, config_present}
拒绝 : {ok, reason, action_id, progress, discovered_count, lit_count, travel_count, config_present}
get_snapshot : {discovered_ids, lit_ids, discovered_count, lit_count, travel_count,
                progress, last_fast_travel, reject_count, region_count, site_count,
                config_present, invalid_input_policy, last_result, last_reject_reason}
```
成功恒 `progress>=0` 且严格较前一成功动作 +1；拒绝时 `ok=false`、不改任何状态、不改进度。

### 3.4 reason 常量（签名稳定）
```
REASON_OK="ok" / NO_CONFIG="no_config" / INVALID_INPUT="invalid_input"
UNKNOWN_REGION="unknown_region" / UNKNOWN_SITE="unknown_site"
ALREADY_DISCOVERED="already_discovered" / ALREADY_LIT="already_lit"
NOT_LIT="not_lit" / REGION_NOT_DISCOVERED="region_not_discovered"
ID_NONE="<none>" / POLICY_REJECT="reject" / UNLOCK_NONE="none"
UNLOCK_REGION_DISCOVERED="region_discovered" / SITE_FIELDS（5 字段契约）
```

### 3.5 `PointsCommitOrchestrator` 本轮新增公开接口（供 HUD / 验证 / 接线）
```
get_world_map_service() -> Object          # ★ A54 唯一实例 getter
bind_world_map_service(service: Object) -> bool  # 显式绑定入口（connect 在生产脚本内）
region_flag(region_id: String) -> String    # "world.region_<id>.discovered"
site_flag(site_id: String) -> String        # "grace.site_<id>.lit"
get_status() 追加 6 个只读 key：
    world_map_bound / world_map_service / world_map_reject_observed /
    map_progress / map_fog_revealed / map_last_fast_travel
```

### 3.6 Rank-1 输入层接线示意（跨 Rank 接线待总指挥裁决，伪代码）
```gdscript
# A54 唯一实例：从生产编排层 autoload 复用，绝不 new 第二个
var wm: Object = PointsCommitOrchestrator.get_world_map_service()
# 玩家在大地图移动 / 交互：
wm.discover_region(region_id)              # 进入新分区 → 区域发现 + 迷雾揭开
wm.light_site(site_id)                     # 接触赐福 → 首次点亮（重复激活 already_lit 拒绝）
wm.fast_travel(site_id)                    # 赐福菜单 → 快旅（未点亮 not_lit 拒绝）
# 落盘由生产编排层订阅 4 信号完成，Rank-1 不写存档（I-1）
```

---

## 4. 真跑输出原文（三段门禁 + 两份验证，11 份日志留档 `teamwork/Rank-3/R38_*.log`）

命令前缀统一 `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot ...`；引擎版本行：`Godot Engine v4.7.2.stable.official.ed1daf0bf`。

### 4.1 三段门禁 EXIT（原文汇总）

```
G1_IMPORT_EXIT=0
G2A_world_map_service_EXIT=0  G2A_points_commit_orchestrator_EXIT=0
G2A_verify_v150_save_commit_EXIT=0  G2A_verify_world_production_v150_EXIT=0
G2B_v150c_all_EXIT=0     G2B_v150c_write_EXIT=0  G2B_v150c_load_EXIT=0
G2B_v150c_assert_EXIT=0  G2B_v150wp_EXIT=0
G3_QUIT_EXIT=0
```

### 4.2 全工程 `SCRIPT ERROR` / `PARSE ERROR` grep（11 段日志，原文）

```
LOG_COUNT=11
R38_g1_import.log:0                              R38_g2a_points_commit_orchestrator.log:0
R38_g2a_verify_v150_save_commit.log:0           R38_g2a_verify_world_production_v150.log:0
R38_g2a_world_map_service.log:0                 R38_g2b_v150c_all.log:0
R38_g2b_v150c_assert.log:0                      R38_g2b_v150c_load.log:0
R38_g2b_v150c_write.log:0                       R38_g2b_v150wp.log:0
R38_g3_quit.log:0
TOTAL_SCRIPT_ERROR_LINES=0   PARSE_ERROR=0   其它 ERROR 行=0
```

逐日志均为 `SCRIPT ERROR=0 / PARSE ERROR=0`（`grep -c -E "SCRIPT ERROR|Parse Error"` 全部为 0）。**既有 WARNING 如实登记**（非本轮引入、非 `SCRIPT ERROR`、不影响 `EXIT=0`）：`[SaveSystem] --script 工具模式…跳过自动读回`、`[ChunkManager] 未找到 ChunkRoot…`、`[R34C]/[R36]/[R37][PCO] 绑定降级…`、`2 ObjectDB instances were leaked at exit`，与 DONE-R37 §4.2 尾注同口径。

### 4.3 两份验证 SUMMARY / RESULT（原文）

```
[V150-C] SUMMARY mode=all    pid=19528 slot=user://saves/verify_v150_R38        pass=85 fail=0 total=85
[V150-C] OVERALL=PASS   [V150-C] RESULT=ALL_MATCH
[V150-C] SUMMARY mode=write  pid=6520  slot=user://saves/verify_v150_R38        pass=25 fail=0 total=25
[V150-C] SUMMARY mode=load   pid=24584 slot=user://saves/verify_v150_R38        pass=14 fail=0 total=14
[V150-C] SUMMARY mode=assert pid=23240 slot=user://saves/verify_v150_R38        pass=66 fail=0 total=66
[V150-C] A02 三进程真跑（write/load/assert pid 互不相同） PASS=true | write=6520 load=24584 assert=23240
[V150-WP] SUMMARY pid=25336 slot=user://saves/verify_v150_wp_25336 pass=53 fail=0 total=53
[V150-WP] OVERALL=PASS   [V150-WP] RESULT=ALL_MATCH
```
**合计 `85 + 105 + 53 = 243 PASS / 0 FAIL`，5 份 G2b 日志全 `RESULT=ALL_MATCH`。**

### 4.4 V150-C 关键断言（原文抽样）

```
[V150-C] W02 commit(reason) 原子写 delta.json 成功（.tmp→flush→rename，先落盘） PASS=true
[V150-C] W08 全部 13 个 flag key 三段式正则 PASS=true | keys=13 bad=[]
[V150-C] W12 ★ 进度序列 [0,1,2,3,4,5] 严格单调递增（拒绝事件不推进度） PASS=true | seq=[0, 1, 2, 3, 4, 5]
[V150-C] W15 ★ 拒绝事件不写盘：commit_count==5（5 次成功事件，2 次拒绝不产生 commit） PASS=true
[V150-C] B00 13 项关键 flag 三方全一致 PASS=true | keys=13
[V150-C] C01 ★ 磁盘 grace.trial.points 保持 500（R38 全链不回退 points） PASS=true | points=500
[V150-C] C04 ★ 磁盘 removals 恒空（R38 绝不写 removals） PASS=true | removals=[]
[V150-C] C05 ★ 11 个 R38 flag 全为 world.map.* / world.region_* / grace.site_* 前缀，无一等于 points/spent PASS=true
[V150-C] L04 新进程内存读回逐项 == 磁盘（重启读回一致） PASS=true | flags=13 项，逐项 get_flag 比对
[V150-C] E11 11 项缺 key 全回落基线（不创建 key） PASS=true | keys=11
[V150-C] H02 生产 slot_01 md5 前后一致（未碰生产存档） PASS=true
```

### 4.5 V150-WP 真实可达回归关键断言（原文抽样）

```
[V150-WP] B00 ★ A48③：运行时树零 presentation.gd 脚本节点 PASS=true | found=false
[V150-WP] P05 A54：两次 getter 返回同一实例（绝不自建第二个） PASS=true | same=true
[V150-WP] B02 ★ A48① 生产订阅者存在性（运行时）：4 信号 connection_list 均含编排层回调 PASS=true
[V150-WP] R01 ★ 区域发现成功（生产真实方法 discover_region(limgrave) → ok=true） PASS=true | reason=ok
[V150-WP] R02 ★ 区域发现 → 落盘：磁盘 world.region_limgrave.discovered == true PASS=true | =true
[V150-WP] R03 ★ 落盘 world.map.progress == 1 / world.map.fog_revealed == 1（迷雾揭开） PASS=true | progress=1 fog=1
[V150-WP] R04 ★ 赐福激活成功（生产真实方法 light_site(limgrave_gatefront) → ok=true） PASS=true | reason=ok
[V150-WP] R05 ★ 赐福激活 → 落盘：磁盘 grace.site_limgrave_gatefront.lit == true PASS=true | =true
[V150-WP] R07 ★ 快旅成功（生产真实方法 fast_travel(limgrave_gatefront) → ok=true） PASS=true | reason=ok
[V150-WP] R08 ★ 快旅 → 落盘：磁盘 world.map.last_fast_travel == limgrave_gatefront PASS=true
[V150-WP] R10 ★ 进度序列 [0,1,2,3] 严格单调递增 PASS=true | seq=[0, 1, 2, 3]
[V150-WP] X02 ★ 重启读回一致：新 WorldState 逐项 get_flag == 磁盘 PASS=true | flags=5 项逐项比对
[V150-WP] D01 ★ 重复激活被拒（already_lit，生产 WorldMapService 幂等门控） PASS=true | ok=false reason=already_lit
[V150-WP] D02 ★★ 重复激活被拒不写盘：progress / lit / commit_count 全不变、reject_observed +1 PASS=true | progress 3→3 commit 3→3 reject 0→1
[V150-WP] D03 ★ 未解锁快旅被拒（not_lit，目标赐福未点亮） PASS=true | ok=false reason=not_lit
[V150-WP] D05 ★ 异常输入拒绝 4 类（null / int / Vector2 / 未注册 id） PASS=true | reasons=invalid_input / invalid_input / invalid_input / unknown_region
[V150-WP] T02 SaveDelta 十字段齐全、无额外顶层字段（冻结） PASS=true | extra=[] missing=[]
[V150-WP] T03 schema_version=3、removals 恒空 PASS=true | schema=3.0 removals=[]
[V150-WP] T07 ★ A76 分区 id 对齐：4 个 region_ids 逐字来自 m6_area_bindings.tres PASS=true
[V150-WP] T08 ★ 赐福点与分区对齐结论：4 个赐福点各归属 1 个已注册分区 PASS=true
[V150-WP] T09 生产 slot_01 md5 前后一致（全程不写 slot_01） PASS=true
```

### 4.6 G3 主场景实证（原文）

```
[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=54（R20 登记 25，如实回读不冒充）
[R36][PCO] A66 生产订阅者已绑定 FocusService 唯一实例 | signals=3 slot=user://saves/slot_01
[R37][PCO] A70/A71 生产订阅者已绑定 FlaskService + DeathService 唯一实例 | signals=7 slot=user://saves/slot_01
[R38][PCO] A48①/A76 生产订阅者已绑定 WorldMapService 唯一实例 | signals=4 slot=user://saves/slot_01（赐福网络 / 大地图进度落盘）
```
`node_count=54` = A74 新基线；R34~R38 全部既有 / 新生产订阅者并存 = **A77 既有闭环不废**；无输入触发服务方法 → **不写盘**。

---

## 5. 赐福点与分区对齐结论（交付要求专节）

| 分区 id（`region_ids`） | 真源 | 赐福点 `site_id` | `position`（逻辑像素） | 三段式 flag |
|---|---|---|---|---|
| `limgrave` | `m6_area_bindings.tres` `area_limgrave.region` | `limgrave_gatefront` | `(512, 384)` | `world.region_limgrave.discovered` / `grace.site_limgrave_gatefront.lit` |
| `weeping_peninsula` | `area_weeping_peninsula.region` | `weeping_shore` | `(1536, 384)` | `world.region_weeping_peninsula.discovered` / `grace.site_weeping_shore.lit` |
| `stormveil` | `area_stormveil_outskirts.region` | `stormveil_gate` | `(2048, 768)` | `world.region_stormveil.discovered` / `grace.site_stormveil_gate.lit` |
| `siofra_well` | `underground_01_siofra_well.region` | `siofra_well` | `(3072, 896)` | `world.region_siofra_well.discovered` / `grace.site_siofra_well.lit` |

**结论（机器判定，非纸面推断）**：
- 4 个 `region_ids` 逐字取自既有 `godot/data/rpg/m6_area_bindings.tres` 的 `region` 字段（4 个 `is_dungeon=false` 地表/野外区域），与 **Rank-1 大地图 4096×2304 分区口径**、**Rank-2 `world_encounters.tres` 的 `region_ids`** 三方同一真源，不臆造（`V150-WP T07 PASS=true` / `S09` / `P07` 表回读 4 区）。
- 4 个赐福点各归属 1 个已注册分区、**4 区一一覆盖**（`V150-WP T08 PASS=true`：`site→region={limgrave_gatefront:limgrave, weeping_shore:weeping_peninsula, stormveil_gate:stormveil, siofra_well:siofra_well}`）；`site_id` 去掉既有 `m6_area_bindings.tres` `grace_ids` 的 `grace_` 前缀（如 `grace_limgrave_gatefront → limgrave_gatefront`），使三段式 flag 对象段简洁、与规范 §3.1 示例 `grace.limgrave_gatefront.lit` 同风格，对应关系逐字可查。
- `position` 落在 Rank-1 `4096×2304` 逻辑像素大地图内、与 Rank-2 遭遇点同位量纲，4 点沿 X 由西到东分散（`[PLACEHOLDER]`，调参唯一入口 `grace_sites.tres`，只改表不改代码）。
- **★ 仍标 `[PLACEHOLDER]`**：A76 最终口径由 Rank-1 `world_scale.tres` 与本表落定；若总指挥调整分区命名，**只改 `grace_sites.tres` 的 `region_ids` / 各行 `region_id` 两处即可对齐，不改代码、不改服务、不改编排层**（数据驱动）。
- ★ 任务单示意 `world.map.region_<id>.discovered` 为四段、与冻结三段式正则冲突，R38 收敛为 `world.region_<id>.discovered`，`<id>` 逐字保留、语义不变、机器正则全 PASS（见 §2.2 / 契约 §3.3 R38 段）。

---

## 6. 验收三态

| 态 | 内容 |
|---|---|
| **通过** | ① 赐福网络数据 + 纯逻辑服务全真跑完成（4 区 4 点 `[PLACEHOLDER]` + rationale / 4 信号 / 激活 · 快旅 · 区域发现 · 迷雾 · 进度 / 重复激活 · 未解锁快旅 · 异常输入拒绝 / 进度单调递增）；② 编排层 R38 段落地：4 信号生产订阅者 + 11 个三段式 flag + `_commit_world_map` 隔离 + 惰性初始化 / 安全降级 + 显式绑定入口 + `get_status` 观测；③ 两份新验证脚本（85 + 53 PASS）+ 三进程三态（105 PASS），合计 **243 PASS / 0 FAIL**、全 `RESULT=ALL_MATCH`；④ 三段门禁 11 份日志全 `EXIT=0`、`SCRIPT ERROR=0` / `PARSE_ERROR=0` / 其它 `ERROR=0`；⑤ **不回退 `grace.trial.points` / 不写 `removals` / 不二次入账** 机器判定 + 反例被拒；⑥ 「区域发现 → 赐福激活 → 快旅 → 重启读回一致 → 重复激活被拒」全链读磁盘断言；⑦ 拒绝事件不写盘实证；⑧ 契约 §3.3 只追加 R38 段（A74~A78）、规范 §3.3 补 11 行、迭代文档 + README §九；⑨ 赐福点与分区对齐结论机器判定（4 区一一覆盖）；⑩ G3 `node_count=54`（A74 新基线）/ `signals=4` 自动装配 / 既有闭环并存（A77）/ 生产 `slot_01` 零改动；⑪ 回执写入并确认中枢归档（§10）。 |
| **失败 / 未达** | ① **A74 后既有 5 份回归 8 条 A38 旧基线断言 FAIL**（41 / 2-1-1 静态期望值过期、非本轮功能回归）—— 属 Rank-1 并行断言同步工作（用户口径称 A79 授权；Rank-1 `DONE-R38.md` §10 待裁决 #1），**不在本轮 Rank-3 授权写入清单，按硬约束未越权同步**；本轮真实可达回归不实例化 `courtyard.tscn`、不含节点数断言，故未遇到该 FAIL；G3 回读已是 `node_count=54`，如实登记。② **定稿录屏 / 目视帧**：headless 无帧缓冲，本轮不含新 MP4 / 抽帧 / 目视结论；大地图空旷无目标 / 角色 40% 可读性 / 相机跟随晕眩 / 视差层错位待总指挥目视。③ **跨 Rank 运行时接线**：Rank-1 输入层玩家坐标 / 分区切换与 Rank-2 野外遭遇触发点归属未由 Rank-3 落地（授权边界），本轮只提供稳定签名 + 生产订阅者。④ **HD-2D 全绿未达**（沿用 A41/A52/A61/A68/A73，A78）：仍 2D `_draw()` / screen-reading shader 近似、无真 DoF / 真体积光 / SSR / Forward+。 |
| **需用户确认 / 待裁决** | 见 §9（共 7 项）。 |

---

## 7. A48 四项逐条自查（硬要求）

| # | 条款 | 结论 | 实证 |
|---|---|---|---|
| ① | 新信号必须有**生产运行时订阅者** | **达标**。`WorldMapService` 4 个新信号的生产订阅者 = `PointsCommitOrchestrator` autoload 的 `bind_world_map_service()`（connect 在**生产脚本内**，非验证脚本）；回调有真实职责（发现 / 点亮 / 快旅 flag 落盘 + 拒绝观测），非空订阅 | G2b / G3 日志 `[R38][PCO] … signals=4`；`B02` 4 信号 connection_list 4/4；`S03` 静态证据 |
| ② | 遵守 A54 唯一实例 | **达标**。唯一实例 = `grace_sites.tres` 加载所得 `WorldMapService` Resource，编排层 `_ensure_world_map_service()` 只加载一次并持有，`get_world_map_service()` 复用、`bind_world_map_service()` 显式拒绝替换、`_world_map_bind_done` 使退出 deferred 不重复 load | `P05` 两次 getter 同一实例 / `S04` 静态证据 / 绑定日志各进程只 1 次 |
| ③ | 不加载 `presentation.gd`、不在验证脚本内模拟编排的**真实可达回归** | **达标**。`verify_world_production_v150.gd` B00 运行时树零 presentation 节点；编排（订阅 / 计算 / 十字段 commit / 先落盘后改实例）全在生产 `points_commit_orchestrator.gd`，验证脚本只调生产真实服务方法 + 读磁盘断言，一行未写落盘逻辑；独立 PID 临时槽 | B00 / R01~R13 / X02 / X03 / D01~D08 / T01~T09 全 PASS |
| ④ | 纯逻辑 + 单元断言不算可玩交付 | **达标（如实登记未完成）**。交付含真实生产服务 / 生产编排层 autoload / 读磁盘断言链 / G3 主场景实证；但 **未做 15~20 秒实机录屏回看**，如实列为未完成 / 需用户确认，不冒充可玩交付 | §6 失败项 ② / §9 待裁决 ③ |

**SceneTree / `--script` 纪律**：两份 verify 用 `Engine.get_main_loop() as SceneTree` 取 root（不用 `get_tree()` / 不用 `/root/...` 绝对路径）、`add_child` 后显式 `call("_ready")`、资源 `CACHE_MODE_IGNORE`；编排层 autoload 在无 HUD 的纯工具模式惰性初始化 / 安全降级、不报错不写盘；三进程三态 / 生产验证独立 PID 临时槽、不碰生产 `slot_01`。

---

## 8. 硬约束遵守声明

- **唯一写入方**：只写 ①~⑫（授权清单内）。**未改** `project.godot` / `courtyard.tscn` / `hud.gd` / `presentation.gd` / `world_scale.tres`（Rank-1）/ `wave_trial_director.gd` / `world_encounters.tres`（Rank-2）/ Rank-4 产出 / 全部既有 `.tres` 数值 / 素材 / 既有 5 份 `verify_*` 回归脚本 / 契约其它历史条款 / 其它 Rank 产出。
- **大改特别条款**：① 既有可玩闭环全保留（A77，G3 R34~R38 订阅者并存 + 编排层既有逻辑逐字未改）；② 不切渲染后端（`gl_compatibility`）、不引入真 3D 网格；③ 美术规格不变（128px / ≤16 色 / ≥256 色 / RGBA / 硬边无噪点，本轮未动任何素材与色库）；④ 人物缩放与地图尺寸数据驱动（Rank-1 `world_scale.tres` / Rank-3 `grace_sites.tres`，脚本无 1.6 / 0.64 / 4096 / 2304 / 分区名字面量）；⑤ A74 后节点数与 uv 变化由 Rank-1 同步断言，Rank-3 不越权、如实登记。
- **零付费 / 零外部依赖 / 不启 GPU job**：仅本地 Godot 4.7.2；未 `--write-movie` 录屏 / 未调 ffmpeg / 未列任何付费项；backlog 全为零付费零外部依赖增量。
- **默认不刺探**：未主动扫目录做进度巡检、未新建只读探针 / 巡检脚本；读取均针对任务单指定契约 / 目标文件 / 上游 DONE / 门禁日志 / 回执归档确认所必需路径，用真跑输出判断。
- **不伪造产物、不谎报成功**：11 份日志非空；四段示意 → 三段式收敛口径、A74 旧基线断言并行同步、headless 无录屏 / 无目视帧、HD-2D 未全绿均如实登记、未隐瞒、未擅自改清单外文件。
- **不自行 git**（总指挥收尾）；**未删除 `.workbuddy` 目录**。

---

## 9. 未完成项 / 待总指挥裁决项（如实登记，不擅改）

1. **`[PLACEHOLDER]` 数值校准**：`grace_sites.tres` 4 赐福点 `position` / `unlock_condition` / `display_name`、Rank-1 `world_scale.tres` 全部数值待人工试玩校准；调参唯一入口 = 各自数据表（只改表不改代码），同步两份 verify 的 `EXPECT_*` / 本文数值表 / 三段门禁。
2. **跨 Rank 运行时接线**：Rank-1 输入层「玩家坐标 / 分区切换 → 调 `WorldMapService.discover_region` / `light_site` / `fast_travel`」键位与 Rank-2 野外遭遇触发点归属请总指挥统一裁决；本轮 Rank-3 只提供稳定签名（§3）+ 生产订阅者，接线前服务不主动触发（安全降级，既有闭环逐字等价）。
3. **A74 旧基线断言同步授权冲突**：既有 5 份回归 8 条 A38 旧基线（41 / 2-1-1）过期 FAIL 属 Rank-1 并行断言同步（用户口径 A79 / Rank-1 `DONE-R38.md` §10 待裁决 #1），Rank-3 不越权改别人的脚本；请总指挥裁决归属与收口。
4. **四段示意 → 三段式收敛口径复核**：任务单示意 `world.map.region_<id>.discovered` 为四段、与冻结三段式正则冲突，本轮严格按正则收敛为 `world.region_<id>.discovered`、未放宽判定；若需保留四段字面或改 `world.map.region_discovered_<id>`，请裁决后只改表与编排层 key 生成 + 补回归。
5. **15~20 秒定稿录屏目视**（A42 / A67 / A72 / A78）：大地图空旷无目标 / 角色 40% 可读性 / 相机跟随晕眩 / 视差层错位 / 赐福点 HUD / HD-2D 全绿由总指挥亲自回看首 / 中 / 尾三帧；headless 无帧缓冲，代码断言不算画面验收，Rank-3 不代做手感 / 审美判断。
6. **`focus_rejected` 落盘策略统一**（R37 遗留冲突）/ 死亡与重生演示覆盖 / 连击 D→A·S 级演示覆盖 / 既有 WARNING 清理。
7. **沿用前序未完成项**：A38 §3.3 契约同步 / HD-2D 全绿路线 / `128bit` 歧义（A53 保留）/ 真机 exe·apk 手感与移动端触控 / GitHub 补推 / A43 目视口径（同 DONE-R37 §8）。

---

## 10. 回执与中枢归档确认（写后实测，如实登记）

- 回执写入授权路径（**`teamwork/command_center/`**，非工程根）：`teamwork/command_center/ai/3/outbox/cmd-20261112-234238-656-A3.json`，四字段 `{"task_id":"…","ai":3,"status":"done","result":"…引用 DONE-R38.md 实际结论…"}`。
### 归档确认（写后回读实测原文，如实登记、不伪造）

```
=== outbox 回执 VALID_JSON 校验 ===
exists=False                （回执已被中枢轮询移走 → dispatcher/receipts/）
outbox_count=0               （ai/3/outbox/ 已清空）
=== 归档副本 ===
receipt_exists=True
receipt VALID_JSON keys=['ai', 'result', 'status', 'task_id'] bytes=3049
=== status.json ===
{"ai": 3, "state": "idle", "current_task": "", "completed": 43, "last_seen": "2026-11-13 08:06:12"}
=== dispatcher.log 尾部 ===
[2026-11-13 08:06:12] ← 3 号 AI 回执 <cmd-20261112-234238-656-A3> 完成：R38 / v0.15.0「大地图 · 2.5D 尺度重构」Rank-3 五块任务全部真跑完成：① 新写 grace_s…
=== ledger 本任务行 ===
VALID_JSON id=cmd-20261112-234238-656-A3 command=cmd-20261112-234238-656 ai=3 status=done finished_at=2026-11-13 08:06:12 result_len=1706
RESULT_MATCH=True    receipt_result_len=1706  ledger_result_len=1706
issued_at=2026-11-12 23:42:39  finished_at=2026-11-13 08:06:12
```

- 回执写入 `teamwork/command_center/ai/3/outbox/cmd-20261112-234238-656-A3.json`（**`teamwork/command_center/`**，非工程根）后经中枢轮询**已归档**：`outbox_count=0`（回执移入 `dispatcher/receipts/`）；归档副本 `dispatcher/receipts/cmd-20261112-234238-656-A3.json` 回读 **VALID_JSON**、四字段齐全（`keys=['ai','result','status','task_id']`）、`task_id=cmd-20261112-234238-656-A3` / `ai=3` / `status=done` / `result_len=1706`；`ai/3/status.json` 更新为 `state=idle` / `current_task=""` / `completed=43`；`dispatcher.log` 尾部回收行确认 id 与派单一致；`ledger.jsonl` 本任务行 `status=done`、`RESULT_MATCH=True`（与回执 result 逐字一致）。**确认中枢归档完成**，不重放、不伪造。

### 补：A74 旧基线断言同步并行实证（如实登记）

`dispatcher.log` 另有 `[2026-11-13 07:59:33] ← 1 号 AI 回执 <cmd-20261113-002853-270-A1> 完成：R38B 完成：按 teamwork/Rank-1/DONE-R38.md §10 清单把 5 份回归脚本的 8 条 A…` —— 印证 **A74 后 A38 旧基线（41 / 2-1-1）断言同步确由 Rank-1 并行处理**（与用户口径 A79 授权一致），Rank-3 本轮按硬约束未越权改别人的脚本、如实登记为 §9 待裁决 #3。
