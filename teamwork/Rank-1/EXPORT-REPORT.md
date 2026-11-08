# EXPORT-REPORT.md · R10 Windows exe 导出与 apk 前置核对

> 轮次：R10「导出 Windows exe + apk 前置核对」
> 任务单 id：`cmd-20261109-033148-246-A1`（派单 `Rank-1\任务书-R10.md`）
> 工程根：`F:/Game/aierdengfahuan/godot`
> 引擎：`D:/Godot/Godot_v4.7.2-stable_win64.exe`，实测 `4.7.2.stable.official.ed1daf0bf`
> 导出模板：`C:/Users/62668/AppData/Roaming/Godot/export_templates/4.7.2.stable`（`version.txt` 实测 `4.7.2.stable`）
> 本报告全部数据来自真跑实际输出与只读核对，**未伪造产物、未谎报成功、未臆造路径**。

---

## 0. 结论速览

| 项 | 结论 |
|---|---|
| Windows exe | **已真实产出**：`F:/Game/aierdengfahuan/build/Aierdengfahuan.exe`，`109127680` 字节，PE 头 `MZ`；配套 `Aierdengfahuan.pck`，`412576` 字节，头 `GDPC` |
| 导出门禁 | 第 2 次 `--headless --export-release` 真跑 `EXIT=0`、`ERROR=0`、`WARNING=0` |
| apk | **本轮未产出、未尝试 apk 导出**。Android 模板与 JDK / debug keystore 具备，但 Android SDK 缺 `platforms/` / `ndk/` / `cmdline-tools/`，且无 Android 导出 preset、无包名与签名配置 → 前置不全，按「前置核对」口径如实登记缺口，**不假装能出 apk** |

---

## 1. 真跑命令（逐字）

```text
"D:/Godot/Godot_v4.7.2-stable_win64.exe" --headless --path "F:/Game/aierdengfahuan/godot" --export-release "Windows Desktop" "F:/Game/aierdengfahuan/build/Aierdengfahuan.exe"
```

导出前已确认：主场景 `res://scenes/Main.tscn` 存在（`godot/scenes/Main.tscn`，3393 字节）；`project.godot` 中 `run/main_scene="res://scenes/Main.tscn"`；`config_version=5`。`build/` 目录由本轮新建。

---

## 2. `godot/export_presets.cfg`（最终落盘内容）

```ini
; Godot 4 导出预设（Rank-1 R10 交付件）
; 平台名 "Windows Desktop" 为 Godot 4 注册的 Windows 导出平台标识。
; 第 1 次 --headless --export-release 真跑输出报缺失字段，本文件按实际报错逐项校正：
;   export_filter / include_filter / exclude_filter 三个 preset 级键，
;   以及 [preset.0.options] 段必须至少含一个键（否则 get_section_keys 报段不存在）。
; options 内目前只写 1 个经真跑确认生效的键，不臆造未验证字段。

[preset.0]

name="Windows Desktop"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="F:/Game/aierdengfahuan/build/Aierdengfahuan.exe"

[preset.0.options]

binary_format/embed_pck=false
```

### 2.1 校正过程（不凭猜测写死字段）

1. **第 1 版**只写任务书要求的 4 个字段 `name` / `platform` / `runnable` / `export_path` + 一个空 `[preset.0.options]` 段。
2. 第 1 次真跑输出报 4 类 `ERROR`（见 §3.1）：`export_filter` / `include_filter` / `exclude_filter` 三个键无默认值；`[preset.0.options]` 段因空段被判定不存在。
3. **按报错逐项补齐**：补 3 个 preset 级键（`export_filter="all_resources"`、`include_filter=""`、`exclude_filter=""`），并在 options 段写入 `binary_format/embed_pck=false` 使段真实存在且与「exe + 独立 pck」产物形态一致。
4. 第 2 次真跑 `ERROR=0` / `WARNING=0`，格式合法。未写入任何未经真跑验证的字段。

