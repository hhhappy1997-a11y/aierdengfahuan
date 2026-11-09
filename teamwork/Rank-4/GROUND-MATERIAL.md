# GROUND-MATERIAL.md · R14 地面材质挂载方案（三个 MeshInstance3D）

> 轮次：**R14**｜派单：`cmd-20261109-082141-612-A4`｜工位：Rank-4 美术管线与工具链
> 依据：`TERRAIN-TILE.md`（R13 方案）、`DONE-R14.md`（本轮真跑结论）、`godot/scenes/courtyard.tscn`（**只读核对**）、`00-协作契约.md` §9.3、`ART-SPEC-FINAL.md` §2 / §4。
> **定位：本文只给步骤与方案，不擅自改 Rank-1 场景。** `godot/scenes/courtyard.tscn`、`godot/project.godot` 及场景侧一切装配均属 Rank-1 独占，本轮一个字节未改；落地执行权与运行期验收归 Rank-1。
> 素材定位：`ground_tile.png` / `ground_material.tres` 均为**程序化占位**，用于消除「纯灰平面」；**ComfyUI 仍是主美术路线**，占位不替代正式素材。

---

## 0. 一句话结论

本轮已用 Godot 4.7.2 真跑生成一份可直接引用的 `res://assets/generated/terrain/ground_material.tres`（`StandardMaterial3D`，`albedo_texture` 指向 `ground_tile.png`、`texture_filter = 0`(Nearest)、`uv1_scale = Vector3(4,4,4)`）。Rank-1 挂载时给 `GroundPlate` / `TerraceLow` / `TerraceHigh` 三个 `MeshInstance3D` 各配**独立材质实例**：贴图入口 + `albedo_color` 置白 + `texture_filter = 0` + `texture_repeat = true` 四项成组，`uv1_scale` 按「每 tile = 4 米」分档 `16 / 3 / 2`，即可消除纯灰并保持砖块视觉大小一致。下方 §5 / §6 给两种落地方式，任选其一，**不要叠加**。

---

## 1. 本轮已落盘的资源（真跑结果，非手写）

| 项 | 值 |
|---|---|
| 材质资源 | `res://assets/generated/terrain/ground_material.tres` → `godot/assets/generated/terrain/ground_material.tres`（**249 字节**） |
| 生成方式 | `godot/scripts/build_ground_material.gd`（`extends SceneTree`）经 `ResourceSaver.save()` 真跑生成，`CACHE_MODE_IGNORE` 回读四项全通过（`DONE-R14.md` §2） |
| 贴图 | `res://assets/generated/terrain/ground_tile.png`（128×128、P 模式 16 色、R13 已导入，`.import` / `.godot/imported` 齐全） |
| `.tres` 实际文本 | 见下方代码块（Godot 自己序列化） |

```ini
[gd_resource type="StandardMaterial3D" format=3]

[ext_resource type="Texture2D" path="res://assets/generated/terrain/ground_tile.png" id="1_cqg7n"]

[resource]
albedo_texture = ExtResource("1_cqg7n")
uv1_scale = Vector3(4, 4, 4)
texture_filter = 0
```

> **`uv1_scale = Vector3(4,4,4)` 是派单给的示例值**（`DONE-R14.md` §3 #2）。这一份 `.tres` 可直接挂到任一节点做快速验证，但三个网格尺寸不同，要砖块大小一致必须按 §4 分档，见 §5 / §6。
> `albedo_color`（默认白）与 `texture_repeat`（默认 `true`）因等于默认值被 Godot 序列化时省略——这是 4.7.2 真跑结论，不是遗漏（见 §3）。

---

## 2. 现状（本轮末只读核对 `courtyard.tscn`）

