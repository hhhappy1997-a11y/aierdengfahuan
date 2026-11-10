# -*- coding: utf-8 -*-
# HOST 自动化 2026-11-10 20:47 圈留痕：台账 §7 一行 + 总线一条（append-only）
# 仅追加、带幂等与顺序断言；二进制读写保留 CRLF；写完即由外层删除。
import os, re

BASE = r'F:\Game\aierdengfahuan\teamwork'
LEDGER = os.path.join(BASE, '00-进度台账.md')
BUS = os.path.join(BASE, '00-群聊总线.md')

ROW_HEAD = '| 2026-11-10 20:47 | '
MSG_HEAD = '## MSG-20261110-2047-HOST'
MSG_FULL_TITLE = MSG_HEAD + ' · 2026-11-10 20:47 · HOST → ALL'

row = (
    '| 2026-11-10 20:47 | **自动化本圈：调度中枢恢复在线（相对 19:41 连接拒绝型连续第 3 圈的状态翻转），'
    '按第 1~8 步全闭环执行 —— 动态判定当前轮次 R25 / R25B，启动 5 路执行 AI 真跑并全部收口，不续派 R26（空转保护）**。'
    '20:47 `GET /api/state` 返回 `HTTP 200`、305605 B，`AierdengfahuanCommander.exe` 进程在、8765 LISTENING；'
    '触发快照 `total=95/done=91/working=4/failed=0`、`demo=false`、`space=teamwork/command_center` 正确 → 未 POST `/api/config`。'
    '逐条解析 ledger 4 条 `status!=done` 全部为 `[ROUND=R25]`（总指挥 20:46:05 GUI 亲自派发：'
    '`cmd-20261110-204604-819-A1` / `823-A2` / `840-A3` / `844-A4`），4 份 `DONE-R25.md` 全缺、无任务书文件（正文自包含在 `调度任务单-latest.json`，4 份 id 与 ledger 一致）'
    '→ 按第 6 步并行启动 **4 路 R25 执行 AI** 真跑：Rank-1 `run/main_scene` 改指 courtyard.tscn + Boss 可见形象接线（ViewImage 实证第二角色）；'
    'Rank-2 A13 落地 + 削韧/异常/处决接入（v030 53 PASS/0 FAIL）；Rank-3 裁决 A15 契约口径 + 三段式 flag 登记（16 PASS、31 PASS 不回退）；'
    'Rank-4 16 色受控色板重绘 15 张 PNG + 450 帧录屏（47/34 PASS 不回退）。四路三段门禁 `SCRIPT ERROR=0`，4 份 `DONE-R25.md` 齐备、'
    '4 份回执按各自本轮 id 写入 outbox 并被中枢消费归档 `dispatcher/receipts/`，4 条命令全转 `done`。'
    '收口前重取 `/api/state` 发现总指挥 21:47:28 并发新派 `[ROUND=R25B]` 给 Rank-4（`cmd-20261110-214727-361-A4`、DONE 缺、无回执）'
    '→ 按 05:00 圈 R12 先例**补拉第 5 路执行 AI**，真跑收口：450 帧 `v030_final.mp4`(867453 B)、Boss 首/中/尾三帧可见、'
    '双产物重导 exe/pck/apk/idsig 字节数与验签 v2+v3 true / 包名 `com.aierdengfahuan.game` 如实登记、HD-2D 全绿未达与中帧 death 不可辨如实写未达；'
    '`DONE-R25B.md` 与回执齐备。并发保护全程生效（R25B 由并发实例写齐，本实例只复核不重做、不写第二份回执）。'
    '**HOST 未 POST /api/issue、未代写任何回执、未伪造真跑结论**：R25 与 R25B 均由总指挥亲自派单，HOST 不抢派；'
    '第 3 步无「DONE 已存在但 working」的路 → 不写回执；第 4 步 `[ROUND=R26]` / `[ROUND=R25C]` / `[ROUND=R27]` 精确标记 0 命中、'
    '8 份下一轮任务书全缺，但按 §3 任务池核对 4 份 DONE 剩余项全为 `128bit` 待用户确认 / 人工试玩属用户侧(A17) / HD-2D 全绿未达(画面审美验收) / '
    '需总指挥裁决项，且总指挥在场连续亲自派单（20:46 R25 → 21:47 R25B）→ **空转保护，不续派、不生成空任务书、等待总指挥给新方向**。'
    '终态 `/api/state`：`total=96/done=96/working=0/failed=0`、4 路 idle、`demo=false` / space 正确、ledger 96 条无 `status!=done`、'
    '末条 `cmd-20261110-214727-361-A4`(R25B) 22:00:55 done。**本圈动作 = 5 路执行 AI + 台账 §7 本行 + 总线 `MSG-20261110-2047-HOST` 一条 + 按第 8 步上传仓库**；'
    '推送结果在 §9 回填，失败如实登记待重推、不谎报成功。零付费、零外部依赖、默认不刺探、不改 4 路既有产出、'
    '不生成 `00-汇总.md`、不对跨模块争议裁决、未启动第二个 GPU job；总指挥回来后以总指挥口径为准 |'
)

