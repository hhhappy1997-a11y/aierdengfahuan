# ASSET-SPEC-R23 · R23 新素材 I-5 接入契约（可执行校验条目）

- 任务单：`cmd-20261109-133602-471-A2`（[ROUND=R23]）
- 定义方：Rank-2（战斗系统与数据驱动）
- 契约定位：**I-5（Rank-4 素材 → Rank-1 接入）**。按 `teamwork/Rank-2/接口契约.md:3,19`，I-5 不经过 2 号；本轮按总指挥派单「由你定义接入契约」，由 Rank-2 出具校验条目，供 **R23B 接入时逐项校验**。
- 口径来源：用户新口径「**128bit 256色以上**」，改变了既有 **≤256 色** 规格。
- 状态：契约已定义；**R23 新素材本轮尚未产出**，`godot/assets/generated/r23/`（Rank-4 所有权）为预期落点，本文件不创建、不写入该目录。
- 本文件性质：§3 每条均为「**文件 / 字段 / 期望值 / 判定方法**」四元组，R23B 可直接逐条执行，不是描述性说明。

---

## 1. 规格变更登记（R23 相对既有基线）

### 1.1 既有 ≤256 色规格的逐字证据（基线文件）

基线文件 = `godot/assets/generated/chars/import.json`（主角真实交付）与 `godot/assets/generated/import.json`（Rank-4 样例）。逐字证据：

| 基线文件:行 | 字段 | 既有值 | 语义 |
|---|---|---|---|
| `chars/import.json:80` | `max_colors` | `256` | 色数**上限** ≤256 |
| `chars/import.json:81` | `indexed` | `true` | 强制索引色 |
| `chars/import.json:78` | `palette` | `"hd2d_index_256_v1"` | 绑定 256 色调色板 |
| `chars/import.json:173` | `palette_scope` | `"shared_sheet_256"` | 全表共用 256 色 |
| `chars/import.json:174` | `unique_opaque_rgb` | `250` | 全表唯一不透明色数 250 |
| `chars/import.json:175` | `global_quantize` | `"Pillow MEDIANCUT 256, dither=NONE, alpha preserved"` | 整表 256 色量化 |
| `chars/import.json:91` | `generated_by` | 含 `"ImageQuantize(256)"` | 生成端 256 色量化 |
| `chars/import.json:176` | `quality_gate` | 含 `"每帧<=256色"` | 每帧色数上限 |
| `chars/import.json:94` | `notes` | 含 `"确保全项目共用一份 ≤256 色索引调色板"` | ≤256 声明 |
| `chars/import.json:96-161` | `frames[].colors` | `100~154` | 各帧实际色数 |
| `generated/import.json:23` | `canvas_base_px` | `128` | 生成端设计基准画布 |
| `generated/import.json:6-7` | `frame_width/height` | `32` | 样例交付端单帧 32×32（**非**运行权威） |
| `generated/import.json:56-57` | `sample_only` / `r2_note` | `true` / 样例说明 | 明确「非真实资产交付，不进入 res://assets/generated/」 |

### 1.2 R23 裁决

| 维度 | 既有（废止） | R23（生效） |
|---|---|---|
| 色数 | **≤256 上限** | **≥256 下限**（任务单口径「256色以上」取 `>=256`，含 256） |
| 索引色 | `indexed:true` 强制 | 不强制；RGBA 直出亦可 |
| 调色板 | 绑定 `hd2d_index_256_v1` / 全表 256 色量化 | 不绑定、不做 256 色量化 |
| 量化 | `ImageQuantize(256)` / `MEDIANCUT 256` | 废止 |
| 唯一不透明色 | `unique_opaque_rgb:250` | `unique_opaque_rgb >= 256` |
| alpha | 既有已「保留 alpha」 | **R23 继续保留且升为强制字段**（§3 B 组） |
| 画布 | `base_canvas_px:128`（`chars`）/`canvas_base_px:128`（样例） | **128px 基准画布，且交付端单帧亦为 128×128**（以运行权威 tres 为准，见 §1.3） |
| pose/帧序/坐标系 | 既有 tres 8/3 动画 | **必须与既有 tres 完全一致**（§3 C 组） |