| 节点 | 类型 / Mesh | Mesh 尺寸 | `material_override` | 现有材质内容 |
|---|---|---|---|---|
| `GroundPlate` | `MeshInstance3D` / `PlaneMesh_15qxa` | `Vector2(64, 64)` | `StandardMaterial3D_e34af` | `albedo_color = Color(0.14, 0.17, 0.2, 1)`、`roughness = 0.9` |
| `TerraceLow` | `MeshInstance3D` / `BoxMesh_6e1c7` | `Vector3(12, 0.6, 12)` | `StandardMaterial3D_2x0px` | `albedo_color = Color(0.2, 0.24, 0.27, 1)`、`roughness = 0.9` |
| `TerraceHigh` | `MeshInstance3D` / `BoxMesh_k5tdy` | `Vector3(8, 1.2, 8)` | `StandardMaterial3D_l1iq4` | `albedo_color = Color(0.24, 0.28, 0.3, 1)`、`roughness = 0.9` |

> 三者当前仍是**纯色 `albedo_color` + 无贴图**，即 `CAPTURE-REPORT.md` §2 的「纯灰平面」。另有 `CliffRim`（`BoxMesh_tihrx`，64×2×2，`StandardMaterial3D_p30c5`），派单未点名，§6.3 仅给可选建议。
> 文件 mtime `2026-11-09 08:28`（晚于 08:21:42 派单，Rank-1 本轮并发改动）；三个节点名、`sub_resource` id、Mesh id 与尺寸**逐字未变**，因此本文引用的 id / 片段仍对齐当前实际文件。**Rank-4 对该文件零写入**。

---

## 3. 四个必须成组设置的属性（缺一即失效）＋ 本轮枚举更正

| # | 属性 | 建议值 | 为什么必须 |
|---|---|---|---|
| 1 | `albedo_texture` | `ExtResource(...)` → `res://assets/generated/terrain/ground_tile.png` | 贴图入口；不设就还是纯色 |
| 2 | `albedo_color` | **`Color(1, 1, 1, 1)`（必须改成白）** | `albedo_texture` 与 `albedo_color` **相乘**；沿用现有深灰 `(0.14,0.17,0.2)` 会把贴图压到近乎全黑。这是最容易漏的一步 |
| 3 | `texture_filter` | **Nearest → 文本值 `0`**（`BaseMaterial3D.TEXTURE_FILTER_NEAREST`） | 契约 §5 / `ART-SPEC-FINAL.md` §4：硬像素边、无 mipmap 糊化 |
| 4 | `texture_repeat` | **`true`**（Enabled） | tile 要重复平铺；禁用时 `uv1_scale > 1` 只会拉伸边缘像素 |

> 保留原有 `roughness = 0.9`（粗糙石面）。新建的 `StandardMaterial3D` 默认 `albedo_color = Color(1,1,1,1)`、`texture_repeat = true`，所以**用本轮 `.tres` 时第 2 / 4 项已满足**；但**改场景内现有 `sub_resource`（方式 B）时必须显式把 `albedo_color` 从深灰改成白**（§6）。

### 3.1 本轮真跑对 R13 文档的两处更正（重要）

`TERRAIN-TILE.md` §3.1 / §3.3 写过 `BaseMaterial3D.TEXTURE_REPEAT_ENABLED`、`texture_repeat = 1`、`texture_repeat = Enabled`。**Godot 4.7.2 真跑结论（`DONE-R14.md` §2.1）**：

| 项 | R13 写法 | 4.7.2 实际 | 正确写法 |
|---|---|---|---|
| 纹理重复枚举常量 | `BaseMaterial3D.TEXTURE_REPEAT_ENABLED` | `ClassDB.class_get_integer_constant_list("BaseMaterial3D")` 中**无此成员**；引用会 `Parse Error` | 不要引用该常量 |
| `texture_repeat` 类型 / 值 | `texture_repeat = 1` / Enabled | **bool**，默认 `true`（`.tres` 文本里写 `texture_repeat = true`，等于默认时可省略） | `texture_repeat = true` |
| `texture_filter` | `0`（按枚举名推断，未实跑） | **真跑 = 0**，`.tres` 落盘 `texture_filter = 0` | `texture_filter = 0` |

