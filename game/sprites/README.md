# 立绘投放

试玩用的是 `cut/` 里已经抠好透明的图，脚本 `preload`，绘制时缩放到关卡里的大小。不要用 `FileAccess.file_exists` 判断这些图在不在：导出后源文件路径不在 pck 里，之前因此退回了色块。

- `cut/hunter_idle.png` — 站立。`hunter_walk_a.png`、`hunter_walk.png`、`hunter_walk_b.png` — 移动时按这个顺序循环。`hunter_atk1.png`、`hunter_atk2.png`、`hunter_atk3.png` — 三连各一帧。`hunter_jump_up.png`、`hunter_jump.png`、`hunter_jump_down.png` — 起跳、最高点、下落。都朝右、透明底，脚点对齐，共用比例后站立约 96 像素高。朝左时水平翻转。
- `cut/boar.png` — 野猪，透明底，原图朝左（脚本镜像成朝右），高度约 72 像素。
- `cut/bush.png` — 一丛荆条，透明底，放在原先色块荆丛的位置，高度约 58 像素。
- `cut/bg_hunt.jpg` — 猎场原画。关卡把它拆成 `bg_far.png`（天和远山，几乎不动）和 `bg_mid.png`（树、篱笆、牌楼，慢移）。
- `cut/bg_far.png` / `cut/bg_mid.png` — 上面两层，不挂在镜头上。
- `cut/lane_tile.jpg` — 脚下土路，左右重复，和人、野猪同一速度。纵深碰撞仍是代码里的车道范围。

`hunter/` 和 `player.png`、`beast.png`、`bg_hunt.png` 是上一版，关卡不再引用。
