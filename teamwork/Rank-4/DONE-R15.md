# DONE-R15.md · Rank-4 完成报告（R15 · HD-2D 光效程序化 CanvasLayer 近似方案）

> 轮次：**R15**｜派单：`cmd-20261109-083628-786-A4`｜命令：`[ROUND=R15]`｜工位：Rank-4 美术管线与工具链｜日期：2026-11-09
> 状态：**done**（①交付清单 ②自检 ③未完成项与阻塞齐备）
> 必读已读（5 件，逐件全文）：`capture/CAPTURE-REPORT.md`、`teamwork/Rank-4/ART-SPEC-FINAL.md`、`godot/scripts/render/hd2d_placeholder.gd`、`teamwork/Rank-1/DONE-R14.md`（glow 因 `gl_compatibility` 不支持未做）、`teamwork/00-群聊总线.md`（**开工只读一次**）。
> 只读引用（未改）：`godot/scenes/courtyard.tscn`（只读核对节点 / layer，本工位零写入）、`teamwork/Rank-4/HD-2D视觉规范.md` §3 / §7 / §10、`scene_integration.md`、`hd2d_placeholder_attach.gd`、`attach_hd2d_placeholder.gd`、`godot/scripts/core/render_profiles.gd`、`godot/data/render/render_profiles.tres`、`quality_preset_desktop.tres` / `quality_preset_mobile.tres`、`godot/project.godot`、`Rank-4/调度任务单-latest.json`、`command_center/dispatcher/receipts/cmd-20261109-082141-612-A4.json`（回执格式样例）、`Rank-4/DONE-R14.md`（本工位上轮报告）。
> **定位：只交付方案，未实现**（未写 `.gd`、未改 `courtyard.tscn`、未真跑、未抓帧、未验收画面）。

---

## 0. 一句话结论

在 `gl_compatibility` 后端不支持 `Environment` glow / 3D 体积雾 / SSR 的前提下，产出 `HD2D-FX-PLAN.md`：把体积光 / 光尘 / 湿地倒影 / bloom 四项外提为 SubViewport 内 `FXLayer(layer=10)` 一侧的独立 2D CanvasLayer 栈（`FXReflection=1` / `FXGodRays=2` / 既有 `FXLayer=10` / `FXBloom=11` / `FXModulate=12`），逐项给出 Godot 原语、关键参数、叠加顺序与 layer 值，说明与 `HD2DPlaceholderLayer(layer=-10)` 的五条关系，并直接引用既有冻结双档 `quality_preset_*.tres` / `render_profiles.tres` 的「桌面四项全开 / 移动四项全关」作为性能预算答案、附「移动档降级而非全关」待裁决建议。**本轮只交付方案，未实现、未真跑、未验收画面；`status=done` 指方案交付闭环，非画面已达标。**

---

## 1. ① 交付清单

| # | 文件 | 落位 | 字节数 | 说明 |
|---|---|---|---|---|
| 1 | `HD2D-FX-PLAN.md` | `teamwork/Rank-4/` | **25437** | 主交付方案件：四项 FX 各原语 / 关键参数 / 叠加顺序 / layer 值 / 与占位层关系 / 双档性能预算 / 落地步骤 / 边界登记；sha256 前缀 `fe22d2689f5d767f`，UTF-8 通过（§2.3） |
| 2 | `DONE-R15.md` | `teamwork/Rank-4/` | 见文件 | 本文件（①交付清单 ②自检 ③未完成项与阻塞，明确「只交付方案未实现」） |
| 3 | `cmd-20261109-083628-786-A4.json` | `teamwork/command_center/ai/4/outbox/`（中枢实时消费后见 `dispatcher/receipts/`） | **2179** | 回执 JSON，`result` 引用本报告实际结论；sha256 前缀 `8154cb68211ed7a9`，UTF-8 通过（§2.2 / §2.3） |

