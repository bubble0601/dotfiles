"""spec.json と各タブの HTML 断片から、資料の HTML を組み立てる。

使い方:
  python3 build.py path/to/spec.json out.html

spec.json の形は examples/legal-dayoff/spec.json を参照。overview / feature / notes / extra_script / cases の
パスは spec.json のある場所からの相対パス。組み立てたあと、ページ内のスクリプトに構文の誤りが無いかを
node で確かめる(node が無ければ確かめずに終える)。
"""

import json
import os
import shutil
import subprocess
import sys

TEMPLATE = os.path.join(os.path.dirname(__file__), "..", "assets", "template.html")
REQUIRED = ["title", "eyebrow", "headline", "key", "copy_title", "overview", "feature", "notes", "cases"]


def read(base: str, rel: str) -> str:
    with open(os.path.join(base, rel), encoding="utf-8") as f:
        return f.read().rstrip("\n")


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    spec_path, out_path = sys.argv[1], sys.argv[2]
    base = os.path.dirname(os.path.abspath(spec_path))
    spec = json.load(open(spec_path, encoding="utf-8"))
    missing = [k for k in REQUIRED if k not in spec]
    if missing:
        print(f"spec.json に足りない項目: {', '.join(missing)}", file=sys.stderr)
        return 1

    cases = []
    for rel in spec["cases"]:
        cases.extend(json.load(open(os.path.join(base, rel), encoding="utf-8")))
    # </script> を本文に含めるとスクリプトが途中で切れるため、</ を逃がす
    cases_json = json.dumps(cases, ensure_ascii=False).replace("</", "<\\/")

    page = open(TEMPLATE, encoding="utf-8").read()
    values = {
        "TITLE": spec["title"],
        "EYEBROW": spec["eyebrow"],
        "HEADLINE": spec["headline"],
        "META": spec.get("meta_html", ""),
        "KEY": spec["key"],
        "COPY_TITLE": spec["copy_title"],
        "OVERVIEW": read(base, spec["overview"]),
        "FEATURE": read(base, spec["feature"]),
        "NOTES": read(base, spec["notes"]),
        "EXTRA_SCRIPT": read(base, spec["extra_script"]) if spec.get("extra_script") else "",
        "CASES_JSON": cases_json,
    }
    for name, value in values.items():
        page = page.replace("{{" + name + "}}", value)
    if "{{" in page and "}}" in page[page.index("{{"):]:
        leftover = page[page.index("{{"): page.index("{{") + 40]
        print(f"埋まっていない印があります: {leftover}", file=sys.stderr)
        return 1

    # 公開先によってはページの外枠を足さないため、文字コードの指定が無いと UTF-8 以外で読まれて
    # 文字化けし、スクリプトが構文エラーで止まる(node の構文チェックは UTF-8 で読むので気づけない)
    head = page[:400].lower()
    if not head.startswith("<!doctype html>") or '<meta charset="utf-8">' not in head:
        print("雛形の先頭に <!DOCTYPE html> と <meta charset=\"utf-8\"> がありません", file=sys.stderr)
        return 1

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(page)
    print(f"{out_path} を書きました(テストケース {len(cases)} 件、{len(page.encode()) // 1024} KB)")

    node = shutil.which("node")
    if node is None:
        print("node が無いため、スクリプトの構文は確かめていません")
        return 0
    script = page.split("<script>")[1].split("</script>")[0]
    check = subprocess.run(
        [node, "-e", "new Function(require('fs').readFileSync(0, 'utf8'))"],
        input=script, text=True, capture_output=True,
    )
    if check.returncode != 0:
        print("ページ内のスクリプトに構文の誤りがあります:\n" + check.stderr, file=sys.stderr)
        return 1
    print("ページ内のスクリプトの構文: 問題なし")
    return 0


if __name__ == "__main__":
    sys.exit(main())
