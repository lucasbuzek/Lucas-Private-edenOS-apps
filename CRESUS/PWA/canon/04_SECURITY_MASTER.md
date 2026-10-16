# SECURITY MASTER — WORLDWIDE IDENTITY

Never treat a ticker alone as the identity of an investment.

Canonical relationship:
LegalEntity -> Issuer -> Security -> Listing

Listing metadata may include:
- MIC / exchange;
- ticker;
- listing currency;
- timezone;
- trading calendar;
- ISIN;
- FIGI;
- LEI;
- provider identifiers;
- cross-listing relationships.

## Rules
- Disambiguate same/similar tickers across exchanges.
- Distinguish issuer economics from a particular listing.
- Track listing currency separately from reporting/functional currency.
- Do not compare prices across cross-listings without appropriate currency/share-ratio treatment.
- Corporate actions belong to the correct security/listing relationship.
- If identity is uncertain, resolve identity before valuation.
- Worldwide means no hard-coded South Africa/US assumptions.
