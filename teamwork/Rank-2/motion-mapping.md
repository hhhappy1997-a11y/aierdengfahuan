# motion-mapping.md —— Godogen `rootmotion.json` → 本作翻滚 / 攻击判定帧时序映射（R3）

> 2 号工位 · 战斗系统与数据驱动 · R3 交付件（任务书-R3.md §2）。
> 中文 UTF-8。唯一写入 `Rank-2\`。引擎 Godot 4.7.2 标准版 / GDScript。
> 关联：`数据表schema.md` §0.3 / §3 / §7（帧口径）、`player_actions.tres`（8 状态实例）、`boss_01_margit.tres`（Boss 招式实例）、`战斗系统设计.md` §1.1。

---

## 0. 结论速览与诚实声明

- 本文件把本机 Godogen motion 的 `rootmotion.json` 字段（`pelvisXZ` / `footContact` / `loop` / `numFrames` / `fps` / `hipY`，另含 `frameData` / `scaleRoot`）映射到本作**翻滚起手 / 无敌 / 恢复**与**攻击前摇 / 判定 / 后摇**三段帧，并给出 **fps→logic_fps 换算**、**loop clip 末帧重复首帧 + Godot `loop_mode = LINEAR`**、**脚步声落在 `footContact` 由 0 变 1 的帧**三条硬结论。
- **如实声明（不伪造输出）**：本机 `D:\godogen_assets\motion\` 下**没有预置的 `rootmotion.json` 实例**。该文件是 `add-moves` 命令的**运行时产物** `<name>_rootmotion.json`（见 `motion/README.md:12,25`、`add_moves.py:470-471,489`）；目录内现有的是 `basic.json`（`idle/walk/run/jump` 的规格）、`README.md` 与生成脚本。本轮**未实跑** `gen-moves` / `add-moves` 生成本作翻滚 / 攻击 clip（需 `mia-rig` rig + 权重，且任务书 §4 明确 `gen3d` / `mia-rig` 本机不可用、不补装、不碰 WSL）。
- 因此本映射的**字段语义与帧规则**取自两处权威只读定义：`D:\godogen_assets\motion\README.md:25-32`（字段含义、loop 规则、脚步声规则）与 `add_moves.py:457-465`（`rootmotion['clips'][name]` 实际写入的字段名 / 类型 / 单位）。**不编造任何 clip 的具体帧数据 / 数值实例**；本作用到的帧号全部来自本工位 3 份 `.tres` 的真实值。
- 本映射只作**姿态 / 帧时序参考**，**不引入任何 3D 模型资产**（任务书 §4、用户指令）；rootmotion 的米制位移不改写 `.tres` 里的 px 战斗数值。

---

## 1. `rootmotion.json` 字段契约（权威定义，只读）

来源：`motion/README.md:25-32` 字段语义 + `add_moves.py:457-465` 实际写入结构。
顶层：`{"scaleRoot": <float>, "clips": {<move_name>: {...}}}`；每个 clip 含下表字段。

| 字段 | 类型 / 结构 | 单位 / 取值 | 语义（README 原文要点） | 本作用途 |
|---|---|---|---|---|
| `fps` | int | 帧率，如 `basic.json` 实测 `30` | clip 采样帧率；`n_frames / fps` 为时长基准 | 换算到本作 `logic_fps` |
| `numFrames` | int | 帧数 | 该 clip 总帧数；**loop clip 末帧 = 首帧** | 一周期 `(numFrames-1)/fps` |
| `loop` | bool | `true` = 闭合循环 | `idle/walk/run` 为 `true`；`jump/attack/roll` 为 `false` | 决定 Godot `loop_mode` |
| `pelvisXZ` | `Array<[x, z]>` 长度 `numFrames` | **米**；角色帧 `+z` 前 / `+x` 左 | 髋部相对首帧的水平偏移；**游戏据此移动实体**，不是动画内位移 | 翻滚冲刺 / 攻击前冲的「每帧位移量」参考 |
| `hipY` | `Array<float>` 长度 `numFrames` | 米 | 髋部高度序列 | 翻滚身位压低 / 跳跃顶点参考 |
| `footContact` | `Array<[left, right]>` 长度 `numFrames` | `0/1` | 每帧左右脚是否着地；`1` = 该脚 planted | **脚步声触发帧 / foot IK 锁定期** |
| `frameData` | 对象（扩展） | — | `strikes.measure` 测得的打击 / 循环指标（README:44-45 的 impact timing） | 攻击判定帧的客观参考（本作未强制使用） |
| `scaleRoot` | float（顶层 + 每 clip） | 米/单位 | 骨架缩放 | 由 1 号表现层换算，2 号不读 |

> 单位桥接：rootmotion 是**米**；本作距离 / 半径一律 **px（2.5D 世界投影像素）**（`数据表schema.md` §0.3），由 1 号像素→米缩放系数解耦。2 号只取字段的**帧时序 / 相对形状**，不把米值写进 `.tres` 战斗数值。

---

## 2. 本作帧基准（`数据表schema.md` 侧，真源）

| 量 | 值 / 口径 | 来源 |
|---|---|---|
| 逻辑帧 | 固定物理步长 `@ logic_fps` | `数据表schema.md` §0.3 / §7 `logic_fps` |
| `logic_fps` | **`60`**（8 条状态全等，E-6；须等于 `Engine.physics_ticks_per_second`） | `player_actions.tres` 8 条实测全 `60` |
| 帧区间 | **一律左闭右开 `[start, end)`** | `数据表schema.md` §0.3 |
| 招式三段 | `startup_frames`（前摇/起手，无判定）→ `active_frames`（**判定帧**，`[startup, startup+active)`）→ `recovery_frames`（后摇，无判定） | `数据表schema.md` §3 / E-2 |
| 翻滚三段 | `startup`（起手）→ `active`（**无敌段**）→ `recovery`（恢复）；无敌区间 `[invulnerable_start_frame, invulnerable_end_frame)` | `数据表schema.md` §7 / E-7 |
| `total_frames` | **不设字段**，由 `startup + active + recovery` 派生 | `数据表schema.md` §3 / E-2 |

---

## 3. 字段 → 帧时序映射（核心）

### 3.1 `fps` / `numFrames` → 本作 `logic_fps`（必须先换算）

rootmotion clip 的 `fps` 与本作 `logic_fps = 60` 通常不等（`basic.json` 实测 `fps = 30`）。映射公式：

```
k = logic_fps / clip.fps                 # 60 / 30 = 2（本例）
f_game   = round(f_motion * k)           # motion 帧 → 本作逻辑帧
duration = (numFrames - 1) / clip.fps    # loop clip 一周期秒数（末帧重复首帧，故 -1）
```

- **判定 / 无敌帧一律以本作 `.tres` 的 `startup_frames / active_frames` 为准**（表驱动，改数值不改代码），rootmotion 帧只用来**对齐动作姿态落在哪一段**，不反向覆盖表内帧号。
- 若 clip 由 `gen-moves` 产出且 `fps` 非 30，仍按上式用 clip 自身 `fps` 换算，不硬编码 30。

### 3.2 `pelvisXZ` → 翻滚冲刺 / 攻击前冲的位移时序

- `pelvisXZ[f] = [x, z]` 是第 `f` 帧髋部相对首帧的水平偏移（米）。逐帧差分 `ΔpelvisXZ[f] = pelvisXZ[f] - pelvisXZ[f-1]` 给出该帧的位移量。
- 翻滚：本作 `move_speed_px_per_sec = 260.0`（`player_actions.tres` 的 `action_04_roll`）在 `active` 无敌段内产生冲刺位移；`pelvisXZ` 的**形状**（起手蓄势 → 无敌段前冲 → 恢复段收势）用来对齐「哪几帧真正在移动」，避免整段匀速滑步。
- 攻击：Boss / 敌人招式的前冲（如 `move_03_holy_hammer` 大前摇）可借 `pelvisXZ` 判断前摇末段是否前踏，使判定帧 `[startup, startup+active)` 与武器到达位置一致。
- **约束**：米→px 换算与实体位移由 1 号表现层完成；2 号**只**据此确定帧时序，不改 `.tres` 的 `move_speed_px_per_sec` / `hitbox_reach_px`（I-4 只调 `set_pose()`）。

### 3.3 `hipY` → 身位高低（翻滚压低 / 跳跃顶点）

- `hipY[f]` 为髋部高度序列。翻滚 `active` 无敌段对应 `hipY` 的**低谷**（身体压低）；`basic.json` 的 `jump` 用 `apex: {"kind": "root_rise"}` 抬升，对应 `hipY` 峰值。
- 本作用其**相对形状**决定翻滚 / 受击姿态的锁帧选择（`pose_frame_offset` / `set_pose(pose_name, frame_index)`），不把 `hipY` 数值写入逻辑。

### 3.4 `footContact` 0→1 → 脚步声帧（任务书硬结论）

- `footContact[f] = [left, right]`，`1` 表示该脚着地（planted）。
- **脚步声落在 `footContact` 由 `0` 变 `1` 的帧**：对每只脚独立检测 `footContact[f][side] == 1 且 footContact[f-1][side] == 0`，该 `f`（经 3.1 换算到 `f_game`）即一次落脚事件，触发脚步声；`foot IK` 在该值保持 `1` 的连续区间内锁定脚部。
- 对应本作：`walk` / `run` 为 `loop=true` 循环状态，落脚事件随每个循环周期重复；`roll` / `attack_*` 为 `loop=false`，只在动作内触发。
- 2 号只给出**落脚逻辑帧号**；音频触发属表现层（1 号 / 本地合成音效），2 号不写音频、不引付费音源（工具链 §6）。

### 3.5 `loop` → Godot `loop_mode = LINEAR` + 末帧重复首帧（任务书硬结论）

- `loop = true` 的 clip 是**闭合循环**：`add_moves.py:61` 明确 `a loop's last frame is its first`，即 `numFrames` 帧里**末帧重复首帧**。
- 因此一周期有效帧数为 `numFrames - 1`，时长 `(numFrames - 1) / fps` 秒；`pelvisXZ[-1]` 是一周期累计位移，wrap 时实体路径从该点继续（README:30-32）。
- **Godot 侧**：clip 按导入长度 / 轨道使用，`loop_mode = LINEAR`（`Animation.loop_mode = Animation.LOOP_LINEAR` 或导入器等价设置），不要手动删末帧、不要改成 ping-pong；`length` 与 tracks 按导入值保留。
- `loop = false` 的 clip（翻滚 / 攻击 / 跳跃）为 one-shot，播完停在末帧并交回状态机；不设循环。

