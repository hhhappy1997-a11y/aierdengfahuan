# DONE-R6 · Rank-1（引擎架构与渲染）完成标志

> 轮次：R6（HOST 全闭环调度续派；**边界收口**，不硬造新功能）
> 派单：`Rank-1\任务书-R6.md` ｜ 任务单 id：`cmd-20261109-020321-541-A1`
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（`--version` 实测 `4.7.2.stable.official.ed1daf0bf`，EXIT=0）
> HOST 监测只认本文件。本轮只写 `F:\Game\aierdengfahuan\teamwork\Rank-1\`，唯一例外为
> `command_center\ai\1\outbox\` 回执 JSON；未写其它工位 / teamwork 根目录 / 总纲 / 契约 / 群聊总线 / 历史任务书；
> 未自行 git commit / push。
> **本轮为边界收口**：`任务书-R6.md` 四项交付清单全部依赖总指挥裁决 / 超可写范围 / headless 做不到，
> 按协作规则「依赖裁决的项不得擅自实现」，本轮未实现任何一项，只做核对、补说明、登记、真跑自检。
> 真跑结论全部来自实际输出，未伪造；未把 `project_root/` 拷到 `teamwork\` 外、未伪造「工程根已落位」。

---

## ① 本轮实际交付 / 改动文件清单

| # | 文件（绝对路径） | 动作 | 说明 |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\teamwork\Rank-1\R6-待裁决登记.md` | **新建** | 四项待裁决项的依据 / 客观证据 / 为何需裁决 / 建议 |
| 2 | `F:\Game\aierdengfahuan\teamwork\Rank-1\PROJECT_ROOT_LAYOUT.md` | **纯追加 §8**（补齐落位步骤说明） | §8 目录树核对结论 + 落位前 17 件逐件校验清单 + 落位后门禁复核步骤 + 权限收尾；既有 §1~§7 一字未改 |
| 3 | `F:\Game\aierdengfahuan\teamwork\Rank-1\DONE-R6.md` | **新建**（本文件） | ① 交付清单 ② 自检（真跑实际输出结论）③ 未完成项与阻塞 |
| 4 | `F:\Game\aierdengfahuan\teamwork\command_center\ai\1\outbox\cmd-20261109-020321-541-A1.json` | **新建**（中枢协议例外） | 回执 JSON，`status=done` |

**对照 `任务书-R6.md` §交付清单 4 项**（均按硬约束未擅自实现，逐项登记见 `R6-待裁决登记.md`）：

