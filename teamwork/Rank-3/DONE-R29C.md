# DONE-R29C.md · Rank-3 交付（R29C / v0.7.1 裁决 A31 口径统一扩大 + A32 派生色登记）

> 派单 `cmd-20261111-120737-845-A3` · `[ROUND=R29C]` · Rank-3（RPG / 世界 / 存档）· 2026-11-11
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--version` = `4.7.2.stable.official.ed1daf0bf`（G0 `EXIT=0`）
> **结论：派单 ①②③④ 全部真实达成。** A31 两处残留口径差异已统一到 A26 落地口径（逐处改前→改后见 §2）、A32 派生色说明已追加到锚点 v2 §8、README R29C 条目与「还差什么」已更新、**31 PASS / 0 FAIL 存档 / HUD 回归不回退 + 三段门禁 `grep SCRIPT ERROR=0` 达成**；只写自有文档 / 契约 §3.3 / GDD 行 492 / 锚点 v2 / README，**未写任何 `godot/` 工程业务文件**、未自行 git、零付费、零外部依赖、未启 GPU job、未新建只读探针 / 巡检脚本。

---

## 0. 一句话结论

按总指挥裁决 **A31** 把 R29 如实登记、授权边界外保留的两处口径差异（`WAVE-TRIAL-GDD.md` 行 492「Rank-3 订阅写 / Rank-1 不写 flag」、`00-协作契约.md` §3.3 `grace.tutorial.completed` 行「写方 Rank-3」）统一为裁决 A26 落地口径 —— **写方 Rank-1 `tutorial_director.gd`、commit reason `tutorial_step_reward`、教学 HUD 读运行时游标、世界 flag 只作历史进度**；按裁决 **A32** 在 `HD2D-STYLE-ANCHOR-v2.md` 追加 §8「派生色说明」，钉死 shader 色 uniform 真源为 `depth_profile.tres` 锚点色 `#1B2A4A` / `#C99A3A`，登记派生显示色 `#2B3A5C` / `#F0A94C` 的来源公式与 rationale、立下「不得冒充新色板」硬规则。真跑 12 次引擎调用全 `EXIT=0`、31 PASS 不回退、12 份日志 `SCRIPT ERROR=0` / `Parse Error=0` / `ERROR:` 前缀 = 0（G3 仅 1 条既有退出 WARNING，非 ERROR）。

---

## 1. 实际交付清单

| # | 文件 | 动作 | 内容 |
|---|---|---|---|
| 1 | `teamwork/Rank-3/WAVE-TRIAL-GDD.md` 行 492 | **就地改 1 处** | §10.3 inputs 事件输入表「Rank-3 订阅信号写 / Rank-1 不写 flag」→ A26 落地口径（详见 §2.1） |
| 2 | `teamwork/00-协作契约.md` §3.3 | **就地改 1 行 + 追加 1 段** | 登记表 `grace.tutorial.completed` 行写方 Rank-3 → Rank-1（详见 §2.2）；追加 R29C 说明段（逐处改前→改后 + 未动边界） |
| 3 | `F:/Game/aierdengfahuan/HD2D-STYLE-ANCHOR-v2.md` | **追加 §8（1 节 4 子节）** | 「派生色说明」：§8.1 uniform 真源与来源公式 / §8.2 派生显示色来源公式与 rationale / §8.3 四要素硬规则 + 不得冒充新色板 / §8.4 未完成待登记（详见 §3） |
| 4 | `F:/Game/aierdengfahuan/README.md` | **就地改 1 处 + 追加 4 处** | 第 16 项「还差什么」同步 A31/A32；头部 R29C 说明行；「一、已做了什么」R29C 条目行 + R29C 回归真跑行；「二、还差什么」R29C 复核段（详见 §5） |
| 5 | `teamwork/Rank-3/R29C-*.log`（12 份） | **新建 · 运行输出留档** | G0-version / G1-import / G2a~G2f / G3-quit / RUN-r19 / RUN-r17 / TFV-selftest，均为实际 stdout（非工程源文件、非脚本） |
| 6 | `teamwork/Rank-3/DONE-R29C.md` | **新建** | 本文件 |
| 7 | `teamwork/command_center/ai/3/outbox/cmd-20261111-120737-845-A3.json` | **新建** | 回执 JSON（`task_id` / `ai:3` / `status:"done"` / `result` 引用本文实际结论） |

