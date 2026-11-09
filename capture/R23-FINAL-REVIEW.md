# R23-FINAL-REVIEW.md — R23B 15 秒实机录屏目视回看

> 补单 `cmd-20261109-141302-870-A1`（`[ROUND=R23B]`）· Rank-1（引擎架构与渲染）
> 引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable）· 2026-11-09 本机 +0800
> **一句话结论：新素材（r23 玩家 spritesheet + r23 地面贴片）确实进入可见画面，且与 R23 旧帧有明显可辨差异；HD-2D 全绿仍未达，如实写「未达」。**

---

## 0. 真跑命令与产物（如实登记）

```bat
D:/Godot/Godot_v4.7.2-stable_win64.exe \
  --path F:/Game/aierdengfahuan/godot \
  --write-movie F:/Game/aierdengfahuan/capture/r23_final.png \
  --fixed-fps 30 --quit-after 450 \
  --script res://test/presentation.gd \
  res://scenes/courtyard.tscn
```

| 项 | 真跑结果 |
|---|---|
| `CAPTURE_EXIT` | **0** |
| Movie Maker | `recording movie in 1280×720 @ 30 FPS` |
| 输出 PNG | **450 张** `r23_final00000000.png` ~ `r23_final00000449.png`，全部 1280×720 |
| 时间线 | `SEG-A frame=0` / `SEG-B frame=150` / `SEG-C frame=300` / `时间线完成 frame=450`（非单帧循环） |
| WAV | `r23_final.wav`，**5,760,044 B**，Movie Maker 音频轨真实产出 |
| ffmpeg | `ffmpeg -y -framerate 30 -i capture/r23_final%08d.png -c:v libx264 -pix_fmt yuv420p -movflags +faststart capture/r23_final.mp4`，`FFMPEG_EXIT=0` |
| MP4 | `capture/r23_final.mp4`，**1,288,103 B**；ffprobe：`h264 / yuv420p / 1280×720 / 30 fps / nb_frames=450 / duration=15.000000` |
| **WAV 是否混入** | **未混入**。ffprobe 音频流计数 = **0**，MP4 仅视频轨。`r23_final.wav` 单独保留。与 R22 `r22_demo.mp4` 口径一致（同样仅视频轨、`r22_demo.wav` 未混入），**如实登记、不谎报合并** |
| 日志 | `teamwork/Rank-1/r23b_capture.log`、`capture/r23b_ffmpeg.log` |

> 录屏为**单个 GPU/编码任务**（非 headless，OpenGL 3.3 / NVIDIA RTX 4060 Ti），未与其它 GPU 任务并行。

---

## 1. 首 / 中 / 尾三帧目视（ViewImage 真看，非推测）

| 帧 | 文件 | 档位 | 目视所见 |
|---|---|---|---|
| 首 | `r23_final00000000.png` | 段 A medium / desktop | 深蓝夜空 + 星点 + 远山剪影 + 横向雾带；**地面为密集不规则的石砖贴图**（暖金 / 棕褐 / 青灰 / 橙点交替，砖块大小与走向不统一，有明显颗粒与磨损细节），绝非纯色平面；中央**红发 + 钴蓝板甲 + 金色护肩/胸饰**的像素骑士，轮廓清晰、配色层次丰富；右上暖金体积光柱 + 光尘、角色脚下暖金光池；HUD「赐福 · 宁姆格福」+「画质设置·低/中/高」金线深蓝面板，尺寸正常不遮挡角色。角色左侧有一个深蓝色尖锐几何形状（见 §6） |
| 中 | `r23_final00000225.png` | 段 B low / mobile | 地面石砖贴图**依旧清晰高密度**（未因降档丢失）；角色换成**红白头饰 + 钴蓝板甲 + 金护肩 + 蓝色下摆**的另一 pose，完整可见、未被 HUD 遮挡；HUD 标题随 flag 变为「赐福 · 巡礼教堂」；**四项光效全关**——光柱 / 光尘 / 倒影 / bloom 消失，画面整体更暗、地面无暖金光池，符合 R22 段 B 口径；三档 HUD 面板尺寸一致（low 档未放大） |
| 尾 | `r23_final00000449.png` | 段 C high / desktop | 地面石砖纹理**最锐利**、细节最密；角色为**红发 + 黄黑格纹头巾 + 钴蓝板甲 + 胸前发光青蓝宝石**的 pose，无破图 / 重复小人 / 空白；深蓝夜空 + 分层山影 + 雾带 + 暖金光柱 + 光尘 + 脚下光池回归；HUD 标题「赐福 · 希芙拉河井底」为**暗色未点亮态**（frame=420 flag 设为 false），演示脚本 HUD 事件驱动生效 |

