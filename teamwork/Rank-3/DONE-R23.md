# DONE-R23.md · Rank-3 交付报告（R23 · 契约口径与 README 合规登记）

- 任务：`cmd-20261109-133602-490-A3`，`[ROUND=R23]`，Rank-3 执行 AI（RPG / 世界 / 存档）
- 日期：2026-11-09
- 任务单：`teamwork/Rank-3/调度任务单-latest.json`（开工只读，已读 ✓）
- 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，实测 `--version` = `4.7.2.stable.official.ed1daf0bf`（`G0_EXIT=0`）
- 工程根（`--path`）：`F:/Game/aierdengfahuan/godot`

> **真跑结论（总览，均为实际 stdout）**：
> ① 用户 R23 拍板口径「`128bit` + 256 色以上」与 DNF 合规边界已落到文档真源：契约 §9.3（I-5 资产交付口径真源）、汇总 §6.2 第 5 行、README §3.4、`teamwork/Rank-3/DNF-COMPLIANCE-R23.md`。
> ② **R21/R22 的 31 PASS / 0 FAIL**（`r19_verify_hud.gd` 20 + `verify_hud_binding.gd` 11）R23 重跑**不回退**；R22 存档端到端 `r22_save_e2e.gd`（write 7 + read 9 = **16 PASS / 0 FAIL**）两独立进程 pid=20120 / 32552 真跑通过。
> ③ 三段门禁 G1 `--headless --import` / G2 `--check-only --script` ×4 / G3 `--headless --quit` 全 `EXIT=0`；11 份 `R23-*.log` 逐份 `grep SCRIPT ERROR / Parse Error / ERROR` **全为 0**。
> ④ 本轮**未新建任何验证脚本 / 只读探针 / 巡检脚本**，复用既有 `r19_verify_hud.gd` / `verify_hud_binding.gd` / `r22_save_e2e.gd`；只写 `00-协作契约.md` / `00-汇总.md §6.2` / `README.md` / `teamwork/Rank-3/`（+ 回执例外）。

---

## ① 实际交付清单（本轮真正写入的文件与段落）

| # | 文件 | 动作 | 改动段落 |
|---|------|------|------|
| 1 | `teamwork/00-协作契约.md` | **修改** | **仅 §9.3 美术素材规格**（原 120–126 行 → 现 120–132 行）；§3 跨模块接口表与 §1~§8 / §9.1 / §9.2 / §10 等其它历史条款**零写入** |
| 2 | `teamwork/00-汇总.md` | **修改** | **仅 §6.2 表格第 5 行**（`128bit` 歧义待确认项，现 113 行）；§1~§5 / §6.1 / §6.2 其余 7 行 / §7 及文末按「不改动其它历史条款」**零写入** |
| 3 | `F:/Game/aierdengfahuan/README.md` | **修改** | ① 顶部说明追加 1 行 R23 更新记录（现第 8 行）；② 文末**新增 §3.4**「R23 素材条目与本机可选素材源合规登记」（现 162–176 行）。§3.1~§3.3 既有 `stat` 实测表与历史结论**未改** |
| 4 | `teamwork/Rank-3/DNF-COMPLIANCE-R23.md` | **新建** | 合规登记全文（版权 / 仅本机参考 / 不进发布包 / 不随仓库分发 / 与既有保守口径关系） |
| 5 | `teamwork/Rank-3/R23-*.log`（11 份） | **新建 · 运行输出留档** | `R23-G0-version` / `G1-import` / `G2a-writer` / `G2b-hud` / `G2c-r19` / `G2d-e2e` / `G3-quit` / `RUN-r19` / `RUN-r17` / `E2E-write` / `E2E-read`，均为实际 stdout，非工程源文件、非脚本 |
| 6 | `teamwork/Rank-3/DONE-R23.md` | **新建** | 本报告 |
| 7 | `teamwork/command_center/ai/3/outbox/cmd-20261109-133602-490-A3.json` | **新建** | 回执 JSON，写在 `teamwork/command_center/` 下的精确路径（**未**写到工程根 `command_center/`） |

### 1.1 契约 §9.3 改动对照（I-5 口径真源）

