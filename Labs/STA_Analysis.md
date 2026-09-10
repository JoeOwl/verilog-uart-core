# Static Timing Analysis (STA)

## Given

| Parameter | Value |
|---|---|
| `T_cq` (clock-to-Q) | 0.5 ns |
| `T_su` (setup) | 0.5 ns |
| `T_in` = `T_out` (I/O delays) | 0.5 ns |
| Clock period `T` | 4 ns |

Ideal clock, no skew assumed throughout.

## General Setup-Slack Formulas

```
Input path:                Slack = T − (T_in + T_combo + T_su)
Reg-to-reg path:            Slack = T − (T_cq + T_combo + T_su)
Output path:                Slack = T − (T_cq + T_combo + T_out)
Pure combinational I/O path: Slack = T − (T_in + T_combo + T_out)
```

## Path-by-Path

**1. IN_1 → FF1** (2 ns combo)
Arrival = 0.5 + 2 + 0.5 = 3.0 ns → Slack = 4 − 3.0 = **1.0 ns**

**2. FF1 → FF2** (2 ns combo)
Arrival = 0.5 + 2 + 0.5 = 3.0 ns → Slack = 4 − 3.0 = **1.0 ns**

**3. FF1 → OUT_1** (through the 2.4 ns block)
Arrival = 0.5 + 2.4 + 0.5 = 3.4 ns → Slack = 4 − 3.4 = **0.6 ns**

**4. FF2 → OUT_1** (also through the 2.4 ns block — the two Q outputs join before it)
Arrival = 0.5 + 2.4 + 0.5 = 3.4 ns → Slack = 4 − 3.4 = **0.6 ns**

**5. IN_2 → OUT_2** (pure combinational, 1 ns block)
Arrival = 0.5 + 1 + 0.5 = 2.0 ns → Slack = 4 − 2.0 = **2.0 ns**

## Result

| Path | Slack |
|---|---|
| IN_1 → FF1 | 1.0 ns |
| FF1 → FF2 | 1.0 ns |
| FF1 → OUT_1 | **0.6 ns** |
| FF2 → OUT_1 | **0.6 ns** |
| IN_2 → OUT_2 | 2.0 ns |

**Worst (critical) slack = 0.6 ns**, on the register-to-output paths through the 2.4 ns combinational block (FF1/FF2 → OUT_1). Since it's positive, the design meets timing — but with the least margin on that path, making it the critical path for further optimization.