### 3.6 `frameData` → 攻击判定帧的客观参考（扩展，非强制）

- `add_moves.py:443,456,460` 把 `strikes.measure(...)` / `blade_strike(...)` 的 `frameData` 写进 clip（README:44-45 称 impact timing）。
- 可作为「武器到达峰值」的客观帧，用来**校验** `.tres` 里 `active_frames` 判定区间是否落在真实挥击速度峰附近；若不一致，改 `.tres` 的 `startup/active/recovery` 数值，不改代码（表驱动）。本轮未实跑 clip，此字段仅登记为可用参考。

---

## 4. 翻滚 / 攻击三段帧对照表（帧号全部取自本工位 `.tres` 真实值，`logic_fps=60`）

### 4.1 玩家（`player_actions.tres`）

| 动作 | 表内字段 `startup/active/recovery` | 三段区间（逻辑帧，左闭右开） | 判定 / 无敌 | 位移 / 备注 |
|---|---|---|---|---|
| `action_04_roll` | `4 / 12 / 12` | 起手 `[0,4)` · **无敌 `[4,16)`** · 恢复 `[16,28)` | `[invulnerable_start_frame=4, end=16)` 与 `[startup, startup+active)` 完全对齐（E-7 ✓） | `move_speed_px_per_sec=260.0`；`pelvisXZ` 前冲须落在无敌段 |
| `action_05_attack_light` | `8 / 5 / 14` | 前摇 `[0,8)` · **判定 `[8,13)`** · 后摇 `[13,27)` | `cancel_window_frames=6` | `motion_multiplier=1.0`，`hitbox_reach_px=62.0` |
| `action_06_attack_heavy` | `20 / 8 / 26` | 前摇 `[0,20)` · **判定 `[20,28)`** · 后摇 `[28,54)` | `cancel_window_frames=8` | `motion_multiplier=1.65`，`hitbox_reach_px=78.0` |
| `idle/walk/run` | `0/1/0`（循环） | `loop=true` 闭合周期 | — | `footContact 0→1` 落脚事件按周期重复 |
| `hitstun/death` | `0/12/6`、`0/48/0` | one-shot | — | — |

