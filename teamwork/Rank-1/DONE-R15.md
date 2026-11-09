# DONE-R15 · Rank-1 引擎架构与渲染

> 命令 `cmd-20261109-083628-778-A1` · `[ROUND=R15]` · AI=1
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（v4.7.2.stable.official.ed1daf0bf）
> 依据：`Rank-4/GROUND-MATERIAL.md`（三 MeshInstance3D 材质方案）、`godot/scripts/attach_hud.gd`（HUD 实例 + pack 22→23 口径）、`godot/scripts/tune_env.gd`（SceneTree 追加式 owner 重设 / CACHE_MODE_IGNORE 回读模式）、`capture/CAPTURE-REPORT.md`（画面验收「纯灰平面 / 无任何 UI」两项差距）、`00-群聊总线.md`（开工只读一次）
> 本轮定位：**串行装配** —— 一个 `extends SceneTree` 幂等脚本同时完成「三个地形节点挂 ground_material.tres」+「hud.tscn 以实例挂到 FXLayer」，节点数 22→23。本轮只有本工位写 `godot/scenes/courtyard.tscn`。

---

## ① 实际交付清单

| 类别 | 文件 | 说明 |
|---|---|---|
| 新增脚本 | `godot/scripts/assemble_r15.gd` | `extends SceneTree`，幂等；本轮全部装配逻辑（备份/材质/HUD/owner/pack/保存/回读）串行于此一个脚本 |
| 引擎产物 | `godot/scripts/assemble_r15.gd.uid` | 20 B，`--import` 自动生成（非手工创建） |
| 改动前备份 | `_archived_20261108/courtyard.tscn.bak-pre-r15` | 5230 B；sha256 = `d70ae5b7…` 与改造前源**逐字节一致**；脚本内 `FileAccess` 幂等写入（已存在则跳过，绝不被覆盖） |
| 修改场景 | `godot/scenes/courtyard.tscn` | 22→23 节点；三个 `material_override` 指向外部材质 + 新增 HUD 实例节点段 |
| 日志留档 | `capture/r15_assemble.log` | 首次真跑落盘 + CACHE_MODE_IGNORE 回读 stdout |
| 日志留档 | `capture/r15_assemble_idempotent.log` | 幂等重跑 stdout |
| 日志留档 | `capture/r15_capture.log` | Movie Maker 抓帧 stdout（任务给定绝对路径命令） |
| 日志留档 | `capture/r15_gate_import.log` / `r15_gate_checkonly.log` / `r15_gate_quit.log` / `r15_gate_summary.log` | 三段门禁 stdout + 真实 EXIT 汇总 |
| 抓帧产出 | `capture/r1500000000.png` ~ `r1500000005.png` | 6 帧，各 74069 B，1280×720，PNG 签名合法 |
| 抓帧产出 | `capture/r15.wav` | 76844 B，Movie Maker 音频轨 |
| 交付文档 | `teamwork/Rank-1/DONE-R15.md` | 本文件 |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-083628-778-A1.json` | 按任务单 id 写入（在 **teamwork** 下，非工程根） |

### courtyard.tscn 具体改动（落盘文本实证）

```
3:[ext_resource type="Material" path="res://assets/generated/terrain/ground_material.tres" id="1_2x0px"]
7:[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="4_6e1c7"]
70:material_override = ExtResource("1_2x0px")     # GroundPlate
75:material_override = ExtResource("1_2x0px")     # TerraceLow
80:material_override = ExtResource("1_2x0px")     # TerraceHigh
85:material_override = SubResource("StandardMaterial3D_p30c5")  # CliffRim（派单未点名，保持原样）
115:[node name="Hud" type="CanvasLayer" parent="SubViewportContainer/SubViewport/FXLayer" unique_id=1276405765 instance=ExtResource("4_6e1c7")]
```

- 三个地形 `MeshInstance3D` 由原深灰纯色 `SubResource("StandardMaterial3D_e34af" / "2x0px" / "l1iq4")` 改为**同一外部材质** `ExtResource("1_2x0px")` → `ground_material.tres`（派单明确「分档 uv 可只挂同一材质，不追求差异」）。
- HUD 以 `instance=ExtResource("4_6e1c7")` 挂入 `FXLayer` 下，本场景 SceneState 只 +1 个节点段（22→23）；`hud.tscn` 内部 `HudPanel` / `TitleLabel` 由实例展开，不写入本场景。
- `pack()` 从活节点树重序列化，自动丢弃了 3 个已无引用的 `StandardMaterial3D` sub_resource（e34af / 2x0px / l1iq4，仅保留 CliffRim 的 p30c5）——这是 Godot 自身的无害清理，非手工删除，节点数不受影响。
- `Environment`（R14 暖金 ambient × 冷雾 fog）、相机 / SunLight / Mesh / 22 个既有节点及 `unique_id` 全部零改动（既有件不重做）。
- 改造前 sha256 `d70ae5b76992a5f3552bee851cca7b701608e676ebb7938d78b75de92758f395`（= R14 终态），改造后 `709f05bd1e754e0999bfe8a933828c52a3974b83c0643d43476aaa6970642fc6`，`cmp` 不同（确有改动）。

---

## ② 自检（真跑实际输出 + 节点数）

### 2.1 首次真跑落盘 + `CACHE_MODE_IGNORE` 磁盘回读

命令：`D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/assemble_r15.gd` → **EXIT=0**
`capture/r15_assemble.log` 实际 stdout（原样）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[R15] === ASSEMBLE R15 START ===
[R15] STEP1 BACKUP 写入 5230 字节 -> F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r15
[R15] STEP2 load+instantiate OK, SceneState node_count(before)=22
[R15] STEP3 material_override <- res://assets/generated/terrain/ground_material.tres | node=SubViewportContainer/SubViewport/Terrain/GroundPlate
[R15] STEP3 material_override <- res://assets/generated/terrain/ground_material.tres | node=SubViewportContainer/SubViewport/Terrain/TerraceLow
[R15] STEP3 material_override <- res://assets/generated/terrain/ground_material.tres | node=SubViewportContainer/SubViewport/Terrain/TerraceHigh
[R15] STEP4 HUD 实例已挂入 SubViewportContainer/SubViewport/FXLayer/Hud
[R15] STEP5 NODE_COUNT before=22 after=23 expected_before=22 expected_after=23 had_hud=false count_ok=true
[R15] STEP5 PROBE hud_present=true runtime_nodes=25 (实例展开后整树)
[R15] STEP5 SAVE_OK path=res://scenes/courtyard.tscn save_err=0
[R15_VERIFY] MATERIAL node=SubViewportContainer/SubViewport/Terrain/GroundPlate non_null=true res=res://assets/generated/terrain/ground_material.tres
[R15_VERIFY] MATERIAL node=SubViewportContainer/SubViewport/Terrain/TerraceLow non_null=true res=res://assets/generated/terrain/ground_material.tres
[R15_VERIFY] MATERIAL node=SubViewportContainer/SubViewport/Terrain/TerraceHigh non_null=true res=res://assets/generated/terrain/ground_material.tres
[R15_VERIFY] HUD present=true is_instance=true scene_file_path=res://scenes/hud.tscn children_ok=true
[R15_VERIFY] NODES SceneState=23 expected=23 ok=true runtime=25
[R15_VERIFY] CACHE_MODE_IGNORE 磁盘回读 OK=true
[R15] === ASSEMBLE R15 END verify_ok=true ===
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

- **节点数**：`load` 后 `get_state().get_node_count()` = **22**；`PackedScene.pack()` 后 = **23**（`before=22 after=23 count_ok=true`）。脚本以 `before==22 && after==23` 为硬门槛，任一不满足即 `push_error + quit(1)` **中止 `ResourceSaver.save()`**（本轮满足，未触发）。收尾独立复核 `grep -c "^\[node "` = **23**。
- **pack → instantiate 往返探针**：HUD 实例可展开，`HudPanel` / `TitleLabel` 齐全，运行期整树 25 节点（22 既有 + HUD 实例 1 + 内部 2，属正常实例展开，非错误）。
- **`CACHE_MODE_IGNORE` 磁盘回读**：`ResourceLoader.load(..., "PackedScene", CACHE_MODE_IGNORE)` 绕过进程缓存重读刚落盘的 `courtyard.tscn` —— 三个材质 `non_null=true`、HUD `present=true / is_instance=true / scene_file_path=res://scenes/hud.tscn / children_ok=true`、`SceneState=23 ok=true`、**`OK=true`**。
- 2 条 WARNING 为工程既有现象（autoload ChunkManager、退出时 ObjectDB leaked），与 R9~R14 一致，**非 ERROR / 非 SCRIPT ERROR**，如实登记、未冒充全绿。

