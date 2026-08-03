# Resource fields 11–20: dynamic market pricing

These are the next ten populated fields in the `0x340`-byte resource record, covering offsets `0x9C` through `0xC8`.

## Results

| Offset | Research name | Confidence | Meaning |
|---:|---|---|---|
| `0x9C` | `negativeImbalanceScaleDollar` | High | Divisor controlling how strongly a negative dollar-side market imbalance changes the live dollar price multiplier. |
| `0xA0` | `rubleFlowCouplingIntoDollar` | High | Weight by which the ruble-side flow imbalance contributes to dollar-side market pressure. Usually `0.5`; a few resources use `0.65`, `0.75`, or `0.85`. |
| `0xA4` | `dynamicDollarPriceMultiplier` | High | Live dollar price multiplier. Initialized to `1`, recalculated from recent trade/flow imbalance, and clamped to `0.15–15`. |
| `0xA8` | `rubleSellMultiplier` | High | Multiplier used to derive the ruble sell-price bound; normally `0.95`. |
| `0xAC` | `rubleBuyMultiplier` | High | Multiplier used to derive the ruble buy-price bound; normally `1.05`. |
| `0xB8` | `positiveImbalanceScaleRuble` | High | Divisor controlling the ruble multiplier's response to positive market pressure. |
| `0xBC` | `negativeImbalanceScaleRuble` | High | Divisor controlling the ruble multiplier's response to negative market pressure. |
| `0xC0` | `dollarFlowCouplingIntoRuble` | High | Weight by which dollar-side flow imbalance contributes to ruble-side market pressure. It mirrors `0xA0` in the current table. |
| `0xC4` | `dynamicRublePriceMultiplier` | High | Live ruble price multiplier. Initialized to `1`, recalculated from recent trade/flow imbalance, and clamped to `0.15–15`. |
| `0xC8` | `resourcePairingEligibilityFlag` (tentative) | Medium-low | Boolean used when building runtime pairs/cache entries between resource-handling objects. It is not consumed by the dynamic-price calculation. Exact player-facing purpose remains unknown. |

## Dynamic-price flow

`UpdateDynamicResourceMarketPrices` (`1402FB130`) constructs two currency-specific pressure values from recent economic flows:

```text
dollar pressure = dollar flow difference + ruble flow difference × field 0xA0
ruble pressure  = ruble flow difference  + dollar flow difference × field 0xC0
```

Positive and negative pressure use separate scale/divisor fields. The results update `0xA4` and `0xC4`, which are then consumed by `FinalizeResourcePricesAndBounds` (`1402A9F40`) to produce the live dollar and ruble price bounds.

This means these fields do not describe manufacturing difficulty. They describe how volatile each resource's world-market price is and how activity in one currency market influences the other.

## `0xC8` observations

The flag is `1` for exactly 15 current resources:

```text
plants, chemicals, uf6, nuclearfuel, nuclearfuelburned,
fabric, alcohol, food, clothes, meat, ecomponents,
mcomponents, plastics, eletronics, explosives
```

It is read by `FUN_1401DF6B0` and `FUN_1401E2310`. Both functions iterate runtime resource-handling objects and only create certain pair/cache records when the other object's resource has this flag. This supports a pairing or transfer-eligibility interpretation, but does not yet prove whether it represents packaged goods, a logistics rule, or another production/distribution distinction.

## Functions examined

| Address | Research name | What it contributed |
|---:|---|---|
| `1402FB130` | `UpdateDynamicResourceMarketPrices` | Directly reads the imbalance scales and cross-currency weights, then writes the two live multipliers. |
| `1402A9F40` | `FinalizeResourcePricesAndBounds` | Applies the live multipliers and the currency-specific buy/sell multipliers to final market prices. |
| `1401DF6B0` | raw name retained | Rebuilds runtime resource-pair/cache records and checks associated resource field `0xC8`. |
| `1401E2310` | raw name retained | A larger related resource-distribution/cache rebuild that also checks `0xC8`. |
| `1401C1700` | raw name retained | Runtime caller of `1401DF6B0`. |
| `1401C5FE0` | raw name retained | Runtime caller of `1401E2310`. |
| `1401C6D60` | raw name retained | Second runtime caller of `1401E2310`. |

The last five functions are listed without invented semantic names until their containing gameplay system is identified with higher confidence.
