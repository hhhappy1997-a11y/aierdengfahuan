# DONE-R2 · Rank-1（引擎架构与渲染）完成标志

> 轮次：R2（HOST 23:43 直接驱动）｜派单：`Rank-1\任务书-R2.md`｜口径：`00-续派与监测规则.md` §6
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`｜`--version` 实测：`4.7.2.stable.official.ed1daf0bf`
> HOST 监测只认本文件。本轮只写 `F:\Game\aierdengfahuan\teamwork\Rank-1\`，未写其它工位 / teamwork 根目录 / 总纲 / 契约 / 任务书 / 群聊总线；未 git commit / push；未打开 `任务书-R3.md`。

---

## ① 本轮实际交付 / 更新文件清单

| # | 文件（绝对路径） | 动作 | 工程落位（`res://`） |
|---|---|---|---|
| 1 | `F:\Game\aierdengfahuan\teamwork\Rank-1\project.godot` | 新建 | 工程根 `project.godot` |
| 2 | `F:\Game\aierdengfahuan\teamwork\Rank-1\scene_router.gd` | 新建 | `scripts/core/scene_router.gd`（autoload `SceneRouter`） |
| 3 | `F:\Game\aierdengfahuan\teamwork\Rank-1\camera_rig.gd` | 新建 | `scripts/render/camera_rig.gd` |
| 4 | `F:\Game\aierdengfahuan\teamwork\Rank-1\performance_hud.gd` | 新建 | `scripts/ui/performance_hud.gd` |
| 5 | `F:\Game\aierdengfahuan\teamwork\Rank-1\quality_preset_desktop.tres` | 新建 | `data/render/quality_preset_desktop.tres` |
| 6 | `F:\Game\aierdengfahuan\teamwork\Rank-1\quality_preset_mobile.tres` | 新建 | `data/render/quality_preset_mobile.tres` |
| 7 | `F:\Game\aierdengfahuan\teamwork\Rank-1\quality_preset.gd` | 新建（**附加必要脚本**） | `scripts/core/quality_preset.gd`（`class_name QualityPreset extends Resource`） |
| 8 | `F:\Game\aierdengfahuan\teamwork\Rank-1\hybrid_2d3d_animated_sprite.gd` | **更新** | `scripts/render/hybrid_2d3d_animated_sprite.gd` |
| 9 | `F:\Game\aierdengfahuan\teamwork\Rank-1\场景树骨架.tscn` | **修正 R1 遗留缺陷** | `scenes/Main.tscn` |
| 10 | `F:\Game\aierdengfahuan\teamwork\Rank-1\README.md` | **追加 §7**（§1~§6 首轮原样不改） | `docs/` |
| 11 | `F:\Game\aierdengfahuan\teamwork\Rank-1\DONE-R2.md` | 新建（本文件） | — |

**对照任务书 §2 的 8 类固定交付**：`project.godot` ✓、`scene_router.gd` ✓、`camera_rig.gd` ✓、`performance_hud.gd` ✓、`quality_preset_desktop.tres` + `quality_preset_mobile.tres` ✓、`hybrid_2d3d_animated_sprite.gd`（更新）✓、`README.md` §7 ✓、`DONE-R2.md` ✓ —— **8 类全部产出**。
`quality_preset.gd` 是为让两份 `.tres` 能被引擎加载校验而附加的必要脚本；`场景树骨架.tscn` 是真跑暴露缺陷后的修正，二者均为附加 / 修正，**不替代任何固定项**。

**各件要点**

