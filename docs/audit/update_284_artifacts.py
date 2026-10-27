from pathlib import Path

docs = Path("mod_rebuild/docs")
# 284: final artifact
p = docs / "284-dynamic-pan-cuisine-delight-20261028.md"
t = p.read_text(encoding="utf-8")
t = t.replace("## 6. 产物\n\n待构建完成后补最终 JAR 哈希。", "## 6. 产物\n\n```text\nartifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar\n1,565,831 bytes\nSHA-256 C3726CA1118D808DD9203228163DB8CC588B19D59481F488E99F276D08D86AE5\n```\n\nB 当前资源：490 blockstate、520 block model、644 item model、780 recipe、489 loot、51 TFC food 定义、737 语言键。")
p.write_text(t, encoding="utf-8")

# 280: current counts
p = docs / "280-b-implementation-gap-vs-tech-docs-20261028.md"
t = p.read_text(encoding="utf-8")
t = t.replace(
    "- 当前数据量：清理旧内容并扩展炒锅后为 489 blockstate、503 block model、620 item model、769 recipe、489 loot、52 TFC food 定义、698 item lang keys（旧面团/融化锅/旧可可/旧蛋糕/旧黄油已清理，见 282；炒锅 14 条，见 283）。",
    "- 当前数据量：动态炒锅系统落地后为 490 blockstate、520 block model、644 item model、780 recipe、489 loot、51 TFC food 定义、737 item lang keys（旧面团/融化锅/旧可可/旧蛋糕/旧黄油已清理；动态炒锅见 284）。")
t = t.replace("**K2：已从“单一占位配方”扩展为 14 条真实配方，但仍未实机，不能标为完成。**\n原 `193` 只是 K2 垂直切片；此前把“1 条配方 + 静态构建”写成完成是不合格的，已按 283 更正。",
    "**K2：已重写为 Cuisine Delight 式动态炒锅（多食材/热源/油/锅铲/动态 TFC 营养），但仍未实机，不能标为完成。**\n原 `193` 只是 K2 垂直切片；此前把“1 条配方 + 静态构建”写成完成是不合格的。283 的 14 条静态配方也只是过渡，已由 284 的动态系统替换。")
p.write_text(t, encoding="utf-8")

# 282: artifact/counts -> 284 final
p = docs / "282-cleanup-legacy-kitchen-content-20261028.md"
t = p.read_text(encoding="utf-8")
t = t.replace("| recipe | **769** |", "| recipe | **780** |")
t = t.replace("最终 B 产物（283 炒锅扩展后）：", "最终 B 产物（284 动态炒锅后）：")
t = t.replace("1,513,040 bytes\nSHA-256 7E0521F2C268BD6E43C690368E2136C44BA3B58C57166D1B6811B3FA99458374",
              "1,565,831 bytes\nSHA-256 C3726CA1118D808DD9203228163DB8CC588B19D59481F488E99F276D08D86AE5")
p.write_text(t, encoding="utf-8")

# 281 pointer
p = docs / "281-remove-legacy-dried-items-20261028.md"
t = p.read_text(encoding="utf-8")
t = t.replace("最终产物见 283（1,513,040 bytes / `7E0521F2...`）", "最终产物见 284（1,565,831 bytes / `C3726CA1...`）")
p.write_text(t, encoding="utf-8")

# 279
p = docs / "279-protocol-code-fixes-20261028.md"
t = p.read_text(encoding="utf-8")
t = t.replace("| `artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar` | 1,513,040 B | `7E0521F2C268BD6E43C690368E2136C44BA3B58C57166D1B6811B3FA99458374` |",
              "| `artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar` | 1,565,831 B | `C3726CA1118D808DD9203228163DB8CC588B19D59481F488E99F276D08D86AE5` |")
p.write_text(t, encoding="utf-8")

# README
p = Path("mod_rebuild/README.md")
t = p.read_text(encoding="utf-8")
t = t.replace("B: artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar    1,513,040 bytes\n   SHA-256 7E0521F2C268BD6E43C690368E2136C44BA3B58C57166D1B6811B3FA99458374",
              "B: artifacts/TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar    1,565,831 bytes\n   SHA-256 C3726CA1118D808DD9203228163DB8CC588B19D59481F488E99F276D08D86AE5")
p.write_text(t, encoding="utf-8")
print("updated artifacts/counts")