| 交付项 | 本轮处置 | 归类 |
|---|---|---|
| 工程根 `project_root/` 落位到 `F:\Game\aierdengfahuan\` | **未执行**（只核对目录树 + 补齐落位步骤） | 需 HOST 授权 / 超唯一可写范围 |
| headless 之外的帧时间 / p99 / spike 实测 | **未做**（headless 无渲染管线） | 需人工试玩 / headless 做不到 |
| 3 号真实实现与真实 chunk 场景接入装配层 | **未做**（依赖 3 号产出 + 待裁决） | 需总指挥裁决 |
| R5 件接入正式装配层 | **未做**（需改既有件） | 需总指挥裁决 |

**既有交付件一律未改**：R2/R3/R4/R5 全部平铺件、`project_root\` 17 件、历史 `任务书*.md` /
`调度任务单*.json` 均未改动。真跑三段门禁对 `project_root\` 直接执行，引擎生成的 `.godot\`
缓存与 11 个 `.gd.uid` 已清理，交付树恢复 **17 件原样**（核对见 §2.1）。未补 stub / 占位场景 /
联调驱动，未硬造新功能。

---

## ② 自检结果（真跑实际输出结论，未伪造）

### 2.1 目录树与映射一致性核对（只读）

对 `F:\Game\aierdengfahuan\teamwork\Rank-1\project_root\` 实际清单：

- 实体文件 **17 个**，`.gd` **11 个**；与 `PROJECT_ROOT_LAYOUT.md` §2 的 17 件映射表**逐件一致**
  （`project.godot` 1 / `scripts/` 11 / `scenes/` 2 / `data/render/` 3），无遗漏、无多余实体文件。
- 另有 1 个 §2 表未列的空目录 `scenes/world/chunks/`，与 §3 预留的 3 号真实 chunk 场景路径一致，非多余文件。
- 真跑后清理引擎生成的 `.godot\` 与 11 个 `.gd.uid`，复查文件总数回到 **17**。

### 2.2 三段构建门禁（契约 §10 / 任务书 R6 §真跑要求，对 `project_root/` 直接真跑）

`<godot>` = `D:/Godot/Godot_v4.7.2-stable_win64.exe`；`<root>` = `F:/Game/aierdengfahuan/teamwork/Rank-1/project_root`。
**直接对该目录跑，未把工程树拷到 `teamwork\` 外、未补 stub、未改任何既有件**；stdout+stderr 全量捕获到
系统临时目录 `C:\Users\62668\AppData\Local\Temp\r1_r6_gate\`（留存供复核，非交付件、不在 teamwork 内）。

| 段 | 实际命令 | EXIT | 实际输出结论 |
|---|---|---|---|
| G0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| **G1** | `<godot> --headless --path <root> --import` | `0` | `first_scan_filesystem` 5 步 DONE；`update_scripts_classes` 11 步 DONE，全局类 `QualityPreset` / `RenderProfiles` / `HybridSpriteRig` 注册成功；`loading_editor_layout` DONE。**但** `正在创建自动加载脚本……` 阶段报 9 条 `ERROR`（3 个 autoload 脚本 `File not found`，逐字见 2.3） |
| **G2** | `<godot> --headless --path <root> --check-only --script res://<f>.gd`（循环 project_root 内全部 11 个 `.gd`） | **11 条均 `0`**（非 0 退出数 = 0） | 11 个 `.gd` 全部静态解析通过，日志仅引擎 banner、无错误输出 |
| **G3** | `<godot> --headless --path <root> --quit` | `0` | 启动退出；报 9 条 `ERROR`（3 个 autoload 实例化失败）+ **9 条 `WARNING`**（`[ChunkManager] ... 加载跳过：scene_missing`），逐字见 2.3 |

### 2.3 grep 校验（关键：运行时 SCRIPT ERROR 不改退出码，必须 grep 才算通过）

对三段合并日志 `all.log`：

```
grep -n   "SCRIPT ERROR"                             → NONE
grep -niE "error|parse error|failed|warning|leaked"  → 命中见下（18 条 ERROR + 9 条 WARNING，均非 SCRIPT ERROR）
```

- **`SCRIPT ERROR` = NONE**（任务书 R6 指定 grep 项，判据通过）。
- **无 `Parse Error` / 脚本解析类 `Failed`**：G2 11 个 `.gd` 静态检查全 EXIT=0。
- G1 / G3 的 `ERROR` 共 **18 条**，全部为 3 号工位 3 个待落位 autoload 脚本缺失，按「3 个路径 × 2 段 × 3 类错误」分布。以下 9 行为三类错误模式的逐字归纳（G1 段动词为 `create`、G3 段为 `instantiate`，两措辞均在实际日志中出现）：

```
ERROR: Attempt to open script 'res://scripts/world/world_state.gd' resulted in error 'File not found'.
ERROR: Failed loading resource: res://scripts/world/world_state.gd.
ERROR: Failed to create an autoload, can't load from UID or path: res://scripts/world/world_state.gd.   [G1] / Failed to instantiate ... [G3]
ERROR: Attempt to open script 'res://scripts/core/game_events.gd' resulted in error 'File not found'.
ERROR: Failed loading resource: res://scripts/core/game_events.gd.
ERROR: Failed to create an autoload, can't load from UID or path: res://scripts/core/game_events.gd.   [G1] / Failed to instantiate ... [G3]
ERROR: Attempt to open script 'res://scripts/world/save_system.gd' resulted in error 'File not found'.
ERROR: Failed loading resource: res://scripts/world/save_system.gd.
ERROR: Failed to create an autoload, can't load from UID or path: res://scripts/world/save_system.gd.  [G1] / Failed to instantiate ... [G3]
```

