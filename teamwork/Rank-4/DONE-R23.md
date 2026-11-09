# DONE-R23.md — Rank-4 DNF 定风格 + 本机 ComfyUI 重绘可发布素材（ROUND=R23）

- 派单 id：`cmd-20261109-133602-467-A4`（`[ROUND=R23]`）
- 执行：Rank-4（美术管线与工具链）
- 时间：2026-11-09（本机 +0800）
- 必读（已读）：`teamwork/Rank-4/调度任务单-latest.json`（完整 task 字段）、`DNF素材接入说明.md`、
  `tools/extract_dnf.py`、`comfyui_workflow_pixel.json`、`pose_names.json`、
  `player_spriteframes.tres` / `boss_spriteframes.tres`、`DONE-R22.md`
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable.official.ed1daf0bf）
- ComfyUI：本机 `127.0.0.1:8188` v0.33.2，RTX 4060 Ti
- 一句话结论：**DNF 参考 21 张 + ComfyUI 本机重绘 13 张可发布素材（含 128×128 严格无缝 ground_tile、
  玩家 8 帧、Boss 3 招、装饰层）+ 2 张对齐 spritesheet 全部真实产出；13 张全部经 ViewImage 目视确认
  （1 张破图换 seed 重试并如实登记）；三段门禁 EXIT 0/0/0、SCRIPT ERROR=0；零付费、DNF 贴片零进入
  发布路径；`128bit` 歧义显式保留；无伪造、无谎报、无 git 提交。**

---

## 0. 环境事实

| 项 | 值 |
|---|---|
| 工程根 | `F:/Game/aierdengfahuan`（`godot/project.godot`；本轮四路均冻结，未写） |
| DNF 资源 | `D:/WeGameApps/地下城与勇士：创新世纪/ImagePacks2`，实测 **16691 个 NPK** |
| 提取器 | `C:/Users/62668/WorkBuddy/2026-10-31-15-43-21/dfo-extractor.exe`（`preview` / `inspect` / `npk`） |
| ComfyUI output | `F:/Download/ComfyUI-output`（`C:/ComfyUI-aki-v95/output` 符号链接目标） |
| checkpoint | `pixelArtDiffusionXL_spriteShaper.safetensors`（6.9 GB，`/object_info` 枚举确认存在） |
| lora | `pixel-art-xl.safetensors` / `sdxl_lightning_4step_lora.safetensors`（均存在） |
| 目录所有权 | 只写 `teamwork/Rank-4/`、`godot/assets/generated/r23/`、`capture/r23_ref_*`。**未写** `courtyard.tscn` / `project.godot` / `hud.gd` / 既有 `assets/generated` 其它目录 / 任何 `.tres` / `command_center` 工程根（工程根本无该目录） |

---

## 1. 实际交付清单

| # | 产物 | 真跑 / 说明 | 状态 |
|---|---|---|---|
| 1 | `r23_dnf_reference/contact_sheet.png` | 21 格 4× 像素化风格证据联系表（配色条 + 色数/覆盖率标注），ViewImage 真看 | 已产出 |
| 2 | `DNF-STYLE-REFERENCE-R23.md` | 构图 / 配色 / 轮廓 / 光感规律，基于 21 帧实测统计（非主观臆断） | 已写 |
| 3 | `r23_dnf_reference/manifest.json` | 21 帧溯源清单，`published_in_pck: false` + provenance | 已写 |
| 4 | `r23_dnf_reference/.gdignore` + `.gitignore` | Godot 不导入 / `raw/` 原始贴片不入库 | 已写 |
| 5 | `r23_dnf_reference/build_reference.py` | 可复现提取 + 联系表 + 统计管线 | 已写 |
| 6 | `godot/assets/generated/r23/*.png`（13 张） | ComfyUI 本机重绘，128×128 RGBA，见 §2 | 已产出 |
| 7 | `player_spritesheet.png` / `boss_spritesheet.png` | 1024×128 / 384×128，帧序与既有 `.tres` 一致 | 已产出 |
| 8 | `godot/assets/generated/r23/manifest.json` | 来源 / seed / 尺寸 / 实测色数 / pose 名 / `published_in_pck: true` | 已写 |
| 9 | `r23_comfyui/` 工作流与日志 | `test_prompt.json`、`batch_generate.py`、`retry_attack_light.py`、`build_manifest.py`、`batch_log.json`、两张目视联系表 | 已写 |
| 10 | `capture/r23_ref_*` | 2×2 平铺预览 + 三段门禁日志 | 已产出 |
| 11 | 三段门禁 | G1 import → G2 check-only script → G3 quit，`EXIT 0/0/0`，`SCRIPT ERROR\|Parse Error = 0` | 全绿 |
| 12 | `DONE-R23.md` | 本文件 | 已写 |
| 13 | 回执 JSON | `teamwork/command_center/ai/4/outbox/cmd-20261109-133602-467-A4.json` | 已写 |

