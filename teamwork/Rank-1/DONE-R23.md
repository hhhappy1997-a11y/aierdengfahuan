# DONE-R23.md · Rank-1 引擎架构与渲染（R23 HD-2D 夜景与景深整改）

> 命令 `cmd-20261109-133602-469-A1` · `[ROUND=R23]` · AI=1（Rank-1）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
> 工程根 `F:/Game/aierdengfahuan/godot`；回执目录 `F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/`
> 详细口径见 `teamwork/Rank-1/HD2D-NIGHT-R23.md`（HD-2D 目标差距登记 / 未达全绿）
> **结论：`status=done` 指本轮「夜景+景深整改 / HUD 修复 / 门禁 / 回归 / 抓帧 / 文档 / 回执」闭环；不代表 HD-2D 全绿（见 §4）**

---

## ① 改动文件清单（实际交付）

| 类别 | 文件 | 说明 |
|---|---|---|
| 场景（独占） | `godot/scenes/courtyard.tscn` | `Environment` 冷夜雾 5 参数、`SunLight` 暖金主光色/energy、新增 `ParallaxBackdropLayer`(CanvasLayer layer=5) + `ParallaxBackdrop`(Node2D) 两节点；HUD `layer=20` / QualitySettings `layer=40` 原样不回退 |
| 新增渲染脚本 | `godot/scripts/render/hd2d_parallax.gd` | 程序化多层视差远景 `CanvasLayer _draw()`：深蓝夜空 / 3 层山影剪影 / 远近雾带 / 平滑景深 / 分层光尘 / 地面冷夜压暗；零外部依赖 |
| 引擎自动产物 | `godot/scripts/render/hd2d_parallax.gd.uid` | 20 字节，G1 `--headless --import` 自动生成，非手写 |
| UI 场景 | `godot/scenes/hud.tscn` | `HudPanel` / `TitleLabel` 由固定 offset 改纯 anchor 比例布局，修复 low 档面板放大；金线深蓝配色不动 |
| 真跑日志 | `teamwork/Rank-1/r23_*.log`（9 份） | `r23_gate_import` / `r23_gate_checkonly{,_profile,_mobile}` / `r23_gate_quit` / `r23_verify_fx_profile` / `r23_verify_fx_mobile` / `r23_verify_interaction` / `r23_capture`，均为最终版真跑 stdout |
| 抓帧产物 | `capture/r23_night_00000000.png` ~ `r23_night_00000012.png`（13 张）+ `r23_night_.wav` | Movie Maker 真实输出，1280×720；最终版为目视回看精修后重抓覆盖 |
| 差距登记 | `teamwork/Rank-1/HD2D-NIGHT-R23.md` | 与 HD-2D 目标逐项对照 + 未达全绿结论 |
| 交付文档 | `teamwork/Rank-1/DONE-R23.md` | 本文件 |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-133602-469-A1.json` | 按本轮 id 写入精确路径（在 `teamwork/command_center/` 下，非工程根 `command_center/`） |

**未写**：`project.godot`、`hud.gd`、`godot/assets/generated/r23/`、`verify_frame_data.gd`、`README.md`、`00-协作契约.md`、`00-汇总.md`、`capture/CAPTURE-REPORT.md`、`hd2d_fx.gd` / `hd2d_fx.tscn`（Rank-4 独占，4 项光效零改动）。

---

## ② 门禁与 PASS 数字（真跑，最终版）

### 2.1 三段门禁 + 回归 + 抓帧 EXIT

| 段 | 命令 | EXIT |
|---|---|---|
| G1 | `--headless --path <root> --import` | **0** |
| G2 | `--headless --check-only --script verify_quality_interaction.gd` | **0** |
| G2 | `--headless --check-only --script verify_fx_profile.gd` | **0** |
| G2 | `--headless --check-only --script verify_fx_mobile.gd` | **0** |
| G3 | `--headless --path <root> --quit` | **0** |
| 回归 | `--headless --script verify_fx_profile.gd` | **0** |
| 回归 | `--headless --script verify_fx_mobile.gd` | **0** |
| 交互 | `--headless --script verify_quality_interaction.gd` | **0** |
| 抓帧 | `--path <root> --script verify_quality_interaction.gd --write-movie capture/r23_night_.png --fixed-fps 30`（不带 `--headless`，单个 GPU 任务） | **0** |

### 2.2 `grep SCRIPT ERROR` 结论

对最终版 9 份 `r23_*.log` **逐文件**精确 grep `SCRIPT ERROR|Parse Error`：**全部 0 条**，汇总 `SCRIPT_ERROR_TOTAL=0`；`ERROR_TOTAL=0`。既有 `ObjectDB instances were leaked` / `ChunkManager 未找到 ChunkRoot` 为工程既有 WARNING（非本轮引入、不改退出码）。

### 2.3 PASS 数字（不回退）

| 脚本 | 结果 |
|---|---|
| `verify_fx_profile.gd` | `SUMMARY pass=34 fail=0 total=34` / `RESULT=PASS` → **34 PASS** |
| `verify_fx_mobile.gd` | `SUMMARY pass=47 fail=0 total=47` / `RESULT=PASS` → **47 PASS** |
| `verify_quality_interaction.gd` | `SUMMARY pass=19 fail=0 total=19` / `RESULT=PASS` → **19 PASS** |

**34 PASS / 47 PASS 未回退**；4 项光效（体积光/光尘/倒影/bloom）与 HUD `layer=20` / `quality_settings layer=40` 均不回退。

### 2.4 节点数（CACHE_MODE_IGNORE 真跑回读，如实登记）

**= 27**（R22 登记为 25，本轮新增 `ParallaxBackdropLayer` + `ParallaxBackdrop` 两节点，**不冒充 25**）。两处独立回读一致：
- `[R22] LOAD path=res://scenes/courtyard.tscn ... SceneState_node_count=27 CACHE_MODE_IGNORE=true`
- `[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=27`

