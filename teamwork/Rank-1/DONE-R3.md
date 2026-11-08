# DONE-R3 · Rank-1（引擎架构与渲染）完成标志

> 轮次：R3（HOST 全闭环调度自动启动）｜派单：`Rank-1\任务书-R3.md`｜任务单 id：`cmd-20261109-003206-888-A1`
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`｜`--version` 实测：`4.7.2.stable.official.ed1daf0bf`（EXIT=0）
> HOST 监测只认本文件。本轮只写 `F:\Game\aierdengfahuan\teamwork\Rank-1\`，并按中枢协议另写 `command_center\ai\1\outbox\` 回执 JSON；未写其它工位 / teamwork 根目录 / 总纲 / 契约 / 任务书 / 群聊总线；未自行 git commit / push。
> 真跑结论全部来自实际输出，完整命令与日志结论见 `BUILD.md`。

---

## ① 本轮实际交付 / 更新文件清单

| # | 文件（绝对路径） | 动作 | 工程落位（`res://`） |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\teamwork\Rank-1\project.godot` | **补齐 R3 口径注释**（头部 + `[rendering]` 说明） | 工程根 `project.godot` |
| 2 | `F:\Game\aierdengfahuan\teamwork\Rank-1\build_main.gd` | **新建** | `scripts/build_main.gd` |
| 3 | `F:\Game\aierdengfahuan\teamwork\Rank-1\render_profiles.gd` | **新建**（必要附加脚本，使 `.tres` 可被引擎加载校验） | `scripts/core/render_profiles.gd` |
| 4 | `F:\Game\aierdengfahuan\teamwork\Rank-1\render_profiles.tres` | **新建**（桌面 / 移动两列对照） | `data/render/render_profiles.tres` |
| 5 | `F:\Game\aierdengfahuan\teamwork\Rank-1\BUILD.md` | **新建** | `docs/` |
| 6 | `F:\Game\aierdengfahuan\teamwork\Rank-1\DONE-R3.md` | **新建**（本文件） | — |

**对照任务书 R3 §2 的 5 类固定交付**：`project.godot` ✓、`build_main.gd` ✓、`render_profiles.tres` ✓、`BUILD.md` ✓、`DONE-R3.md` ✓ —— **5 类全部产出**。`render_profiles.gd` 是为让 `render_profiles.tres` 能被引擎加载校验而附加的必要 Resource 脚本（与 R2 附加 `quality_preset.gd` 同性质），**不替代任何固定项**。

**各件要点**

- `project.godot`：**不重做 R2 配置**（config_version=5、5 个 autoload、15 个 input action、Jolt+60、`textures/canvas_textures/default_texture_filter=0`、双档 rendering_method、`[hd2d]` 冻结值全部保留）。仅补齐 R3 口径注释：config_version `--version` 实测复核、`canvas_items`/`canvas_textures` 冲突处理依据、像素图 lossless/关 mipmaps/Nearest 三要素、Jolt+60、`[input]` 15 action 完整性、主场景自 R3 起由 `build_main.gd` 生成（手写骨架降级为结构示意）。
- `build_main.gd`：`extends SceneTree`，`_initialize()` 搭 16 节点树 → `_assign_owner()` 先叶子后父级设 owner 链（**跳过 `scene_file_path` 非空的实例化节点**，防 GLB 内联成上百 MB 文本）→ `PackedScene.pack()` → `instantiate()` 比对节点数 → **比对通过才** `ResourceSaver.save()` 生成 `res://scenes/Main.tscn`。无 `_ready` / `_process` / 信号连接 / 游戏状态；全静态类型。`_free_tree()` 后序递归释放内存节点，消除 `--script` 退出时的 RID / ObjectDB 残留。
- `render_profiles.tres`（+ `.gd`）：桌面 / 移动两列——低分辨率基准 640×360 / 480×270、常驻 chunk 9 / 4、volumetric / motes / wet_reflection / bloom 全开 / 全关、目标帧时间 16.67 / 33.33 ms、显存上限 1536 / 512 MB；数值与 R2 两份 `quality_preset_*.tres` 对齐，字段命名按 R3 任务书。
- `BUILD.md`：三段门禁命令 + 真跑实际输出结论（含 `SCRIPT ERROR` grep）+ exe / apk 导出模板前置核对清单 + 口径说明。

