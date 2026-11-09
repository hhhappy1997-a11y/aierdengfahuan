# DONE-R13.md · Rank-4 完成报告（R13 画面整改 · 地形 tile）

> 轮次：**R13**｜派单：`cmd-20261109-080019-799-A4`｜命令：`[ROUND=R13]`｜工位：Rank-4 美术管线与工具链｜日期：2026-11-09
> 状态：**done**（交付清单、真跑自检、未完成项与阻塞齐备）
> 必读已读：`capture/CAPTURE-REPORT.md`（「地形无贴图纯灰」）、`teamwork/00-协作契约.md` §9.3、`teamwork/00-群聊总线.md`（开工只读一次）、`teamwork/Rank-4/ART-SPEC-FINAL.md`。
> 只读引用（未改）：`godot/scenes/courtyard.tscn`、`godot/assets/generated/palette_256.json`、`teamwork/Rank-4/调度任务单-latest.json`。

---

## 0. 一句话结论

针对 `CAPTURE-REPORT.md` §2「地形是无贴图的纯灰平面」，本轮**本地程序化**产出一张 128×128 地面 tile PNG（暖灰石土 × 冷蓝夜雾、暖金高光点缀），全局量化到 **16 色（≤256）**、P 模式索引图、`dither=NONE`、Nearest 整数倍放大不插值出新色、硬像素边；双份落位且 sha256 一致；`TERRAIN-TILE.md` 给出三个 `MeshInstance3D` 的 `StandardMaterial3D` 挂载方案，**本工位对 Rank-1 场景零写入**（期间并发改动见 §3 #9）；PNG 与 JSON 全部真跑校验通过，不伪造输出。

---

## 1. 交付清单

| # | 文件 | 落位 | 字节数 | 说明 |
|---|---|---|---|---|
| 1 | `ground_tile.png` | `godot/assets/generated/terrain/ground_tile.png` | **1495** | 主交付，`res://assets/generated/terrain/ground_tile.png` |
| 2 | `ground_tile.png` | `teamwork/Rank-4/ground_tile.png` | **1495** | 留档副本，与 #1 sha256 完全一致 |
| 3 | `gen_ground_tile.py` | `teamwork/Rank-4/gen_ground_tile.py` | 见文件 | 唯一产出工具：`_draw()` 式整数坐标像素绘制 + 量化 + 统计；固定 `seed=1304` 可复跑；仅依赖本机 Pillow |
| 4 | `TERRAIN-TILE.md` | `teamwork/Rank-4/TERRAIN-TILE.md` | 见文件 | 挂载方案：现状核对 / 四属性成组 / UV 缩放 / 三种枚举避坑 / 方式 A·B / 导入设置 / 验收清单 |
| 5 | `DONE-R13.md` | `teamwork/Rank-4/DONE-R13.md` | 见文件 | 本文件 |
| 6 | `cmd-20261109-080019-799-A4.json` | `teamwork/command_center/ai/4/outbox/` → 被中枢实时消费后现存 `teamwork/command_center/dispatcher/receipts/cmd-20261109-080019-799-A4.json` | 1217 | 回执 JSON；写入 outbox 后由中枢接收移入 receipts，内容逐字一致（详见 §2.4） |

> 可写范围核对：以上均落在 `teamwork/Rank-4/`、`godot/assets/generated/terrain/`、`teamwork/command_center/ai/4/outbox/` 三处授权范围内；`godot/assets/generated/terrain/` 为本轮新建目录（任务授权）。

---

## 2. 自检：真跑解析 / 统计实际输出

### 2.1 生成 + 量化 + 统计脚本真跑 stdout

命令：`python teamwork/Rank-4/gen_ground_tile.py`（已消除 `getdata` 弃用警告，复跑无警告）

```text
=== R13 ground_tile 真跑统计 ===
palette_id = hd2d_index_256_v1  board_colors = 32
seed = 1304
pre_quantize_unique_rgb = 46
size = (128, 128)  mode = P
palette_indices_used = 16
unique_colors = 16
file_bytes_godot = 1495
file_bytes_rank4 = 1495  copy_equal = True
all_colors_in_shared_board = True
nearest_2x_no_new_color = True
transparency = None
quantize_dither = NONE
ASSERT = ALL PASS
```

要点：底图 46 色 → 显式共享 32 色板 `quantize(dither=NONE)` 收敛到 **16 色**，是一次真实的全图量化，非直接出索引图冒称量化；所有输出色均在 `palette_256.json` 冻结 32 色内（`all_colors_in_shared_board = True`），不私加新色（契约 §9.3 / `ART-SPEC-FINAL.md` §2.2）。

### 2.2 独立复核（重新打开 PNG + `json.load` 调色板，不复用脚本内存态）

