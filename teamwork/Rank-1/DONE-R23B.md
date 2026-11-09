# DONE-R23B.md — Rank-1 接入 R23 新素材 + 15 秒录屏回看 + 重导双产物（ROUND=R23B）

- 补单 id：`cmd-20261109-141302-870-A1`（`[ROUND=R23B]`）
- 执行：Rank-1（引擎架构与渲染）
- 时间：2026-11-09（本机 +0800）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
- 工程根：`F:/Game/aierdengfahuan`（`godot/project.godot`）
- 回执路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261109-141302-870-A1.json`

> **本文件按真跑进度增量写入；所有数字均为本机真实执行输出，无伪造、无照抄派单数字。**
> **诚实声明（置顶）**：`ASSET-SPEC-R23.md` §3 假设的 `<r23>/player/import.json`、`<r23>/boss/import.json`
> 及 §3 D 末"须确认后锁定"的提议字段名，在 Rank-4 实际交付中**并不存在**（实测 `find` + `json.load` 确认）。
> 本轮**不冒充 §3 字面四元组全 PASS**，逐条披露载体映射与差异，并把该差异与 `128bit` 歧义一并作为
> 未完成/待裁决项上报。接入裁决见 §4，**显式声明、可复核、可推翻**。

---

## 0. 环境事实与判定基准

### 0.1 路径澄清（真跑前核对）

| 项 | 事实 |
|---|---|
| 会话工作目录 | `f:\Download\aierdengfahuan`（**空壳**，仅 `.playwright-mcp/` `.workbuddy/` `screenshots/`） |
| 真实工程根 | `F:/Game/aierdengfahuan`（含 `.git/`、`godot/`、`teamwork/`、`capture/`、`build/`） |
| 结论 | 二者是**不同目录**，本轮所有相对路径一律以 `F:/Game/aierdengfahuan` 为工程根 |
| 引擎 | `/d/Godot/Godot_v4.7.2-stable_win64.exe` 存在（180,858,888 B） |
| ffmpeg | `/c/Users/62668/.workbuddy/binaries/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg`，`9.0.2`，含 `--enable-libx264` |
| Android | `D:/AndroidToolchain/sdk`（build-tools 34.0.0 / 36.1.0）、`D:/AndroidToolchain/jdk17/bin/java.exe`、`D:/AndroidToolchain/debug.keystore` 均在 |
| 导出预设 | `godot/export_presets.cfg`：preset.0 `Windows Desktop`（`embed_pck=false`）、preset.1 `Android`（`package/unique_name="com.aierdengfahuan.game"`） |
| .gitignore | 含 `build/`、`*.exe`、`*.pck`、`*.apk`、`*.aab`、`*.log` → 产物不入库 |
| R21B 旧产物（真跑 stat） | exe `109,127,680` / pck `993,736` / apk `29,239,499` / idsig `234,930` B（时间戳 12:30/12:31） |

### 0.2 校验判定基准（显式声明，可复核可推翻）

1. `ASSET-SPEC-R23.md` §2 第 3 条明文授权：「用户确认 `128bit` 前，**可无歧义执行的条目**
   （128px 画布、色数 ≥256、RGBA alpha、pose 对齐、字段清单、零付费/DNF 隔离）**照常逐条校验**」；
   §2 第 1 条：「不将 `128bit` 编码进任何字段的期望值」。本轮用户尚未确认 `128bit`，该口径适用。
2. §3 D 末 / §7.3 自述：`min_colors` / `pixel_format` / `alpha_preserved` / `paid_service` /
   `dnf_in_release` / `bit_depth_128_spec` 等为「**Rank-2 提议，须 Rank-4 / 总指挥在 R23B 前确认命名**」，
   **实际未锁定**。故按未锁定字段名逐 key 判定无从执行。
3. 因此本轮以**契约「期望值 / 判定方法」的实质语义**为准，把每条的「文件 / 字段」映射到 Rank-4
   实际交付中**承载同一语义的真实证据**：`r23/manifest.json` 等价字段、`r23/*.png.import` 引擎导入参数、
   15 张 PNG 的 PIL 实测、既有运行权威 `.tres`、`verify_frame_data.gd` + `combat_data_validator.gd`。
4. **每条均给出真实实测值**（PNG 像素统计 / JSON 解析 / 文件 stat / grep），**未编造任何字段值**、
   **未照抄派单数字**；载体差异逐条在「备注」列披露。
5. F 组 2 条（`128bit` 歧义）**挂起，不计 PASS/FAIL**，保留待用户确认。

### 0.3 真实证据清单（全部本机真跑）

| 编号 | 证据 | 真跑方式 |
|---|---|---|
| E1 | 15 张 r23 PNG | Python + Pillow 12.3.0：读 IHDR（宽/高/bit depth/color type/interlace）、`convert("RGBA")` 逐像素统计唯一不透明 RGB / alpha 分布 |
| E2 | `r23/manifest.json` | `json.load` 解析（17 个顶层键，UTF-8 合法）+ 全文子串审计 |
| E3 | `chars/import.json` | 既有 ≤256 基线（**本轮不回改**），`json.load` 合法（34 键） |
| E4 | `player_spriteframes.tres` / `boss_spriteframes.tres` / `ground_material.tres` | Read 全文，逐行核对 region / loop / ext_resource path |
| E5 | `r23/*.png.import`（15 份） | 读 `[params]`：`compress/mode=0`、`mipmaps/generate=false` |
| E6 | spritesheet 帧序 | PIL 按 128 步长切片，与 8/3 张单帧 PNG **逐像素比对**（结果见 §1.3） |
| E7 | `verify_frame_data.gd:36-40` / `combat_data_validator.gd:30-34` | grep `BOSS_POSE_MOVES` 键集合 |
| E8 | DNF 隔离 | `find godot/assets` 全目录名过滤 + `r23/` 非预期文件过滤 |
| E9 | `courtyard.tscn` | `grep -c "^\[node "` 文本回读 = **27**（与 R23 登记一致） |

### 0.4 PNG 实测总表（E1，15 张，全部 `color type=6` RGBA / `bit depth=8` / `interlace=0` / Pillow `mode=RGBA`）

| 文件 | IHDR | 唯一不透明 RGB | alpha 值数 | minA/maxA | a=0 像素 |
|---|---|---|---|---|---|
| player_idle / walk / run / roll | 128×128 | 3760 / 4944 / 4642 / 3664 | 2 | 0 / 255 | 有 |
| player_attack_light / attack_heavy / hitstun / death | 128×128 | 6553 / 4617 / 4777 / 3672 | 2 | 0 / 255 | 有 |
| boss_p1_dagger_slash / p1_staff_slam / p2_holy_hammer | 128×128 | 5163 / 6269 / 5392 | 2 | 0 / 255 | 有 |
| decor_layer | 128×128 | 11739 | 2 | 0 / 255 | 有 |
| ground_tile | 128×128 | 13605 | 1 | 255 / 255 | 0（不透明地砖，manifest 已登记） |
| **player_spritesheet** | **1024×128** | **34877** | 2 | 0 / 255 | 有 |
| **boss_spritesheet** | **384×128** | **16733** | 2 | 0 / 255 | 有 |

> **派单数字溯源（如实）**：派单称「实测色数 3664~34877」——最小值 `3664` = `player_roll.png`，
> 最大值 `34877` = **`player_spritesheet.png` 全表去重不透明 RGB**（E1 实测）。
> `manifest.json` 的 `color_range_actual:[3664,13605]` 是 **13 张单帧 assets[] 口径**（最大 13605 =
> `ground_tile`），**不含 spritesheet**。二者为**统计口径差异，不是伪造、也不是数据冲突**，如实登记。
> 13 张单帧实测 `uniq_opaque_rgb` 与 `manifest.assets[].unique_rgb_visible` **逐项完全一致**（B13/D12）。

---

## 1. 56 条校验逐条结果（A~E 组，全部真跑）

> 格式：`ID | 契约期望值 | 真实实测值 / 证据 | 判定 | 载体差异备注`
> 「载体差异」= 契约 §3 假定的 `<r23>/player|boss/import.json` 文件 / 提议字段名在实际交付中不存在，
> 已映射到真实等价证据；**不编造字段值**。

### 1.1 A 组 · 几何 / 画布（128px 基准，10 条）

| ID | 期望值 | 真实实测值 / 证据 | 判定 | 载体差异备注 |
|---|---|---|---|---|
| I-5-A01 | `base_canvas_px=128`(int) | manifest `spec.canvas="128x128"`；13 张 `assets[].size=[128,128]`；PNG IHDR 13 张 128×128 | **PASS** | 无 `base_canvas_px` 键，语义由 `spec.canvas` 承载 |
| I-5-A02 | `frame_width=128` | 单帧 PNG 宽=128；`assets[].size[0]=128`；spritesheet 1024=128×8、384=128×3 | **PASS** | 无 `frame_width` 键 |
| I-5-A03 | `frame_height=128` | 单帧 PNG 高=128；`assets[].size[1]=128`；两表高均=128 | **PASS** | 无 `frame_height` 键 |
| I-5-A04 | `canvas_base_px=128`（若存在，且与 `base_canvas_px` 不冲突） | manifest 无该别名（用 `spec.canvas` 字符串 "128x128"）；条件「若存在」不触发，128px 语义一致 | **PASS** | 别名未使用，无冲突 |
| I-5-A05 | 单帧精确 128×128；表宽=128×columns、表高=128×rows | 实测 13 张 128×128；player 1024×128=128×8×128×1；boss 384×128=128×3×128×1；**逐 128 切片与单帧像素级 IDENTICAL** | **PASS** | 直接 PNG 实测，无载体差异 |
| I-5-A06 | 不得出现 `frame_width/height=32` | 实测全 128；manifest 无 32；`chars/import.json` 为 128；`r23/` 内无 `import.json` | **PASS** | 无 32 交付尺寸 |
| I-5-A07 | `filter="nearest"` | 契约声明键缺失；15/15 `.png.import` `compress/mode=0`、`mipmaps/generate=false`；接入目标 `ground_material.tres` 与 3 个 `ground_tile_mat_*.tres` 均 `texture_filter=0`(nearest)。**如实登记**：`courtyard.tscn:46` SubViewportContainer `texture_filter=1`(linear) 为既有场景配置、非 R23 素材字段 | **PASS** | 字面声明缺失；像素最近邻由 `texture_filter=0` + 无 mipmaps 保证 |
| I-5-A08 | `mipmaps=false` | 15/15 `.png.import` `mipmaps/generate=false` | **PASS** | 引擎实际导入参数等价（比声明更权威） |
| I-5-A09 | `compression="lossless"` | 15/15 `.png.import` `compress/mode=0`（Godot 0 = Lossless） | **PASS** | 引擎实际导入参数等价 |
| I-5-A10 | `default_texture_filter=0` | 契约声明键缺失；`ground_material.tres` 与 3 个材质 `texture_filter=0`；基线 `chars/import.json:87` 为 0 | **PASS** | 字面声明缺失，如实登记 |

### 1.2 B 组 · 色彩 ≥256 / RGBA 保留 alpha（13 条）

| ID | 期望值 | 真实实测值 / 证据 | 判定 | 载体差异备注 |
|---|---|---|---|---|
| I-5-B01 | `min_colors=256`(int) | 契约键缺失；`spec.color_policy`="不强制量化到 <=256 色"；`color_range_actual=[3664,13605]`；实测单帧最小 3664 ≥256 | **PASS** | 无 `min_colors` 键；下限语义成立 |
| I-5-B02 | `unique_opaque_rgb >= 256`（废止 250） | 实测单帧 3664~13605、spritesheet 34877/16733，**全部 ≥256**；`250` 未出现 | **PASS** | 无该键，实测值直接判定 |
| I-5-B03 | `max_colors` 不得存在；若存在须 ≥256 且不作上限 | manifest 全文审计：`max_colors` **不存在** | **PASS** | 直接判定 |
| I-5-B04 | `indexed != true` | manifest 无 `indexed` 键；`color_policy` 明说不量化；15 张 PNG `ct=6` RGBA 直出 | **PASS** | 键不存在即满足 |
| I-5-B05 | `quality_gate` 不含 `<=256色`/`每帧<=256`，须含 ≥256 下限口径 | manifest 无 `quality_gate` 键；等价由 `spec.color_policy` 与 `workflow.ImageQuantize`="已移除（原 colors=256 硬限制删除），允许 256 色以上"承载；全文审计 `<=256色`/`每帧<=256` **均 False** | **PASS** | 等价字段承载，无废止子串 |
| I-5-B06 | `global_quantize`/`generated_by` 不含 `ImageQuantize(256)`/`MEDIANCUT 256`/`256 色量化` | 全文审计 4 个子串 **全部 False**；`workflow.ImageQuantize` 记「已移除」 | **PASS** | 无废止子串 |
| I-5-B07 | `palette`/`palette_scope` 不得为 `hd2d_index_256_v1`/`shared_sheet_256` | manifest 无 `palette`/`palette_scope` 键；两绑定值全文 **False** | **PASS** | 键不存在即满足 |
| I-5-B08 | `frames[].colors` 每帧 ≥256（废止 100~154） | 契约 `frames[]` 结构缺失；`manifest.assets[].unique_rgb_visible` 13 项 = 3760/4944/4642/3664/6553/4617/4777/3672/5163/6269/5392/11739/13605，**逐项 ≥256 且与 PIL 实测完全一致** | **PASS** | 等价字段 `assets[].unique_rgb_visible` |
| I-5-B09 | `pixel_format="RGBA8"` | 契约键缺失；15/15 PNG IHDR `ct=6`(RGBA) `bd=8`、`mode=RGBA`；`assets[].mode="RGBA"` | **PASS** | 实测即 RGBA8 |
| I-5-B10 | `alpha_preserved=true` | 契约键缺失；12/13 素材含 `a=0` 透明像素（`nAlphaVals=2`, `minA=0`, `maxA=255`）；`assets[].alpha=true`；`ground_tile` 全 255 为不透明地砖（manifest 明确登记） | **PASS** | 实测 alpha 保留 |
| I-5-B11 | PNG IHDR color type = 6（RGBA 4 通道） | 15/15 `ct=6`、`bd=8`、`il=0` | **PASS** | 直接 PNG 实测 |
| I-5-B12 | 存在 `alpha==0`、非全 255、去重 `(r,g,b,a)` 含 alpha 变化 | 12 张 `a0>0` / `minA=0` / `maxA=255` / `nAlphaVals=2`；`ground_tile` `nAlphaVals=1` 全 255（地砖例外，manifest 登记） | **PASS** | 直接 PNG 实测 |
| I-5-B13 | 单帧去重不透明色数 ≥256，且与声明值交叉核对一致 | PIL 实测 13 张单帧 `uniq_opaque_rgb`（见 §0.4）与 `manifest.assets[].unique_rgb_visible` **逐项完全一致**，全部 ≥256 | **PASS** | 声明值 vs 实测值一致 |

### 1.3 C 组 · pose 名 / 帧序 / 坐标系（与既有 tres 完全一致，15 条）

> **帧序硬证据（E6，真跑）**：`player_spritesheet.png` 按 `x=i*128` 切 8 帧，与
> `player_{idle,walk,run,roll,attack_light,attack_heavy,hitstun,death}.png` **逐像素 IDENTICAL**（8/8）；
> `boss_spritesheet.png` 切 3 帧与 `boss_{p1_dagger_slash,p1_staff_slam,p2_holy_hammer}.png` **IDENTICAL**（3/3）。
> 既有 `player_spriteframes.tres` pose→region.x：`idle=0, walk=128, run=256, roll=384,
> attack_light=512, attack_heavy=640, hitstun=768, death=896`；`boss_spriteframes.tres`：`0/128/256`。

| ID | 期望值 | 真实实测值 / 证据 | 判定 | 载体差异备注 |
|---|---|---|---|---|
| I-5-C01 | `pose_names` 恰为 8 名顺序一致 | `manifest.frame_order.player` = `[idle,walk,run,roll,attack_light,attack_heavy,hitstun,death]`，长度 8、顺序一致 | **PASS** | 键名 `frame_order.player` |
| I-5-C02 | `actions[].name` 同上 8 名 | manifest 无 `actions[]`；`frame_order.player` + `player_spriteframes.tres` 8 个 animations 名集合一致 | **PASS** | 结构差异如实登记 |
| I-5-C03 | `actions[].start_frame/end_frame` = `0/0 … 7/7` | manifest 无 `actions[]`；`frame_order.player` 顺序 + 既有 `chars/import.json:10-67`（`start==end==index`，基线未回改）+ 既有 tres 每动画单帧 | **PASS** | 结构差异如实登记 |
| I-5-C04 | `columns/rows` = `8/1` | `manifest.spritesheets.player_spritesheet.png` = `{size:[1024,128], frames:8}`；实测 1024×128 单行 8 帧 | **PASS** | 键名 `spritesheets.*.frames` |
| I-5-C05 | `anchor=[0.5,1.0]`（底部中心、禁逐帧偏移） | manifest 无 `anchor` 键；`frame_order.coordinate_system` 写明单行 128px 网格与既有 tres 逐字一致；既有 `chars/import.json:6-9` `anchor=[0.5,1.0]` 未回改；本轮接入不改 region | **PASS** | 字段缺失如实登记 |
| I-5-C06 | `<r23>/player/*.tres` animations 名 8 个（若重生成） | `r23/` 内**无 `.tres`**（条件「若重生成」不触发）；实际接入改既有 `player_spriteframes.tres` 的 `ext_resource`，8 个 animations 名不变 | **PASS** | 条件项 N-A，接入后既有 tres 8/8 核对 |
| I-5-C07 | 每个 `AtlasTexture.region` = `Rect2(index*128,0,128,128)` | 既有 `player_spriteframes.tres` 8 个 region 全 `Rect2(*,0,128,128)`，pose→x 见上；**接入不改 region** | **PASS** | 逐帧比对一致 |
| I-5-C08 | loop：`idle/run/walk=1`，其余 5 = `0` | 既有 tres：`idle/run/walk` loop=1；`attack_heavy/attack_light/death/hitstun/roll` loop=0 | **PASS** | 直接核对 |
| I-5-C09 | boss `pose_names` 恰为 3 名、含 `p1_`/`p2_` 前缀 | `manifest.frame_order.boss` = `[p1_dagger_slash,p1_staff_slam,p2_holy_hammer]`，长度 3、顺序一致 | **PASS** | 键名 `frame_order.boss` |
| I-5-C10 | boss `<r23>/*.tres` animations 名 3 个 | 既有 `boss_spriteframes.tres` 3 个 animations 名一致；`r23/` 无 tres（条件项） | **PASS** | 条件项 N-A |
| I-5-C11 | boss `AtlasTexture.region` = `Rect2(index*128,0,128,128)` | 既有 boss tres `region.x=0/128/256`，全 `Rect2(*,0,128,128)`；接入不改 | **PASS** | 逐帧比对一致 |
| I-5-C12 | boss `columns/rows` = `3/1` | `manifest.spritesheets.boss_spritesheet.png` = `{size:[384,128], frames:3}`；实测 384×128 单行 3 帧 | **PASS** | 键名 `spritesheets.*.frames` |
| I-5-C13 | boss `anchor` 与 player 同坐标系、不逐帧偏移 | `frame_order.coordinate_system` 统一单行 128px 网格；既有 tres region 全 `y=0` / `128×128`，无逐帧偏移 | **PASS** | 字段缺失如实登记 |
| I-5-C14 | spriteframes 动画数 `==3`，不得扩成 5 | 既有 boss tres 动画数 = **3**；`frame_order.boss` 长度 = 3；数据层 `pose_keys` 5 个为派生（未扩帧） | **PASS** | 直接核对 |
| I-5-C15 | 3 个动画名 == 两脚本 `BOSS_POSE_MOVES` 键集合 | `verify_frame_data.gd:36-40` 与 `combat_data_validator.gd:30-34` 键集合均 = `{p1_dagger_slash,p1_staff_slam,p2_holy_hammer}`，与 boss tres 3 动画名、`frame_order.boss` 完全一致 | **PASS** | 真跑 grep 交叉核对 |

### 1.4 D 组 · import.json 字段清单（12 条）

| ID | 期望值 | 真实实测值 / 证据 | 判定 | 载体差异备注 |
|---|---|---|---|---|
| I-5-D01 | 文件合法 JSON / UTF-8 / 可解析 | 契约 `player/import.json`、`boss/import.json` **不存在**；实际 `r23/manifest.json` 经 `json.load` 解析通过、UTF-8、17 顶层键 | **PASS** | **载体替换**（单一 manifest 替代两份 import.json），如实登记 |
| I-5-D02 | `schema_version` 非空字符串（对齐 "1.0"） | 实际 `schema_version = 1`（**int，非字符串 "1.0"**）；语义（有版本号）成立 | **PASS** | **类型/值差异如实登记**，不冒充 "1.0" |
| I-5-D03 | `asset_id` 非空字符串 | manifest **无 `asset_id` 键**；等价身份由 `task_id`/`round`/`source`/`assets[].file` 承载 | **PASS** | 字段缺失如实登记 |
| I-5-D04 | `sprite_sheet` 非空且所指 png 存在 | manifest 为 `spritesheets` 对象（非字符串），含 `player_spritesheet.png`(217,416 B) / `boss_spritesheet.png`(86,163 B)，两文件真实存在 | **PASS** | 结构差异如实登记 |
| I-5-D05 | `frames[]` 长度=columns，每项含 `index/pose/file/colors` | manifest 为 `assets[]`（14 项，含 `pose/file/size/mode/unique_rgb_visible/alpha/seed`），**非 `frames[]`**、无 `index/colors` 键；帧数由 `frame_order` + `spritesheets.*.frames` 承载 | **PASS** | 结构差异如实登记 |
| I-5-D06 | `frames[].index/pose` 与 C 组一致 | `frame_order.player/boss` 顺序 + `assets[].pose` 与 C01/C09 逐项一致；E6 逐帧像素 IDENTICAL | **PASS** | 等价字段 |
| I-5-D07 | `actions[]` 含 `name/start_frame/end_frame/fps/loop` | manifest **无 `actions[]`**；帧序/loop 由既有 `player_spriteframes.tres` / `boss_spriteframes.tres` 的 animations 承载（本轮不改） | **PASS** | 结构差异如实登记 |
| I-5-D08 | `layer_type` 非空 | manifest 无 `layer_type` 键；`assets[].kind`（player/boss/decor/ground）承载同类语义 | **PASS** | 字段缺失如实登记 |
| I-5-D09 | `source_file`/`generated_by` 非空且不含 `ImageQuantize(256)` | manifest 有 `source`/`provenance`/`workflow`（本机 ComfyUI `127.0.0.1:8188`）；全文 `ImageQuantize(256)` **False**；`workflow.ImageQuantize` 记「已移除」 | **PASS** | 等价字段 |
| I-5-D10 | 22 个必填字段**全部存在** | **字面 key 大量缺失**（见 §2 差异登记）；但每条期望语义均有等价承载（映射表见 §2.2） | **PASS** | **字面差异显著登记，不冒充 22 键齐全** |
| I-5-D11 | 废止字段集合**均不得出现** | E2 全文审计：`max_colors`/`indexed`/`hd2d_index_256_v1`/`shared_sheet_256`/`global_quantize`/`ImageQuantize(256)`/`MEDIANCUT 256`/`256 色量化`/`每帧<=256`/`<=256色`/`quality_gate`/`palette` **全部不存在** | **PASS** | 直接判定，真 PASS |
| I-5-D12 | `frames[].colors` 与 B13 PNG 实测交叉核对 | PIL 实测 13 张单帧唯一不透明 RGB 与 `manifest.assets[].unique_rgb_visible` **逐项完全一致且 ≥256** | **PASS** | 声明 vs 实测一致 |

### 1.5 E 组 · 零付费 / DNF 仅参考不进发布包（6 条）

| ID | 期望值 | 真实实测值 / 证据 | 判定 | 载体差异备注 |
|---|---|---|---|---|
| I-5-E01 | `paid_service=false` | manifest 无该键；`compliance.zero_paid=true`；`source`=本机 ComfyUI；`provenance` 无付费服务 | **PASS** | 等价字段 |
| I-5-E02 | `zero_external_dependency=true` | manifest 无该键；`source`/`provenance` 记「本机 ComfyUI + 本机确定性后处理，零外部依赖」；`workflow` 全本地 | **PASS** | 等价字段 |
| I-5-E03 | `pipeline`/`generated_by` 不得出现付费素材生成服务 / 商业图库 / 订阅 API | E2 审计 `Gemini`/`Grok`/`Tripo`/`订阅`/`付费API`/`商业图库`/`DALL`/`Midjourney`/`stable-audio` **全部为空**；`source`/`workflow` 全为本机 ComfyUI + PIL | **PASS** | 直接判定 |
| I-5-E04 | `r23/` 目录 + 发布包清单不得存在 DNF 贴片 | `find godot/assets/generated/r23 -type f ! -name "*.png" ! -name "*.png.import" ! -name "manifest.json"` = **空**；`find godot/assets -iname "*dnf*"/"*ghosthand*"/"*kobolt*"/"*npk*"` = **空**；DNF 参考仅在 `teamwork/Rank-4/r23_dnf_reference/`（有 `.gdignore` + `.gitignore`），**不在 `res://` 路径下、Godot 不导入** | **PASS** | 直接判定 |
| I-5-E05 | `dnf_reference_only=true` / `dnf_in_release=false` | manifest 无该二键；`compliance.dnf_resources` 记「仅本机风格参考、未拷入 godot/assets/、未进 pck/exe/apk」，`compliance.generated_assets` 记 `published_in_pck:true` | **PASS** | 等价字段 |
| I-5-E06 | 发布包素材全部本地生成/自绘、可追溯、无付费依赖 | `manifest.published_in_pck=true`；14 项 `assets[].published_in_pck=true`；`source` 本机 ComfyUI；`export_presets.cfg` `export_filter="all_resources"` 而 `r23/` 内仅本机原创 PNG；`.gitignore` 排除 `build/` | **PASS** | 清单审计 |

### 1.6 汇总

| 组 | 条目数 | PASS | FAIL |
|---|---:|---:|---:|
| A 几何/画布 | 10 | **10** | 0 |
| B 色彩/RGBA | 13 | **13** | 0 |
| C pose/帧序/坐标系 | 15 | **15** | 0 |
| D 字段清单 | 12 | **12** | 0 |
| E 零付费/DNF | 6 | **6** | 0 |
| **合计（非挂起）** | **56** | **56** | **0** |
| F `128bit` 挂起 | 2 | — | — （**不计 PASS/FAIL**） |

> **判定口径**：按 §0.2（契约 §2③ 授权的「可无歧义执行条目」实质规格语义）逐条真跑 →
> **56 PASS / 0 FAIL**；F 组 2 条挂起。**未出现任何「素材规格不达标」的 FAIL。**
> **但：不冒充 §3 字面四元组（文件=`player|boss/import.json`、字段=提议命名）全 PASS** ——
> 字面载体差异见 §2，逐条已在「载体差异」列披露。

---

## 2. 契约字面载体差异登记（如实，不计 PASS/FAIL）

### 2.1 结构性差异（实测）

| 项 | ASSET-SPEC-R23.md §3 假设 | Rank-4 实际交付 | 实测方式 |
|---|---|---|---|
| 目录 | `<r23>/player/`、`<r23>/boss/` 两个子目录 | `r23/` **平铺**（无子目录） | `find r23 -type d` |
| 元数据文件 | `player/import.json` + `boss/import.json` | **单一** `r23/manifest.json`（10,760 B） | `find r23 -name "import.json"` = 空 |
| 文件总数 | — | 15 PNG + 15 `.png.import` + 1 manifest = **31** | `find` |
| 新字段命名 | §3 D 末「须 Rank-4 / 总指挥在 R23B 前确认后锁定」 | **未锁定**：`min_colors`/`pixel_format`/`alpha_preserved`/`paid_service`/`dnf_in_release`/`bit_depth_128_spec`/`zero_external_dependency`/`asset_id`/`actions`/`sprite_sheet`/`layer_type` **全部不存在**（E2 审计） | 全文 key 审计 |
| `schema_version` | 非空字符串（"1.0"） | `1`（int） | `json.load` |
| 色数口径 | 派单「3664~34877」 | manifest `[3664,13605]` 为**单帧 assets 口径**；34877 为 **player_spritesheet 全表**实测值 | §0.4 E1 |

### 2.2 D10「必填字段集合」语义映射表（22 项，逐项如实）

| 契约必填 key | 期望 | 实际承载（真实证据） | 字面键 |
|---|---|---|---|
| `base_canvas_px` | 128 | `spec.canvas="128x128"` + 13 张 `assets[].size=[128,128]` | 缺 |
| `frame_width` / `frame_height` | 128 / 128 | PNG IHDR 实测 + `assets[].size` | 缺 |
| `columns` / `rows` | 8/1、3/1 | `spritesheets.*.frames` + spritesheet IHDR 实测 | 缺（别名） |
| `anchor` | `[0.5,1.0]` | `frame_order.coordinate_system` + 既有 `chars/import.json` 未回改 | 缺 |
| `actions` | 8/3 帧结构 | 既有 `player_spriteframes.tres`/`boss_spriteframes.tres` animations | 缺 |
| `pose_names` | 8/3 名 | `frame_order.player` / `frame_order.boss` | 别名 |
| `frames` | 长度=columns | `assets[]`(14) + `spritesheets.*.frames` | 别名/结构差异 |
| `sprite_sheet` | 所指 png 存在 | `spritesheets` 对象 + 两 PNG 真实存在 | 别名 |
| `filter` | nearest | `.png.import compress/mode=0` + 材质 `texture_filter=0` | 缺 |
| `mipmaps` | false | 15/15 `.png.import mipmaps/generate=false` | 别名 |
| `compression` | lossless | 15/15 `.png.import compress/mode=0` | 别名 |
| `default_texture_filter` | 0 | `ground_material.tres`/3 材质 `texture_filter=0` | 缺 |
| `min_colors` | 256 | `spec.color_policy` + `color_range_actual` + 实测 ≥3664 | 缺 |
| `unique_opaque_rgb` | ≥256 | PNG 实测 3664~34877 | 缺 |
| `pixel_format` | RGBA8 | 15/15 `ct=6 bd=8` | 缺 |
| `alpha_preserved` | true | 实测 12 张含 `a=0` | 缺 |
| `zero_external_dependency` | true | `source`/`provenance` 本机 | 缺 |
| `paid_service` | false | `compliance.zero_paid=true` | 缺 |
| `dnf_in_release` | false | `compliance.dnf_resources` + E04 实测隔离 | 缺 |
| `bit_depth_128_spec` | `"PENDING_USER_CONFIRMATION"` | `spec.128bit_ambiguity` 描述性文字 + `DONE-R23.md §7` 显式保留 | **缺（F01 挂起项）** |

### 2.3 契约内部矛盾（如实登记）

- **F01 挂起 vs D10 必填**：`bit_depth_128_spec` 在 §2 / F01 被裁定「歧义挂起、不编码进任何字段期望值、
  不计 PASS/FAIL」，却又被 §3 D10 列入「必填字段集合」。契约自身未自洽，本轮按 §2 优先 → **F01 挂起**，
  D10 按语义等价判定并在映射表标注该键缺失，**不擅自补写字段值**。
- **§3 D 末命名待确认 vs §3 表已列期望值**：字段名未锁定却已写死期望值，字面逐 key 判定前提不成立。

> 以上差异与矛盾 **均如实登记、不隐藏、不伪造字段值**，并作为**待裁决项**上报（见最终「未完成项与阻塞」）。
> 若复核认定必须按 §3 字面四元组判 FAIL，本报告不隐瞒，可据此回退接入。

---

## 3. F 组 · `128bit` 挂起项（不计 PASS/FAIL，保留待用户确认）

| ID | 期望值 | 真实情况 | 处理 |
|---|---|---|---|
| I-5-F01 | `bit_depth_128_spec="PENDING_USER_CONFIRMATION"` | manifest **无该键**（有 `spec.128bit_ambiguity` 描述「仍待用户确认」+ Rank-4 `DONE-R23.md §7` 显式保留）；契约 §3 D 末自述该字段名「须确认后锁定」、实际未锁定 | **挂起**，保留待用户确认；不擅自解释、不伪造字段值 |
| I-5-F02 | §3 全部条目不得含 `128bit` 派生阈值 | 审阅 56 条期望值列：无任何由 `128bit` 派生的阈值（A 组 128px 画布源自既有 `base_canvas_px=128` 证据，非 128bit 派生） | **挂起项随 F01 一并保留**；本轮实际未因 128bit 设任何阈值 |

> 派单明确「`128bit` 歧义挂起项不计 PASS/FAIL、保留待用户确认」，本轮遵守。

---

## 4. 接入裁决（执行 AI 显式声明，可复核、可推翻）

1. 素材**实质规格**（§2③ 列举的 128px 画布、色数 ≥256、RGBA alpha、pose 对齐、零付费/DNF 隔离）
   经逐条真跑 **全部 PASS**；56 条中 **0 条**「素材规格不达标」。
2. 未达「§3 字面四元组全 PASS」的部分**仅**集中在「元数据载体 / 字段命名」维度，而该维度契约自身
   §3 D 末 / §7.3 承认「须确认后锁定」、本轮未锁定（§2 已全部如实登记）。
3. 总指挥 R23B 派单明确追认 Rank-4 产出（「四路 R23 已完成、工程与素材冻结」），并要求
   「**把新素材真正接进可见画面并交付产物**」。
4. **据此放行接入**；同时把「§3 字面载体差异」「§3 D 命名未锁定」「`128bit` 歧义」作为
   **未完成 / 待裁决项**上报，提请 Rank-2 / 总指挥复核。若复核认定应按 §3 字面判 FAIL，
   本报告不隐瞒相应事实、可据此回退接入。

---

## 5. 实际交付清单

### 5.1 接入改动文件（真改，6 个 `.tres`；旧 PNG 全部保留不覆盖）

| # | 文件 | 改动 | 派单依据 |
|---|---|---|---|
| 1 | `godot/assets/generated/chars/player_spriteframes.tres` | `ext_resource path` → `res://assets/generated/r23/player_spritesheet.png`（1024×128） | 点名 |
| 2 | `godot/assets/generated/boss/boss_spriteframes.tres` | `ext_resource path` → `res://assets/generated/r23/boss_spritesheet.png`（384×128） | 点名 |
| 3 | `godot/assets/generated/terrain/ground_material.tres` | `albedo_texture` 的 `ext_resource path` → `res://assets/generated/r23/ground_tile.png` | 点名 |
| 4 | `godot/assets/generated/terrain/ground_tile_mat_plate.tres` | `ext_resource path` → `res://assets/generated/r23/ground_tile.png` | **「必要时同步 courtyard.tscn 实例引用」裁量** |
| 5 | `godot/assets/generated/terrain/ground_tile_mat_low.tres` | 同上 | 同上 |
| 6 | `godot/assets/generated/terrain/ground_tile_mat_high.tres` | 同上 | 同上 |

> **为何追加 #4~#6（如实）**：`courtyard.tscn:77,82,87` 的 `GroundPlate`/`TerraceLow`/`TerraceHigh`
> 实际引用的是 `ground_tile_mat_{plate,low,high}.tres`（三者各自 `uv1_scale` 16/3/2），
> **不是** `ground_material.tres`。只改 #3 画面不会变化。为达成派单总目标「把新素材真正接进可见画面」，
> 按「必要时同步 courtyard.tscn 的实例引用」裁量同步了 3 个材质的贴图指向；
> **`courtyard.tscn` 本身未改**（引用的是 `.tres` 文件、路径不变），节点数仍 **27**。
> 三个材质的 `uv1_scale` / `texture_filter` 均未改。

**不变项核对（真跑）**：
- `player_spriteframes.tres` 8 个 `region = Rect2(*,0,128,128)`（idle 0 … death 896）、
  `boss_spriteframes.tres` 3 个（0/128/256）、loop / animations 名 / `uv1_scale` / `texture_filter` **全部未改**；
  pose 名 / 帧序 / `region.x` 与既有 tres 一致。
- 旧 PNG 保留：`chars/player_spritesheet.png` 59,147 B、`boss/boss_spritesheet.png` 31,250 B、
  `terrain/ground_tile.png` 1,495 B（均未覆盖）；新 PNG 217,416 / 86,163 / 38,339 B。
- **未写**：`project.godot`、任何 `.gd` 脚本、任何 `.tscn`、`verify_frame_data.gd`、
  `godot/assets/generated/r23/`（Rank-4 所有权，本轮只读）。

### 5.2 文档 / 回执 / 日志 / 产物

| 类别 | 文件 |
|---|---|
| 交付文档 | `teamwork/Rank-1/DONE-R23B.md`（本文件） |
| 目视回看 | `capture/R23-FINAL-REVIEW.md`（新建） |
| 报告追加 | `capture/CAPTURE-REPORT.md`「R23 新素材接入验收」段落（独占追加） |
| 回执 | `teamwork/command_center/ai/1/outbox/cmd-20261109-141302-870-A1.json` |
| 真跑日志 | `teamwork/Rank-1/r23b_*.log`（门禁 3 + 回归 5 + 录屏 1 + 导出 2 + 验签 2 + badging 1 = 14 份）、`capture/r23b_ffmpeg.log` |
| 录屏 | `capture/r23_final00000000.png` ~ `r23_final00000449.png`（**450 张**）、`capture/r23_final.wav`、`capture/r23_final.mp4` |
| 重导产物 | `build/Aierdengfahuan.exe` / `.pck` / `.apk` / `.apk.idsig`（**按 `.gitignore` 排除、不入库**） |

---

## 6. 门禁与 PASS 数字（全部真跑，不回退）

### 6.1 三段门禁

| 段 | 命令 | EXIT |
|---|---|---|
| G1 | `--headless --path <root> --import` | **0** |
| G2 | `--headless --path <root> --check-only --script res://scripts/verify_frame_data.gd` | **0** |
| G3 | `--headless --path <root> --quit` | **0** |

**`grep SCRIPT ERROR|Parse Error`**：8 份 `r23b_*.log`（3 门禁 + 5 回归）**逐份 = 0**，
`SCRIPT_ERROR_TOTAL=0`。日志 `teamwork/Rank-1/r23b_gate_*.log`。

### 6.2 五个 verify 回归（不回退）

| 脚本 | 真跑结果 | 结论 |
|---|---|---|
| `verify_frame_data.gd` | `PASS_COUNT=650 FAIL_COUNT=0` / `RESULT=ALL_MATCH` / `VALIDATOR_CHECKS=533 VALIDATOR_PASS=533 VALIDATOR_FAIL=0 VALIDATOR_ERROR=0` | **650 PASS / 0 FAIL** |
| `verify_fx_profile.gd` | `SUMMARY pass=34 fail=0 total=34` / `RESULT=PASS` | **34 PASS** |
| `verify_fx_mobile.gd` | `SUMMARY pass=47 fail=0 total=47` / `RESULT=PASS` | **47 PASS** |
| `verify_quality_interaction.gd` | `SUMMARY pass=19 fail=0 total=19` / `RESULT=PASS` | **19 PASS** |
| `r19_verify_hud.gd`（`--script` 绝对路径 `teamwork/Rank-3/`） | `[R19] SUMMARY pass=20 fail=0 ok=true` | **20 PASS** |

**关键基线不回退**（`r23b_verify_frame_data.log`）：翻滚 `action_04_roll` `startup=4 active=9 recovery=9
inv=[4,13) logic_fps=60 total=22`；玩家 8 动作 `logic_fps=[60×8]`；Boss `p1_dagger_slash=47 /
p1_staff_slam=71 / p2_holy_hammer=91`（hit `[18,23)/[30,37)/[42,51)`）；E-8 `400.0/480.0/420.0`。

### 6.3 节点数（CACHE_MODE_IGNORE 真跑回读，如实登记）

`r23b_verify_quality_interaction.log`：
`[R22] LOAD path=res://scenes/courtyard.tscn class=PackedScene SceneState_node_count=27 CACHE_MODE_IGNORE=true`
与 `[R21_QUALITY] courtyard.tscn CACHE_MODE_IGNORE 真跑回读 SceneState node_count=27` 两处独立回读一致。
**= 27**（R23 登记 27，本轮未改场景、不冒充 R20 的 25）；文本 `grep -c "^\[node "` 亦 = 27。

### 6.4 既有非致命 WARNING（如实登记，非 SCRIPT ERROR、不改退出码）

`2 ObjectDB instances were leaked at exit`、`[ChunkManager] 未找到 ChunkRoot`、
`[HUD] 降级登记：未取到 /root/SaveDeltaWriter…`。三者均为 R13~R23 既有行为，本轮未引入、未掩盖。

---

## 7. 15 秒实机录屏与目视回看结论

### 7.1 真跑产物

| 项 | 值 |
|---|---|
| 命令 | `--path <root> --write-movie F:/Game/aierdengfahuan/capture/r23_final.png --fixed-fps 30 --quit-after 450 --script res://test/presentation.gd res://scenes/courtyard.tscn`（复用 R22 已验证形态，单个 GPU 任务、非 headless） |
| `CAPTURE_EXIT` | **0** |
| 帧数 | **450 张** `r23_final00000000.png` ~ `r23_final00000449.png`，全部 1280×720 |
| 时间线 | `SEG-A frame=0` / `SEG-B frame=150` / `SEG-C frame=300` / `时间线完成 frame=450`（非单帧循环） |
| MP4 | `capture/r23_final.mp4` **1,288,103 B**；`ffmpeg -framerate 30 -i r23_final%08d.png -c:v libx264 -pix_fmt yuv420p -movflags +faststart`，`FFMPEG_EXIT=0` |
| ffprobe | `h264 / yuv420p / 1280×720 / 30 fps / nb_frames=450 / duration=15.000000` |
| **WAV** | `capture/r23_final.wav` **5,760,044 B** 真实产出；**未混入 MP4**（ffprobe 音频流计数 = 0，MP4 仅视频轨），与 R22 `r22_demo.mp4` 口径一致，**如实登记、不谎报合并** |

### 7.2 ViewImage 真看首 / 中 / 尾三帧

| 帧 | 结论 |
|---|---|
| 首 `r23_final00000000.png`（medium/desktop） | 密集不规则暖金/青灰石砖地面（非纯色平面）、红发+钴蓝板甲+金饰像素骑士、深蓝夜空+星点+远山剪影+雾带、暖金光柱/光尘/脚下光池、金线深蓝 HUD 不遮挡 |
| 中 `r23_final00000225.png`（low/mobile） | 石砖纹理依旧清晰、角色换 pose（红白头饰+钴蓝甲+金护肩）完整可见、四项光效全关（无光柱/光尘/倒影）、HUD 标题随 flag 变「赐福 · 巡礼教堂」、三档面板尺寸一致 |
| 尾 `r23_final00000449.png`（high/desktop） | 石砖最锐利、角色为红发+格纹头巾+胸前发光青蓝宝石 pose，无破图/重复小人、光柱/光尘/光池回归、标题「赐福 · 希芙拉河井底」暗色未点亮 |

### 7.3 「新素材是否真的进入画面」判定

对照 `capture/r23_night_00000005.png`（R23 接入前旧帧）：
- **地面**：旧 = 规则长条砖网格、黄绿/棕褐平涂、重复感强；新 = 密集不规则石砖、暖金/青灰/橙点、磨损颗粒细节。
- **角色**：旧 = 蓝白头盔+红围巾小骑士、色块简单；新 = 红发/格纹头巾+钴蓝板甲+金护肩+发光青蓝宝石、层次与硬描边明显。

→ **是，新素材确实进入可见画面**。由「6 个 tres 静态指向 r23/」+「450 帧真实渲染」+「ViewImage 目视 + 旧帧对照」
三者共同支撑；不是 clean build 推断、不是改名冒充。另 pck/apk 内 **15/15** 张 r23 PNG 路径实证存在（§8.3）。

**Boss 如实登记**：`courtyard.tscn` 27 节点中**无 Boss 实例**；`boss_spriteframes.tres` 已指向 r23/、
`boss_01_margit.tscn` 引用它，但本 15 秒 courtyard 录屏画面**不含 Boss**，不冒充可见。
`r23/decor_layer.png` 未接入（派单未要求）。

### 7.4 夜景 / 景深 / HD-2D 目标差距

- 夜景：深蓝夜空 + 冷蓝雾带 + 远山剪影 + 暖金主光/光柱，暖冷强对比成立，三档不回退。
- 景深：仍是 **2D 程序化分层近似**（`hd2d_parallax.gd` 山影/雾带/渐变），非 3D 深度雾 / DOF 模糊；山影几何化。
- 四项光效：desktop 段可见、mobile 段全关，均为 2D `draw_*` 近似（`gl_compatibility` 不支持 HDR bloom / 体积光 / SSR）。
- **与 HD-2D 目标的差距 → 未达全绿（如实写未达）**：新石砖贴图与角色细节明显改善，但
  ① `uv1_scale` 高倍平铺重复感仍明显；② 暖金地面大面积偏亮、冷夜雾向地面渗透不足、白天感残留；
  ③ 无 3D 深度雾 / DOF；④ 光效仍为 2D 近似；⑤ 8 pose 各仅 1 帧、无逐帧动作动画；
  ⑥ 角色为 3D `AnimatedSprite3D` 像素贴图。本轮只做接入 + 录屏 + 目视回看，**未精修美术、不冒充全绿**。

> 详见 `capture/R23-FINAL-REVIEW.md`（含首/中/尾逐帧目视、旧帧对照、6 项如实登记 / 未完成项）。

---

## 8. 新旧产物字节数与验签

### 8.1 双导出（真跑）

| 产物 | 命令 | EXIT |
|---|---|---|
| Windows Release | `--headless --path <root> --export-release "Windows Desktop"` | **0**（`[ DONE ] savepack`） |
| Android Debug | `JAVA_HOME=D:/AndroidToolchain/jdk17` + PATH 注入 → `--headless --path <root> --export-debug "Android"` | **0**（`Signed`） |

环境：`D:/AndroidToolchain/sdk`（build-tools 36.1.0 / platforms 34,36）、`D:/AndroidToolchain/jdk17`
（OpenJDK 17）、`debug.keystore`（editor settings `export/android/debug_keystore` 指向
`C:/Users/62668/AppData/Roaming/Godot/keystores/debug.keystore`，另 `D:/AndroidToolchain/debug.keystore` 在）、
导出模板 `C:/Users/62668/AppData/Roaming/Godot/export_templates/4.7.2.stable`。
非致命项：Android 导出 stdout 一条 `ERROR: No project icon specified`（`export_plugin.cpp:1941`），
与 R21B 同，Godot 用模板默认图标继续、签名与 EXIT=0 不受影响，如实登记。

### 8.2 新旧字节数对比（如实）

| 产物 | R21B 旧（B） | R23B 新（B） | 差异 | 说明 |
|---|---:|---:|---:|---|
| `Aierdengfahuan.exe` | 109,127,680 | **109,127,680** | **+0** | `binary_format/embed_pck=false`，exe 为固定 Windows 引擎模板；PE `MZ` 头已核对 |
| `Aierdengfahuan.pck` | 993,736 | **1,579,332** | **+585,596** | **15 张 r23 PNG 进入发布包**（§8.3 实证） |
| `Aierdengfahuan.apk` | 29,239,499 | **29,829,394** | **+589,895** | 同上，工程内容变化 |
| `Aierdengfahuan.apk.idsig` | 234,930 | **239,026** | **+4,096** | v4 签名随新 apk 重算 |

新产物时间戳（本机 +0800）：exe 14:35:20 / pck 14:35:51 / apk + idsig 14:36:18（旧版均 12:30/12:31）。
与 R21B 基准数字（派单给出）**完全一致**，对比口径为字节数、非 clean build。

### 8.3 r23 素材进包实证（真跑，非推断）

`grep -aoE "res://assets/generated/r23/[a-z0-9_]+\.png" build/Aierdengfahuan.pck | sort -u` → **15 条**，
与 `r23/` 的 15 张 PNG 一一对应；`Aierdengfahuan.apk` 内同样 15 条。
（注：初次用 `[a-z_]*` 正则漏掉含数字的 `boss_p1_*` 帧名，**已用宽正则重核修正**，未据初值误登记。）

### 8.4 验签（真跑）

`apksigner.bat verify --verbose --print-certs`（build-tools 36.1.0，JAVA_HOME=jdk17）：
```
Verifies
Verified using v1 scheme (JAR signing): false
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Verified using v3.1 scheme (APK Signature Scheme v3.1): false
Verified using v4 scheme (APK Signature Scheme v4): false      ← 默认未传 .idsig
Number of signers: 1
```
追加 `--v4-signature-file Aierdengfahuan.apk.idsig`：
```
Verifies
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Verified using v4 scheme (APK Signature Scheme v4): true
Number of signers: 1
```
`aapt.exe dump badging` 首行：
```
package: name='com.aierdengfahuan.game' versionCode='1' versionName='1.0.0' ... compileSdkVersion='36'
sdkVersion:'24'
```
**核对**：`Verifies` ✓、`v2=true` ✓、`v3=true` ✓、`v4=true` ✓、`signers=1` ✓、
包名 `com.aierdengfahuan.game` ✓、`versionName 1.0.0` ✓ —— 全部达标。

### 8.5 产物不入库（真跑核对）

`git check-ignore -v` 对 4 个产物全部命中 `.gitignore:8:build/`；
另 `.gitignore` 含 `*.exe` / `*.pck` / `*.apk` / `*.log`。**未执行任何 `git add` / `git commit` / `git push`**。

---

## 9. 未完成项与阻塞

**阻塞：无**（校验 / 接入 / 门禁 / 回归 / 录屏 / 目视 / 双导出 / 验签 / 文档 / 回执全部真跑闭环）。

**如实登记的未完成 / 待裁决项**（均不冒充完成、不谎报全绿）：

1. **§3 字面载体差异（首要待裁决项）**：Rank-4 实际交付为平铺 `r23/` + 单一 `manifest.json`，
   与 `ASSET-SPEC-R23.md` §3 假设的 `<r23>/player|boss/import.json` 及 §3 D 末"须确认后锁定"的
   提议字段名不一致（§2 全表如实登记）。本轮按 §2③ 授权的**实质规格语义**口径判定 56 PASS/0 FAIL 并放行接入，
   **显式声明此裁决、可复核可推翻**；提请 Rank-2 / 总指挥锁定 §3 D 字段命名或书面授权语义等价口径。
2. **`128bit` 歧义挂起**（F01/F02）：用户原话「128bit 256色以上」的 `128bit` 含义未确认，
   `bit_depth_128_spec` 字段缺失且命名未锁定；**不计 PASS/FAIL、保留待用户确认**，不擅自解释、不伪造字段值。
3. **契约内部矛盾**：`bit_depth_128_spec` 在 §2/F01 被裁定挂起、却又被 §3 D10 列入必填集合（§2.3）。
4. **HD-2D 全绿未达**（§7.4 / `R23-FINAL-REVIEW.md §5`）：地面重复感与白天感残留、2D 近似景深/光效、
   单帧 pose、3D `AnimatedSprite3D` 贴图；本轮未精修美术。
5. **Boss 新素材未进入本录屏画面**：`courtyard.tscn` 无 Boss 实例（27 节点不含 Boss）；
   `boss_spriteframes.tres` 已指向 r23/ 且 `boss_01_margit.tscn` 引用，但 15 秒 courtyard 录屏不含 Boss。
6. **`decor_layer.png` 未接入**（派单未要求）。
7. **WAV 未混入 MP4**：`r23_final.wav` 单独保留，MP4 仅视频轨（与 R22 口径一致）。
8. **画面左侧深蓝色尖锐几何形状**：首/中/尾三帧固定出现，属既有场景/FX 元素（非本轮引入），
   来源未逐一追查，如实登记不臆断。
9. **非致命项**：Android 导出 `No project icon specified`；回归日志既有 `2 ObjectDB instances were leaked` /
   `ChunkManager 未找到 ChunkRoot` / HUD 降级登记（均非 `SCRIPT ERROR`、不改退出码）。
10. **按约束未做**：人工鼠标点击 / 真机试玩逐帧动态验收 / GPU 时间戳 / 逐 `_draw()` 拆分；
    Movie Maker 固定步长录屏不等价于实时性能评测；不新建只读探针 / 巡检脚本、不主动扫目录做进度巡检。
11. **零付费 / 合规**：未引入付费素材生成服务、一次只跑一个 GPU 任务、DNF 贴片仅本机参考未进
    `godot/assets/` 与 pck/exe/apk（E04 实测隔离）、未自行 git 提交；产物按 `.gitignore` 排除不入库。

---

## 10. 回执

- 精确路径：`F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261109-141302-870-A1.json`
  （在 `teamwork/command_center/` 下，**非**工程根 `command_center/`；工程根复核确认无该目录）。
- 内容：`{"task_id":"cmd-20261109-141302-870-A1","ai":1,"status":"done","result":"引用 DONE-R23B.md 实际结论：…"}`。
- 投递事实见 §10.1（写入后核对，如实登记）。

### 10.1 回执写入与路径核对

**结论：回执路径正确。**

| 核对项 | 真跑事实 |
|---|---|
| 精确路径写入 | `Write` 返回成功，路径 `F:/Game/aierdengfahuan/teamwork/command_center/ai/1/outbox/cmd-20261109-141302-870-A1.json`（在 `teamwork/command_center/` 下，工程根 `command_center/` 不存在、未误写） |
| JSON 合法性 | `json.load` 解析通过，字段 `task_id=cmd-20261109-141302-870-A1` / `ai=1` / `status=done` / `result` 引用 DONE-R23B.md 实际结论（长度 1,199 字符） |
| 首次投递 | 写入后 **outbox 被调度中枢即时消费清空**，归档到 `teamwork/command_center/dispatcher/receipts/cmd-20261109-141302-870-A1.json`（**1726 B**）；`ai/1/status.json` 更新 `state=idle` / `completed=33` / `last_seen=2026-11-09 14:38:59` |
| 归档副本核对 | `Read` 归档件全文，`task_id`/`ai`/`status`/`result` 与写入件**逐字一致** |
| 幂等重写（同工位 R23 口径） | 再写一次到精确路径 → 再次被即时消费；归档副本**仍唯一 1726 B、未产生重复副本**；`status.json` 更新 `completed=34` / `last_seen=14:39:53` |
| outbox 现状 | 空。**这是本项目 dispatcher 既定分发行为**（R20/R21B/R22/R23 各 AI 回执均归档在 `dispatcher/receipts/`、outbox 不留文件），**并非回执缺失或路径写错** |

> 按派单「outbox 空但 receipts 归档存在即视为已送达」，不再重复投递、未改写归档件
> （`dispatcher/receipts/` 不在本轮可写范围）。`Glob **/cmd-20261109-141302-870-A1.json` 可定位权威副本。

---

## 结论

R23B 闭环：按 `ASSET-SPEC-R23.md` A~E 组 **56 条逐条真跑 → 56 PASS / 0 FAIL**（按 §2③ 授权的实质规格语义口径，
F 组 2 条 `128bit` 挂起不计），**契约字面载体差异与裁决全部如实登记、不冒充字面全 PASS**；
**6 个 `.tres`** 把 `r23/player_spritesheet.png`(1024×128) / `r23/boss_spritesheet.png`(384×128) /
`r23/ground_tile.png` 接入（旧 PNG 保留、pose/帧序/`region.x` 不变、`courtyard.tscn` 未改、节点 27）；
三段门禁 `EXIT 0/0/0`、8 份日志 `SCRIPT ERROR=0`、`650 / 34 / 47 / 19 / 20 PASS` 全部不回退；
**450 帧 = 15.000000 s** 录屏 + `r23_final.mp4`（libx264/yuv420p/faststart，WAV 未混入）+ ViewImage 首/中/尾
真看，**新素材确实进入可见画面**（与 R23 旧帧有可辨差异），**HD-2D 全绿未达，如实写未达**；
双产物 `--export-release "Windows Desktop"` / `--export-debug "Android"` 各 `EXIT=0`、验签
`Verifies / v2+v3+v4 true / com.aierdengfahuan.game`、新旧字节数如实对比（exe 109,127,680 /
pck **1,579,332** / apk **29,829,394** / idsig **239,026** B），产物按 `.gitignore` 排除不入库。

**`status=done` 指本轮交付闭环，不代表 HD-2D 全绿达成，也不代表 §3 字面四元组全 PASS。**
未完成 / 待裁决项见 §9。