**R2 已产出、本轮明确不重做**：`scene_router.gd`、`camera_rig.gd`、`performance_hud.gd`、`quality_preset.gd`、`quality_preset_desktop.tres`、`quality_preset_mobile.tres`、`hybrid_2d3d_animated_sprite.gd`、`场景树骨架.tscn`、`chunk_streaming.gd`、`README.md`、`DONE-R2.md`，以及历史 `任务书.md` / `任务书-R2.md`。

---

## ② 自检结果（含真跑的实际输出结论）

### 2.1 临时验证工程（真跑载体）

- 位置：系统临时目录 `C:\Users\62668\AppData\Local\Temp\r1_r3_verify`（**不在 teamwork 内、不提交、用完即删**）。
- 放入：本工位全部交付件（`project.godot` + 8 个 `.gd` + 3 份 `.tres` + 占位 `scenes/Main.tscn`，占位为 R2 手写 `场景树骨架.tscn`，保证 import / quit 有场景可开）。
- 3 个最小依赖替身 stub（`world_state.gd` / `game_events.gd` / `save_system.gd`）：因 3 号 `WorldState` / `GameEvents` / `SaveSystem` 真实实现未到位，仅让 5 个 autoload 能加载 —— **不是探针 / 测量 / preflight 脚本，不进交付清单、用完即删**。
- 结论记录后已删除，未留在 teamwork 内。

### 2.2 三段构建门禁（契约 §10，真跑）

`<godot>` = `D:\Godot\Godot_v4.7.2-stable_win64.exe`，`<tmp>` = 上述临时工程根。

| 段 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| 0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `<godot> --headless --path <tmp> --import` | `0` | `first_scan_filesystem` / `update_scripts_classes` DONE；全局类 `QualityPreset` / `RenderProfiles` / `HybridSpriteRig` 注册成功；无 Parse Error |
| 2 | `<godot> --headless --path <tmp> --check-only --script <8 个 .gd>` | **8 条均 `0`** | `build_main.gd` / `scene_router.gd` / `quality_preset.gd` / `render_profiles.gd` / `camera_rig.gd` / `hybrid_2d3d_animated_sprite.gd` / `performance_hud.gd` / `chunk_streaming.gd` 全部静态解析通过 |
| 3 | `<godot> --headless --path <tmp> --quit` | `0` | 打开占位主场景成功；`SceneRouter._ready()` 加载两份 `quality_preset_*.tres` 成功 |

### 2.3 R3 构建脚本实跑（三段门禁之外的额外验证）

| 步 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| 4 | `<godot> --headless --path <tmp> --script res://scripts/build_main.gd` | `0` | `[build_main] BUILD_OK output=res://scenes/Main.tscn nodes=16`；`pack()`→`instantiate()` 节点数比对 `16 = 16` 通过才 `save()`；`grep -c '^\[node ' Main.tscn` = `16` 双重印证 |
| 5 | `<godot> --headless --path <tmp> --quit` | `0` | 打开 build_main.gd 生成的 16 节点主场景成功 |

### 2.4 grep 校验（关键：运行时 SCRIPT ERROR 不改退出码，必须 grep 才算通过）

对 `<tmp>/logs/` 全部日志：

```
grep -rn "SCRIPT ERROR"             <logs>  → NONE
grep -rniE "parse error|error|failed" <logs>  → NONE
```