> 清单里另有 `FLAG_USE_TEXTURE_REPEAT`，它是**渲染 flag 位**、不是 `texture_repeat` 属性的取值，勿混用。R13 原文按「不擅改历史工位件」原则保留不改，本轮只在此登记更正。

### 3.2 三个「Nearest」不在同一个枚举空间（避坑，R13 §3.3 沿用）

| 出现位置 | 枚举类型 | Nearest 对应的值 | 备注 |
|---|---|---|---|
| `SubViewportContainer.texture_filter = 1`、`HD2DPlaceholder.texture_filter = 1` | `CanvasItem.TextureFilter` | `1` | 已由 Rank-1 落地，保持不动 |
| `project.godot` 的 `textures/canvas_textures/default_texture_filter=0` | 项目设置专用枚举 | `0` | 已核对为 0，保持不动 |
| **本方案要设的 `StandardMaterial3D.texture_filter`** | **`BaseMaterial3D.TextureFilter`** | **`0`**（`TEXTURE_FILTER_NEAREST`，本轮真跑确认） | 与上面两个**不同枚举**，切勿填 `1`（那是 Linear） |

---

## 4. UV 缩放分档：统一「每 1 个 tile = 4 米」

`PlaneMesh` / `BoxMesh` 默认 UV 为 0..1 覆盖整网格；直接贴一张 128px 图会把 64×64 米地面拉成巨大色块。用 `uv1_scale = Vector3(x, y, 1)` 让贴图在 U/V 方向重复 x/y 次。按每 tile 覆盖 4×4 米（128px / 4m = 32 px/m）：

| 节点 | 网格尺寸（顶面） | 建议 `uv1_scale` | 计算 | 每 tile 实际尺寸 |
|---|---|---|---|---|
| `GroundPlate` | 64 × 64 | **`Vector3(16, 16, 1)`** | 64 / 16 | 4 × 4 m |
| `TerraceLow` | 12 × 12 | **`Vector3(3, 3, 1)`** | 12 / 3 | 4 × 4 m |
| `TerraceHigh` | 8 × 8 | **`Vector3(2, 2, 1)`** | 8 / 2 | 4 × 4 m |

> 三者 `uv1_scale` 不同但**每 tile 米数相同**，砖块在画面里大小一致。这也是三节点**不能共用一个材质实例**的原因（共用 scale 会让 64m 地面与 8m 高台密度差 8 倍）。
> 本轮交付的 `.tres` 是 `Vector3(4,4,4)`（派单示例值，第三分量对 2D UV 不生效，固定填 `1` 即可），**仅供单节点快速验证**；正式分档请按上表另存 / 另设。
> **BoxMesh 侧面拉伸（已知取舍）**：单一 `uv1_scale` 对六个面一视同仁，`TerraceLow` 侧面高 0.6m、`TerraceHigh` 侧面高 1.2m，薄侧面上纹理会被压扁。平台很薄、俯视角下顶面为主视觉，通常可接受。若需修正：方案 a `uv1_triplanar = true` + `uv1_scale = Vector3(0.25, 0.25, 0.25)`（世界空间频率，1/4 米⁻¹）；方案 b 由 Rank-1 生成 BoxMesh 时按世界米写 UV 并**去掉** `uv1_scale`。两种二选一，**不要叠加**。三平面映射会增加采样成本，移动端性能预算由 Rank-1 评估。

---

## 5. 方式 A（推荐）：外部 `.tres` 材质 + `material_override` 引用

第 1 步：以本轮真跑的 `ground_material.tres` 为模板，**复制三份**到同目录，仅改 `uv1_scale`（`texture_filter = 0` / `albedo_texture` / 默认白 / 默认 `texture_repeat=true` 均不变）：

