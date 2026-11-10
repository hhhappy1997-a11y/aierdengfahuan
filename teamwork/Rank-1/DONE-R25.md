# DONE-R25 · Rank-1 交付（cmd-20261110-204604-819-A1 / [ROUND=R25] / v0.3.0 方向 1、2 / 裁决 A16）

- 执行 AI：Rank-1（引擎架构与渲染）
- 工程根：`F:/Game/aierdengfahuan`；引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
- **结论速览**：A16 `run/main_scene` 改指 `courtyard.tscn`（只改一行）；Boss 可见形象与 `set_pose` 接线完成；三段门禁 `SCRIPT ERROR=0`；34 / 47 / 19 / 20 / 45 PASS 全不回退；Movie Maker 抓帧 + ViewImage 真看（含最近邻裁剪放大）**确认画面出现第二个角色（Boss）**，夜景 / 景深 / 三套 HUD 不回退。未完成项见 §8。

---

## 0. 并发实例与本文更新说明（如实登记，不隐瞒）

本轮同一任务存在**并发执行实例**：

- 并发实例约 21:22 曾写入本文件，结论为「画面第二个角色（Boss）**未达 / 存疑**」。该结论基于当时的**旧配置**（`courtyard.tscn` 的 BossVisual `x=4.0`、rig `frame_size=Vector2i(128,128)`、`scale 0.65`、`offset(-64,-128)`、SceneState node_count 32）——彼时 Boss 精灵 quad 被移出可见区域，目视确实未辨识到独立 Boss，其"未达"结论对应当时状态、并非谎报。
- 21:31–21:32 配置已修正并全量重跑 / 重抓：`courtyard.tscn` 收敛为 `x=2.0`、rig `frame_size` 默认、`scale 1.6`、`offset(-16,-48)`、`auto_aabb=false`；21:31 重跑门禁 / verify（`r25_g*` / `r25_verify_*` 日志），21:32:16 重抓 `v030_boss_00000000..14.png`；并发实例另产出 `v030_demo.mp4` + 450 帧 `v030_demo*.png`（15 秒录屏）。
- **本文以 21:40 后当前磁盘状态为准**：亲自重跑三段门禁 + 5 个 verify（`r25_final_*.log`），并对当前 `v030_boss` 帧用 ViewImage 真看 + 最近邻裁剪放大复核，结论更正为「**Boss 已出现**」。并发实例那份"未达"结论已被后续迭代与目视证据推翻，特此如实更正——不沿用过时结论、也不谎报成功。
- 当前 `courtyard.tscn`、`project.godot`、`encounter_v010.tscn`、build 脚本、抓帧产物均为上述修正后的最终状态。

## 1. 实际交付清单

| 文件 | 动作 | 说明 |
|---|---|---|
| `godot/project.godot` | 独占改 1 行 | `run/main_scene` `Main.tscn` → `courtyard.tscn`；其余段逐字不动；`Main.tscn` 保留 |
| `godot/scripts/combat/build_encounter_v010.gd` | 同步更新 | Boss 下挂 Hybrid + 可见精灵、绑定既有 `.tres`、`sprite_path` 接线；`EXPECTED_NODES` 6→8；pack 前后节点数比对 + `CACHE_MODE_IGNORE` 回读 + `RENDER_PROBE` / `COURTYARD_READBACK` |
| `godot/scenes/encounter_v010.tscn` | 由构建脚本重建 | 6 → 8 节点 |
| `godot/scenes/courtyard.tscn` | 覆写（Rank-1 独占） | 磁盘 29 → 33 节点：`SubViewport` 内新增 `BossVisual/Hybrid2D3DAnimatedSprite/PixelSprite` 3 节点 + `EncounterRoot/Boss` 的 `sprite_path` instance 内部覆盖段 1 条 |
| `capture/v030_boss_00000000..14.png`（15 帧）+ `v030_boss_.wav` | 抓帧产物 | 1280×720 @30 FPS，21:32:16 最终批次 |
| `capture/v030_demo00000000..449.png` + `v030_demo.mp4` + `v030_demo.wav` | 并发实例产出 | 450 帧 15 秒录屏（21:18），本轮未改动 |
| `teamwork/Rank-1/DONE-R25.md` | 本文 | 以最终状态复核更新 |
| `teamwork/Rank-1/r25_*.log` | 真跑日志 | 构建 1 / 门禁 10（G1 + G2×8 + G3）/ verify 5 / 抓帧 1 / 最终复核门禁 10 + verify 5 / 诊断中间日志若干 |
| `teamwork/command_center/ai/1/outbox/cmd-20261110-204604-819-A1.json` | 回执 | 严格按任务单 id 写到精确路径 |

