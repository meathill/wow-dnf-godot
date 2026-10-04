# 立绘投放

试玩用的是 `cut/` 里已经抠好透明的图，脚本 `preload`，绘制时缩放到关卡里的大小。不要用 `FileAccess.file_exists` 判断这些图在不在：导出后源文件路径不在 pck 里，之前因此退回了色块。

- `cut/hunter_idle.png` `hunter_walk.png` `hunter_attack.png` `hunter_jump.png` — 林狩四帧，朝右，透明底。关卡里高度约 96 像素，宽按比例。仍着地用 idle，移动用 walk，挥击用 attack，离地用 jump。朝左时水平翻转。
- `cut/boar.png` — 野猪，透明底，原图朝左（脚本镜像成朝右），高度约 72 像素。
- `cut/bush.png` — 一丛荆条，透明底，放在原先色块荆丛的位置，高度约 58 像素。
- `cut/bg_hunt.jpg` — 猎场远景（不透明整幅），铺在镜头后。纵深碰撞仍是代码里的车道范围。

`hunter/` 和 `player.png`、`beast.png`、`bg_hunt.png` 是上一版，关卡不再引用。
