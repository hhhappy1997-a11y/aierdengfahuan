# TERRAIN-TILE.md · R13 地面 tile 与 `courtyard.tscn` 材质挂载方案

> 轮次：**R13（画面整改 · 地形无贴图纯灰）**｜派单：`cmd-20261109-080019-799-A4`｜工位：Rank-4 美术管线与工具链
> 依据：`capture/CAPTURE-REPORT.md` §2「地形是无贴图的纯灰平面」、`00-协作契约.md` §9.3、`ART-SPEC-FINAL.md` §2 / §4、`godot/scenes/courtyard.tscn`（只读核对）。
> **定位：本文只给方案，不擅自改 Rank-1 场景。** `godot/scenes/courtyard.tscn`、`godot/project.godot`、一切 `.gd` 均属 Rank-1 独占，本轮一个字节未改。落地执行权与运行期验收归 Rank-1。
> 素材定位：本 tile 是**程序化 `_draw()` 式地形占位**，用于消除「纯灰平面」；**ComfyUI 仍是主美术路线**，占位不替代正式素材（契约 §9.3 / `ART-SPEC-FINAL.md` §7）。

---

## 0. 一句话结论

给 `GroundPlate` / `TerraceLow` / `TerraceHigh` 三个 `MeshInstance3D` 的 `StandardMaterial3D` 各加四样东西：`albedo_texture` 指向 `res://assets/generated/terrain/ground_tile.png`、`albedo_color` 置白、`texture_filter = Nearest`、`uv1_scale` 按「每 tile = 4 米」分档设置，并开启 `texture_repeat`。三个节点用**各自独立**的材质实例（贴图相同、`uv1_scale` 不同），才能保证不同尺寸网格上的砖块密度一致。

---

## 1. 本轮交付的 tile（统计摘要，实际值见 `DONE-R13.md` §2）

| 项 | 值 |
|---|---|
| 主落位 | `res://assets/generated/terrain/ground_tile.png` → `godot/assets/generated/terrain/ground_tile.png` |
| 留档 | `teamwork/Rank-4/ground_tile.png`（与主落位 sha256 一致） |
| 尺寸 | **128 × 128** |
| 模式 | **P（8-bit 索引图，无 alpha 通道）** |
| 唯一颜色数 | **16**（≤ 256，全部取自共享板 `hd2d_index_256_v1` 冻结 32 色） |
| 文件字节数 | **1495** |
| 量化 | `quantize(palette=共享板, dither=NONE)`：底图 46 色 → 收敛 16 色，无误差扩散 |
| Nearest 适用性 | 整数倍 2× 放大后颜色集合不变（不插值出新色）；无 resize / 无抗锯齿 / 无字体 / 无模糊，硬像素边 |
| 可平铺 | 是：32×16 石砖、奇数行错缝 16px，128 可整除，四周硬缝对齐 |

**配色与光向**：主体暖灰石土（`#C6BBA4` → `#29251F` 五档），缝隙与右下背光边为冷蓝夜雾（`#7E96BF` / `#2B3A5C` / `#16233F` 等），左上受光边少量暖金高光（`#FFD27A` / `#F0A94C`），零星苔点。对应 HD-2D「暖金光 × 冷夜雾」基调：暖金只作高光、冷蓝主导阴影，避免整片过暖导致冷暖对比失效（`ART-SPEC-FINAL.md` §2.2）。

生成脚本：`teamwork/Rank-4/gen_ground_tile.py`（固定 `seed=1304`，可复跑；零外部生成服务、零付费、仅 Pillow）。

---

## 2. 现状（只读核对 `godot/scenes/courtyard.tscn`）

| 节点 | 类型 / Mesh | Mesh 尺寸 | 现有 `material_override` | 现有材质内容 |
|---|---|---|---|---|
| `GroundPlate` | `MeshInstance3D` / `PlaneMesh_15qxa` | `Vector2(64, 64)` | `StandardMaterial3D_e34af` | `albedo_color = Color(0.14, 0.17, 0.2, 1)`、`roughness = 0.9` |
| `TerraceLow` | `MeshInstance3D` / `BoxMesh_6e1c7` | `Vector3(12, 0.6, 12)` | `StandardMaterial3D_2x0px` | `albedo_color = Color(0.2, 0.24, 0.27, 1)`、`roughness = 0.9` |
| `TerraceHigh` | `MeshInstance3D` / `BoxMesh_k5tdy` | `Vector3(8, 1.2, 8)` | `StandardMaterial3D_l1iq4` | `albedo_color = Color(0.24, 0.28, 0.3, 1)`、`roughness = 0.9` |

