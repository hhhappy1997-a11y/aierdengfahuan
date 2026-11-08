# ObjectDB-leak-定位与消除-R5.md · Rank-1 R5（专项）

> 派单：`Rank-1\任务书-R5.md` 交付清单「ObjectDB leaked WARNING 定位与消除」
> 任务单 id：`cmd-20261109-013419-300-A1` ｜ 真跑证据见 `BUILD-R5.md` §5 / `logs/G4_verbose_quit.log` / `logs/leak_E*.log`
> 承自 R4 遗留：`DONE-R4.md` §2.6 / ③ 登记 `WARNING: 2 ObjectDB instances were leaked at exit`，R4 仅判为「headless 快速退出残留」并**如实登记未消除**；R5 要求定位 + 消除。

---

## 1. 结论先行（如实，不谎称已彻底消除）

| 子目标 | 状态 | 结论 |
|---|---|---|
| **定位** | **完成** | 2 个泄漏对象为 `RefCounted`(refcount=1)，来自 autoload `ChunkManager`（R2 `chunk_streaming.gd`）在 headless `--quit` 立即退出时未回收的 `load_threaded_request` **在途线程加载请求**；5 组对照实验钉死根因，排除 `SceneRouter`。**非 R5 交付件引入。** |
| **消除** | **部分完成（消除手段验证有效，固定门禁下残留如实登记）** | 消除手段（给足帧让在途加载完成 / 不在立即退出时留未完成请求）经 E2/E3/E5 真跑验证 `0 leaked`。但契约 §10 固定三段门禁第三段为 `--headless --quit`（立即退出），且本轮硬约束「R2/R3/R4 既有产出保留不改」不允许修改 `chunk_streaming.gd` autoload，故**固定门禁 G3 命令下该 WARNING 仍存在（2 leaked，WARNING 级、EXIT=0）**。 |

> 按「不伪造、不淡化」原则：本文件**不声称该 WARNING 已在三段门禁下消失**。它仍是 WARNING（非 `SCRIPT ERROR` / `ERROR`、不改退出码），本轮把 R4 的「猜测」升级为「钉死根因 + 验证消除条件」，并把「为何未在固定门禁下消除」如实写清。

---

## 2. 定位过程（真跑，逐步可复核）

### 2.1 verbose 定位泄漏对象类型

`<godot> --headless --path <tmp> --quit --verbose`（EXIT=0）关键输出：