```text
=== 独立复核（重新解析，不复用生成脚本内存态） ===
png_magic_ok = True
palette_json_load_ok = True  board_colors = 32
mode = P  size = (128, 128)
palette_indices_used = 16
unique_colors = 16  <=256 = True
all_colors_in_shared_board = True
file_bytes = 1495  os_size = 1495  equal = True
nearest_2x_no_new_color = True
transparency = None
```

### 2.3 双份落位与哈希（真跑）

```text
-rw-r--r-- 1 admin 197121 1495 Nov  9 08:07 godot/assets/generated/terrain/ground_tile.png
-rw-r--r-- 1 admin 197121 1495 Nov  9 08:07 teamwork/Rank-4/ground_tile.png
74550fc1d2ad903ebf9d03e8016810b79d44319edbb6489afb0f386b998824db *godot/assets/generated/terrain/ground_tile.png
74550fc1d2ad903ebf9d03e8016810b79d44319edbb6489afb0f386b998824db *teamwork/Rank-4/ground_tile.png
```

### 2.4 回执 JSON 真跑校验（含中枢实时消费说明，如实登记）

第一次写入 `command_center/ai/4/outbox/cmd-20261109-080019-799-A4.json` 后，中枢进程**实时消费**该文件，移入 `dispatcher/receipts/cmd-20261109-080019-799-A4.json`（`Read` 复核内容与我写入的逐字一致）。为确保 outbox 交付到位，重写一次，同样被实时消费。最终采用容错校验（outbox 在则校验 outbox，否则校验中枢保存的同一份）：

```text
=== 回执 JSON 真跑校验（容错：中枢实时消费） ===
outbox_exists = False
receipts_exists = True
validated_path = dispatcher/receipts/cmd-20261109-080019-799-A4.json
json_load_ok = True
keys = ['ai', 'result', 'status', 'task_id']
task_id = cmd-20261109-080019-799-A4
ai = 4  status = done
result_chars = 678
task_id_match = True
result_references_done = True
result_has_stats = True
ASSERT = PASS
```

> 结论：回执**已写入 outbox 且已被中枢接收**（receipts 中的文件即回执本体，`json.load` 通过、字段与 `task_id` 全对）。outbox 当前为空是中枢消费行为，**不是未写、不是失败**；此项如实登记，不伪造「outbox 常驻」结论。回执 `result` 引用本报告实际结论（含 128x128 / 16 / 1495 / Nearest / sha256 等真跑数据）。

### 2.5 硬性约束逐项对照

| 约束 | 本轮实际 | 结论 |
|---|---|---|
| 本地程序化生成、零外部生成服务 | 仅 Pillow `ImageDraw` 整数坐标矩形/线/点，无网络、无 API | 通过 |
| 零付费 / 零外部依赖增量 | 无付费项；Pillow 为本机既有（12.3.0） | 通过 |
| 尺寸 128×128 | `size = (128, 128)` | 通过 |
| 全局量化 ≤256 色 | 46 色 → `quantize(dither=NONE)` → 16 色，`unique_colors = 16 <=256 = True` | 通过 |
| Nearest 适用性 / 无抗锯齿 / 硬像素边 | P 模式索引图、`dither=NONE`、无 resize/模糊/字体、2× Nearest 放大颜色集合不变、无 alpha | 通过 |
| 配色暖灰/冷蓝、HD-2D 暖金光/冷夜雾 | 取共享板 `stone_earth` / `cold_night_fog` / `warm_gold_key` / `deep_blue_ui` / `vegetation` 语义组；暖金仅作高光、冷蓝主导阴影 | 通过 |
| 统计并写出 尺寸/唯一颜色数/文件字节数 | §2.1 / §2.2 / 本报告与回执均写出实际值 | 通过 |
| 双份落位 | `godot/assets/generated/terrain/` + `teamwork/Rank-4/`，sha256 一致 | 通过 |
| 只给方案、不擅自改 Rank-1 场景 | `courtyard.tscn` **本工位零写入**（期间并发改动见 §3 #9，三个地形节点 / 材质 id 未变）；未写 `project.godot`、未写 `.gd`/`.tres`/`.import` | 通过 |
| 所有 JSON/PNG 真跑校验 | PNG 重开解析 + `json.load` 调色板 + `json.load` 回执，均通过 | 通过 |
| 不伪造输出 | 上述全部为命令实际 stdout，含弃用警告复跑、中枢消费等真实插曲 | 通过 |
| ComfyUI 仍主美术路线、tile 仅占位 | 文档与回执均声明，未宣称占位为正式素材 | 通过 |
| 默认不刺探 | 只读必读件 + 任务必需的场景/调色板/任务单；未做进度巡检、未写探针/巡检脚本（`gen_ground_tile.py` 是产出工具，其统计段属任务要求的交付自检） | 通过 |
| 不自行 git | 未执行任何 git 命令 | 通过 |
| 中文 UTF-8 | 全部文档/回执 UTF-8 中文 | 通过 |

---

