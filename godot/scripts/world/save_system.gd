extends Node
## SaveSystem autoload 装配占位（R8 · Rank-1）
## 注册路径：res://scripts/world/save_system.gd（project.godot [autoload] SaveSystem）
##
## 用途：R7 全工程门禁 18 条 ERROR 中，6 条（G1 3 条 + G3 3 条）来自本 autoload
## 注册路径下全工程根没有任何脚本，导致 autoload 创建 / 实例化失败。
## 本件只做「装配层闭合」——让 5 个 autoload 全部指向工程中实际存在的脚本，
## 不实现任何存档功能，不重做既有交付件。
##
## 归属与边界（契约 I-1 / §6、任务书-R8、MSG-20261109-0249-HOST）：
##  - 存档（SaveDelta 持久化、delta.json 原子写、schema 迁移、单槽回放）归 Rank-3。
##    本占位不读写任何存档文件、不构造 / 解析 SaveDelta、不定义存档格式。
##  - 真实实现由 Rank-3 落位后，由 HOST 裁决把本 autoload 改指向 3 号正式件；
##    本轮不改 scripts/rpg/（3 号所有）、不改其它工位任何文件。
##  - 本件落在 Rank-1 可写的 scripts/world/，未覆盖任何既有文件。

# 装配占位阶段不承载信号与方法；真实接口由 3 号正式件提供后再替换本文件。
func _ready() -> void:
	pass