> 可写范围核对：以上 3 处即本轮全部写入，均在派单授权范围内（工位 `Rank-4/` + 回执例外 `command_center/ai/4/outbox/`）。未写任何 `.gd` / `.tres` / `.import` / `.tscn` / 其它工位 / 总线 / 总纲 / 契约 / 任务书。

---

## 2. ② 自检

### 2.1 派单要求逐项对照

| 派单要求 | 落在方案何处 | 结论 |
|---|---|---|
| 体积光：原语 / 参数 / 叠加 / layer | §3.1（`Polygon2D`×4 + `Line2D`；spread 40/86/132/178、alpha 0.18/0.12/0.07/0.04、samples 48 / density 0.75 / decay 0.95 / weight 0.40 / exposure 0.32）、§2.1（layer=2） | 通过 |
| 光尘：原语 / 参数 / 叠加 / layer | §3.2（`Node2D._draw()`+`draw_circle()`；48 远景冷白 + 32 近景暖金、seed 20261108、2~6 px/s、横摆 ±3 px）、§2.1（layer=10，复用 `LightDust`） | 通过 |
| 湿地倒影：原语 / 参数 / 叠加 / layer | §3.3（`_draw()`+`draw_rect()` 镜像；压缩 0.70 / alpha 0.35 / 波纹 0.03）、§2.1（layer=1） | 通过 |
| bloom：原语 / 参数 / 叠加 / layer | §3.4（同心圆半径 4/8/14/22/32 或 `TextureRect`+`GradientTexture2D`；threshold≈0.95、intensity 0.50、仅 `warm_gold_key` 过阈）、§2.1（layer=11） | 通过 |
| 叠加顺序 | §2.1 总表（主树 -10→0→UI；SubViewport 3D→1→2→10→11→12），对齐 `HD-2D视觉规范.md` §10 层序 | 通过 |
| layer 值 | §2.1（新增 1 / 2 / 11 / 12；既有 `HD2DPlaceholderLayer=-10`、`FXLayer=10` 冻结保留） | 通过 |
| 与 `HD2DPlaceholderLayer(layer=-10)` 的关系 | §2.2 五条（数值不冲突 / 本轮零改动 / 参照基线 / 功能互补 / 退出独立） | 通过 |
| 性能预算：桌面 / 移动各开关哪项 | §4.2 冻结口径（桌面四项全开、移动四项全关）+ §4.3 逐项开销与降级建议 + §4.4 分档落地 | 通过 |
| 只给方案、不改运行中脚本、不碰 `courtyard.tscn` | §7 合规声明 + 本文件 §2.4 禁区只读核对 | 通过 |
| 原语覆盖派单点名项 | `_draw()`（光尘 / 倒影 / bloom A）、`Line2D` / `Polygon2D`（体积光）、`ColorRect` 渐变（§3.4 B + §3.6 如实说明须 `TextureRect`+`GradientTexture2D` 或 shader）、`CanvasModulate`（§3.5） | 通过 |

### 2.2 回执 JSON 真跑校验（容错：中枢实时消费）

写入 `command_center/ai/4/outbox/cmd-20261109-083628-786-A4.json` 后被中枢进程**实时消费**，移入 `dispatcher/receipts/cmd-20261109-083628-786-A4.json`。按「outbox 在则校验 outbox，否则校验中枢保存的同一份」容错校验，实际 stdout：

```text
=== 回执 JSON 容错校验（中枢实时消费）===
outbox_exists  = False
receipts_exists= True
validated_path = F:/Game/aierdengfahuan/teamwork/command_center/dispatcher/receipts/cmd-20261109-083628-786-A4.json
json_load_ok   = True
keys           = ['ai', 'result', 'status', 'task_id']
task_id        = cmd-20261109-083628-786-A4
ai / status    = 4 / done
result_chars   = 1311
task_id_match  = True
ai_match       = True
status_done    = True
result_ref_done=  True
result_onlyplan=  True
```

