"""E2E テストケース md(21 列の HTML table)から行を抜き出し、資料のテストケース表用の JSON にする。

使い方:
  python3 extract_cases.py docs/e2e/従業員区分-v2.md --match LEGAL-DAYOFF --group 従業員区分 -o cases-screen.json

--match はテスト ID に対する正規表現。--group は表の見出し行とコピーの見出しに出る名前。
"""

import argparse
import html
import json
import re
import sys

# e2e-case-writer-output-format の列順(0 始まり)
COL_ID, COL_RANK, COL_AUTO = 0, 1, 5
COL_SCREEN, COL_AREA = 9, 10
COL_PURPOSE, COL_PRE, COL_STEPS, COL_EXP, COL_NOTE = 12, 13, 14, 15, 16


def split_items(cell: str) -> list[str]:
    """<br> 区切りの番号付きリストを、番号を外した文の配列にする"""
    items = []
    for part in cell.split("<br>"):
        text = html.unescape(re.sub(r"<[^>]+>", "", part)).strip()
        if text:
            items.append(re.sub(r"^\d+\.\s*", "", text))
    return items


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("md")
    parser.add_argument("--match", required=True, help="テスト ID に対する正規表現")
    parser.add_argument("--group", required=True, help="表の見出し行に出す名前")
    parser.add_argument("-o", "--output", required=True)
    args = parser.parse_args()

    source = open(args.md, encoding="utf-8").read()
    pattern = re.compile(args.match)
    cases = []
    # 給与.md のように <tr> を字下げし、セルの中身を改行して書いた md もある
    for row in re.findall(r"^\s*<tr>\s*\n(.*?)\n\s*</tr>", source, re.S | re.M):
        cells = [c.strip() for c in re.findall(r"<td[^>]*>(.*?)</td>", row, re.S)]
        if len(cells) < 21 or not pattern.search(cells[COL_ID]):
            continue
        cases.append(
            {
                "id": cells[COL_ID],
                "rank": cells[COL_RANK].strip(),
                "auto": cells[COL_AUTO],
                "group": args.group,
                "screen": cells[COL_SCREEN],
                "area": cells[COL_AREA],
                "purpose": html.unescape(cells[COL_PURPOSE]),
                "pre": split_items(cells[COL_PRE]),
                "steps": split_items(cells[COL_STEPS]),
                "exp": split_items(cells[COL_EXP]),
                "note": html.unescape(cells[COL_NOTE]),
            }
        )
    if not cases:
        print(f"{args.match} に当たる行がありません", file=sys.stderr)
        return 1
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(cases, f, ensure_ascii=False, indent=1)
    print(f"{len(cases)} 件を {args.output} に書きました")
    return 0


if __name__ == "__main__":
    sys.exit(main())