### 2.2 幂等性真跑（重复执行不叠加、字节不变）

再跑一次同一命令 → `capture/r15_assemble_idempotent.log`，**EXIT=0**：

```
[R15] STEP1 BACKUP 已存在，跳过（幂等）: F:/Game/aierdengfahuan/_archived_20261108/courtyard.tscn.bak-pre-r15
[R15] STEP2 load+instantiate OK, SceneState node_count(before)=23
[R15] STEP4 HUD 已存在（幂等重跑），不重复挂入
[R15] STEP5 NODE_COUNT before=23 after=23 expected_before=23 expected_after=23 had_hud=true count_ok=true
[R15] STEP5 PROBE hud_present=true runtime_nodes=25 (实例展开后整树)
[R15] STEP5 SAVE_OK path=res://scenes/courtyard.tscn save_err=0
[R15_VERIFY] MATERIAL ... non_null=true (三节点)
[R15_VERIFY] HUD present=true is_instance=true scene_file_path=res://scenes/hud.tscn children_ok=true
[R15_VERIFY] NODES SceneState=23 expected=23 ok=true runtime=25
[R15_VERIFY] CACHE_MODE_IGNORE 磁盘回读 OK=true
[R15] === ASSEMBLE R15 END verify_ok=true ===
```

- 重跑前 sha256 `709f05bd…`、重跑后 sha256 `709f05bd…` —— **字节级完全一致**；节点数仍 23；备份 `bak-pre-r15` 仍为 `d70ae5b7…` 未被覆盖。绝对目标值 + 「HUD 已存在则跳过」+「备份已存在则跳过」三重幂等设计均验证通过。

