# DONE-R10.md · Rank-1 R10「导出 Windows exe + apk 前置核对」

> 任务单 id：`cmd-20261109-033148-246-A1`（派单 `Rank-1\任务书-R10.md`）
> 轮次：R10 ｜ 状态：**完成（exe 真产出；apk 仅前置核对，未产出且不谎报）**
> 必读开工已读一次：`任务书-R10.md`、`GATE-FINAL.md`、`00-协作契约.md`、`00-群聊总线.md`
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`（`4.7.2.stable.official.ed1daf0bf`）
> 工程根：`F:/Game/aierdengfahuan/godot`（R9 已 `ERROR=0`、51/51 `.gd` 通过）

---

## ① 交付清单（实际落盘）

| # | 交付项 | 路径 | 实际结果 |
|---|---|---|---|
| 1 | `godot/export_presets.cfg` | `F:/Game/aierdengfahuan/godot/export_presets.cfg` | 新建，Godot 4 合法；定义 `Windows Desktop` preset：`name` / `platform` / `runnable=true` / `export_path="F:/Game/aierdengfahuan/build/Aierdengfahuan.exe"` 齐备；按第 1 次真跑报错补 `export_filter` / `include_filter` / `exclude_filter` 与 `[preset.0.options]` 段 |
| 2 | Windows exe 真跑导出 | 命令见 §2 | **成功**：`EXIT=0`、`ERROR=0`、`WARNING=0` |
| 3 | exe 产物 | `F:/Game/aierdengfahuan/build/Aierdengfahuan.exe` | **真实存在，109127680 字节**，PE 头 `MZ` |
| 4 | 配套资源包 | `F:/Game/aierdengfahuan/build/Aierdengfahuan.pck` | **真实存在，412576 字节**，头 `GDPC` |
| 5 | Android 前置核对 | 见 `EXPORT-REPORT.md` §5 | 模板/JDK/keystore 具备；SDK `platforms/` / `ndk/` / `cmdline-tools/` 缺失、无 Android preset → 如实登记缺口 |
| 6 | `EXPORT-REPORT.md` | `Rank-1/EXPORT-REPORT.md` | 已写：exe 路径与大小 / 实际导出输出 / apk 缺口清单 / 结论 |
| 7 | `DONE-R10.md` | 本文件 | 已写：①交付清单 ②自检 ③未完成项与阻塞 |
| 8 | 真跑输出留存 | `Rank-1/export_run_1.log`（21608 B）、`Rank-1/export_run_2.log`（20464 B） | 两次导出完整 stdout/stderr 原文 |
| 9 | 回执 JSON | `command_center/ai/1/outbox/cmd-20261109-033148-246-A1.json` | 按任务单 id 写入 |

> 新建目录：`F:/Game/aierdengfahuan/build/`（本轮创建）。

---

## ② 自检（含真跑实际输出）

### 2.1 真跑命令（逐字，两次相同）

```text
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --export-release "Windows Desktop" "F:/Game/aierdengfahuan/build/Aierdengfahuan.exe"
```

导出前核对：主场景 `res://scenes/Main.tscn` 存在（3393 B）；`project.godot` 中 `run/main_scene="res://scenes/Main.tscn"`；`config_version=5`。导出模板目录 `4.7.2.stable` 的 `version.txt` 实测 `4.7.2.stable`，与引擎一致。

### 2.2 第 1 次真跑（第 1 版预设，用于按报错校正）

`EXIT=0`，产物已生成，但输出含预设缺字段报错。实际报错原文（出现 2 组）：

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Couldn't find the given section "preset.0" and key "export_filter", and no default was given.
   at: get_value (core/io/config_file.cpp:60)
ERROR: Couldn't find the given section "preset.0" and key "include_filter", and no default was given.
   at: get_value (core/io/config_file.cpp:60)
ERROR: Couldn't find the given section "preset.0" and key "exclude_filter", and no default was given.
   at: get_value (core/io/config_file.cpp:60)
ERROR: Cannot get keys from nonexistent section "preset.0.options".
   at: get_section_keys (core/io/config_file.cpp:94)
