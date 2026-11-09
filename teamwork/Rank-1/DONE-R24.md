# DONE-R24 · Rank-1 交付（cmd-20261109-205253-697-A1 / [ROUND=R24] / v0.2.0 P0）

- 执行 AI：Rank-1（引擎架构与渲染）
- 工程根：`F:/Game/aierdengfahuan`；引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）
- 结论速览：把 `res://scenes/encounter_v010.tscn` 以 **instance 占位**接进 `godot/scenes/courtyard.tscn`，战斗状态 Label 用 instance 属性覆盖移到屏幕底部；三段门禁与四个 verify 全绿；抓帧目视「战斗 HUD（含 Boss HP）出现、既有深蓝夜景/视差远景/金线深蓝 HUD/画质面板不回退」。但 **Boss 仍无可见像素形象，未达 HD-2D 全绿**（如实登记，见 §5）。

---

## 1. 实际交付清单（改动文件）

| 文件 | 动作 | 说明 |
|---|---|---|
| `godot/scenes/courtyard.tscn` | 覆写（唯一可写既有场景） | 27 → 29 节点；新增 encounter instance 占位 + StatusLabel 内部覆盖段 |
| `godot/scripts/combat/build_courtyard_v020.gd` | 新建 | `extends SceneTree` 构建脚本（本轮唯一新增脚本） |
| `teamwork/Rank-1/courtyard.tscn.r24.bak` | 新建 | 原始 27 节点串行备份（6809 bytes） |
| `capture/v020_courtyard_00000000..14.png`（15 帧）+ `v020_courtyard_.wav` | 新建 | Movie Maker 抓帧产物（任务单 ④ 指定前缀） |
| `teamwork/Rank-1/r24_*.log` | 新建 | 真跑日志：构建 1 / 门禁 7 / verify 4 / courtyard 运行时 1 / 抓帧 1 |
| `teamwork/Rank-1/DONE-R24.md` | 新建 | 本文 |
| `teamwork/command_center/ai/1/outbox/cmd-20261109-205253-697-A1.json` | 新建 | 回执 |

**零写入**：`project.godot`、`encounter_v010.tscn`、`encounter_director.gd`、既有战斗件、任何 PNG/tres 美术资源、其它 Rank 目录的既有文件。`capture/` 仅新建任务单 ④ 指定前缀 `v020_courtyard*` 文件，未触碰 Rank-4 既有文件。

**回执路径与中枢收件（如实登记）**：回执 JSON 已按任务单写到精确路径 `teamwork/command_center/ai/1/outbox/cmd-20261109-205253-697-A1.json`（写入两次、内容一致、JSON 合法）。调度中枢的 dispatcher 收件器是实时的，两次写入后该文件都被立即移走，现实际落位为 `teamwork/command_center/dispatcher/receipts/cmd-20261109-205253-697-A1.json`（1162 bytes，21:08，内容与所写完全一致），`ai/1/status.json` 已登记 `completed=35 / last_seen 21:08:53`。历史 35 轮回执均落在 `dispatcher/receipts/`、`outbox` 常态为空，属该工程既有收件设计，非写入失败；故不再重复写入以免制造重复回执。

---

## 2. 构建脚本串行流程与节点数如实登记

`build_courtyard_v020.gd` 真跑日志 `r24_build_courtyard_v020.log`（`EXIT=0`，`END ok=true`）：

```
BACKUP already_exists keep_original_baseline path=.../courtyard.tscn.r24.bak
BASELINE disk_nodes=27（当前 courtyard 如实登记，未冒充）
INSTANTIATE runtime_nodes_before=40
HUD_OVERRIDE HUD/StatusLabel offset=(24,660)-(1224,692) no_overlap=true
ATTACH parent=Courtyard instance_path=res://scenes/encounter_v010.tscn runtime_nodes_after_add=46 added=6
NODE_COUNT before=40 after_add=46 after_pack=46 pack_err=0
SAVED path=res://scenes/courtyard.tscn err=0
OVERRIDE_SEGMENT appended ok=true
READBACK disk_nodes=29 baseline=27 instances=[Hud:hud.tscn | HD2DFX:hd2d_fx.tscn | QualitySettings:quality_settings.tscn | EncounterRoot:encounter_v010.tscn]
READBACK runtime_nodes=46 enc_instance=true enc_subtree=6 label_y=660 hud_bottom_ok=true legacy_instances_intact=true
END ok=true
```

节点数如实登记（口径区分清楚，不拿一个数冒充另一个）：

