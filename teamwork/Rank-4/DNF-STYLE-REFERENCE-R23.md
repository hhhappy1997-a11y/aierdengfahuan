# DNF-STYLE-REFERENCE-R23.md — DNF 贴片风格 / 构图参考（ROUND=R23）

- 派单：`cmd-20261109-133602-467-A4`
- 执行：Rank-4（美术管线与工具链）
- 用途：**仅定风格与构图**，供本机 ComfyUI 重绘可发布素材时作为提示词与验收参照。
- 硬约束：DNF 客户端资源版权归 **Neople / 腾讯**，仅本机开发参考。参考目录已写 `.gdignore`、
  `manifest.json` 记 `published_in_pck: false`、`raw/` 由 `.gitignore` 隔离；
  **绝不拷入 `godot/assets/`、绝不进 pck / exe / apk / 发布包**。
  联系表为 **4× 像素化风格证据**，不随仓库分发可识别商业贴片。

---

## 1. 提取事实（真跑，非推测）

| 项 | 值 |
|---|---|
| 资源根 | `D:/WeGameApps/地下城与勇士：创新世纪/ImagePacks2`（本机实测 **16691 个 NPK**） |
| 提取器 | `C:/Users/62668/WorkBuddy/2026-10-31-15-43-21/dfo-extractor.exe`（Bun 打包，v 命令集见 `--help`） |
| 命令 | `preview <NPK> --entry <img> --frame <n>`（单帧定向提取）；`inspect <NPK> --json` 核对条目 |
| 参考目录 | `teamwork/Rank-4/r23_dnf_reference/` |
| 生成脚本 | `r23_dnf_reference/build_reference.py`（可复现） |
| 联系表 | `r23_dnf_reference/contact_sheet.png`（21 格，4× 像素化 + 配色条 + 色数/覆盖率标注） |
| 清单 / 统计 | `r23_dnf_reference/manifest.json` / `style_stats.json` |

**实际提取 21 张有效贴片（13 条 SOURCES / 21 帧，ok=21、failed=0）**，四类齐全：

| 类别 | 张数 | 代表条目（NPK → img） |
|---|---|---|
| 人物 character | 3 | `sprite_character_swordman_equipment_growtype_basics.NPK` → `ghosthand.img` f0/f1/f2 |
| 怪物 monster | 3 | `sprite_monster_abnova_kobolt.NPK` → `rollingkobolt.img` f0/f1/f2 |
| 地砖 tile | 5 | `sprite_map_breakableobject.NPK` → `mobgen_floor` / `stonetomb` f0,f1 / `jip` / `rollingstonepiece` |
| 特效 effect | 7 | `sprite_map_act2_fountain.NPK` → `fountainwaterglow` f0,f1、`fountainparticles` f0,f1；`sprite_map_breakableobject.NPK` → `chn_event_doll_ob_light`、`timespiral_particle` f0,f1 |
| 道具 prop | 3 | `treasurebox` / `barrel` / `fountain2` |

每帧归一化为 128×128 RGBA（保持原像素硬边，NEAREST），统计口径为**非透明像素唯一 RGB**。

### 1.1 已知限制（如实登记，不掩饰）

1. **超宽横条型 img 本机提取器不支持**：`sprite_commonmap_town_*_tile.NPK` 的 `tile.img` / `tile_ex.img`
   （canvas 67328×224 / 27008×224）、`sprite_common_commoneffect2_ground.NPK`、`sprite_character_*_effect_*`
   （如 `atblastsword` / `atcounterattack`，canvas 11376×148 等）均报 `无效帧尺寸: #0`，
   或解出 `18×1` / `4274×11360` 异常碎片；`npk --include` 整包解压同样得到近全透明碎片与超大图。
   与 `F:/Download/aierdengfahuan2/docs/DNF素材接入说明.md §5.1`「国服新版 NPK / LINK 变体超出本机
   dfo-extractor 版本支持」结论一致，属可复现已知限制。
   **应对**：地砖 / 特效两类改用 `sprite_map_*` 包内**正常尺寸**的地面、石砌、光晕、粒子贴片，
   同样能反映 DNF 的配色、轮廓、光感规律，且均为真实 DNF 贴片。
2. **人物为单层时装部件**：`ghosthand.img` 是 179 帧的单层部件（500×500 canvas），
   非透明覆盖率仅 **0.7%**；bbox 裁紧放大后仍是细长部件，联系表上呈稀疏竖条。
   `DNF素材接入说明.md §3.C` 明确「NPK 里没有一张现成的完整角色图，完整角色需
   skin/pants/shoes/coat/hair 五层按 SpriteX/SpriteY 合成」；当前 basics 包仅
   `ghosthand` / `pinkghosthand` 两个部件 img，**不具备五层合成条件**。
   本轮不伪造、不拼贴假人物，如实保留稀疏状态；完整人形轮廓由「怪物」类（滚石哥布林 3 帧）
   与 ComfyUI 重绘结果共同承担。