- `project.godot`：`config_version=5`（口径见 ②）、5 个 autoload（`WorldState` / `GameEvents` / `SaveSystem` / `ChunkManager` / `SceneRouter`，按 §6 第 3 条「GameEvents 由 3 号实现、1 号注册」）、15 个 input action 映射表、`[hd2d]` 冻结值段 + 双档画质路径、`[rendering]` 使用 `textures/canvas_textures/default_texture_filter=0`（**不是 `canvas_items`**）、Jolt Physics + `physics_ticks_per_second=60`、桌面 / 移动双档 `renderer/rendering_method`。
- `scene_router.gd`：公开 `pause_chunk_stream()` / `resume_chunk_stream()` / `request_short_load(dungeon_id, direction)` / `travel_to_grace(target_grace_id)`，信号 `short_load_started` / `short_load_finished` / `grace_travel_requested` / `chunk_stream_paused` / `chunk_stream_resumed` / `quality_preset_changed`，明确「加载接口归属 1 号」（回应 3 号 A6）；`_ready()` 实际 `ResourceLoader.load` 两份 `.tres`，使第三段门禁真正覆盖 `.tres` 加载校验。
- `camera_rig.gd`：跟随（`exp` 帧率无关平滑 + 死区）、SubViewport 低分辨率缓冲与整数倍放大、`Vector3.snapped()` 整像素量化；冻结常量见 ④。
- `performance_hud.gd`：F3 性能 HUD，帧时间 / p99 / 常驻 chunk 数 / 静态内存，属交付件非临时测量脚本。
- 两份 `.tres`：桌面 640×360 / 9 chunk / FX 全开 / 16.67 ms / 1536 MB；移动 480×270 / 4 chunk / FX 全关 / 33.33 ms / 512 MB（契约 §9.2 降级档）。
- `hybrid_2d3d_animated_sprite.gd`：**不扩展 I-4 接口**（`set_pose(pose_name, frame_index)` 签名不变）；`frame_index` = 动作内帧索引、clamp 归本模块；冻结 pose 枚举 `idle/walk/run/roll/attack_light/attack_heavy/hitstun/death` + Boss `dagger_slash/staff_slam/holy_hammer` 做名称校验；前缀 `p1_`/`p2_` 沿用 `pose_prefix`，阶段切换不扩展接口。
- `场景树骨架.tscn`：R1 两处 `Transform3D(...)` 多写了 1 个参数（13 个，合法 12），已修正，详见 ②。

---

## ② 自检结果（含真跑的实际输出结论）

### 2.1 `config_version` 口径（不硬编码、不谎报）

- 真跑 `D:\Godot\Godot_v4.7.2-stable_win64.exe --version` → 实测输出 `4.7.2.stable.official.ed1daf0bf`，EXIT=0。
- `config_version` 是 Godot 工程配置的**格式版本号（整数）**，Godot 4.x 系列为 `5`，**不是引擎版本号**；不能把 `4.7.2` 填进该键，否则 `project.godot` 非法。
- 「按 `--version` 实测填写」的落实：① 据实测主版本写 `config/features=PackedStringArray("4.7", "GL Compatibility")`；② `config_version=5` 经下方三段门禁真跑验证被 4.7.2 接受（`--headless --import` / `--headless --quit` 日志无 config_version 相关警告、引擎未回写或拒绝），**不是凭记忆硬编码**。
- 该解释已同时登记在 `README.md` §7.4 待主 AI 裁决，若 HOST 口径不同按裁决回改。

### 2.2 临时验证工程（真跑载体）

- 位置：系统临时目录 `C:\Users\62668\AppData\Local\Temp\r1_r2_verify`（不在 teamwork 内、不提交）。
- 放入本工位产出的文本件（`project.godot` + 6 个 `.gd` + 2 个 `.tres` + `Main.tscn`）；因 3 号 `WorldState` / `GameEvents` / `SaveSystem` 尚未交付，验证工程内另放 **3 个最小 stub 脚本**让 5 个 autoload 能加载 —— stub **不是探针 / 测量 / preflight 脚本**，仅是依赖替身，**不进入交付清单、用完即删**。
- 结论记录后已删除：`DELETE_OK: /tmp/r1_r2_verify 已删除，未留在 teamwork 内、未提交`。

### 2.3 三段构建门禁（契约 §10 / `00-工具链接入说明.md` §4.2）

| 段 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| 0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `<godot> --headless --path <tmp> --import` | `0` | `first_scan_filesystem` 完成；全局类 `QualityPreset` / `HybridSpriteRig` 注册成功；无 Parse Error |
| 2 | `<godot> --headless --path <tmp> --check-only --script <6 个 .gd>` | **6 条均 `0`** | `scene_router.gd` / `quality_preset.gd` / `camera_rig.gd` / `hybrid_2d3d_animated_sprite.gd` / `performance_hud.gd` / `chunk_streaming.gd` 全部静态解析通过 |
| 3 | `<godot> --headless --path <tmp> --quit` | `0` | 打开 `Main.tscn` 成功；`SceneRouter._ready()` 实际加载两份 `.tres` 成功（无缺失警告） |

### 2.4 首轮真跑暴露的缺陷与修正（如实记录，未隐瞒）

首次全量真跑**未通过**，如实记录：