---

## 3. 真跑实际输出

完整 stdout/stderr 留存：`Rank-1/export_run_1.log`（21608 字节）、`Rank-1/export_run_2.log`（20464 字节）。

### 3.1 第 1 次（第 1 版预设）

`EXIT=0`，产物已生成，但输出含预设缺字段报错。实际报错原文（出现 2 组，共 8 行 `ERROR` + 8 行 `at:`）：

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
...
[ DONE ] first_scan_filesystem
...（同组 4 条 ERROR 再次出现）...
[   0% ] savepack | Started 打包中 (102 steps)
...（102 步逐个保存 res:// 文件）...
[  97% ] savepack | 正在保存文件：res://project.binary
[ DONE ] savepack
```

产物（第 1 次）：`Aierdengfahuan.exe` 109127680 字节、`Aierdengfahuan.pck` 412576 字节。

### 3.2 第 2 次（按报错校正后，最终交付口径）

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
...
[  37% ] savepack | 正在保存文件：res://.godot/exported/133200997/export-4a24720ee5e787dbe30abc634fa3679d-Main.scn
[  38% ] savepack | 正在保存文件：res://scripts/combat/attach_boss_to_courtyard.gdc
...
[  97% ] savepack | 正在保存文件：res://scripts/build_main.gd.remap
[  97% ] savepack | 正在保存文件：res://.godot/global_script_class_cache.cfg
[  97% ] savepack | 正在保存文件：res://.godot/uid_cache.bin
[  97% ] savepack | 正在保存文件：res://project.binary
[ DONE ] savepack

=== ERROR / WARNING COUNT ===
0
0
```

两次日志 grep 实际计数（逐字，含 `SCRIPT ERROR`）：

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

第 1 次的 8 行 `ERROR` 全为 §3.1 所列预设缺字段报错（非 `SCRIPT ERROR`、非脚本解析错误），按报错校正后归零；`grep -c "ERROR"` / `grep -c "WARNING"` 最终均为 `0`。三段门禁 `ERROR=0`、51/51 `.gd` 通过的结论沿用必读件 `GATE-FINAL.md`，本轮按 HOST 派单聚焦「导出命令真跑」，未复跑三段门禁、未谎报复跑。

### 3.3 产物存在性与字节大小（真跑前后对照）

```text
=== BEFORE (mtime/size) ===
/f/Game/aierdengfahuan/build/Aierdengfahuan.exe 109127680 2026-11-09 03:36:08.146622900 +0800
/f/Game/aierdengfahuan/build/Aierdengfahuan.pck 412576 2026-11-09 03:36:20.177090900 +0800
=== AFTER (mtime/size) ===
/f/Game/aierdengfahuan/build/Aierdengfahuan.exe 109127680 2026-11-09 03:37:30.090306100 +0800
/f/Game/aierdengfahuan/build/Aierdengfahuan.pck 412576 2026-11-09 03:37:40.214136500 +0800
```

mtime 由 03:36 → 03:37 刷新，证明为第 2 次真跑重新产出，非沿用旧文件。

### 3.4 产物文件头校验（python 只读，实际输出）

```text
Aierdengfahuan.exe size=109127680 head=b'MZ\x90\x00\x03\x00\x00\x00' hex=4d5a900003000000
Aierdengfahuan.pck size=412576 head=b'GDPC\x04\x00\x00\x00' hex=4744504304000000
```

`MZ` = Windows PE 可执行文件；`GDPC` = Godot 4 PCK 包。产物为真实 Godot 导出件，非空壳、非伪造。

---

## 4. 交付产物清单