| 项 | R23 前（旧） | R23 后（用户拍板口径） |
|---|---|---|
| 定位 | 无 I-5 关联标注 | 标题加「**I-5 资产交付口径真源**」，导语显式绑定跨模块接口 I-5（4 → 1）`assets/generated/<品类>/` |
| 色数 | 全项目共用一份 **≤256 色**索引调色板（上限） | **256 色以上（≥256 色）**，由上限**放宽为下限**，不再以 256 色封顶 |
| 画布 | 128px 基准画布 + 256 色索引调色板 | **128px 基准画布不变**（逐帧 128×128 / 脚贴地保持） |
| RGBA / alpha | 未在 §9.3 单列 | **显式保留**：RGBA + 透明通道；装饰层逐像素对齐 / 非装饰区全透明规范不变 |
| `128bit` | 待用户确认，落地暂按 128px 理解 | **歧义显式保留、待用户确认**（128px 画布 / 位宽 / 色深），**不消歧、不自行改口径、以用户为准** |
| 零付费 | 本地 ComfyUI / 零付费 / 零外部服务 | **不变**，并显式补「不引入任何付费素材或付费素材生成服务」 |
| DNF 资源 | 无 | **新增**：DNF（Neople / 腾讯版权）NPK / 贴片**仅本机开发期风格参考**，**不得进 `pck` / `exe` / `apk`**，不得随仓库分发可识别商业贴片；正式素材仍只走本地 ComfyUI |
| 落点 | 4 号 `import.json` / 视觉规范 / 1 号导入设置 | **逐字保留不变** |

> **关于「I-5 规格」落点的如实说明**：契约 §3 的 I-5 表格行是「跨模块接口（先对齐，不得私改）」的**接口方向定义**（4 → 1 交付 spritesheet + `import.json`），本身**不含**「≤256 色 / 128px / `128bit`」任何字段；这些字段全部集中在 §9.3。故本轮按「只改相关段落，不改动其它历史条款」**只改 §9.3**，并在 §9.3 显式建立 I-5 ↔ 资产规格的关联，未私改 §3 接口表。若总指挥要求连 §3 I-5 行一并补注规格，需另行授权。

### 1.2 汇总 §6.2 第 5 行改动对照

| 列 | R23 前 | R23 后 |
|---|---|---|
| 项 | `128bit` 歧义 | `128bit` 歧义（**R23 用户拍板口径**） |
| 现状 | 暂按 128px 理解 | 用户本轮口径「`128bit` + 256 色以上」：色数由 ≤256 **放宽为 256 色以上（≥256 色）** 下限、**128px 基准画布不变**、RGBA/alpha 保留、零付费；`128bit` 词义歧义**显式保留、不消歧、以用户为准**；契约 §9.3 已同步，DNF 资源仅本机参考、不进发布包 |
| 需要 | 用户确认是尺寸还是位宽 | 用户确认 `128bit` 指尺寸还是位宽 / 色深；A8 裁决表与 §6.2 第 8 行 R22 遗留快照按「不改动其它历史条款」保留原样 |

### 1.3 README 资产表新增内容

- 顶部说明：追加 `R23 · cmd-20261109-133602-490-A3（Rank-3）` 更新记录，声明 §3.1~§3.3 既有实测值未改。
- **新增 §3.4**（资产表新增部分，明确标注「口径 / 合规登记，**非落盘产物**」）：
  - **R23 素材条目**：来源 **本地 ComfyUI 自制** / **128px 基准画布** / **≥256 色（256 色以上）** / **RGBA / alpha 保留** / 零付费；`published_in_pck: **false**`；`128bit` 歧义保留待用户确认。
  - **本机可选素材源：DNF NPK 仅参考**：DNF（Neople / 腾讯版权）**仅本机开发期风格参考**、不进工程素材链；`published_in_pck: **false**`；**参考目录 `.gdignore`** 标记（Godot 不扫描 / 不导入 / 不打包）；不随仓库分发可识别商业贴片；不得进 `pck` / `exe` / `apk`。
  - 合规口径段：`published_in_pck:false` 全覆盖、`.gdignore` 机制说明、版权归属与合规登记指向。
- **如实边界**：本轮**未新增任何落盘素材文件**，`godot/assets/generated/r23/` 归 Rank-4 所有、本轮未写未生成 PNG；§3.4 不编造 `stat` 字节数。

### 1.4 可写范围 / 硬约束核对

- ✅ 只写：`00-协作契约.md`、`00-汇总.md`（仅 §6.2 第 5 行）、`README.md`、`teamwork/Rank-3/`、回执例外 `teamwork/command_center/ai/3/outbox/`。
- ✅ **绝对未碰**：`courtyard.tscn`、`project.godot`、`godot/assets/generated/**`（素材目录）、`godot/scripts/**`（既有工程文件，验证脚本只读复用）、其它 Rank 文档、`build/` 产物、其它 Rank 目录。
- ✅ 未新建只读探针 / 巡检脚本；未主动扫目录做进度巡检（仅对任务单指定的验证脚本、引擎、outbox 做定向存在性核对）；未自行 `git`；零付费、未引入付费素材生成服务。