---

## 2. ComfyUI 实际出图清单（13 张，全部真跑、全部目视通过）

工作流：`pixelArtDiffusionXL_spriteShaper` + `pixel-art-xl`(0.8) + `sdxl_lightning_4step`(0.75)，
`euler / sgm_uniform / steps=8 / cfg=1.8`，512×512 latent → `ImageScale nearest-exact` → **128×128**。
**已移除 `ImageQuantize(colors=256)` 节点**（解除 ≤256 色硬限制，允许 256 色以上）。
像素 100% 来自 ComfyUI 输出 PNG；玩家/Boss/装饰层的 alpha 由本机确定性 flood-fill 抠纯色背景生成
（硬边、不羽化、不绘制新像素）；色数按**非透明像素唯一 RGB**统计，如实登记。

| 文件 / pose | seed | 尺寸 | 实测唯一 RGB | alpha | 备注 |
|---|---|---|---|---|---|
| `player_idle` | 20261109010 | 128×128 | 3760 | RGBA | 帧序 x=0 |
| `player_walk` | 20261109011 | 128×128 | 4944 | RGBA | x=128 |
| `player_run` | 20261109012 | 128×128 | 4642 | RGBA | x=256 |
| `player_roll` | 20261109013 | 128×128 | 3664 | RGBA | x=384 |
| `player_attack_light` | **20261109914** | 128×128 | 6553 | RGBA | x=512；**原 seed 20261109014 破图，换 seed 重试** |
| `player_attack_heavy` | 20261109015 | 128×128 | 4617 | RGBA | x=640；任务点名必交帧 |
| `player_hitstun` | 20261109016 | 128×128 | 4777 | RGBA | x=768 |
| `player_death` | 20261109017 | 128×128 | 3672 | RGBA | x=896 |
| `boss_p1_dagger_slash` | 20261109030 | 128×128 | 5163 | RGBA | x=0 |
| `boss_p1_staff_slam` | 20261109031 | 128×128 | 6269 | RGBA | x=128 |
| `boss_p2_holy_hammer` | 20261109032 | 128×128 | 5392 | RGBA | x=256 |
| `decor_layer` | 20261109050 | 128×128 | 11739 | RGBA | 装饰层 |
| `ground_tile` | 20261109060 | 128×128 | **13605** | 不透明 | **严格无缝平铺**，见 §4 |

**实测色数范围 3664 – 13605，全部 > 256**（满足用户「256 色以上」新口径；不再量化到 ≤256）。
`player_spritesheet.png` = 1024×128 单行 8 帧、`boss_spritesheet.png` = 384×128 单行 3 帧；
**pose 名 / 帧序 / 坐标系与既有 `player_spriteframes.tres`(8) / `boss_spriteframes.tres`(3) 逐字一致**
（boss 第三招沿用 `.tres` 里的 `p2_holy_hammer` 名字）。

---

## 3. DNF 参考提取结论（风格证据，非发布素材）

