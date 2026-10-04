# 猎归

原创横版清版动作的 Godot 4 单体仓库。玩家是猎人林狩。试玩只有第一关「猎归」：在荆丛猎场打野兽，地面攻击是三连。

没有坐骑，也没有全屏慢动作。林狩与刺脊兽已有透明底 PNG 立绘（`game/sprites/`），开场有约 5 秒中文过场。

## 用 Godot 打开

1. 安装 [Godot 4.3](https://godotengine.org/) 或同代 4.x。不要用 Godot 3。
2. 打开 Godot 项目管理器，选「导入」，指向本仓库里的 `game/project.godot`。
3. 导入的是 `game/` 这一层，不是仓库根目录。
4. 主场景是 `scenes/intro.tscn`（过场后进入 `scenes/level1.tscn`）。按 F5 运行。

不需要 Node、pnpm 或 npm。

命令行自检（已装 4.3 时）：

```bash
godot --headless --path game --quit
godot --headless --path game --script res://scripts/combat_check.gd
```

## 试玩怎么操作

开场文字期间可按 **J** 或 **Enter** 跳过，直接进关。

| 键 | 作用 |
| --- | --- |
| A / D，或 ← / → | 沿猎场左右走 |
| W / S，或 ↑ / ↓ | 前后纵深（W/↑ 远离，S/↓ 靠近） |
| J | 地面攻击（过场里也用于跳过） |
| K（或空格） | 跳跃。跳起时打不中地面连段，野兽的扑咬也会落空 |
| 第三击起手时按住 ↑ | 向背后投 |
| 第三击起手时按住 ↓ | 向面朝的方向投 |
| ↑ 和 ↓ 同时按住 | 算向后投 |
| 第三击起手时松开 ↑ / ↓ | 第三击把猎物打倒 |
| R | 重开本关 |

屏幕上始终有虚拟摇杆区（左：方向，右：J 攻击 / K 跳跃），触屏与鼠标都可用。

口诀：**A/D 移动，W/S 前后，J 攻击，K 跳跃。第三下按住上或下是投。**

W 和 S 只负责前后，不决定投技。投技只看方向键上/下（以及虚拟摇杆上/下）。

连段规则见 `docs/setting/combat.md`。第一击或第二击必须先打中，再在短窗口里按 J，才会出下一击。打空就回到第一击。

清掉三头野兽即过关。这一关走不到猎户村。

中文界面字体为 `game/fonts/NotoSansSC-Regular.ttf`（Noto Sans SC 子集，OFL），已设为默认 Theme 字体，Web 导出不依赖系统字体。

## Web 导出（仅本机）

仓库里已有一次本机 HTML5 导出（**关闭线程**，无需 SharedArrayBuffer / Cross-Origin-Isolation）：

- 目录：`build/web/`（入口 `index.html`，另有 `.wasm` / `.pck` / `.js`）
- **只在本机可用**，没有公开网址。要给别人玩，需自行把该目录放到静态托管。

本机预览示例：

```bash
cd build/web && python3 -m http.server 8080
# 浏览器打开 http://127.0.0.1:8080/
```

重新导出（需 Godot 4.3 与同版本 Web 导出模板，且已装 `web_nothreads_release`）：

```bash
godot --headless --path game --export-release "Web" ../build/web/index.html
```

导出预设在 `game/export_presets.cfg`，`variant/thread_support=false`。

## 目录

```
README.md
docs/setting/     设定（中文）
game/             Godot 4.3 工程
  project.godot
  scenes/         过场、关卡、角色、野兽、界面
  scripts/
  sprites/        player.png / beast.png
build/web/        本机 HTML5 导出（未托管）
```

## 立绘

- `game/sprites/player.png` — 林狩侧视，默认朝右，约 96px 高，透明底
- `game/sprites/beast.png` — 刺脊兽侧视，默认朝右（脚本按 facing 翻转），约 64px 高

脚本已按路径加载；无图时仍回退色块占位。
