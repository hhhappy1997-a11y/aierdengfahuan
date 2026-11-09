# DONE-R21B.md — Rank-4 产物对齐交付（ROUND=R21B）

- 补单 id：`cmd-20261109-122557-230-A4`
- 执行：Rank-4（美术管线与工具链）
- 时间：2026-11-09 12:26~12:31（本机 +0800）
- 结论：**两次导出均 EXIT=0，四件产物已按 R13~R21 最终工程重导完成；无伪造、无谎报。**
- 本轮只做产物对齐，**未改任何工程源文件**（`--import` 自动生成的 `.godot/` 缓存与 `.uid` 除外），未执行任何 git 操作。

## 0. 环境事实（真跑前核对）

| 项 | 值 |
|---|---|
| 引擎 | `D:/Godot/Godot_v4.7.2-stable_win64.exe`，`--version` = `4.7.2.stable.official.ed1daf0bf` |
| 工程 | `F:/Game/aierdengfahuan/godot/project.godot`（`config_version=5`） |
| 导出模板 | `C:/Users/62668/AppData/Roaming/Godot/export_templates/4.7.2.stable`（`windows_release_x86_64.exe`、`android_debug.apk` 齐全） |
| Android SDK | `D:/AndroidToolchain/sdk`（platforms 34/36，build-tools 34.0.0 / 36.1.0） |
| JDK | `D:/AndroidToolchain/jdk17`（OpenJDK 17）；本轮 `JAVA_HOME` 指向此处并加入 PATH |
| debug.keystore | `C:/Users/62668/AppData/Roaming/Godot/keystores/debug.keystore`（editor settings `export/android/debug_keystore` 指向，实测存在）；另 `D:/AndroidToolchain/debug.keystore`、`~/.android/debug.keystore` 均在 |
| project.godot 关键键 | `textures/vram_compression/import_etc2_astc=true`（project.godot:141）已存在；R20 新增第 6 个 autoload `SaveDeltaWriter`（project.godot:52） |
| editor settings | `export/android/android_sdk_path=D:/AndroidToolchain/sdk`；`export/android/java_sdk_path=D:/AndroidDev/jdk-17.0.20.1+1`（历史值，实测 java.exe 存在；本轮未改） |
| .gitignore | 含 `build/`、`*.exe`、`*.pck`、`*.apk`、`*.aab`、`*.log` |

## 1. 实际交付清单

| 产物 / 动作 | 真跑命令 | EXIT | 状态 |
|---|---|---|---|
| 导入 | `Godot.exe --headless --path F:/Game/aierdengfahuan/godot --import` | 0 | ERROR=0 |
| Windows Release 重导 | `--headless --export-release "Windows Desktop"` | 0 | 生成 `build/Aierdengfahuan.exe` + `.pck` |
| 启动验证 | 导出 exe `--headless --quit-after 10` | 0 | 正常退出 |
| Android Debug 重导 | `--headless --export-debug "Android"`（JAVA_HOME=jdk17） | 0 | 生成 `build/Aierdengfahuan.apk` + `.apk.idsig` |
| 验签 | `apksigner.bat verify --verbose --print-certs` | 0 | Verifies |
| v4/idsig 匹配 | `apksigner.bat verify --v4-signature-file <idsig>` | 0 | Verifies / v4=true |
| 包名版本 | `aapt.exe dump badging` | 0 | 包名 / versionName 核对 |

导出日志（均在 `teamwork/Rank-4/`，`*.log` 被 .gitignore 排除）：
`r21b-import.log`、`r21b-export-windows.log`、`r21b-run-verify.log`、`r21b-export-android.log`、`r21b-apksigner-verify.log`、`r21b-apksigner-verify-v4.log`、`r21b-aapt-badging.log`。

## 2. 两段导出 stdout 关键行（含导入与启动验证）

### 2.1 `--import`（EXIT=0，ERROR=0）
```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[ DONE ] first_scan_filesystem
IMPORT_EXIT=0
```
日志全文经 Grep（`ERROR|SCRIPT ERROR|error:|Error`）**无匹配** → ERROR=0。

### 2.2 `--export-release "Windows Desktop"`（EXIT=0）
```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[ DONE ] first_scan_filesystem
[   0% ] savepack | Started 打包中 (102 steps)
[  75% ] savepack | 正在保存文件：res://scripts/rpg/save_delta_writer.gdc
[  82% ] savepack | 正在保存文件：res://scripts/attach_fx_r17.gdc
[  85% ] savepack | 正在保存文件：res://scripts/build_fx_r18_verify.gdc
[  90% ] savepack | 正在保存文件：res://scripts/save_delta_writer.gdc
[  91% ] savepack | 正在保存文件：res://scripts/tune_r16.gdc
[  98% ] savepack | 正在保存文件：res://scripts/wire_r19.gd.remap
[ DONE ] savepack
EXPORT_WINDOWS_EXIT=0
```
> 上述 `save_delta_writer` / `wire_r19` / `tune_r16` / `attach_fx_r17` / `build_fx_r18_verify` 等即 R13~R21 新增脚本，证明产物已含最终工程内容（`.pck` 随之增大，见 §3）。

### 2.3 启动验证（EXIT=0）
```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
RUN_VERIFY_EXIT=0
```

