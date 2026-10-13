#!/usr/bin/env python3
"""spec(JSON) からペライチ HTML を組む。画像・CSS・JS をすべて埋め込んだ 1 ファイルにする。

usage: build.py spec.json out.html
"layout": "visual"(既定)は spec の sections から図解ペライチを組む。"free" は "body" の HTML 断片を殻で包む。
free の本文中の <img src="相対パス"> は base64 で埋め込み、id の無い <textarea data-kind="q"> には連番の id を振る。
選択コメントと「全入力内容をコピー」はどの layout にも付く。
spec の形は ../examples/spec.*.example.json を見る。
"""
import base64, json, mimetypes, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
TPL = os.path.join(HERE, '..', 'templates')
LAYOUTS = ('visual', 'free')
KINDS = ('general', 'proposal')
LABELS = {
    'general': {'points': 'ポイント', 'notes': '注意点'},
    'proposal': {'points': 'できるようになること', 'questions': 'きいておきたいこと', 'notes': 'この仕様の留意点'},
}

def data_uri(path):
    mime = mimetypes.guess_type(path)[0] or 'image/jpeg'
    with open(path, 'rb') as f:
        return f'data:{mime};base64,' + base64.b64encode(f.read()).decode()

def esc(t):
    return (t or '').replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')

def tpl(name):
    return open(os.path.join(TPL, name), encoding='utf-8').read()

def fig(base, f):
    cap = f'<figcaption>{esc(f["caption"])}</figcaption>' if f.get('caption') else ''
    return f'<figure><img src="{data_uri(os.path.join(base, f["src"]))}" alt="{esc(f.get("alt", ""))}">{cap}</figure>'

def h3(k, t):
    return f'<h3 class="h3"><span class="k {k}">{t}</span></h3>'

def section(base, sec, labels, qcounter):
    out = [f'<section><div class="eyebrow">{esc(sec.get("eyebrow", ""))}</div><h2>{esc(sec["title"])}</h2>']
    if sec.get('sub'):
        out.append(f'<p class="sub">{esc(sec["sub"])}</p>')
    if sec.get('figures'):
        out.append('<div class="stack">' + ''.join(fig(base, f) for f in sec['figures']) + '</div>')
    if sec.get('points'):
        out.append(h3('k1', sec.get('points_label', labels['points'])))
        out.append('<div class="points">' + ''.join(
            f'<div class="point"><b>{esc(p["title"])}</b><span>{esc(p["body"])}</span></div>' for p in sec['points']) + '</div>')
    if sec.get('questions'):
        out.append(h3('k2', sec.get('questions_label', labels['questions'])))
        qs = []
        for q in sec['questions']:
            qcounter[0] += 1
            qs.append(f'<div class="q"><div class="n">質問 {esc(q["id"])}</div><p>{esc(q["text"])}</p><small>{esc(q.get("note", ""))}</small>'
                      f'<label class="ans"><span>回答</span><textarea id="q{qcounter[0]}" data-kind="q" rows="2" placeholder="ここに回答を書く"></textarea></label></div>')
        out.append('<div class="qs">' + ''.join(qs) + '</div>')
    if sec.get('notes'):
        out.append(h3('k3', sec.get('notes_label', labels['notes'])))
        out.append('<ul class="notes">' + ''.join(
            f'<li><b>{esc(n["title"])}</b><span>{esc(n["body"])}</span></li>' for n in sec['notes']) + '</ul>')
    out.append('</section>')
    return '\n'.join(out)

def visual_body(spec, base):
    kind = spec.get('kind', 'general')
    if kind not in KINDS:
        sys.exit(f'kind は {" / ".join(KINDS)} のどれか: {kind!r}')
    if kind != 'proposal' and any(sec.get('questions') for sec in spec['sections']):
        sys.exit('questions は kind: "proposal" のときだけ使える')
    out = [f'<header><div class="eyebrow">{esc(spec.get("eyebrow", ""))}</div><h1>{esc(spec["headline"])}</h1><p class="lead">{esc(spec.get("lead", ""))}</p></header>']
    if spec.get('hero'):
        out.append(fig(base, spec['hero']))
    qc = [0]
    for sec in spec['sections']:
        out.append(section(base, sec, LABELS[kind], qc))
    return '\n'.join(out)

