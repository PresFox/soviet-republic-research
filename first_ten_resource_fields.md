# First ten ResourceRecord fields

Analysis is based on `InitializeHardcodedResourceDefinitions`, `CalculateResourcePriceRecursive` (`FUN_1402A9470`), `FinalizeResourcePricesAndBounds` (`FUN_1402A9F40`), and the dynamic market update at `FUN_1402FB130`.

| Offset | Current name | Confidence | What the code establishes |
|---:|---|---|---|
| `0x44` | `resourceClass_0x44` | Medium | Selects special handling for negative resource classes. Positive values 0–4 are not recursion depth and remain undecoded. |
| `0x50` | `workerPriceMultiplier` | High | When positive, price A and B are derived by multiplying the corresponding workers price. |
| `0x54` | unknown | Low | Nonzero almost exclusively on waste records. Values range from tiny fractions for recyclable waste to 1 for several terminal waste types. No verified consumer has yet been isolated. |
| `0x58` | `calculatedPriceA` | High | Current calculated price on economic side A. Used directly when valuing cargo and production inputs. |
| `0x5C` | `calculatedPriceB` | High | Current calculated price on economic side B. The exact ruble/dollar ordering is not yet proven. |
| `0x78` | `directPriceComponentA` | High | Direct per-resource component added into recursive price A. It is also randomized/scaled during market initialization and temporarily backed up at `+0x80`. |
| `0x7C` | `directPriceComponentB` | High | Parallel direct component for price B, backed up at `+0x84`. |
| `0x88` | `priceRangeMultiplierA_low` | High | Multiplies calculated price A to create one side of its initial allowed/range pair; normally 0.95. |
| `0x8C` | `priceRangeMultiplierA_high` | High | Multiplies calculated price A to create the other side of its range; normally 1.05. |
| `0x98` | `positiveImbalanceScaleA` | High | Divides a positive recent supply/demand imbalance before it is converted into the dynamic price-A multiplier at `+0xA4`. Larger values make price A react less strongly. |

## Closely related fields immediately following these ten

- `+0x9C`: negative-imbalance scale for price A.
- `+0xA0`: cross-couples the second recorded market-flow difference into price-A pressure.
- `+0xA4`: live dynamic multiplier applied to price A.
- `+0xB8/+0xBC`: positive/negative imbalance scales for price B.
- `+0xC0`: inverse cross-coupling coefficient for price-B pressure.
- `+0xC4`: live dynamic multiplier applied to price B.

“A” and “B” are deliberately retained until a caller proves which one is rubles and which one is dollars.
