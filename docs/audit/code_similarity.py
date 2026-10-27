import re
from pathlib import Path


def tokens(path):
    text = path.read_text(encoding="utf-8", errors="ignore")
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//.*", "", text)
    text = re.sub(r'"(?:\\.|[^"\\])*"', '"S"', text)
    text = re.sub(r"'(?:\\.|[^'\\])*'", "'C'", text)
    return re.findall(r"[A-Za-z_$][A-Za-z0-9_$]*|[0-9]+", text)


def shingles(values, n=5):
    return {tuple(values[i:i + n]) for i in range(max(0, len(values) - n + 1))}


def jaccard(left, right):
    if not left or not right:
        return 0.0
    return len(left & right) / len(left | right)


refs = []
for root in ("de_moddev/src-ref/TFC-decompiled", "de_moddev/src-ref/Firmalife"):
    for path in Path(root).rglob("*.java"):
        refs.append((path, tokens(path)))

projects = []
for root in (
    "mod_rebuild/tfcfarmingplus/src/main/java",
    "mod_rebuild/tfcagricultureplus/src/main/java",
):
    projects.extend(Path(root).rglob("*.java"))

results = []
for path in projects:
    current = tokens(path)
    current_shingles = shingles(current)
    best_score = 0.0
    best_ref = None
    for ref, ref_tokens in refs:
        if abs(len(current) - len(ref_tokens)) > max(200, len(current)):
            continue
        score = jaccard(current_shingles, shingles(ref_tokens))
        if score > best_score:
            best_score = score
            best_ref = ref
    results.append((best_score, path, best_ref))

for score, path, ref in sorted(results, reverse=True)[:30]:
    ref_name = ref.relative_to("de_moddev/src-ref") if ref else "<none>"
    print(f"{score:.3f} {path.relative_to('mod_rebuild')} <= {ref_name}")
