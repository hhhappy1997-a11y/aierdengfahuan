# 艾尔登法环 · HD-2D（aierdengfahuan）

> 项目级**运行时状态表**。按 godogen `prompts/runtime.md` 纪律长期维护三块：① 已做了什么、② 还差什么、③ 资产清单表；
> 结构性事实自己验（能加载 / 无 SCRIPT ERROR / 资产就位），产出先目视检查再接入，零付费、零外部依赖。
> 工程根 `F:/Game/aierdengfahuan`｜Godot 工程 `F:/Game/aierdengfahuan/godot`｜引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`
> （`--version` = `4.7.2.stable.official.ed1daf0bf`，R22 实测 `EXIT=0`）。
> 本文件由 **R22 · cmd-20261109-124640-185-A3（Rank-3）** 更新；资产表字节数均为 `stat -c %s` 对实际落盘文件的实测值，不编造。
> **R23 · cmd-20261109-133602-490-A3（Rank-3）** 追加 §3.4「R23 素材条目与本机可选素材源合规登记」（口径 / 合规登记，非落盘产物）；§3.1~§3.3 既有实测值与历史结论未改。

---

## 中枢 done 轮次

来源：`teamwork/command_center/commander/report.md`（调度中枢战报，逐 ROUND 的 done 记录）。

| 项 | 值 |
|---|---|
| 中枢**最近 done 轮次** | **R21B**（`cmd-20261109-122557-230-A4`，2026-11-09 12:37:03 done，按最终工程重导 exe / apk） |
| 当前 dispatched 轮次 | **R22**（A1 / A2 / A3 / A4 四路，2026-11-09 12:46:40 派发；本 README 由 A3 本单更新） |
| 已 done 的 ROUND 序列 | R7 · R8 · R9 · R10 · R11 · R12 · R13 · R14 · R15 · R16 · R17 · R18 · R19 · R20 · R20B · R21 · R21B |
| 1–4 号累计完成 | 30 / 23 / 23 / 26（report.md「1-4 号 AI 状态」） |

> 资产表「中枢 done 轮次」列依据 report.md 各 ROUND 的**任务标题与 done 记录**归类，非逐文件精确溯源；
> 逐文件原始落位轮次见各 `teamwork/Rank-N/DONE-R*.md`。R21B = 工程冻结后的最终交付态，R22 = 本单真跑验收态。

---

## 一、已做了什么

| 域 | 已落地（含对应中枢 done 轮次） |
|---|---|
| 工程骨架 | `godot/project.godot`：`config_version=5`、`run/main_scene=res://scenes/Main.tscn`、**6 个 autoload**（WorldState / GameEvents / SaveSystem / ChunkManager / SceneRouter / SaveDeltaWriter，R20 注册第 6 个）、15 个 input action、Jolt Physics、GL Compatibility、项目级 Nearest 纹理过滤。R7–R9 门禁归零，R20 / R21B |
| 存档（Rank-3） | **十字段 SaveDelta**（`schema_version / slot / seq / baseline / flags / quests / inventory / spawns / removals / meta`）、`schema_version=3`、单槽 `slot_01`、**三段式 flag** `^(world\|quest\|combat\|grace\|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`、`.tmp → flush → rename_absolute → delta.json` 原子写、1→2→3 迁移 / 日志升序回放 / `_apply_snapshot`。R20 注册 autoload、R21 统一 `travel_to()` 与 `grace_fast_travel()` 两入口口径。**R22 本单补做「写盘 → 重启独立引擎进程 → `_load()` 回放 → `get_flag` 读回」端到端真跑**（见下） |
| 战斗（Rank-2） | 帧数据 / Boss 3 招 / 阶段切换 / `CombatDataValidator` 类级实例化、翻滚帧修正。R9–R21 |
| 美术与渲染（Rank-4/Rank-1） | I-5 四类 PNG、SpriteFrames、HD-2D 光效独立场景、画质桌面 / 移动双档、地面材质与程序化占位兜底。R13–R21 |
| 场景 | `courtyard.tscn`（**实测 25 节点**）、`player.tscn` / `boss_01_margit.tscn` / `hud.tscn` / `hd2d_fx.tscn` / `quality_settings.tscn`。R15–R21B |
| 产物 | `build/` 下 exe / pck / apk / apk.idsig（R21B 按最终工程重导，字节数见资产表） |
| 三段门禁 / 回归 | R21 的 **31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R22 重跑**不回退**；G1 `--import` / G2 `--check-only --script` / G3 `--quit` 全 `EXIT=0`，12 份 R22 日志 `grep SCRIPT ERROR / Parse Error / ERROR` **全 0** |

