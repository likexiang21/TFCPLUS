#!/usr/bin/env python3
"""Build the archived documentation index and inventory index."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
ARCHIVE = DOCS / "archive"
OLD_DOCS = ROOT.parent / "moddev" / "docs"
OLD_INVENTORY = ROOT.parent / "moddev" / "inventory"


def category(number: int | None) -> str:
    if number is None:
        return "未分类"
    if number < 30:
        return "架构 / API / 脚手架"
    if number < 60:
        return "Firmalife / Patchouli"
    if number < 80:
        return "作物 / 植物"
    if number < 100:
        return "贴图 / 渲染"
    if number < 130:
        return "轮次 / 交接"
    if number < 200:
        return "农业实现"
    if number < 245:
        return "近期 / 验证"
    return "未分类"


def number_of(name: str) -> int | None:
    match = re.match(r"(\d+)", name)
    return int(match.group(1)) if match else None


def title_of(path: Path) -> str:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = path.read_text(encoding="utf-8", errors="replace")
    if path.suffix.lower() == ".json": return path.stem
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("#"):
            value = line.lstrip("#").strip(); return value if value and value != "---" else path.stem
        if line and line != "---":
            return line[:120]
    return path.stem


def build_archive_index() -> None:
    files = sorted(
        [path for path in ARCHIVE.iterdir() if path.is_file() and path.suffix.lower() in (".md", ".txt", ".json")],
        key=lambda path: (number_of(path.name) is None, number_of(path.name) or 9999, path.name),
    )
    groups: dict[str, list[Path]] = {}
    for path in files:
        groups.setdefault(category(number_of(path.name)), []).append(path)
    order = [
        "架构 / API / 脚手架",
        "Firmalife / Patchouli",
        "作物 / 植物",
        "贴图 / 渲染",
        "轮次 / 交接",
        "农业实现",
        "近期 / 验证",
        "未分类",
    ]
    lines = [
        "# 旧文档库归档索引",
        "",
        "> 本目录是 `moddev/docs` 的完整归档副本（226 个文件，字节级复制），用于保留历史上下文。",
        "> **它不是当前开发规范**；当前规范看 `../README.md`、`../273-...` 和 `../274-...`。",
        "> 归档文档之间的相对链接、旧类名、旧路径可能仍指向 `moddev` 时代内容，未逐篇重写。",
        "",
        "## 分类统计",
        "",
        "| 分类 | 文件数 |",
        "|---|---:|",
    ]
    for group in order:
        if group in groups:
            lines.append(f"| {group} | {len(groups[group])} |")
    lines.append(f"| **合计** | **{len(files)}** |")
    lines.append("")
    for group in order:
        if group not in groups:
            continue
        lines.extend([f"## {group}", "", "| 文件 | 标题 |", "|---|---|"])
        for path in groups[group]:
            title = title_of(path).replace("|", "\\|")
            lines.append(f"| [{path.name}](archive/{path.name}) | {title} |")
        lines.append("")
    (DOCS / "ARCHIVE-INDEX.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def build_inventory_index() -> None:
    dirs = sorted([path for path in OLD_INVENTORY.iterdir() if path.is_dir()], key=lambda path: path.name)
    lines = [
        "# 旧证据 inventory 索引",
        "",
        "> 旧证据目录未复制进 `mod_rebuild`，以节省 32.5 MB 非源码数据；此索引链接到 `moddev/inventory`。",
        "> 这些是历史验证/渲染证据，不是新版开发规范。",
        "",
        f"共 **{len(dirs)}** 个目录。",
        "",
        "| 目录 | 文件数 | 大小 |",
        "|---|---:|---:|",
    ]
    for path in dirs:
        files = [item for item in path.rglob("*") if item.is_file()]
        size = sum(item.stat().st_size for item in files)
        lines.append(f"| [{path.name}](../../moddev/inventory/{path.name}) | {len(files)} | {size / 1024 / 1024:.1f} MB |")
    lines.append("")
    (DOCS / "INVENTORY.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    build_archive_index()
    build_inventory_index()
    print("wrote docs/ARCHIVE-INDEX.md and docs/INVENTORY.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