msg = (
    '\n## MSG-20261110-2047-HOST · 2026-11-10 20:47 · HOST → ALL\n'
    '- TYPE: 通知（中枢恢复在线 · 状态翻转 · R25/R25B 全闭环收口；非静默圈）\n'
    '- REF: /api/state（HTTP 200 / 触发 95/91/4/0 → 终态 96/96/0/0），00-进度台账.md §7，MSG-20261110-1941-HOST，'
    'cmd-20261110-204604-819-A1/823-A2/840-A3/844-A4，cmd-20261110-214727-361-A4\n'
    '- BODY: **HOST 自动化本圈：调度中枢自 19:41 连续不可达后恢复在线，按第 1~8 步执行完整闭环，5 路执行 AI 全部真跑收口，不续派 R26**。'
    '20:47 `GET http://127.0.0.1:8765/api/state` 返回 `HTTP 200`（305605 B），`demo=false` / `space=teamwork/command_center` 正确、未 POST `/api/config`；'
    '触发快照 `total=95/done=91/working=4/failed=0`。动态逐条解析 ledger：4 条 `status!=done` 全为 `[ROUND=R25]`（总指挥 20:46:05 GUI 亲自派发），'
    '4 份 `DONE-R25.md` 全缺、无任务书文件（真源为 `调度任务单-latest.json`，id 与 ledger 一致）→ 按第 6 步并行启动 **4 路 R25 执行 AI**：'
    'Rank-1 入口改 courtyard.tscn + Boss 可见形象（ViewImage 实证第二角色）、Rank-2 A13 + 削韧/异常/处决（v030 53 PASS）、'
    'Rank-3 A15 契约口径 + 三段式 flag（16/31 PASS 不回退）、Rank-4 16 色重绘 15 张 PNG + 450 帧录屏（47/34 PASS 不回退）；'
    '四路三段门禁 `SCRIPT ERROR=0`、4 份 DONE 齐备、4 份回执按各自本轮 id 写入并被中枢消费归档、4 条命令全 `done`。'
    '收口前重取 state 发现总指挥 21:47:28 并发新派 `[ROUND=R25B]`（Rank-4，DONE 缺、无回执）→ 按 05:00 圈先例**补拉第 5 路执行 AI**：'
    '450 帧 `v030_final.mp4`、Boss 三帧可见、双产物重导与 apksigner 验签 v2+v3 true / 包名 `com.aierdengfahuan.game` 如实登记，'
    'HD-2D 全绿未达与中帧 death 不可辨如实写未达；`DONE-R25B.md` 与回执齐备（并发实例写齐，本实例只复核不重做、不写第二份回执）。'
    '**HOST 未 POST /api/issue、未代写回执、未伪造结论**（R25/R25B 均总指挥亲自派单，HOST 不抢派）；'
    '无「DONE 已存在但 working」→ 不写回执；`[ROUND=R26]`/`[ROUND=R25C]`/`[ROUND=R27]` 精确标记 0 命中、8 份下一轮任务书全缺，'
    '但 §3 任务池剩余项全为 `128bit` 待确认 / 人工试玩属用户侧 / HD-2D 全绿未达 / 需裁决项，且总指挥在场连续亲自派单 → '
    '**空转保护，不续派、不硬造空任务，等待总指挥给新方向**。终态 `total=96/done=96/working=0/failed=0`、4 路 idle、ledger 无待办。'
    '本圈留痕 = 台账 §7 一行 + 本条通知，并按第 8 步 `git add -A` → commit → `git push origin main`（结果回填 §9，失败如实登记、不谎报成功）。'
    '零付费、零外部依赖、默认不刺探、不改 4 路既有产出、不生成 `00-汇总.md`、不裁决跨模块争议、未启动第二个 GPU job；总指挥回来后以总指挥口径为准。\n'
    '- STATUS: OPEN\n'
)

