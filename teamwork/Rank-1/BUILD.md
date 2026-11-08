# BUILD.md · Rank-1 R3（构建门禁真跑记录与导出前置核对）

> 派单：`Rank-1\任务书-R3.md` ｜ 口径：`00-协作契约.md` §10 / `00-工具链接入说明.md` §4.2
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`（标准版 4.7.2）
> 本文件记录**真跑的实际输出结论**，不伪造、不写"未找到 godot、无法真跑"的旧结论（R2 已作废）。

---

## 1. 引擎与版本实测

| 命令 | 退出码 | 实际输出 |
|---|---|---|
| `D:\Godot\Godot_v4.7.2-stable_win64.exe --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |

`config_version` 口径：`--version` 实测的是**引擎版本字符串**；`project.godot` 的 `config_version` 是**工程配置格式版本（整数）**，Godot 4.x 为 `5`。本轮据实测主版本维持 `config/features=PackedStringArray("4.7", "GL Compatibility")`，`config_version=5` 沿用 R2 并经三段门禁验证被 4.7.2 接受，未把 `4.7.2` 硬填进整数键（否则 project.godot 非法）。口径登记见 `DONE-R3.md` ③。

## 2. 三段构建门禁（契约 §10，真跑）

验证载体：系统临时目录 `C:\Users\62668\AppData\Local\Temp\r1_r3_verify`（**不在 teamwork 内、不提交、用完即删**）。放入本工位交付件（`project.godot` + 8 个 `.gd` + 3 份 `.tres` + 占位 `scenes/Main.tscn`），并为 3 号尚未交付的 `WorldState` / `GameEvents` / `SaveSystem` 放 3 个最小依赖替身 stub（**非探针 / 测量 / preflight 脚本，仅让 5 个 autoload 能加载，不进交付清单**）。

命令占位：`<godot>` = `D:\Godot\Godot_v4.7.2-stable_win64.exe`，`<tmp>` = 上述临时工程根（Windows 路径）。

| 段 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| 0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| 1 | `<godot> --headless --path <tmp> --import` | `0` | `first_scan_filesystem` 完成；全局类 `QualityPreset` / `RenderProfiles` / `HybridSpriteRig` 注册成功；`update_scripts_classes` DONE；无 Parse Error |
| 2 | `<godot> --headless --path <tmp> --check-only --script <8 个 .gd>` | **8 条均 `0`** | `build_main.gd` / `scene_router.gd` / `quality_preset.gd` / `render_profiles.gd` / `camera_rig.gd` / `hybrid_2d3d_animated_sprite.gd` / `performance_hud.gd` / `chunk_streaming.gd` 全部静态解析通过 |
| 3 | `<godot> --headless --path <tmp> --quit` | `0` | 打开占位主场景 `scenes/Main.tscn` 成功；`SceneRouter._ready()` 加载两份 `quality_preset_*.tres` 成功（无缺失警告） |

### 2.1 R3 构建脚本实跑（三段门禁之外的额外验证，非替代）

| 步 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| 4 | `<godot> --headless --path <tmp> --script res://scripts/build_main.gd` | `0` | `[build_main] BUILD_OK output=res://scenes/Main.tscn nodes=16`；`PackedScene.pack()` → `instantiate()` 节点数比对 `16 = 16` 通过 → 才 `ResourceSaver.save()`；`grep -c '^\[node ' Main.tscn` = `16`，双重印证 |
| 5 | `<godot> --headless --path <tmp> --quit` | `0` | 打开 build_main.gd 生成的 16 节点主场景成功 |

`build_main.gd`：`extends SceneTree`，仅 `_initialize()` 一次性构建后 `quit()`；先叶子后父级设 owner，`_assign_owner()` 跳过 `scene_file_path` 非空的实例化节点（防 GLB 内联）；无 `_ready` / `_process` / 信号连接 / 游戏状态；全静态类型。

## 3. grep 校验（关键：运行时 SCRIPT ERROR 不改退出码，必须 grep 才算通过）

对 `<tmp>/logs/` 全部日志：

```
grep -rn "SCRIPT ERROR"            <logs>   → NONE
grep -rniE "parse error|error|failed" <logs> → NONE
```

- **SCRIPT ERROR：NONE**。
- **`ERROR` / Parse Error / Failed：NONE**（含首轮 G4 的 RID / ObjectDB leaked 在修正后已全部消失，见 §4）。
- WARNING：`grep -i warning` 命中 56 行（含 `at: push_warning(...)` 与 backtrace 定位行），其中 WARNING 级消息 28 条 = 27 条 `chunk_limgrave_* 加载跳过：scene_missing`（9 个 chunk id × G3/G4/G5 三次启动）+ 1 条 `[ChunkManager] 未找到 ChunkRoot`。均来自 R2 既有 `chunk_streaming.gd` 的降级设计（3 号 chunk 场景 / 地牢场景未到位），**不是 SCRIPT ERROR、不影响退出码（G3/G4/G5 均 EXIT=0）**。