**未写**：任何 `godot/` 工程业务文件（`depth_profile.tres` / `v070_depth_grade.gdshader` / `hd2d_parallax.gd` / `hd2d_fx.gd` / `hud.gd` / `tutorial_director.gd` / `verify_depth_profile_v070.gd` / `palette_256.json` / `project.godot` / 场景 / 素材 / `.tres` / shader）、其它 Rank 目录、`00-汇总.md` / `00-进度台账.md` / 群聊总线 / 资产表 / 中枢 done 表；未修改任何验证 `.gd` 脚本。

---

## 2. A31 两处「改前 → 改后」逐处对照

**统一目标（裁决 A26 落地口径）**：写方 = Rank-1 `tutorial_director.gd`（运行时代理按 `max` 写、`set_flag` 与本步奖励合并一次 `commit("tutorial_step_reward")`）；commit reason = `tutorial_step_reward`（每步结算 T-P1）；读方 = 教学 HUD 读运行时游标（`get_snapshot()["step_index"]` / `hud.gd read_tutorial_progress()`）、绝不读世界 flag；世界 flag `grace.tutorial.step_index` / `grace.tutorial.completed` 只作历史进度（重启恢复 / 回放断言纯读 `get_flag`）。信号名 `tutorial_step_completed(step_id, reward)` 保留不改（A26 实现即此信号）。

### 2.1 第 ① 处 · `WAVE-TRIAL-GDD.md` 行 492（任务单称「§10.6 行 492」）

> **定位如实说明**：任务单字面「§10.6 行 492」，按行号 492 + 「Rank-3 订阅写 / Rank-1 不写 flag」内容精确定位为 **§10.3 inputs 事件输入表**的「事件输入」行（§10.6 在本文件中是 failure states）。按任务单给定的行号 + 内容改该行，未改动其它行。

| 项 | 改前 | 改后 |
|---|---|---|
| 事件输入行「口径」列 | `Rank-3 订阅信号写 \`grace.tutorial.step_index\` / \`grace.tutorial.completed\` 并累加 \`grace.trial.points\`（I-1）；**Rank-1 不写 flag**` | `**A31 按裁决 A26 落地口径统一**（R29C）：**写方 Rank-1 \`tutorial_director.gd\`**（运行时代理：每步 \`step_index\` 按 \`max\` 推进的 \`set_flag\` 与本步 \`grace.trial.points\` 奖励合并入同一次 \`commit("tutorial_step_reward")\` 原子落盘、不新增落盘点；三步全完成 \`commit("tutorial_completed")\` 置 \`completed=true\`）／**教学 HUD 读运行时游标**（\`get_snapshot()["step_index"]\` / \`hud.gd read_tutorial_progress()\`）、绝不读世界 flag／**世界 flag 只作历史进度**（重启恢复 / 回放断言纯读 \`get_flag\`）／信号名 \`tutorial_step_completed(step_id, reward)\` 保留不改。R28 原登记「Rank-3 订阅信号写 / Rank-1 不写 flag」已废止，逐处改前→改后见 \`teamwork/Rank-3/DONE-R29C.md\`` |

- 四列（类别 / 输入 / 来源 / 口径）结构与「来源」列 `**Rank-1** 导演层信号` **保持不动**；只替换「口径」列，为最小授权改动。
- 改后同时覆盖四项统一要素（写方 Rank-1 / reason `tutorial_step_reward` / 教学 HUD 读运行时游标 / 世界 flag 只作历史进度），并标注 R28 原登记值（不隐瞒历史）。

### 2.2 第 ② 处 · `00-协作契约.md` §3.3 登记表 `grace.tutorial.completed` 行（行 78）

