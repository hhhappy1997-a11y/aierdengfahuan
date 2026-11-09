# DONE-R14 · Rank-1 引擎架构与渲染

> 命令 `cmd-20261109-082141-606-A1` · `[ROUND=R14]` · AI=1
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable.official.ed1daf0bf）
> 依据：`capture/CAPTURE-REPORT.md`（画面验收：整体偏冷灰蓝、缺暖金/冷雾对比）、`teamwork/Rank-1/DONE-R13.md`（R13 暖金主光 + 相机拉近后仍偏冷，根因是 `Environment` 的 ambient/fog 仍冷调）、`godot/scripts/tune_visual.gd`（参考其 SceneTree 追加式 pack / 回读模式）、`00-群聊总线.md`（开工只读一次）
> 本轮定位：**最小可验证整改** —— 给 `WorldEnvironment` 的 `Environment` 设暖金 ambient × 冷雾 fog 对比，节点数保持 22。

---

## ① 实际交付清单

| 类别 | 文件 | 说明 |
|---|---|---|
| 新增脚本 | `godot/scripts/tune_env.gd` | 6336 B，`extends SceneTree`，幂等；本轮整改逻辑 |
| 引擎产物 | `godot/scripts/tune_env.gd.uid` | 19 B，`--import` 自动生成（非手工创建） |
| 改动前备份 | `_archived_20261108/courtyard.tscn.bak-pre-r14` | 5234 B，`cmp` 与源文件逐字节一致 |
| 修改场景 | `godot/scenes/courtyard.tscn` | 仅 1 个内嵌 `Environment` 资源的 4 个属性，节点数不变 |
| 日志留档 | `capture/r14_tune_run.log` | 真跑落盘 + 回读 stdout |
| 日志留档 | `capture/r14_tune_idempotent.log` | 重复真跑（幂等性验证）stdout |
| 日志留档 | `capture/r14_gate_import.log` / `r14_gate_checkonly.log` / `r14_gate_quit.log` | 三段门禁 stdout |
| 日志留档 | `capture/r14_capture.log` | 画面抓帧 stdout（任务给定绝对路径命令） |
| 抓帧产出 | `capture/r1400000000.png` ~ `r1400000005.png` | 6 帧，各 43732 B，1280×720，PNG 签名合法 |
| 抓帧产出 | `capture/r14.wav` | 76844 B，Movie Maker 音频轨 |
| 交付文档 | `teamwork/Rank-1/DONE-R14.md` | 本文件 |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-082141-606-A1.json` | 按任务单 id 写入（注意在 **teamwork** 下，非工程根） |

### courtyard.tscn 具体改动（只动这些，其余零改动）

`WorldEnvironment` 节点（`SubViewportContainer/SubViewport/WorldEnvironment`）引用的内嵌 `Environment` 子资源。脚本对现有实例 `duplicate()` 一份干净副本后再设值，以确保 `pack` 把修改后的值真正序列化落盘；sub_resource id 由 `Environment_w844m` → `Environment_e34af`（引擎重新分配，仅 id 变化、无功能影响）。

| 属性 | 改前（R13 终态） | 改后（R14） | 意图 |
|---|---|---|---|
| `ambient_light_color` | `Color(0.28, 0.36, 0.52, 1)` 冷蓝 | `Color(1, 0.82, 0.6, 1)` 暖金 | 任务给定暖金色，替代冷调环境光 |
| `ambient_light_energy` | `0.6` | `0.8` | 提高能量（见下方「取值说明」） |
| `fog_enabled` | `true` | `true` | 保持启用 |
| `fog_light_color` | `Color(0.32, 0.42, 0.6, 1)` 冷蓝 | `Color(0.4, 0.55, 0.72, 1)` 冷雾 | 与暖金 ambient 形成「暖金 × 冷雾」对比 |
| `fog_density` | `0.008` | `0.008`（不显式改） | 沿用温和值，不把画面糊掉 |

- `ambient_light_source = 2`（AMBIENT_SOURCE_COLOR，暖金色真正生效）、`background_mode/color`、`tonemap_mode` 全部**零改动**，避免破坏既有天空带与色调映射。
- **其余 22 个节点本身、材质 / Mesh / 相机 / SunLight 全部零改动**（R13 已落盘的暖金主光与相机拉近原样保留，既有件不重做）。

> **取值说明（如实登记，便于总指挥裁决）**：任务举例 `ambient_light_energy` 为 `0.6`，而磁盘当前值本就是 `0.6`；为落实「提高」这一动作要求，取 `0.8`（仍低于 Godot 默认 `1.0`，属温和提高、不过曝）。若总指挥要求严格按举例值 `0.6`，只需把 `tune_env.gd` 中 `AMBIENT_ENERGY` 一行改回 `0.6` 重跑即可。所有赋值均为绝对目标值，脚本幂等。

---

## ② 自检（真跑实际输出 + 节点数）

### 2.1 真跑落盘 + `CACHE_MODE_IGNORE` 回读

命令：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/tune_env.gd` → **EXIT=0**
日志 `capture/r14_tune_run.log` 实际输出：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[TUNE_ENV] BEFORE ambient_color=(0.28, 0.36, 0.52, 1.0) ambient_energy=0.60000002384186 ambient_source=2 fog_enabled=true fog_color=(0.32, 0.42, 0.6, 1.0) fog_density=0.00800000037998
[TUNE_ENV] AFTER  ambient_color=(1.0, 0.82, 0.6, 1.0) ambient_energy=0.80000001192093 ambient_source=2 fog_enabled=true fog_color=(0.4, 0.55, 0.72, 1.0) fog_density=0.00800000037998
[TUNE_ENV] pack_err=0 nodes_before=22 nodes_after=22 expect=22
[TUNE_ENV] save_err=0
[TUNE_ENV_VERIFY] nodes=22 ambient_color=(1.0, 0.82, 0.6, 1.0) ambient_energy=0.80000001192093 ambient_source=2 fog_enabled=true fog_color=(0.4, 0.55, 0.72, 1.0) fog_density=0.00800000037998 ambient_color_ok=true ambient_energy_ok=true fog_enabled_ok=true fog_color_ok=true fog_mild_ok=true nodes_ok=true OK=true
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