### 2.4 `--export-debug "Android"`（EXIT=0）
```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[ DONE ] first_scan_filesystem
ERROR: No project icon specified. Please specify one in the Project Settings under Application -> Config -> Icon
   at: load_icon_refs (platform/android/export/export_plugin.cpp:1941)   ← 非致命，见 §5
[   0% ] export | Started 正在为 Android 导出 (105 steps)
[  97% ] export | 正在对齐 APK……
[  98% ] export | 正在签名调试 APK……
Signing binary using:
D:/AndroidToolchain/sdk/build-tools/36.1.0/apksigner.bat sign --verbose --ks ... F:/Game/aierdengfahuan/build/Aierdengfahuan.apk
Signed
[  99% ] export | 正在校验 APK……
[ DONE ] export
EXPORT_ANDROID_EXIT=0
```

## 3. 新旧字节数对比（如实）

| 产物 | 07:55/07:56 旧版 | R21B 新版 | 差异 | 说明 |
|---|---|---|---|---|
| `Aierdengfahuan.exe` | 109,127,680 B | **109,127,680 B** | 0 | preset `binary_format/embed_pck=false`，exe 为固定 Windows 引擎模板，工程内容全在 `.pck`；PE MZ 头 `4d 5a`（"MZ"）已核对 |
| `Aierdengfahuan.pck` | 785,756 B | **993,736 B** | **+207,980 B** | R13~R21 新增脚本/资源进包 |
| `Aierdengfahuan.apk` | 29,024,306 B | **29,239,499 B** | **+215,193 B** | 同上，工程内容变化 |
| `Aierdengfahuan.apk.idsig` | 234,930 B | **234,930 B** | 0 | 时间戳 12:31:11 已刷新；v4 验签 `true` 证明与新 apk 匹配，非旧文件残留 |

新产物时间戳：exe 12:30:10、pck 12:30:19、apk/idsig 12:31:11（旧版均为 07:55/07:56）。

## 4. 验签结果

`apksigner.bat verify --verbose --print-certs`（build-tools 36.1.0，JAVA_HOME=jdk17）：
```
Verifies
Verified using v1 scheme (JAR signing): false
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Verified using v3.1 scheme (APK Signature Scheme v3.1): false
Verified using v4 scheme (APK Signature Scheme v4): false
Number of signers: 1
```
> `v4: false` 仅因默认 verify 未传入 `.idsig` 文件。

追加 `--v4-signature-file Aierdengfahuan.apk.idsig` 后：
```
Verifies
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Verified using v4 scheme (APK Signature Scheme v4): true
Number of signers: 1
```

`aapt.exe dump badging` 首行：
```
package: name='com.aierdengfahuan.game' versionCode='1' versionName='1.0.0' platformBuildVersionName='16' ...
sdkVersion:'24'  targetSdkVersion:'36'
```

**核对结论**：`Verifies` ✓、`v2=true` ✓、`v3=true` ✓（另 `v4=true`）、包名 `com.aierdengfahuan.game` ✓、`versionName 1.0.0` ✓ —— 全部达标。

## 5. 未完成项与阻塞

- **无阻塞**：`--import`、Windows Release 导出、Android Debug 导出、启动验证、验签全部真跑 EXIT=0，四件产物均已按最终工程重导。
- 如实登记的非致命项 / 待办（均不影响本轮交付）：
  1. Android 导出 stdout 出现一条 `ERROR: No project icon specified. Please specify one in the Project Settings under Application -> Config -> Icon`（`export_plugin.cpp:1941`）。Godot 使用模板默认图标继续，导出与签名仍成功、EXIT=0。属工程配置历史遗留，本轮硬约束「不改工程源文件」范围内**未修改**；若须消除，需有权限工位在 `application/config/icon` 补图标后重导。
  2. exe 与 idsig 字节数与旧版完全相同：exe 因 `embed_pck=false` 为固定模板（非陈旧产物）；idsig 字节数恰好不变但时间戳刷新、且 v4 验签 `true` 证实有效。二者均非伪造、非旧文件残留。
  3. editor settings 的 `export/android/java_sdk_path` 仍为历史值 `D:/AndroidDev/jdk-17.0.20.1+1`（实测 java.exe 存在）；本轮按命令要求以 `JAVA_HOME=D:/AndroidToolchain/jdk17` + PATH 注入，Godot 实际调用 `build-tools/36.1.0/apksigner.bat` 完成签名。未改动 editor settings（超出 Rank-4 目录所有权）。
  4. 未执行任何 git 提交；产物按 `.gitignore`（`build/`、`*.exe`、`*.apk`、`*.pck`、`*.log`）排除、不入库。

## 6. 回执

- 已按精确路径写入 `teamwork/command_center/ai/4/outbox/cmd-20261109-122557-230-A4.json`：`{"task_id":"cmd-20261109-122557-230-A4","ai":4,"status":"done","result":"引用 DONE-R21B.md 实际结论：…"}`。
- 调度中枢 dispatcher 于 `2026-11-09 12:37:03` 消费该 outbox 回执并归档到 `teamwork/command_center/dispatcher/receipts/cmd-20261109-122557-230-A4.json`（592 B）；`dispatcher.log` 留有「← 4 号 AI 回执 <cmd-20261109-122557-230-A4> 完成」，`ledger.jsonl` 该条 `status=done`、`finished_at=12:37:03`、`result` 与写入内容逐字一致。`ai/4/status.json` 同步更新为 `state=idle`、`completed=26`。
- 说明：outbox 被消费后为空是本项目 dispatcher 的既定分发行为（历史各 AI 回执均归档在 `dispatcher/receipts/`，outbox 不留文件），**并非回执缺失或路径写错**。为避免产生重复归档副本，未在 outbox 重复写入。回执内容、精确写入路径、中枢接收记录三者均已核实。