### 4.2 Boss 招式（`boss_01_margit.tres`，供 `frameData` 校验参考）

| 招式 | `startup/active/recovery` | 判定区间 `[startup, startup+active)` | 备注 |
|---|---|---|---|
| `move_01_dagger_slash` | `18 / 5 / 24` | `[18,23)` | `damage_type=physical` |
| `move_02_staff_slam` | `30 / 7 / 34` | `[30,37)` | `motion_multiplier=1.55` |
| `move_03_holy_hammer` | `42 / 9 / 40` | `[42,51)` | `damage_type=holy`，`status_buildup_frost=35.0`，`breaks_guard=true` |

### 4.3 敌人招式（`enemy_01_limgrave_soldier.tres`）

| 招式 | `startup/active/recovery` | 判定区间 |
|---|---|---|
| `move_01_soldier_slash` | `12 / 4 / 18` | `[12,16)` |

> 换算示例（若对应 clip `fps=30`）：roll 无敌段 `[4,16)` 游戏帧 ← motion 帧 `[2,8)`；light attack 判定 `[8,13)` ← `[4,6.5)`→取整 `[4,7)`；仅为对齐示意，**最终以 `.tres` 游戏帧为准**，motion 帧不回写表。

---

## 5. 与硬约束的关系

- **零付费 / 零外部依赖**：只引用本机 `D:\godogen_assets\motion\` 的只读文本定义；不调用付费 API、不实跑 GPU job、不引入 3D 模型 / GLB 资产（任务书 §4、工具链 §6）。
- **I-4 只调 `set_pose()`**：本映射产出的「帧号 / 落脚帧 / 姿态段」交给表现层；2 号不写 billboard、锚定、缩放、`SpriteFrames`，pose 名按 R2 口径冻结表加 `p1_` / `p2_` 前缀。
- **改数值不改代码**：所有三段帧号来自 `.tres`；调整手感只改 `.tres` 的 `startup/active/recovery/invulnerable_*` 字段，rootmotion 映射规则（本文件）与 GDScript 不改。
- **默认不刺探**：开工只读一次总线；motion 目录的读取是任务书 §2 指定的映射输入，非进度巡检、非扫别人工位。

---

## 6. 未完成项与阻塞（如实登记，见 `DONE-R3.md` §4）

1. **本机无预置 `rootmotion.json` 实例**：文件是 `add-moves` 运行时产物，目录内只有 `basic.json` 与生成脚本；本轮**未实跑** `gen-moves` / `add-moves` 生成本作翻滚 / 攻击 clip（前置 `mia-rig` rig / 权重本机不可用，任务书 §4 禁止补装、不碰 WSL）。本文件为**字段契约映射**，不含任何真实 clip 帧数据，不冒充已对齐产物。
2. **`frameData` / `scaleRoot` 未实测**：仅登记为扩展参考字段，未用真实 clip 数值校验判定区间。
3. **`basic.json` 的 `jump` 含 `apex` / `stance_bookend`**：本作 8 状态无 jump，未纳入帧映射；若 M2 引入跳跃需补 `hipY` 顶点映射。
4. **米→px 换算系数**：归 1 号表现层，待裁决（跨模块 Q 项），2 号不定义。
