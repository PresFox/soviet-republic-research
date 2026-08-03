# Resource fields 21–30: covered, open, and aggregate transport profiles

These ten fields span the first two complete `0x20`-byte resource transport profiles and the first three populated fields of the third profile.

| Profile index | Record base | Game name |
|---:|---:|---|
| 0 | `0xCC` | `RESOURCE_TRANSPORT_COVERED` |
| 1 | `0xEC` | `RESOURCE_TRANSPORT_OPEN` |
| 2 | `0x10C` | `RESOURCE_TRANSPORT_GRAVEL` |

## Fields

| Offset | Research name | Confidence | Interpretation |
|---:|---|---|---|
| `0xCC` | `coveredCapacityConversionFactor` | High | Covered-transport compatibility and resource amount/capacity conversion factor. |
| `0xD0` | `coveredVisualParameterA` | Medium-low | First covered-cargo presentation/geometry parameter; exact axis and units are not proven. |
| `0xD4` | `coveredVisualParameterB` | Medium-low | Second covered-cargo presentation/geometry parameter. It always equals `0xD0` in the current table. |
| `0xE8` | `coveredProfileFlag` | Low | Boolean at the end of the covered profile. Its consumer-side purpose remains unresolved. |
| `0xEC` | `openCapacityConversionFactor` | High | Open-transport compatibility and amount/capacity conversion factor. |
| `0xF0` | `openVisualParameterA` | Medium-low | First open-cargo presentation/geometry parameter. |
| `0xF4` | `openVisualParameterB` | Medium-low | Second open-cargo presentation/geometry parameter. |
| `0x10C` | `aggregateCapacityConversionFactor` | High | Aggregate/gravel compatibility and amount/capacity conversion factor. |
| `0x110` | `aggregateVisualParameterA` | Medium-low | First aggregate presentation parameter; likely pile/particle geometry or scaling. |
| `0x114` | `aggregateVisualParameterB` | Medium-low | Second aggregate presentation parameter. Values such as `30` suggest an angle or extent, but this is unproven. |

## Proven consumer behavior

`CollectResourcesCompatibleWithTransportType` (`1402AAC20`) reads:

```text
ResourceRecord + 0xCC + transportType × 0x20
```

Every resource with a positive leading factor is added to the compatible-resource list. Storage and logistics routines also multiply or divide resource amounts by the same factor. It therefore provides both transport-profile compatibility and conversion between nominal amount and a capacity unit.

The resource record does not contain one exclusive cargo-type enum. It contains a profile for every transport type, so one resource may have positive factors in several profiles.

## Newly decoded functions

| Address | Research name | Meaning |
|---:|---|---|
| `1402A15A0` | `ParseResourceTransportType` | Converts `RESOURCE_TRANSPORT_*` strings into indices 0–17. |
| `1400E4CB0` | `ResourceTransportTypeToName` | Converts a numeric transport type back into its configuration string. |
| `1402AAC20` | `CollectResourcesCompatibleWithTransportType` | Builds the resources accepted by a transport/storage type from the repeated profile factors. |

## Complete transport-type index

| Index | Name | Index | Name |
|---:|---|---:|---|
| 0 | `COVERED` | 9 | `ELETRIC` |
| 1 | `OPEN` | 10 | `VEHICLES` |
| 2 | `GRAVEL` | 11 | `GENERAL` |
| 3 | `OIL` | 12 | `NUCLEAR1` |
| 4 | `CEMENT` | 13 | `NUCLEAR2` |
| 5 | `COOLER` | 14 | `HEATING` |
| 6 | `LIVESTOCK` | 15 | `WATER` |
| 7 | `PASSANGER` | 16 | `SEWAGE` |
| 8 | `CONCRETE` | 17 | `WASTE` |

`PASSANGER` and `ELETRIC` preserve the game's own spelling.

The exact meanings of the later fields in each profile still require a rendering or cargo-layout consumer. They should remain tentative rather than being asserted as width, length, or angle.