## 3. 未完成项与阻塞（如实登记，不擅自处理）

| # | 项 | 性质 | 归属 / 说明 |
|---|---|---|---|
| 1 | 材质**运行期实挂与画面效果验收** | 未实跑 | 需 Rank-1 在 `courtyard.tscn` 按 `TERRAIN-TILE.md` §3 落地后重录一帧；本轮只给方案，**未臆造运行期结论**。验收清单见 `TERRAIN-TILE.md` §5 |
| 2 | `BaseMaterial3D.TEXTURE_FILTER_NEAREST` 在 Godot 4.7.2 的**文本序列化值** | 未实跑确认 | 文档以枚举名为准并提示「编辑器保存后确认」；场景里 `texture_filter = 1` 属另一枚举（CanvasItem），已在 §3.3 列三者避坑表，未照抄 |
| 3 | `BoxMesh` 侧面纹理拉伸 / 是否启用 `uv1_triplanar` 及移动端性能预算 | 待取舍 | Rank-1 裁决；`TERRAIN-TILE.md` §3.2 给出两种可选修正，未越界执行 |
| 4 | 三份 `.tres`、`.import` 是否落盘及落盘方 | 待装配 | 属 Rank-1 装配权；本轮未预置、未伪造 `uid`/`path` 等运行时值 |
| 5 | 回执被中枢**实时消费**，outbox 不常驻 | 非阻塞（已送达） | §2.4 已容错校验 receipts 中同一份通过；若 HOST 需 outbox 常驻副本，请在中枢停止消费后由 HOST 决定 |
| 6 | 正式地形美术贴图仍待 ComfyUI 主管线产出 | 长期占位状态 | 本 tile 依契约 §9.3 为 `_draw()` 占位 / 降级件，**不替代主路线**；`qwen-image` / ComfyUI 出图仍按既有长期阻塞登记，不谎报 |
| 7 | `128bit` 歧义（128px 画布 vs 位宽/色深） | 既有待裁决 | 沿用 `ART-SPEC-FINAL.md` §6 / `README.md` 待裁决口径，本轮按 128px 画布理解，不自行改口径 |
| 8 | `git commit` / `push` | 按约束未执行 | 契约 §9.1 由主 AI 统一提交；本工位不自行 git |
| 9 | `courtyard.tscn` 于本轮期间被并发实例改动 | 非阻塞（已核对） | mtime `08:04:36`：并发 Rank-1 调整镜头与暖金主光；三个地形节点 / 材质 id / Mesh id 逐字未变，方案仍适用；本工位零写入、未覆盖（详见 §4 与 `TERRAIN-TILE.md` §2） |

> 无本轮新增阻塞导致任务失败：交付清单 6 项全部落位，硬性约束全部满足。上述均为跨工位裁决 / 运行期验收 / 长期占位 / 并发核对类登记项。

---

## 4. 合规声明

- 只写 `teamwork/Rank-4/`（`ground_tile.png`、`gen_ground_tile.py`、`TERRAIN-TILE.md`、`DONE-R13.md`）、`godot/assets/generated/terrain/`（`ground_tile.png`）与回执例外 `teamwork/command_center/ai/4/outbox/`（回执已被中枢消费移入 `dispatcher/receipts/`，该移动由中枢执行、非本工位写入）。
- **本工位未写**：`godot/scenes/courtyard.tscn`、`godot/project.godot`、任何 `.gd` / `.tres` / `.import`、`00-群聊总线.md`、`00-协作契约.md`、`00-项目总纲.md`、`ART-SPEC-FINAL.md`、`palette_256.json`、其它 Rank 工位、任务书。未自行 `git commit` / `git push`。
  - **并发变更如实登记**：`courtyard.tscn` 的 mtime 为 `2026-11-09 08:04:36`（晚于 08:00:20 派单）。本轮末只读复核发现该文件由并发 Rank-1 实例调整了 `Camera3D.transform`（`0,12,18` → `0,9.6,14.4`）与 `SunLight.light_color` / `light_energy`（更暖金光、1.8），属 R13 画面整改同轮的并发改动，**非本工位写入、本工位未覆盖也未回改**。三个地形节点、其 `material_override` 的 `sub_resource` id、三个 Mesh id **逐字未变**，故 `TERRAIN-TILE.md` 的方案片段仍对齐当前实际文件（该文档 §2 已同步登记）。
- 零付费 / 零外部生成服务 / 零外部依赖增量；ComfyUI 仍是主美术路线，本地程序化 tile 仅为地形占位；所有 JSON / PNG 真跑校验、不伪造输出；中文 UTF-8。
- 开工按契约读一次 `00-群聊总线.md`，已知 R13 为「画面整改」轮次、企微桥接停用、回执按 `task_id` 写入 outbox 由中枢消费；本轮未向总线追加消息（无接口变更 / 里程碑交付 / 阻塞求助 / @ 回应四类事件）。