def free_body(spec, base):
    path = os.path.join(base, spec['body'])
    html = open(path, encoding='utf-8').read()
    body_dir = os.path.dirname(path)
    def inline(m):
        src = m.group(2)
        if re.match(r'(data:|https?:|//)', src):
            return m.group(0)
        return m.group(1) + data_uri(os.path.join(body_dir, src)) + m.group(3)
    html = re.sub(r'(<img\b[^>]*?\bsrc=")([^"]+)(")', inline, html)
    n = [0]
    def number(m):
        n[0] += 1
        return f'<textarea id="q{n[0]}" '
    return re.sub(r'<textarea (?![^>]*\bid=)(?=[^>]*\bdata-kind=)', number, html)

INTERACTIVE_UI = '''<div id="selpop" role="dialog" aria-label="選択した文へのコメント"><blockquote id="selquote"></blockquote><textarea id="seltext" placeholder="この部分へのコメント"></textarea><div class="row"><button type="button" id="seldel" hidden style="margin-right:auto;color:#B8402F">削除</button><button type="button" id="selcancel">キャンセル</button><button type="button" class="pri" id="selsave">保存</button></div></div>
<div class="copybar" id="copybar">
 <div class="st" id="copystatus">__INPUTS__はこのブラウザに自動保存されます。テキストを選択してコメントできます。ハイライトをクリックすると内容が見られます。</div>
 <div style="display:flex;gap:8px;flex-wrap:wrap"><button type="button" id="btn-copy">全入力内容をコピー</button></div>
</div>
<div class="outbox" id="outbox" hidden><textarea id="outtext" readonly aria-label="全入力内容"></textarea></div>'''

def main(spec_path, out_path):
    spec = json.load(open(spec_path, encoding='utf-8'))
    layout = spec.get('layout', 'visual')
    if layout not in LAYOUTS:
        sys.exit(f'layout は {" / ".join(LAYOUTS)} のどれか: {layout!r}')
    base = os.path.dirname(os.path.abspath(spec_path))
    content = visual_body(spec, base) if layout == 'visual' else free_body(spec, base)
    has_questions = 'data-kind=' in content
    status, heading = ('回答とコメント', '回答・コメント') if has_questions else ('コメント', 'コメント')
    key = spec.get('storage_key', os.path.splitext(os.path.basename(out_path))[0])
    js = (tpl('page.js').replace('__STORAGE_KEY__', key).replace('__TITLE__', spec['title'].replace("'", "\\'"))
          .replace('__COPY_HEADING__', heading))
    wrap = 'wrap narrow' if spec.get('width') == 'narrow' else 'wrap'
    html = '\n'.join([
        f'<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n<title>{esc(spec["title"])}</title>',
        '<link rel="preconnect" href="https://fonts.googleapis.com">',
        '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Zen+Kaku+Gothic+New:wght@500;700;900&family=Noto+Sans+JP:wght@400;500;700&display=swap">',
        f'<style>\n{tpl("page.css")}{tpl("interactive.css")}\n</style>', f'<div class="{wrap}">',
        content,
        INTERACTIVE_UI.replace('__INPUTS__', status),
        f'<script>\n{js}\n</script>',
        '</div>\n'])
    open(out_path, 'w', encoding='utf-8').write(html)
    mb = os.path.getsize(out_path) / 1024 / 1024
    print(out_path, layout, round(mb, 2), 'MB')
    if mb > 10:
        print('!! 10 MB 超: Slack でプレビューされない。JPEG の品質を下げるか図を減らす', file=sys.stderr)

if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
