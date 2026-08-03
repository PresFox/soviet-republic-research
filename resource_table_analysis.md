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
| `0x44` | `productionChainDepth` | High | The recursive price calculation uses it as dependency depth. Ordinary values are 0–4; special resources use negative sentinels. |
| `0x50` | `workerPriceMultiplier` | High | When positive, `FUN_1402A9F40` derives both prices by multiplying the workers-resource prices by this value. |
| `0x58` | `calculatedPriceA` | High | Written by the recursive resource-price calculator and subsequently adjusted and bounded. |
| `0x5C` | `calculatedPriceB` | High | Second price calculated in parallel with `+0x58`. Exact market/currency ordering is not yet proven. |
| `0x60` | `priceBoundA` | High | Calculated from price A and a multiplier; swapped with `+0x58` if the ordering is reversed. |
| `0x64` | `priceBoundB` | High | Calculated from price B and a multiplier; swapped with `+0x5C` if required. |
| `0x68`, `0x6C` | `productionCostAdjustmentA/B` | Medium-high | Calculated by scanning building production recipes and added to the two prices. |
| `0x70`, `0x74` | `specialPriceCopyA/B` | High | Copies of the computed prices for resources whose chain-depth sentinel is `-2`. |
| `0x88`, `0x8C` | `priceMultiplierA_low/high` | High | Directly multiply price A/bound A. Usually 0.95 and 1.05. |
| `0xA4` | `priceMultiplierA_base` | High | Direct multiplier applied to price A; currently 1 for every resource. |
| `0xA8`, `0xAC` | `priceMultiplierB_low/high` | High | Directly multiply price B/bound B. Usually 0.95 and 1.05. |
| `0xC4` | `priceMultiplierB_base` | High | Direct multiplier applied to price B; currently 1 for every resource. |
| `0x2EC` | `isWasteResource` | High | Explicitly set only for the ten waste/fertiliser records. |
| `0x30C` | `recyclingMaterialFamily` | High | Groups resources with the corresponding recoverable waste/material family; it does not match transport cargo classes. |

`price A/B` deliberately avoids assigning rubles versus dollars until a caller proves the ordering.

### `productionChainDepth` special values

- `0`: raw resource
- `1`–`4`: increasing production dependency depth
- `-1`, `-2`, `-3`, `-4`, `-5`: special/nonstandard resources. Their exact individual meanings need separate caller analysis; `-2` and `-5` receive explicit special price handling.

## Repeated transport/presentation profiles

The middle of the record is not a collection of unrelated flags. It contains repeated profile blocks. A typical block begins with an enable/scale value and is followed by dimensions or capacity/presentation parameters. Confirmed block starts include:

- `0xCC`: packaged/general cargo profile
- `0xEC`: open-storage profile
- `0x10C`: aggregate profile
- `0x12C`: liquid profile
- `0x14C`: dry-bulk profile

Further blocks continue at roughly `0x20` intervals through the record. Some values persist because the initializer reuses one temporary `0x340` record and its constructor supplies defaults. Therefore a nonzero value alone does **not** prove that a resource belongs to that cargo category. The consumers of each block must be traced before naming all of them.

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

- Exact identities of price A and price B.
- `+0x54`, `+0x78`, `+0x7C`, `+0x98`, `+0x9C`, `+0xA0`, `+0xB8`, `+0xBC`, `+0xC0`.
- `+0xC8` and `+0x248`: real classification flags, but neither uniquely denotes citizen-consumed goods.
- Exact semantics and consumers of every repeated transport/presentation block.
- `+0x310` (normally 0.3, but 1 for two records); likely a global physical/economic scaling parameter, not safely nameable yet.

## Main conclusion

The resource record combines four systems: identity/localization, economic price derivation, cargo presentation/physical profiles, and recycling/waste classification. The cleanest first modding target is the economic section and the named identity/assets. Cargo compatibility needs consumer-side analysis before its fields can safely be externalized.