### R22 存档端到端真跑结论（补 R21 §3.2 明确未做项）

用既有 `SaveDeltaWriter.commit(reason)` / `world_state.gd._load()` / `save_delta.gd` 十字段口径，**两个独立 Godot 进程**完成完整回放：

```
[写盘进程]  E2E_PHASE=write ... --script r22_save_e2e.gd   → SUMMARY phase=write pid=30324 pass=7 fail=0 ok=true
[重启进程]  E2E_PHASE=read  ... --script r22_save_e2e.gd   → SUMMARY phase=read  pid=38396 pass=9 fail=0 ok=true
```

- 两阶段 **pid 不同**（30324 / 38396）= 真正重启引擎进程，非同进程内内存往返。
- 写盘：经 `set_flag` 注入 5 个三段式 flag → `SaveDeltaWriter.commit("r22_e2e_write")` → 真实原子写 `user://saves/slot_01/delta.json`（932 字节）。
- 读回：新进程 `_ready()` 后内存为基线（`get_flag(...,false)=false`，未读档）→ 调既有 `_load()` 回放 → `get_flag` 逐项读回 **5/5 一致**。
- 校验：**十字段齐全且无额外顶层字段**、`schema_version=3`、`slot=slot_01`、5 个 flag 全通过三段式正则、`meta.last_commit_reason=r22_e2e_write` 跨进程一致。
- 合计 **16 PASS / 0 FAIL**；stdout 证据留档 `teamwork/Rank-3/R22-E2E-write.log` / `R22-E2E-read.log`。

---

## 二、还差什么

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 1 | ComfyUI 正式 spritesheet 主美术路线接入 | 长期项 · 未解决 | 当前为本地零付费出图 + 程序化 `_draw()` 占位兜底；ComfyUI 仍是主路线（历轮 DONE 一贯口径），不宣称已能出图 |
| 2 | 真正 HDR bloom / 3D 体积光 / SSR | 长期项 · 未达成 | 四项光效为 2D 程序化 `draw_*` 几何 / 加色近似；`gl_compatibility` 后端不支持原生 3D 后处理，不夸大 |
| 3 | 赐福菜单 UI 画面 / 运行期人工试玩验收 | 未做 · 不阻塞 | `hud.tscn` 仍为 `HudPanel` + `TitleLabel`，菜单以 `Array[Dictionary]` 数据快照供 UI 消费；画面 / 人工试玩不在本单范围 |
| 4 | 15–20 秒实机录屏并目视回看 | R22 · A4 另单在办 | 本单（A3）不代做、不谎报；godogen 交付纪律由 Rank-4 R22 承担 |
| 5 | 既有退出 WARNING | 如实保留 · 非 ERROR | `[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`，历轮已登记，R22 真跑中仍出现，未隐藏、未宣称零 WARNING |
| 6 | 历史待裁决 / 登记项 | 只登记不擅改 | A8（契约两段式示例 vs 严格三段式）、`chunk.<id>.loaded` 归一口径、6 条 `res://scenes/*` 未实机换场景、`chunk_origin` 全 0 —— 交 HOST 裁决 |
| 7 | 多槽存档 UI / 玩家精确坐标进存档 | 按规范不做 | 规范冻结单槽 `slot_01`、复活锚点以 `meta.last_grace_id` 表达，非缺陷 |
| 8 | `project.godot` | 工程冻结 | 本轮四路均不写，保证录屏对应稳定工程、产物无需重导 |

> 存档端到端真跑在 R21 §3.2 曾登记为「按公共契约不新建只读探针 / 巡检脚本，未冒充本轮重跑」；
> **R22 本单已补齐**（用本单验证载体 `teamwork/Rank-3/r22_save_e2e.gd`，非只读探针、非进度巡检脚本），故不再列为未完成项。

---

## 三、资产清单表（依据实际落盘文件，字节数为 `stat -c %s` 实测）

### 3.1 类别汇总