### 2.3 磁盘文本 / 备份复核

```
=== 改造前 === 22 节点 · d70ae5b76992a5f3552bee851cca7b701608e676ebb7938d78b75de92758f395
=== 改造后 === 23 节点 · 709f05bd1e754e0999bfe8a933828c52a3974b83c0643d43476aaa6970642fc6
=== 备份   === 5230 B  · d70ae5b76992a5f3552bee851cca7b701608e676ebb7938d78b75de92758f395  (= 改造前源)
=== cmp(备份, 现场景) === 不同（已改动，符合预期）
```

### 2.4 三段门禁（一次性真跑，真实退出码）

`capture/r15_gate_summary.log`：

```
GATE1_IMPORT_EXIT=0
GATE2_CHECKONLY_EXIT=0
GATE3_QUIT_EXIT=0
########## grep -n -E 'SCRIPT ERROR|ERROR' 三段门禁日志 ##########
No matches found (0 条)
```

- `grep -n -E "SCRIPT ERROR|ERROR"` 三段日志 → **0 条**。
- `--import`：正常文件系统扫描，无 ERROR；自动生成 `assemble_r15.gd.uid`。
- `--check-only --script assemble_r15.gd`：日志仅版本行 → 只解析、未执行 `_initialize()`，**未误触发场景二次修改**；门禁后复查 `courtyard.tscn` sha256 仍 `709f05bd…`、节点数 23。
- `--quit`：仅 1 条 `2 ObjectDB instances were leaked` WARNING（非 ERROR，R9~R14 门禁即有），未冒充全绿。

### 2.5 画面抓帧（任务给定绝对路径命令，一次成功）

命令（任务原文，绝对路径 + `.png` 后缀）：

```
D:/Godot/Godot_v4.7.2-stable_win64.exe --path F:/Game/aierdengfahuan/godot --write-movie F:/Game/aierdengfahuan/capture/r15.png --fixed-fps 30 --quit-after 6 res://scenes/courtyard.tscn
```

`capture/r15_capture.log` 实际 stdout（`CAPTURE_EXIT=0`）：

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 616.92 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Ti