3. 横条特效贴片不可用 → 特效光感规律改由正常尺寸的 `fountainwaterglow` / `*_particle` / `ob_light` 归纳。

---

## 2. 风格规律（基于 21 帧实测统计，非主观臆断）

统计口径：`unique_rgb_visible`（非透明像素唯一 RGB）、`luma_mean` / `luma_p90`（0.299R+0.587G+0.114B）、
`sat_mean`（max−min）、`edge_strong_ratio`（相邻可见像素 RGB 平均绝对差 > 30 的比例，近似轮廓强度）、
`alpha_coverage`。

| 类别 | n | 平均色数 | luma_mean | luma_p90 | sat_mean | edge_strong | coverage |
|---|---|---|---|---|---|---|---|
| character | 3 | 10.0 | 80.0 | 171.1 | 23.1 | **0.582** | 0.007 |
| monster | 3 | 41.7 | 63.5 | 154.2 | 45.8 | 0.272 | 0.409 |
| tile | 5 | 16.8 | 96.1 | 195.3 | 29.4 | 0.189 | 0.380 |
| effect | 7 | 26.0 | **139.7** | **213.5** | 37.9 | 0.413 | 0.067 |
| prop | 3 | 22.3 | 107.1 | 180.1 | **72.0** | 0.339 | 0.316 |

全局：色数 **4 – 107**；luma_mean **62.0 – 193.8**；sat_mean **0.0 – 122.3**。

### 2.1 构图（Composition）

- **足底锚点 + 居中**：`inspect --json` 显示每个 img 都有 `anchor`（如 `rollingkobolt.img` anchor
  `[200,400]`、`ghosthand.img` anchor `[250,500]`），即 DNF 以**足底中心**为对齐基准，角色居中、
  脚踩同一条地面线；本轮 ComfyUI 重绘沿用「centered, feet on ground line」。
- **3/4 前视 + 全身**：怪物帧为完整全身、略带前三分之四视角，动态姿势夸张（前扑、横滚），
  剪影优先可读，不做写实透视。
- **帧序列横排**：`canvas` 是所有帧横向拼起来的总画布，`delay=83ms`；
  对应到本项目即 `player_spriteframes.tres` 的 1024×128 单行 8 帧 `Rect2(x,0,128,128)`、
  `boss_spriteframes.tres` 的 384×128 单行 3 帧 —— **帧序/坐标系可直接对齐**。
- **道具与地砖为顶视/正交**：地砖、宝箱、木桶、喷泉采用平面顶视或小角度正交，
  无强透视、无景深，便于平铺与场景叠层。

### 2.2 配色（Palette）

DNF 贴片是**低色数索引色**（实测单帧 4–107 色，多数 10–45 色），靠**硬色阶**而非渐变塑形。
实测主色可归为四组（RGB 取自 `top_colors` 频次聚合）：

| 组 | 代表 RGB | 用途 |
|---|---|---|
| **暖金 / 土橙**（主色） | `(197,107,41)` `(222,148,49)` `(148,99,49)` `(197,148,74)` `(181,156,99)` | 金属镶边、皮革、木桶、宝箱、砖缝暖光；道具类 sat 高达 72 |
| **冷蓝 / 紫灰**（暗部与冷色） | `(31,31,39)` `(47,47,71)` `(95,95,119)` `(127,127,175)` `(41,41,58)` | 冷色阴影、盔甲暗面、人物部件（sat 仅 23，低饱和冷灰蓝） |
| **近黑描边** | `(16,16,16)` `(16,8,25)` `(33,25,33)` | 1px 硬轮廓、砖缝、分隔线 |
| **高光 / 特效点缀** | `(226,226,226)` `(189,255,239)` `(123,197,206)` `(252,240,247)` | 水光、粒子、冷白高光；特效类 luma_p90 高达 213.5 |

**规律**：暖金（左上主光）与冷蓝紫（阴影）成对出现，形成 DNF 标志性的**暖冷对比**；
高饱和暖橙只用在焦点（宝箱、金属、光效），大面积铺地/角色底色压低饱和度。
本项目 ComfyUI 重绘据此采用 `saturated warm gold armor trim + deep cobalt blue plate + cyan gem accents`。

