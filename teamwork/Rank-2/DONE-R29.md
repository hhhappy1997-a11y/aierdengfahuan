# DONE-R29.md · Rank-2（战斗系统与数据驱动）

> 轮次 **R29**｜命令 `cmd-20261111-112803-988-A2`（`[ROUND=R29]`，v0.7.0 新内容）｜派单 `cmd-20261111-112803-988`
> 真源：`teamwork/Rank-2/调度任务单-latest.json`（`id` / `ai=2` / 正文完整核对；被 Read 截断的 `task` 全文经 python 解析补齐）
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan`，Godot 工程 `F:/Game/aierdengfahuan/godot`｜中文 UTF-8
> 结论：**任务单 ①~④ 全部落地并经真跑验证**。核心资源首版 **11:46 尽早落盘**供 Rank-4 读取；
> 三段门禁 `EXIT=0`、`grep SCRIPT ERROR / Parse Error = 0`；新增 `class_name DepthProfile`
> 已 `--headless --import` 注册（`godot/.godot/global_script_class_cache.cfg:51`）。
> `verify_depth_profile_v070.gd` **46 PASS / 0 FAIL / `RESULT=PASS` / `EXIT=0`**。
> **如实登记（重要）**：Rank-3 的 `HD2D-STYLE-ANCHOR-v2.md` 本轮**已并发落盘**，故色板**未降级**
> ——采用其 §5.3 `colors_16`（16 色受控板）+ §2.2 唯一锚点 `#1B2A4A` / `#C99A3A`。
> 早期用 Glob `**/HD2D-STYLE-ANCHOR*` 未匹配到工程根级文件，一度误判「未落盘」并采用
> `palette_256.json` 的 `#2B3A5C` / `#F0A94C`；真跑 `FileAccess.file_exists` 返回 `exists=true`
> 后复核确认文档确实存在，随即纠正色号 / 暗角并把 verify 重写为「已落盘→v2 板 / 未落盘→降级板」
> 双分支。**首版 46 PASS 不作最终结论，最终以修正后重跑的 46 PASS 为准**；纠错全过程见
> `DEPTH-PROFILE-TUNING.md §3`，不掩盖、不谎报。

---

## 1. 实际交付清单

| # | 文件 | 动作 | 大小 | 内容 |
|---|---|---|---|---|
| 1 | `godot/scripts/render/depth_profile.gd` | **新写** | 5985 B | `extends Resource` / `class_name DepthProfile`；P1 七字段 + `desktop`/`mobile` 容器字段；默认值全为 `[PLACEHOLDER]` 非法占位基线并逐项写 rationale；`is_valid()` 合法性自检（负强度 / 超 1 系数 / 空表 / 字段缺失拒绝不崩）+ `_is_hex6()` 色号格式。 |
| 2 | `godot/data/render/depth_profile.tres` | **新写** | 953 B | 顶层 `DepthProfile` 容器 + 2 个 `DepthProfile` 子资源（desktop / mobile），两档 7 字段数值；色号逐字取 v2 锚点；mobile 降级不糊不黑。 |
| 3 | `godot/scripts/verify_depth_profile_v070.gd` | **新写** | 13729 B | `extends SceneTree`，**46 条断言**：色板依据双分支（`[ANCHOR]` / `[DEGRADE]`）+ 两档合法 + 降级①~⑥ + 12 类边界拒绝；逐条 PASS/FAIL + SUMMARY + RESULT，失败 `quit(1)`。 |
| 4 | `teamwork/Rank-2/DEPTH-PROFILE-TUNING.md` | **新写** | — | 数值假设表 / 调参唯一入口 / broken 4 定义 / 与 `quality_preset_*.tres` 关系 / 色板依据与纠错登记。 |
| 5 | `teamwork/Rank-2/DONE-R29.md` | **新写** | 本文件 | 本文件。 |
| 6 | `teamwork/command_center/ai/2/outbox/cmd-20261111-112803-988-A2.json` | **新写** | — | 按本命令 id 的回执（**teamwork 下 `command_center/ai/2/outbox`，非工程根 `command_center/`**）。 |

另有 `teamwork/Rank-2/R29-*.log` **4 份真跑日志**（`gate1-import` / `gate2-checkonly` / `run-verify` / `gate3-quit`），均为真实执行输出，非推断。

**未写 / 未改**（目录所有权硬约束）：`hud.gd` / `presentation.gd` / 场景 / shader / 素材 / 契约 / README / `project.godot` / 既有 `quality_preset_*.tres` / `render_profiles.tres` / 既有战斗件 / 导演脚本；**未自行 git**。零付费、零外部依赖、未启 GPU job、未新建只读探针 / 巡检脚本（verify 为正式自测件）。

