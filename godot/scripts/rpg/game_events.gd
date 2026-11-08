extends Node

## I-2 信号总线（R2 临时口径 §3 第 3 条）：由 1 号注册为 GameEvents autoload、3 号实现。
## 击杀信号参数一律单个 String（数据表 id），不是 StringName / Dictionary / 不带第二参数。
## 击杀 flag 只由 3 号 SaveDeltaWriter 写；2 号只发信号不双写，避免 seq 重复。
## 本节点只承载信号，不写任何 flag、不碰存档文件。

signal enemy_defeated(enemy_id: String)
signal boss_defeated(boss_id: String)
signal dungeon_transition_requested(dungeon_id: String, direction: String)  # direction: "enter" / "exit"
signal travel_requested(target_grace_id: String)