> 结论：回执**已写入 outbox 且已被中枢接收**（receipts 中文件即回执本体，`json.load` 通过、四字段齐备、`task_id` 正确、`ai=4` / `status=done`、`result` 引用 `DONE-R15.md` 实际结论且含「只交付方案 / 未实现」）。`outbox_exists=False` 是中枢消费行为，**不是未写、不是失败**；如实登记，不伪造「outbox 常驻」（与 `DONE-R14.md` §2.6 同一既有正常流程）。

### 2.3 交付文件 UTF-8 / 字节数真跑核对

```text
=== 交付文件 UTF-8 / 字节数 ===
HD2D-FX-PLAN.md bytes = 25437 utf8_ok = True sha256[:16] = fe22d2689f5d767f
cmd-20261109-083628-786-A4.json bytes = 2179 utf8_ok = True sha256[:16] = 8154cb68211ed7a9
```

> 主交付件与回执均 `utf8_ok=True`、中文 UTF-8。`DONE-R15.md`（本文件）在交付后最终复核中一并验 UTF-8；本文件交付清单按历轮惯例写「见文件」，不臆造字节数。文档内**不含行首 ```json 围栏**（回执是独立 `.json` 文件），与 `ART-SPEC-FINAL.md` §5 一贯口径自洽。

### 2.4 禁区只读核对（本工位零写入）

```text
=== 禁区只读核对（本工位零写入，仅登记当前磁盘状态）===
hd2d_placeholder.gd bytes = 14670 mtime = 2026-11-09 02:33:38 sha256[:16] = b377f40103cd0ac6
courtyard.tscn bytes = 5230 mtime = 2026-11-09 08:28:32 sha256[:16] = d70ae5b76992a5f3
00-群聊总线.md bytes = 32813 mtime = 2026-11-09 07:37:02 sha256[:16] = 890fecb05443a387
```

- `hd2d_placeholder.gd` mtime `02:33:38`、`courtyard.tscn` mtime `08:28:32`、`00-群聊总线.md` mtime `07:37:02` **均早于本轮派单 `08:36:29`**，佐证本工位对三者**零写入**（全程仅 `Read` / `Grep` 只读）。
- `courtyard.tscn` sha256 前缀 `d70ae5b76992a5f3` 与 `Rank-1/DONE-R14.md` §2.3 登记的改造后值 `d70ae5b7…` 一致，说明自 R14 起该场景未被改动；本轮 Rank-1 独占、本工位不碰，如实登记。
- `00-群聊总线.md` 开工只读一次、未追加（本轮无接口变更 / 里程碑交付 / 阻塞求助 / 回应 @ 四类事件，且总线不在可写范围）。

### 2.5 硬性约束逐项对照

| 约束 | 本轮实际 | 结论 |
|---|---|---|
| 只给方案、不改运行中脚本 | `hd2d_placeholder.gd` 零写入（§2.4 mtime 早于派单） | 通过 |
| 不碰 `godot/scenes/courtyard.tscn`（Rank-1 本轮独占） | 仅只读核对节点 / layer，零写入 | 通过 |
| 默认不刺探 | 只读必读 5 件 + 任务直接相关的场景 / 双档件 / 回执样例；未做进度巡检、未写探针 | 通过 |
| 零付费 / 零外部素材 | 无网络 / API / 插件 / 云服务 / 新增素材 | 通过 |
| ComfyUI 仍主美术路线 | 方案 §0 / §7 声明 2D 程序化仅零依赖兜底，不取代主路线、不宣称已能出图 | 通过 |
| 不伪造输出 | 未真跑不贴脚本 stdout；性能预算标「设计目标、非本轮实测」；枚举标「须 `ClassDB` 真跑」；`CAPTURE-REPORT` 0.37/0.49ms 标为不含 FX 的既有基线 | 通过 |
| 中文 UTF-8 | 主交付件与回执 `utf8_ok=True`（§2.3） | 通过 |
| 不自行 git | 未执行任何 git 命令 | 通过 |
| `00-群聊总线.md` 开工只读一次 | 只读一次、未追加（§2.4 mtime 佐证） | 通过 |
| 不写其它工位 / 总纲 / 契约 / 任务书 | 未写 | 通过 |
| 回执按 `task_id` 写 outbox | `cmd-20261109-083628-786-A4.json`，已被中枢消费归档（§2.2） | 通过 |

---

## 3. ③ 未完成项与阻塞（如实登记，明确「只交付方案未实现」）

| # | 项 | 性质 | 归属 / 说明 |
|---|---|---|---|
| 1 | **只交付方案，未实现**（首要） | 按派单 | 本轮未写任何 `.gd`、未新增 / 启用任何 CanvasLayer 节点、未改 `courtyard.tscn`、未真跑脚本、未抓帧、未验收画面。`HD2D-FX-PLAN.md` 全部是设计值（沿用冻结件），**不代表引擎中已实现或画面已出现四项 FX** |
| 2 | 四项 FX 的运行期落地与画面验收 | 未实跑 | 需 Rank-1（本轮独占 `courtyard.tscn`）按方案 §5 落地后重录一帧复核；本轮不越界、不臆造运行期结论 |
| 3 | `CanvasItemMaterial.BLEND_MODE_ADD` 等 Godot 4 枚举名 / 值 | 待真跑核对 | 方案 §3.6 已标注须用 `ClassDB.class_get_integer_constant_list()` 核对；沿用 `DONE-R14.md` §2.1「臆造 `TEXTURE_REPEAT_ENABLED` 致 Parse Error」教训，本轮不写死、不臆造 |
| 4 | 性能预算为设计目标 | 非实测 | §4.4 的桌面 ≤1.5ms / 移动 ≤0.5ms 是建议增量预算；`CAPTURE-REPORT.md` 的 0.37 / 0.49ms 是不含 FX 的 12 帧静态基线，不冒充本方案实测 |
| 5 | 双档口径未改 | 按约束 | 桌面四项全开 / 移动四项全关为既有冻结（`quality_preset_*.tres` / `render_profiles.tres`）；§4.3「移动档降级而非全关」只是**待裁决建议**，须总指挥裁决、由 Rank-1 装配权执行，本轮未写任何 `.tres` |
| 6 | 2D / 3D 遮挡固有限制 | 待裁决 | SubViewport 内 2D CanvasLayer 天然覆盖 3D，2D 倒影无法插到 3D 角色「之下」；方案用半透明镜像近似，真实遮挡顺序仍待 Rank-1 结合场景裁决（`scene_integration.md` §4 #3 既有登记） |
| 7 | `glow_enabled` / `volumetric_fog_enabled` 语义桥接 | 待落地 | 既有字段指 3D 后处理（本后端无效），方案建议桥接为 2D FX 层 `visible`；属 Rank-1 装配权，本轮只给接线建议、未改字段 |
| 8 | `CanvasModulate` 色值 / `ColorRect` 渐变 | 设计建议 | 已如实限域（仅 SubViewport 内、默认关 / 移动关）与说明 API 边界；色值非冻结口径，须 Rank-1 结合 R14 暖金 ambient / 冷雾裁决 |
| 9 | 回执被中枢**实时消费**，outbox 不常驻 | 非阻塞（已送达） | §2.2 已容错校验 receipts 中同一份通过；若 HOST 需 outbox 常驻副本，请在中枢停止消费后由 HOST 决定 |
| 10 | `128bit` 歧义 / ComfyUI 正式素材接入 / 出图长期阻塞 | 既有长期项 | 沿用 `ART-SPEC-FINAL.md` §6 与历轮登记，本轮不自行改、不谎报 |
| 11 | `git commit` / `git push` | 按约束未执行 | 契约 §9.1 由主 AI 统一提交；本工位不自行 git |

> 无本轮新增阻塞导致任务失败：交付清单 3 项全部落位，派单要求与硬性约束全部满足。上述均为「按派单只给方案」的固有限制、跨工位裁决 / 运行期验收 / 长期占位类登记项。

---

## 4. 合规声明

- 本工位**写入**仅限：`teamwork/Rank-4/HD2D-FX-PLAN.md`、`teamwork/Rank-4/DONE-R15.md`、回执例外 `teamwork/command_center/ai/4/outbox/cmd-20261109-083628-786-A4.json`（中枢消费后移入 `dispatcher/receipts/`，该移动由中枢执行）。
- **本工位未写**：`godot/scripts/render/hd2d_placeholder.gd`、`godot/scenes/courtyard.tscn`、`godot/project.godot`、任何其它 `.gd` / `.tres` / `.import` / `.tscn`、`00-群聊总线.md`、`00-协作契约.md`、`00-项目总纲.md`、`ART-SPEC-FINAL.md`、`HD-2D视觉规范.md`、`scene_integration.md`、其它 Rank 工位、任务书。未自行 `git commit` / `git push`。
- 零付费 / 零外部生成服务 / 零外部素材增量 / 零插件；**ComfyUI 仍是主美术路线**，本方案是 2D 程序化零依赖兜底，不取代主路线、不宣称已能出图、不宣称已实现 3D 后处理；所有 stdout 为真跑、不伪造、不谎报全绿；中文 UTF-8；`00-群聊总线.md` 开工只读一次、未追加。

---

## 结论

主任务闭环：`HD2D-FX-PLAN.md` 交付，在 `gl_compatibility` 不支持 `Environment` glow 的前提下给出体积光 / 光尘 / 湿地倒影 / bloom 四项的程序化 CanvasLayer 近似方案（原语 / 参数 / 叠加顺序 / layer 值 / 与 `HD2DPlaceholderLayer(layer=-10)` 关系 / 桌面·移动双档性能预算齐备）；`DONE-R15.md` 三段齐备；回执按 `task_id` 写入 outbox 并被中枢实时接收，`json.load` 四字段与内容断言全通过。
**`status=done` 指方案交付闭环，不代表画面已实现 / 已验收 —— 本轮只给方案、未实现。** 未完成项与阻塞见 §3。

> 证据：`HD2D-FX-PLAN.md`（25437 B，UTF-8）、回执 `cmd-20261109-083628-786-A4.json`（2179 B，UTF-8，outbox → receipts）、§2.2 / §2.3 / §2.4 真跑校验 stdout。

---

## 5. 追加复核补记（本实例 · 并发保护分支；只追加，不改动上文任何结论）

> 上文 §0~§4 与「结论」均由并发实例先写。本实例按派单「并发保护」判定为「已由并发实例完成，本次仅复核」：**未重做方案、未覆盖既有结论、未重复写第二份回执**，仅追加复核证据并补齐派单点名的一处缺口。

### 5.1 并发判定与独立复核证据（本实例只读 / 真跑）

- 开工只读检查 `HD2D-FX-PLAN.md` / `DONE-R15.md` / `command_center/ai/4/outbox/*` / `dispatcher/receipts/cmd-20261109-083628-786-A4.json` 起初均不存在；本实例准备写入时 `Write` 返回「文件尚未被读取」→ 复查确认方案与 DONE 已被并发实例先写、回执已被中枢消费移入 receipts。
- 独立复核（非引用上文自述）：
  - `Read` 回执本体 `command_center/dispatcher/receipts/cmd-20261109-083628-786-A4.json`：合法 JSON、四字段齐备，`task_id=cmd-20261109-083628-786-A4` ✓ / `ai=4` / `status=done` / `result` 引用 `DONE-R15.md` 实际结论且含「只交付方案、未实现」。
  - `Glob command_center/ai/4/outbox/*` → `No files found`（中枢实时消费，与 §2.2 容错说明一致）；`Glob **/dispatcher/receipts/cmd-20261109-083628-786-A4.json` → 命中 1 个文件。
  - 只读 `wc -c` / `sha256sum` 实际 stdout（EXIT=0）：

```text
HD2D-FX-PLAN.md                            bytes=25437  sha256[:16]=fe22d2689f5d767f
DONE-R15.md                                bytes=14420  sha256[:16]=b02db5b31820f005
receipts/cmd-20261109-083628-786-A4.json   bytes=2179   sha256[:16]=8154cb68211ed7a9
```

  与 §2.3 登记的 25437 / `fe22d2689f5d767f`、2179 / `8154cb68211ed7a9` 逐项吻合；两文件 `Read` 中文正常显示，UTF-8 可解码。
  - 派单主交付核对：方案 §3.1~§3.4 逐项给出体积光 / 光尘 / 湿地倒影 / bloom 的 Godot 原语 / 参数 / 叠加顺序（§2.1 层序总表），§6 #7 明确不宣称实现后处理，§0 / §7 明确只给方案、不改运行中脚本、不碰 `courtyard.tscn` —— 交付完整。

### 5.2 补缺口：后台出图 job 只读观察结论（派单点名项）

上文 §3 #10 仅把「出图长期阻塞」登记为既有长期项，**未记载本轮对该后台 job 的只读观察**；按派单「③ 未完成项与阻塞（如实，含后台出图 job 只读观察结论）」补记（只读，**未启动第二个 GPU 出图 job、未重启、未杀现有 job**）：

- `Read Rank-4/asset_proof_stdout.txt`：近乎空（1 行）。
- `Read Rank-4/asset_proof_stderr.log`：`[load] text_encoder (nf4)` / `[load] transformer (nf4) from Qwen/Qwen-Image-2.1`、权重 `0/750 → …`、`Loading checkpoint shards: 50%|█████ | 1/2 [05:35<05:35, 335.95s/it]`，停在权重 / shard 加载阶段。
- 两日志 grep `(?i)\.png|saved|output|保存`（本实例真跑，实际输出）：

```text
asset_proof_stdout.txt : No matches found
asset_proof_stderr.log : No matches found
```

- **结论**：该后台 `qwen-image --quant nf4` job 两份日志内**无 PNG 产出记录**，长期阻塞延续，如实记阻塞；本轮 R15 写方案文档、不涉及出图、不需要 GPU，按派单「无 PNG 则如实记阻塞并继续本轮交付」执行，不启动第二个 GPU job、不重启 / 不杀现有 job。
- 如实区分：R15 复核时 `godot/assets/generated/` 与 `capture/` 下存在若干 PNG（文件名含 r11/r14 等轮次标记），**不属于上述两份后台日志的输出**，产出方不在本轮核对范围、不臆断来源、不据此宣称该后台 job 已出图；`ART-SPEC-FINAL.md §3.3`「工程根真实 PNG = 0」为 **R9 时点**结论，与 R15 现状存在时点差异，本补记不照搬该旧数值。

### 5.3 真跑 / 引擎输出（如实，不伪造）

- 本实例本轮**未运行任何 Godot 引擎命令**、未写探针 / 测量 / preflight 脚本 → **无引擎门禁输出，无 `SCRIPT ERROR` / `Parse Error` / `ERROR` 引擎 grep 结果可贴**；不伪造、不谎报全绿。派单「本轮主交付是文档方案、不强制三段门禁」按此执行。
- 上文所有 stdout 均为只读核对 / 文本校验的真跑输出，本实例已独立复验其中字节数 / 哈希与回执四字段（§5.1）。

### 5.4 补记后判定

交付清单 3 项、DONE 三段、回执一份（`task_id` 正确、只一份）齐备；本段只**追加**后台出图 job 观察与复核证据，**不改动上文 §0~§4 与「结论」任何既有结论**，`status=done` 口径不变（指方案交付闭环，非画面已实现 / 已验收）。
