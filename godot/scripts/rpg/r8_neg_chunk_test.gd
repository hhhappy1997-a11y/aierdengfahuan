extends SceneTree

## R8 · Rank-3 负坐标 chunk_id 归一验证载体（工程根 res:// 内真跑，--script 运行）。
## 用途：主动验证 R8 归一方案（sanitize_flag_segment / normalize_chunk_flag /
## normalize_flag_key）对负坐标 chunk_id 的产物是 I-1 合法三段式；并验证正坐标产物
## 与 R7 基线逐字一致（既有 45 项断言零回归）、I-1 首段白名单未被擅自扩展。
## 本件是 R8 联调验证载体，不是刺探 / 巡检 / 测量 / preflight 脚本；
## 不写 project.godot、不改任何既有交付件、不直接读写存档文件、不启动任何 GPU job。
## 中文 UTF-8；Godot 4 合法语法。输出统一 R8_NORM_ 前缀，便于 grep 归因。

var _pass: int = 0
var _fail: int = 0


func _ck(tag: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("R8_NORM_PASS %s | %s" % [tag, detail])
	else:
		_fail += 1
		print("R8_NORM_FAIL %s | %s" % [tag, detail])


func _initialize() -> void:
	# 1) R7 §2 实测的两种负坐标 + 多位数负坐标：归一产物必须合法三段式、不含 '-'
	var neg_cases: Array = [
		["chunk_limgrave_-1_-1", "world.chunk_limgrave_neg1_neg1.loaded"],
		["chunk_limgrave_0_-1", "world.chunk_limgrave_0_neg1.loaded"],
		["chunk_limgrave_-12_-3", "world.chunk_limgrave_neg12_neg3.loaded"]
	]
	for c in neg_cases:
		var cid: String = String(c[0])
		var expect: String = String(c[1])
		var key: String = ChunkWorldBridge.normalize_chunk_flag(cid)
		_ck("R8_NORM_KEY_%s" % cid, key == expect, "%s -> %s (expect %s)" % [cid, key, expect])
		_ck("R8_NORM_VALID_%s" % cid, ChunkWorldBridge.is_valid_flag_key(key), "is_valid_flag_key(%s)=true" % key)
		_ck("R8_NORM_NOHYPHEN_%s" % cid, key.find("-") == -1, "no '-' in %s" % key)

	# 2) 正坐标回归：产物与 R7 基线逐字一致（既有 45 项断言零回归）
	var pos_key: String = ChunkWorldBridge.normalize_chunk_flag("chunk_limgrave_0_0")
	_ck("R8_NORM_POS_REGRESSION", pos_key == "world.chunk_limgrave_0_0.loaded", "pos=%s (R7 baseline)" % pos_key)

	# 3) normalize_flag_key 对含负坐标的原始 key 也收敛为合法三段式
	var nk: String = ChunkWorldBridge.normalize_flag_key("chunk.chunk_limgrave_0_-1.loaded")
	_ck("R8_NORM_FLAGKEY_NEG", nk == "world.chunk_limgrave_0_neg1.loaded", "normalize_flag_key=%s" % nk)
	_ck("R8_NORM_FLAGKEY_VALID", ChunkWorldBridge.is_valid_flag_key(nk), "is_valid_flag_key(%s)=true" % nk)
	_ck("R8_NORM_FLAGKEY_4SEG", ChunkWorldBridge.normalize_flag_key("a.b.c.d") == "", "4-segment raw -> empty (unchanged)")
	_ck("R8_NORM_FLAGKEY_LEGAL", ChunkWorldBridge.normalize_flag_key("world.chunk_limgrave_0_0.loaded") == "world.chunk_limgrave_0_0.loaded", "legal key unchanged")

	# 4) sanitize_flag_segment 基础性质
	_ck("R8_NORM_SEG_NEG", ChunkWorldBridge.sanitize_flag_segment("-1") == "neg1", "-1 -> neg1")
	_ck("R8_NORM_SEG_IDEMPOTENT", ChunkWorldBridge.sanitize_flag_segment("neg1") == "neg1", "idempotent")
	_ck("R8_NORM_SEG_DROP", ChunkWorldBridge.sanitize_flag_segment("A.b") == "b", "illegal chars dropped")

	# 5) 待裁决项 B 未擅改：chunk.* 原始首段仍非法（白名单未扩展）
	_ck("R8_NORM_RAW_STILL_INVALID", not ChunkWorldBridge.is_valid_flag_key("chunk.chunk_limgrave_0_0.loaded"), "chunk.* raw first-segment still invalid (I-1 whitelist unchanged)")

	print("R8_NORM_SUMMARY pass=%d fail=%d" % [_pass, _fail])
	quit()