| 项 | 改前 | 改后 |
|---|---|---|
| `grace.tutorial.completed` 行「读写方」列「写」 | `**写**：Rank-3（订阅三步全完成信号置 \`true\`，与末次 \`step_index\` 同一 \`commit("tutorial_completed")\` 原子先落盘）` | `**写**：**Rank-1 \`tutorial_director.gd\`**（A26 运行时代理 / R29C 按裁决 A31 统一：三步全完成置 \`true\`，与末次 \`step_index\` 同一 \`commit("tutorial_completed")\` 原子先落盘、T-P2 沿用不改；每步 \`step_index\` / 本步 \`grace.trial.points\` 奖励由同一运行时代理合并入 \`commit("tutorial_step_reward")\`、见 \`step_index\` 行）` |
| 同行追加「A26 落地口径」注记 | （无） | `｜**A26 落地口径（A31 扩大统一）**：写方 Rank-1 \`tutorial_director.gd\`、每步 commit reason \`tutorial_step_reward\`、教学 HUD 读运行时游标、世界 flag 只作历史进度（R28 原登记「写方 Rank-3 订阅三步全完成信号」已废止，逐处改前→改后见 \`teamwork/Rank-3/DONE-R29C.md\`）` |
| 同行「读」列 / 「单调性」列 | `**读**：赐福点亮态（读三段式 flag，不硬编码条件）、老玩家跳过教学门控、回放断言（纯读 \`get_flag\`）`／`**只增不减（false → true 单向）**：… 一次性永久成就` | **未改，逐字保留** |

> **reason 归属如实说明（不篡改其它历史条款）**：A26 落地口径四要素中的 `tutorial_step_reward` 是**每步结算 T-P1 / \`step_index\` 行**的 commit reason（R29 已统一，本轮不再改）；`grace.tutorial.completed` 自身的原子落盘 reason 仍是 `tutorial_completed`（GDD §10.8 T-P2、契约 §3.3 R28 / R29 说明段均写明「沿用不改」）。本处统一的**核心是写方** Rank-3 → Rank-1 `tutorial_director.gd`，并把四要素作为口径归属注记带上；若把 `completed` 行 reason 强行改成 `tutorial_step_reward`，会与 T-P2 / R28 / R29 历史条款冲突、越出「不改动其它历史条款」授权，故如实保留 `tutorial_completed`。

### 2.3 配套说明段与 README 同步（若涉及）

| # | 位置 | 动作 | 内容 |
|---|---|---|---|
| S1 | 契约 §3.3 末尾 | **追加 R29C 说明段** | 逐处改前→改后（登记表 `completed` 行「写」、R28 原口径废止、GDD 行 492 配套改动）+ 明确未动边界（见 §2.4）+ 新残留如实登记 |
| S2 | README 第 16 项 | **就地改标题 + 说明列** | 「§10.8 之外残留口径差异待裁决」→「A31 已统一两处 / 余 GDD §10.8 `completed` 行」；说明列把 R29「保留未动、交裁决」更新为 R29C「两处已统一 + 新残留登记 + A32 派生色公式待补」 |
| S3 | README 头部 / 已做 / 还差什么 | **追加 4 处** | 见 §5 |

### 2.4 未改动其它历史条款（逐处核对）

- **契约 §3.3**：`grace.tutorial.step_index` 整行（R29 已统一）、`commit("tutorial_completed")` / `tutorial_step_reward` / `load` / R26 三处波次 reason、R25 / R26 / R27 / R28 / R29 五组历史说明段、三段式正则段、§4.4 十字段 / `schema_version=3` 段、I-1~I-6 接口表、§3.1 / §3.2 缺号、§9 及其余历史条款一律未改。
- **GDD**：本轮**只改行 492**；§10.8 的 `grace.tutorial.completed` 行（行 589）仍为 R28 登记「写：Rank-3（订阅三步全完成信号置 `true`…）」、T-P1~T-P4、口径差异登记段、T-V1~T-V10、R29 说明段、§10.1~§10.7 / §10.9 及 §0~§9 全部历史章节一律未改。
- **README**：§3.1~§3.4 资产表实测字节数、中枢 done 轮次表（仍 R22 快照）、R22~R29 各历史说明行 / 条目行 / 复核段一律未改（只就地订正第 16 项）。
- **如实登记的新残留**：因任务单 ① 授权清单只列「GDD 行 492 + 契约 §3.3 `completed` 行」，且「不改动其它历史条款」，**GDD §10.8 的 `grace.tutorial.completed` 行仍写方 Rank-3**，与契约 §3.3 已统一的 `completed` 行存在**新的残留口径差异**；按 R29 同样的「如实登记 → 交总指挥裁决」模式保留未动，交裁决是否后续扩大统一（见 §6 第 1 项）。

---

## 3. A32 派生色说明（`HD2D-STYLE-ANCHOR-v2.md` 追加 §8，只追加本段、不改任何 `godot/` 工程文件）

**触发**：`capture/CAPTURE-REPORT.md` §12.2 / `capture/V070-RUNTIME-REVIEW.md` §3 / `teamwork/Rank-4/DONE-R29.md` §2 的 R29 shader 报告把 `cool_fog_color` 标为 `#2B3A5C`、`warm_glow_color` 标为 `#F0A94C`，与锚点 v2 §2.2 / §5 钉死的 `#1B2A4A` / `#C99A3A` 不同。

