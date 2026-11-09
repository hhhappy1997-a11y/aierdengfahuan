# DONE-R13 · Rank-1 引擎架构与渲染

> 命令 `cmd-20261109-080019-791-A1` · `[ROUND=R13]` · AI=1
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable.official.ed1daf0bf）
> 依据：`capture/CAPTURE-REPORT.md`（首次真实画面验收：整体偏冷灰蓝、缺暖金主光、角色在 1280×720 里偏小）、`teamwork/00-协作契约.md`、`00-群聊总线.md`（开工只读一次）、`godot/scripts/attach_pose_frames.gd`（SceneTree 构建 / pack / 回读模式）
> 本轮定位：**最小可验证整改** —— 暖金主光 + 相机温和拉近，节点数保持 22。

---

## ① 实际交付清单

| 类别 | 文件 | 说明 |
|---|---|---|
| 新增脚本 | `godot/scripts/tune_visual.gd` | 5594 B，`extends SceneTree`，本轮整改逻辑 |
| 引擎产物 | `godot/scripts/tune_visual.gd.uid` | 19 B，`--import` 自动生成（非手工创建） |
| 修改场景 | `godot/scenes/courtyard.tscn` | 仅 2 个节点 / 3 个属性，节点数不变 |
| 改动前备份 | `_archived_20261108/courtyard.tscn.bak-pre-r13` | 5231 B，`cmp` 与源文件逐字节一致 |
| 日志留档 | `capture/r13_tune_run.log` | 真跑 + 回读 stdout |
| 日志留档 | `capture/r13_gate_import.log` / `r13_gate_checkonly.log` / `r13_gate_quit.log` | 三段门禁 stdout |
| 日志留档 | `capture/r13_capture.log` / `r13_capture_fixed.log` | 抓帧（原命令 / 路径修正）stdout |
| 抓帧产出 | `capture/tuned00000000.png` ~ `tuned00000005.png` | 6 帧，各 42326 B，1280×720 |
| 抓帧产出 | `capture/tuned.wav` | 76844 B，Movie Maker 音频轨 |
| 交付文档 | `teamwork/Rank-1/DONE-R13.md` | 本文件 |
| 回执 | `command_center/ai/1/outbox/cmd-20261109-080019-791-A1.json` | 按任务单 id 写入 |

### courtyard.tscn 具体改动（只动这些，其余零改动）

| 节点 | 属性 | 改前 | 改后 |
|---|---|---|---|
| `SubViewportContainer/SubViewport/SunLight` | `light_color` | `Color(1, 0.82, 0.55, 1)` | `Color(1, 0.78, 0.45, 1)` |
| 同上 | `light_energy` | `1.6` | `1.8` |
| `SubViewportContainer/SubViewport/Camera3D` | `transform.origin` | `(0, 12, 18)` | `(0, 9.6, 14.4)` |

- 相机只改 origin（沿指向场景中心方向约 20% 拉近，角色占比约 +25%），**basis 朝向、`fov=40`、`near/far` 全部不变**，注视点仍落在 `(0,0,~-2)` 附近，构图不破坏。
- 用绝对目标值而非相对缩放，保证脚本**幂等**（`--check-only` / 重复真跑不会叠加拉近）。
- 其余 20 个节点、`Environment` / `StandardMaterial3D` / `PlaneMesh` / `BoxMesh` 全部零改动。

---

## ② 自检（真跑实际输出 + 节点数）

### 2.1 真跑落盘 + `CACHE_MODE_IGNORE` 回读

命令：`godot --headless --path godot --script res://scripts/tune_visual.gd` → **EXIT=0**
日志 `capture/r13_tune_run.log` 实际输出：

