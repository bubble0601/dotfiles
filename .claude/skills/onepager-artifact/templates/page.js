(function(){
 var KEY='__STORAGE_KEY__-answers', MKEY='__STORAGE_KEY__-memos';
 var areas=Array.prototype.slice.call(document.querySelectorAll('textarea[data-kind]'));
 function load(){try{var d=JSON.parse(localStorage.getItem(KEY)||'{}');areas.forEach(function(t){if(d[t.id])t.value=d[t.id];});}catch(e){}}
 function save(){try{var d={};areas.forEach(function(t){if(t.value.trim())d[t.id]=t.value;});localStorage.setItem(KEY,JSON.stringify(d));}catch(e){}}
 var memos=[];
 function mload(){try{memos=JSON.parse(localStorage.getItem(MKEY)||'[]');if(!Array.isArray(memos))memos=[];}catch(e){memos=[];}}
 function msave(){try{localStorage.setItem(MKEY,JSON.stringify(memos));}catch(e){}}
 function secTitle(el){var sec=el&&el.closest?el.closest('section,header'):null;if(!sec)return '';var eb=sec.querySelector('.eyebrow'),h=sec.querySelector('h2,h1');return ((eb?eb.textContent.trim()+' ':'')+(h?h.textContent.trim():'')).trim();}
 function secIndex(el){var secs=Array.prototype.slice.call(document.querySelectorAll('header,section'));var sec=el&&el.closest?el.closest('section,header'):null;return secs.indexOf(sec);}
 /* highlight */
 function findRanges(root,quote){var out=[];if(!root||!quote)return out;var w=document.createTreeWalker(root,NodeFilter.SHOW_TEXT,{acceptNode:function(n){var p=n.parentNode;if(!p)return NodeFilter.FILTER_REJECT;if(p.closest('textarea,script,style,#selpop,#selbtn'))return NodeFilter.FILTER_REJECT;return NodeFilter.FILTER_ACCEPT;}});var nodes=[],text='';var n;while((n=w.nextNode())){nodes.push({node:n,start:text.length});text+=n.nodeValue;}
  var i=text.indexOf(quote);if(i<0)return out;var j=i+quote.length;var r=document.createRange();var sset=false;
  for(var k=0;k<nodes.length;k++){var a=nodes[k].start,b=a+nodes[k].node.nodeValue.length;if(!sset&&i>=a&&i<b){r.setStart(nodes[k].node,i-a);sset=true;}if(sset&&j>a&&j<=b){r.setEnd(nodes[k].node,j-a);out.push(r);break;}}
  return out;}
 var memoRanges=[];function paint(){var secs=document.querySelectorAll('header,section');memoRanges=[];var hl=(window.CSS&&CSS.highlights&&window.Highlight)?new Highlight():null;memos.forEach(function(m){var root=secs[m.si]||document.querySelector('.wrap');findRanges(root,m.quote).forEach(function(r){if(hl)hl.add(r);memoRanges.push({m:m,r:r});});});if(hl)CSS.highlights.set('memo',hl);}
 function memoAt(x,y){var pos=null;if(document.caretPositionFromPoint){var cp=document.caretPositionFromPoint(x,y);if(cp)pos={node:cp.offsetNode,offset:cp.offset};}else if(document.caretRangeFromPoint){var cr=document.caretRangeFromPoint(x,y);if(cr)pos={node:cr.startContainer,offset:cr.startOffset};}if(!pos)return null;for(var i=0;i<memoRanges.length;i++){try{if(memoRanges[i].r.isPointInRange(pos.node,pos.offset))return memoRanges[i];}catch(e){}}return null;}
 function renderList(){}
 /* selection UI */
 var pop=document.getElementById('selpop'),pending=null;
 function hideBtn(){}
 function onSel(){if(pop.style.display==='block'&&(document.getElementById('seltext').value.trim()||(pending&&pending.edit)))return;var sel=window.getSelection();if(!sel||sel.isCollapsed||!sel.rangeCount){hideBtn();return;}var text=sel.toString().replace(/\s+/g,' ').trim();if(text.length<2){hideBtn();return;}var node=sel.anchorNode.nodeType===1?sel.anchorNode:sel.anchorNode.parentNode;if(!node.closest('.wrap')||node.closest('textarea,.copybar,#selpop,#memopanel,.outbox')){hideBtn();return;}var r=sel.getRangeAt(0),rect=r.getBoundingClientRect();if(!rect.width&&!rect.height){hideBtn();return;}pending={quote:text,section:secTitle(node),si:secIndex(node)};document.getElementById('selquote').textContent=text;document.getElementById('seltext').value='';pop.style.left=Math.max(8,Math.min(window.innerWidth-440,rect.left+window.scrollX+rect.width/2-210))+'px';pop.style.top=(rect.bottom+window.scrollY+8)+'px';pop.style.display='block';var pr=pop.getBoundingClientRect();if(pr.right>window.innerWidth-8)pop.style.left=Math.max(8,window.innerWidth-pr.width-16+window.scrollX)+'px';}
 document.addEventListener('mouseup',function(){setTimeout(onSel,0);});
 document.addEventListener('keyup',function(e){if(e.shiftKey||e.key==='Shift')setTimeout(onSel,0);});
 document.addEventListener('mousedown',function(e){if(pop.contains(e.target))return;if(pop.style.display==='block'&&(!document.getElementById('seltext').value.trim()||(pending&&pending.edit&&document.getElementById('seltext').value.trim()===pending.edit.comment)))closePop();});
 function closePop(){pop.style.display='none';pending=null;document.getElementById('seldel').hidden=true;}
 function openEdit(hit,x,y){var m=hit.m;pending={edit:m};document.getElementById('selquote').textContent=m.quote;var ta=document.getElementById('seltext');ta.value=m.comment;document.getElementById('seldel').hidden=false;var rect=hit.r.getBoundingClientRect();pop.style.left=Math.max(8,Math.min(window.innerWidth-440,rect.left+window.scrollX))+'px';pop.style.top=(rect.bottom+window.scrollY+8)+'px';pop.style.display='block';var pr=pop.getBoundingClientRect();if(pr.right>window.innerWidth-8)pop.style.left=Math.max(8,window.innerWidth-pr.width-16+window.scrollX)+'px';ta.focus();}
 document.addEventListener('click',function(e){if(pop.contains(e.target)||e.target.closest('.copybar,textarea,button,a'))return;var sel=window.getSelection();if(sel&&!sel.isCollapsed)return;var hit=memoAt(e.clientX,e.clientY);if(hit){openEdit(hit,e.clientX,e.clientY);}});
 document.getElementById('seldel').addEventListener('click',function(){if(pending&&pending.edit){var i=memos.indexOf(pending.edit);if(i>=0)memos.splice(i,1);msave();paint();}closePop();});
 document.getElementById('selcancel').addEventListener('click',closePop);
 document.getElementById('selsave').addEventListener('click',function(){var v=document.getElementById('seltext').value.trim();if(!pending){closePop();return;}if(pending.edit){if(v){pending.edit.comment=v;}else{var i=memos.indexOf(pending.edit);if(i>=0)memos.splice(i,1);}msave();paint();closePop();return;}if(!v){closePop();return;}memos.push({id:Date.now(),si:pending.si,section:pending.section,quote:pending.quote,comment:v});msave();paint();closePop();});
 document.addEventListener('keydown',function(e){if(e.key==='Escape'&&pop.style.display==='block')closePop();});
 /* copy */
 function build(){
  var lines=['# __TITLE__ — 回答・コメント',''];
  var secs=Array.prototype.slice.call(document.querySelectorAll('header,section'));
  secs.forEach(function(sec,si){
   var eb=sec.querySelector('.eyebrow'),h=sec.querySelector('h2,h1');
   var head='## '+((eb?eb.textContent.trim()+' ':'')+(h?h.textContent.trim():'')).trim();
   var body=[];
   sec.querySelectorAll('.q').forEach(function(q){var n=q.querySelector('.n').textContent.trim(),p=q.querySelector('p').textContent.trim(),t=q.querySelector('textarea');if(!t||!t.value.trim())return;body.push('### '+n+': '+p);body.push('回答: '+t.value.trim());body.push('');});
   memos.filter(function(m){return m.si===si;}).forEach(function(m){body.push('### コメント: 「'+m.quote+'」');body.push(m.comment);body.push('');});
   if(body.length){lines.push(head,'');lines=lines.concat(body);}
  });
  return lines.join('\n');
 }
 var st=document.getElementById('copystatus');function say(m){st.textContent=m;}
 document.getElementById('btn-copy').addEventListener('click',function(){var text=build();var done=function(){say('コピーしました('+new Date().toLocaleTimeString('ja-JP')+')');};var fail=function(){var ob=document.getElementById('outbox'),ta=document.getElementById('outtext');ta.value=text;ob.hidden=false;ta.focus();ta.select();say('自動コピーできませんでした。下の欄を選択してコピーしてください。');};function legacy(){try{var ta=document.createElement('textarea');ta.value=text;ta.style.position='fixed';ta.style.opacity='0';document.body.appendChild(ta);ta.select();var ok=document.execCommand('copy');document.body.removeChild(ta);ok?done():fail();}catch(e){fail();}}if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(text).then(done,legacy);}else{legacy();}});
 areas.forEach(function(t){t.addEventListener('input',function(){save();t.style.height='auto';t.style.height=(t.scrollHeight+2)+'px';});});
 load();areas.forEach(function(t){if(t.value){t.style.height='auto';t.style.height=(t.scrollHeight+2)+'px';}});
 mload();renderList();if(document.fonts&&document.fonts.ready){document.fonts.ready.then(paint);}else{paint();}
})();