1. `G2` 中 `camera_rig.gd` → `SCRIPT ERROR: Parse Error: Function "expf()" not found in base self.`（`expf` 在 Godot 4.7 不存在）。已改为 `exp(...)`，并把整像素量化改用 `Vector3.snapped()` 成员方法，避免其它不确定的全局 `f` 变体函数。
2. `G1` / `G3` → `ERROR: Parse Error: Parse error. [Resource file res://scenes/Main.tscn:53]`、`ERROR: Failed loading resource: res://scenes/Main.tscn.`，`G3_QUIT_EXIT=1`。根因是 R1 遗留 `场景树骨架.tscn` 中 Camera3D 与 SunLight 两处 `Transform3D(...)` 写成 **13 个参数**（合法 12，origin 多写 1 个 `0`）。已修正为 12 参数。
3. `quality_preset_mobile.tres` 内 `;` 注释行保守移除（文本资源内注释合法性无必要冒险）。

修正后**清掉 `.godot` 缓存全量复跑**，得到 2.3 的通过结果。

### 2.5 grep 校验（关键：运行时 SCRIPT ERROR 不改退出码，必须 grep 才算通过）

- `grep -rn "SCRIPT ERROR" <logs>` → **NONE**
- `grep -rniE "parse error|error:|failed loading|warning"` → 仅 G3 的 9 条 `WARNING: [ChunkManager] chunk_limgrave_* 加载跳过：scene_missing`
- `grep -rni "error" <logs>` → **NONE**

9 条 WARNING 的由来：临时工程不含 3 号负责的 chunk 场景，`chunk_streaming.gd` 既有降级设计（每个 id 只 warn 一次）触发，**不是 SCRIPT ERROR、不影响退出码（G3 仍为 0）**。该日志同时实证负坐标 chunk id 字面形式（见 ③）。

**总自检结论：三段门禁真跑通过**，本工位 `.gd` / `.tscn` / `.tres` / `project.godot` 均为 Godot 4.7.2 合法语法、可解析可打开；R1 §4「本机未找到 godot、无法真跑」的旧结论已按 §6 第 8 条作废并纠正。

---

## ③ 未完成项与阻塞（含待 HOST 裁决）

### 3.1 未完成项（非阻塞，均如实登记）