---

## ② 真跑输出结论（实际 stdout，未删改、未补写）

### 2.1 命令清单（引擎 `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--path F:/Game/aierdengfahuan/godot`）

| 段 | 命令标志 | 日志 |
|----|----|----|
| G0 | `--version` | `R23-G0-version.log` |
| G1 门禁 | `--headless --import` | `R23-G1-import.log` |
| G2a | `--headless --check-only --script res://scripts/save_delta_writer.gd` | `R23-G2a-writer.log` |
| G2b | `--headless --check-only --script res://scripts/hud.gd` | `R23-G2b-hud.log` |
| G2c | `--headless --check-only --script <abs>/r19_verify_hud.gd` | `R23-G2c-r19.log` |
| G2d | `--headless --check-only --script <abs>/r22_save_e2e.gd` | `R23-G2d-e2e.log` |
| G3 门禁 | `--headless --quit` | `R23-G3-quit.log` |
| 回归 A | `--headless --script <abs>/r19_verify_hud.gd` | `R23-RUN-r19.log` |
| 回归 B | `--headless --script res://scripts/verify_hud_binding.gd` | `R23-RUN-r17.log` |
| E2E 写盘 | `E2E_PHASE=write ... --script <abs>/r22_save_e2e.gd` | `R23-E2E-write.log` |
| E2E 读回 | `E2E_PHASE=read  ... --script <abs>/r22_save_e2e.gd` | `R23-E2E-read.log` |

> `<abs>` = `F:/Game/aierdengfahuan/teamwork/Rank-3/`。执行顺序按 R22 既有经验：回归脚本的 autoload commit 会改写 `user://` 存档的 `meta.last_commit_reason`，故 **E2E 两阶段排在回归之后**重放，使最终磁盘态与 E2E 结论一致（`R⑥` 复核 `meta.last_commit_reason=r22_e2e_write` 成立）。

### 2.2 退出码（11 次引擎调用全部 `EXIT=0`）

```
G0_EXIT=0  G1_EXIT=0  G2a_EXIT=0  G2b_EXIT=0  G2c_EXIT=0  G2d_EXIT=0  G3_EXIT=0
R19_EXIT=0  R17_EXIT=0  E2E_WRITE_EXIT=0  E2E_READ_EXIT=0
```

### 2.3 PASS / FAIL 数字（实际 SUMMARY 行）

```
[R19] SUMMARY pass=20 fail=0 ok=true
[R17] SUMMARY mode=AUTOLOAD_OK degraded=false flag_chain_verified=true pass=11 fail=0 ok=true
[R22] SUMMARY phase=write pid=20120 pass=7 fail=0 ok=true
[R22] SUMMARY phase=read  pid=32552 pass=9 fail=0 ok=true
```

| 项 | 数值 | 说明 |
|---|---|---|
| R21 HUD / 存档回归 | **20 PASS / 0 FAIL** | `r19_verify_hud.gd`，①~⑳ 含两入口 autoload 优先级 / commit 顺序 / 8 节点 7 边 / R17 flag 增量 |
| R17 HUD 绑定回归 | **11 PASS / 0 FAIL** | `verify_hud_binding.gd`，`degraded=false`、`flag_chain_verified=true` |
| **R21 合计（任务单 ④ 的 31 PASS）** | **31 PASS / 0 FAIL** | 20 + 11，R23 重跑**不回退** |
| R22 存档端到端 write | **7 PASS / 0 FAIL** | `pid=20120`，真实原子写 `slot_01/delta.json`（932 B），十字段 / `schema_version=3` / 5 个三段式 flag |
| R22 存档端到端 read | **9 PASS / 0 FAIL** | `pid=32552`，**另一个独立引擎进程**，`_load()` 回放后 `get_flag` 逐项读回 **5/5** 一致 |
| **R22 端到端合计** | **16 PASS / 0 FAIL** | 两进程 pid 不同 = 真重启，非同进程内存往返 |

> 两个 E2E 进程 pid（20120 / 32552）**不同**，`R②` 证明新进程 `_load()` 前内存为基线（未读档），`R⑥` 证明 `meta.last_commit_reason=r22_e2e_write` 跨进程一致，十字段 / `schema_version=3` / 单槽 `slot_01` / 三段式 flag 全部成立。

### 2.4 三段门禁 `grep SCRIPT ERROR=0`