### 3.1 要点（§8.1 uniform 真源 + 来源公式）

- **真源**：`godot/data/render/depth_profile.tres`（P1 唯一数据源，Rank-2 所有）的 `cold_night_fog_color = "#1B2A4A"` / `warm_gold_key_color = "#C99A3A"`，desktop / mobile 两档逐字引用 v2 §2.2 唯一锚点；依据 `teamwork/Rank-2/DEPTH-PROFILE-TUNING.md` §2 第 6 / 7 行、§3。shader（`godot/shaders/v070_depth_grade.gdshader`）的 `cool_fog_color` / `warm_glow_color` 及全部 uniform **一律无默认值**，由 `godot/scripts/render/hd2d_parallax.gd::_r29_map_profile()` 经 `set_shader_parameter` 注入。
- **来源公式（色号逐字直取、零数值派生）**：`cool_fog_color = Color(depth_profile.cold_night_fog_color)`、`warm_glow_color = Color(depth_profile.warm_gold_key_color)`，即 `#RRGGBB` → `Color(String(v))` → `vec3`，**色号本身不做任何数学运算**。真正带量纲派生的是强度类 uniform（`cool_fog_strength = clamp(fog_density × 5, 0, 1)`、`depth_far_strength = clamp(layer_depths[0] × 0.4, 0, 1)`、`blur_radius = clamp(parallax_coefficients[0] × 25, 0, 4)`），系数 `×5 / ×0.4 / ×25` 均标 `[PLACEHOLDER]` 待试玩校准、rationale 见 `hd2d_parallax.gd:430-434` 注释。

### 3.2 派生显示色 `#2B3A5C` / `#F0A94C` 来源公式与 rationale（§8.2，如实登记）

- **来源**：**不是锚点色的代码派生**，而是 `godot/assets/generated/palette_256.json`（Rank-4 32 色项目级色库）的灰阶档 **L3 = `#2B3A5C`（`gray_pct 28`，冷夜雾中间调）/ L7 = `#F0A94C`（`gray_pct 85`，暖金受光主色）**，亦为 `verify_depth_profile_v070.gd` 的 `FALLBACK_COLD_GROUP` / `FALLBACK_WARM_GROUP` 降级常量；属 v2 §5.1 已登记的「另一套历史色板（32 色板与 v1 §2 的 16 色受控板并存、不擅自合并）」，与锚点无逐字派生关系。
- **rationale（为何出现在 shader 报告）**：`teamwork/Rank-2/DONE-R29.md` 文首 / `DEPTH-PROFILE-TUNING.md` §3 如实纠错登记 —— Rank-2 早期 Glob 误判锚点文档「未落盘」，`depth_profile.tres` **首版**曾采用 `palette_256.json` 的 `#2B3A5C` / `#F0A94C`（暗角 `0.32`）；真跑 `FileAccess.file_exists` 纠正后**最终 `.tres` 改回锚点 `#1B2A4A` / `#C99A3A`**、暗角 `0.24`、首版 46 PASS 不作最终结论。Rank-4 录屏 / shader 报告显示色沿该历史首版 / 降级分支口径，与最终 `.tres` 真源不一致，属**历史显示色、不是 v2 新增色**。

### 3.3 硬规则（§8.3）