- **节点数**：`pack 前 = 22`、`pack 后 = 22`、`期望 = 22`。脚本内四重门槛（`err_pack==OK`、`before==22`、`after==22`、`before==after`）全部满足才 `ResourceSaver.save`；任一不满足即 `abort save`。收尾独立复核 `grep -c "^\[node " godot/scenes/courtyard.tscn` = **22**。
- **回读**：`ResourceLoader.load("res://scenes/courtyard.tscn", "PackedScene", CACHE_MODE_IGNORE)` 绕过进程缓存从磁盘重读，`ambient_color_ok / ambient_energy_ok / fog_enabled_ok / fog_color_ok / fog_mild_ok / nodes_ok / OK` **全 true**（`fog_mild_ok` 校验 `fog_density <= 0.02`，确认雾仍温和）。
- 2 条 WARNING 为工程既有现象（SceneTree 运行时 autoload 触发 ChunkManager、退出时 ObjectDB leaked），与 R9/R10/R13 一致，**非 ERROR / 非 SCRIPT ERROR**，如实登记。

### 2.2 幂等性真跑（重复执行不叠加、字节不变）

再跑一次同一命令 → `capture/r14_tune_idempotent.log`，**EXIT=0**：

```
=== 重复真跑前 sha256 ===
d70ae5b76992a5f3552bee851cca7b701608e676ebb7938d78b75de92758f395
[TUNE_ENV] BEFORE ambient_color=(1.0, 0.82, 0.6, 1.0) ambient_energy=0.80000001192093 ... fog_color=(0.4, 0.55, 0.72, 1.0)
[TUNE_ENV] AFTER  ambient_color=(1.0, 0.82, 0.6, 1.0) ambient_energy=0.80000001192093 ... fog_color=(0.4, 0.55, 0.72, 1.0)
[TUNE_ENV] pack_err=0 nodes_before=22 nodes_after=22 expect=22
[TUNE_ENV] save_err=0
[TUNE_ENV_VERIFY] nodes=22 ... OK=true
=== 重复真跑后 sha256 ===
d70ae5b76992a5f3552bee851cca7b701608e676ebb7938d78b75de92758f395
=== 重复真跑后节点数 ===
22
```

- `BEFORE` 已是目标值、`AFTER` 无叠加、`OK=true`；**sha256 前后完全一致**（字节级幂等），节点数仍 22。绝对目标值设计 + `duplicate()` 断开缓存关联均得到验证。

### 2.3 磁盘文本复核

