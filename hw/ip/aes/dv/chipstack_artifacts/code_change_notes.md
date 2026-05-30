# Code Change Notes — AES DV

- Date: 2025-09-04 20:40:00 UTC
- Chat Session: 1

## Summary
Updated `env/aes_seq_item.sv` to improve randomization and constraints for better coverage. Fixed a constraint syntax issue and ensured new enable knobs are preserved during item copying.

## Changes
- Added optional enable knobs (default-off): `randomize_operation_en`, `randomize_key_len_en`, `randomize_data_len_en`.
- Introduced rand selectors: `operation_rand`, `key_len_rand`, `data_len_rand`, `data_pattern_sel`, `iv_pattern_sel`.
- Added distribution constraints gated by knobs for operation/key/data length; added pattern selection distributions favoring random with occasional corner cases.
- Enhanced `post_randomize()` to map selectors to main fields when enabled and to generate corner-case data/IV patterns.
- Fixed missing semicolon in `back2back_c` constraint else-branch.
- Updated `do_copy()` to copy the new enable knobs for backward-compatible behavior when items are cloned.

## Rationale
- Better exploration of ENC/DEC, key lengths (128/192/256), various `data_len` edges, and data/IV corner patterns to lift functional coverage.
- Keep defaults stable by gating key behavior behind enable switches; pattern selection remains largely random-biased.

## Files Touched
- Modified: `env/aes_seq_item.sv`

## Verification Plan (next steps)
- Compile DV to ensure no LRM errors (semicolon fix addresses one).
- Run smoke with knobs disabled to confirm stability.
- Run focused tests with knobs enabled to assess coverage lift.