**零写入**：任何素材 PNG / `.tres`（Rank-4 独占重绘）、`encounter_director.gd` / `encounter_rules_v020.gd`（Rank-2 独占）、`test/presentation.gd`（Rank-4 独占）、契约与 README（Rank-3 独占）、其它 Rank 目录既有文件。`boss_spriteframes.tres` 只被引用、零改动。诊断中间帧（`v030_boss_dbg*` / `v030_boss_ab*`）与临时裁剪副本均已清理。

## 2. `main_scene` 前后值（裁决 A16）

| | 值 | 位置 |
|---|---|---|
| 前 | `run/main_scene="res://scenes/Main.tscn"` | `godot/project.godot:37` |
| 后 | `run/main_scene="res://scenes/courtyard.tscn"` | `godot/project.godot:37` |

- **改动只限这一行**；`[autoload]`（6 项 + R20 注释）、`[input]`（15 个 action）、`[physics]`、`[rendering]`、`[display]`、`[hd2d]`、`config_version` 及全部注释经逐行核对**逐字不动**；`Main.tscn` 保留不删。
- `project.godot:16` 历史注释曾于真跑期间被并行进程同步为 `courtyard.tscn`，本 AI 已恢复为原文 `Main.tscn`（R3 历史说明），最终除第 37 行外完全一致。
- 效果：exe / apk 默认入口与 15 秒录屏所用的 `courtyard.tscn` 一致；G3 `--headless --quit` 即以 courtyard 为主场景加载，`EXIT=0`。

## 3. Boss 节点结构与 `set_pose` 接线

### 3.1 `encounter_v010.tscn`（8 节点，独立场景自洽）

```
EncounterRoot            (Node,   encounter_director.gd)
├─ Boss                  (Node3D, boss_controller.gd)
│  │  boss_data = ExtResource(boss_01_margit.tres)
│  │  sprite_path = NodePath("Hybrid2D3DAnimatedSprite")   ← 覆盖默认 "../Hybrid2D3DAnimatedSprite"
│  └─ Hybrid2D3DAnimatedSprite  (Node3D, hybrid_2d3d_animated_sprite.gd)
│     │  pose_frame_counts = {dagger_slash:1, staff_slam:1, holy_hammer:1}   ← clamp frame_index 到 0
│     │  auto_aabb = false
│     └─ PixelSprite      (AnimatedSprite3D)
│           sprite_frames = ExtResource("res://assets/generated/boss/boss_spriteframes.tres")
│           animation = &"p1_dagger_slash"
│           scale = 1.6 / centered = false / offset = (-16,-48) / pixel_size = 0.03125
├─ CombatEventBus, CombatResolver
└─ HUD/StatusLabel
```

- `BossController._ready()` → `_sprite = get_node_or_null(sprite_path)` 解析到 Hybrid rig（有 `set_pose`）→ `_apply_pose()` → `rig.set_pose(pose_name, frame_index)` → 名称校验（`FROZEN_POSES` + `p1_`/`p2_` 前缀）+ `frame_index` clamp → `AnimatedSprite3D.play(full_pose)` / `set("frame", 0)`。**消费方真实存在、真实调用**，不再是 R24 的 `_sprite=null` 直接 return。
- `boss_spriteframes.tres` 动画名 `p1_dagger_slash` / `p1_staff_slam` / `p2_holy_hammer` 与 `BossController` 的 `pose_prefix + move.pose_name` 完全匹配；`pose_frame_counts` 把每动作帧数钉死为 1，避免录制期间 `_move_frame` 递增导致 `frame` 越界。
- 素材口径：该 `.tres` 指向 `res://assets/generated/r23/boss_spritesheet.png`（Rank-4 本轮重绘内容、**路径不变**），Rank-1 只引用既有 `.tres`，零改素材。

### 3.2 `courtyard.tscn`（让 Boss 在画面里真正可见）

- 根因：`EncounterRoot` 挂在主视口 `Courtyard` 根下，其 Boss 子树属于主视口 World3D（无 3D 相机），R24 已证实不可见；只有 `SubViewport`（`own_world_3d=true` + `Camera3D.current=true`）里的 3D 节点才会被录屏渲染。
- 在 `SubViewportContainer/SubViewport` 下新增 `BossVisual`(Node3D, x=2.0，玩家右侧) → `Hybrid2D3DAnimatedSprite`(`auto_aabb=false`、`pose_frame_counts` 同 3.1) → `PixelSprite`(AnimatedSprite3D，绑定同一 `boss_spriteframes.tres`，`animation=&"p1_dagger_slash"`，`scale 1.6`、`offset(-16,-48)`、`centered=false`、`pixel_size 0.03125`)。
- 末尾按 R24 经验追加 **instance 内部属性覆盖段**（`--script` 模式下 `pack()` 不写实例内部子节点属性差异，须追加后回读校验）：