| 项 | 说明 |
|---|---|
| 工程根 `F:\Game\aierdengfahuan\` 未建立 | 任务书 §1 明确「不建立、不写入工程根」，交付件为工位内文本件，供建工程根时拷贝 |
| 3 号 `WorldState` / `GameEvents` / `SaveSystem` 真实实现 | 未到位，验证工程用 stub 代替；真工程落地前需 3 号交付（口径 §6 第 3 条：GameEvents 由 3 号实现、1 号注册） |
| 3 号 chunk 场景 / 地牢场景 / 赐福网络 | 未到位，G3 的 9 条 `scene_missing` 即此；`request_short_load` 的 `change_scene_to_file` 目前走空跑降级；M2 验收需至少 3 个占位 chunk 场景 |
| 4 号 `import.json` / spritesheet / ≤256 色调色板 | I-5 未联调；`pose_frame_counts` 待导入流程回填，缺省时 `frame_index` 只做下限 clamp |
| GDExtension `Hybrid2D3D-Renderer` 装入与 `set_custom_aabb` 真实 API 校准 | 待 M0；脚本已有 `has_method` / 属性守卫，扩展不在时静默降级 |
| 移动端常驻 chunk 数降级落地 | `.tres` 写 4，但 R1 `chunk_streaming.gd` 固定 `RADIUS=1` → 9 块，运行时按档位调整半径**尚未实现（未伪造已实现）** |
| 人工试玩 / 手感 / 审美判断 | 按总纲与契约由用户亲自兜底，本轮未做 |
| R3 排队包 | 本轮不做，未打开 `任务书-R3.md` |

### 3.2 需 HOST 裁决的阻塞 / 分歧项

1. **4 号 A8 假设 `640×360 @3x` 与本工位冻结 `@2x` 冲突**：本工位按 R1 `场景树骨架.tscn` 的 `stretch_shrink=2` + 1280×720 窗口冻结 `640×360 @2x`，未擅自改骨架。冻结值见 ④，请 HOST 转交 4 号确认或给裁决后回改。
2. **负坐标 chunk id 命名**（任务书 §3 口径 7 要求登记）：真跑日志实证生成 `chunk_limgrave_-1_-1` / `chunk_limgrave_-1_0` / `chunk_limgrave_-1_1` 等含连字符形式；按契约字面 `chunk_<区域>_-1_0` 保留负号，**未擅自改 `_m1_`**，与 3 号存档键、4 号资产目录兼容性待裁决。
3. **`GameEvents` 归属最终裁决**：本轮按口径 §6 第 3 条（3 号实现、1 号注册）推进，最终归属仍待裁决后回改。
4. **移动端降级档的 chunk 半径实现方式**：改 `RADIUS` 还是保持 9 块只降分辨率 / 内存，待裁决（当前 `.tres` 已给降级目标值 4，运行时未落地）。
5. **`config_version` 口径确认**：见 ② 2.1；若要求把 `4.7.2` 直接填入该整数键会产出非法 `project.godot`，本轮按引擎合法格式版本 5 落地并真跑验证，请确认此解释。
6. **I-4 封装类名与 GDExtension 全局类同名风险**（R1 §5 第 3 项遗留）：本轮沿用 `HybridSpriteRig` 类名 + 场景节点名 `Hybrid2D3DAnimatedSprite`，仍待裁决。

---

## ④ 给 4 号的冻结值（单列，由 HOST 转交）

| 项 | 冻结值 | 来源 / 使用方式 |
|---|---|---|
| 低分辨率缓冲基准 | **`640 × 360`** | `camera_rig.gd::LOW_RESOLUTION_WIDTH/HEIGHT`、`project.godot [hd2d]`、桌面档 `.tres` |
| 整数放大倍数 | **`2×`**（窗口基准 `1280 × 720`，`SubViewportContainer.stretch_shrink = 2`） | `camera_rig.gd::INTEGER_UPSCALE_FACTOR`；**不采用 4 号 A8 假设的 `@3x`**，分歧见 ③ 3.2 第 1 条 |
| 像素→米缩放比（给 4 号 A4） | **`32.0 px = 1.0 m`** | 常量 `camera_rig.gd::PIXELS_PER_METER`；可取 `get_pixels_per_meter()`；与 `project.godot [hd2d]/render/pixels_per_meter` 一致 |
| 像素素材规格 | **`128px` 基准画布 + `≤256 色` 索引调色板** | 契约 §9.3 / §6 第 7 条；全项目共用一份调色板 |
| 桌面 / 移动双档差异 | 桌面 640×360 / 9 chunk / FX 全开 / 16.67 ms / 1536 MB；移动 480×270 / 4 chunk / FX 全关 / 33.33 ms / 512 MB | 两份 `quality_preset_*.tres`；4 号按此对齐视觉规范与贴图规格 |
| 冻结 pose 名（给 4 号 import.json 动作名） | `idle/walk/run/roll/attack_light/attack_heavy/hitstun/death` + Boss `dagger_slash/staff_slam/holy_hammer`，前缀 `p1_`/`p2_` | 续派规则 §6 第 6 条；`hybrid_2d3d_animated_sprite.gd::FROZEN_POSES` |

---

## ⑤ 合规声明

- 只写 `F:\Game\aierdengfahuan\teamwork\Rank-1\`；未写 `Rank-2/3/4\`、未写 teamwork 根目录、未改总纲 / 契约 / 首轮任务书 / 群聊总线。
- 未写群聊总线（回应由 HOST 统一代发，避免并发追加冲突）；未自行 `git commit` / `git push`；未打开或执行 `任务书-R3.md`。
- 零付费 / 零外部依赖：未引用付费素材、未调用 `asset-gen/api.md` 付费 API、未列云服务或花费确认项。
- 默认不刺探：开工只读一次 `00-群聊总线.md`（读到末尾）；未扫别人工位、未轮询、未写探针 / 测量 / preflight 脚本；临时 stub 仅为验证工程的依赖替身。
- 遵守 §6 统一口径：I-4 `set_pose(pose_name, frame_index)` 不扩展接口、pose 名冻结、`frame_index` 为动作内帧索引且 clamp 归 1 号；像素素材 128px + ≤256 色；负坐标 chunk id 按契约字面保留负号并登记待裁决。
- 中文、UTF-8；`.gd` / `.tscn` / `.tres` / `project.godot` 均经 Godot 4.7.2 真跑验证为合法语法，GDScript 全静态类型。
- **完成标准**：`任务书-R2.md` §2 的 8 类文件全部产出、`DONE-R2.md` 存在、三段门禁真跑结论已记录 —— 达成。
