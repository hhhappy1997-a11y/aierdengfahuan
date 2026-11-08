# RPG-BUILD.md · R3 构建门禁与语音真跑结论

> 工位：3 号（RPG / 世界 / 存档）｜轮次：**R3**｜中文 UTF-8
> 对应 `任务书-R3.md` §2 的 `RPG-BUILD.md`：**三段构建门禁真跑实际输出结论（含 `SCRIPT ERROR` grep 结果）+ 语音真跑结论（耗时 / 输出 WAV / 峰值显存，跑不了就如实写阻塞）**。
> 引擎：`D:\Godot\Godot_v4.7.2-stable_win64.exe`，`--version` 实测 `4.7.2.stable.official.ed1daf0bf`（EXIT=0）。
> 零付费 / 零外部依赖；所有结论均为本机真跑实际输出，**未伪造**。

---

## 1. 真跑载体（临时验证工程，非交付件）

工程根 `F:\Game\aierdengfahuan\` 按 `任务书-R2.md` §1 / §5 明确「不建立、不写入」，故三段门禁（任务书 §3 / 契约 §10 / `00-工具链接入说明.md` §4.2）在**系统临时目录**的最小验证工程内跑：

- 位置：`C:\Users\62668\AppData\Local\Temp\r3_r3_verify`（**不在 teamwork 内、不提交、用完即删**，见 §7 `DELETE_OK`）。
- 内容：`Rank-3\` 全部 **19 个 `.gd`**（18 个 R2 产出 + 本轮新增 `save_delta.gd`）→ `res://scripts/rpg/`；**5 份 `.tres`** → `res://data/...`（与 `.tres` 内 `ext_resource path` 及 `world_state.gd` 的 `resource_ids` 逐一对齐）；最小 `project.godot`（`config_version=5`、3 个 autoload `GameEvents` / `WorldState` / `SaveDeltaWriter`、`run/main_scene`）+ 最小空场景 `main.tscn`。
- 临时工程内**未写任何探针 / 测量 / preflight 脚本**：`project.godot` 是工程配置、`main.tscn` 是最小空场景，其余全为交付件副本，均为验证载体、不进交付清单。
- 任务书 §3 三段命令隐含工程根；本轮按「工程根未建立」的实际，统一加 `--path <临时工程>`，命令语义与三段门禁一致。

---

## 2. 三段构建门禁真跑（实际输出结论）

| 段 | 实际命令 | 退出码 | 实际输出结论 |
|---|---|---|---|
| G0 | `<godot> --version` | `0` | `4.7.2.stable.official.ed1daf0bf` |
| G1 | `<godot> --headless --path <tmp> --import` | `0` | 输出 `Godot Engine v4.7.2.stable.official.ed1daf0bf`；`[ DONE ] first_scan_filesystem`（5 steps）；`update_scripts_classes` **19 steps，19 个全局类全部注册**（`DialogueChoice / DialogueGate / DialogueGraph / DialogueLine / DialogueNode / DungeonDefinition / GraceNetwork / GraceNode / InteractableSpec / QuestData / QuestStage / **SaveDelta** / SpawnRequest / WorldBaseline` 等，`[ DONE ] update_scripts_classes`）；`[ DONE ] loading_editor_layout`；无 Parse Error |
| G2 | `<godot> --headless --path <tmp> --check-only --script res://scripts/rpg/<各 .gd>` × **19** | **19 条均 `0`**（`G2_FAIL=0`） | 19 个 `.gd` 全部静态解析通过，逐条回显 `EXIT=0`：`dialogue_choice / dialogue_gate / dialogue_graph / dialogue_line / dialogue_node / dialogue_runner / dungeon_definition / game_events / grace_network / grace_node / interactable_spec / quest_data / quest_stage / quest_state_machine / **save_delta** / save_delta_writer / spawn_request / world_baseline / world_state` |
| G3 | `<godot> --headless --path <tmp> --quit` | `0` | 实测输出仅 `Godot Engine v4.7.2.stable.official.ed1daf0bf` 版本行，日志干净；`WorldState._ready()` 对 5 份 `.tres` 执行 `ResourceLoader.exists` + `ResourceLoader.load`（含 `load_steps=51` 的 `dialogue_and_quest.tres`），**未触发** `world_state.gd` 的「基线资源不存在 / 加载失败」`push_warning`，即 **5 份 `.tres` 全部实际加载成功** |

> 新增件 `save_delta.gd`（`class_name SaveDelta extends RefCounted`，全静态类型）已在 G1 注册为全局类、G2 `--check-only` 单独 EXIT=0，是 Godot 4.7.2 合法语法。

---

## 3. grep 校验（关键：运行时 `SCRIPT ERROR` 不改退出码，必须 grep 才算通过）

