# Remaining resource-table columns

## Structural result

The resource record's numeric columns are now structurally accounted for:

1. identity and localization (`0x00–0x44`);
2. static and dynamic economy (`0x50–0xC4`);
3. one tentative runtime pairing flag (`0xC8`);
4. eighteen `0x20`-byte transport profiles (`0xCC–0x30B`);
5. recycling/material-family classification (`0x30C`);
6. one unresolved global scaling value (`0x310`);
7. five mesh/material pointers (`0x318–0x338`).

There are therefore no longer dozens of unrelated mystery columns in the middle of the record. Most belong to the same repeated transport-profile structure.

## Transport profiles

Each profile begins at:

```text
profileBase = ResourceRecord + 0xCC + transportType × 0x20
```

| Index | Transport type | Base | Populated fields currently exposed |
|---:|---|---:|---|
| 0 | Covered | `0xCC` | factor, visual A/B, flag |
| 1 | Open | `0xEC` | factor, visual A/B |
| 2 | Gravel/aggregate | `0x10C` | factor, visual A/B |
| 3 | Oil | `0x12C` | factor, visual A/B, flow A/B |
| 4 | Cement | `0x14C` | factor, visual A/B |
| 5 | Cooler | `0x16C` | factor, visual A/B |
| 6 | Livestock | `0x18C` | factor, visual A/B |
| 7 | Passenger | `0x1AC` | factor, visual A/B |
| 8 | Concrete | `0x1CC` | factor, visual A/B |
| 9 | Electric | `0x1EC` | factor, visual A/B |
| 10 | Vehicles | `0x20C` | factor, visual A/B |
| 11 | General | `0x22C` | factor, visual A/B, flag |
| 12 | Nuclear 1 | `0x24C` | factor, visual A/B |
| 13 | Nuclear 2 | `0x26C` | factor, visual A/B |
| 14 | Heating | `0x28C` | factor, visual A/B |
| 15 | Water | `0x2AC` | factor, visual A/B, flow A/B |
| 16 | Sewage | `0x2CC` | factor, visual A/B, flow A/B |
| 17 | Waste | `0x2EC` | factor, visual A/B |

### Leading factor

The leading float of every profile is high-confidence:

- a positive value enables/qualifies the resource for that transport type;
- storage and logistics calculations use it to convert resource quantities into effective capacity;
- the value is selected dynamically with `0xCC + type × 0x20`.

The former `isWasteResource` at `0x2EC` is therefore more precisely the leading factor of the waste transport profile. It happens to behave like a Boolean in the current table because waste resources use `1` and other resources use `0`.

### Later profile parameters

Offsets `+0x04` and `+0x08` within profiles vary in ways consistent with cargo presentation, layout, pile dimensions, or rendering scale. Liquid-like profiles additionally populate `+0x0C` and `+0x10`, consistent with flow/presentation parameters. Exact axes and units have not been proven, so the table deliberately uses `VisualParameter*` and `FlowParameter*` tentative names.

Flags at profile offset `+0x1C` are populated for the covered and general profiles. Their precise meaning is still unknown.

## Tail fields

| Offset | Name | Confidence | Status |
|---:|---|---|---|
| `0x30C` | `recyclingMaterialFamily` | High | Relates resources to the waste/material family from which they can be recovered or with which they are grouped. |
| `0x310` | `unknown_0x310` | Low | `1` for workers and electricity; approximately `0.3` for every other resource. Candidate scans did not isolate a credible direct consumer. |
| `0x318–0x338` | `meshAndMaterialAssets[5]` | High | Up to five loaded mesh/material pointers associated with the resource definition. |

## Important limitation

The table now has structural names for essentially every populated column, but structure is not the same as exact gameplay semantics. The capacity factors are proven. The profile subparameters are correctly assigned to their transport type, but their exact rendering/physics meanings still need runtime experiments or a clear low-level rendering consumer.
