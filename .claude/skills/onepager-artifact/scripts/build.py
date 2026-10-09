#!/usr/bin/env python3
"""spec(JSON) と図(JPEG/PNG)からペライチ HTML を組む。

usage: build.py spec.json out.html
選択コメントと「全入力内容をコピー」はどの kind にも付く。"kind" が "proposal" のときだけ質問の回答欄を使える。
spec の形は ../examples/spec.proposal.example.json / spec.general.example.json を見る。図は base64 で埋め込む。
"""
import base64, json, mimetypes, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
TPL = os.path.join(HERE, '..', 'templates')
KINDS = ('general', 'proposal')
LABELS = {
    'general': {'points': 'ポイント', 'notes': '注意点'},
    'proposal': {'points': 'できるようになること', 'questions': 'きいておきたいこと', 'notes': 'この仕様の留意点'},
}
INPUTS = {'general': ('コメント', 'コメント'), 'proposal': ('回答とコメント', '回答・コメント')}  # (バーの説明文, コピーの見出し)

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

INTERACTIVE_UI = '''<div id="selpop" role="dialog" aria-label="選択した文へのコメント"><blockquote id="selquote"></blockquote><textarea id="seltext" placeholder="この部分へのコメント"></textarea><div class="row"><button type="button" id="seldel" hidden style="margin-right:auto;color:#B8402F">削除</button><button type="button" id="selcancel">キャンセル</button><button type="button" class="pri" id="selsave">保存</button></div></div>
<div class="copybar" id="copybar">
 <div class="st" id="copystatus">__INPUTS__はこのブラウザに自動保存されます。テキストを選択してコメントできます。ハイライトをクリックすると内容が見られます。</div>
 <div style="display:flex;gap:8px;flex-wrap:wrap"><button type="button" id="btn-copy">全入力内容をコピー</button></div>
</div>
<div class="outbox" id="outbox" hidden><textarea id="outtext" readonly aria-label="全入力内容"></textarea></div>'''

def main(spec_path, out_path):
    spec = json.load(open(spec_path, encoding='utf-8'))
    kind = spec.get('kind', 'general')
    if kind not in KINDS:
        sys.exit(f'kind は {" / ".join(KINDS)} のどれか: {kind!r}')
    if kind != 'proposal' and any(sec.get('questions') for sec in spec['sections']):
        sys.exit('questions は kind: "proposal" のときだけ使える')
    base = os.path.dirname(os.path.abspath(spec_path))
    css = tpl('page.css') + tpl('interactive.css')
    qc = [0]
    body = [f'<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n<title>{esc(spec["title"])}</title>',
            '<link rel="preconnect" href="https://fonts.googleapis.com">',
            '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Zen+Kaku+Gothic+New:wght@500;700;900&family=Noto+Sans+JP:wght@400;500;700&display=swap">',
            f'<style>\n{css}\n</style>', '<div class="wrap">',
            f'<header><div class="eyebrow">{esc(spec.get("eyebrow", ""))}</div><h1>{esc(spec["headline"])}</h1><p class="lead">{esc(spec.get("lead", ""))}</p></header>']
    if spec.get('hero'):
        body.append(fig(base, spec['hero']))
    for sec in spec['sections']:
        body.append(section(base, sec, LABELS[kind], qc))
    key = spec.get('storage_key', os.path.splitext(os.path.basename(out_path))[0])
    status, heading = INPUTS[kind]
    js = (tpl('page.js').replace('__STORAGE_KEY__', key).replace('__TITLE__', spec['title'].replace("'", "\\'"))
          .replace('__COPY_HEADING__', heading))
    body.append(INTERACTIVE_UI.replace('__INPUTS__', status))
    body.append(f'<script>\n{js}\n</script>')
    body.append('</div>\n')
    html = '\n'.join(body)
    open(out_path, 'w', encoding='utf-8').write(html)
    mb = os.path.getsize(out_path) / 1024 / 1024
    print(out_path, kind, round(mb, 2), 'MB')
    if mb < 1:
        print('!! 1 MB 未満: Slack でプレビューされない。図を増やすか JPEG の品質を上げる', file=sys.stderr)
    elif mb > 10:
        print('!! 10 MB 超: Slack でプレビューされない。JPEG の品質を下げるか図を減らす', file=sys.stderr)

if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
