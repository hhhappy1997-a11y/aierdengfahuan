extends Resource
class_name M6AreaBindings

## R4 补齐件：M6 赐福传送网络的「区域接入」数据表（任务书-R4.md 交付清单第 2 行）。
## R2 `grace_network.tres`（8 节点 / 7 边）已是 M6 完整节点图，本件**不重做、不改写**，
## 只补齐「3~4 区域 + 2 地牢 + 1 地下入口」到引擎侧的接入映射，供联调对账：
##   area_id → ChunkManager.region → 初始 chunk 原点 → 场景路径 → 该区域赐福节点 → 边界 flag。
## 与 grace_network.tres 的关系：grace_ids / boundary_flags 逐条引用现有节点与边条件，不新增节点 / 边。
##
## 字段语义（bindings 元素为 Dictionary，.tres 手写零歧义，与 grace_network.tres 的 edges 同构）：
##   area_id          String   与 grace_network.tres 各 GraceNode.area_id 对齐
##   region           String   切区域时喂给 ChunkManager.region（chunk_streaming.gd:24，_make_id 用它拼 chunk id）
##   chunk_origin_x   int      该区域初始 set_player_chunk 的 x（默认 0）
##   chunk_origin_y   int      该区域初始 set_player_chunk 的 y（默认 0）
##   scene_path       String   与 GraceNode.scene_path 对齐（SceneRouter 传送 / 短加载落点）
##   grace_ids        Array    该区域挂接的 grace_id（String 数组，引用 grace_network.tres 节点）
##   boundary_flags   Array    接入传送网的前置三段式 flag（引用 grace_network.tres requires_flags / edges）
##   is_dungeon       bool     地牢独立场景（不走 chunk 网格）
##   is_underground   bool     地下入口 / 地下区域
##
## 中文 UTF-8；Godot 4 全静态类型；零付费 / 零外部依赖。

@export var network_id: String = ""       # 关联的 GraceNetwork.network_id
@export var bindings: Array = []          # 元素 Dictionary（见上）