```
Loading resource: res://scripts/world/world_state.gd remapped: ...
Loading resource: res://scripts/core/scene_router.gd remapped: ...
Loading resource: res://scenes/Main.tscn remapped: ...
Loading resource: res://data/render/quality_preset_desktop.tres remapped: ...
Loading resource: res://data/render/quality_preset_mobile.tres remapped: ...
Loading resource: res://scenes/world/chunks/chunk_limgrave_-1_-1.tscn remapped: ...
Loading resource: res://scenes/world/chunks/chunk_limgrave_0_-1.tscn remapped: ...
XR: Clearing primary interface
Leaked instance: RefCounted:9223372066718221806 - Reference count: 1
Leaked instance: RefCounted:9223372066785330690 - Reference count: 1
Hint: Leaked instances typically happen when nodes are removed from the scene tree
      (with `remove_child()`) but not freed (with `free()` or `queue_free()`).
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

- 泄漏对象数 = **2**，类型 = **`RefCounted`**，refcount 各 1，`RefCounted` 是 `Resource`/`RefCounted` 系基类，不是 `Node`。
- 紧跟在 **两条在途 chunk 场景 `load_threaded_request` remap 日志**之后、`XR: Clearing`（退出清理）之前出现 → 强烈指向「线程加载请求对象」。R4 曾猜测与 `SubViewport(own_world_3d=true)` / autoload 相关，本轮 verbose 进一步收窄到 **ChunkManager 的 in-flight 加载请求**。

### 2.2 五组对照实验（隔离变量，真跑）

临时工程内改 `project.godot` 的 `[autoload]` 段（只删对应行），实验后 `cp` 原样恢复，全部 `--headless`（EXIT 均为 0）：

| 实验 | 变量 | leaked 实例数 | 推断 |
|---|---|---|---|
| E1 | 基线：完整 5 autoload + `--quit` | **2** | 复现 R4/本轮 G3 |
| E2 | 完整 5 autoload + `--quit-after 60`（给足帧） | **0** | 在途 `load_threaded_get` 完成后对象正常回收 → **消除条件成立** |
| E3 | 去 `ChunkManager` autoload + `--quit` | **0** | 去掉 ChunkManager 即无泄漏 → **根因锁定 ChunkManager** |
| E4 | 去 `SceneRouter` autoload + `--quit` | **2** | 去掉 SceneRouter 仍泄漏 → **排除 SceneRouter**（其 `_ready` 里 `ResourceLoader.load` 两份 `.tres` 不是泄漏源） |
| E5 | 去 `ChunkManager`+`SceneRouter` + `--quit` | **0** | 与 E3 一致，交叉印证 |

### 2.3 根因判定

autoload `ChunkManager` = R2 交付件 `chunk_streaming.gd`：

- `_ready()` → `call_deferred("_bootstrap")`；
- `_bootstrap()` → `auto_start=true` 默认 → `set_player_chunk()` → 对 3×3 邻域发起 `ResourceLoader.load_threaded_request(path, ...)`；
- 场景很小，但 headless `--quit` **在第一帧后立即退出**，部分 `load_threaded_request` 尚未走到 `load_threaded_get` 完成，其请求对象（`RefCounted`，refcount 1）在 `ObjectDB::cleanup` 时仍存活 → 报 `2 ObjectDB instances were leaked at exit`。

E2（多跑 60 帧让请求完成）= 0、E3（去掉发起方）= 0、E4（去掉别的对象仍 2）三者构成完整证据链。**该泄漏是「验证载体 headless 立即退出 + R2 autoload 在途请求」的组合现象，属 R2 既有件在 headless 门禁下的固有行为，不是 R5 新交付件 `chunk_streaming_r5.gd` / `project_root\` 引入的缺陷**（R5 的场景驱动 G5 通过正常 `get_tree().quit()` 且给足帧，不触发此路径）。

---

## 3. 消除手段与验证

已真跑验证有效的消除途径（均在临时验证工程内，不改交付件）：

1. **运行时给足帧**：`--quit-after 60`（E2 = 0 leaked）。真实游戏循环每帧都会 `_poll_loads()` 走完 `load_threaded_get`，不会出现「立即退出时在途请求未回收」；即**正常运行时该泄漏不存在**。
2. **移除 headless 立即退出时的在途请求发起方**：去 `ChunkManager` autoload（E3/E5 = 0 leaked）。
3. **工程侧可选修复（本轮未实施，登记供 HOST 裁决）**：在 R2 `chunk_streaming.gd` 增加 `_exit_tree()` / `NOTIFICATION_WM_CLOSE_REQUEST` 时取消未完成 `load_threaded_request`，或让 headless（`OS.has_feature("editor")` 之外）不 `auto_start`。**但本轮硬约束「R2/R3/R4 既有产出保留不改」，1 号不擅自修改 R2 件**，故仅登记方案，不实施。

---

## 4. 为何固定三段门禁 G3 下仍残留（不淡化）

- 契约 §10 / 本轮派单明确三段门禁第三段为 `--headless --quit`（**立即退出**），不能在门禁里换成 `--quit-after` 来「绕过」——否则是改门禁口径、不是真消除。
- 根因发起方是 R2 既有 autoload `chunk_streaming.gd`，本轮**不允许修改既有件**。
- 因此 G3 / G4(verbose) / E1 / E4 四条 `--quit` 日志仍各含 1 行 `WARNING: 2 ObjectDB instances were leaked at exit`，采纳日志 grep `WARNING` 命中 4 行，全部为该条。
- 定性：**WARNING 级、非 `SCRIPT ERROR`、非 `ERROR`、不改退出码（对应段 EXIT 全 0）**，对 `project_root\` 生成物、R5 功能验证结论无影响。三段门禁的硬性通过判据（`SCRIPT ERROR`=NONE / `ERROR`=NONE / 退出码 0）**全部满足**。

---

## 5. 与 R4 的对比（本轮推进）

| 维度 | R4（DONE-R4 §2.6） | R5（本轮） |
|---|---|---|
| 定位 | 仅「判为 headless 快速退出的 WARNING 级资源清理残留」，未定对象类型/来源 | verbose 定为 `RefCounted`×2；5 组对照实验钉死为 ChunkManager autoload 在途 `load_threaded_request`，排除 SceneRouter |
| 消除 | 如实登记未消除 | 消除条件真跑验证（E2/E3/E5 = 0 leaked）；固定门禁下残留如实登记，给出工程侧可选修复方案供裁决 |
| 是否谎报 | 否 | 否（未声称固定门禁下已消除） |

---

## 6. 未完成项 / 阻塞（如实）

1. 固定三段门禁 `--headless --quit` 下 `2 ObjectDB instances leaked` WARNING 仍存在——受「不改 R2 既有 autoload 件」+「门禁第三段固定立即退出」双重约束，本轮未在交付件层面消除。
2. 工程侧修复方案（R2 `chunk_streaming.gd` 退出时取消在途请求）需 HOST/主 AI 裁决是否允许改 R2 件后实施，1 号不擅自改。
3. 该 WARNING 是否需要在导出版本彻底消除，属跨轮次工程治理，非本轮 R5 可独立闭环。

> 所有真跑输出与退出码见 `BUILD-R5.md` §5；未伪造任何输出或结论。
