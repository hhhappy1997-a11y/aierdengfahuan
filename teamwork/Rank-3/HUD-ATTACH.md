# HUD-ATTACH.md · R14 HUD 接入件执行说明

> 命令 `cmd-20261109-082141-610-A3` · `[ROUND=R14]` · Rank-3（RPG / 世界 / 存档）
> 配套件：`godot/scripts/attach_hud.gd`、`godot/scenes/hud.tscn`（R13 已交付）
> 引擎 Godot 4.7.2.stable · 纯程序化、零外部素材 · 中文 UTF-8

## 1. 定位

`attach_hud.gd` 是「把独立 HUD 场景接入主场景」的**可复用接入件**（`extends SceneTree`）：

`load("res://scenes/courtyard.tscn")` → `instantiate()` → `load("res://scenes/hud.tscn").instantiate()`
以**实例**挂到 `SubViewportContainer/SubViewport/FXLayer` 下 → 只给新节点及其子节点设 `owner` →
`PackedScene.pack()` 前后比对节点数 → `CACHE_MODE_IGNORE` 回读校验 HUD 存在。

**R14 只交付脚本 + 本说明，不执行写入主场景。**

## 2. 执行时机（为什么是 R15 串行）

| 轮次 | 动作 |
|---|---|
| R14（本轮） | 仅 `--check-only --script` 验证语法，**不调用脚本逻辑** |
| R15 | Rank-1 结束本轮对 `courtyard.tscn` 的并发修改、场景文件稳定后，**串行**去掉 `--check-only` 真跑一次 |

原因：Rank-1 本轮并发改同一 `courtyard.tscn`。脚本真跑会 `ResourceSaver.save()` 覆盖该文件，
并行会互相覆盖。R15 必须等 Rank-1 本轮落盘完成且不再改动后再执行，且执行前后各留一次哈希。

## 3. 命令

R14 语法门禁（真跑、无写入）：

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --check-only --script "res://scripts/attach_hud.gd"
```

R15 串行接入（真跑、会覆盖 `courtyard.tscn`）：

```
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --script "res://scripts/attach_hud.gd"
```

R15 执行前先备份（见 §6）。脚本内任何校验不通过都会 `push_error` + `quit(1)`，且**在 save 之前返回**，
失败不会落盘。

## 4. 节点数预期（22→23）与口径

- 当前 `courtyard.tscn` 共 **22** 个 `[node]` 段（R14 开工复核）。
- 统计口径：`PackedScene.get_state().get_node_count()`，即 **.tscn 内 `[node]` 段数量**（SceneState 层），
  **不是**运行期递归节点数。
- `hud.tscn` 以 `instance=ExtResource(...)` 挂入：实例根节点 `Hud` 在本场景里只占 **1** 个节点段，
  其内部 `HudPanel` / `TitleLabel` 属于被实例的场景，不计入本场景 SceneState → **22 + 1 = 23**。
- 运行期 `instantiate()` 会展开实例，整树递归节点数为 **22 + 3 = 25**，属正常实例展开，不是错误；
  脚本同时用 `PROBE hud_present` 校验 `HudPanel` / `TitleLabel` 完整。
- 若引擎未把 HUD 写成实例（真实 `get_node_count()` 会是 25），脚本会如实 `push_error` + `quit(1)`，
  **不伪造 23**。R15 若遇此情况，按实际输出登记并交调度裁决，不要改预期值蒙混。

| 项 | 预期 |
|---|---|
| pack 前 `get_node_count()` | 22 |
| pack 后 `get_node_count()` | 23 |
| pack→instantiate 运行期递归节点数 | 25（HUD 实例展开） |
| `CACHE_MODE_IGNORE` 回读 | `FXLayer/Hud` 存在，且 `HudPanel` / `TitleLabel` 存在 |

## 5. 脚本内关键实现

- **owner**：`_assign_owner_added(hud, root)` 只给追加的 HUD 子树（`Hud` + `HudPanel` + `TitleLabel`）
  设 `owner=root`；既有 22 节点 owner 由 `instantiate()` 自带，**不改动**。
- **实例标记**：`hud.set("scene_file_path", HUD_PATH)`，让 `pack()` 写出 `instance=ExtResource(...)`。
- **幂等**：若 `FXLayer/Hud` 已存在，脚本直接拒绝重复挂入。
- **回读**：`ResourceLoader.load(COURTYARD_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)`
  强制忽略缓存、从磁盘重读刚保存的场景后再 `instantiate()` 校验。
- **零外部素材**：只用工程内既有 `.tscn` 与 Godot 内置 API，无贴图 / 字体 / 插件 / 云服务 / 付费调用。

## 6. 回退方式

**执行前备份**（R15；按工程既有 `copy /Y` 口径，也可用 `cp`）：

```
copy /Y "F:\Game\aierdengfahuan\godot\scenes\courtyard.tscn" "F:\Game\aierdengfahuan\godot\scenes\courtyard.tscn.r14.bak"
```

**回退**（还原到接入前）：

```
copy /Y "F:\Game\aierdengfahuan\godot\scenes\courtyard.tscn.r14.bak" "F:\Game\aierdengfahuan\godot\scenes\courtyard.tscn"
```

其它回退选项：

1. 脚本校验失败即未 save，**天然回退**，无需还原。
2. 只想撤销 HUD：从 `courtyard.tscn` 删除
   `[node name="Hud" parent="SubViewportContainer/SubViewport/FXLayer" instance=ExtResource(...)]`
   这一段，以及它对应的 `[ext_resource ... path="res://scenes/hud.tscn" ...]` 登记行；
   其余既有节点保持不动。
3. `.bak` 属临时文件，回退确认后自行清理；本工位**不自行 git**。

## 7. 边界声明

- R14 未写 `courtyard.tscn` / 其它主场景，未自行 git（commit / push 均未执行）。
- 可写范围仅 `Rank-3\`、`godot/scripts/attach_hud.gd`、`command_center/ai/3/outbox/`（回执）。
- 22→23 是脚本内的**设计预期与断言**，R14 未真跑 pack、未取得实际节点数输出；
  实际值以 R15 真跑 stdout 的 `NODE_COUNT` 行为准。