### 1.3 单帧尺寸口径裁决（消除样例歧义）

`generated/import.json:57` 的 `r2_note` 称「128px 为生成端设计基准画布，frame_width/height=32 为交付端单帧尺寸」。但**运行权威** `godot/assets/generated/chars/player_spriteframes.tres:7-35` 与 `godot/assets/generated/boss/boss_spriteframes.tres:7-15` 的 `AtlasTexture.region` 全部为 `Rect2(*, 0, 128, 128)`。

> **R23 契约裁决**：以运行权威 tres 为准 —— 生成端基准画布 = 交付端单帧 = **128×128**。`generated/import.json` 的 `32×32` 因 `sample_only:true` 明确不进发布包，不作为 R23 契约基线；若 R23B 交付中出现 `frame_width/height=32`，判 **FAIL**。

---

## 2. `128bit` 歧义登记（保留待用户确认，不擅自解释）

用户原话「128bit 256色以上」中的 `128bit` 存在歧义，候选解读：

| 候选 | 解读 | 与既有证据关系 |
|---|---|---|
| (a) | `128bit` 为 **128px 基准画布** 的笔误 | 与 `chars/import.json:79 base_canvas_px=128`、`generated/import.json:23 canvas_base_px=128` 一致 |
| (b) | **128-bit 位深 / 色深** | 图像领域无标准 128-bit 像素格式（常见 8/16/24/32-bit）；与「256色以上」不构成常规对应关系 |
| (c) | `128` 与 `bit` 分指两件事：128px 画布 + 某位深要求 | 位深部分仍不明 |
| (d) | 其它（加密强度 / 资产编号等） | 无证据 |

**契约裁决（必须遵守）**：

1. **不将 `128bit` 编码进任何字段的期望值**；§3 中任何条目都不因 `128bit` 设阈值。
2. R23 `import.json` 必须含 `bit_depth_128_spec` 字段，值固定为 `"PENDING_USER_CONFIRMATION"`（见 §3 F 组），作为挂起标记。
3. 用户确认前，该维度**不参与 PASS/FAIL 合计**（挂起，既不算 PASS 也不算 FAIL）；可无歧义执行的条目（128px 画布、色数 ≥256、RGBA alpha、pose 对齐、字段清单、零付费/DNF 隔离）照常逐条校验。
4. 用户确认后由 Rank-2 补写 §3 新条目，再纳入合计；确认前**不擅自解释、不伪造字段值**。

---

## 3. 可执行校验条目表（核心）

### 路径占位符

- `<r23>` = `godot/assets/generated/r23/`（R23 新素材预期落点，Rank-4 所有权，本轮不创建）。
- `<r23>/player/` = 主角 8 pose 素材；`<r23>/boss/` = Boss 3 pose 素材。
- `<spec>` = 本文件；`<gate-log>` = `teamwork/Rank-2/R23-*.log`。
- 「基线」列给出既有运行权威文件:行，作为期望值来源。

### A 组 · 几何 / 画布（128px 基准）

