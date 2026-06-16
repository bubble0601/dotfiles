#!/usr/bin/env node
'use strict';
/* Tool-Call Leak Guard — single file, no deps. Wire the SAME file to BOTH the
 * Stop hook and the SessionStart hook.
 *   Stop        : if the last assistant turn leaked tool-call markup as text and no
 *                 tool actually ran -> clean the transcript + block (force re-issue).
 *   SessionStart: sweep past transcripts in the project folder (live one untouched).
 * Fail-open everywhere. Extend markers via env LEAK_GUARD_MARKERS="call,court,count,course,NEW"
 * or edit the array below. LEAK_GUARD_LOOSE=1 = also catch a bare line-leading tag. */
const fs = require('fs');
const path = require('path');

let MARKERS = (process.env.LEAK_GUARD_MARKERS || 'call,court,count,course')
  .split(',').map(s => s.trim().toLowerCase()).filter(Boolean);
if (!MARKERS.length) MARKERS = ['call', 'court', 'count', 'course'];
const M = '(?:' + MARKERS.map(s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|') + ')';
const RM = 3; // min repeats for a collapsed-call run

const STRICT = new RegExp('(?:^|\\n)[ \\t]*' + M + '[ \\t]*\\r?\\n[ \\t]*<\\s*(?:antml:)?(?:invoke|parameter|function_calls)\\b', 'i');
const LOOSE = /(?:^|\n)[ \t]*<\s*(?:antml:)?(?:invoke|parameter|function_calls)\b/i;
const LEAKY = new RegExp('^[ \\t]*' + M + '(?:[ \\t]*$|[<>])', 'gim');     // marker bare OR glued to < or >
const LEAKY_LINE = new RegExp('^[ \\t]*' + M + '(?:[ \\t]*$|[<>])', 'i');
const MARKER_LINE = new RegExp('^[ \\t]*' + M + '[ \\t]*$', 'i');
const MARKER_STRIP = new RegExp('^[ \\t]*' + M + '[ \\t]*$', 'gim');
const OPEN_LINE = /^[ \t]*<\s*(?:antml:)?(?:invoke|function_calls)\b/i;
const MARKUP_LINE = /^[ \t]*<\s*(?:antml:)?(?:invoke|parameter|function_calls|\/invoke|\/parameter|\/function_calls)\b/i;
const HASLEAK = new RegExp('(?:^|\\n)[ \\t]*' + M + '[ \\t]*\\r?\\n[ \\t]*<\\s*(?:antml:)?(?:invoke|parameter|function_calls)\\b', 'i');
const PREFILTER = new RegExp('<\\s*\\/?\\s*(?:antml:)?(?:invoke|function_calls)\\b|(?:^|\\n)[ \\t]*' + M + '[ \\t]*(?:\\n|<)', 'i');

