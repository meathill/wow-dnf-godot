#!/usr/bin/env python3
"""Point the Godot 4.3 web shell at visualViewport so landscape phones fill the visible area."""
import sys
from pathlib import Path

OLD = "if(isFullscreen||wantsFullWindow){width=window.innerWidth*scale;height=window.innerHeight*scale}"
NEW = (
    "if(isFullscreen||wantsFullWindow){"
    "var __vv=window.visualViewport;"
    "var __w=(__vv&&__vv.width)||window.innerWidth;"
    "var __h=(__vv&&__vv.height)||window.innerHeight;"
    "width=__w*scale;height=__h*scale}"
)


def main() -> None:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "build/web/index.js")
    text = path.read_text(encoding="utf-8")
    count = text.count(OLD)
    if count != 1:
        if NEW in text:
            print("already patched", path)
            return
        raise SystemExit(f"expected 1 canvas-size pattern in {path}, found {count}")
    path.write_text(text.replace(OLD, NEW, 1), encoding="utf-8")
    print("patched", path)


if __name__ == "__main__":
    main()