```
[node name="Boss" parent="EncounterRoot" index="0"]
sprite_path = NodePath("../../SubViewportContainer/SubViewport/BossVisual/Hybrid2D3DAnimatedSprite")
```

  使 courtyard 运行时 `BossController.set_pose` 驱动的是**画面里可见**的 Boss 形象。

### 3.3 摆位 / 不重叠（当前帧目视 + 裁剪放大实测）

| 对象 | 画面大致区域 |
|---|---|
| 玩家 | 左侧较小，蓝甲 / 蓝盾青宝石，约 x≈650–760 |
| **Boss（第二个角色）** | 右侧大型，金色牛角头盔（两侧上弯大角）+ 红色大披风 + 白脸 + 米黄长武器，约 x≈770–1080 / y≈270–500 |
| 赐福 HUD | 左上 x≈30–510，y≈45–185 |
| 画质面板 | 右上 rect=(760,32)-(1244,176) |
| 底部战斗 HUD | y≈660–692，横贯 x≈24–1224 |

Boss 在**玩家右侧**、两者明显分开无重叠；Boss 顶 y≈270 > 画质面板底 176 与赐福 HUD 底 185；Boss 底 y≈500 < 战斗 HUD 顶 660。三套 HUD 全部避开。

## 4. 节点数回读（pack 前后 + `CACHE_MODE_IGNORE`）

| 口径 | 数值 | 证据 |
|---|---|---|
| `encounter_v010.tscn` pack 前 / pack 后 | **8 / 8**，`pack_err=0` | `r25_build_v010.log` `NODE_COUNT before=8 after=8 expected=8` |
| `encounter_v010.tscn` 磁盘 `SceneState.get_node_count()` | **8** | `CACHE_MODE_IGNORE` 回读 `disk_nodes=8 director=true boss=true bus=true label=true` |
| 接线回读 | 全 true | `WIRING hybrid=true pixel=true sprite_path=true rig_has_set_pose=true frames_bound=true animation=true local_consumer=true` |
| `courtyard.tscn` 磁盘 SceneState 节点数 | **29 → 33** | +3 真实节点 +1 instance 内部覆盖段；运行期 `quality_settings` 与 `verify_quality_interaction` 均回读 `node_count=33` |
| instance 覆盖段回读 | **生效** | `COURTYARD_READBACK ... resolved=true override_ok=true visual_frames_bound=true` |
| 渲染前置回读 | 全正常 | `RENDER_PROBE pose_frame_counts={...} sf_anims=[p1_dagger_slash,p1_staff_slam,p2_holy_hammer] before(frame=0 fc=1 tex=true) after_set_pose18(frame=0 fc=1 tex=true)`；`RENDER_NODE bossVisual_visible=true pos=(2.0,0,0) pixel_visible=true scale=(1.6,1.6,1.6)` |

`build_encounter_v010.gd` 真跑 `END ok=true`、`ENGINE_EXIT=0`。

## 5. 真跑输出结论（三段门禁 + 5 个 verify）

引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--headless --path F:/Game/aierdengfahuan/godot`。**21:31 并发实例重跑**（`r25_g1_import.log` / `r25_g2_*.log` / `r25_g3_quit.log` / `r25_verify_*.log`）与 **21:4x 本 AI 亲自复核重跑**（`r25_final_g1.log` / `r25_final_g2_*.log` / `r25_final_g3.log` / `r25_final_verify_*.log`）结论一致：

| 段 | 命令要点 | EXIT | `SCRIPT ERROR` |
|---|---|---|---|
| G1 | `--headless --import` | 0 | 0 |
| G2 | `--headless --check-only --script` × 8（build_encounter_v010 / encounter_director / encounter_rules_v020 / verify_fx_profile / verify_fx_mobile / verify_quality_interaction / verify_encounter_v010 / verify_encounter_v020） | 全 0 | 全 0 |
| G3 | `--headless --quit`（main_scene = `courtyard.tscn`） | 0 | 0 |

**两批共 30 份门禁 / verify 日志 `grep -c "SCRIPT ERROR"` 全部为 0。**

| verify 脚本 | 期望 | 实测 | 结论 |
|---|---|---|---|
| `verify_fx_profile.gd` | 34 | `pass=34 fail=0 RESULT=PASS` | 不回退 |
| `verify_fx_mobile.gd` | 47 | `pass=47 fail=0 RESULT=PASS` | 不回退 |
| `verify_quality_interaction.gd` | 19 | `pass=19 fail=0 RESULT=PASS` | 不回退（回读 courtyard `node_count=33`） |
| `verify_encounter_v010.gd` | 20 | `pass=20 fail=0 RESULT=ALL_MATCH` | 不回退 |
| `verify_encounter_v020.gd` | 45 | `pass=45 fail=0 RESULT=ALL_MATCH` | 不回退 |

注：门禁 / 运行仅有既有 WARNING（`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`），**非 `SCRIPT ERROR`**，与 R23/R24 日志一致。

## 6. Movie Maker 抓帧 + ViewImage 目视结论

命令：`--path <godot> --write-movie capture/v030_boss_.png --fixed-fps 30 --quit-after 15 res://scenes/courtyard.tscn` → 15 帧 1280×720，`EXIT=0`；日志含 `[BossController] 抽中招式 -> phase=1 move=move_01_dagger_slash pose=p1_dagger_slash`（录制期间 Boss AI 真实推进、`set_pose` 被调用）与 `node_count=33`。