| 段 | 标志 | `SCRIPT ERROR` | `Parse Error` | `ERROR` | `EXIT` |
|----|----|:--:|:--:|:--:|:--:|
| G1 | `--headless --import` | 0 | 0 | 0 | 0 |
| G2a | `--check-only --script` writer | 0 | 0 | 0 | 0 |
| G2b | `--check-only --script` hud | 0 | 0 | 0 | 0 |
| G2c | `--check-only --script` r19 | 0 | 0 | 0 | 0 |
| G2d | `--check-only --script` r22_e2e | 0 | 0 | 0 | 0 |
| G3 | `--headless --quit` | 0 | 0 | 0 | 0 |

> **11 份 `R23-*.log` 逐份 `grep`：`SCRIPT_ERROR=0 PARSE_ERROR=0 ERROR_LINES=0` 全为 0**；三段门禁 `grep SCRIPT ERROR=0` 达成。
> 退出残留仍是工程既有 WARNING（`[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked at exit`），**非 ERROR、未隐藏、未宣称零 WARNING**（`R23-G3-quit.log` / `R23-E2E-*.log` 可复核）。

---

## ③ 合规声明

- **版权**：DNF（Dungeon & Fighter）资源著作权及相关权利归 **Neople** / **腾讯**；本项目为同人 / 非商业 Godot 学习工程，不主张权利、不声称获授权、不授予任何许可。
- **使用范围**：DNF NPK / 贴片**仅本机开发期风格参考**（目视比对风格 / 配色 / 像素密度 / 动作节奏），不拷贝、不抠图、不描摹、不转绘为项目素材，不进 `godot/assets/generated/**` 与 `res://` 资源树。
- **发布边界**：`published_in_pck: false` 全覆盖；**不得进 `pck` / `exe` / `apk`**（含 aab）任何发布包；**不随仓库分发可识别商业贴片**（git / Release 附件 / 对外物料）。
- **机制保证**：DNF 参考目录以 **`.gdignore`** 标记，Godot 4.7.2 跳过该目录扫描与资源导入；本轮禁写素材目录，**仅登记该约定**，未实际落地 `.gdignore` 文件（见 ④）。
- **与既有保守口径的关系**：是**收窄隔离带、不是放宽**。零付费 / 零外部服务（§5）、本地 ComfyUI 主美术路线（§9.3）、`_draw()` 非正式路线、`128bit` 不自行消歧、RGBA/alpha 保留、不扫目录不建探针 —— **一条未松**；唯一实质变更是用户拍板的色数由 ≤256 放宽为 256 色以上下限。
- **零付费**：未引入任何付费素材 / 付费素材生成服务；真跑纯本地 Godot 4.7.2，一次一段、无 GPU job。

---

## ④ 未完成项与阻塞

**阻塞：无功能性阻塞。** 派单 5 项（① 契约 §9.3 + 汇总 §6.2、② README 资产表新增、③ DNF 合规登记、④ 31 PASS 不回退 + 三段门禁、⑤ 只写指定文件）均真实达成。

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | `128bit` 词义（128px 画布 / 位宽 / 色深） | **待用户确认 · 显式保留** | 按用户 R23 口径不消歧、不自行改口径；契约 §9.3 / 汇总 §6.2 第 5 行 / README §3.4 均已登记 |
| 2 | 汇总 §4 裁决表 A8 与 §6.2 第 8 行 R22 遗留快照中的 `128bit` 旧措辞 | **按契约保留原样** | 任务单限定「只改 §6.2 的待确认项、不改动其它历史条款」；A8「暂按 128px 基准画布 + 256 色索引调色板理解」与第 8 行「`128bit` 待用户输入」属历史裁决 / 遗留快照，未同步改写。若需全文口径一致，请总指挥另行授权 |
| 3 | `.gdignore` 在 DNF 参考目录实际落地 | **仅登记约定 · 未落盘** | 任务单禁改素材目录；`.gdignore` 由素材目录所有方 Rank-4 按需落地，本轮只在 README §3.4 / 合规登记写明机制 |
| 4 | R23 素材实体 PNG | **未产出 · 不冒充** | `godot/assets/generated/r23/` 归 Rank-4；本轮只做口径与合规登记，README §3.4 明确标注「非落盘产物」、不编造字节数 |
| 5 | §3 跨模块接口表 I-5 行补注规格 | **未做 · 需授权** | 见 ① 1.1；该表「先对齐，不得私改」且不含色数字段，按「不改动其它历史条款」未动 |
| 6 | exe / pck / apk 重导 | **不在本轮** | 本轮未写任何 `godot/` 工程文件，工程未变更，产物无需重导；既有产物为 R21B 态 |
| 7 | 既有退出 WARNING | **如实保留 · 非 ERROR** | `[ChunkManager] 未找到 ChunkRoot`、`2 ObjectDB instances were leaked`，历轮已登记，R23 真跑中仍出现 |
| 8 | 赐福菜单 UI 画面 / 运行期人工试玩 / HD-2D 全绿 | 长期项 · 不阻塞 | 历轮一贯口径，不在本单范围 |