| 口径 | 数值 |
|---|---|
| 原始 courtyard 磁盘 `SceneState.get_node_count()` | **27**（R22/R23 日志同为 27；未冒充） |
| 原始 courtyard 运行时 `instantiate()` 树 | 40（27 条目中 3 个 instance 展开为 hud 3 / hd2d_fx 5 / quality_settings 9 个节点） |
| 挂入 encounter（6 节点）后运行时 | 46 |
| `PackedScene.pack()` 前后比对 | 40 → 46 → 46，`pack_err=0`（无静默丢节点） |
| 保存后 `CACHE_MODE_IGNORE` 回读磁盘 `disk_nodes` | **29** = 27 + 1 个 instance 占位 + 1 个 instance 内部覆盖段 |
| 回读 `instantiate()` 运行时节点 | 46；encounter 子树 6；`label_y=660` |

回读枚举到 **4 个 instance 引用**齐全（Hud / HD2DFX / QualitySettings / EncounterRoot），原有 3 个 `scene_file_path` 非空 = **未被内联展开**，`legacy_instances_intact=true`。`verify_quality_interaction.gd` 独立回读也打印 `SceneState_node_count=29`。

**Godot 4.7 真跑结论（如实登记，非伪造）**：`--script` 模式下 `PackedScene.pack()` 会正确写出 instance 占位，但**不会**把实例内部子节点 `StatusLabel` 的属性差异写成 instance 内部覆盖段 —— 首轮回读 `label_y` 仍是源值 20；把该 Label 的 `owner` 改指主场景根也不生效。故脚本在 `ResourceSaver.save()` 之后按 Godot 4 `.tscn` 标准格式追加一条 instance 内部覆盖段，再由 `CACHE_MODE_IGNORE` 真跑回读校验 `label_y=660` 生效。`encounter_v010.tscn` 源文件始终零改动。

与原始备份的 `diff` 显示改动最小化：仅新增 3 条 `ext_resource`（`quality_settings.gd` / `encounter_v010.tscn` / `encounter_director.gd`）、`QualitySettings` 段被 pack 补齐 `type/layer/script`（与源场景等价，功能零回退）、新增 `EncounterRoot` instance 段与 `StatusLabel` 覆盖段；深蓝夜景 Environment / 三层视差节点 / 赐福 HUD / 画质面板结构均未改动。

---

## 3. HUD 重叠处理

- 战斗状态 Label 用 **instance 属性覆盖**从 `(24,20)` 移到 `(24,660)-(1224,692)`，字号 18 / 金色字沿用源场景。
- 保护区：赐福 HUD 矩形 `x<730,y<220`（实测面板约 `x 32..512, y 43..187`）；右上画质面板 `x>760,y<180`（实测 `rect=(760,32)-(1244,176)`）。
- 底部文字 `y≥660`，既 `>220` 也 `>180`，三帧目视确认**无重叠、无裁切、无换行**。
- 挂进**根节点 `Courtyard`**（主视口 1280×720 层级）而非 `SubViewport(640×360)`：encounter 自带 HUD 是 `CanvasLayer`，只有挂主视口层级，`(24,660)` 才是 1280×720 屏幕底部；挂进低分辨率 SubViewport 会让 `y=660` 落到视口外不可见。

---

## 4. 真跑输出结论（全部 `EXIT=0`，`SCRIPT ERROR=0`）

### 三段门禁（7 个日志 `SCRIPT ERROR` 计数全为 0）
| 段 | 命令要点 | EXIT |
|---|---|---|
| G1 | `--headless --import` | 0 |
| G2 | `--headless --check-only --script` × 5（`build_courtyard_v020` / `verify_fx_profile` / `verify_fx_mobile` / `verify_quality_interaction` / `verify_encounter_v010`） | 全 0 |
| G3 | `--headless --quit`（main_scene = Main.tscn） | 0 |

### 四个 verify 零回退
| 脚本 | 期望 | 实测 | 结论 |
|---|---|---|---|
| `verify_fx_profile.gd` | 34 PASS | `pass=34 fail=0 RESULT=PASS` | 不回退 |
| `verify_fx_mobile.gd` | 47 PASS | `pass=47 fail=0 RESULT=PASS` | 不回退 |
| `verify_quality_interaction.gd` | 19 PASS | `pass=19 fail=0 RESULT=PASS` | 不回退（回读 courtyard `node_count=29`） |
| `verify_encounter_v010.gd` | 20 PASS | `pass=20 fail=0 RESULT=ALL_MATCH` | 不回退 |

### 补充运行时验证（直接真跑，非新建探针）
`--headless --quit res://scenes/courtyard.tscn` → `EXIT=0`，`SCRIPT ERROR=0`；日志出现 `[BossController] 阶段装载 -> phase_index=1 pose_prefix=p1_ 招式数=2`，证明 encounter 的 Boss 逻辑节点在 courtyard 内被实例化并驱动；画质面板 `rect=(760,32)-(1244,176)`、`node_count=29` 均为运行期实际回读。