> 三者当前都是**纯色 `albedo_color` + 无贴图**，正是 `CAPTURE-REPORT.md` §2 登记的「纯灰平面」。
> 另有 `CliffRim`（`BoxMesh_tihrx`，`Vector3(64, 2, 2)`，`StandardMaterial3D_p30c5`），本轮派单未点名，下面 §3.6 仅给可选建议，不作为本轮交付。

> **并发变更核对（本轮末只读复核，如实登记）**：`courtyard.tscn` 在本轮期间由并发实例调整过 `Camera3D.transform`（`0, 12, 18` → `0, 9.6, 14.4`）与 `SunLight.light_color` / `light_energy`（更暖的金光、1.8），文件 mtime `2026-11-09 08:04:36`（晚于 08:00:20 派单）。**本工位对该文件零写入**；且 `GroundPlate` / `TerraceLow` / `TerraceHigh` 三个节点、其 `material_override` 的 `sub_resource` id、三个 Mesh 的 id **逐字未变**，因此 §3.4 / §3.5 引用的 id 与 `.tscn` 片段仍对齐当前实际文件，方案无需改。该并发改动与本文同属 R13「画面整改」（镜头 + 暖金主光），彼此不冲突。

---

## 3. 挂载方案

### 3.1 四个必须成组设置的属性（缺一即失效）

| # | 属性 | 建议值 | 为什么必须 |
|---|---|---|---|
| 1 | `albedo_texture` | `ExtResource("...")` → `res://assets/generated/terrain/ground_tile.png` | 贴图入口；不设就还是纯色 |
| 2 | `albedo_color` | **`Color(1, 1, 1, 1)`（必须改成白）** | `albedo_texture` 与 `albedo_color` **相乘**；沿用原来的深灰 `(0.14,0.17,0.2)` 会把贴图压到近乎全黑。这是最容易漏的一步 |
| 3 | `texture_filter` | **Nearest**（`BaseMaterial3D.TEXTURE_FILTER_NEAREST`） | 契约 §5 / `ART-SPEC-FINAL.md` §4：硬像素边、无 mipmap 糊化 |
| 4 | `texture_repeat` | **Enabled**（`BaseMaterial3D.TEXTURE_REPEAT_ENABLED`） | tile 要重复平铺；禁用时 `uv1_scale > 1` 只会拉伸边缘像素 |

> 保留原有 `roughness = 0.9`（粗糙石面，不抢暖金高光）。不要顺手改 `albedo_color` 之外的既有字段。

### 3.2 UV 缩放建议：统一「每 1 个 tile = 4 米」

`PlaneMesh` / `BoxMesh` 的默认 UV 都是 **0..1 覆盖整个网格**。若直接贴一张 128px 图，64×64 米的地面只显示 1 张贴图，必然被拉成巨大色块。用 `uv1_scale = Vector3(x, y, 1)` 让贴图在 U/V 方向重复 x/y 次。

按「每 tile 覆盖 4×4 米」定密度（128px / 4m = 32 px/m，与 640×360 低分辨率缓冲 + Nearest 放大的像素密度相称）：

| 节点 | 网格尺寸（顶面） | 建议 `uv1_scale` | 计算 | 每 tile 实际尺寸 |
|---|---|---|---|---|
| `GroundPlate` | 64 × 64 | **`Vector3(16, 16, 1)`** | 64 / 16 | 4 × 4 m |
| `TerraceLow` | 12 × 12 | **`Vector3(3, 3, 1)`** | 12 / 3 | 4 × 4 m |
| `TerraceHigh` | 8 × 8 | **`Vector3(2, 2, 1)`** | 8 / 2 | 4 × 4 m |

> 三者 `uv1_scale` 不同但**每 tile 米数相同**，所以砖块在画面里大小一致、不会一块粗一块细。这也是为什么三节点**不能共用一个材质实例**（共用 scale 会让 64m 地面与 8m 高台密度差 8 倍）。
> `uv1_scale` 的第三个分量对 2D UV 不生效，固定填 `1`。

**BoxMesh 侧面拉伸（已知取舍，如实登记）**：单一 `uv1_scale` 对 BoxMesh 六个面一视同仁，`TerraceLow` 侧面高 0.6m、`TerraceHigh` 侧面高 1.2m，会在很薄的侧面上重复 3 / 2 个 tile，纹理被压扁。平台很薄、镜头俯视角下顶面为主视觉，通常可接受。若 Rank-1 认为明显，可选修正：

- 方案 a：`uv1_triplanar = true` + `uv1_triplanar_sharpness` 默认；此时 `uv1_scale` 语义变为**世界空间频率**，改为 `Vector3(0.25, 0.25, 0.25)`（1/4 米⁻¹ = 每 4m 一个 tile）。注意三平面映射会增加纹理采样成本，移动端降级档请由 Rank-1 在性能预算内评估。
- 方案 b：未来由 Rank-1 在生成 BoxMesh 时按世界米写 UV，则**去掉** `uv1_scale`（保持 1）。两种做法二选一，**不要叠加**，否则密度会翻倍。