| 路径 | 大小（字节） | 说明 |
|---|---|---|
| `F:/Game/aierdengfahuan/build/Aierdengfahuan.exe` | 109127680 | Windows Desktop release 可执行文件（PE） |
| `F:/Game/aierdengfahuan/build/Aierdengfahuan.pck` | 412576 | 配套资源包（GDPC），exe 运行需同目录 |
| `F:/Game/aierdengfahuan/godot/export_presets.cfg` | — | Windows Desktop preset（本轮新建，Godot 4 合法） |

---

## 5. Android 前置核对（只读，逐项如实登记）

### 5.1 `tpl.tpz` / `jdk17.zip` / `cmdline.zip` 是否含 Android 模板

用 `python zipfile` 只读列中央目录，实际输出：

```text
=== tpl.tpz === size=1281349702 entries=35
  first8: ['templates/android_debug.apk', 'templates/android_release.apk', 'templates/android_source.zip', 'templates/icudt_godot.dat', 'templates/ios.zip', 'templates/linux_debug.arm32', 'templates/linux_debug.arm64', 'templates/linux_debug.x86_32']
  android_matches: 3 ['templates/android_debug.apk', 'templates/android_release.apk', 'templates/android_source.zip']
=== jdk17.zip === size=190817615 entries=580
  first8: ['jdk-17.0.20.1+1/', 'jdk-17.0.20.1+1/bin/', ...]
  android_matches: 0 []
=== cmdline.zip === size=153583359 entries=104
  first8: ['cmdline-tools/bin/avdmanager.bat', 'cmdline-tools/bin/sdkmanager.bat', ...]
  android_matches: 3 ['cmdline-tools/lib/external/com/android/tools/smali/...']（仅 jar 名含 android，非 Godot 导出模板）
```

- `tpl.tpz` **含** Android 导出模板 3 件，且**已安装**到 `export_templates/4.7.2.stable/`：`android_debug.apk`（127260725）、`android_release.apk`（104803333）、`android_source.zip`（214418211）；该目录 `version.txt` 实测 `4.7.2.stable`，与引擎一致。
- `jdk17.zip` 是 JDK 17 压缩包（`jdk-17.0.20.1+1/`），**不含** Android 模板；已解压到 `D:/AndroidDev/jdk-17.0.20.1+1/`。
- `cmdline.zip` 是 Android SDK command-line tools（`sdkmanager.bat` / `avdmanager.bat` 等），**不含** Godot 导出模板。

### 5.2 编辑器设置中登记的 Android 路径（`editor_settings-4.7.tres` 实际行）

```text
export/android/debug_keystore = "C:/Users/62668/AppData/Roaming/Godot/keystores/debug.keystore"
export/android/debug_keystore_pass = "android"
export/android/java_sdk_path = "D:/AndroidDev/jdk-17.0.20.1+1"
export/android/android_sdk_path = "D:/AndroidDev/android-sdk"
```

### 5.3 路径存在性核对（实际输出）

| 项 | 路径 | 实测 |
|---|---|---|
| JDK | `D:/AndroidDev/jdk-17.0.20.1+1/` | **存在**（bin/conf/lib/jmods 齐全，`bin/keytool.exe` 可用） |
| Android SDK 根 | `D:/AndroidDev/android-sdk/` | **存在但不完整**：仅 `build-tools/34.0.0`、`platform-tools/`（adb 等） |
| `platforms/`（android-xx） | `D:/AndroidDev/android-sdk/platforms/` | **不存在** |
| `cmdline-tools/` | `D:/AndroidDev/android-sdk/cmdline-tools/` | **不存在**（`cmdline.zip` 未解压落位） |
| NDK | `ndk/` / `ndk-bundle/` / `cmake/` | **均不存在** |
| debug keystore | `C:/Users/62668/AppData/Roaming/Godot/keystores/debug.keystore` | **存在且有效**（2666 字节；`keytool -list -storepass android` `EXIT=0`，PKCS12，条目 `androiddebugkey`，SHA-256 `A3:A1:B8:C8:...:5F:3B`） |
| 环境变量 | `ANDROID_HOME` / `ANDROID_SDK_ROOT` / `JAVA_HOME` / `ANDROID_NDK_HOME` | **均为空** |
| 未解压包源 | `D:/AndroidDev/dl/` | 仅 `build-tools.zip`、`jdk17.zip`、`platform-tools.zip`，**无** platform / ndk / cmdline 安装包 |