| 类别 | 实际落盘文件（路径相对工程根） | 文件数 | 字节数合计 | 中枢 done 轮次 |
|---|---|:--:|--:|---|
| I-5 玩家 **base 8 帧** PNG | `godot/assets/generated/chars/player_*.png`（8 动作） | 8 | **70,598** | R21B（冻结最终态） |
| I-5 玩家 **decor 8 帧** PNG | `godot/assets/generated/decor/player_decor_*.png` | 8 | **11,505** | R21B（冻结最终态） |
| I-5 Boss **base 3 招** PNG | `godot/assets/generated/boss/boss_{dagger_slash,holy_hammer,staff_slam}.png` | 3 | **32,269** | R21B（冻结最终态） |
| I-5 Boss **decor 3 招** PNG | `godot/assets/generated/boss/boss_decor_*.png` | 3 | **16,379** | R21B（冻结最终态） |
| 四类 PNG 合表 spritesheet | `chars/player_spritesheet.png`、`decor/player_decor_spritesheet.png`、`boss/boss_spritesheet.png`、`boss/boss_decor_spritesheet.png` | 4 | **118,363** | R21B（冻结最终态） |
| SpriteFrames | `chars/player_spriteframes.tres`、`boss/boss_spriteframes.tres` | 2 | **3,129** | R21B（冻结最终态） |
| player / boss 角色场景 | `godot/scenes/player.tscn`、`godot/scenes/boss_01_margit.tscn` | 2 | **735** | R21B（冻结最终态） |
| courtyard 主场景 | `godot/scenes/courtyard.tscn`（`grep -c '^\[node '` 实测 **25 节点**） | 1 | **6,406** | R20B → R21B |
| hd2d_fx 光效 | `godot/scenes/hd2d_fx.tscn` + `godot/scripts/hd2d_fx.gd` | 2 | **20,917** | R16 → R18 → R21B |
| hud | `godot/scenes/hud.tscn` + `godot/scripts/hud.gd` | 2 | **24,468** | R16 → R19 → R21 → R21B |
| quality_settings | `godot/scenes/quality_settings.tscn` + `godot/scripts/quality_settings.gd` | 2 | **13,181** | R20 → R21 → R21B |
| save_delta_writer / 存档三件 | `godot/scripts/save_delta_writer.gd` + `scripts/rpg/world_state.gd` + `scripts/rpg/save_delta.gd` | 3 | **30,958** | R20 → R21 → **R22**（本单端到端真跑） |
| 产物 exe | `build/Aierdengfahuan.exe` | 1 | **109,127,680** | **R21B**（重导） |
| 产物 pck | `build/Aierdengfahuan.pck` | 1 | **993,736** | **R21B**（重导） |
| 产物 apk | `build/Aierdengfahuan.apk` | 1 | **29,239,499** | **R21B**（重导） |
| 产物 idsig | `build/Aierdengfahuan.apk.idsig` | 1 | **234,930** | **R21B**（重导） |

### 3.2 I-5 四类 PNG 逐文件字节数明细

| 类 | 文件（相对 `godot/assets/generated/`） | 字节 |
|---|---|--:|
| 玩家 base | `chars/player_attack_heavy.png` | 9,220 |
| 玩家 base | `chars/player_attack_light.png` | 5,190 |
| 玩家 base | `chars/player_death.png` | 5,425 |
| 玩家 base | `chars/player_hitstun.png` | 9,081 |
| 玩家 base | `chars/player_idle_rgba.png` | 15,019 |
| 玩家 base | `chars/player_roll.png` | 8,044 |
| 玩家 base | `chars/player_run.png` | 11,115 |
| 玩家 base | `chars/player_walk.png` | 7,504 |
| 玩家 base 变体 | `chars/player_idle_single.png`（idle 另一变体，不计入 8 动作） | 8,345 |
| 玩家 decor | `decor/player_decor_attack_heavy.png` | 1,037 |
| 玩家 decor | `decor/player_decor_attack_light.png` | 1,324 |
| 玩家 decor | `decor/player_decor_death.png` | 1,691 |
| 玩家 decor | `decor/player_decor_hitstun.png` | 339 |
| 玩家 decor | `decor/player_decor_idle.png` | 1,414 |
| 玩家 decor | `decor/player_decor_roll.png` | 1,863 |
| 玩家 decor | `decor/player_decor_run.png` | 2,015 |
| 玩家 decor | `decor/player_decor_walk.png` | 1,822 |
| Boss base | `boss/boss_dagger_slash.png` | 12,672 |
| Boss base | `boss/boss_holy_hammer.png` | 10,352 |
| Boss base | `boss/boss_staff_slam.png` | 9,245 |
| Boss decor | `boss/boss_decor_dagger_slash.png` | 6,485 |
| Boss decor | `boss/boss_decor_holy_hammer.png` | 3,314 |
| Boss decor | `boss/boss_decor_staff_slam.png` | 6,580 |

### 3.3 场景 / 脚本 / 产物逐文件字节数明细