| ID | 文件 | 字段 / key | 期望值 | 判定方法 | 基线 |
|---|---|---|---|---|---|
| I-5-A01 | `<r23>/*/import.json` | `base_canvas_px` | `128`（int） | 字段存在且 `==128` | `chars/import.json:79` |
| I-5-A02 | `<r23>/*/import.json` | `frame_width` | `128`（int） | `==128` | `player_spriteframes.tres:7-35` region |
| I-5-A03 | `<r23>/*/import.json` | `frame_height` | `128`（int） | `==128` | 同上 |
| I-5-A04 | `<r23>/*/import.json` | `canvas_base_px`（若使用该别名） | `128`（int） | 若存在则 `==128`；与 `base_canvas_px` 不得冲突 | `generated/import.json:23` |
| I-5-A05 | `<r23>/*/*.png` 精灵表 | 单帧尺寸 | 每帧精确 `128×128`，表宽 `=128*columns`，表高 `=128*rows` | 读 IHDR 与逐 128 步长切片测量 | `player_spriteframes.tres` / `boss_spriteframes.tres` region |
| I-5-A06 | `<r23>/*/import.json` | 不得出现 `frame_width=32` 或 `frame_height=32` | 无 32 交付尺寸 | 数值判定；出现即 FAIL | §1.3 裁决（样例 `sample_only`） |
| I-5-A07 | `<r23>/*/import.json` | `filter` | `"nearest"` | `==` | `chars/import.json:84` |
| I-5-A08 | `<r23>/*/import.json` | `mipmaps` | `false` | `==` | `chars/import.json:85` |
| I-5-A09 | `<r23>/*/import.json` | `compression` | `"lossless"` | `==` | `chars/import.json:86` |
| I-5-A10 | `<r23>/*/import.json` | `default_texture_filter` | `0` | `==0` | `chars/import.json:87` |

### B 组 · 色彩 ≥256 / RGBA 保留 alpha

| ID | 文件 | 字段 / key | 期望值 | 判定方法 | 基线 |
|---|---|---|---|---|---|
| I-5-B01 | `<r23>/*/import.json` | `min_colors`（R23 新增） | `256`（int） | 字段存在且 `==256` | 任务单「色数 ≥256」 |
| I-5-B02 | `<r23>/*/import.json` | `unique_opaque_rgb` | `>=256`（int） | 数值 `>=256`；**废止既有 `250`** | `chars/import.json:174` |
| I-5-B03 | `<r23>/*/import.json` | `max_colors` | 不得存在；若存在不得承载 ≤256 上限语义（值须 `>=256` 且不作上限） | key 不存在优先；存在则值 `>=256` | 废止 `chars/import.json:80` |
| I-5-B04 | `<r23>/*/import.json` | `indexed` | 不得为 `true`；为 `false` 或省略 | `!=true` | 废止 `chars/import.json:81` |
| I-5-B05 | `<r23>/*/import.json` | `quality_gate` | 不得含子串 `<=256色` / `每帧<=256`；须含 `>=256` 下限口径 | 子串判定 | 废止 `chars/import.json:176` |
| I-5-B06 | `<r23>/*/import.json` | `global_quantize` / `generated_by` | 不得含 `ImageQuantize(256)` / `MEDIANCUT 256` / `256 色量化` | 子串判定 | 废止 `chars/import.json:91,175` |
| I-5-B07 | `<r23>/*/import.json` | `palette` / `palette_scope` | 不得为 `hd2d_index_256_v1` / `shared_sheet_256` 等 256 索引绑定值 | 值判定 | 废止 `chars/import.json:78,173` |
| I-5-B08 | `<r23>/*/import.json` | `frames[].colors` | 每一帧 `colors >= 256` | 逐帧数值 `>=256` | 既有 `100~154` 全部不达标，R23 必须突破 |
| I-5-B09 | `<r23>/*/import.json` | `pixel_format`（R23 新增） | `"RGBA8"` | `==` | 用户「RGBA」 |
| I-5-B10 | `<r23>/*/import.json` | `alpha_preserved`（R23 新增） | `true` | `==true` | `chars/import.json:175,198` `"alpha preserved"/"alpha kept"` |
| I-5-B11 | `<r23>/*/*.png` | PNG IHDR color type | `6`（RGBA，4 通道）；或 `2`+`tRNS` 且解析后具 alpha | 读 IHDR | RGBA 保留 alpha |
| I-5-B12 | `<r23>/*/*.png` | alpha 通道实测 | 存在 `alpha==0` 的透明像素，且非全 `255`；去重 `(r,g,b,a)` 组合中含 alpha 变化 | 像素统计 | 不得压平为 RGB / 不得丢透明 |
| I-5-B13 | `<r23>/*/*.png` | 单帧去重不透明色数 | `>=256`（唯一不透明 RGB 计数） | 逐帧像素统计，与 `frames[].colors` / `unique_opaque_rgb` 声明值交叉核对 | 声明值 vs 实测值须一致 |