### 2.3 轮廓（Silhouette / Outline）

- **近黑 1px 硬描边**：所有类别共用 `(16,16,16)` / `(31,31,39)` 级深色勾边，边缘无抗锯齿，
  像素块为硬边（`NEAREST`，无灰度过渡）。
- **轮廓强度分层**：人物部件 `edge_strong=0.582`（细线高对比）> 特效 `0.413` > 道具 `0.339`
  > 怪物 `0.272` > 地砖 `0.189`（砖纹柔和、重复纹理为主）。
  即**主体越重要、边缘越硬越暗**；背景/地面刻意弱化边缘以免抢主体。
- **平涂 cel shading**：同一色相内 2–3 级离散色阶（暗 / 中 / 亮高光），无平滑渐变；
  实测单帧色数低（4–107）正是硬色阶的证据。

### 2.4 光感（Lighting）

- **固定主光方向 + 冷暖二分**：左上暖金为 key light，右下 / 阴影压冷蓝紫；
  不做逐像素光照、不做 SSR / HDR，靠色块分区表达体积。
- **亮度分层明确**：特效最亮（luma_mean 139.7 / p90 213.5）→ 道具 107.1 → 地砖 96.1
  → 人物 80.0 → 怪物 63.5（最暗，压低以便前景光效突出）。
  即「**主体中低亮度 + 特效高光点睛**」，高光集中在小面积（特效 coverage 仅 0.067，
  却贡献近白 `(226,226,226)` 与冷青 `(189,255,239)`）。
- **特效为硬边光斑 + 粒子**：`fountainwaterglow` / `fountainparticles` / `timespiral_particle`
  呈离散白/青/粉小色块与细线，无柔光晕、无 bloom 拖尾；与程序化 `_draw()` 光尘思路一致。
- 地砖类 luma_p90 达 195.3（`(252,240,247)` 近白石面高光），说明**地面也保留少量硬高光**，
  不是纯平涂暗块。

---

## 3. 对 ComfyUI 重绘的指导（本轮实际采用的提示词要素）

由上述规律提炼，写进 `r23_comfyui/batch_generate.py` 的 positive prompt：

```
pixel art game sprite, full body, front three-quarter view,
bold near-black 1px hard outline, flat cel shading with 3 hard value steps,
saturated warm gold armor trim and deep cobalt blue plate, cyan gem accents,
crisp hard pixel edges, no anti-aliasing, centered, feet on ground line,
HD-2D dark fantasy, readable silhouette, solid uniform flat neutral gray background
```

negative 明确排除：`smooth gradients / anti-aliasing / blurry / 3d render / photorealistic /
gradient background / glow / motion blur / depth of field / frame / border`，即排除一切与
DNF 硬边低色数规律相悖的效果。

地砖单独用 `seamless tileable ... top-down orthographic ... repeats seamlessly on all four edges`
（对应 §2.1 的正交顶视与平铺需求）。

**规格口径**：128px 基准画布保持不变；本轮按用户新口径**不再强制量化到 ≤256 色**，
工作流已移除 `ImageQuantize(colors=256)` 节点；实测色数按非透明像素唯一 RGB 如实登记。
用户口径「128bit」具体含义**仍待用户确认**，本轮不擅自改尺寸口径（详见 `DONE-R23.md` 歧义登记）。

---

## 4. 合规声明

- DNF 资源版权归 Neople / 腾讯，本目录仅为**本机本地开发参考素材库**。
- `r23_dnf_reference/.gdignore` → Godot 不导入该目录，**不进 pck**。
- `r23_dnf_reference/.gitignore` → `raw/` 原始可识别商业贴片**不入库 / 不随仓库分发**。
- `manifest.json`：`published_in_pck: false`、`provenance` 版权与用途说明。
- `contact_sheet.png`：4× 像素化，仅作**风格证据**，不分发可识别商业贴片。
- **未**把任何 DNF 贴片拷入 `godot/assets/`；**未**进 pck / exe / apk / 发布包。
- 发布版美术全部为本机 ComfyUI 重绘素材（`godot/assets/generated/r23/`，`published_in_pck: true`）。

---

## 5. 目视检查结论

`contact_sheet.png` 已用 ViewImage 真看：6 行 4 列共 21 格，配色条与英文标签（类别/名/帧号/色数/
覆盖率）清晰；怪物、地砖、特效、道具各格均有可辨内容，**无空白格、无破图、无纯色块**；
人物 3 格为单层部件稀疏竖条（见 §1.1 限制 2，如实登记，不伪造）。
判定：**合格（风格证据用途）**，并保留上述限制说明。