（G1 段 9 条措辞为 `Failed to create an autoload`，G3 段 9 条为 `Failed to instantiate an autoload`；逐字原文见留存日志 `g1_import.log` / `g3_quit.log`。）

- G3 的 `WARNING` 共 **9 条**，均为 R2 `ChunkManager` 因 3 号真实 chunk 场景未落位而跳过加载：

```
WARNING: [ChunkManager] chunk_limgrave_-1_-1 加载跳过：scene_missing
WARNING: [ChunkManager] chunk_limgrave_0_-1 加载跳过：scene_missing
WARNING: [ChunkManager] chunk_limgrave_1_-1 加载跳过：scene_missing
WARNING: [ChunkManager] chunk_limgrave_-1_0 加载跳过：scene_missing
WARNING: [ChunkManager] chunk_limgrave_0_0 加载跳过：scene_missing
WARNING: [ChunkManager] chunk_limgrave_1_0 加载跳过：scene_missing
WARNING: [ChunkManager] chunk_limgrave_-1_1 加载跳过：scene_missing
WARNING: [ChunkManager] chunk_limgrave_0_1 加载跳过：scene_missing
WARNING: [ChunkManager] chunk_limgrave_1_1 加载跳过：scene_missing
```

每条附 `push_warning` 与 `GDScript backtrace`（定位到 `chunk_streaming.gd:_report_failure_once / _request_chunk / set_player_chunk / _bootstrap`）。

**归类结论**：上述 18 条 `ERROR` + 9 条 `WARNING` 全部源于 `PROJECT_ROOT_LAYOUT.md` §3 已登记的
**3 号跨工位依赖未落位**（3 个 autoload 真实实现 + 真实 chunk 场景），是「工程根尚未落位、依赖尚未到位」的
客观证据；**不是 `SCRIPT ERROR`、不是本工位交付件缺陷、不是语法错误**。本轮如实登记，**不宣称「工程根全绿通过」、
不伪造、不擅自补 stub 消除**（补 stub / 临时验证工程属 R5 已完成的既有验证，本轮不重做、不硬造）。

### 2.4 总自检结论