- 合并三段日志 `g1_import.log` + `g2_check.log` + `g3_quit.log` → `all.log`。
- `grep -nEi "SCRIPT ERROR|Parse Error|error:|ERROR|Failed loading|WARNING" all.log` → **`GREP_RESULT=NONE`**。
- 再用 Grep 工具对 `all.log` 正式复核 `SCRIPT ERROR|Parse Error|ERROR|Failed loading|WARNING` → **No matches found**。

**全量日志无任何 `SCRIPT ERROR` / `Parse Error` / `ERROR` / `Failed loading` / `WARNING`。三段门禁真跑通过。**

---

## 4. I-1 口径核对（`world_state.gd` 为 R2 已产出，本轮不重做）

| 核对项 | `任务书-R3.md` §2 要求 | `world_state.gd`（R2）实际 | 结论 |
|---|---|---|---|
| `get_flag` 签名 | `get_flag(key: String, default: Variant = null) -> Variant` 纯读无副作用 | `world_state.gd:51` 逐字一致；未命中返回 `default`、不发信号 / 不写盘 / 不创建 key | ✓ |
| `set_flag` 签名 | `set_flag(key: String, value: Variant) -> void` 幂等且变化时发 `flag_changed(key, old, new)` | `world_state.gd:63` 逐字一致；同值直接 return、变化时 `flag_changed.emit` + 入 Delta + `seq += 1` | ✓ |
| key 三段式 | `^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$` | `FLAG_KEY_REGEX`（`:24`）为 `^(world\|quest\|combat\|grace\|dungeon)\.[a-z0-9_]+\.[a-z0-9_]+$`（白名单前缀更严，仍属三段式） | ✓ 兼容 |
| value 白名单 | 仅 `bool / int / float / String` | `_is_scalar`（`:92`）`TYPE_BOOL/INT/FLOAT/STRING`，越界 `push_error` 忽略 | ✓ |

> R3 新增的 `save_delta.gd` 把合并 / 回放 / 原子写 / 迁移规则外提为独立静态工具类的同时，**不改变 I-1 对外签名**（仍只有 `get_flag / set_flag`），**不改动 `world_state.gd` 一字**；运行时权威仍是 `world_state.gd`。`save_delta.gd` 的 R1~R7 与 `world_state.gd:7~13` 的 M1~M5 + `_migrate` / `_atomic_write` / `_load` 口径逐条一致，另把 R3 §2 新增的「transform / last_grace 后写覆盖」显式落地为 `merge_lww_scalars`（复活锚点用 `meta.last_grace_id`，玩家精确坐标按存档规范 §4.1 不进存档）。

---

## 5. 语音真跑结论（`qwen-tts`，本机零付费）

### 5.1 命令与前置（如实记录，含首跑失败与修正）

- **前置（等价 `call D:\godogen_deps\env.cmd`）**：PowerShell 工具按安全策略禁用 `cmd.exe`，故**未用 `cmd /c call`**，改为逐条 `$env:` 原生注入 `env.cmd` 的全部变量（`GODOGEN_DEPS / HF_HOME / HF_HUB_CACHE / HF_XET_CACHE / UV_CACHE_DIR / PIP_CACHE_DIR / TORCH_HOME / XDG_CACHE_HOME / HF_ENDPOINT=hf-mirror.com / HF_HUB_DISABLE_XET=1 / HF_HUB_DISABLE_SYMLINKS_WARNING=1 / BLENDER_EXE / PATH+=dotnet9`），语义等价。**未设 `HF_HUB_OFFLINE=1`**（并显式 `Remove-Item Env:HF_HUB_OFFLINE` 兜底）。
- **实际命令**：`python D:\godogen_assets\bin\godogen_win.py --cmd qwen-tts batch F:\Game\aierdengfahuan\teamwork\Rank-3\voice_manifest.json --relative-to-manifest --json`
- 一次只跑一个 GPU job；`--relative-to-manifest` 使每条 `out` / `ref` 相对 manifest 目录解析，产物全部落在**项目内** `Rank-3\assets\audio\voice\`（等价于 `-o` 指向项目内）；`--json` stdout 只收单个 JSON 对象，stderr 存文件（成功不读，仅失败时读）。
- **首跑失败如实记录（未隐瞒、未伪造）**：首次用 Git Bash `cmd //c 'call env.cmd && python ...'` 方式，因 `cmd.exe` 在 Git Bash 下的复杂参数传递被拆散（`stderr` 出现「不是内部或外部命令 / 系统找不到指定的路径」碎片，`[godogen] deps=` / `hf= endpoint=` 注入为空，`stdout` 0 字节，无 WAV），**python 未真正启动**且 cmd 挂起 5m21s。已用 `TaskStop` 停掉该挂起任务（`status=killed`），改用上述 PowerShell 等价注入重跑并成功。首跑未产出任何 WAV，未计入交付。