```ini
; ground_tile_mat_plate.tres —— GroundPlate
[gd_resource type="StandardMaterial3D" format=3]
[ext_resource type="Texture2D" path="res://assets/generated/terrain/ground_tile.png" id="1_tile"]
[resource]
albedo_color = Color(1, 1, 1, 1)
albedo_texture = ExtResource("1_tile")
texture_filter = 0
texture_repeat = true
uv1_scale = Vector3(16, 16, 1)
roughness = 0.9
```

`ground_tile_mat_low.tres`（`Vector3(3, 3, 1)`）、`ground_tile_mat_high.tres`（`Vector3(2, 2, 1)`）同理，仅改 `uv1_scale`。也可直接改本轮 `ground_material.tres` 复用其中一份（它是 249 字节的真跑产物）。

第 2 步：在 `courtyard.tscn` 头部加三行 ext（打包时由 Godot 分配 uid，不建议手写）：

```ini
[ext_resource type="Material" path="res://assets/generated/terrain/ground_tile_mat_plate.tres" id="3_plate"]
[ext_resource type="Material" path="res://assets/generated/terrain/ground_tile_mat_low.tres" id="4_low"]
[ext_resource type="Material" path="res://assets/generated/terrain/ground_tile_mat_high.tres" id="5_high"]
```

第 3 步：把三个节点的 `material_override` 从 `SubResource(...)` 换成 `ExtResource(...)`：

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

> 三份 `.tres` 是否落盘、由谁落盘，属 Rank-1 装配权；**Rank-4 本轮只预置了一份 `ground_material.tres`**，未擅自生成另外两份、未伪造 uid。

---

## 6. 方式 B（最小改动）：直接改 `courtyard.tscn` 内现有 `sub_resource`

不新增文件，在原有三块 `[sub_resource type="StandardMaterial3D" ...]` 里各补 4 行（以 `GroundPlate` 为例，另两块同理只换 `uv1_scale`）。头部加一行贴图 ext：

```ini
[ext_resource type="Texture2D" path="res://assets/generated/terrain/ground_tile.png" id="3_tile"]

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_e34af"]
albedo_color = Color(1, 1, 1, 1)
albedo_texture = ExtResource("3_tile")
texture_filter = 0
texture_repeat = true
uv1_scale = Vector3(16, 16, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_2x0px"]
albedo_color = Color(1, 1, 1, 1)
albedo_texture = ExtResource("3_tile")
texture_filter = 0
texture_repeat = true
uv1_scale = Vector3(3, 3, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_l1iq4"]
albedo_color = Color(1, 1, 1, 1)
albedo_texture = ExtResource("3_tile")
texture_filter = 0
texture_repeat = true
uv1_scale = Vector3(2, 2, 1)
roughness = 0.9
```

> 三个 `sub_resource` 的 `id` 沿用原文件实际值，未增删节点、未改节点树。**方式 B 必须显式把 `albedo_color` 置白**（原值是深灰，见 §2），否则贴图会被乘暗。

### 6.1 两种方式的对应关系（勿叠加）

| | 方式 A | 方式 B |
|---|---|---|
| 新增文件 | 3 份 `.tres`（可由本轮 1 份复制） | 0 |
| 场景改动 | 3 行 ext + 3 处 `material_override` | 1 行 ext + 3 块 `sub_resource` 各补 4 行 |
| `albedo_color` | 新建材质默认白，可不写 | **必须显式改白** |
| 复用性 | 可被其它场景引用 | 仅限本场景 |

### 6.2 落地顺序建议

1. 先按 §4 定好三档 `uv1_scale`；2. 选 §5 或 §6 之一落地；3. 用编辑器保存一次让 Godot 自己序列化 `texture_filter = 0` / `texture_repeat`（避免手抄枚举值出错）；4. 按 §8 验收。

### 6.3 可选（非本轮范围）：`CliffRim`