```
=== 磁盘节点数 ===  22
=== Environment sub_resource 段落（落盘文本）===
7:[sub_resource type="Environment" id="Environment_e34af"]
8-background_mode = 1
9-background_color = Color(0.07, 0.1, 0.16, 1)
10-ambient_light_source = 2
11-ambient_light_color = Color(1, 0.82, 0.6, 1)
12-ambient_light_energy = 0.8
13-tonemap_mode = 2
14-fog_enabled = true
15-fog_light_color = Color(0.4, 0.55, 0.72, 1)
16-fog_density = 0.008
=== WorldEnvironment 节点引用 ===
74:[node name="WorldEnvironment" ...]
75-environment = SubResource("Environment_e34af")
=== sha256 改造后 / 备份 ===
d70ae5b76992a5f3552bee851cca7b701608e676ebb7938d78b75de92758f395  .../godot/scenes/courtyard.tscn
b04685124803a980d78dfe307aa0c447d21ff0b6405e9ee2ff41df9aab1b4460  .../_archived_20261108/courtyard.tscn.bak-pre-r14
=== 与备份是否不同 ===  不同(已改动, 符合预期)
```

- 备份 `bak-pre-r14` 与改造前源 `b0468512…` 逐字节一致，改造后为 `d70ae5b7…`，确认确有改动；备份文件仍在。

### 2.4 三段门禁（真跑）

```
GATE1_IMPORT_EXIT=0      # --headless --path F:/Game/aierdengfahuan/godot --import
GATE2_CHECKONLY_EXIT=0   # --headless --path ... --check-only --script res://scripts/tune_env.gd
GATE3_QUIT_EXIT=0        # --headless --path ... --quit
########## grep SCRIPT ERROR / ERROR ##########
No matches found (0 条)
```

- `grep -n -E "SCRIPT ERROR|ERROR" capture/r14_gate_*.log` → **No matches found（0 条）**。
- `--import`：正常 5 步文件系统扫描日志，无 ERROR；自动生成 `tune_env.gd.uid`。
- `--check-only --script tune_env.gd`：日志仅版本行 → 只解析、未执行 `_initialize()`，**未误触发场景二次修改**；门禁后复查 `courtyard.tscn` sha256 仍为 `d70ae5b7…`、节点数 22，佐证幂等设计兜底生效。
- `--quit`：仅 1 条 `2 ObjectDB instances were leaked` WARNING（非 ERROR，R9/R10/R13 门禁即有），未冒充全绿。

### 2.5 画面抓帧（任务给定绝对路径命令，一次成功）

命令（任务原文，绝对路径 + `.png` 后缀）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/r14.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
```

`capture/r14_capture.log` 实际 stdout（`CAPTURE_EXIT=0`）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 616.92 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Ti

Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
--------------------------------------------------------------------------------
Done recording movie at path: F:/Game/aierdengfahuan/capture/r14.png
6 frames at 30 FPS (movie length: 00:00:00:06), recorded in 00:00:00 (100% of real-time speed).
CPU render time: 0.00 seconds (average: 0.02 ms/frame)
GPU render time: 0.00 seconds (average: 0.00 ms/frame)
Encoding time: 0.15 seconds (average: 24.51 ms/frame)
--------------------------------------------------------------------------------
```

- 渲染**可用**（OpenGL 3.3 / RTX 4060 Ti / Movie Maker 正常启用），日志 `grep -c ERROR` = **0**。
- 产出 `r1400000000.png` ~ `r1400000005.png`（6 帧，各 43732 B）+ `r14.wav`（76844 B）。
- PNG 头核验：6 张签名全部 `89504e470d0a1a0a`、尺寸全部 **1280×720**；对照 R13 `tuned00000000.png`（42326 B）同为 1280×720，本轮帧更大 → 画面内容确有变化。
- 本轮直接用任务给定的绝对路径命令，未复现 R13 那次「相对 `capture/` 被解析到 `godot/capture/`」的目录失败。

### 2.6 画面定性对比（实际查看两张 PNG，非像素精确测量）

| 观察项 | R13 旧帧 `tuned00000000.png` | R14 新帧 `r1400000000.png` |
|---|---|---|
| 两块平台色调 | **冷灰** | **明显转为暖米黄 / 卡其** |
| 天空带 / 远景雾 | 蓝色天空带 + 灰蓝渐变 | 蓝色天空带 + 灰蓝渐变（仍偏冷） |
| 中央角色 | 蓝红像素骑士 | 蓝红像素骑士（不变） |
| 整体观感 | 整体偏冷灰蓝 | 近景暖、远景冷，出现层次 |

