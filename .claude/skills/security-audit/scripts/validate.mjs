#!/usr/bin/env node
// security-review.html に埋め込んだデータの整合を検査する。
// 使い方: node validate.mjs <security-review.html> [--unexamined]
// --unexamined を付けると、問題も checkedAt もない(「未調査」のままの)小分類を一覧する
import { readFileSync } from 'fs';
import vm from 'vm';

const path = process.argv[2];
if (!path) {
  console.error('usage: node validate.mjs <security-review.html> [--unexamined]');
  process.exit(2);
}
const html = readFileSync(path, 'utf8');
const m = html.match(/<script id="scan-data">([\s\S]*?)<\/script>/);
if (!m) {
  console.error('<script id="scan-data"> が見つからない');
  process.exit(2);
}
const ctx = { window: {} };
vm.runInNewContext(m[1], ctx);
const D = ctx.window.SCAN;

if (process.argv.includes('--unexamined')) {
  const used = new Set(D.issues.map((i) => i.category));
  for (const c of D.categories) if (!used.has(c.key) && !c.checkedAt) console.log(c.scope, c.key, c.name);
  process.exit(0);
}
const errors = [];
const err = (m) => errors.push(m);

const scopeKeys = new Set(D.scopes.map((s) => s.key));
const catKeys = new Set();
for (const c of D.categories) {
  if (!scopeKeys.has(c.scope)) err(`category ${c.key}: 未定義の scope ${c.scope}`);
  if (catKeys.has(c.key)) err(`category ${c.key}: key が重複`);
  catKeys.add(c.key);
}
const zoneKeys = new Set(D.zones.map((z) => z.key));
const prefixes = new Set((D.meta.sources || []).map((s) => s.prefix));

const issueKeys = new Set();
const ids = new Map();
for (const s of D.issues) {
  if (issueKeys.has(s.key)) err(`issue ${s.key}: key が重複`);
  issueKeys.add(s.key);
  if (!catKeys.has(s.category)) err(`issue ${s.key}: 未定義の category ${s.category}`);
  // 記号は小分類の key + 連番
  if (!new RegExp(`^${s.category}-\\d+$`).test(s.key)) err(`issue ${s.key}: 記号が「${s.category}-連番」の形でない`);
  for (const f of s.findings) {
    if (ids.has(f.id)) err(`finding ${f.id}: ${ids.get(f.id)} と ${s.key} で重複`);
    ids.set(f.id, s.key);
    if (!['HIGH', 'MEDIUM', 'LOW'].includes(f.sev)) err(`finding ${f.id}: sev が不正 ${f.sev}`);
    for (const z of f.zones || []) if (!zoneKeys.has(z)) err(`finding ${f.id}: 未定義の zone ${z}`);
    const p = f.id.replace(/\d+$/, '');
    if (prefixes.size && !prefixes.has(p)) err(`finding ${f.id}: 接頭辞 ${p} が meta.sources にない`);
  }
}
for (const s of D.issues) {
  for (const m of s.measures) {
    for (const id of [...(m.fixes || []), ...(m.reduces || [])]) {
      if (!ids.has(id)) err(`issue ${s.key} の対策「${m.label}」: 存在しない指摘 ${id}`);
    }
    if (!m.prevent && !(m.fixes || []).length && !(m.reduces || []).length) {
      err(`issue ${s.key} の対策「${m.label}」: fixes・reduces・prevent のどれもない`);
    }
  }
  const covered = new Set(s.measures.flatMap((m) => [...(m.fixes || []), ...(m.reduces || [])]));
  for (const f of s.findings) {
    if (!f.resolved && !covered.has(f.id) && !D.issues.some((o) => o.measures.some((m) => (m.fixes || []).includes(f.id) || (m.reduces || []).includes(f.id)))) {
      err(`finding ${f.id}: どの対策にも結び付いていない`);
    }
  }
}

const open = D.issues.flatMap((s) => s.findings).filter((f) => !f.resolved);
const tally = open.reduce((a, f) => ((a[f.sev] = (a[f.sev] || 0) + 1), a), {});
console.log(`問題 ${D.issues.length} / 指摘 ${ids.size}(未対応 ${open.length}: ${JSON.stringify(tally)})`);
if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}
console.log('OK');
