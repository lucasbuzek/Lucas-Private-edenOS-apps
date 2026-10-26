export function totalReturn({entryPrice, exitPrice, dividends=0, buyCosts=0, sellCosts=0, taxes=0}) {
  if (!(entryPrice>0) || !(exitPrice>=0)) throw new Error("invalid prices");
  const pricePnL=exitPrice-entryPrice;
  const netDividends=dividends-taxes;
  const costs=buyCosts+sellCosts;
  const netPnL=pricePnL+netDividends-costs;
  return {
    priceReturn: pricePnL/entryPrice,
    grossDividendReturn: dividends/entryPrice,
    taxDrag: taxes/entryPrice,
    costDrag: costs/entryPrice,
    totalReturn: netPnL/entryPrice,
    netPnL
  };
}

export function dividendCaptureScenario({
  buyPrice, sellPrice, dividend, quantity=1,
  commissionBuy=0, commissionSell=0, spreadCost=0, slippage=0,
  dividendTaxRate=0
}) {
  if (quantity<=0) throw new Error("quantity must be positive");
  const grossDividend=dividend*quantity;
  const taxes=grossDividend*dividendTaxRate;
  const entry=buyPrice*quantity;
  const exit=sellPrice*quantity;
  return totalReturn({
    entryPrice:entry,
    exitPrice:exit,
    dividends:grossDividend,
    buyCosts:commissionBuy+spreadCost/2+slippage/2,
    sellCosts:commissionSell+spreadCost/2+slippage/2,
    taxes
  });
}

export function assertNoLookahead({decisionAt, eventKnownAt}) {
  if (!eventKnownAt) throw new Error("event knowledge timestamp required for backtest");
  if (Date.parse(eventKnownAt)>Date.parse(decisionAt)) throw new Error("look-ahead bias: event not known at decision time");
  return true;
}