- 诚实结论：暖金 ambient 确实生效并**可见**（平台由冷灰转暖米黄），暖近景 × 冷远景的层次已出现；但**背景整体仍偏冷、无体积光 / 光尘 / bloom / 湿地倒影，尚未完全达到「暖金主光 × 冷夜雾强对比」**。本轮按「最小可验证整改」只动 `Environment` 指定项，不冒充达标。

### 2.7 回执写入与中枢消费（如实登记）

- 回执按任务单 id 写入 `teamwork/command_center/ai/1/outbox/cmd-20261109-082141-606-A1.json`（`Write` 返回成功）。随后被调度中枢自动消费、归档到 `teamwork/command_center/dispatcher/receipts/cmd-20261109-082141-606-A1.json`（920 B）。
- 归档件经 `python json.load(encoding='utf-8')` 解析 `JSON_OK`，`task_id / ai / status` 字段断言通过，`result`（471 字符）与 `DONE-R14.md` 实际结论一致；`outbox/` 消费后清空属中枢既有正常流程（总线 `MSG-20261109-0500-HOST` 记「回执按各自 id 写入并被消费」，本轮同批 `-608-A2` / `-610-A3` / `-612-A4` 回执同样已被消费归档）。与 R13 交付惯例一致，未重写以免对共享中枢做多余动作。
- **未写到工程根 `command_center/`**（该目录不存在）；`00-群聊总线.md` 开工只读一次、未追加。

---

## ③ 未完成项与阻塞

1. **「暖金 × 冷夜雾强对比」未完全达标**：`background_color` 仍为深蓝冷调 `Color(0.07,0.1,0.16)`、地形材质为中性灰、无体积光 / bloom / 倒影 / UI。依据 R13 已确认 `project.godot` 渲染后端为 `gl_compatibility`（OpenGL 3.3），该后端不支持 `Environment` glow 后处理，无法真跑验证；本轮未写入在该后端下无效的属性以免冒充完成。要根本达标需后续调整背景色 / 地形材质 / 光源层次或升级渲染后端，超出本轮「最小整改」范围，登记为后续项。
2. **`ambient_light_energy` 取值偏离任务举例**：任务举例 `0.6`、磁盘当前值亦为 `0.6`，为落实「提高」取 `0.8`（已温和、低于默认 1.0）。已在 ① 透明登记并给出一行回改路径，供总指挥裁决，未隐瞒。
3. **角色偏小 / 构图**：R13 已做相机温和拉近，本轮按「既有件不重做」未再调整相机；如需进一步构图优化属后续项。
4. **既有 WARNING（非本轮引入、非 ERROR）**：`ChunkManager 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`，与 R9/R10/R13 记录一致，未处理、未冒充全绿。
5. **按约束未做**：默认不刺探；不写其它工位 / 总线 / 总纲 / 契约；不自行 git；零付费 / 零外部依赖；既有件不重做；`00-群聊总线.md` 开工只读一次、未追加（本轮无接口变更 / 里程碑 / 阻塞求助 / 回应 @ 事件，且总线不在可写范围）；所有文档中文 UTF-8、Godot 4 合法语法。

---

## 结论

主任务闭环：`tune_env.gd` 落盘并真跑，**节点数 pack 前/后/回读均 22**，`CACHE_MODE_IGNORE` 磁盘回读 `OK=true`（暖金 ambient `Color(1,0.82,0.6)` / energy `0.8`、`fog_enabled=true`、冷雾 `Color(0.4,0.55,0.72)`、`fog_density 0.008` 温和）；重复真跑 sha256 不变（幂等）；三段门禁 `EXIT` 全 0、`SCRIPT ERROR` / `ERROR` grep 0 条；抓帧按绝对路径命令**成功产出 6 帧 1280×720 PNG**（`ERROR=0`），画面平台由冷灰转暖米黄，暖金 ambient 可见生效。未完成项为「整体色调未完全达标」等如实登记。
回执 `status=done` 指**主任务闭环**，不代表「画面全绿达标」。

> 证据：`capture/r14_tune_run.log`、`r14_tune_idempotent.log`、`r14_gate_import.log`、`r14_gate_checkonly.log`、`r14_gate_quit.log`、`r14_capture.log`、`capture/r14000000*.png`、`_archived_20261108/courtyard.tscn.bak-pre-r14`。
