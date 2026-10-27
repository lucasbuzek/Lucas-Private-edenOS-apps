// CRESUS backend candidate — deterministic agent/orchestrator, not a trading engine.
export const PROVIDERS = Object.freeze({
  easyequities: {
    label: 'EasyEquities', assetClass: 'equities', integration: 'GUIDED_MANUAL_ONLY',
    openAccountUrl: 'https://www.easyequities.co.za/',
    helpUrl: 'https://support.easyequities.co.za/support/solutions/articles/13000112049-how-do-i-deposit-money-into-my-zar-account-',
    capabilities: { cardFunding: 'DOCUMENTED_CHECK_VIRTUAL_CARD_WITH_ISSUER', liveOrderAPI: false },
    note: 'Fractional equities and card deposit documented; official public trade API NOT verified.',
  },
  luno: {
    label: 'Luno', assetClass: 'spot_crypto', integration: 'OFFICIAL_READ_ONLY_MARKET_API',
    openAccountUrl: 'https://www.luno.com/',
    helpUrl: 'https://guide.luno.com/hc/en-gb/articles/11035573761181-I-m-a-foreign-resident-not-a-local-citizen-Can-I-still-open-a-Luno-account',
    capabilities: { cardFunding: 'CONFLICTING_OFFICIAL_PAGES_CHECK_ACCOUNT', liveOrderAPI: 'EXISTS_NOT_ENABLED' },
    note: 'Official API supports orders but CRESUS deliberately has NO order-writing API key or implementation.',
  },
});
export const ONBOARDING_STEPS = Object.freeze([
  'CHOOSE_PROVIDER', 'CREATE_ACCOUNT', 'VERIFY_IDENTITY', 'CHECK_CARD_ELIGIBILITY',
  'REVIEW_FEES_AND_MINIMUMS', 'FUND_MANUALLY', 'VERIFY_ACCOUNT_READ_ONLY',
  'REVIEW_FIRST_TRADE_MANUALLY'
]);
const finitePositive = x => typeof x === 'number' && Number.isFinite(x) && x > 0;
export function createPlan(input = {}) {
  const provider = String(input.provider || '');
  if (!Object.hasOwn(PROVIDERS, provider)) throw new Error('Unknown brokerage provider.');
  const spendingLimitUSD = input.spendingLimitUSD ?? 5;
  if (!finitePositive(spendingLimitUSD) || spendingLimitUSD > 5)
    throw new Error('Initial proof-of-concept spending limit must be at most 5 USD.');
  return {
    provider, assetClass: PROVIDERS[provider].assetClass,
    spendingLimitUSD, fundingCurrency: 'PROVIDER_DEPENDENT',
    stageIndex: 0, status: 'NOT_VERIFIED',
    cardNumberStored: false, credentialsStored: false,
    liveExecutionEnabled: false, automationEnabled: false, createdAt: new Date().toISOString(),
  };
}
export function advancePlan(plan, declaredStep) {
  if (plan.stageIndex >= ONBOARDING_STEPS.length) throw new Error('Already at final step.');
  if (declaredStep !== ONBOARDING_STEPS[plan.stageIndex])
    throw new Error('Onboarding stage mismatch. Do not skip verification or eligibility checks.');
  const nextIndex = plan.stageIndex + 1;
  return { ...plan, stageIndex: nextIndex,
    status: nextIndex === ONBOARDING_STEPS.length ? 'USER_REPORTED_FINISHED_NOT_API_VERIFIED' : 'SELF_REPORTED',
    liveExecutionEnabled: false, automationEnabled: false };
}
const ALLOWED_PAIRS = new Set(['XBTZAR', 'ETHZAR', 'SOLZAR', 'XRPZAR']);
export function evaluateMarket(data, pair, now = Date.now()) {
  if (!ALLOWED_PAIRS.has(pair) || data?.pair !== pair)
    throw new Error('Unsupported or mismatched instrument identity.');
  const bid = Number(data.bid), ask = Number(data.ask), time = Number(data.timestamp);
  if (!finitePositive(bid) || !finitePositive(ask) || !Number.isFinite(time) || ask < bid)
    throw new Error('Invalid quote fields or crossed market.');
  const ageMs = now - time;
  if (ageMs < -60000 || ageMs > 120000) throw new Error('Quote is stale or time cannot be verified.');
  if (data.status !== 'ACTIVE') throw new Error('Market is not confirmed active.');
  const spreadPercent = Math.round(((ask - bid) / ask) * 10000) / 100;
  const warnings = ['Quote is a momentary observation, not a trading recommendation.',
    'Card fees, FX, brokerage fees and minimum order sizes have not been verified for this account.',
    'No profit or fill can be predicted from this observation.'];
  return {
    pipeline: ['INSTRUMENT_RESOLVED', 'DATA_ACQUIRED', 'FRESHNESS_VERIFIED',
      'SPREAD_CALCULATED', 'RISK_REVIEW_REQUIRED', 'NO_EXECUTION'],
    instrument: pair, bid: String(data.bid), ask: String(data.ask), spreadPercent,
    observedAt: new Date(time).toISOString(), source: 'LUNO_OFFICIAL_MARKET_API',
    sourceUrl: 'https://api.luno.com/api/1/ticker?pair=' + pair,
    status: 'RESEARCH_ONLY', tradeAuthorized: false, confidence: 'MARKET_QUOTE_ONLY',
    warnings,
  };
}
export async function probeLunoMarket(pair, fetchFn = fetch) {
  if (!ALLOWED_PAIRS.has(pair)) throw new Error('Pair not allowlisted.');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 6000);
  try {
    const response = await fetchFn('https://api.luno.com/api/1/ticker?pair=' + pair,
      { signal: controller.signal, headers: { accept: 'application/json' } });
    if (!response.ok) throw new Error('Market provider returned HTTP ' + response.status);
    return evaluateMarket(await response.json(), pair);
  } finally { clearTimeout(timeout); }
}