1. **四要素齐全**：今后任何 shader 派生 / 显示色若要登记为「由锚点色派生」，必须逐色写明 **① 来源锚点 hex ② 派生公式（明度档 / 色相 / 混合的具体算式与系数）③ 结果 hex ④ rationale**，登记于 §8 或经裁决；四要素不全者按「历史显示色 / 非 v2 受控色板成员」如实登记。
2. **不得冒充新色板（A32 裁决核心）**：不得把 `#2B3A5C` / `#F0A94C` 宣称为「v2 新色板 / 第三套色板 / 锚点色的合法派生」；**不并入 §5.2 16 色受控表**、**不改写 §5.3 可机器解析常量块**（`colors_16` / `cold_night_fog_hex=#1B2A4A` / `warm_gold_key_hex=#C99A3A` / `high_saturation_allowlist` / `wave_band_hex` 逐字冻结）、不改写 §2.2 锚点色号与 `depth_profile.tres` 色号语义；纳入受控板须先补齐四要素并走 §5.1「扩展新色经裁决统一并入、单资产不得私加」流程。
3. **真源唯一 + `hd2d_parallax.gd::_r29_base_defaults()` 的 `cool_fog_color=Color(0.12,0.22,0.40)` / `warm_glow_color=Color(1.0,0.72,0.32)` 是 `[PLACEHOLDER]` 安全默认、非色板色**，不得当作新色号引用。
4. **不得改 `godot/` 工程文件**：`depth_profile.tres` / `v070_depth_grade.gdshader` / `hd2d_parallax.gd` / `palette_256.json` / `verify_depth_profile_v070.gd` 的修正与派生公式补登记属 Rank-2 / Rank-4 工程写入、经裁决，Rank-3 本轮一律未动。

### 3.4 与既有结论的关系（§8.4）

§8 为纯追加说明段，**不改变 §3 差距清单、§4 判据、§5 色板、§7 边界**任何既有结论；README「还差什么」第 2 / 12 项保持未达；与 A30「不谎称 shader 生效 / 不把 2D 近似包装成 HD-2D 全绿」纪律一致。`#2B3A5C` / `#F0A94C` 目前缺「由锚点经何种公式派生」的规范公式，待 Rank-4 补四要素并交裁决（见 §6 第 2 项）。

---

## 4. 真跑输出结论（不靠 clean build，用实际 stdout）

### 4.1 命令清单（引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--path F:/Game/aierdengfahuan/godot`，一次一个进程、串行 12 次）

| 段 | 命令标志 | 日志 | `EXIT` |
|---|---|---|:--:|
| G0 | `--version` | `R29C-G0-version.log` | 0 |
| G1 门禁 | `--headless --import` | `R29C-G1-import.log` | 0 |
| G2a | `--headless --check-only --script <abs>/verify_tutorial_flags_v060.gd` | `R29C-G2a-tfv060.log` | 0 |
| G2b | `--headless --check-only --script res://scripts/save_delta_writer.gd` | `R29C-G2b-writer.log` | 0 |
| G2c | `--headless --check-only --script res://scripts/hud.gd` | `R29C-G2c-hud.log` | 0 |
| G2d | `--headless --check-only --script <abs>/r19_verify_hud.gd` | `R29C-G2d-r19.log` | 0 |
| G2e | `--headless --check-only --script res://scripts/verify_hud_binding.gd` | `R29C-G2e-r17.log` | 0 |
| G2f | `--headless --check-only --script <abs>/r22_save_e2e.gd` | `R29C-G2f-e2e.log` | 0 |
| G3 门禁 | `--headless --quit` | `R29C-G3-quit.log` | 0 |
| 回归 A | `--headless --script <abs>/r19_verify_hud.gd` | `R29C-RUN-r19.log` | 0 |
| 回归 B | `--headless --script res://scripts/verify_hud_binding.gd` | `R29C-RUN-r17.log` | 0 |
| TFV selftest | `--headless --script <abs>/verify_tutorial_flags_v060.gd` | `R29C-TFV-selftest.log` | 0 |

> `<abs>` = `F:/Game/aierdengfahuan/teamwork/Rank-3/`。**12 次引擎调用全 `EXIT=0`**。`--script` 模式沿用历轮纪律：脚本内不用 `/root/...` 绝对路径，用 `Engine.get_main_loop()` / `get_root().get_node_or_null()` 相对探活（本轮未改任何 `.gd` 脚本、未新建探针 / 巡检脚本）。

### 4.2 PASS / FAIL（实际 SUMMARY 行）