`BoxMesh(64, 2, 2)` 若也要贴同一 tile，按每 4m 一个 tile 取 `uv1_scale = Vector3(16, 0.5, 1)` 或三平面 `Vector3(0.25, 0.25, 0.25)`；派单未点名该节点，只登记建议，不计入 R14 交付。

---

## 7. 导入设置（只读核对当前 `ground_tile.png.import`，供 Rank-1 核对）

```ini
[params]
compress/mode=0
mipmaps/generate=false
process/fix_alpha_border=true
process/premult_alpha=false
process/size_limit=0
detect_3d/compress_to=1
```

- `compress/mode=0`（lossless）、`mipmaps/generate=false`（关 mipmap，Nearest 硬边不糊）、`fix_alpha_border=true`、`premult_alpha=false`、`size_limit=0` 与 `TERRAIN-TILE.md` §4 建议一致，保持不动。
- 差异登记：当前 `detect_3d/compress_to=1`，`TERRAIN-TILE.md` §4 建议 `=0`。**本轮只读未改**，导入配置属 Rank-1 装配权；若需调整由 Rank-1 决定（`DONE-R14.md` §3 #4）。
- `uid` / `path` / `dest_files` 由 Godot 首次导入生成，Rank-4 不预置、不伪造具体值；项目级 `textures/canvas_textures/default_texture_filter=0` 已落地，无需再改。

---

## 8. 给 Rank-1 的验收自检清单（本轮不代跑）

1. 三个节点不再是纯灰：顶面可见规则错缝石砖、1px 硬缝、左上暖金受光边 / 右下冷蓝阴影。
2. 砖块在 `GroundPlate` / `TerraceLow` / `TerraceHigh` 上**视觉大小一致**（验证 §4 的 `uv1_scale` 分档生效）。
3. 拉近 / 拉远无插值模糊、无 mipmap 糊化（验证 `texture_filter = 0` + 关 mipmaps）。
4. 贴图正常重复平铺、无边缘拉伸条（验证 `texture_repeat = true`）。
5. 整体不过暗（验证 `albedo_color` 已置白；方式 B 尤其容易漏）；暖金只出现在高光、冷蓝主导阴影。
6. 用 `CAPTURE-REPORT.md` 同款命令重录一帧，与 `capture/frame00000000.png` 对照，确认「地形无贴图纯灰」项可关闭。

---

## 9. 合规声明与边界

- **只给方案，不改场景**：`godot/scenes/courtyard.tscn` **本工位零写入**（本轮期间该文件由并发实例改动，mtime `08:28`；三个地形节点 / 材质 id / Mesh id 逐字未变，见 §2）；未写 `godot/project.godot`、未写其它 `.gd` / `.tres` / `.import`（本轮唯一 `.tres` 为授权目录内 `ground_material.tres`）、未写其它工位 / 总线 / 总纲 / 契约 / 任务书，未自行 `git commit` / `git push`。
- 本轮写入仅限 `teamwork/Rank-4/`（`DONE-R14.md`、`GROUND-MATERIAL.md`）、`godot/scripts/build_ground_material.gd`、`godot/assets/generated/terrain/ground_material.tres` 与回执例外 `teamwork/command_center/ai/4/outbox/`。
- 零付费 / 零外部生成服务 / 零外部素材；ComfyUI 仍是主美术路线，本 tile 与材质仅为地形占位；中文 UTF-8；Godot 4.7.2 合法语法；所有结论均来自真跑 stdout，不伪造、不臆造运行期画面效果。
- **未完成 / 待 Rank-1**：① 材质实际挂载与运行期画面效果需 Rank-1 真跑验收（§8）；② 三份分档 `.tres` / `.import` 是否落盘及落盘方属 Rank-1 装配权（§5 / §7）；③ BoxMesh 侧面拉伸是否启用三平面映射及移动端性能预算属 Rank-1 取舍（§4）；④ R13 文档枚举写法的更正已在 §3.1 登记，R13 原文保留不改。以上均只登记、不擅改、不越界执行。