```
[TUNE] BEFORE sun_color=(1.0, 0.82, 0.55, 1.0) sun_energy=1.60000002384186 cam_origin=(0.0, 12.0, 18.0) fov=40.0
[TUNE] AFTER  sun_color=(1.0, 0.78, 0.45, 1.0) sun_energy=1.79999995231628 cam_origin=(0.0, 9.6, 14.4) fov=40.0
[TUNE] pack_err=0 nodes_before=22 nodes_after=22 expect=22
[TUNE] save_err=0
[TUNE_VERIFY] nodes=22 sun_color=(1.0, 0.78, 0.45, 1.0) sun_energy=1.79999995231628 cam_origin=(0.0, 9.6, 14.4) color_ok=true energy_ok=true cam_ok=true nodes_ok=true OK=true
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

- **节点数**：`pack 前 = 22`、`pack 后 = 22`、`期望 = 22`，脚本内三重门槛（`err_pack==OK`、`before==22`、`after==22`、`before==after`）全部满足才 `ResourceSaver.save`；任一不满足即 `abort save`。收尾独立复核 `grep -c "^\[node " godot/scenes/courtyard.tscn` = **22**。
- **回读**：`ResourceLoader.load("res://scenes/courtyard.tscn", "PackedScene", CACHE_MODE_IGNORE)` 绕过进程缓存从磁盘重读，`color_ok / energy_ok / cam_ok / nodes_ok / OK` **全 true**。磁盘 `courtyard.tscn:62 / :70 / :71` 逐行核对一致；当前场景 sha256 `b0468512…` 与备份 `99c7c1e2…` 不同（确有改动）。
- 2 条 WARNING 为工程既有现象（SceneTree 运行时 autoload 触发 ChunkManager、退出时 ObjectDB leaked），**非 ERROR / 非 SCRIPT ERROR**，如实登记。

### 2.2 三段门禁（真跑）

```
GATE1_IMPORT_EXIT=0      # --headless --path godot --import
GATE2_CHECKONLY_EXIT=0   # --headless --path godot --check-only --script res://scripts/tune_visual.gd
GATE3_QUIT_EXIT=0        # --headless --path godot --quit
```

- `grep -E "SCRIPT ERROR|ERROR" capture/r13_gate_*.log` → **No matches found**（0 条）。
- `--import`：正常 5 步文件系统扫描日志，无 ERROR。
- `--check-only --script tune_visual.gd`：日志仅版本行 → 只解析、未执行 `_initialize()`，**未误触发场景二次修改**（幂等设计亦兜底）。
- `--quit`：仅 1 条 `2 ObjectDB instances were leaked` WARNING（非 ERROR，R9/R10 门禁即有），未冒充全绿。

### 2.3 画面抓帧（两次真跑，如实并列）

**第一次 · 按任务给定原命令** `--write-movie capture/tuned.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn`
→ 进程 **EXIT=0，但 0 个 PNG 产出**。日志 `capture/r13_capture.log` 实际输出：

```
OpenGL API 3.3.0 NVIDIA 616.92 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Ti
Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
ERROR: Condition "d.is_null()" is true. Returning: FAILED          (write_begin, movie_writer_pngwav.cpp:75)
ERROR: Condition "f_wav.is_null()" is true. Returning: ERR_UNCONFIGURED   × 6 帧 (write_frame, :145)
Done recording movie at path: F:/Game/aierdengfahuan/godot/capture/tuned.png
6 frames at 30 FPS (movie length: 00:00:00:06), recorded in 00:00:01 (100% of real-time speed).
```

- 共 **7 条 ERROR**：Godot 把相对 `capture/` 解析到工程根 `godot/capture/`（日志末行可见），该目录不存在 → 目录句柄 `d.is_null()` → `write_begin` 失败 → 6 帧 `write_frame` 全部 `ERR_UNCONFIGURED`。结尾虽自报 "6 frames"，实际 `find` 全项目无任何 `tuned*` 文件。
- 判定：这是**输出目录路径问题，不是渲染环境不可用**（GPU / OpenGL 3.3 / Movie Maker 均正常启用）。**未伪造抓帧成功**，原样留档。
- 未新建 `godot/capture/`（不在本轮可写范围），改用等价绝对路径修正。

**第二次 · 绝对路径修正** `--write-movie "F:/Game/aierdengfahuan/capture/tuned.png"`（其余参数不变）→ **EXIT=0，日志 `ERROR=0`**
日志 `capture/r13_capture_fixed.log` 实际输出：

```
OpenGL API 3.3.0 NVIDIA 616.92 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Ti
Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
Done recording movie at path: F:/Game/aierdengfahuan/capture/tuned.png
6 frames at 30 FPS (movie length: 00:00:00:06), recorded in 00:00:01 (100% of real-time speed).
CPU render time: 0.00 seconds (average: 0.01 ms/frame)
GPU render time: 0.00 seconds (average: 0.00 ms/frame)
Encoding time: 0.14 seconds (average: 23.90 ms/frame)
```

- 产出 `tuned00000000.png` ~ `tuned00000005.png`（6 帧，各 42326 B）+ `tuned.wav`（76844 B）。
- PNG 头核验：6 张全部合法 PNG、**1280×720**；对比旧帧 `frame00000000.png` 1280×720 / 39208 B。
- **抓帧结论：成功（经路径修正后）**，6 帧真实画面落盘。

### 2.4 画面定性对比（实际查看两张 PNG，非像素精确测量）

| 观察项 | 旧帧 `frame00000000.png` | 新帧 `tuned00000000.png` |
|---|---|---|
| 角色 / 平台大小 | 角色约 80px 高（验收报告），平台较小 | **明显变大**，顶部蓝色天空带变窄 → 相机拉近生效，角色占比增大 |
| 平台色调 | 冷灰 | 略偏暖灰（暖光参数已落盘） |
| 整体色调 | 冷灰蓝 | **仍偏冷灰蓝** |

- 诚实结论：相机拉近有效、暖光参数已落盘并回读确认，但**画面整体仍偏冷灰蓝，未达到"暖金主光 × 冷夜雾强对比"**。原因：`Environment` 的 `ambient_light_color (0.28,0.36,0.52)`、`fog_light_color (0.32,0.42,0.6)` 与中性灰地形材质仍为冷调，DirectionalLight 暖色被冷环境光稀释。本轮按「最小整改」未动这些项，**不冒充达标**。

---

## ③ 未完成项与阻塞

1. **glow（任务第 4 点，可选）→ 未做**。依据 `godot/project.godot:139-140`：`renderer/rendering_method="gl_compatibility"`（GL Compatibility / OpenGL 3.3）。该后端不支持 `Environment` glow 后处理，无法真跑验证效果；按任务「仅在能真跑验证时做，否则登记为未做」如实登记，**未写入在该后端下无效的 glow 属性**以免冒充完成。
2. **整体偏冷灰蓝未根本解决**：暖金主光参数已改并落盘，但环境光 / 雾 / 地形材质仍冷调。要达标需后续调整 `Environment` ambient/fog、材质反光或进一步提升暖光能量，超出本轮「最小整改」范围，登记为后续项，不擅自扩大改动。
3. **抓帧原命令相对路径问题**：任务给定命令的 `capture/tuned.png` 在本机 Godot 解析到不存在的 `godot/capture/`。本轮以绝对路径等价修正后已拿到 6 帧真实 PNG；建议后续统一用绝对路径或由有权工位预建该目录（本轮不越界创建）。
4. **既有 WARNING（非本轮引入、非 ERROR）**：`ChunkManager 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`，与 R9/R10 门禁记录一致，未处理、未冒充全绿。
5. **按约束未做**：默认不刺探、不写其它工位 / 总线 / 总纲 / 契约、不自行 git、零付费 / 零外部依赖、既有件不重做；所有文档中文 UTF-8、Godot 4 合法语法。

---

## 结论

主任务闭环：`tune_visual.gd` 落盘并真跑，**节点数 22 = 22**，`CACHE_MODE_IGNORE` 回读确认 SunLight 光色 / energy 与 Camera3D 变更落盘（`OK=true`）；三段门禁 EXIT 全 0、`SCRIPT ERROR` / `ERROR` grep 无匹配；抓帧原命令因输出目录解析失败如实留档，绝对路径修正后**成功产出 6 帧 1280×720 PNG**。glow 与「整体色调达标」为如实登记的未完成项。回执 `status=done` 指**主任务闭环**，不代表「画面全绿达标」。

> 证据：`capture/r13_tune_run.log`、`r13_gate_import.log`、`r13_gate_checkonly.log`、`r13_gate_quit.log`、`r13_capture.log`、`r13_capture_fixed.log`、`capture/tuned0000000*.png`。
