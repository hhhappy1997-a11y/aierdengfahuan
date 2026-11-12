# DONE-R31B · 遗留补齐结论（由 R32 合并执行）

- 补回执 id：`cmd-20261111-141611-495-A1`
- 背景：上一轮四条 R31B 派单因执行进程通道故障未接单，本轮 R32 派单（A39 裁决授权）由 Rank-1 合并补齐并另写一份回执。
- 归属：Rank-1；`godot/scripts/combat/encounter_director.gd` 本轮唯一写入方（A44）。

## 补齐内容（3 处，均为「按实接入、最小改动」）

1. **`godot/scripts/combat/encounter_director.gd`**
   - `signal player_hit_landed(damage: int)` 声明在 R31B 已部分写入，本轮核对其确实存在；
   - **只在 `_try_player_hit()` 玩家成功命中处补 1 行** `player_hit_landed.emit(int(damage))`；
   - 未改既有数值 / 判定分支 / 帧数据 / 输出格式 / 其它两个信号（`encounter_finished` / `grace_rested`）/ BossController `move_landed` 订阅链。

2. **`godot/scripts/render/impact_feedback.gd`**
   - 补 `SIG_PLAYER_HIT_LANDED` 常量；
   - `bind_director()` 按实订阅该信号（connect 前 `get_signal_connection_list()` 按方法名去重）；
   - `_exit_tree` 释放列表纳入该信号；
   - 命中时经统一回调 `_on_combat_signal()` 自动 `request_impact()` → 暖金闪光 / 微震 / hitstop 在真实游玩中触发，不再只靠集成层手动调用；`request_impact()` 公共入口保留。

3. **`godot/scripts/render/verify_impact_feedback_v090.gd`**
   - **保留既有 35 条断言不删不放宽**；
   - 新增 L 组 7 条：`真实导演层 emit 后闪光 > 0` / `连续命中不叠加异常` / `降级仍闪光` / `HUD 避让区像素 0` / `connect 去重不重复触发` / `真实信号名按实回读` / `订阅连接数`；
   - 新增 `RealHitDirector` 替身（只声明真实存在的 `player_hit_landed(damage:int)` 信号）模拟真实导演层 emit，不加载 / 不修改任何既有战斗件。

## 真跑结论

```
[V090] L1 真实导演层声明 player_hit_landed(damage:int) 且 _try_player_hit 内 emit PASS=true
[V090] L4 真实导演层 emit 一次命中后闪光 > 0 PASS=true | flash=0.4200 impact=1 shake=6.0 hitstop=2
[V090] L5 连续 5 次命中：flash/shake/hitstop 恒在 [0,上限]、无 NaN、不叠加异常 PASS=true
[V090] L7 降级下真实命中仍闪光>0、shake/hitstop=0、HUD 避让区像素仍 0 PASS=true
[V090] SUMMARY pass=42 fail=0 total=42 ok=true
[V090] RESULT=ALL_MATCH
[V090] SCRIPT_ERROR=0
```

- 三段门禁 GATE1/2/3 EXIT=0；全工程 G3 `SCRIPT ERROR=0`；A38 节点数 41 / uv `2/1/1` 不变。
- 未引入 `cosf()/sinf()`（R31 踩坑），沿用 `cos()/sin()`。

## 未完成项 / 待裁决项

- R31B 遗留补齐本身**无未完成项**。
- 完整交付清单、全部真跑输出原文、验收三态与待总指挥裁决项见 `DONE-R32.md`。