（日志中「R20 登记 25」为 `quality_settings.gd` 内未改的静态提示文本，非本轮回读值。）

---

## ③ 抓帧文件名与目视结论

**抓帧**：`capture/r23_night_00000000.png` ~ `capture/r23_night_00000012.png`（13 张，1280×720）+ `capture/r23_night_.wav`，Movie Maker `13 frames at 30 FPS`，EXIT=0。

**ViewImage 真看三档代表帧**（产出先目视再接入）：

| 帧 | 档位 | 目视结论 |
|---|---|---|
| `r23_night_00000000.png` | low / mobile | 深蓝冷夜天空 + 星点 + 雾带 + 远山剪影；地面暖金砖压暗成冷夜暗金；HUD 面板约 480px 宽，与中/高档一致、未放大；像素骑士完整可见；mobile 四项光效全关（无光柱），符合冻结口径 |
| `r23_night_00000005.png` | medium / desktop | 同上夜景；暖金体积光柱、光尘、角色脚下湿地倒影、bloom 光晕可见；HUD 一致、角色可见 |
| `r23_night_00000010.png` | high / desktop | 同上夜景、山影层次较首版明显；光柱/光尘/倒影最锐利；HUD 一致、角色可见；首版 high 档「双光源错位」已消除（全场单一光源） |

**R22 三项判定整改实证**：①「亮蓝白天调」→ 三档均深蓝冷夜雾 + 暖金主光对比；②「无平滑多层景深」→ 新增程序化 3 层山影剪影 / 雾带 / 渐变景深；③「low 档 HUD 面板放大遮挡角色」→ 纯 anchor 布局后 low/medium/high 面板尺寸一致（约 480px），三档角色始终完整可见。

**目视回看迭代（如实）**：首版抓帧（`light_energy=2.4`、山影被雾带盖住、视差层画了独立辉光点）经 ViewImage 判定「地面过亮残留白天感 / 景深层次不明显 / high 档双光源错位」，据此精修（主光 2.4→1.5、山影剪影化 + 雾带分置、地面冷夜压暗、去掉重复辉光点）后**重跑全链并覆盖重抓**同名 13 帧；文档与日志均为最终版。

---

## ④ 未完成项与阻塞

**阻塞：无**（门禁 / 回归 / 抓帧 / 文档 / 回执均闭环）。

**如实登记的未完成项 / 边界（详见 `HD2D-NIGHT-R23.md` §4，结论 = 未达 HD-2D 全绿）**：

