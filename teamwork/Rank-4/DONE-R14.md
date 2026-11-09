# DONE-R14.md · Rank-4 完成报告（R14 · 地面材质资源真跑生成）

> 轮次：**R14**｜派单：`cmd-20261109-082141-612-A4`｜命令：`[ROUND=R14]`｜工位：Rank-4 美术管线与工具链｜日期：2026-11-09
> 状态：**done**（①交付清单 ②自检含回读实际输出 ③未完成项与阻塞齐备）
> 必读已读：`teamwork/Rank-4/TERRAIN-TILE.md`、`godot/assets/generated/terrain/ground_tile.png`（经 `.import` 运行期 `load()` 验证）、`teamwork/00-群聊总线.md`（**开工只读一次**）。
> 只读引用（未改）：`godot/scenes/courtyard.tscn`、`godot/project.godot`、`godot/scripts/tune_visual.gd`、`godot/scripts/build_main.gd`、`Rank-4/DONE-R13.md`、`Rank-4/调度任务单-latest.json`、`command_center/dispatcher/receipts/cmd-20261109-080019-791-A1.json`（回执格式样例）。

---

## 0. 一句话结论

用 `extends SceneTree` 脚本 `godot/scripts/build_ground_material.gd` 在 **Godot 4.7.2** 真跑生成 `godot/assets/generated/terrain/ground_material.tres`（`StandardMaterial3D`：`albedo_texture` 指向 `ground_tile.png`、`texture_filter = 0`（Nearest）、`uv1_scale = Vector3(4,4,4)`），`ResourceSaver.save()` 后用 `CACHE_MODE_IGNORE` 从磁盘重读，**类型 / 贴图引用 / 过滤值 / UV 缩放四项全通过**、绕过缓存生效、`ASSERT = ALL PASS`。三段门禁复跑 `G1 --import` / `G2 --check-only --script` / `G3 --quit` / `RUN --script` **全 EXIT=0**，`SCRIPT ERROR = 0` / `Parse Error = 0` / `ERROR = 0`。真跑同时补上 R13 遗留的枚举确认，并纠正了 R13 文档中两处与 4.7.2 不符的写法（见 §2.1）。**`courtyard.tscn` 本工位零写入**（Rank-1 本轮并发改同一场景）；`GROUND-MATERIAL.md` 只给挂载方案、不改场景。零付费 / 零外部素材 / 不自行 git / 中文 UTF-8 / 不伪造输出。

---

## 1. 交付清单

| # | 文件 | 落位 | 字节数 | 说明 |
|---|---|---|---|---|
| 1 | `build_ground_material.gd` | `godot/scripts/build_ground_material.gd` | 见文件 | `extends SceneTree`，`_initialize()` 一次性执行 + `quit(code)`；构造材质 → `ResourceSaver.save()` → `CACHE_MODE_IGNORE` 回读四项自检；只写 `.tres`，不加载 / 不保存任何场景 |
| 2 | `ground_material.tres` | `godot/assets/generated/terrain/ground_material.tres` | **249** | 主交付，由引擎 `ResourceSaver.save()` 真跑生成；sha256 `fc5cc268e69e409d89c3e41c11100d8add041d5125e74797d733812ae5cd2936` |
| 3 | `GROUND-MATERIAL.md` | `teamwork/Rank-4/GROUND-MATERIAL.md` | 见文件 | 挂载三个 `MeshInstance3D` 的完整步骤（现状核对 / 四属性成组 / UV 分档 / 两种方式 / 枚举更正 / 导入设置 / 验收清单），**只给方案不改场景** |
| 4 | `DONE-R14.md` | `teamwork/Rank-4/DONE-R14.md` | 见文件 | 本文件 |
| 5 | `cmd-20261109-082141-612-A4.json` | `teamwork/command_center/ai/4/outbox/`（中枢实时消费后见 `dispatcher/receipts/`） | 见 §2.6 | 回执 JSON，`result` 引用本报告实际结论 |

> 可写范围核对：以上均落在派单授权的 `teamwork/Rank-4/`、`godot/scripts/build_ground_material.gd`（单文件）、`godot/assets/generated/terrain/`、回执例外 `teamwork/command_center/ai/4/outbox/` 四处。`godot/.godot/` 下 `editor` / `imported` / `uid_cache.bin` / `global_script_class_cache.cfg` 的 mtime 变化是 `G1 --import` 与 `--script` 的**引擎自动缓存行为**，非本工位手动写入的源件，如实登记。

