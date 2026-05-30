Quick summary of the user task: Update `aes_seq_item.sv` with additional randomization knobs and constraints to improve AES DV functional coverage while keeping legacy behavior unchanged by default.

Plan summary: Add optional enable switches, introduce new rand selectors and `dist` constraints for operation/key/data length, add data/IV pattern selection with edge-case bias, and map these into fields in `post_randomize()` only when enabled.

Files touched (by plan):
- Edited: `hw/ip/aes/dv/env/aes_seq_item.sv`
- Added: `hw/ip/aes/dv/chipstack_artifacts/code_change_plan.md`
- Added: `hw/ip/aes/dv/chipstack_artifacts/code_change_notes.md`
- Added: `hw/ip/aes/dv/chipstack_artifacts/summary.md`
- Added: `hw/ip/aes/dv/chipstack_artifacts/git_manager.md`

Git branch: `shivang-chipstack-chipstack-aes-constraints`

PR and commit:
- PR: https://github.com/chipstack-ai/opentitan/pull/9
- Head commit: `21f346aebad3f8a3e5cad780c3fb277b1074548b`

Confidence: High

