# AES DV Code Change Plan — Improve Randomization and Constraints

- Date: 2025-09-04 20:37:20 UTC
- Chat Session: 1
- Repo Path: `hw/ip/aes/dv`
- Target File: `env/aes_seq_item.sv`

## Summary
Enhance `aes_seq_item` randomization and constraints to better explore corner cases and balance distributions, improving functional coverage across AES modes, key lengths, operations, data/IV patterns, and back-to-back behavior. No RTL changes. DV-only updates with optional knobs to preserve backward compatibility.

## Current State (as observed)
- `aes_seq_item.sv` defines control knobs and randomizable fields for data, with existing constraints for back-to-back and clear register behavior.
- There are basic/legacy behaviors for data/key masking and IV handling.

## Planned Changes
1) Add optional randomization knobs (gated enables) so legacy tests remain stable by default:
- `randomize_operation_en`, `randomize_key_len_en`, `randomize_data_len_en` (booleans)

2) Introduce new rand selectors to drive variety and edge cases:
- `rand bit [1:0] operation_rand` with ENC/DEC balanced distribution.
- `rand bit [2:0] key_len_rand` to sweep 128/192/256.
- `rand bit [3:0] data_len_rand` with bias toward 0/1/15 and mid-range.
- `rand int unsigned data_pattern_sel`, `rand int unsigned iv_pattern_sel` selecting corner-case patterns (all-zeros, all-ones, 0xAA/0x55, ascending, fully-random).

3) Add constraints to shape distributions and edge coverage when knobs are enabled:
- `operation_rand_c`, `key_len_rand_c`, `data_len_rand_c` using `dist`.
- `data_pattern_sel_c`, `iv_pattern_sel_c` favoring mostly random but occasionally corner cases.

4) Map the randomized selectors into the main fields in `post_randomize()` only when enabled:
- Apply `operation_rand`→`operation`, `key_len_rand`→`key_len`, `data_len_rand`→`data_len`.
- Generate data/IV corner patterns when selected; otherwise preserve randomized values.

5) Keep existing behaviors intact:
- Maintain key masking for unused key words per `key_len`.
- Mask unused data bytes based on `data_len`.
- Preserve existing back-to-back and clear-register constraints/flows.

6) Optional follow-ups (non-blocking in this change):
- Add a light-weight `reseed_rate` randomization and constraint if coverage indicates gaps.
- Consider cross-coverage points in covergroups (separate files) for `mode x operation x key_len` and `data_len x pattern`.
- Add sequence-level switches to toggle the new enable knobs in targeted tests/regressions.

## Affected Files (planned)
- Modify: `env/aes_seq_item.sv` — add rand fields, enable knobs, constraints, and `post_randomize()` logic as described.
- No other DV or RTL files changed in this plan.

## Testing and Coverage
- Compile DV to ensure no LRM/lint issues.
- Run a smoke regression with knobs disabled (backward-compat check).
- Run focused regression with knobs enabled to observe coverage lift in:
  - Modes: ECB/CBC/CFB/OFB/CTR
  - Ops: ENC/DEC
  - Key lengths: 128/192/256
  - Data/IV patterns and `data_len` edge values
- Compare coverage reports and ensure no test destabilization.

## Risks and Mitigations
- Risk: Changing default behavior. Mitigation: keep knobs off by default; only opt-in tests use them.
- Risk: Over-constraining randomization leading to failures. Mitigation: use soft distributions and keep fallbacks.

## Rollout
- Stage 1: Land `aes_seq_item.sv` updates with knobs default-off.
- Stage 2: Update/author tests to enable knobs in selected regressions and monitor coverage.