[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[ DONE ] first_scan_filesystem
[   0% ] savepack | Started 打包中 (102 steps)
[  97% ] savepack | 正在保存文件：res://project.binary
[ DONE ] savepack
```

**已尝试的修正（按报错，不凭猜测）**：补 `export_filter="all_resources"` / `include_filter=""` / `exclude_filter=""` 三个 preset 级键；在 `[preset.0.options]` 写入 `binary_format/embed_pck=false`（使段真实存在且与 exe+独立 pck 产物形态一致）。未写入任何未验证字段。

产物（第 1 次）：`Aierdengfahuan.exe` 109127680 B、`Aierdengfahuan.pck` 412576 B。

### 2.3 第 2 次真跑（校正后，最终交付口径）——实际输出

```text
EXIT=0
=== ACTUAL STDOUT/STDERR ===
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started 项目初始化 (5 steps)
[   0% ] first_scan_filesystem | 正在扫描文件结构……
[  16% ] first_scan_filesystem | 正在加载全局类名……
[  33% ] first_scan_filesystem | 正在校验 GDExtension……
[  50% ] first_scan_filesystem | 正在创建自动加载脚本……
[  66% ] first_scan_filesystem | 正在初始化插件……
[  83% ] first_scan_filesystem | 正在启动文件扫描……
[ DONE ] first_scan_filesystem

[   0% ] savepack | Started 打包中 (102 steps)
[   1% ] savepack | 正在保存文件：res://.godot/imported/vo_bellkeeper_01.wav-944507aad81d42f3948527c3e9f74147.sample
[  37% ] savepack | 正在保存文件：res://.godot/exported/133200997/export-4a24720ee5e787dbe30abc634fa3679d-Main.scn
[  38% ] savepack | 正在保存文件：res://scripts/combat/attach_boss_to_courtyard.gdc
[  97% ] savepack | 正在保存文件：res://scripts/build_main.gd.remap
[  97% ] savepack | 正在保存文件：res://.godot/global_script_class_cache.cfg
[  97% ] savepack | 正在保存文件：res://.godot/uid_cache.bin
[  97% ] savepack | 正在保存文件：res://project.binary
[ DONE ] savepack

=== ERROR / WARNING COUNT ===
0
0
```

判据：`EXIT=0`。两次日志 grep 实际计数（逐字，含 `SCRIPT ERROR`）：

```text
-- export_run_1.log --
SCRIPT ERROR: 0
Parse Error: 0
ERROR: 8
WARNING: 0
-- export_run_2.log --
SCRIPT ERROR: 0
Parse Error: 0
ERROR: 0
WARNING: 0
```

第 1 次的 8 行 `ERROR` 全部为 §2.2 所列的预设缺字段报错（非 `SCRIPT ERROR`、非脚本解析错误），校正后归零。完整 102 步打包输出见 `export_run_2.log`。
三段门禁（G1 `--import` / G2 全量 `.gd --check-only` / G3 `--quit`）的 `ERROR=0`、51/51 `.gd` 通过结论沿用必读件 `GATE-FINAL.md`，本轮按 HOST 明确派单聚焦「导出命令真跑」，未复跑三段门禁、未谎报复跑。

### 2.4 产物存在性与字节大小（真跑前后对照，实际输出）

```text
=== BEFORE (mtime/size) ===
/f/Game/aierdengfahuan/build/Aierdengfahuan.exe 109127680 2026-11-09 03:36:08.146622900 +0800
/f/Game/aierdengfahuan/build/Aierdengfahuan.pck 412576 2026-11-09 03:36:20.177090900 +0800
=== AFTER (mtime/size) ===
/f/Game/aierdengfahuan/build/Aierdengfahuan.exe 109127680 2026-11-09 03:37:30.090306100 +0800
/f/Game/aierdengfahuan/build/Aierdengfahuan.pck 412576 2026-11-09 03:37:40.214136500 +0800
```

mtime 03:36 → 03:37 刷新，证明为第 2 次真跑重新产出。

### 2.5 产物文件头校验（python 只读，实际输出）

```text
Aierdengfahuan.exe size=109127680 head=b'MZ\x90\x00\x03\x00\x00\x00' hex=4d5a900003000000
Aierdengfahuan.pck size=412576 head=b'GDPC\x04\x00\x00\x00' hex=4744504304000000
```

`MZ` = Windows PE；`GDPC` = Godot 4 PCK。产物真实有效，非空壳、非伪造。

### 2.6 Android 前置核对（只读，实际输出摘要）

```text
=== tpl.tpz === size=1281349702 entries=35
  android_matches: 3 ['templates/android_debug.apk', 'templates/android_release.apk', 'templates/android_source.zip']
=== jdk17.zip === size=190817615 entries=580
  android_matches: 0 []          ← 是 JDK 17，非模板
=== cmdline.zip === size=153583359 entries=104
  android_matches: 3（仅 smali jar 名，非 Godot 导出模板）
```

编辑器设置实际登记：`java_sdk_path="D:/AndroidDev/jdk-17.0.20.1+1"`、`android_sdk_path="D:/AndroidDev/android-sdk"`、`debug_keystore="C:/Users/62668/AppData/Roaming/Godot/keystores/debug.keystore"`。

路径实测：JDK **存在**；`android-sdk/` **存在但不完整**（仅 `build-tools/34.0.0`、`platform-tools/`）；`platforms/` / `cmdline-tools/` / `ndk/` / `cmake/` **均不存在**；`debug.keystore` **存在且有效**（`keytool -list` `EXIT=0`，PKCS12、`androiddebugkey`）；`ANDROID_HOME`/`ANDROID_SDK_ROOT`/`JAVA_HOME`/`ANDROID_NDK_HOME` **均为空**；`D:/AndroidDev/dl/` 只有 build-tools/jdk17/platform-tools 三个 zip，无 platform/NDK 包。

已安装的 Godot Android 模板（版本一致，实测）：
```text
4.7.2.stable/version.txt = 4.7.2.stable
android_debug.apk   127260725
android_release.apk 104803333
android_source.zip  214418211
```

---

## ③ 未完成项与阻塞

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| 1 | apk 产物 | **未完成（本轮范围内不产出）** | 任务书 R10 对 Android 的要求是「前置核对」，非「导出 apk」。SDK 缺 `platforms/android-<api>`、`ndk/`、`cmdline-tools/`，`export_presets.cfg` 无 Android preset 与包名/签名/横竖屏配置 → **前置不全，未产出 apk、未尝试 apk 导出、未伪造 apk、不假装能出 apk** |
| 2 | Android SDK 组件补装 | **待裁决，只登记不擅改** | 是否补装 `platforms/` / NDK / 解压 `cmdline.zip`、是否新增 Android preset 与包名签名，属超本轮范围 / 需 HOST 裁决；零外部依赖、不自行下载或解压 |
| 3 | exe 窗口启动 / 人工试玩 / 画面可见性验收 | **未做** | 本轮只到 `--headless` 导出。`GATE-FINAL.md` §7 已声明未做窗口渲染验收，本轮不宣称「已能出图 / 已渲染可见」 |
| 4 | 1 条 `ObjectDB leaked` WARNING | **沿用 R9 结论，未擅改** | R9 门禁为 `--headless --quit` 残留，WARNING 级非 ERROR；本轮导出输出 `WARNING=0`，与之不冲突，未改 `chunk_streaming.gd` |
| 5 | 二进制产物是否进仓库 | **待裁决** | 契约 §9.1 已注明「exe / apk 是否连二进制一起提交待用户确认」；本轮不自行 `git commit` / `git push` |

**阻塞判定**：Windows exe 交付**无阻塞**（已真产出）。apk 侧存在**环境性缺口**（SDK 组件未齐 + 无 Android preset），如实登记为阻塞，未绕过、未臆造路径、未谎报。

---

## ④ 完成标志与边界

- 回执：已写入 `command_center/ai/1/outbox/cmd-20261109-033148-246-A1.json`（`task_id=cmd-20261109-033148-246-A1`、`ai=1`、`status=done`）；随后被中枢 dispatcher 正常消费归档至 `command_center/dispatcher/receipts/cmd-20261109-033148-246-A1.json`（1114 B，与历轮回执同目录），`dispatcher.log` 实测 `[2026-11-09 03:41:07] ← 1 号 AI 回执 <cmd-20261109-033148-246-A1> 完成`，`python json.load` 校验通过。`result` 引用本文件实际结论，明确写出 exe 已产出（含路径与 109127680 字节）与 apk 未产出。
- 只写：`Rank-1\`、`godot/export_presets.cfg`、新建 `build\`、回执 `outbox\`。未写总线 / 总纲 / 契约 / 任务书 / 其它工位 / `godot` 既有件；未自行 git；零付费 / 零外部依赖；既有件未重做；待裁决项只登记不擅改；中文 UTF-8；Godot 4 合法语法。
- 全部结论来自两次 `--headless --export-release` 真跑与只读核对的实际输出，**未伪造输出、未冒充全绿、未伪造 exe、未谎报 apk**。