Movie Maker mode enabled, recording movie in 1280×720 @ 30 FPS...
--------------------------------------------------------------------------------
Done recording movie at path: F:/Game/aierdengfahuan/capture/r15.png
6 frames at 30 FPS (movie length: 00:00:00:06), recorded in 00:00:01 (100% of real-time speed).
CPU render time: 0.00 seconds (average: 0.01 ms/frame)
GPU render time: 0.00 seconds (average: 0.00 ms/frame)
Encoding time: 0.15 seconds (average: 25.69 ms/frame)
--------------------------------------------------------------------------------
```

- 渲染可用（OpenGL 3.3 / RTX 4060 Ti / Movie Maker 正常启用），`grep -c ERROR` = **0**。
- 产出 `r1500000000.png` ~ `r1500000005.png`（6 帧，各 74069 B）+ `r15.wav`（76844 B）。
- PNG 头核验：6 张签名全部 `89504e470d0a1a0a`、尺寸全部 `00000500×000002d0` = **1280×720**；对照 R14 `r1400000000.png`（43732 B）同尺寸、本轮帧更大 → 画面内容确有变化。

### 2.6 画面定性（实际查看 `r1500000000.png`，非像素精确测量）

| 观察项 | `capture/frame00000000.png`（初版纯灰） | R15 `r1500000000.png` |
|---|---|---|
| 地形 | 纯灰平面、无贴图 | **规则错缝石砖贴图清晰可见**（暖米黄 / 浅黄 / 棕砖块 + 深色硬缝），纯灰已消除 |
| HUD / UI | 无任何 UI | **深蓝底 + 金边面板 + 金字「赐福 · 宁姆格福」清晰可见**（左上） |
| 角色 | 蓝红像素骑士 | 蓝红像素骑士（不变） |
| 天空 | 蓝色天空带 | 蓝色天空带（仍偏冷） |

- 诚实结论：`CAPTURE-REPORT.md` §2 的「地形无贴图纯灰」与「没有任何 UI」两项，本轮经真跑抓帧**均已可见消除**；`GROUND-MATERIAL.md` §8 自检 1/4（有砖、贴图重复平铺）成立。但**砖块视觉大小一致性（§8 #2）未做验证/未做分档**（见 ③），BoxMesh 薄侧面纹理拉伸可见（GROUND-MATERIAL.md §4 已知取舍），且整体仍无体积光 / 光尘 / bloom / 倒影、背景仍偏冷 —— 不冒充 HD-2D 全绿达标。

---

## ③ 未完成项与阻塞

1. **UV 分档未做**：三个节点共用同一 `ground_material.tres`（`uv1_scale=Vector3(4,4,4)`），按派单「分档 uv 可只挂同一材质，不追求差异」允许。大地面砖块偏大、两平台薄侧面纹理拉伸在抓帧中可见；`GROUND-MATERIAL.md` §4 的 per-node 分档 `16/3/2` 与三平面映射（`uv1_triplanar`）均属后续优化或需 Rank-1 评估移动端性能预算，本轮按派单最小装配**未擅改、只登记**。
2. **HUD 仅静态接入、未绑数据**：本轮只按派单「实例化 hud.tscn 挂 FXLayer」完成结构装配；`WorldState` 三段式 flag 绑定、赐福菜单数据驱动、`hud.gd` 实装属 Rank-3 R15 方案（`HUD-BINDING.md`）/ R16 后续轮次，本轮未写 `hud.gd`、未改 `hud.tscn`、未绑任何运行期数据。
3. **画面整体仍未达总纲 HD-2D 强对比**：无体积光 / 光尘 / 湿地倒影 / bloom，背景 `background_color` 仍深蓝冷调。承 R14 结论 `gl_compatibility`（OpenGL 3.3）后端不支持 `Environment` glow；替代方案属 Rank-4 R15（`HD2D-FX-PLAN.md`）范围，本轮不在其内，不冒充全绿。
4. **CliffRim 未点名、保持原材质**（`SubResource("StandardMaterial3D_p30c5")`）：严格守住派单「三个 MeshInstance3D」范围，未擅自扩展。
5. **既有 WARNING（非本轮引入、非 ERROR）**：`ChunkManager 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`，与 R9~R14 记录一致，未处理、未冒充全绿。
6. **按约束未做 / 边界**：默认不刺探（仅只读必读件与本工位/中枢自身回执路由）；零付费 / 零外部素材 / 零外部生成服务；既有件不重做（`attach_hud.gd` / `tune_env.gd` / `build_ground_material.gd` 等仅作参考，未重跑、未改）；不伪造输出、不冒充全绿；中文 UTF-8、Godot 4.7.2 合法语法；不写其它工位 / 总线 / 总纲 / 契约 / 任务书；不自行 `git commit` / `git push`；`00-群聊总线.md` 开工只读一次、未追加（本轮无接口变更 / 里程碑 / 阻塞求助 / 回应 @ 事件，且总线不在可写范围）。

---

## 结论

主任务闭环：`assemble_r15.gd` 落盘并真跑，**节点数 pack 前 22 / pack 后 23 / CACHE_MODE_IGNORE 磁盘回读 23**，三材质 `non_null=true`、HUD 实例 `present=true is_instance=true children_ok=true`、`OK=true`；重复真跑 sha256 不变（字节级幂等）、备份未被覆盖；三段门禁真实 EXIT `0/0/0`、`SCRIPT ERROR` / `ERROR` grep **0 条**；抓帧按绝对路径命令**一次成功产出 6 帧 1280×720 PNG**（`ERROR=0`），画面中地形石砖贴图与 HUD 金线深蓝面板均清晰可见，`CAPTURE-REPORT.md` 的「纯灰平面」「无 UI」两项已可见消除。未完成项为 UV 分档 / HUD 数据绑定 / 整体光效等，如实登记。

`status=done` 指**本轮装配主任务闭环**，不代表「画面 HD-2D 全绿达标」。

> 证据：`capture/r15_assemble.log`、`r15_assemble_idempotent.log`、`r15_capture.log`、`r15_gate_import.log`、`r15_gate_checkonly.log`、`r15_gate_quit.log`、`r15_gate_summary.log`、`capture/r15000000*.png`、`_archived_20261108/courtyard.tscn.bak-pre-r15`。