---

## 2. 接入前后对照（同工程、同档位口径，R23 旧帧 vs R23B 新帧）

对照帧：`capture/r23_night_00000005.png`（R23 时期 **接入新素材之前** 的 medium/desktop 画面）。

| 维度 | R23 旧帧（接入前） | R23B 新帧（接入后） | 判定 |
|---|---|---|---|
| **地面** | 规则的**长条形砖块网格**，黄绿 / 棕褐 / 浅米平涂交替，几何化、重复感强、细节少 | **密集不规则石砖**：暖金 / 青灰 / 棕褐 / 橙点混杂，砖块大小走向不一，有明显磨损与颗粒细节，像真实石板路面 | **明显变化** → `r23/ground_tile.png` 进入画面 |
| **玩家角色** | 蓝白头盔 + 红色围巾 + 蓝灰甲的小骑士，色块简单、偏小、轮廓较平 | 红发 / 格纹头巾 + 钴蓝板甲 + 金色护肩 + 发光青蓝宝石，暖金 / 钴蓝 / 青宝石配色层次丰富、近黑硬描边更清晰、体积更大 | **明显变化** → `r23/player_spritesheet.png` 进入画面 |
| 夜景 / 景深 / HUD | 深蓝夜空 + 山影 + 暖金光柱 + 金线深蓝 HUD | 同左，保持不回退 | 不回退 |

> 结论：**「新素材是否真的进入画面」= 是**。依据是两处可辨的像素级视觉差异，且由
> `player_spriteframes.tres` / 3 个地面材质 `ext_resource` 指向 `res://assets/generated/r23/*.png`
> 的静态改动 + 450 帧真实渲染 + ViewImage 目视三者共同支撑；不是 clean build 推断，也不是改名冒充。

---

## 3. 新素材是否真的进入画面（判定）

| 新素材 | 接入改动 | 本录屏是否可见 | 说明 |
|---|---|---|---|
| `r23/player_spritesheet.png`（1024×128，8 pose） | `chars/player_spriteframes.tres` ext_resource 指向 r23/ | **是**（三帧角色均换图，且 30 次 `set_pose` 切帧可见不同姿势） | pose 名 / 帧序 / `region.x` 与既有 tres 一致，未改 region |
| `r23/ground_tile.png`（128×128，严格无缝） | `terrain/ground_material.tres` + `courtyard.tscn` 实际引用的 3 个 `ground_tile_mat_{plate,low,high}.tres` ext_resource 指向 r23/ | **是**（三帧地面均为新石砖纹理，三档皆可见） | 只改 `ground_material.tres` 不会进画面（场景未引用它），故按派单「必要时同步 courtyard.tscn 实例引用」裁量同步了 3 个材质；`courtyard.tscn` 本身未改、节点数仍 27 |
| `r23/boss_spritesheet.png`（384×128，3 pose） | `boss/boss_spriteframes.tres` ext_resource 指向 r23/ | **否** | `courtyard.tscn` **无 Boss 实例**（27 节点中不含 Boss），Boss 素材由 `scenes/boss_01_margit.tscn` 引用；本 15 秒 courtyard 录屏画面不含 Boss，**如实登记，不冒充可见** |
| `r23/decor_layer.png` | 未接入（派单未要求） | 否 | 如实登记 |

---

## 4. 夜景与景深效果

- **夜景**：深蓝夜空 + 星点 + 冷蓝雾带 + 远山剪影 + 暖金主光/光柱，构成 R23 建立的暖冷强对比；三档均在，未回退。
- **景深**：为**程序化 2D 分层近似**（`hd2d_parallax.gd` 的多层山影 / 雾带 / 渐变），不是 3D 深度雾 / 真实 DOF 模糊；近景地面全程清晰，无随距离的虚化。山影偏几何化、层次有限。
- **四项光效**：desktop 段（首/尾帧）光柱 / 光尘 / 倒影 / bloom 可见，mobile 段（中帧）四项全关，符合 `verify_fx_profile.gd 34 PASS` / `verify_fx_mobile.gd 47 PASS` 口径；均为 2D `draw_*` 近似（`gl_compatibility` 后端不支持 HDR bloom / 3D 体积散射 / SSR）。