### C 组 · pose 名 / 帧序 / 坐标系（与既有 tres 完全一致）

**Player 8 pose（基线 `player_spriteframes.tres:37-102` + `chars/import.json:10-77`）**

| index | pose | region.x | loop |
|---:|---|---:|---:|
| 0 | `idle` | 0 | 1 |
| 1 | `walk` | 128 | 1 |
| 2 | `run` | 256 | 1 |
| 3 | `roll` | 384 | 0 |
| 4 | `attack_light` | 512 | 0 |
| 5 | `attack_heavy` | 640 | 0 |
| 6 | `hitstun` | 768 | 0 |
| 7 | `death` | 896 | 0 |

| ID | 文件 | 字段 / key | 期望值 | 判定方法 | 基线 |
|---|---|---|---|---|---|
| I-5-C01 | `<r23>/player/import.json` | `pose_names` | 恰为 `[idle,walk,run,roll,attack_light,attack_heavy,hitstun,death]`，**顺序一致、长度=8** | 序列相等比对 | `chars/import.json:68-77` |
| I-5-C02 | `<r23>/player/import.json` | `actions[].name` | 同上 8 名，顺序一致 | 序列相等比对 | `chars/import.json:10-67` |
| I-5-C03 | `<r23>/player/import.json` | `actions[].start_frame` / `end_frame` | `idle=0/0, walk=1/1, run=2/2, roll=3/3, attack_light=4/4, attack_heavy=5/5, hitstun=6/6, death=7/7` | 逐项 `start==end==index` | `chars/import.json:10-67` |
| I-5-C04 | `<r23>/player/import.json` | `columns` / `rows` | `8` / `1` | `==` | `chars/import.json:4-5` |
| I-5-C05 | `<r23>/player/import.json` | `anchor` | `[0.5, 1.0]`（底部中心、脚贴地、全帧共用、禁止逐帧偏移） | 数组相等 | `chars/import.json:6-9` |
| I-5-C06 | `<r23>/player/*.tres`（若重生成 SpriteFrames） | `animations[].name` | 8 名与 C01 集合一致 | 集合相等 | `player_spriteframes.tres:44,52,60,68,76,84,92,100` |
| I-5-C07 | `<r23>/player/*.tres` | 每个 `AtlasTexture.region` | `Rect2(index*128, 0, 128, 128)`，index 0..7 | 逐帧比对 region.x/y/w/h | `player_spriteframes.tres:7,11,15,19,23,27,31,35` |
| I-5-C08 | `<r23>/player/*.tres` | `animations[].loop` | idle/run/walk=`1`，其余 5 个=`0` | 逐项比对 | `player_spriteframes.tres:43,51,59,67,75,83,91,99` |

**Boss 3 pose（基线 `boss_spriteframes.tres:17-42`）**

| index | pose | region.x |
|---:|---|---:|
| 0 | `p1_dagger_slash` | 0 |
| 1 | `p1_staff_slam` | 128 |
| 2 | `p2_holy_hammer` | 256 |