def read_bytes(p):
    with open(p, 'rb') as f:
        return f.read()

def write_bytes(p, b):
    with open(p, 'wb') as f:
        f.write(b)

# ---- 台账 §7：在 §8 标题前插入一行，断言位于 §7 内且唯一 ----
b = read_bytes(LEDGER)
nl = b'\r\n' if b'\r\n' in b else b'\n'
sec8 = '## 8. 每次更新的收尾动作'.encode('utf-8')
assert b.count(sec8) == 1, 'LEDGER sec8 anchor not unique'
sec7 = '## 7. 变更记录'.encode('utf-8')
assert b.count(sec7) == 1, 'LEDGER sec7 anchor not unique'
assert b.index(sec7) < b.index(sec8), 'LEDGER sec7/sec8 order broken'
if ROW_HEAD.encode('utf-8') in b:
    print('LEDGER row already exists -> SKIP')
else:
    row_b = row.encode('utf-8')
    pos = b.index(sec8)
    # 插到 §8 标题所在行的行首之前，保证新行在 §7 内
    line_start = b.rfind(nl, 0, pos)
    insert_at = line_start + len(nl) if line_start >= 0 else 0
    new = b[:insert_at] + row_b + nl + nl + b[insert_at:]
    assert new.count(ROW_HEAD.encode('utf-8')) == 1, 'LEDGER row not unique after insert'
    assert new.index(ROW_HEAD.encode('utf-8')) > new.index(sec7), 'LEDGER row not in sec7'
    assert new.index(ROW_HEAD.encode('utf-8')) < new.index(sec8), 'LEDGER row not before sec8'
    write_bytes(LEDGER, new)
    print('LEDGER sec7 row appended OK')

# ---- 总线：末尾追加，按完整标题行断言顺序（1941 < 2047）且唯一 ----
b = read_bytes(BUS)
heads = re.findall(rb'## MSG-[0-9]+-[0-9]+-HOST', b)
assert len(heads) > 0, 'BUS no MSG heads'
last_head = heads[-1].decode('ascii')
assert b'## MSG-20261110-1941-HOST' in last_head.encode('ascii'), 'BUS last head not 1941: ' + last_head
if MSG_HEAD.encode('ascii') in b:
    print('BUS msg already exists -> SKIP')
else:
    msg_b = msg.encode('utf-8')
    # 文件末尾若已有换行则不加多余空行；统一用文件自身行尾
    if nl == b'\r\n':
        msg_b = msg_b.replace(b'\n', b'\r\n')
    if b.endswith(nl):
        new = b + msg_b.lstrip(nl)
    else:
        new = b + nl + msg_b.lstrip(nl)
    heads2 = re.findall(rb'## MSG-[0-9]+-[0-9]+-HOST', new)
    assert new.count(MSG_HEAD.encode('ascii')) == 1, 'BUS msg not unique after append'
    assert heads2[-1].decode('ascii') == '## MSG-20261110-2047-HOST', 'BUS new msg not last'
    assert new.index(b'## MSG-20261110-1941-HOST') < new.index(MSG_HEAD.encode('ascii')), 'BUS order 1941 < 2047 broken'
    write_bytes(BUS, new)
    print('BUS MSG-20261110-2047-HOST appended OK, order 1941 < 2047')

print('DONE')