// self-adapting: SAME short token glued to </> repeated >=RM times = a collapsed
// call even if the word is NOT in the marker list (markup-glue keeps it FP-safe).
function structuralLeak(t) {
  const seen = {};
  for (const l of t.split(/\r?\n/)) {
    const m = l.match(/^[ \t]*([A-Za-z]{2,15})[<>]/);
    if (!m) continue;
    const w = m[1].toLowerCase();
    seen[w] = (seen[w] || 0) + 1;
    if (seen[w] >= RM) return w;
  }
  return null;
}
function leakyRunMax(t) {
  let max = 0, cur = 0;
  for (const l of t.split(/\r?\n/)) {
    if (LEAKY_LINE.test(l)) { cur++; if (cur > max) max = cur; }
    else if (l.trim() !== '') cur = 0;
  }
  return max;
}
function summarizeInvoke(name, body) {
  const re = /<\s*(?:antml:)?parameter\s+name\s*=\s*["']?([^"'>\s]+)["']?\s*>([\s\S]*?)(?:<\/\s*(?:antml:)?parameter\s*>|$)/gi;
  const ps = []; let m;
  while ((m = re.exec(body)) !== null) ps.push('  ' + m[1] + '=' + (m[2] || ''));
  const h = '[leaked tool-call markup removed (was never executed; reissued separately): ' + name;
  return ps.length ? h + '\n' + ps.join('\n') + ']' : h + ']';
}
// deterministic line-based cleaner (linear time, no ReDoS, no over-deletion)
function cleanText(text) {
  if (typeof text !== 'string' || (!HASLEAK.test(text) && leakyRunMax(text) < RM && structuralLeak(text) === null)) return { text, changed: false };
  const lines = text.split(/\r?\n/), out = []; let changed = false, i = 0;
  while (i < lines.length) {
    if (MARKER_LINE.test(lines[i])) {                 // marker run then a real tag = tag burst
      let j = i; while (j < lines.length && MARKER_LINE.test(lines[j])) j++;
      if (j < lines.length && OPEN_LINE.test(lines[j])) {
        changed = true; i = j; let burst = '';
        while (i < lines.length) {
          if (burst && MARKER_LINE.test(lines[i])) break;
          burst += (burst ? '\n' : '') + lines[i];
          const nx = i + 1 < lines.length ? lines[i + 1] : null; i++;
          if (nx === null || !MARKUP_LINE.test(nx)) break;
        }
        const ir = /<\s*(?:antml:)?invoke\s+name\s*=\s*["']?([^"'>\s]+)["']?[^>]*>([\s\S]*?)(?:<\/\s*(?:antml:)?invoke\s*>|$)/gi;
        const sm = []; let im;
        while ((im = ir.exec(burst)) !== null) sm.push(summarizeInvoke(im[1], im[2] || ''));
        if (!sm.length) sm.push('[leaked tool-call markup removed (reissued separately)]');
        for (const s of sm) out.push(s); continue;
      }
    }
    if (LEAKY_LINE.test(lines[i])) {                  // collapsed-call run (bare or glued), blanks ok
      let j = i, leaky = 0, last = i;
      while (j < lines.length) {
        if (LEAKY_LINE.test(lines[j])) { leaky++; last = j; j++; }
        else if (lines[j].trim() === '') j++; else break;
      }
      if (leaky >= RM) { changed = true; out.push('[leaked tool-call markup removed (the tool call did not render; only marker fragments survived)]'); i = last + 1; continue; }
    }
    out.push(lines[i]); i++;
  }
  let n = out.join('\n');
  if (changed) n = n.replace(MARKER_STRIP, '');
  n = n.replace(/\n{3,}/g, '\n\n').replace(/[ \t]+\n/g, '\n').trim();
  return { text: n, changed: n !== text || changed };
}
function cleanFileRaw(file, raw) {
  const lines = raw.split('\n'); let removed = 0, fc = false;
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].trim()) continue;
    let o; try { o = JSON.parse(lines[i]); } catch (_) { continue; }
    if (!(o.type === 'assistant' || (o.message && o.message.role === 'assistant'))) continue;
    const c = (o.message || o).content; if (!Array.isArray(c)) continue;
    let lc = false;
    for (const b of c) { if (!b || typeof b !== 'object' || b.type !== 'text') continue; const r = cleanText(b.text || ''); if (r.changed) { b.text = r.text; removed++; lc = true; } }
    if (lc) { lines[i] = JSON.stringify(o); fc = true; }
  }
  if (fc) { try { const t = file + '.lg.tmp'; fs.writeFileSync(t, lines.join('\n')); fs.renameSync(t, file); } catch (_) { return 0; } }
  return removed;
}
function cleanFile(f) { let raw; try { raw = fs.readFileSync(f, 'utf8'); } catch (_) { return 0; } return cleanFileRaw(f, raw); }
function collectJsonl(dir, out) {
  let e; try { e = fs.readdirSync(dir, { withFileTypes: true }); } catch (_) { return; }
  for (const x of e) { const p = path.join(dir, x.name); if (x.isDirectory()) { if (!x.name.startsWith('_')) collectJsonl(p, out); } else if (x.isFile() && x.name.endsWith('.jsonl')) out.push(p); }
}
function runSessionStart(p) {
  const tp = (p && (p.transcript_path || p.transcriptPath)) || ''; if (!tp) return;
  const dir = path.dirname(tp), cur = path.resolve(tp), stp = path.join(dir, '_leakguard_state.json');
  let last = 0; try { last = Number(JSON.parse(fs.readFileSync(stp, 'utf8')).lastRun) || 0; } catch (_) {}
  const start = Date.now(); const files = []; collectJsonl(dir, files);
  for (const f of files) {
    if (path.resolve(f) === cur) continue;            // never touch the live conversation
    let s; try { s = fs.statSync(f); } catch (_) { continue; }
    if (s.mtimeMs <= last) continue;
    let raw; try { raw = fs.readFileSync(f, 'utf8'); } catch (_) { continue; }
    if (PREFILTER.test(raw)) cleanFileRaw(f, raw);
  }
  try { fs.writeFileSync(stp, JSON.stringify({ lastRun: start })); } catch (_) {}
}
function out(o) { try { process.stdout.write(JSON.stringify(o)); } catch (_) {} }

function main() {
  const arg = process.argv[2];
  if (arg && arg.endsWith('.jsonl')) { process.stdout.write('cleaned ' + cleanFile(arg) + ' block(s)\n'); return; }
  let input = ''; try { input = fs.readFileSync(0, 'utf8'); } catch (_) { return out({}); }
  let p = {}; try { p = JSON.parse(input || '{}'); } catch (_) { return out({}); }
  if (p.hook_event_name === 'SessionStart') { try { runSessionStart(p); } catch (_) {} return out({}); }
  if (p.stop_hook_active) return out({});             // loop guard
  const tp = p.transcript_path || p.transcriptPath; if (!tp) return out({});
  let raw; try { raw = fs.readFileSync(tp, 'utf8'); } catch (_) { return out({}); }
  const lines = raw.split(/\r?\n/).filter(Boolean); let last = null;
  for (let i = lines.length - 1; i >= 0; i--) { let o; try { o = JSON.parse(lines[i]); } catch (_) { continue; } const m = o.message || o; const role = (m && m.role) || o.role || o.type; if (role === 'assistant') { last = m; break; } }
  if (!last) return out({});
  let content = last.content; if (typeof content === 'string') content = [{ type: 'text', text: content }]; if (!Array.isArray(content)) return out({});
  let hasTool = false, text = '';
  for (const b of content) { if (!b || typeof b !== 'object') continue; if (b.type === 'tool_use' || b.type === 'server_tool_use' || b.type === 'tool_call') hasTool = true; if (b.type === 'text' && typeof b.text === 'string') text += '\n' + b.text; }
  const re = process.env.LEAK_GUARD_LOOSE ? LOOSE : STRICT;
  const isLeak = re.test(text) || (text.match(LEAKY) || []).length >= RM || structuralLeak(text) !== null;
  if (isLeak) { try { cleanFile(tp); } catch (_) {} }   // tidy the saved log
  if (hasTool) return out({});                          // a real tool ran this turn
  if (isLeak) return out({ decision: 'block', reason: 'Tool-call leak detected: your last message contains raw tool-call markup as plain text but no tool actually ran. Re-issue the intended tool call exactly once using the proper structured tool-call mechanism. Never paste tool-call markup as prose.' });
  out({});
}
module.exports = { cleanText, cleanFile, cleanFileRaw, runSessionStart, structuralLeak };
if (require.main === module) main();