- 实际提取 **21 张有效贴片 / 13 条 SOURCES / 0 失败**，四类齐全：
  人物 3、怪物 3、地砖 5、特效 7、道具 3。
- **风格结论**（详见 `DNF-STYLE-REFERENCE-R23.md`，基于实测统计）：
  - **构图**：`anchor` 足底锚点 + 居中 + 3/4 前视全身；帧序列横排、`delay=83ms`；
    地砖/道具为顶视正交；对应本项目单行 128px 网格 spritesheet。
  - **配色**：低色数索引色（单帧 4–107 色）；**暖金/土橙**（197,107,41 / 222,148,49 /
    197,148,74）与**冷蓝紫灰**（31,31,39 / 47,47,71 / 127,127,175）成对形成暖冷对比；
    近黑 (16,16,16) 描边；特效高光近白 (226,226,226) / 冷青 (189,255,239)。
    道具饱和度最高（sat 72）、人物最低（sat 23）。
  - **轮廓**：近黑 1px 硬描边、无抗锯齿、平涂 2–3 级硬色阶；轮廓强度分层
    人物 0.582 > 特效 0.413 > 道具 0.339 > 怪物 0.272 > 地砖 0.189（主体越重要边缘越硬）。
  - **光感**：左上暖金 key light + 右下冷蓝紫阴影的固定二分，不做渐变/SSR/HDR；
    亮度分层 特效 139.7 > 道具 107.1 > 地砖 96.1 > 人物 80.0 > 怪物 63.5，
    即「主体中低亮度 + 小面积高光特效点睛」。
- 上述规律已写进 ComfyUI 的 positive/negative prompt（暖金装甲+钴蓝板甲+青宝石点缀、
  近黑硬描边、3 级硬色阶、排除渐变/抗锯齿/景深/重复角色）。

### 3.1 已知限制（如实登记，不掩饰）

1. **超宽横条型 img 本机提取器不支持**：`sprite_commonmap_town_*_tile.NPK` 的 `tile.img` /
   `tile_ex.img`、`sprite_common_commoneffect2_ground.NPK`、`sprite_character_*_effect_*`
   均报 `无效帧尺寸: #0` 或解出 `18×1` / `4274×11360` 异常碎片；`npk --include` 整包解压同样
   得到近全透明碎片与超大图。与 `DNF素材接入说明.md §5.1`「国服新版 NPK / LINK 变体超出本机
   dfo-extractor 版本支持」结论一致。**真正的 DNF 地砖 tile 与技能特效横条贴片本轮未提取到**；
   地砖/特效两类改用 `sprite_map_*` 包内**正常尺寸**的地面、石砌、光晕、粒子贴片（均为真实 DNF 贴片）
   归纳风格规律。
2. **人物为单层时装部件**：`ghosthand.img` 179 帧单层部件，非透明覆盖率仅 0.7%，
   bbox 裁紧放大后联系表上仍呈稀疏细竖条；当前 basics 包仅 `ghosthand` / `pinkghosthand`
   两个部件 img，**不具备五层合成条件**，未产出完整 DNF 人物立绘（与接入说明 §3.C 一致）。
   完整人形轮廓由「怪物」类与 ComfyUI 重绘结果承担，不伪造拼贴。

---

## 4. 目视检查与地面无缝

- **13 张出图目视**：用棋盘格联系表（`r23_comfyui/contact_sheet_generated.png`）ViewImage 真看。
  首次检查发现 `player_attack_light`（seed 20261109014）**生成 4 个重复小人**（破图）；按门禁
  **换 seed 20261109914 + 强化 single/one-figure 约束重试**，重跑后为单个清晰骑士，
  其余 12 张全部清晰可辨、透明背景干净、各帧姿势有区别。重试记录在 `batch_log.json` 与 manifest。