### 3.3 三个「Nearest」不在同一个枚举空间（避坑）

场景里已有的 `texture_filter = 1` 是 `CanvasItem` 的枚举，**不能照抄到材质上**：

| 出现位置 | 枚举类型 | Nearest 对应的值 | 备注 |
|---|---|---|---|
| `SubViewportContainer.texture_filter = 1`（tscn:49）、`HD2DPlaceholder.texture_filter = 1`（tscn:129） | `CanvasItem.TextureFilter` | `1`（`TEXTURE_FILTER_NEAREST`；`0` = Inherited） | 已由 Rank-1 落地，保持不动 |
| `project.godot` 的 `textures/canvas_textures/default_texture_filter=0` | 项目设置专用枚举 | `0`（`0`=Nearest，`1`=Linear） | `ART-SPEC-FINAL.md` §4 已核对为 0，保持不动 |
| **本方案要设的 `StandardMaterial3D.texture_filter`** | **`BaseMaterial3D.TextureFilter`** | **`TEXTURE_FILTER_NEAREST`（该枚举中值为 `0`）** | 与上面两个**不同枚举**，切勿填 `1`（那是 Linear） |

> 落地建议：在编辑器里把材质 `Texture Filter` 下拉选 **Nearest** 后保存，让 Godot 自己序列化出准确数值；下面 `.tres` / `.tscn` 片段中的 `texture_filter = 0` 是按 `BaseMaterial3D.TEXTURE_FILTER_NEAREST` 给出的文本值，**以枚举名为准**。本轮未在 Godot 运行期实跑该序列化值，不臆造运行期结论（见 §6）。

### 3.4 方式 A（推荐）：外部 `.tres` 材质资源 + `material_override` 引用

优点：三个材质各自可调、可被其它场景复用、不把场景文本撑长。先落一个共享的贴图 ext 与三份材质，例如 `res://assets/generated/terrain/ground_tile_mat_plate.tres`：

```ini
[gd_resource type="StandardMaterial3D" format=3]

[ext_resource type="Texture2D" path="res://assets/generated/terrain/ground_tile.png" id="1_tile"]

[resource]
albedo_color = Color(1, 1, 1, 1)
albedo_texture = ExtResource("1_tile")
texture_filter = 0
texture_repeat = 1
uv1_scale = Vector3(16, 16, 1)
roughness = 0.9
```

`TerraceLow` / `TerraceHigh` 各复制一份，仅把 `uv1_scale` 改为 `Vector3(3, 3, 1)` / `Vector3(2, 2, 1)`（同目录另存 `ground_tile_mat_low.tres` / `ground_tile_mat_high.tres`）。然后在 `courtyard.tscn` 头部加三行 ext，并把三个节点的 `material_override` 从 `SubResource(...)` 换成 `ExtResource(...)`：

```ini
[ext_resource type="Material" path="res://assets/generated/terrain/ground_tile_mat_plate.tres" id="3_plate"]
[ext_resource type="Material" path="res://assets/generated/terrain/ground_tile_mat_low.tres" id="4_low"]
[ext_resource type="Material" path="res://assets/generated/terrain/ground_tile_mat_high.tres" id="5_high"]
```

```ini
[node name="GroundPlate" type="MeshInstance3D" parent="SubViewportContainer/SubViewport/Terrain" unique_id=468563102]
material_override = ExtResource("3_plate")
mesh = SubResource("PlaneMesh_15qxa")

[node name="TerraceLow" type="MeshInstance3D" parent="SubViewportContainer/SubViewport/Terrain" unique_id=1792765888]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 8, 0.3, -6)
material_override = ExtResource("4_low")
mesh = SubResource("BoxMesh_6e1c7")

[node name="TerraceHigh" type="MeshInstance3D" parent="SubViewportContainer/SubViewport/Terrain" unique_id=760291856]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -9, 0.6, -8)
material_override = ExtResource("5_high")
mesh = SubResource("BoxMesh_k5tdy")
```

> 三份 `.tres` 是否落盘、由谁落盘，属 Rank-1 装配权。本轮 **Rank-4 未预置任何 `.tres`**，避免越界；上面文本可直接拷贝使用。

### 3.5 方式 B（最小改动）：直接改 `courtyard.tscn` 内现有 `sub_resource`

不新增文件，在原有三块 `[sub_resource type="StandardMaterial3D" ...]` 里各补 4 行（以 `GroundPlate` 为例，另两块同理只换 `uv1_scale`）：