1. **HD-2D 全绿未达**：景深为 2D 程序化几何近似，非 3D 深度雾 / 景深模糊 / 美术贴图远景；山影偏几何化。
2. **无真实相机视差**：用分层时间漂移近似，未接相机位移（脚本注释已声明）。
3. **地面白天感仍有残留**：暖金砖地大面积偏亮，冷夜雾向地面渗透不足，未达原作「暗场景 + 局部强光池」对比强度。
4. **4 项光效仍是 2D 近似**（`hd2d_fx.gd`，Rank-4 独占、本轮零改动）；`gl_compatibility` 后端不支持 Environment glow / 真实 bloom 后处理（R13 已登记）。
5. **角色为 3D `AnimatedSprite3D` 像素贴图**，非纯 2D 像素精灵合成。
6. **光源位置随画质档漂移**：`hd2d_fx.gd` 的 `LIGHT_POS=(452,92)` 固定 640×360 逻辑坐标不随 SubViewport 缩放，三档光柱横向位置不同；本轮去掉视差层重复辉光点消除「双光源错位」，但不在不动 Rank-4 脚本的前提下统一三档光源位置。
7. **信号注入 ≠ 鼠标点击**：三档切换沿用 `Button.pressed.emit()`（非 `InputEventMouseButton`），未做 GUI 人工点击 / 真机试玩 / 逐帧动态验收。
8. **`low_resolution_size` 与 SubViewport 实际尺寸不一致**（low 480×270→426×240、high 960×540→1280×720）、Movie Maker 输出恒 1280×720、`scaling_3d/scale` 为 ProjectSettings 运行期改写（不落盘）：均为既有行为，如实回读、未改。
9. **既有 WARNING（非本轮引入、非 ERROR）**：`ObjectDB instances were leaked`、`ChunkManager 未找到 ChunkRoot`；不改退出码、未冒充全绿。
10. **按约束未做 / 未写**：真机鼠标点击、人工试玩逐帧动态验收、逐帧时间性能实测；不新建只读探针 / 巡检脚本、不主动扫目录做进度巡检；零付费 / 零外部素材 / 零付费生成服务 / 零插件；不写禁写清单文件；不伪造产物、不谎报成功；不自行 `git commit` / `git push`。

---

## 结论

R23 主任务闭环：独占 `courtyard.tscn` 把亮蓝白天调改为深蓝夜空 + 冷夜雾 + 暖金主光强对比（`fog_density 0.008→0.02`、ambient 暖金→冷蓝 0.8→0.4、主光 `(1,0.78,0.45)`→`(1,0.72,0.32)` / energy 1.8→1.5），新增零外部依赖的程序化多层视差远景层（3 层山影 / 雾带 / 平滑景深 / 分层光尘 / 地面冷夜压暗），修复 low 档 HUD 面板放大（改纯 anchor，三档尺寸一致、角色始终可见）；4 项光效与 HUD `layer=20` / `quality_settings layer=40` 不回退。真跑三段门禁、9 份日志 `SCRIPT ERROR=0`、`verify_fx_profile.gd` **34 PASS** / `verify_fx_mobile.gd` **47 PASS**（不回退）/ `verify_quality_interaction.gd` 19 PASS；Movie Maker 抓 13 张 `r23_night_*.png` 并 ViewImage 目视确认三档夜景 / 景深 / HUD 修复；节点数 `CACHE_MODE_IGNORE` 如实回读 **27**（R22=25，不冒充）。

`status=done` 指本轮交付闭环，**不代表 HD-2D 全绿已达成**（见 §4 与 `HD2D-NIGHT-R23.md` §4）。

> 证据：`teamwork/Rank-1/r23_*.log`（9 份）、`HD2D-NIGHT-R23.md`、`capture/r23_night_0000000*.png` + `r23_night_.wav`、`godot/scenes/courtyard.tscn`、`godot/scenes/hud.tscn`、`godot/scripts/render/hd2d_parallax.gd`（+ `.uid`）。

---

## ⑤ 回执路由状态（收尾复核追加，不改动上文结论）

- 回执按本轮 id 写入精确路径 `teamwork/command_center/ai/1/outbox/cmd-20261109-133602-469-A1.json`
  （**在 `teamwork/command_center/` 下，非工程根 `command_center/`**）；写入成功后被调度中枢
  **即时消费**，outbox 现为空，归档到
  `teamwork/command_center/dispatcher/receipts/cmd-20261109-133602-469-A1.json`（与 R20/R21/R22 同现象）。
- 只读复核归档件：`json.load` 解析通过，`task_id=cmd-20261109-133602-469-A1` / `ai=1` /
  `status=done` / `result` 引用 DONE-R23.md 实际结论（长度 773 字符），字段与本工位写入一致。
- 工程根 `F:/Game/aierdengfahuan/command_center/` **不存在**，未误写到工程根；按派单
  「outbox 空但 receipts 归档存在即视为已送达」，未重复投递、未改写归档件；
  `dispatcher/receipts/` 不在本轮可写范围。