- **ground_tile 无缝**：SDXL 直出并非严格无缝（左右/上下边缘 MAE 12.64 / 23.60）。
  做**最小侵入确定性后处理**（仅把最外 1 行/1 列改为两侧均值并强制四角相等），
  处理后 **LR/TB 边缘 MAE = 0.0 / 0.0，逐像素边缘严格对齐**；
  `capture/r23_ref_ground_tile_2x2.png` 的 2×2 平铺 ViewImage 复核：中央十字接缝消失、
  无可见 1px 色环/模糊带伪影。该后处理为**本机确定性处理、像素仍来自 ComfyUI**，如实登记；
  若要求「必须由模型直接输出严格无缝图」，则本项未达成（见 §8）。
- **DNF 联系表目视**：21 格均有内容，配色条与标签清晰，无空白/破图/纯色块；
  人物 3 格稀疏竖条为客观限制（§3.1）。

---

## 5. 合规边界落实方式

| 约束 | 落实 |
|---|---|
| DNF 贴片仅本机开发参考 | 全部落在 `teamwork/Rank-4/r23_dnf_reference/`（协作空间，非 Godot 资源目录） |
| 参考目录写 `.gdignore` | 已写空 `.gdignore` → Godot 不导入、**不进 pck** |
| manifest 记 `published_in_pck:false` | `r23_dnf_reference/manifest.json` 已记，并附 `provenance` 版权声明（Neople/腾讯） |
| 绝不拷进 `godot/assets/` | `find godot/assets -iname "*dnf*"/*ghosthand*/*kobolt*` **为空**，实测核对 |
| 绝不进 pck/exe/apk/发布包 | 参考目录不在 `res://` 资源路径下、Godot 不导入；发布版美术为本机 ComfyUI 原创 |
| 联系表只作风格证据、不分发可识别商业贴片 | `contact_sheet.png` 为 **4× 像素化**风格证据；`raw/` 原始帧由 `.gitignore` 排除，不入库/不随仓库分发 |
| 可发布素材标记 | `godot/assets/generated/r23/manifest.json` 每项 `published_in_pck: true`，来源为 ComfyUI 本地 |
| 零付费 | 全程仅本机 `dfo-extractor.exe` + 本机 ComfyUI + 本机 PIL，无任何付费素材生成服务 |

**未改**：`courtyard.tscn` / `project.godot` / `hud.gd` / 既有 `assets/generated` 其它目录 /
任何 `.tres`。三段门禁 G1 `--import` 在 `r23/` 内自动生成 15 个 `.import` 元数据（引擎行为，
位于本轮可写目录内）。

---

## 6. GPU 纪律与真跑输出结论

- 最终 `/queue`：`{"queue_running": [], "queue_pending": []}` → **running=0 / pending=0**。
- **一次只跑一个 GPU job**：`batch_generate.py` 串行提交，确认上一个 job `completed` 且
  `/queue running=0` 才提交下一个；`batch_log.json` 记 `blocked=false`、13/13 ok。
- **旧 qwen-image job 不杀不重启**：未触碰 `qwen_3_8b_fp8mixed.safetensors` 及任何既有 job；
  `/history` 原有 683 条记录未改动。
- **`/system_stats` 超时如实登记**：首轮诊断时 `/system_stats`、`/queue`、`/history/<id>` 曾出现
  curl 空返回/超时（服务加载 6.9 GB 模型期间），按「以 /queue 为准、超时如实登记」处理；
  以 ComfyUI `output/` 真实 PNG 为硬证据。`batch_log.json` 记 `queue_timeouts=0`、
  `system_stats_timeouts=0`（批量阶段无超时），首轮超时情况在此显式登记。
- **不无限等待、不伪造 PNG**：脚本每 job 设 240s 上限，超时即停止并登记 `blocked`；本轮 13 张
  全部在时限内真实产出，未触发阻塞。
- **三段门禁**：`--headless --import` / `--headless --check-only --script res://scripts/verify_fx_mobile.gd` /
  `--headless --quit` → **EXIT 0 / 0 / 0**，`SCRIPT ERROR|Parse Error` 三段合计 **0**
  （`capture/r23_ref_g*.log` 留存）。G3 退出时引擎报 `2 ObjectDB instances were leaked`
  （warning，**非 SCRIPT ERROR**），如实登记。