注：门禁 / 运行时仅有既有的 `WARNING: 2 ObjectDB instances were leaked at exit` 与 `[ChunkManager] 未找到 ChunkRoot` 警告（R23 门禁日志同样存在），**非 `SCRIPT ERROR`**。

---

## 5. Movie Maker 抓帧目视结论（ViewImage 真看 3 帧）

命令：`--write-movie capture/v020_courtyard_.png --fixed-fps 30 --quit-after 15 res://scenes/courtyard.tscn` → 15 帧 1280×720，`EXIT=0`；录屏日志还出现 `[BossController] 抽中招式 -> move_01_dagger_slash`，Boss AI 在录制期间真实推进。真看帧：`00000000` / `00000007` / `00000014`（三帧结论一致）。

| 目视项 | 结论 |
|---|---|
| 战斗 HUD（底部 y≈660） | ✅ **出现**，金色文字逐字可读：`玩家 HP 100/100 ｜ Boss HP 100% ｜ 动作 idle 0/0 ｜ 闪避 0 ｜ 命中 0 ｜ 进行中`，含 `Boss HP 100%` |
| 赐福 HUD | ✅ 左上金线深蓝面板「赐福 · 宁姆格福」完整、不回退 |
| 右上画质面板 | ✅ 深蓝金线面板「画质设置 · 低 / 中 / 高」+ 低/中/高 三按钮完整、不回退 |
| 深蓝夜景 | ✅ 深蓝星空 / 冷夜雾 / 暖金主光 / 铺砖 3D 地面与台地在，不回退 |
| 三层视差远景 | ✅ 上部远景水平渐变条带与地平线层次仍在，与 R23 一致、不回退（目视可辨层次，未新增也未破损） |
| 金线深蓝 HUD 配色 | ✅ 保持 |
| HUD 重叠 / 遮挡 | ✅ 底部文字与左上 `x<730,y<220`、右上 `x>760,y<180` 均无重叠；无裁切 / 换行 |
| **Boss 可见形象** | ❌ **未出现**：全画面仅 1 个像素人形（右侧中部光柱下的玩家），没有第二个大型敌人 / Boss 像素或 3D 形象 |
| 战斗数值推进 | ⚠️ 15 帧内数值恒定（无输入注入；Boss 抽招但未命中），为 v0.1.0 静态表现，非本轮回退 |

### 未达 HD-2D 全绿（如实写未达）
「Boss 与战斗 HUD 出现」**只达成一半**：战斗 HUD（含 `Boss HP 100%`）已出现，但 **Boss 本体没有可见形象**。根因：`encounter_v010.tscn` 的 `Boss` 是纯逻辑 `Node3D + boss_controller.gd`，其 `sprite_path = "../Hybrid2D3DAnimatedSprite"` 在该场景内不存在，`_sprite=null`，`_apply_pose()` 直接 return；v0.1.0 独立运行时同样无 Boss 形象。本轮目录所有权禁止改 `encounter_v010.tscn` / `encounter_director.gd` / 既有战斗件 / 任何美术资源，故不补可见精灵，**也不伪造「已出现」**。Boss 的可见呈现目前仅为 HUD 文字 `Boss HP 100%` 与运行时 `[BossController]` 日志。**结论：未达 HD-2D 全绿。**

---

## 6. 未完成项与阻塞

1. **Boss 可见像素/3D 形象缺失（P0 遗留）**：需由拥有 encounter 源 / 美术资源的工位补一个可见精灵节点并接上 `boss_controller` 的 `sprite_path`；本轮受目录所有权硬约束不做。这是「未达 HD-2D 全绿」的唯一主因。
2. 战斗 HUD 数值在录屏内不推进（无输入注入）；按公共契约本轮不新建只读探针/巡检脚本，未做交互注入。
3. 未产出完整 15 秒视频：任务单以「15 秒录屏」为背景描述，本轮按 ④ 只要求抓帧目视，故录 15 帧（@30fps，约 0.5 秒）用于核对。
4. 无 git 操作（总指挥收尾）。

---

## 7. 契约与所有权遵守

- 直接改、直接真跑；未新建只读探针 / 巡检脚本（新增脚本仅 `build_courtyard_v020.gd` 交付件）。
- 零付费、零外部依赖、一次只跑一个 GPU 任务（Movie Maker 单独一次）。
- 不伪造产物、不谎报成功、不自行 git。
- 未写 `project.godot` / `encounter_v010.tscn` / `encounter_director.gd` / 既有战斗件 / 任何 PNG/tres 美术资源。
- capture/ 只新建 `v020_courtyard*` 前缀文件，未触碰 Rank-4 既有文件。