| ID | 文件 | 字段 / key | 期望值 | 判定方法 | 基线 |
|---|---|---|---|---|---|
| I-5-C09 | `<r23>/boss/import.json` | `pose_names` | 恰为 `[p1_dagger_slash, p1_staff_slam, p2_holy_hammer]`，**顺序一致、长度=3、含 `p1_`/`p2_` 前缀** | 序列相等比对 | `boss_spriteframes.tres:24,32,40` |
| I-5-C10 | `<r23>/boss/*.tres` | `animations[].name` | 同上 3 名 | 集合相等 | `boss_spriteframes.tres:24,32,40` |
| I-5-C11 | `<r23>/boss/*.tres` | 每个 `AtlasTexture.region` | `Rect2(index*128, 0, 128, 128)`，index 0..2 | 逐帧比对 | `boss_spriteframes.tres:7,11,15` |
| I-5-C12 | `<r23>/boss/import.json` | `columns` / `rows` | `3` / `1` | `==` | `boss_spriteframes.tres` 3 帧横排 |
| I-5-C13 | `<r23>/boss/import.json` | `anchor` | 与 player 同坐标系（底部中心 `[0.5,1.0]`）；不得逐帧偏移 | 值/语义判定 | `chars/import.json:6-9` + 坐标系一致口径 |
| I-5-C14 | `<r23>/boss/import.json` | spriteframes 动画数 | `==3`；**不得**因数据层 `pose_keys` 有 5 个（`p1_dagger_slash/p1_staff_slam/p2_dagger_slash/p2_holy_hammer/p2_staff_slam`）就扩成 5 帧 | 数值 `==3` | `R23-verify650-run.log` `[ACTUAL][BOSS] pose_keys=...`（5 个为数据表派生，非 spriteframes 动画） |
| I-5-C15 | 交叉核对 | 3 个 spriteframes 动画名 | 必须等于 `verify_frame_data.gd:36-40` `BOSS_POSE_MOVES` 与 `combat_data_validator.gd:30-34` `BOSS_POSE_MOVES` 的键集合 | 集合相等 | 保证帧数据回归 47/71/91 不回退 |

### D 组 · import.json 字段清单（必填 / 废止 / 新增）

| ID | 文件 | 字段 / key | 期望值 | 判定方法 | 说明 |
|---|---|---|---|---|---|
| I-5-D01 | `<r23>/*/import.json` | 文件本身 | 合法 JSON、UTF-8、可解析 | JSON.parse | 前置条件 |
| I-5-D02 | `<r23>/*/import.json` | `schema_version` | 非空字符串（对齐样例 `"1.0"`） | key 存在 + 类型 | `generated/import.json:2` |
| I-5-D03 | `<r23>/*/import.json` | `asset_id` | 非空字符串 | key 存在 + 类型 | `generated/import.json:3` |
| I-5-D04 | `<r23>/*/import.json` | `sprite_sheet` | 非空字符串，且所指 `.png` 在同目录真实存在 | key 存在 + 文件存在 | `chars/import.json:95` |
| I-5-D05 | `<r23>/*/import.json` | `frames[]` | 数组长度 = `columns`（player 8 / boss 3）；每项含 `index/pose/file/colors` | 结构 + 长度 | `chars/import.json:96-161` |
| I-5-D06 | `<r23>/*/import.json` | `frames[].index` / `.pose` | 与 C 组帧序/pose 名逐项一致 | 序列比对 | C01/C09 |
| I-5-D07 | `<r23>/*/import.json` | `actions[]` | 每项含 `name/start_frame/end_frame/fps/loop` | 结构校验 | `chars/import.json:10-67` |
| I-5-D08 | `<r23>/*/import.json` | `layer_type` | 非空（既有 `"base"`） | key 存在 | `chars/import.json:82` |
| I-5-D09 | `<r23>/*/import.json` | `source_file` / `generated_by` | 非空；`generated_by` 不得含 `ImageQuantize(256)` | 子串判定 | `chars/import.json:91-92` |
| I-5-D10 | `<r23>/*/import.json` | 必填字段集合 | `base_canvas_px, frame_width, frame_height, columns, rows, anchor, actions, pose_names, frames, sprite_sheet, filter, mipmaps, compression, default_texture_filter, min_colors, unique_opaque_rgb, pixel_format, alpha_preserved, zero_external_dependency, paid_service, dnf_in_release, bit_depth_128_spec` **全部存在** | 逐 key 存在性 | §3 A/B/C/E/F 汇总 |
| I-5-D11 | `<r23>/*/import.json` | 废止字段集合 | `max_colors(≤256语义), indexed:true, palette:hd2d_index_256_v1, palette_scope:shared_sheet_256, global_quantize含256, generated_by含ImageQuantize(256), quality_gate含<=256色` **均不得出现** | 逐 key/子串不存在 | §1.1 / §1.2 |
| I-5-D12 | `<r23>/*/import.json` | `frames[].colors` 与 B13 PNG 实测 | 声明值 == 实测唯一不透明色数，且 `>=256` | 交叉核对 | 防声明/实测脱节 |