- **SCRIPT ERROR：NONE**。
- **ERROR / Parse Error / Failed：NONE**（含首轮 G4 的 RID / ObjectDB leaked 在修正后已全部消失，见 2.5）。
- WARNING：`grep -i warning` 命中 56 行（含 `at: push_warning(...)` 与 backtrace 定位行），其中 WARNING 级消息 28 条 = 27 条 `chunk_limgrave_* 加载跳过：scene_missing`（9 个 chunk id × G3/G4/G5 三次启动）+ 1 条 `未找到 ChunkRoot`。均来自 R2 既有 `chunk_streaming.gd` 降级设计（3 号 chunk 场景未到位），**不是 SCRIPT ERROR、不影响退出码（G3/G4/G5 均 EXIT=0）**。

### 2.5 首轮真跑暴露的缺陷与修正（如实记录，未隐瞒）

首次全量真跑 **grep 未通过**，如实记录两处：

1. G1/G3/G4/G5 出现 `SCRIPT ERROR: Parse Error: Expected statement, found "/" instead.`（at `res://scripts/world/world_state.gd:2`）。根因：用 Git Bash `printf` 写验证工程 stub 时，`\n` / `\t` 里的反斜杠被 MSYS 路径转换成 `/`（文件实际为 `-> Variant:/n/treturn ...`），导致依赖替身 stub 损坏 —— **是验证载体问题，不是交付件问题**；同时实证「运行时 SCRIPT ERROR 不改退出码」：该轮 G1/G3/G4/G5 退出码仍全部为 `0`。改用 heredoc 写 stub（真实换行）后消除。
2. G4 出现 `ERROR: ... RID allocations ... leaked at exit.` 与 `WARNING: 21 ObjectDB instances were leaked at exit.`。根因：`probe.free()` 只释放 `instantiate()` 根节点、子树残留，且 `_build_tree()` 的 root 树未释放。给 `build_main.gd` 增加 `_free_tree()` 后序递归释放 probe 与 root 后，RID / ObjectDB leaked 全部消失（复跑 `ERROR=NONE`）。

修正后 `rm -rf` 清掉 `.godot` 缓存**全量复跑**，得到 2.2 / 2.3 / 2.4 的通过结果。

### 2.6 总自检结论

**三段门禁真跑通过（含 `SCRIPT ERROR` grep = NONE）**，build_main.gd 实跑生成 16 节点主场景并完成节点数比对，桌面 / 移动双档资源经 `--import` 解析与全局类注册校验；本工位 `.gd` / `.tres` / `.tscn` / `project.godot` 均为 Godot 4.7.2 合法语法、可解析可打开。真跑可用，未伪造输出。

---

## ③ 未完成项与阻塞（含待 HOST 裁决 / 口径登记）

### 3.1 未完成项（非阻塞，均如实登记）

