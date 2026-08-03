# First ten ResourceRecord fields

Analysis is based on `InitializeHardcodedResourceDefinitions`, `CalculateResourcePriceRecursive` (`FUN_1402A9470`), `FinalizeResourcePricesAndBounds` (`FUN_1402A9F40`), and the dynamic market update at `FUN_1402FB130`.

| Offset | Current name | Confidence | What the code establishes |
|---:|---|---|---|
| `0x44` | `resourceClass_0x44` | Medium | Selects special handling for negative resource classes. Positive values 0–4 are not recursion depth and remain undecoded. |
| `0x50` | `workerPriceMultiplier` | High | When positive, price A and B are derived by multiplying the corresponding workers price. |
| `0x54` | unknown | Low | Nonzero almost exclusively on waste records. Values range from tiny fractions for recyclable waste to 1 for several terminal waste types. No verified consumer has yet been isolated. |
| `0x58` | `dollarBuyPrice` | High | Matches the dollar Buy column in the global-market GUI exactly after display rounding. |
| `0x5C` | `rubleBuyPrice` | High | Matches the ruble Buy column in the global-market GUI exactly after display rounding. |
| `0x78` | `directDollarPriceComponent` | High | Direct per-resource component added into recursive dollar pricing. It is also randomized/scaled during market initialization and temporarily backed up at `+0x80`. |
| `0x7C` | `directRublePriceComponent` | High | Parallel direct component for ruble pricing, backed up at `+0x84`. |
| `0x88` | `dollarSellMultiplier` | High | Normally 0.95; creates the dollar sell side of the price pair. |
| `0x8C` | `dollarBuyMultiplier` | High | Normally 1.05; creates the dollar buy side of the price pair. |
| `0x98` | `positiveImbalanceScaleDollar` | High | Divides positive recent supply/demand imbalance before it becomes the dynamic dollar-price multiplier at `+0xA4`. |

## Closely related fields immediately following these ten

- `+0x9C`: negative-imbalance scale for price A.
- `+0xA0`: cross-couples the second recorded market-flow difference into price-A pressure.
- `+0xA4`: live dynamic multiplier applied to price A.
- `+0xB8/+0xBC`: positive/negative imbalance scales for price B.
- `+0xC0`: inverse cross-coupling coefficient for price-B pressure.
- `+0xC4`: live dynamic multiplier applied to price B.

The global-market GUI comparison identifies side A as dollars and side B as rubles. For normal positive prices, `sell = buy × 0.95 / 1.05`, matching the displayed values to two decimals.