**R23 新增字段名（Rank-2 提议，须 Rank-4 / 总指挥在 R23B 前确认命名）**：`min_colors`(B01)、`pixel_format`(B09)、`alpha_preserved`(B10)、`paid_service`(E01)、`dnf_reference_only`/`dnf_in_release`(E05)、`bit_depth_128_spec`(F01)。若命名变更，须同步更新本文件条目 ID 后再执行校验。

### E 组 · 零付费 / DNF 仅参考不进发布包

| ID | 文件 | 字段 / key | 期望值 | 判定方法 | 依据 |
|---|---|---|---|---|---|
| I-5-E01 | `<r23>/*/import.json` | `paid_service`（R23 新增） | `false` | `==false` | 公共契约「零付费、不引入付费素材生成服务」 |
| I-5-E02 | `<r23>/*/import.json` | `zero_external_dependency` | `true` | `==true` | `chars/import.json:93` 既有字段 |
| I-5-E03 | `<r23>/*/import.json` | `pipeline` / `pipeline_tier` / `generated_by` | 不得出现付费素材生成服务 / 商业图库 / 订阅 API 标识；须为本地生成或自绘 | 白名单 + 子串判定 | 公共契约 |
| I-5-E04 | `<r23>/` 全目录 + 发布包清单 | DNF 贴片文件 | 不得存在任何 DNF 参考图 / 贴图（`*.png/*.jpg/*.webp/*.tres` 等） | 文件名 + 清单判定 | 派单「DNF 贴片仅本机风格参考、绝不进发布包」 |
| I-5-E05 | `<r23>/*/import.json` | `dnf_reference_only` / `dnf_in_release`（R23 新增） | `true` / `false` | 分别 `==true` / `==false` | 派单 |
| I-5-E06 | 发布包（导出模板 / 打包清单） | 素材来源 | 全部为本地生成/自绘；`generated_by` 可追溯；无外部付费依赖 | 清单审计 | 公共契约 |

### F 组 · `128bit` 挂起项（不计 PASS/FAIL）

| ID | 文件 | 字段 / key | 期望值 | 判定方法 | 说明 |
|---|---|---|---|---|---|
| I-5-F01 | `<r23>/*/import.json` | `bit_depth_128_spec` | `"PENDING_USER_CONFIRMATION"` | `==` 字符串 | §2 歧义挂起标记 |
| I-5-F02 | 全部 §3 条目 | 是否含 `128bit` 派生阈值 | 不得出现 | 审阅判定 | §2 第 1 条：不编码进任何字段期望值 |

---

## 4. R23B 接入校验流程（可执行）

1. Rank-4 产出 R23 新素材于 `<r23>`（本轮 R23 **不产出、不校验**，仅定义契约）。
2. 对 `<r23>/player/` 与 `<r23>/boss/` 各执行一遍 §3 的 A/B/C/D/E 组全部条目；每条输出：
   `条目ID | 实际值 | 期望值 | PASS|FAIL | 来源文件:行`。
3. F 组（挂起项）单列输出，**不计入 PASS/FAIL 合计**。
4. **全部非挂起条目 PASS 才允许接入**；任一 FAIL 拒绝接入并回报 Rank-4 修正后重校。
5. 接入后必须重跑数据回归：
   - `D:/Godot/Godot_v4.7.2-stable_win64.exe --headless --path F:/Game/aierdengfahuan/godot --script res://scripts/verify_frame_data.gd`
   - 确认 `PASS_COUNT=650 FAIL_COUNT=0 RESULT=ALL_MATCH`、`VALIDATOR_CHECKS=533 ... VALIDATOR_ERROR=0`、翻滚 `4/9/9=22@60` / 无敌 `[4,13)`、Boss `47/71/91`、E-8 `400/480/420` **不回退**。