真看**当前磁盘** `v030_boss_00000000.png` / `00000007.png` / `00000014.png`（21:32:16 批次，三帧静态一致），并对首帧做最近邻裁剪放大（原图 x=580..1160、y=190..560，2×）复核：

| 目视项 | 结论 |
|---|---|
| **第二个角色（Boss）形象** | ✅ **出现**：金色牛角头盔（两侧上弯大角）+ 红色大披风 + 白脸 + 米黄长武器，体型明显大于玩家，与 `boss_spritesheet.png` 首帧一致；右半区红色像素 3252 / 金色 12504，佐证红披风与金角 |
| 玩家与 Boss 相对位置 | ✅ 玩家在左（x≈650–760）、Boss 在其右侧（x≈770–1080），明显分开、无重叠 |
| 赐福 HUD（左上） | ✅ 金线深蓝面板「赐福 · 宁姆格福」完整，不回退 |
| 画质面板（右上） | ✅ 深蓝金线面板「画质设置 · 低 / 中 / 高」+ 低/中/高 三按钮完整，不回退 |
| 底部战斗 HUD | ✅ 金色文字逐字可读：`玩家 HP 100/100 ｜ Boss HP 100% ｜ 动作 idle 0/0 ｜ 闪避 0 ｜ 命中 0 ｜ 进行中`，不回退 |
| 深蓝夜景 / 铺砖 3D 地面 / 光柱 / 景深 / 视差远景 | ✅ 全部保持，不回退 |
| 三套 HUD 重叠 / 遮挡 / 裁切 | ✅ 无 |
| 战斗数值推进 | ⚠️ 15 帧内数值恒定（无输入注入；Boss 抽招但未命中），为静态表现，非本轮回退 |

抓帧素材基线：Rank-4 于 `2026-11-10 21:07:26` 重绘的 r23 素材（第二轮深蓝夜景版）。

## 7. 项目既有踩坑与本轮排查（如实登记）

- **SceneTree `--script` 模式 `add_child` 不 flush `_ready`**：构建脚本全部用 `set()` / 属性直接赋值，不依赖 `_ready`；回读验证时显式 `rig.call("_ready")` 触发装配。
- **pack 前后节点数比对 + `CACHE_MODE_IGNORE` 回读**：构建脚本内建（8→8→8）；courtyard 覆盖段按 R24 经验追加后回读 `override_ok=true`。
- **instance 内部属性覆盖在 pack 时可能丢失**：courtyard.tscn 手工追加标准覆盖段并回读验证（`resolved=true`）。
- **构建脚本自身解析错（已修复重跑）**：`Transform3D` 12-float 构造在 GDScript 不存在 → 改 `Node3D.scale`；`int` 字面量在 float 参数位不匹配 → 补 `.0`。另 `ok` 表达式在 `_free_tree()` 之后对已释放节点求 `boss_rb != null` 导致 `ok=false`（各分项打印全 true 却 `ok=false`），已把 `ok` 求值移到释放之前。中间态不属最终门禁输出，最终 `END ok=true`。
- **Rank-2 并发**：`encounter_director.gd` 在真跑期间处于写入中间态（444 行、8 个方法未定义），首跑构建报 8 条 `SCRIPT ERROR` 且生成的 `encounter_v010.tscn` 一度丢失 director 脚本；待 Rank-2 写完（21:00:47，28837 bytes / 45 个 func）后重跑构建恢复 `director=true`，最终门禁全绿。Rank-1 **零改动**该文件。
- **Rank-4 并发**：r23 素材在真跑期间两次重绘（20:59:04 第一轮简化图、21:07:26 第二轮深蓝夜景版），画面主体随之变化；曾一度把"素材重绘导致的画面变化"误判为 Boss 出现，经严格 A/B 纠正。Rank-1 **零改**任何 PNG / `.tres`。
- **Boss 不可见的真正根因（本轮最大坑）**：`frame_size = Vector2i(128,128)` 使 `HybridSpriteRig._configure_anchor()` 把 `offset` 设为 `(-64,-128)`，配合 `scale=0.65` 把 `AnimatedSprite3D` 的 quad 移出可见区域；`custom_aabb` 亦参与剔除。通过 A/B 对照（换 `sprite_frames`、改 x、删脚本、`auto_aabb=false`、严格 `AnimatedSprite3D.visible` A/B + 像素级 diff）逐步定位，最终改用与 Player 一致的可行配置（`frame_size` 默认 32×48 / `scale 1.6` / `offset (-16,-48)`）+ `auto_aabb=false`，Boss 正常渲染。这也是并发实例 21:22「未达」结论的成因，21:31 后已修正。

