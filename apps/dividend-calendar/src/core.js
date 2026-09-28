export const EventStatus = Object.freeze({
  DECLARED: "declared",
  ESTIMATED: "estimated",
  PAID: "paid",
  CANCELLED: "cancelled",
  UNKNOWN: "unknown"
});

export function normalizeDividendEvent(raw) {
  if (!raw?.symbol) throw new Error("symbol required");
  const status = Object.values(EventStatus).includes(raw.status) ? raw.status : EventStatus.UNKNOWN;
  const amount = raw.amount == null ? null : Number(raw.amount);
  if (amount != null && (!Number.isFinite(amount) || amount < 0)) throw new Error("invalid dividend amount");
  return {
    symbol: String(raw.symbol).trim().toUpperCase(),
    declarationDate: dateOrNull(raw.declarationDate),
    exDate: dateOrNull(raw.exDate),
    recordDate: dateOrNull(raw.recordDate),
    paymentDate: dateOrNull(raw.paymentDate),
    amount,
    currency: raw.currency || null,
    frequency: raw.frequency || null,
    status,
    source: raw.source || null,
    sourceUrl: raw.sourceUrl || null,
    observedAt: raw.observedAt || null,
    confidence: raw.confidence ?? (status === EventStatus.DECLARED ? 1 : null)
  };
}

function dateOrNull(v) {
  if (!v) return null;
  const s=String(v).slice(0,10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s) || Number.isNaN(Date.parse(s+"T00:00:00Z"))) throw new Error("invalid date: "+v);
  return s;
}

export function eventsInWindow(events, field, from, to) {
  if (!["declarationDate","exDate","recordDate","paymentDate"].includes(field)) throw new Error("unsupported date field");
  return events.filter(e => e[field] && e[field] >= from && e[field] <= to)
    .sort((a,b) => a[field].localeCompare(b[field]) || a.symbol.localeCompare(b.symbol));
}

export function trailingDividend(events, symbol, asOf, days=365) {
  const end = Date.parse(asOf+"T23:59:59Z");
  const start = end - days*86400000;
  return events.filter(e => e.symbol===symbol && e.exDate && e.status!==EventStatus.CANCELLED)
    .filter(e => { const t=Date.parse(e.exDate+"T00:00:00Z"); return t>=start && t<=end; })
    .reduce((s,e)=>s+(e.amount||0),0);
}

export function trailingYield({events,symbol,asOf,price}) {
  if (!(price>0)) return null;
  return trailingDividend(events,symbol,asOf)/price;
}

export function dividendGrowthSeries(events, symbol) {
  const yearly = new Map();
  for (const e of events) {
    if (e.symbol!==symbol || !e.exDate || e.status===EventStatus.CANCELLED || e.amount==null) continue;
    const y=e.exDate.slice(0,4); yearly.set(y,(yearly.get(y)||0)+e.amount);
  }
  return [...yearly.entries()].sort().map(([year,amount])=>({year,amount}));
}

export function detectDividendCuts(series) {
  const cuts=[];
  for(let i=1;i<series.length;i++) if(series[i].amount < series[i-1].amount)
    cuts.push({year:series[i].year, previous:series[i-1].amount, current:series[i].amount,
      declinePct:(series[i].amount/series[i-1].amount)-1});
  return cuts;
}