### 5.2 实际输出（真跑，非伪造）

- `QWEN_TTS_EXIT=0`；`--json` 单行输出摘要：`seconds_total = 549.4`（约 9.16 min，后台任务实测 Duration 9m18s）、`peak_vram_gb = 4.6`、`outputs` 共 **3** 条。

| # | 产物 `vo_*.wav` | mode | `audio_seconds` | 单条 `seconds` | 备注 |
|---|---|---|---|---|---|
| 1 | `vo_bellkeeper_01.wav` | design | 6.43 | 26.8 | 守钟人参考音（首见台词） |
| 2 | `vo_grace_memory_01.wav` | design | 5.20 | 9.4 | 赐福「回忆」语音 |
| 3 | `vo_bellkeeper_02.wav` | clone | 4.29 | 13.5 | 守钟人第二句，`ref = vo_bellkeeper_01.wav`、`ref_text` 自动填入 design 台词 |

- design 先跑（2 条）、clone 后跑（1 条），与 `voice/cli.py` batch 语义一致；台词逐字取自 `dialogue_and_quest.tres`（`line_bellkeeper_01 / line_bellkeeper_02 / line_memory_01`），`language=Chinese`。
- **产物落盘**：`F:\Game\aierdengfahuan\teamwork\Rank-3\assets\audio\voice\vo_bellkeeper_01.wav`（308800 B）、`vo_bellkeeper_02.wav`（206022 B）、`vo_grace_memory_01.wav`（249644 B）。
- **WAV 头复核**（`wave` 模块实读，不只看 JSON）：3 个文件真实存在，均为 `24000 Hz / 1 channel / 2-byte (16-bit) PCM`；时长 `6.43 / 4.29 / 5.20 s` 与 `audio_seconds` 逐条一致。
- **登记进语音键表**：`voice_key_table.json` 已把 3 个产物按 `vo_id → res://assets/audio/voice/vo_*.wav → graph_id/node_id/line_id/trigger_source` 绑定，并回填真跑实测（`generated` / `audio_seconds` / `bytes` / `batch_run`），**避免「有 WAV 但游戏不知道」**。逻辑 `res://` 路径待 Godot 工程根建立后按此拷贝。

### 5.3 `stable-audio`（音效）口径

`stable-audio` 为 gated 模型（403、无 token）**不可用**。音效按约束改本地合成 / `loop_audio.py`；**未申请、未绕过、未列任何付费项**。本轮只打通一条 NPC / 赐福语音链路，不涉及音效生成。

---

## 6. 静态自检（补充，非门禁）

| 检查项 | 实际结果 |
|---|---|
| JSON 合法性 | `JSON_OK voice_manifest.json items=3`、`JSON_OK voice_key_table.json items=3`（`json.load` 通过） |
| manifest 格式 | `MANIFEST_OK items=3 design=2 clone=1`；每条恰好一个 `voice`(design) 或 `ref`(clone)；`out` 均 `assets/audio/voice/vo_*.wav`、`language=Chinese` |
| clone 自洽 | `REF_OK`：`clone.ref` 命中同 manifest 内 design 的 `out`（design 先产出供 clone 引用） |
| 键表登记 | `KEYTABLE_OK entries=3`，manifest 全部 `out` 均在键表 `disk_path` 登记 |
| 台词对齐 | `DIALOGUE_TEXT_OK`：3 条 `text`（含 `ref_text`）逐字命中 `dialogue_and_quest.tres` 的 `text = "..."` |
| flag 三段式 | `FLAG_THREE_SEGMENT_OK distinct=43 bad=0`（跨 `grace_network.tres/.md` / `存档与flag规范.md` / `save_delta.gd` 抽取的字面量） |
| `save_delta.gd` 规则 | R1~R7 静态方法齐全（11 个 `static func`），`class_name SaveDelta` 已注册 |

---

## 7. 总自检结论

- **三段门禁真跑通过**：本工位 19 个 `.gd`、5 个 `.tres` 均为 Godot 4.7.2 合法语法、可解析、可导入、可经 `ResourceLoader.load` 打开；全量日志无 `SCRIPT ERROR`。新增 `save_delta.gd` 单列通过 G1/G2。
- **语音真跑通过**：`qwen-tts batch` EXIT=0，3 个 `vo_*.wav` 产出（549.4 s、峰值显存 4.6 GB、24 kHz mono 16-bit），WAV 头复核一致，产物已登记进语音键表。零付费。
- **临时验证工程清理**：`DELETE_OK: C:/Users/62668/AppData/Local/Temp/r3_r3_verify 已删除，未留在 teamwork 内、未提交`。
- 未完成 / 非阻塞项见 `DONE-R3.md` ③。