- **真跑失败项：无**（提取 / 出图 / 重试 / 门禁 / 无缝化全部完成）。

---

## 7. `128bit` 歧义（显式保留，不擅自改口径）

用户口径为「**128bit 256色以上**」。本轮落实：
- **128px 基准画布保持不变**（所有单帧 128×128；spritesheet 为 128px 网格横排）；
- **不再强制量化到 ≤256 色**：已移除工作流 `ImageQuantize(colors=256)` 节点，实测色数 3664–13605，
  均 > 256，按非透明像素唯一 RGB 如实登记；
- 保留 alpha（RGBA），地砖另做严格无缝；
- **`128bit` 的具体含义仍待用户确认**：它可能指「位深/色彩精度」「128 位调色板」「128×128 画布的
  另一种表述」或笔误。本轮**不擅自改尺寸口径、不擅自换算**，在 manifest 与本报告显式保留歧义，
  待用户澄清后于 R23B 再决定是否调整。

---

## 8. 未完成项与阻塞

1. **`128bit` 含义待用户确认**（§7），未擅自改尺寸/色彩口径。
2. **R23B 才接入**：本轮仅产出 `r23/` 目录素材与对齐 spritesheet，**未改任何 `.tres` / 场景 /
   渲染脚本**，素材尚未在 courtyard 场景中可见；用户所看「素材太丑」的画面改善需 R23B 接入后
   才能用录屏/画面验证。本轮不做场景改动（任务单⑥明确禁止）。
3. **DNF 横条型 tile / 技能特效贴片未提取到**：本机提取器版本不支持新版 NPK/LINK 变体（§3.1），
   已用正常尺寸 map 贴片补齐四类风格规律，但严格意义上的「DNF 地砖 tile 贴片 / 技能特效横条」
   缺失，如实登记；如需可后续换用支持该变体的提取器。
4. **DNF 完整人物立绘未产出**：单层部件 + 不具备五层合成条件（§3.1）。
5. **ground_tile 严格无缝由本机后处理达成**，非 ComfyUI 模型直接输出的无缝图（§4）。
   若要求模型直出无缝，本项未达成。
6. **破图重试一次**：`player_attack_light` 首轮破图，换 seed 重试成功（§4）；其余 12 张一次通过。
7. **G3 引擎 warning**：`2 ObjectDB instances were leaked`（非 SCRIPT ERROR，不掩盖）。
8. **首轮 `/system_stats` 等 curl 超时**（§6），已如实登记，未据此谎报状态。
9. **阻塞：无**（`blocked=false`、13/13 出图完成、门禁全绿）。交付已完成部分即全部计划内产物。

---

## 9. 回执

- 精确路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/4/outbox/cmd-20261109-133602-467-A4.json`
- 内容：`{"task_id":"cmd-20261109-133602-467-A4","ai":4,"status":"done","result":"引用 DONE-R23.md 实际结论"}`
- 注意：**未写到工程根 `command_center/`**（工程根本轮复核确认无该目录）。
- **投递事实（如实登记）**：回执首次写入精确路径后被调度中枢即时收取并归档至
  `teamwork/command_center/dispatcher/receipts/cmd-20261109-133602-467-A4.json`
  （14:09，1332 字节），`outbox/` 被清空；已 Read 校验归档副本内容与写入件**逐字一致**、
  `task_id`/`ai`/`status` 正确。随后**幂等重写一次**到精确路径。
  此为协作空间正常消费行为（与 `DONE-R22.md §7` 一致），**非回执未写或路径错误**；
  `outbox/` 校验时可能为空，`dispatcher/receipts/` 留有权威副本，
  可用 `Glob **/cmd-20261109-133602-467-A4.json` 定位。

详细风格规律见 `DNF-STYLE-REFERENCE-R23.md`；逐张 seed/色数/合规见
`godot/assets/generated/r23/manifest.json` 与 `r23_comfyui/batch_log.json`。