- 目录树核对：`project_root\` 17 件与映射表逐件一致。
- 三段门禁对 `project_root\` 直接真跑：G1/G2/G3 **EXIT 全 0**，G2 **11 个 `.gd` 全静态解析通过**，
  **`SCRIPT ERROR` grep = NONE**。
- 跨工位依赖缺口如实登记：3 个 autoload `ERROR`（G1/G3 各 9 条）+ 9 条 `scene_missing` WARNING，
  根因均为 3 号真实产出未落位，非脚本错误。
- 真跑可用、结论均来自实际输出，未伪造；未把工程树拷出 `teamwork\` 外，交付树清理后恢复 17 件原样。

---

## ③ 未完成项与阻塞（明确标注四项需总指挥裁决）

`任务书-R6.md` §交付清单 4 项**全部**为依赖裁决 / 超范围 / headless 限制项，本轮按硬约束**未擅自实现**，
逐项依据与建议见 `R6-待裁决登记.md`：

| # | 未完成项 | 阻塞 / 归类 | 是否需总指挥裁决 |
|---|---|---|---|
| 1 | 把 `project_root/` 落位到 `F:\Game\aierdengfahuan\` 工程根 | 工程根在 `teamwork\` 外，超「唯一可写 Rank-1 + outbox」范围；用户硬约束「绝不越界写入」「绝不伪造已落位」 | **是（需 HOST 授权，本轮为边界收口，工程根落位等待总指挥授权）** |
| 2 | headless 之外的运行期帧时间 / p99 / spike 实测 | headless 无渲染管线，无法实测；`16.67 / 33.33 ms` 为资源表目标值静态核对；需 F3 性能 HUD + 人工试玩 | **是（采数安排 / 口径需裁决；本轮未做、未伪造数值）** |
| 3 | 3 号真实实现（`WorldState`/`GameEvents`/`SaveSystem`）与真实 chunk 场景接入装配层 | 3 号产出未到位（本轮真跑 18 条 autoload ERROR + 9 条 scene_missing WARNING 为证）；属别人工位、需改既有件 | **是** |
| 4 | R5 件（`chunk_streaming_r5.gd`）接入正式装配层 | 需改 `project.godot` / `scene_router.gd`（既有件），任务书明确「需改既有件，待裁决」 | **是** |

**延续项（非本轮新增，未擅自改，供总指挥一并知悉）**：R2/R3/R4/R5 遗留待裁决（4 号 A8 `@3x` vs
本工位 `@2x` 冻结值、负坐标 chunk id 命名、`GameEvents` 最终归属、`canvas_items` vs `canvas_textures`
合法键、`config_version` 口径、`HybridSpriteRig` 与 GDExtension 全局类同名风险、`128bit` 确切含义）；
`ObjectDB leaked` WARNING（R5 已定位为 R2 `ChunkManager` 在途线程加载 + `--quit` 时序，消除方案
`--quit-after 10` 已实证，根因在既有件未擅改）；4 号 `import.json` / spritesheet / ≤256 色调色板；
GDExtension `Hybrid2D3D-Renderer` 装入；exe / apk 导出；人工试玩 / 手感 / 审美判断。

**四项均未进入实现**；`R6-待裁决登记.md` 已给出可执行建议，等待总指挥（HOST / 主 AI）裁决或授权后
方可进入下一轮。**工程根落位等待总指挥授权**。

---

## ④ 合规声明

- 只写 `F:\Game\aierdengfahuan\teamwork\Rank-1\`（`project_root\` 为其子目录）；唯一例外为按中枢协议
  在 `command_center\ai\1\outbox\` 写回执 JSON。未写 `Rank-2/3/4\`、未写 teamwork 根目录、未改总纲 / 契约 /
  历史任务书 / 群聊总线。
- **未写群聊总线**（用户硬性约束）；未自行 `git commit` / `git push`；未打开或改动 R6 之外的历史派单。
- **绝不越界**：未把 `project_root/` 拷到 `teamwork\` 外、未落位工程根、未伪造「工程根已落位」。
- **绝不编造真跑输出**：三段门禁对 `project_root/` 直接真跑，实际输出（含 18 条 `ERROR` / 9 条 `WARNING`）
  逐字登记于 §2；依赖缺失如实写阻塞，未用 R5 临时验证工程的 `R5_PASS` 冒充本轮结论。
- 零付费 / 零外部依赖：未引用付费素材、未调用付费 API、未列云服务或花费确认项。
- 默认不刺探：开工只读一次必读清单（`任务书-R6.md` / `DONE-R5.md` / `PROJECT_ROOT_LAYOUT.md` /
  `00-协作契约.md` / `00-群聊总线.md`）与本工位 `project_root\` 目录树；未扫别人工位、未轮询、未写
  探针 / 测量 / preflight 脚本。真跑日志留存于系统临时目录，非交付件、用完不进工位。
- 既有交付件不重做：R2/R3/R4/R5 件与 `project_root\` 17 件均未改内容；`PROJECT_ROOT_LAYOUT.md`
  仅纯追加 §8；真跑生成的 `.godot` / `.gd.uid` 缓存已清理、交付树恢复原样。中文 UTF-8；
  本轮未新增 `.gd`，无 Godot 4 语法改动。

## ⑤ 完成标准

`DONE-R6.md` 已写（① 本轮实际交付清单 ② 自检含三段门禁真跑实际输出结论与 `SCRIPT ERROR` grep = NONE
③ 未完成项与阻塞明确标注四项需总指挥裁决）；`R6-待裁决登记.md` 已写、落位步骤说明已补齐、
outbox 回执 JSON 已写 —— **达成**。
本轮性质为**边界收口**：四项交付清单均未擅自实现，工程根落位等待总指挥授权。
