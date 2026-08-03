# Resource table analysis

Source: `FUN_1402A1D60` and the post-processing functions `FUN_1402A92D0` and `FUN_1402A9F40`.

## Container and record layout

- Resource vector: `GameData + 0xC2B0` (begin), `+0xC2B8` (end), `+0xC2C0` (capacity).
- Record size: `0x340` bytes.
- `+0x00`: inline internal-name string.
- `+0x40`: localization ID.
- `+0x318`, `+0x320`, `+0x328`, `+0x330`, `+0x338`: up to five loaded mesh pointers.

## Confirmed or strongly supported fields

| Offset | Proposed name | Confidence | Evidence |
|---:|---|---|---|
| `0x44` | `resourceClass_0x44` | Medium | A classification used mainly for special handling of negative classes. Positive values 0–4 are not used as recursion depth by `FUN_1402A9470`; their precise distinction remains unknown. |
| `0x50` | `workerBasedDisposalCostMultiplier` | High | `FUN_1402A9F40` multiplies both currency prices of `workers` by this value and flips their sign, creating negative disposal-value prices for spent fuel and selected waste types. |
| `0x54` | `compositeWastePriceContributionMultiplier` | High | `FUN_140197CB0` and `FUN_140197D80` multiply a component's amount and currency price by this field when valuing mixed or hazardous waste compositions. |
| `0x58` | `dollarBuyPrice` | High | Matches the global-market dollar Buy value exactly after display rounding. |
| `0x5C` | `rubleBuyPrice` | High | Matches the global-market ruble Buy value exactly after display rounding. |
| `0x60` | `dollarSellPrice` | High | The other dollar price bound paired with the buy price at `+0x58`. |
| `0x64` | `rubleSellPrice` | High | The other ruble price bound paired with the buy price at `+0x5C`. |
| `0x68`, `0x6C` | `dollar/rubleProductionCostAdjustment` | Medium-high | Calculated by scanning building production recipes and added to the corresponding currency prices. |
| `0x70`, `0x74` | `specialDollar/RublePriceCopy` | High | Currency-specific copies of computed prices for resources whose class sentinel is `-2`. |
| `0x88`, `0x8C` | `dollarSell/BuyMultiplier` | High | Dollar-side price multipliers, usually 0.95 and 1.05. |
| `0xA4` | `dynamicDollarPriceMultiplier` | High | Live supply/demand multiplier applied to dollar pricing. |
| `0xA8`, `0xAC` | `rubleSell/BuyMultiplier` | High | Ruble-side price multipliers, usually 0.95 and 1.05. |
| `0xC4` | `dynamicRublePriceMultiplier` | High | Live supply/demand multiplier applied to ruble pricing. |
| `0x9C`, `0xB8`, `0xBC` | `dynamicMarketImbalanceScales` | High | Currency- and sign-specific divisors controlling how strongly supply/demand pressure moves the live price multipliers. |
| `0xA0`, `0xC0` | `crossCurrencyFlowCoupling` | High | Weights by which flow imbalance in one currency market contributes to pressure in the other. |
| `0xC8` | `resourcePairingEligibilityFlag` (tentative) | Medium-low | Gates creation of resource-pair/cache records in `FUN_1401DF6B0` and `FUN_1401E2310`; it is not a price field. |
| `0x2EC` | `isWasteResource` | High | Explicitly set only for the ten waste/fertiliser records. |
| `0x30C` | `recyclingMaterialFamily` | High | Groups resources with the corresponding recoverable waste/material family; it does not match transport cargo classes. |

The global-market GUI comparison proves that side A is dollars and side B is rubles. With the usual 0.95/1.05 pair, a normal positive sell price equals `buy × 0.95 / 1.05`.

### `resourceClass_0x44` observations

- Positive values `0`–`4` correlate loosely with resource groups, but the recursive price calculator treats them equivalently.
- Price recursion follows actual building input/output recipes, independently of this number.
- `-1` through `-5` are special/nonstandard resource classes. `-1`, `-2`, and `-5` receive explicit price-return handling.
- Chemicals and explosives being class `0` does not mean the game considers them easy to manufacture.

## Repeated transport/presentation profiles

The middle of the record is not a collection of unrelated flags. It contains repeated profile blocks. A typical block begins with an enable/scale value and is followed by dimensions or capacity/presentation parameters. Confirmed block starts include:

- `0xCC`: packaged/general cargo profile
- `0xEC`: open-storage profile
- `0x10C`: aggregate profile
- `0x12C`: liquid profile
- `0x14C`: dry-bulk profile

Further blocks continue at roughly `0x20` intervals through the record. Some values persist because the initializer reuses one temporary `0x340` record and its constructor supplies defaults. Therefore a nonzero value alone does **not** prove that a resource belongs to that cargo category. The consumers of each block must be traced before naming all of them.

`FUN_1402AAC20` now provides direct consumer-side proof of this layout. Given a cargo/storage category from 0 through 17, it tests `ResourceRecord + 0xCC + category * 0x20`; resources whose value is positive are collected as compatible with that category. The exact category-number-to-name mapping still needs to be established.

The table does not currently expose a proven single `cargoType` enum. Vehicle/building compatibility may use these profiles together with external vehicle/storage definitions rather than one resource field.

## Recycling families (`+0x30C`)

| Value | Members |
|---:|---|
| 10 | gravel, rawgravel, prefabpanels, bricks, cement, asphalt, concrete, waste_gravel |
| 11 | steel, iron, rawiron, mcomponents, waste_steel |
| 12 | aluminium, bauxite, rawbauxite, alumina, waste_aluminium |
| 13 | ecomponents, plastics, eletronics, waste_plastic |
| 14 | plants, fertiliser_liquid, waste_bio |
| 15 | food, meat, livestock, fertiliser |
| 16 | wood, boards, waste_burnable |
| 17 | oil, chemicals, bitumen, uranium, yellowcake, uf6, nuclearfuel, nuclearfuelburned, fuel, alcohol, explosives, waste_toxic |
| 18 | vehicles, trains, fabric, clothes, waste_other |
| 19 | coal, rawcoal, waste_ash |
| `-1` | workers, eletric, heat, water, usagewater |

This is a material/recycling relationship, not necessarily a production-chain relationship. That explains seemingly odd groupings such as alcohol with petrochemical and toxic materials.

## Still unresolved

- `+0x78/+0x7C` are confirmed direct price components; their precise economic labels remain unknown.
- `+0x98/+0x9C/+0xA0` and `+0xB8/+0xBC/+0xC0` are confirmed dynamic-market response coefficients. Their mathematical roles are known, although official player-facing terminology is not.
- `+0xC8` gates a runtime resource-pairing/cache path. Its exact logistics or production meaning remains unresolved. `+0x248` is also still unresolved.
- Exact semantics and consumers of every repeated transport/presentation block.
- `+0x310` (normally 0.3, but 1 for two records); likely a global physical/economic scaling parameter, not safely nameable yet.

## Main conclusion

The resource record combines four systems: identity/localization, economic price derivation, cargo presentation/physical profiles, and recycling/waste classification. The cleanest first modding target is the economic section and the named identity/assets. Cargo compatibility needs consumer-side analysis before its fields can safely be externalized.