```ini
[ext_resource type="Texture2D" path="res://assets/generated/terrain/ground_tile.png" id="3_tile"]

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_e34af"]
albedo_color = Color(1, 1, 1, 1)
albedo_texture = ExtResource("3_tile")
texture_filter = 0
texture_repeat = 1
uv1_scale = Vector3(16, 16, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_2x0px"]
albedo_color = Color(1, 1, 1, 1)
albedo_texture = ExtResource("3_tile")
texture_filter = 0
texture_repeat = 1
uv1_scale = Vector3(3, 3, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_l1iq4"]
albedo_color = Color(1, 1, 1, 1)
albedo_texture = ExtResource("3_tile")
texture_filter = 0
texture_repeat = 1
uv1_scale = Vector3(2, 2, 1)
roughness = 0.9
```

> 三个 `sub_resource` 的 `id` 沿用原文件实际值，未改动节点树、未增删节点。

### 3.6 可选（非本轮范围）：`CliffRim`

`BoxMesh(64, 2, 2)` 若也要贴同一 tile，按每 4m 一个 tile 取 `uv1_scale = Vector3(16, 0.5, 1)` 或用三平面映射 `Vector3(0.25, 0.25, 0.25)`；派单未点名该节点，此处只登记建议，不计入 R13 交付。

---

## 4. 导入设置建议（`.import` 关键项，供 Rank-1 核对）

PNG 首次被 Godot 导入时会自动生成 `ground_tile.png.import` 与 `.godot/imported/...`。按 `ART-SPEC-FINAL.md` §4 四项，关键 `params` 建议：

```ini
[params]
compress/mode=0
mipmaps/generate=false
process/fix_alpha_border=true
process/premult_alpha=false
process/size_limit=0
detect_3d/compress_to=0
```

- `compress/mode=0`（lossless）、`mipmaps/generate=false`（关 mipmap，Nearest 硬边不糊）、`fix_alpha_border=true`（防透明边杂色，本图无 alpha 亦无害）、`detect_3d/compress_to=0`（不转 3D 压缩格式）。
- `uid` / `path` / `dest_files` / `metadata` 由 Godot 首次导入生成，**Rank-4 不预置、不伪造具体值**；项目级 `textures/canvas_textures/default_texture_filter=0` 已由 Rank-1 落地，无需再改。
- 若开启纹理重复，`mipmaps/generate=false` 更要保持：远处不会因 mipmap 与 Nearest 冲突出现闪烁。

---

## 5. 给 Rank-1 的验收自检清单（本轮不代跑）

1. 三个节点不再是纯灰：顶面可见规则错缝石砖、1px 硬缝、左上暖金受光边 / 右下冷蓝阴影。
2. 砖块在 `GroundPlate` / `TerraceLow` / `TerraceHigh` 上**视觉大小一致**（验证 §3.2 的 `uv1_scale` 分档生效）。
3. 拉近/拉远无插值模糊、无 mipmap 糊化（验证 `texture_filter = Nearest` + 关 mipmaps）。
4. 贴图正常重复平铺、无边缘拉伸条（验证 `texture_repeat = Enabled`）。
5. 整体不过暗（验证 `albedo_color` 已置白）；暖金只出现在高光、冷蓝主导阴影，冷暖对比未被压平。
6. 用 `CAPTURE-REPORT.md` 同款命令重录一帧，与 `capture/frame00000000.png` 对照，确认「地形无贴图纯灰」项可关闭。

---

## 6. 合规声明与未完成项

- **只给方案，不改场景**：`godot/scenes/courtyard.tscn` **本工位零写入**（本轮期间该文件由并发实例调整了镜头与暖金主光，见 §2；三个地形节点与材质 id 未变）；未写 `godot/project.godot`、未写任何 `.gd` / `.tres` / `.import`、未写其它工位 / 总线 / 总纲 / 契约 / 任务书，未自行 `git commit` / `git push`。
- 本轮写入仅限 `teamwork/Rank-4/`（`TERRAIN-TILE.md`、`gen_ground_tile.py`、`ground_tile.png`、`DONE-R13.md`）、`godot/assets/generated/terrain/`（`ground_tile.png`）与回执例外 `teamwork/command_center/ai/4/outbox/`。
- 零付费 / 零外部生成服务；ComfyUI 仍是主美术路线，本 tile 仅为地形占位；中文 UTF-8；PNG 与 JSON 均真跑校验，不伪造输出。
- **未完成 / 待 Rank-1**：① 材质实际挂载与运行期画面效果需 Rank-1 在场景侧真跑验收（§5），本轮**未实跑、不臆造运行期结论**；② `BaseMaterial3D.TEXTURE_FILTER_NEAREST` 在 4.7.2 的文本序列化值建议由编辑器保存后确认（§3.3）；③ BoxMesh 侧面拉伸是否启用三平面映射、以及移动端性能预算，属 Rank-1 取舍（§3.2）；④ `.tres` / `.import` 是否落盘及落盘方，属 Rank-1 装配权（§3.4 / §4）。以上均只登记、不擅改、不越界执行。