---

## ⑤ 约束对照

直接改、直接真跑 ✓（未新建任何只读探针 / 巡检脚本，复用既有 3 份验证载体）；只写 `00-协作契约.md` / `00-汇总.md §6.2` / `README.md` / `teamwork/Rank-3/`（+ 回执例外）✓；不主动扫目录做进度巡检 ✓（仅定向存在性核对）；零付费、不引入付费素材生成服务 ✓；不伪造产物（R23 素材不冒充落盘、`.gdignore` 不冒充已落地）✓；不谎报成功（A8 / 第 8 行旧措辞、§3 I-5 表未动、既有 WARNING 均如实登记）✓；目录所有权 ✓（未碰 `courtyard.tscn` / `project.godot` / 素材目录 / 其它 Rank 文档）；三段门禁 `grep SCRIPT ERROR=0` ✓；中文 UTF-8 ✓；不自行 `git` 提交 ✓（由总指挥收尾）。

---

## ⑥ 回执（含实测）

按本轮 `task_id` 写 `F:/Game/aierdengfahuan/teamwork/command_center/ai/3/outbox/cmd-20261109-133602-490-A3.json`（在 `teamwork/command_center/` 下，**未**写到工程根 `command_center/`）：

```json
{"task_id":"cmd-20261109-133602-490-A3","ai":3,"status":"done","result":"引用 DONE-R23.md 实际结论：① 契约 §9.3（I-5 资产交付口径真源）按用户 R23 拍板改：色数 ≤256 放宽为 256 色以上（≥256 色）、128px 基准画布不变、128bit 歧义显式保留待用户确认、RGBA/alpha 保留、零付费、DNF NPK 仅本机开发参考且不得进 pck/exe/apk；汇总 §6.2 第 5 行待确认项同步。② README 资产表新增 §3.4：R23 素材条目（ComfyUI 本地 / 128px / ≥256 色）+「本机可选素材源：DNF NPK 仅参考」，published_in_pck:false、参考目录 .gdignore。③ teamwork/Rank-3/DNF-COMPLIANCE-R23.md 合规登记（版权 Neople/腾讯、仅本机、不进发布包、不随仓库分发可识别商业贴片、与既有保守口径为收窄隔离非放宽）。④ 真跑：R21/R22 的 31 PASS/0 FAIL（r19 20 + r17 11）不回退，R22 存档端到端 16 PASS/0 FAIL（write 7 pid=20120 + read 9 pid=32552，两独立进程）；三段门禁 G1 --import / G2 --check-only ×4 / G3 --quit 全 EXIT=0，11 份 R23-*.log grep SCRIPT ERROR/Parse Error/ERROR 全 0。⑤ 未新建探针/巡检脚本、零付费、不自行 git；未完成项：128bit 词义待用户确认、A8 与 §6.2 第 8 行历史措辞按契约保留、.gdignore 与 R23 素材实体未落盘（归 Rank-4 / 禁写素材目录）。"}
```

**实测（本轮）**：写入成功后 `outbox/` 被中枢实时消费清空（目录 mtime `13:49`、当前 0 文件），归档件
`teamwork/command_center/dispatcher/receipts/cmd-20261109-133602-490-A3.json`（**1380 字节**）读回校验：
`json_valid=True`、`task_id=cmd-20261109-133602-490-A3` / `ai=3` / `status=done`、
`result_len=748`、`keys=['ai','result','status','task_id']`、`result` 以「引用 DONE-R23.md 实际结论：」开头；
工程根 `command_center/` 不存在（未误写）。按幂等 / 并发保护**不重复写第二份回执**，与 `DONE-R21.md §⑤` /
`DONE-R22.md §⑤` 同一消费时序现象，如实登记，未隐藏首次核对 `outbox/` 时的 `FileNotFoundError`。

> 结论：回执路径**正确**（`teamwork/command_center/ai/3/outbox/` 下的精确 id 文件，且已被中枢按该 id 归档）；内容符合任务单要求的 `{"task_id":...,"ai":3,"status":"done","result":"引用 DONE-R23.md 实际结论"}` 结构。