---

## 2. 自检：真跑实际 stdout（不伪造）

### 2.1 枚举真跑验证（派单「需真跑验证」的落点）

首版脚本用 `BaseMaterial3D.TEXTURE_FILTER_NEAREST` 成功，但引用 `BaseMaterial3D.TEXTURE_REPEAT_ENABLED` 时 **Parse Error**。改用 `ClassDB.class_get_integer_constant_list("BaseMaterial3D")` 核对后，运行期实际得到：

| 项 | 真跑实际值 | 结论 |
|---|---|---|
| `BaseMaterial3D.TEXTURE_FILTER_NEAREST` | **0** | 枚举合法、值为 `0`；`BaseMaterial3D` 常量清单中确有 `TEXTURE_FILTER_NEAREST` / `TEXTURE_FILTER_LINEAR` / ... / `TEXTURE_FILTER_MAX` |
| `ResourceLoader.CACHE_MODE_IGNORE` | **0** | 常量合法；与工程既有 `tune_visual.gd` 的写法一致 |
| `.tres` 落盘文本 | `texture_filter = 0` | **由 Godot 自己序列化**，运行期证实 R13 §3.3 的推断；补上 `DONE-R13.md` §3 #2「文本序列化值未实跑确认」 |
| `BaseMaterial3D` 常量清单 | **不含** `TEXTURE_REPEAT_ENABLED` | R13 §3.1 / §3.3 中 `BaseMaterial3D.TEXTURE_REPEAT_ENABLED` 与 `texture_repeat = 1` 的写法**在 4.7.2 不成立** |
| `StandardMaterial3D.texture_repeat` | **bool，默认 `true`** | 不是整数枚举；这正是首版 `%d` 打印触发 `String formatting error` 的根因。默认 `true` 表示纹理重复已启用 → **`uv1_scale` 平铺条件成立**，派单三项即足够，无需额外设置 |

> 以上两点更正已写入 `GROUND-MATERIAL.md` §3 / §4，`TERRAIN-TILE.md`（R13 历史件）按不擅改既有工位件的原则**不改原文**，只在本轮文档登记更正。

### 2.2 脚本真跑完整 stdout（`RUN --headless --script`）

