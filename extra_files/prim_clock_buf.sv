// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Stub abstract wrapper for `prim_clock_buf`.
//
// Upstream OpenTitan auto-generates this wrapper to dispatch between
// `prim_generic_clock_buf` and `prim_xilinx_clock_buf` based on
// `PRIM_DEFAULT_IMPL`.  For the formal flows in this submodule we keep
// only the generic implementation, so this stub delegates straight to it.
//
// Required because `pwrmgr.sv` directly instantiates `prim_clock_buf`.

module prim_clock_buf #(
  parameter bit NoFpgaBuf = 1'b0,
  parameter bit RegionSel = 1'b0
) (
  input        clk_i,
  output logic clk_o
);

  prim_generic_clock_buf #(
    .NoFpgaBuf(NoFpgaBuf),
    .RegionSel(RegionSel)
  ) u_impl_generic (
    .clk_i,
    .clk_o
  );

endmodule