---

## 2. 按任务单正文逐项落实

### ① `depth_profile.gd` + `depth_profile.tres`（P1 参数化 / 尽早落盘）

`class_name DepthProfile extends Resource`，按 `TECHNICAL-ART-DEPTH-v060.md` §5 **P1**「多层视差景深 + 边缘暗角 + 冷夜雾 + 暖金光晕」参数化。**7 个参数字段 + 两档数值**（全部 `[PLACEHOLDER]` 首版、待人工试玩校准，逐项 rationale 见 `depth_profile.gd` 头注与 TUNING §2）：

| 字段 | 语义 | `desktop` | `mobile` | 合法域 |
|---|---|---|---|---|
| `layer_depths` | 层深（各层归一化深度，远→近，长度=层数） | `[0.25, 0.55, 0.90]`（3 层） | `[0.35, 0.80]`（2 层） | 每个 `0<d<=1` |
| `parallax_coefficients` | 视差系数（与层深一一对应） | `[0.06, 0.14, 0.26]` | `[0.05, 0.12]` | 每个 `0<c<=1`、严格递增 |
| `fog_density` | 冷夜雾密度 | `0.035` | `0.018` | `0~1` |
| `vignette_strength` | 边缘暗角强度 | `0.24` | `0.12` | `0~1` |
| `warm_glow_strength` | 暖金光晕强度 | `0.45` | `0.22` | `0~1` |
| `cold_night_fog_color` | 冷夜雾色号 | `#1B2A4A` | `#1B2A4A` | `#RRGGBB` ∈ 色板 |
| `warm_gold_key_color` | 暖金主光色号 | `#C99A3A` | `#C99A3A` | `#RRGGBB` ∈ 色板 |

- **mobile 降级不糊不黑**：层数 3→2、雾 0.035→0.018（低于工程 `fog_density=0.02` 基线）、暗角 0.24→0.12、光晕 0.45→0.22、视差逐项更小；两档色号相同（调性不随画质档变，只降强度/层数/密度）。
- **rationale 摘要**：视差系数对齐 `hd2d_parallax.gd:47-49` 既有 `0.06/0.14/0.26`；雾密度以 `Environment.fog_density=0.02` 为基线；暗角对齐 v2 §2.3 建议 `0.10~0.25` 且避 R28B「low 档缩放伤 HUD 文字」；光晕对齐 `FXBloom`「仅 warm_gold_key 过阈」；色号逐字引用 v2 §2.2 锚点（明度差 43≈4 档，满足 J2）。
- **落盘时间（文件 mtime 真值）**：`depth_profile.gd` / `depth_profile.tres` 首版 **2026-11-11 11:46**（尽早落盘，Rank-4 shader 可读）；依锚点文档纠正色号/暗角后 **11:47** 定稿；`verify_depth_profile_v070.gd` **11:48** 落盘。
- **单文件两档实现**：顶层 `DepthProfile` 容器以 `desktop` / `mobile`（宽类型 `Resource`）引用 2 个 `[sub_resource]` 子资源，运行时 `as DepthProfile` 还原；`CACHE_MODE_IGNORE` 真读盘回读两档 7 字段全部命中（见 `R29-run-*.log` 的 `[R29][desktop]` / `[R29][mobile]` 行）。

### ② `verify_depth_profile_v070.gd`（46 条断言）

`extends SceneTree`，**46 PASS / 0 FAIL / `RESULT=PASS` / `EXIT=0`**。分组：

| 组 | 条数 | 内容 | 结果 |
|---|---:|---|---|
| ⓪ 色板依据选定并如实登记 | 1 | `[ANCHOR]` 已落盘→v2 16 色板 / `[DEGRADE]` 未落盘→`palette_256.json` 32 色 | PASS |
| ①~③ 资源加载与两档存在 | 3 | `CACHE_MODE_IGNORE` 真读盘、cast `DepthProfile`、desktop/mobile 子资源存在 | PASS |
| 两档参数合法 | 12 × 2 | `is_valid()`、长度匹配、层深/系数范围、严格递增、三强度 0~1、冷雾/暖金色号 ∈ 色板且逐字 == v2 锚点 | PASS |
| mobile 降级①~⑥ | 6 | 不更亮（光晕）/ 雾不更浓 / 层数不多 / 层深跨度不超 / 视差逐项不超 / 不更黑（暗角） | PASS |
| 边界拒绝不崩 | 12 | 负 fog / 负暗角 / 负光晕 / 系数超 1 / 层深超 1 / fog 超 1 / 空层深表 / 空系数表 / 长度不匹配 / 空色号 / 非法 hex / 全新空实例 —— 全部 `is_valid()==false` 且调用未抛异常未崩溃 | PASS |

