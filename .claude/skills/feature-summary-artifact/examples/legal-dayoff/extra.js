// 2026 年の表(月末締め)
(function buildYear() {
  const tbody = document.getElementById('yearTable');
  for (let m = 0; m < 12; m++) {
    const days = new Date(2026, m + 1, 0).getDate();
    let thu = 0;
    for (let d = 1; d <= days; d++) if (new Date(2026, m, d).getDay() === 4) thu++;
    const byWeekday = thu >= 5 ? 5 : 4;
    const byPeriod = days >= 31 ? 5 : 4;
    const tr = document.createElement('tr');
    if (byWeekday !== 4 || byPeriod !== 4) tr.className = 'diff';
    const cells = [`${m + 1}/1〜${m + 1}/${days}`, `${days} 日`, `${thu} 回`, '4 日', '4 日', `${byWeekday} 日`, `${byPeriod} 日`];
    cells.forEach((c, i) => { const td = document.createElement('td'); td.textContent = c; if (i > 0) td.className = 'num'; tr.appendChild(td); });
    tbody.appendChild(tr);
  }
})();