| 项 | 实际输出 | 结论 |
|---|---|---|
| `r19_verify_hud.gd` | `[R19] SUMMARY pass=20 fail=0 ok=true` | **20 PASS / 0 FAIL** |
| `verify_hud_binding.gd` | `[R17] SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true` | **11 PASS / 0 FAIL**，**首次即 11/0，无 R27 并发 9/2 抖动** |
| **任务单 ④ 的 31 PASS 回归** | 20 + 11 | **31 PASS / 0 FAIL，不回退** |
| `verify_tutorial_flags_v060.gd` selftest | `[TFV060] SUMMARY phase=selftest pid=25924 pass=15 fail=0 ok=true` / `[TFV060] RESULT=ALL_PASS` | **15 PASS / 0 FAIL**；**本轮只跑 selftest 一态，未跑 write/read 两独立进程三态，如实登记、不冒充 R28 的 21 PASS 全流程** |

### 4.3 三段门禁 `grep SCRIPT ERROR=0`

- **12 份 `R29C-*.log` 逐份 `SCRIPT ERROR=0`、`Parse Error=0`、`ERROR:` 前缀 = 0**（`grep -c` 逐份核验）。**三段门禁 `grep SCRIPT ERROR=0` 达成**；`G1 --headless --import` 日志为完整的 `first_scan_filesystem` / `loading_editor_layout` 进度，全局类名 / autoload / 插件初始化正常、无 Parse Error。
- **如实登记（不谎报、也不夸大）**：`R29C-G3-quit.log` 有 **1 条既有退出 WARNING** —— `WARNING: 2 ObjectDB instances were leaked at exit`（`core/object/object.cpp:2536`），历轮已登记、非 ERROR、非回归断言失败、非 Rank-3 引入，如实保留。**本轮 G3 无 R29 那 4 条 `ERROR:` 前缀残留**（R29 的 `add_child() failed` / RID leaked 属 Rank-1 并发面板迁移期产物，本轮已稳定）；G3 日志显示 `[R29][SHOP] 兑换面板迁出 SubViewport → 独立 CanvasLayer(layer=45)` 已正常完成、`[R29][DEPTH] 参数表已读取 … 总命中=20 | 生效来源=res://data/render/depth_profile.tres` 真读路径生效、`[R29][GRADE] shader 小样已挂载`（均属 Rank-1 / Rank-2 / Rank-4 并发产出，Rank-3 未写、未改、未代验）。
- 12 次调用 `EXIT` 全 0、31 PASS 不回退；按历轮「如实保留 WARNING、非 ERROR」纪律一并登记，**不宣称无任何 WARNING**。

---

## 5. README 新增

- **头部**：追加 **R29C 说明行**（A31 两处统一 / A32 §8 派生色说明 / 未改 `godot/` / R29B 为 Rank-1 并行轮次不代写 / 31 PASS / 三段门禁 / G3 1 条 WARNING 如实登记）。
- **「一、已做了什么」**：追加 **R29C 条目行**（A31 两处逐处要点 + A32 §8 四子节要点 + 未动边界 + 新残留登记）与 **R29C 回归真跑行**（12 次调用 / 31 PASS / TFV selftest 15 PASS / `SCRIPT ERROR=0` / G3 无 R29 那 4 条 ERROR、仅 1 条既有 WARNING）。
- **「二、还差什么」**：**就地订正第 16 项**（标题「§10.8 之外残留口径差异待裁决」→「A31 已统一两处 / 余 GDD §10.8 `completed` 行」；说明列补 R29C / A31 统一、新残留、A32 派生色公式待补）；追加 **R29C（v0.7.1）复核段**（第 10/11/12/13/14/15/16 项状态 + A31 新残留 + A32 派生色待补）。
- **未改**：§3.1~§3.4 资产表实测字节数、中枢 done 轮次表（仍 R22 快照）、R22~R29 各历史说明行 / 条目行 / 复核段。

---

## 6. 未完成项与如实边界（无功能性阻塞）