- **色板校验（任务单②）**：`HD2D-STYLE-ANCHOR-v2.md` 本轮已落盘 → **不降级**，用其 §5.3 `colors_16` 16 色受控板 + §2.2 唯一锚点 `#1B2A4A` / `#C99A3A`（文档明示「供 `depth_profile.tres` 字段逐字引用」）；降级分支（自带 `palette_256.json` 32 色常量 + 语义组）保留在脚本中，本轮真跑未触发，触发时打印 `[DEGRADE]` 如实登记。
- **边界（任务单②）**：`DepthProfile.is_valid()` 为被测对象，负强度 / 超 1 系数 / 空表 / 字段缺失一律返回 `false`，不抛异常、不 assert、不崩溃；若真崩则门禁 `SCRIPT ERROR>0`，实测为 0。

### ③ `DEPTH-PROFILE-TUNING.md`（调参文档）

- **数值假设表**：两档 7 字段逐项 `[PLACEHOLDER]` + 语义 + 合法域 + rationale（§2）。
- **调参唯一入口**：`godot/data/render/depth_profile.tres`；`.gd` 默认值只是非法占位基线；校准同步清单 `.tres → verify 期望/色板 → 本文 → 三段门禁`，不静默改数（§1）。
- **broken 4 定义**（§4）：**过暗**（暗部沉进背景 / 明度差 <2 档，嫌疑暗角↑雾↑光晕↓）／**过曝**（暖金泛白 / 全屏发亮，嫌疑光晕↑）／**景深分层不可辨**（三层糊成一片 / 10% 剪影不可读，嫌疑层深跨度小 / 系数梯度小 / 雾过高）／**移动端糊成一片**（480×270 下远景与主体黏连 / HUD 文字不可辨，嫌疑 mobile 雾/层数/暗角未充分降级）；并注明 verify 降级①~⑥ 只保证数值关系、不保证目视清晰，画面判定归 Rank-4 录屏 + 用户试玩。
- **与 `quality_preset_*.tres` 关系**（§5）：正交、零字段重名、零脚本改动；`quality_preset` 管「渲染预算 + 2D FX 开关」，`depth_profile` 管「景深观感强度/层数/色号」；mobile 降级同向（FX 四项全关 + 强度更低）；不重复定义帧时间/内存/缓冲；选档约定 `low→mobile` / `high→desktop`，本轮不接线。

### ④ 三段门禁（真跑，`grep SCRIPT ERROR=0`）

```bash
ENG="D:/Godot/Godot_v4.7.2-stable_win64.exe"
PROJ="F:/Game/aierdengfahuan/godot"
# G1 新增 class_name 必须先 --headless --import（DepthProfile 已注册 global_script_class_cache.cfg:51）
"$ENG" --headless --path "$PROJ" --import
# G2 解析门禁 + 真跑自测
"$ENG" --headless --path "$PROJ" --check-only --script res://scripts/verify_depth_profile_v070.gd
"$ENG" --headless --path "$PROJ" --script res://scripts/verify_depth_profile_v070.gd
# G3 主场景加载退出
"$ENG" --headless --path "$PROJ" --quit
```

- `G1_import=0 / G2_checkonly=0 / G2_run=0 / G3_quit=0`；逐段 `grep -cE "SCRIPT ERROR|Parse Error"` = **0 / 0 / 0 / 0**；Grep 工具对 `R29-*.log` 复核亦 `No matches found`。
- 真跑日志：`teamwork/Rank-2/R29-gate1-import.log` / `R29-gate2-checkonly-verify_depth_profile_v070.log` / `R29-run-verify_depth_profile_v070.log` / `R29-gate3-quit.log`。

---

## 3. 真跑输出结论汇总（最终态）

| 脚本 / 门禁 | PASS | FAIL | RESULT | EXIT |
|---|---:|---:|---|---:|
| `verify_depth_profile_v070.gd`（本轮新） | **46** | 0 | `PASS` | 0 |
| G1 `--headless --import` | — | — | `SCRIPT ERROR / Parse Error = 0` | 0 |
| G2 `--check-only --script` | — | — | `SCRIPT ERROR / Parse Error = 0` | 0 |
| G2 `--script`（真跑，含 46 断言） | 46 | 0 | `PASS` | 0 |
| G3 `--headless --quit` | — | — | `SCRIPT ERROR / Parse Error = 0` | 0 |