6. 三段门禁 `--headless --import` → `--check-only --script` → `--headless --quit`，`grep SCRIPT ERROR=0`。

---

## 5. 本轮 R23 已真跑守住的数据基线（不回退）

来源：`teamwork/Rank-2/R23-verify650-run.log`（`verify_frame_data.gd` 只调用、未修改）。

| 项 | 真跑值 | 结论 |
|---|---|---|
| 650 回归合计 | `PASS_COUNT=650 FAIL_COUNT=0` | `RESULT=ALL_MATCH`（组A `DOC_PASS=111 DOC_FAIL=0` / 组B `VERDICT_PASS=6 VERDICT_FAIL=0` / 组C `VALIDATOR_PASS=533`） |
| `CombatDataValidator.validate_all()` | `checks=533 pass=533 fail=0 errors=0` | `VALIDATOR_CHECKS=533 ... VALIDATOR_ERROR=0` |
| 翻滚 `action_04_roll` | `startup=4 active=9 recovery=9 inv=[4,13) logic_fps=60 total=22` | 4/9/9=22 帧@60、无敌 [4,13) 不回退 |
| 玩家 8 动作 | `logic_fps=[60×8]` | @60 不回退 |
| Boss 三招 | `p1_dagger_slash=47`、`p1_staff_slam=71`、`p2_holy_hammer=91` | hit `[18,23)/[30,37)/[42,51)` 不回退 |
| E-8 max_resistance | `400.0 / 480.0 / 420.0` | bleed/poison/frost 不回退 |

> **口径边界**：R23 变更仅作用于 **I-5 素材规格**（色数 / alpha / 画布 / 字段），**不触碰任何 `godot/data/combat/*.tres` 数据层**。本轮 `project.godot` BEFORE/AFTER = `1794194044 6664` 完全一致，未人工改任何工程文件。R23B 接入后仍须按 §4 第 5 步复跑，确认上述数字不回退。

---

## 6. 边界与所有权（本轮遵守）

- 本轮只写 `teamwork/Rank-2/`：`ASSET-SPEC-R23.md`、`DONE-R23.md`、`R23-*.log`。
- **不写任何 `godot/` 工程文件**（脚本 / 场景 / `.tres` / `project.godot`）、不写其它 Rank 文档、不写工程根 `command_center/`。
- `<r23>`（`godot/assets/generated/r23/`）与 `teamwork/Rank-4/` 归 **Rank-4**；`courtyard.tscn` 与渲染脚本归 **Rank-1**；本轮无人写 `project.godot`。
- 三段门禁中 `--headless --import` 由引擎自动维护 `.godot/` 缓存（class/uid cache），本轮**无新增 class_name、无新增/修改任何工程源文件**；`project.godot` 定点 stat 前后一致。
- 零付费、不引入付费素材生成服务；不新建只读探针/巡检脚本；不主动扫目录做进度巡检；不伪造产物、不谎报成功、不自行 git。

---

## 7. 未完成项 / 待确认

1. **`128bit` 歧义待用户确认**（§2）：候选 (a)~(d) 未裁决，`bit_depth_128_spec="PENDING_USER_CONFIRMATION"` 挂起，确认后补条目。
2. **R23 新素材尚未产出**：§3 全部条目本轮**未执行**（无素材可校），待 R23B 按 §4 逐条校验；本轮不伪造校验结果。
3. **R23 新增字段名待确认**（§3 D 末）：`min_colors` / `pixel_format` / `alpha_preserved` / `paid_service` / `dnf_*` / `bit_depth_128_spec` 为 Rank-2 提议命名，须 Rank-4 / 总指挥在 R23B 前确认后锁定。
4. **既有 ≤256 基线文件本轮不回改**：`chars/import.json` 等既有交付保持原值（本轮只读引用作证据），R23 新口径只作用于 R23 新素材，避免污染既有回归。