## 4. 首轮真跑暴露的缺陷与修正（如实记录，未隐瞒）

首次全量真跑**未通过 grep**，如实记录两处：

1. **G1/G3/G4/G5 出现 `SCRIPT ERROR: Parse Error: Expected statement, found "/" instead.`（at `res://scripts/world/world_state.gd:2`）**。根因：用 Git Bash `printf` 写验证工程的 stub 时，`\n` / `\t` 里的反斜杠被 MSYS 路径转换成了 `/`（文件内容实际为 `-> Variant:/n/treturn ...`），导致依赖替身 stub 损坏 —— **是验证载体（stub）问题，不是任何交付件的问题**；同时实证了「运行时 SCRIPT ERROR 不改退出码」：该轮 G1/G3/G4/G5 退出码仍全部为 `0`。改用 heredoc 写 stub（真实换行）后消除。
2. **G4 出现 `ERROR: ... RID allocations ... leaked at exit.` 与 `WARNING: 21 ObjectDB instances were leaked at exit.`**。根因：`probe.free()` 只释放 `instantiate()` 的根节点、子树残留，且 `_build_tree()` 的 root 树未释放。给 `build_main.gd` 增加 `_free_tree()`（后序递归：先子后父）释放 probe 与 root 后，RID / ObjectDB leaked 全部消失（复跑 `ERROR=NONE`）。

修正后 `rm -rf` 清掉 `.godot` 缓存**全量复跑**，得到 §2 / §3 的通过结果。

## 5. exe / apk 导出模板前置核对清单（契约 §9.2 / 工具链 §7）

> 当前阶段只有工位内文本件、尚无 Godot 工程根，exe / apk **未实跑导出**。以下为落地前必须逐项核对的清单；按全局「不刺探」规则，SDK / 模板路径待用户提供或明确「刺探」指令后才核对，本轮不主动扫盘。

### Windows `exe`（+ `.pck`）

- [ ] Godot 4.7.2 Windows 导出模板版本与引擎 `4.7.2.stable` **完全一致**（版本不符引擎拒绝导出）
- [ ] 导出预设 `Windows Desktop`；主场景 `run/main_scene="res://scenes/Main.tscn"` 指向 `build_main.gd` 生成物
- [ ] `.exe` / `.pck` 是否随二进制一起提交仓库待用户确认（契约 §9.1）；`build/` / `export/` 由 `.gitignore` 排除

### Android `apk`（或 `.aab`）

- [ ] Godot 4.7.2 Android 导出模板版本与引擎一致
- [ ] Android SDK / NDK / JDK 的 D 盘具体路径已登记（工具链 §7 待登记）
- [ ] debug keystore 已生成并在导出预设中配置
- [ ] 导出预设 `Android`：包名、签名、横竖屏方向
- [ ] `renderer/rendering_method.mobile="gl_compatibility"` 与移动档 `render_profiles.tres` / `quality_preset_mobile.tres` 对齐
- [ ] 像素缩放适配：480×270 缓冲 @2x、`textures/canvas_textures/default_texture_filter=0`（Nearest）、像素图 lossless / 关 mipmaps
- [ ] 移动档常驻 chunk 数 4 的**运行时降级落地**（当前 `chunk_streaming.gd` 固定 `RADIUS=1` → 9 块，未实现，见 `DONE-R3.md` ③）
- [ ] 导出 `.apk` / `.aab`

## 6. 口径说明（与任务书字面的差异，如实登记）

- **`canvas_items` vs `canvas_textures`**：任务书 R3 §2 字面写 `rendering/textures/canvas_items/default_texture_filter=0`，但 Godot 4 合法键为 `textures/canvas_textures/default_texture_filter`（R1 §5 第 2 项、R2 §2、契约 §5 均已纠正）。本轮沿用引擎合法键 `=0`（Nearest），未写回历史误写键。像素图 lossless / 关 mipmaps / Nearest 由项目级该键兜底 + 4 号 I-5 `import.json` 逐图 `.import` 落位。
- **`config_version`「实测填写」**：见 §1；已真跑 `--version` 抄录实测引擎版本，`config_version=5` 经三段门禁验证被引擎接受，非凭记忆硬编码。

---

**总自检结论**：三段门禁真跑通过（含 `SCRIPT ERROR` grep = NONE），`build_main.gd` 实跑生成 16 节点主场景并完成节点数比对，桌面 / 移动双档资源经 `--import` 解析与全局类注册校验；本工位 `.gd` / `.tres` / `.tscn` / `project.godot` 均为 Godot 4.7.2 合法语法、可解析可打开。