---

## 5. 与 HD-2D 目标的差距：**未达全绿**（如实写未达）

| 目标项 | R23B 实际 | 判定 |
|---|---|---|
| 像素精灵 × 3D 场景对比 | 硬边像素骑士 + 透视石砖地面，对比成立且比 R23 更清晰 | **部分达到（有改善）** |
| 高质量地面贴图 | 新石砖纹理细节明显提升，但 `uv1_scale` 高倍平铺 → **重复感仍明显**；暖金砖大面积偏亮，**冷夜雾向地面渗透不足**，仍有白天感残留（R23 已登记第 3 项） | **部分达到，未达全绿** |
| 平滑景深 / DOF / 大气远景 | 2D 程序化分层近似，山影几何化；无 3D 深度雾 / DOF 模糊 | **未达** |
| 体积光 / 光尘 / 湿地倒影 / bloom | 2D `draw_*` 近似，随档位开关；非 3D 体积光 / SSR / HDR bloom | **近似，未达** |
| 金线深蓝 UI | 三帧清晰、三档尺寸一致、low 档不遮挡角色 | **达到** |
| 角色动画 | 8 pose 各仅 1 帧（切 pose 换图），**无逐帧动作动画**；ComfyUI spritesheet 已接入但仍为单帧 pose 表 | **未达**（ spritesheet 结构限制） |
| 整体氛围 | 深蓝夜景 + 暖金主光成立，但地面亮度偏高、光池与暗部对比强度不足原作 HD-2D | **未达全绿** |

> 沿用 R20~R23 长期边界：本轮只做「接入 + 录屏 + 目视回看」，**未精修美术**，
> 不冒充全绿。R23 的 `HD2D-NIGHT-R23.md §4` 所列 10 项边界中，
> 地面白天感残留、景深近似、四项光效近似、角色为 3D `AnimatedSprite3D` 贴图等仍未消除。

---

## 6. 如实登记 / 未完成项

1. **HD-2D 全绿未达**（§5），本轮不精修美术、不谎报达标。
2. **Boss 新素材未进入本录屏画面**：`courtyard.tscn` 无 Boss 实例；`boss_spriteframes.tres` 已指向 r23/ 且 `boss_01_margit.tscn` 引用它，但本 15 秒 courtyard 画面不可见。
3. **`decor_layer.png` 未接入**（派单未要求）。
4. **WAV 未混入 MP4**：`r23_final.wav`（5,760,044 B）单独保留，MP4 仅 h264/yuv420p 视频轨（音频流=0），与 R22 口径一致。
5. **画面左侧深蓝色尖锐几何形状**：首 / 中 / 尾三帧均出现、位置固定，为既有场景 / FX 元素（非本轮改动引入），来源未逐一追查，**如实登记不臆断**。
6. 段 B（low/mobile）3D 主体静止（沿用 R22：相机写入会破坏 Movie Maker 的 SubViewport 3D 录制，故取消逐帧相机 / 角色位移），仅靠 30 次 `set_pose` + 5 次 HUD flag 推进，存在短静止区间。
7. 未做人工鼠标点击 / 真机试玩逐帧动态验收；Movie Maker 固定步长录屏不等价于实时性能评测。
8. 既有非致命 WARNING（`2 ObjectDB instances were leaked`、`ChunkManager 未找到 ChunkRoot`、`HUD 降级登记`）在回归日志中出现，非 `SCRIPT ERROR`、不改退出码，如实登记。
9. 零付费、未引入付费素材生成服务、一次只跑一个 GPU 任务、未自行 `git commit`；产物按 `.gitignore` 排除不入库。

---

> 证据：`capture/r23_final00000000.png` / `r23_final00000225.png` / `r23_final00000449.png`（首/中/尾），
> 对照帧 `capture/r23_night_00000005.png`，`capture/r23_final.mp4`、`capture/r23_final.wav`、
> `teamwork/Rank-1/r23b_capture.log`、`capture/r23b_ffmpeg.log`。
> 完整交付与未完成项见 `teamwork/Rank-1/DONE-R23B.md`。
