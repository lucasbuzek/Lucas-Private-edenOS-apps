// CRESUS trading-extension candidate, 2026-10-28.
// Deterministic proposal/risk calculations; never calls a broker or MCP write tool.
const isNumber = (x) => typeof x === 'number' && Number.isFinite(x);
const money = (x) => Math.round((x + Number.EPSILON) * 100) / 100;
export function validatePaperDraft(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw Error('A structured order is required.');
  if (raw.live === true || raw.executionVenue === 'LIVE' || raw.leverage > 1 || raw.derivative === true)
    throw Error('Live orders, leverage and derivatives are disabled in the paper candidate.');
  const mic = String(raw.mic || '').trim().toUpperCase();
  const ticker = String(raw.ticker || '').trim().toUpperCase();
  const currency = String(raw.currency || '').trim().toUpperCase();
  if (!/^[A-Z0-9]{4}$/.test(mic) || !/^[A-Z0-9.\-]{1,22}$/.test(ticker) || !/^[A-Z]{3}$/.test(currency))
    throw Error('Provide an unambiguous listing: MIC, ticker and three-letter currency.');
  if (raw.side !== 'BUY') throw Error('Only unleveraged paper BUY is supported until positions are reconciled.');
  if (!isNumber(raw.quantity) || raw.quantity <= 0 || raw.quantity > 1000000) throw Error('Invalid quantity.');
  if (!isNumber(raw.limitPrice) || raw.limitPrice <= 0 || raw.limitPrice > 100000000) throw Error('Invalid manual paper price.');
  if (!isNumber(raw.availableCapital) || raw.availableCapital <= 0) throw Error('Available capital is required in the listing currency.');
  const cap = raw.maxAllocationPercent ?? 5;
  if (!isNumber(cap) || cap <= 0 || cap > 10) throw Error('Maximum allocation must be greater than zero and at most 10%.');
  const notional = money(raw.quantity * raw.limitPrice);
  if (!Number.isFinite(notional) || notional <= 0 || notional > raw.availableCapital)
    throw Error('Paper order notional must be within declared available capital.');
  const allocationPercent = (notional / raw.availableCapital) * 100;
  if (allocationPercent > cap + 1e-8) throw Error('Order exceeds the declared per-order allocation limit.');
  const sourceUrl = raw.sourceUrl ? String(raw.sourceUrl).trim() : null;
  if (sourceUrl && (!sourceUrl.startsWith('https://') || sourceUrl.length > 2000)) throw Error('Evidence URL must be HTTPS.');
  const observedAt = raw.observedAt ? new Date(raw.observedAt) : null;
  if (observedAt && (!Number.isFinite(observedAt.getTime()) || observedAt.getTime() > Date.now() + 60000))
    throw Error('Invalid observation time.');
  return Object.freeze({
    listing: { mic, ticker, currency, isin: String(raw.isin || '').trim().toUpperCase() || null },
    side: 'BUY', quantity: raw.quantity, limitPrice: raw.limitPrice, notional,
    availableCapital: raw.availableCapital, allocationPercent: Math.round(allocationPercent * 100) / 100,
    maxAllocationPercent: cap, executionVenue: 'PAPER', executableLive: false,
    evidence: { state: 'MANUAL_UNVERIFIED', sourceUrl, observedAt: observedAt?.toISOString() || null },
    warnings: ['Manual paper-price input is NOT a verified live quote.', 'No broker connection or real order submission occurs.', 'Fees, FX and taxes are not estimated.'],
  });
}
// Strategy Lab evaluation only. This cannot place, schedule or submit orders.
export function assessPaperTrigger(rule, quote, now = Date.now()) {
  if (!rule || !quote || rule.live === true) throw Error('Paper-only rule and observation required.');
  if (!['AT_OR_BELOW', 'AT_OR_ABOVE'].includes(rule.condition))
    throw Error('Unsupported trigger condition.');
  if (!isNumber(rule.threshold) || rule.threshold <= 0 || !isNumber(quote.price) || quote.price <= 0)
    throw Error('Positive finite price and threshold required.');
  const at = new Date(quote.observedAt);
  const age = now - at.getTime();
  if (!Number.isFinite(age) || age < -60000 || age > 15 * 60 * 1000)
    return { eligible: false, reason: 'STALE_OR_MISSING_QUOTE', executionVenue: 'PAPER' };
  if (quote.verified !== true || !String(quote.sourceUrl || '').startsWith('https://'))
    return { eligible: false, reason: 'UNVERIFIED_QUOTE', executionVenue: 'PAPER' };
  const eligible = rule.condition === 'AT_OR_BELOW' ? quote.price <= rule.threshold : quote.price >= rule.threshold;
  return { eligible, reason: eligible ? 'RULE_MATCHED_SIMULATION_ONLY' : 'RULE_NOT_MET', executionVenue: 'PAPER', observedAt: at.toISOString() };
}