| 文件（相对工程根） | 字节 |
|---|--:|
| `godot/assets/generated/chars/player_spriteframes.tres` | 2,183 |
| `godot/assets/generated/boss/boss_spriteframes.tres` | 946 |
| `godot/assets/generated/chars/player_spritesheet.png` | 59,147 |
| `godot/assets/generated/decor/player_decor_spritesheet.png` | 11,086 |
| `godot/assets/generated/boss/boss_spritesheet.png` | 31,250 |
| `godot/assets/generated/boss/boss_decor_spritesheet.png` | 16,880 |
| `godot/scenes/player.tscn` | 360 |
| `godot/scenes/boss_01_margit.tscn` | 375 |
| `godot/scenes/courtyard.tscn` | 6,406 |
| `godot/scenes/hd2d_fx.tscn` | 1,031 |
| `godot/scenes/hud.tscn` | 914 |
| `godot/scenes/quality_settings.tscn` | 2,309 |
| `godot/scripts/hd2d_fx.gd` | 19,886 |
| `godot/scripts/hud.gd` | 23,554 |
| `godot/scripts/quality_settings.gd` | 10,872 |
| `godot/scripts/save_delta_writer.gd` | 4,378 |
| `godot/scripts/rpg/world_state.gd` | 15,353 |
| `godot/scripts/rpg/save_delta.gd` | 11,227 |
| `build/Aierdengfahuan.exe` | 109,127,680 |
| `build/Aierdengfahuan.pck` | 993,736 |
| `build/Aierdengfahuan.apk` | 29,239,499 |
| `build/Aierdengfahuan.apk.idsig` | 234,930 |

> 核算：玩家 base 8 动作 = 70,598 B；decor 8 帧 = 11,505 B；Boss base 3 招 = 32,269 B；Boss decor 3 招 = 16,379 B；
> 四张合表 = 59,147 + 11,086 + 31,250 + 16,880 = **118,363 B**；SpriteFrames = 2,183 + 946 = **3,129 B**；
> 角色场景 = 360 + 375 = **735 B**；hd2d_fx = 1,031 + 19,886 = **20,917 B**；hud = 914 + 23,554 = **24,468 B**；
> quality_settings = 2,309 + 10,872 = **13,181 B**；存档三件 = 4,378 + 15,353 + 11,227 = **30,958 B**。
> `player_spriteframes.tres` 实测注册 **8 个动作**（attack_heavy / attack_light / death / hitstun / idle / roll / run / walk），与「玩家 base 8 帧」口径吻合；
> `boss_spriteframes.tres` 对应 3 招。`courtyard.tscn` 的 25 节点为 `grep -c '^\[node '` 实测值。

---

### 3.4 R23 素材条目与本机可选素材源合规登记（2026-11-09 · 口径 / 合规登记，非落盘产物）

> 本小节为**规格口径与合规边界登记**，不代表本轮新增任何落盘素材文件：`godot/assets/generated/r23/` 归 Rank-4 所有，本轮未写、未生成 PNG、`stat` 实测字节数不适用。
> 依据：用户 R23 拍板口径「`128bit` + 256 色以上」与 DNF 合规边界；`teamwork/00-协作契约.md` §9.3（I-5 资产交付口径真源）、`teamwork/Rank-3/DNF-COMPLIANCE-R23.md`。

| 条目 | 来源 / 规格 | 落盘状态 | published_in_pck | 备注 |
|---|---|---|:--:|---|
| **R23 素材条目** | **本地 ComfyUI 自制**（零付费 / 零外部服务）｜**128px 基准画布**｜**≥256 色（256 色以上）**｜**RGBA / alpha 保留** | 口径登记，本轮未新增落盘素材 | **false** | `128bit` 词义歧义（128px 画布 / 位宽 / 色深）显式保留待用户确认；正式素材路线仍为本地 ComfyUI |
| **本机可选素材源：DNF NPK 仅参考** | DNF（`Neople` / 腾讯版权）NPK / 贴片，**仅本机开发期风格参考** | 参考目录，**不进工程素材链** | **false** | 参考目录以 `.gdignore` 标记，Godot 不扫描 / 不导入 / 不打包；不随仓库分发可识别商业贴片；不得进 `pck` / `exe` / `apk` |

**合规口径（`published_in_pck:false` 全覆盖）**：

- 上表两项均 **`published_in_pck: false`** —— 既不进 `.pck`，也不进 `.exe` / `.apk` 任何发布包；R23 素材条目是规格口径而非已发布资产，DNF NPK 是本机参考而非工程素材。
- **参考目录 `.gdignore`**：DNF 参考目录须以 `.gdignore` 标记，使 Godot 4.7.2 跳过该目录的文件系统扫描与资源导入，从机制上保证不被打进发布包；本轮不改素材目录，仅登记该约定（`.gdignore` 由素材目录所有方 Rank-4 按需落地）。
- 版权归 `Neople` / 腾讯；完整合规登记见 `teamwork/Rank-3/DNF-COMPLIANCE-R23.md`。