| # | 项 | 状态 / 归属 |
|---|---|---|
| 1 | **A31 新残留：GDD §10.8 的 `grace.tutorial.completed` 行（行 589）仍「写方 Rank-3 订阅三步全完成信号」** | 任务单 ① 授权清单只列「GDD 行 492 + 契约 §3.3 `completed` 行」、且「不改动其它历史条款」→ 按授权边界保留未动；与契约 §3.3 已统一的 `completed` 行存在新的残留口径差异，**如实登记、交总指挥裁决是否后续扩大统一**（与 R29 登记 → A31 补单同一协作模式） |
| 2 | **A32 派生色 `#2B3A5C` / `#F0A94C` 缺「由锚点 `#1B2A4A` / `#C99A3A` 经何种公式派生」的规范公式** | 实测来自 Rank-4 `palette_256.json` 32 色板独立灰阶档（L3/L7），非锚点色派生；`HD2D-STYLE-ANCHOR-v2.md` §8.4 要求 Rank-4 补「来源锚点 hex + 派生公式 + 结果 hex + rationale」四要素并交裁决；在此之前按「历史显示色、非 v2 色板成员」登记，**不得冒充新色板** |
| 3 | **TFV 全流程 21 PASS** | 本轮按任务单 ④ 只跑 selftest 15 PASS，未跑 write / read 两独立进程三态；如实登记、不冒充 R28 全流程 |
| 4 | **R29B（Rank-1 并行轮次 `cmd-20261111-120737-841-A1` 兑换面板深底遮挡修复）** | 属其它 Rank 并发产出，Rank-3 本轮**不代写、不代验、不冒充已验**（README 头部 / 条目行如实注明） |
| 5 | **历轮长期未达项**：人工试玩（exe / apk 手感 / 审美验收 A17）、`128bit` 歧义（A15 保留待用户确认）、HD-2D 全绿未达（含第 2 项真 HDR bloom / 3D 体积光 / SSR，A30 不切后端）、v0.4.0/0.5.0/0.6.0 `[PLACEHOLDER]` 数值待试玩校准、教学表落地校对、教学 HUD / 点亮态 / 第 1 波衔接运行时接线、Rank-1 / Rank-2 / Rank-4 并发产出未代验、15~20 秒实机录屏目视 | 均属用户侧 / 其它 Rank / 总指挥裁决范围，Rank-3 本轮未代做、未宣称完成、未谎报 |
| 6 | **风格锚点 v2 的 5 组 `[PLACEHOLDER]` 数值 + J1 缩略图 10% 剪影 / 暗角 / 光晕 / 三波色带画面观感** | 待录屏目视 + 用户人工试玩校准；headless 真跑无真实帧缓冲，Rank-3 只能静态查表判 J2 / J3 / J5 / J6，**不宣称 HD-2D 全绿** |

**阻塞：无功能性阻塞。** 派单 ①（A31 两处 + README 同步逐处改前改后）/ ②（A32 追加派生色说明段）/ ③（README R29C 条目与还差什么）/ ④（31 PASS 回归 + 三段门禁 + 只写自有文档）均真实达成。

---

## 7. 授权边界与公共契约核对

- **只写**：`WAVE-TRIAL-GDD.md` 行 492、`00-协作契约.md` §3.3、`HD2D-STYLE-ANCHOR-v2.md` §8、`README.md`（工程根）、`teamwork/Rank-3/`（`DONE-R29C.md` + 12 份 `R29C-*.log`）、`command_center/ai/3/outbox/` 回执 JSON。**未写任何 `godot/` 工程业务文件**，未写其它 Rank 目录，未改任何验证脚本。
- **直接改直接真跑**：12 次引擎调用均实际执行、日志为真实 stdout；**未新建只读探针 / 巡检脚本**（`R29C-*.log` 是运行输出留档，非脚本）。`--script` 模式不用 `/root/...` 绝对路径（沿用既有脚本的相对探活写法）。
- **零付费、零外部依赖、未启 GPU job、未引入付费素材生成服务**；**不伪造产物、不谎报成功**（G3 1 条既有 WARNING / TFV 只跑一态 / GDD §10.8 `completed` 行新残留 / 派生色来自另一套历史色板而非锚点派生 / 任务单「§10.6」与文件实际「§10.3」编号差异均如实登记）；**未自行 git**（总指挥收尾）。
- **中文 UTF-8**；三段门禁 `--headless --import → --check-only --script → --headless --quit` 顺序执行、`grep SCRIPT ERROR=0` 达成；31 PASS 存档 / HUD 回归不回退。