命令：
`Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/build_ground_material.gd`

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==== [R14 build_ground_material] START ====
[enum] BaseMaterial3D.TEXTURE_FILTER_NEAREST = 0
[enum] ResourceLoader.CACHE_MODE_IGNORE = 0
[enum] BaseMaterial3D integer constants = ["NOTIFICATION_POSTINITIALIZE", "NOTIFICATION_PREDELETE", "NOTIFICATION_EXTENSION_RELOADED", "CONNECT_DEFERRED", "CONNECT_PERSIST", "CONNECT_ONE_SHOT", "CONNECT_REFERENCE_COUNTED", "CONNECT_APPEND_SOURCE_OBJECT", "DEEP_DUPLICATE_NONE", "DEEP_DUPLICATE_INTERNAL", "DEEP_DUPLICATE_ALL", "RENDER_PRIORITY_MAX", "RENDER_PRIORITY_MIN", "TEXTURE_ALBEDO", "TEXTURE_METALLIC", "TEXTURE_ROUGHNESS", "TEXTURE_EMISSION", "TEXTURE_NORMAL", "TEXTURE_BENT_NORMAL", "TEXTURE_RIM", "TEXTURE_CLEARCOAT", "TEXTURE_FLOWMAP", "TEXTURE_AMBIENT_OCCLUSION", "TEXTURE_HEIGHTMAP", "TEXTURE_SUBSURFACE_SCATTERING", "TEXTURE_SUBSURFACE_TRANSMITTANCE", "TEXTURE_BACKLIGHT", "TEXTURE_REFRACTION", "TEXTURE_DETAIL_MASK", "TEXTURE_DETAIL_ALBEDO", "TEXTURE_DETAIL_NORMAL", "TEXTURE_ORM", "TEXTURE_MAX", "TEXTURE_FILTER_NEAREST", "TEXTURE_FILTER_LINEAR", "TEXTURE_FILTER_NEAREST_WITH_MIPMAPS", "TEXTURE_FILTER_LINEAR_WITH_MIPMAPS", "TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC", "TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC", "TEXTURE_FILTER_MAX", "DETAIL_UV_1", "DETAIL_UV_2", "TRANSPARENCY_DISABLED", "TRANSPARENCY_ALPHA", "TRANSPARENCY_ALPHA_SCISSOR", "TRANSPARENCY_ALPHA_HASH", "TRANSPARENCY_ALPHA_DEPTH_PRE_PASS", "TRANSPARENCY_MAX", "SHADING_MODE_UNSHADED", "SHADING_MODE_PER_PIXEL", "SHADING_MODE_PER_VERTEX", "SHADING_MODE_MAX", "FEATURE_EMISSION", "FEATURE_NORMAL_MAPPING", "FEATURE_RIM", "FEATURE_CLEARCOAT", "FEATURE_ANISOTROPY", "FEATURE_AMBIENT_OCCLUSION", "FEATURE_HEIGHT_MAPPING", "FEATURE_SUBSURFACE_SCATTERING", "FEATURE_SUBSURFACE_TRANSMITTANCE", "FEATURE_BACKLIGHT", "FEATURE_REFRACTION", "FEATURE_DETAIL", "FEATURE_BENT_NORMAL_MAPPING", "FEATURE_MAX", "BLEND_MODE_MIX", "BLEND_MODE_ADD", "BLEND_MODE_SUB", "BLEND_MODE_MUL", "BLEND_MODE_PREMULT_ALPHA", "ALPHA_ANTIALIASING_OFF", "ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE", "ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE_AND_TO_ONE", "DEPTH_DRAW_OPAQUE_ONLY", "DEPTH_DRAW_ALWAYS", "DEPTH_DRAW_DISABLED", "DEPTH_TEST_DEFAULT", "DEPTH_TEST_INVERTED", "CULL_BACK", "CULL_FRONT", "CULL_DISABLED", "FLAG_DISABLE_DEPTH_TEST", "FLAG_ALBEDO_FROM_VERTEX_COLOR", "FLAG_SRGB_VERTEX_COLOR", "FLAG_USE_POINT_SIZE", "FLAG_FIXED_SIZE", "FLAG_BILLBOARD_KEEP_SCALE", "FLAG_UV1_USE_TRIPLANAR", "FLAG_UV2_USE_TRIPLANAR", "FLAG_UV1_USE_WORLD_TRIPLANAR", "FLAG_UV2_USE_WORLD_TRIPLANAR", "FLAG_AO_ON_UV2", "FLAG_EMISSION_ON_UV2", "FLAG_ALBEDO_TEXTURE_FORCE_SRGB", "FLAG_DONT_RECEIVE_SHADOWS", "FLAG_DISABLE_AMBIENT_LIGHT", "FLAG_USE_SHADOW_TO_OPACITY", "FLAG_USE_TEXTURE_REPEAT", "FLAG_INVERT_HEIGHTMAP", "FLAG_SUBSURFACE_MODE_SKIN", "FLAG_PARTICLE_TRAILS_MODE", "FLAG_ALBEDO_TEXTURE_MSDF", "FLAG_DISABLE_FOG", "FLAG_DISABLE_SPECULAR_OCCLUSION", "FLAG_USE_Z_CLIP_SCALE", "FLAG_USE_FOV_OVERRIDE", "FLAG_MAX", "DIFFUSE_BURLEY", "DIFFUSE_LAMBERT", "DIFFUSE_LAMBERT_WRAP", "DIFFUSE_TOON", "SPECULAR_SCHLICK_GGX", "SPECULAR_TOON", "SPECULAR_DISABLED", "BILLBOARD_DISABLED", "BILLBOARD_ENABLED", "BILLBOARD_FIXED_Y", "BILLBOARD_PARTICLES", "TEXTURE_CHANNEL_RED", "TEXTURE_CHANNEL_GREEN", "TEXTURE_CHANNEL_BLUE", "TEXTURE_CHANNEL_ALPHA", "TEXTURE_CHANNEL_GRAYSCALE", "EMISSION_OP_ADD", "EMISSION_OP_MULTIPLY", "DISTANCE_FADE_DISABLED", "DISTANCE_FADE_PIXEL_ALPHA", "DISTANCE_FADE_PIXEL_DITHER", "DISTANCE_FADE_OBJECT_DITHER", "STENCIL_MODE_DISABLED", "STENCIL_MODE_OUTLINE", "STENCIL_MODE_XRAY", "STENCIL_MODE_CUSTOM", "STENCIL_FLAG_READ", "STENCIL_FLAG_WRITE", "STENCIL_FLAG_WRITE_DEPTH_FAIL", "STENCIL_COMPARE_ALWAYS", "STENCIL_COMPARE_LESS", "STENCIL_COMPARE_EQUAL", "STENCIL_COMPARE_LESS_OR_EQUAL", "STENCIL_COMPARE_GREATER", "STENCIL_COMPARE_NOT_EQUAL", "STENCIL_COMPARE_GREATER_OR_EQUAL"]
[load] res://assets/generated/terrain/ground_tile.png -> (res://assets/generated/terrain/ground_tile.png):<CompressedTexture2D#-9223372008299952663>
[set] albedo_texture = (res://assets/generated/terrain/ground_tile.png):<CompressedTexture2D#-9223372008299952663>
[set] texture_filter = 0
[set] uv1_scale = (4.0, 4.0, 4.0)
[set][default] albedo_color = (1.0, 1.0, 1.0, 1.0)
[set][default] texture_repeat = true
[save] ResourceSaver.save(res://assets/generated/terrain/ground_material.tres) err = 0 (OK=0)
[save] path = res://assets/generated/terrain/ground_material.tres
==== [回读 CACHE_MODE_IGNORE] ====
[readback] class = StandardMaterial3D
[readback] resource_path = res://assets/generated/terrain/ground_material.tres
[readback] is StandardMaterial3D = true
[readback] albedo_texture non-null = true
[readback] albedo_texture class = CompressedTexture2D
[readback] albedo_texture resource_path = res://assets/generated/terrain/ground_tile.png
[readback] texture_filter = 0
[readback] texture_filter == TEXTURE_FILTER_NEAREST = true
[readback] uv1_scale = (4.0, 4.0, 4.0)
[readback][default] texture_repeat = true
[readback][default] albedo_color = (1.0, 1.0, 1.0, 1.0)
[readback] same-instance-as-saved = false (false 表示确实绕过缓存重读)
==== [R14] ASSERT = ALL PASS ====
==== [R14] RESULT=PASS ====
==== [R14 build_ground_material] END ====
WARNING: [ChunkManager] 未找到 ChunkRoot，chunk 实例暂挂本单例下。
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] _bootstrap (res://scripts/world/chunk_streaming.gd:51)
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
RUN_EXIT=0
```

**派单要求的四项回读结果**（上段 `[回读 CACHE_MODE_IGNORE]` 区）：

| 回读项 | 实际值 | 判定 |
|---|---|---|
| 类型 | `class = StandardMaterial3D`、`is StandardMaterial3D = true` | 通过 |
| `albedo_texture` 非空 | `non-null = true`，`class = CompressedTexture2D`，`resource_path = res://assets/generated/terrain/ground_tile.png` | 通过 |
| `texture_filter` 值 | `0`，`== TEXTURE_FILTER_NEAREST = true` | 通过 |
| `uv1_scale` | `(4.0, 4.0, 4.0)` | 通过 |
| （附加）绕过缓存 | `same-instance-as-saved = false` | 证明确实从磁盘重读、未命中进程缓存 |
| （附加）保存 | `err = 0 (OK=0)`、`ASSERT = ALL PASS`、`RESULT=PASS`、`EXIT=0` | 通过 |

> 末尾 2 条 `WARNING` 为工程既有 autoload（`chunk_streaming.gd` 的 `ChunkRoot` 缺失）与 `--script` 退出时的 `ObjectDB leaked`，**非本脚本引入、非 ERROR**，与 Rank-1 历轮 DONE 登记一致；`G3 --quit` 亦复现同类 WARNING，如实登记不冒充「零 WARNING」。

### 2.3 三段门禁复跑（契约 §10，最终定稿版一次连跑）

```text
===== G1 --headless --import =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] update_scripts_classes | Started 正在注册全局类…… (3 steps)
[   0% ] update_scripts_classes | 
[  25% ] update_scripts_classes | 
[  50% ] update_scripts_classes | 
[ DONE ] update_scripts_classes

[   0% ] loading_editor_layout | Started 正在加载编辑器 (5 steps)
[   0% ] loading_editor_layout | 正在加载编辑器布局……
[  16% ] loading_editor_layout | 正在加载停靠面板……
[ DONE ] loading_editor_layout

G1_EXIT=0
===== G2 --headless --check-only --script =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

G2_EXIT=0
===== G3 --headless --quit =====
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
G3_EXIT=0
===== RUN --headless --script =====
（完整 stdout 见 §2.2；末尾）ASSERT = ALL PASS / RESULT=PASS
RUN_EXIT=0
===== 日志统计 =====
LOG_LINES=72
SCRIPT_ERROR_COUNT=0
PARSE_ERROR_COUNT=0
ERROR_COUNT=0
WARNING_COUNT=3
ASSERT_PASS_COUNT=1
RESULT_PASS_COUNT=1
```

> 三段门禁 `G1 / G2 / G3` 与任务真跑 `RUN` **全部 EXIT=0**，`SCRIPT ERROR` / `Parse Error` / `ERROR` 均 `0`。`WARNING_COUNT=3` 为 `G3` 1 条 + `RUN` 2 条既有 autoload / ObjectDB 告警，非 ERROR、非本轮新增故障。

### 2.4 `.tres` 落盘内容（引擎真跑序列化，非手写）

```text
[gd_resource type="StandardMaterial3D" format=3]

[ext_resource type="Texture2D" path="res://assets/generated/terrain/ground_tile.png" id="1_cqg7n"]

[resource]
albedo_texture = ExtResource("1_cqg7n")
uv1_scale = Vector3(4, 4, 4)
texture_filter = 0
```

```text
-rw-r--r-- 1 admin 197121  249 Nov  9 08:29 godot/assets/generated/terrain/ground_material.tres
-rw-r--r-- 1 admin 197121 1495 Nov  9 08:07 godot/assets/generated/terrain/ground_tile.png
fc5cc268e69e409d89c3e41c11100d8add041d5125e74797d733812ae5cd2936 */f/Game/aierdengfahuan/godot/assets/generated/terrain/ground_material.tres
74550fc1d2ad903ebf9d03e8016810b79d44319edbb6489afb0f386b998824db */f/Game/aierdengfahuan/godot/assets/generated/terrain/ground_tile.png
```

> `albedo_color`（默认白）与 `texture_repeat`（默认 `true`）因等于默认值被 Godot 序列化时省略，这从磁盘文本侧再次印证 §2.1 的运行期结论。

### 2.5 迭代过程如实登记（不伪造「一次通过」）

| 轮次 | 动作 | 实际结果 |
|---|---|---|
| v1 首跑 | 用 `%d` 打印 `texture_repeat` | 回读四项已全 PASS、`EXIT=0`，但日志出现 **2 条 `ERROR: String formatting error: a number is required.`**（`texture_repeat` 是 bool 不是数字）。判定为脚本日志噪声，必须修 |
| v2 修正 | 追加 `BaseMaterial3D.TEXTURE_REPEAT_ENABLED` 常量做对比 | `G2 EXIT=1`、真跑 `EXIT=1`：`SCRIPT ERROR: Parse Error: Cannot find member "TEXTURE_REPEAT_ENABLED" in base "BaseMaterial3D"`。**真跑发现该成员在 4.7.2 不存在** |
| v3 定稿 | 去掉该常量引用；`texture_repeat` 改用 `print` 多参数形式；补 `ClassDB.class_get_integer_constant_list` 核对枚举名 | `G2 EXIT=0`、真跑 `EXIT=0`、无 ERROR、四项回读全 PASS |
| 最终复跑 | `G1 / G2 / G3 / RUN` 一次连跑 | 全 `EXIT=0`，统计见 §2.3 |

### 2.6 回执 JSON 真跑校验（中枢实时消费，容错）

回执写入 `command_center/ai/4/outbox/cmd-20261109-082141-612-A4.json` 后被中枢进程**实时消费**，移入 `dispatcher/receipts/cmd-20261109-082141-612-A4.json`。按「outbox 在则校验 outbox，否则校验中枢保存的同一份」容错校验，实际 stdout：

```text
=== 回执 JSON 真跑校验（容错：中枢实时消费）===
outbox_exists = False
receipts_exists = True
validated_path = F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261109-082141-612-A4.json
json_load_ok = True
keys = ['ai', 'result', 'status', 'task_id']
task_id = cmd-20261109-082141-612-A4
ai = 4  status = done
result_chars = 1499
task_id_match = True
ai_match = True
status_done = True
result_references_done = True
result_has_readback = True
ASSERT = PASS
```

> 结论：回执**已写入 outbox 且已被中枢接收**（receipts 中文件即回执本体，`json.load` 通过、四字段齐备、`task_id` 正确、`result` 引用本报告实际结论含真跑数据）。`outbox_exists = False` 是中枢消费行为，**不是未写、不是失败**；如实登记，不伪造「outbox 常驻」。

### 2.7 硬性约束逐项对照

| 约束 | 本轮实际 | 结论 |
|---|---|---|
| `extends SceneTree` 脚本真跑生成 `.tres` | `_initialize()` + `quit(code)`，沿用工程内既有 `build_main.gd` / `tune_visual.gd` 口径；4.7.2 真跑 | 通过 |
| `albedo_texture = load("res://.../ground_tile.png")` | `load()` 返回 `CompressedTexture2D`，回读 `non-null = true` | 通过 |
| `texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST`（或合法枚举，需真跑验证） | 真跑 `= 0`，合法；`.tres` 落盘 `texture_filter = 0` | 通过 |
| `uv1_scale` 让 tile 平铺 | `Vector3(4,4,4)`；`texture_repeat` 运行期默认 `true`，平铺条件成立 | 通过 |
| `ResourceSaver.save()` + `CACHE_MODE_IGNORE` 回读四项 | `err=0`；四项全通过；`same-instance-as-saved=false` 证明绕过缓存 | 通过 |
| 贴实际 stdout | §2.2 / §2.3 / §2.4 全为命令实际输出，含 v1/v2 的 ERROR 与 Parse Error 插曲 | 通过 |
| 三段门禁复跑 | `G1/G2/G3` 全 EXIT=0、`SCRIPT ERROR/Parse Error/ERROR=0` | 通过 |
| **不碰 `courtyard.tscn`** | 脚本不加载 / 不修改 / 不保存任何场景；`G1 --import` 只导入资源、不写 `.tscn`；本工位对该文件零写入（并发改动见 §3 #9） | 通过 |
| 默认不刺探 | 只读必读件 + 任务必需的 `courtyard.tscn`（只读核对节点）、既有脚本写法、任务单、回执样例；未做进度巡检、未写探针 | 通过 |
| 零付费 / 零外部素材 | 仅本机 Godot 4.7.2 + 既有 `ground_tile.png`，无网络 / 无 API / 无新增素材 | 通过 |
| ComfyUI 仍主美术路线 | 本 `.tres` 与 tile 均为程序化占位，不替代正式美术；文档与回执均声明 | 通过 |
| 中文 UTF-8 | 全部文档 / 脚本注释 / 回执 UTF-8 中文 | 通过 |
| Godot 4 合法语法 | `G2 --check-only EXIT=0`、`G1 --import` 无 Parse Error、真跑 EXIT=0 | 通过 |
| 不自行 git | 未执行任何 git 命令 | 通过 |

---

## 3. 未完成项与阻塞（如实登记，不擅自处理）

| # | 项 | 性质 | 归属 / 说明 |
|---|---|---|---|
| 1 | 材质**运行期实挂与画面效果验收** | 未实跑 | 需 Rank-1 在 `courtyard.tscn` 按 `GROUND-MATERIAL.md` 落地后重录一帧；本轮只给方案，**未臆造运行期结论** |
| 2 | 本轮只交付**一份** `ground_material.tres`（`uv1_scale = Vector3(4,4,4)`，派单示例值） | 按派单 | 三个网格要密度一致需各自 `16 / 3 / 2` 分档（`TERRAIN-TILE.md` §3.2）；复制三份 `.tres` 或按方式 B 改 `sub_resource` 属 Rank-1 装配权，本轮未擅自落三份、未伪造 uid |
| 3 | `BoxMesh` 侧面纹理拉伸 / 是否启用 `uv1_triplanar` / 移动端性能预算 | 待取舍 | Rank-1 裁决；`TERRAIN-TILE.md` §3.2 已给两种可选修正，未越界执行 |
| 4 | `.import` 的 `detect_3d/compress_to=1` 与 `TERRAIN-TILE.md` §4 建议 `=0` 的差异 | 既有待核对 | 导入配置属 Rank-1 装配权；本轮只读未改，登记备查 |
| 5 | R13 `TERRAIN-TILE.md` 中 `BaseMaterial3D.TEXTURE_REPEAT_ENABLED` / `texture_repeat = 1` 写法 | 本轮已更正 | 4.7.2 真跑证实该常量不存在、`texture_repeat` 为 bool 默认 `true`；`GROUND-MATERIAL.md` §3 / §4 给出正确写法，R13 原文按不擅改历史件原则保留 |
| 6 | 3 条既有 WARNING（ChunkManager `ChunkRoot` 缺失 / `ObjectDB leaked`） | 非阻塞 | 工程既有 autoload 行为，历轮已登记；非本脚本引入、非 ERROR，未冒充「零 WARNING」 |
| 7 | 回执被中枢**实时消费**，outbox 不常驻 | 非阻塞（已送达） | §2.6 已容错校验 receipts 中同一份通过；若 HOST 需 outbox 常驻副本，请在中枢停止消费后由 HOST 决定 |
| 8 | 正式地形美术贴图仍待 ComfyUI 主管线产出 | 长期占位状态 | 契约 §9.3：本 tile / `.tres` 为 `_draw()` 占位，不替代主路线；出图长期阻塞沿用既有登记，不谎报 |
| 9 | `courtyard.tscn` 于本轮期间被并发实例改动 | 非阻塞（已核对） | mtime `2026-11-09 08:28`（晚于 08:21:42 派单）；三个地形节点、`material_override` 的 `sub_resource` id、三个 Mesh id **逐字未变**（`StandardMaterial3D_e34af / 2x0px / l1iq4`、`PlaneMesh_15qxa`、`BoxMesh_6e1c7 / k5tdy`，尺寸 64×64 / 12×0.6×12 / 8×1.2×8 均未变），`GROUND-MATERIAL.md` 的方案片段仍对齐当前实际文件；本工位零写入、未覆盖、未回改 |
| 10 | `128bit` 歧义（128px 画布 vs 位宽 / 色深） | 既有待裁决 | 沿用 `ART-SPEC-FINAL.md` §6 待裁决口径，本轮不自行改 |
| 11 | `git commit` / `git push` | 按约束未执行 | 契约 §9.1 由主 AI 统一提交；本工位不自行 git |

> 无本轮新增阻塞导致任务失败：交付清单 5 项全部落位，硬性约束全部满足。上述均为跨工位裁决 / 运行期验收 / 长期占位 / 并发核对类登记项。

---

## 4. 合规声明

- 本工位**写入**仅限：`godot/scripts/build_ground_material.gd`、`godot/assets/generated/terrain/ground_material.tres`、`teamwork/Rank-4/DONE-R14.md`、`teamwork/Rank-4/GROUND-MATERIAL.md`、回执例外 `teamwork/command_center/ai/4/outbox/cmd-20261109-082141-612-A4.json`（中枢消费后移入 `dispatcher/receipts/`，该移动由中枢执行）。`godot/.godot/` 缓存变化为引擎自动行为，非手动写入源件。
- **本工位未写**：`godot/scenes/courtyard.tscn`、`godot/project.godot`、其它任何 `.gd` / `.tres` / `.import`、`00-群聊总线.md`、`00-协作契约.md`、`00-项目总纲.md`、`TERRAIN-TILE.md`（R13 历史件）、`ART-SPEC-FINAL.md`、其它 Rank 工位、任务书。未自行 `git commit` / `git push`。
- 零付费 / 零外部生成服务 / 零外部素材增量；ComfyUI 仍是主美术路线，本地程序化 tile 与 `.tres` 仅为地形占位；所有 stdout 真跑、不伪造、不谎报全绿；中文 UTF-8；Godot 4.7.2 合法语法。
- 开工按契约读一次 `00-群聊总线.md`，已知 R14 为地面材质资源轮次、引擎位于 `D:/Godot/Godot_v4.7.2-stable_win64.exe`、三段门禁口径、企微桥接停用、回执按 `task_id` 写入 outbox 由中枢消费；本轮未向总线追加消息（无接口变更 / 里程碑交付 / 阻塞求助 / @ 回应四类事件）。