| 项 | 说明 |
|---|---|
| 工程根 `F:\Game\aierdengfahuan\` 未建立 | 交付件为工位内文本件，供建工程根时拷贝 |
| 3 号 `WorldState` / `GameEvents` / `SaveSystem` 真实实现 | 未到位，验证工程用 stub 代替（口径：GameEvents 由 3 号实现、1 号注册） |
| 3 号 chunk 场景 / 地牢场景 / 赐福网络 | 未到位，27 条 `scene_missing` WARNING 即此；M2 验收需至少 3 个占位 chunk 场景 |
| 4 号 `import.json` / spritesheet / ≤256 色调色板 | I-5 未联调；`pose_frame_counts` 待导入流程回填 |
| GDExtension `Hybrid2D3D-Renderer` 装入与 `set_custom_aabb` 真实 API 校准 | 待 M0；脚本已有 `has_method` / 属性守卫，扩展不在时静默降级 |
| 移动端常驻 chunk 数 4 的运行时落地 | `render_profiles.tres` 写 4，但 R2 `chunk_streaming.gd` 固定 `RADIUS=1` → 9 块，运行时按档位调整半径**尚未实现（R2 遗留，未伪造已实现）** |
| exe / apk 导出 | 未实跑；导出模板 / Android SDK/NDK/JDK/keystore 的 D 盘具体路径待登记（前置核对清单见 `BUILD.md` §5），本轮不主动扫盘 |
| `build_main.gd`「跳过实例化节点」分支真实验证 | 逻辑已在 `_assign_owner()` 实现；本轮构建的树全为 `new` 节点（`scene_file_path` 为空），**跳过分支未被真实触发**，待 M0 真实 GLB 实例化装入后验证 |
| 人工试玩 / 手感 / 审美判断 | 按总纲与契约由用户亲自兜底，本轮未做 |

### 3.2 需 HOST 裁决 / 口径登记的分歧项

1. **`canvas_items` vs `canvas_textures`**：任务书 R3 §2 字面写 `rendering/textures/canvas_items/default_texture_filter=0`，但 R1 §5 第 2 项、R2 §2、契约 §5 已纠正合法键为 `canvas_textures`。本轮沿用引擎合法键 `=0`（Nearest），**未写回历史误写键**，请 HOST 确认此解释。
2. **`config_version`「按 `--version` 实测填写」口径**：`--version` 实测为引擎版本字符串 `4.7.2.stable...`，而 `config_version` 是 project.godot 格式版本整数（Godot 4.x = 5）。本轮真跑 `--version` 抄录实测值、`config_version=5` 沿用 R2 并经三段门禁验证被引擎接受，非硬编码；若要求把 `4.7.2` 填入该整数键会产出非法 `project.godot`，请确认此解释（R2 已登记同一待裁决项）。
3. **任务书 R3 §5 的群聊总线追加**：任务书要求「在 `00-群聊总线.md` 末尾追加一条 `TYPE=交付完成` 消息」，但本轮用户硬性约束明确「**不写群聊总线**、唯一可写 Rank-1 + outbox 回执」。按用户指令**未写总线**，由 HOST 统一收尾，如实登记。
4. R2 遗留待裁决（延续，未擅自改）：4 号 A8 `@3x` vs 本工位 `@2x` 冻结值、负坐标 chunk id 命名、`GameEvents` 最终归属、移动端 chunk 半径实现方式、`HybridSpriteRig` 类名与 GDExtension 全局类同名风险、`128bit` 确切含义。

---

## ④ 合规声明

- 只写 `F:\Game\aierdengfahuan\teamwork\Rank-1\`；唯一例外为按中枢协议在 `command_center\ai\1\outbox\` 写回执 JSON。未写 `Rank-2/3/4\`、未写 teamwork 根目录、未改总纲 / 契约 / 历史任务书。
- **未写群聊总线**（用户硬性约束，见 ③ 3.2 第 3 条）；未自行 `git commit` / `git push`；未打开或改动 R3 之外的历史派单。
- 零付费 / 零外部依赖：未引用付费素材、未调用 `asset-gen/api.md` 付费 API、未列云服务或花费确认项。
- 默认不刺探：开工只读一次 `00-群聊总线.md`；未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；临时 stub 仅为验证工程的依赖替身，用完即删。
- 遵守 R2 口径（`00-续派与监测规则.md` §6）：I-4 `set_pose(pose_name, frame_index)` 不扩展接口、pose 名冻结、`frame_index` 为动作内帧索引且 clamp 归 1 号；像素素材 128px + ≤256 色；负坐标 chunk id 按契约字面保留负号。
- 中文、UTF-8；`.gd` / `.tscn` / `.tres` / `project.godot` 均经 Godot 4.7.2 真跑验证为合法语法，GDScript 全静态类型。

## ⑤ 完成标准

`任务书-R3.md` §2 的 5 类固定文件全部产出、`DONE-R3.md` 存在、三段门禁真跑结论（含 `SCRIPT ERROR` grep）已记录、outbox 回执 JSON 已写 —— **达成**。