### 5.4 apk 缺口清单（本轮不擅改、只登记）

1. Android SDK 缺 `platforms/android-<api>`：Godot Android 导出需要 SDK Platform。
2. Android SDK 缺 `ndk/`（及 `cmake/`）：使用 `android_source.zip` / Gradle 自定义构建或需 native 编译时需要。
3. Android SDK 缺 `cmdline-tools/`：`D:/Godot/_dl/cmdline.zip` 未解压落位。
4. `export_presets.cfg` **无 Android preset**（本轮只按任务书要求定义 Windows Desktop），亦无包名 / 签名 / 横竖屏 / 像素缩放适配配置。
5. 4 个 Android/JDK 环境变量均未设置（编辑器内已写死路径可部分替代，但命令行构建无环境兜底）。

### 5.5 apk 结论

- 具备：Godot 4.7.2 Android 导出模板（已安装且版本一致）、JDK 17、有效 debug keystore、build-tools 34.0.0、platform-tools。
- 缺口：SDK `platforms/` / `ndk/` / `cmdline-tools/` 缺失、无 Android 导出 preset 与包名签名配置。
- **本轮按「apk 前置核对」口径执行：未产出 apk、未尝试 apk 导出、未伪造 apk、不假装能出 apk**。补齐上述缺口并明确包名/签名/横竖屏配置后，方具备真跑 apk 导出的条件；是否补装 SDK 组件属待裁决项，本轮只登记、不擅改、不自行下载或解压（零外部依赖、既有件不重做）。

---

## 6. 结论

- **Windows exe 交付达成**：`export_presets.cfg` 为 Godot 4 合法配置，`--headless --export-release "Windows Desktop"` 真跑 `EXIT=0 / ERROR=0 / WARNING=0`，产物真实存在且文件头可验证（PE + PCK）。
- **apk 前置核对达成**：模板/JDK/keystore 具备，SDK 组件缺口与 preset 缺口已逐项如实登记，未臆造路径、未谎报 apk。
- 边界：以上均为 `--headless` 导出结论，**未做窗口启动 / 人工试玩 / 画面可见性验收**；exe 能否正常渲染运行需后续人工试玩确认。

---

## 7. 边界声明

- 本轮实际写入：`godot/export_presets.cfg`（新建）、`build/Aierdengfahuan.exe` + `build/Aierdengfahuan.pck`（导出产物，新建 `build/`）、`Rank-1/export_run_1.log`、`Rank-1/export_run_2.log`（真跑输出留存）、`Rank-1/EXPORT-REPORT.md`、`Rank-1/DONE-R10.md`、`command_center/ai/1/outbox/` 回执 JSON（写入后由中枢 dispatcher 消费归档至 `command_center/dispatcher/receipts/cmd-20261109-033148-246-A1.json`，`dispatcher.log` 03:41:07 确认接收，JSON 校验通过）。
- 未写：`00-群聊总线.md` / 总纲 / 契约 / 任务书、其它 Rank 工位、`godot/project.godot` / `scenes/` / `scripts/` / `data/` 既有件（仅新增 `export_presets.cfg`）、`D:/AndroidDev/` 与 `D:/Godot/` 任何内容。
- 未自行 `git commit` / `git push`；未调用付费 API / 外部服务；未新增跨工位脚本 / 探针；既有件未重做；中文 UTF-8；GDScript / 配置为 Godot 4 合法语法。
- 全部结论来自两次 `--headless --export-release` 真跑与只读核对实际输出，**未伪造输出、未冒充全绿、未谎报 apk**。