- `[R29][ANCHOR]`：`anchor_doc=HD2D-STYLE-ANCHOR-v2.md exists=true | 文档已落盘，不降级；采用 HD2D-STYLE-ANCHOR-v2.md §5.3 colors_16（16 色受控板）`。
- 两档回读真值（节选）：`desktop ... fog=0.0350 vignette=0.2400 glow=0.4500 cold=#1B2A4A warm=#C99A3A`；`mobile ... fog=0.0180 vignette=0.1200 glow=0.2200 cold=#1B2A4A warm=#C99A3A`。
- `G3` 日志中 `[R29][SHOP] 兑换面板迁出 SubViewport ...` 等为**其它工位并发改动**，非本轮所为，如实登记。

---

## 4. 未完成项 / 阻塞 / 如实边界

1. **所有数值 `[PLACEHOLDER]` 首版，人工试玩校准未执行**（用户侧）；本文与 TUNING 只给假设表与 rationale，不冒充已校准。
2. **Rank-4 shader / `hd2d_parallax.gd` 真机读取接线未做**：本轮只交付数据源 + 结构 + 校验；深度剖面何时、以何方式被 shader 消费属 Rank-4 所有权，不越界、不谎报已生效。
3. **未做 15~20 秒实机录屏回看**：本轮为 headless 数据 / 门禁任务，无渲染管线可录；TUNING §4 的 4 类 broken 画面判定归 Rank-4 录屏目视 + 用户试玩，不伪造画面证据、不宣称 HD-2D 全绿。
4. **色板降级分支本轮未触发**：锚点文档已落盘，降级常量（`palette_256.json` 32 色）保留但真跑未使用；若后续文档被移走，verify 自动降级并打印 `[DEGRADE]`。
5. **早期色板依据误判已纠正并如实登记**（见文首 / TUNING §3）：Glob `**/` 模式未匹配工程根级文件导致误判「未落盘」，真跑 `FileAccess.file_exists` 纠正；首版色号 `#2B3A5C` / `#F0A94C` 与暗角 `0.32` 已废弃，最终值以修正后 `.tres` 为准。
6. **既有画质档 / 场景 / shader / 素材 / 契约 / README / `project.godot` / `hud.gd` / `presentation.gd` 一律未改**；`quality_preset_*.tres` / `render_profiles.tres` 只读参考、未改一字；未自行 git。零付费、零外部依赖、未启 GPU job、未新建只读探针 / 巡检脚本。
7. **未做既有回归全量复跑**：本轮为新增数据/自测件，未改任何既有脚本；`G3 --headless --quit` 主场景加载 `EXIT=0 / SCRIPT ERROR=0`，但未逐一重跑 R28 的 `127/58/11` 等既有 PASS 基线（不在本轮授权与目标内），如实登记、不谎报"全部回归 PASS"。
8. `git status` 中若显示其它文件 modified，系其它工位并发改动，非本轮所为。

---

## 5. 回执

- **精确路径（任务单指定）**：`F:/Game/aierdengfahuan/teamwork/command_center/ai/2/outbox/cmd-20261111-112803-988-A2.json`（`teamwork` 下 `command_center`，非工程根 `command_center/`）。
- 内容：`{"task_id":"cmd-20261111-112803-988-A2","ai":2,"status":"done","result":"引用 DONE-R29.md 实际结论（①~④ 全部落地；depth_profile.gd/.tres 11:46 尽早落盘、11:47 定稿；7 字段两档数值见 DONE §2①；色板因 Rank-3 锚点 v2 已落盘未降级，采用 16 色受控板 + 锚点 #1B2A4A/#C99A3A；verify 46 PASS/0 FAIL/RESULT=PASS；三段门禁 EXIT=0 且 grep SCRIPT ERROR=0；调参文档与未完成项如实登记）"}`。
- **调度中枢自动收件行为（本轮实证）**：回执写入精确 `outbox` 路径 **2 次**（`11:53:56` / `11:54:45`），均被 dispatcher「收件即归档」——移入 `command_center/dispatcher/receipts/cmd-20261111-112803-988-A2.json`（另有时间戳副本 `.20261111-115445-413`）并清空 `outbox`。`dispatcher.log` 本命令 **2 行**「← 2 号 AI 回执 `<cmd-20261111-112803-988-A2>` 完成」为接收铁证；`ai/2/status.json` 已置 `state=idle / current_task="" / completed=35`（总指挥已收件结案）。归档副本 JSON 合法、`ai=2` / `status=done` / `result` 与本轮写入逐字一致。`outbox` 当前为空属标准流程（非交付缺失）；本轮未改调度中枢任何脚本 / 配置，未自行 git。