## 8. 未完成项与阻塞（如实写未达）

1. **15 秒录屏产物早于最终配置修正**：`v030_demo.mp4` / 450 帧由并发实例于 21:18 生成，早于 21:31 配置修正与 21:32 重抓；A16「默认入口与 15 秒录屏一致」以主场景口径已达成，但该录屏画面若需体现修正后的 Boss 形象，建议后续轮次以最终配置重录。本轮按任务 ③ 只做 15 帧抓帧目视，未冒充 15 秒录屏目视结论。
2. **录屏内战斗数值不推进**（无输入注入，Boss 抽招未命中）；按公共契约不新建只读探针 / 巡检脚本，未做交互注入。
3. **Rank-4 素材在真跑期间持续重绘（两轮）**：最终目视结论基于 `21:07:26` 版 PNG；若后续再改 PNG 内容，画面需复审（路径不变，Rank-1 场景接线不受影响）。
4. **Rank-2 `encounter_director.gd` 本轮并发更新**：最终门禁基于其完成版；中间态导致的临时 `SCRIPT ERROR` 已按 §7 如实登记。
5. A15：`128bit` 歧义**保留、待用户确认**，未消歧、未编码进任何期望值；色数口径按裁决为项目级色库 ≥256 / 单帧 ≤16 色索引，本轮未改素材。
6. A17：人工试玩属用户侧，本轮**只给勾选清单、不冒充完成**：
   - [ ] 启动 exe/apk，确认默认入口为 courtyard 夜景庭院（非 Main.tscn）
   - [ ] 确认画面中玩家与 Boss 双角色可辨识、Boss 位于玩家右侧且不遮挡三套 HUD
   - [ ] 试玩轻/重攻击、翻滚、防御、锁定，确认 Boss 二阶段与招式表现
   - [ ] 赐福点亮 / 画质档位切换 / 15 秒录屏观感
7. 无 git 操作（总指挥收尾）。

## 9. 契约与所有权遵守

- 目录所有权：只写 `project.godot` / `encounter_v010.tscn` / `build_encounter_v010.gd` / `courtyard.tscn` / `capture/v030_boss*.png` / `teamwork/Rank-1/`；未写任何素材 PNG / `.tres`、`encounter_director.gd`、`presentation.gd`、契约与 README、其它 Rank 目录。
- 公共契约：直接改、直接真跑；未新建只读探针 / 巡检脚本（仅扩展既有 `build_encounter_v010.gd` 的回读段）；零付费、零外部依赖；一次只跑一个 GPU 任务（Movie Maker 单独一次）；产出先目视检查再接入；不伪造产物、不谎报成功、不自行 git。
- 回执 JSON 按任务单 id 写到精确路径 `F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261110-204604-819-A1.json`（`{"task_id":...,"ai":1,"status":"done","result":"引用 DONE-R25.md 实际结论"}`，JSON 合法）。调度中枢 dispatcher 为实时收件，写入后该文件被立即移走，`outbox/` 常态为空（R24 已登记的既有设计，非写入失败）：当前 `dispatcher/receipts/` 下存在两份同 id 回执 —— 21:28 并发实例版（内容为旧「复核 / 未达」结论）与 21:43 本 AI 版（带时间戳后缀 `.20261110-214349-404`，内容为本文最终结论，字段 `status=done` 校验通过）。本文 DONE-R25.md 已按最终磁盘状态更正，作为本轮权威结论；遵循 R24 经验不再重复写入以免制造第三份回执。
