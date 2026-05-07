// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Stub abstract wrapper for `prim_otp`.
//
// Upstream OpenTitan auto-generates this wrapper to dispatch between
// vendor-specific OTP macros based on `PRIM_DEFAULT_IMPL`.  For the formal
// flows in this submodule we keep only the generic implementation, so this
// stub mirrors the parameter / port list of `prim_generic_otp` and
// delegates the connection with `.*`.
//
// Required because `otp_ctrl.sv` directly instantiates `prim_otp`.

module prim_otp
  import prim_otp_pkg::*;
#(
  parameter  int Width            = 16,
  parameter  int Depth            = 1024,
  parameter  int SizeWidth        = 2,
  parameter  int PwrSeqWidth      = 2,
  parameter  int TestCtrlWidth    = 32,
  parameter  int TestStatusWidth  = 32,
  parameter  int TestVectWidth    = 8,
  localparam int AddrWidth        = prim_util_pkg::vbits(Depth),
  localparam int IfWidth          = 2**SizeWidth*Width,
  parameter      MemInitFile      = "",
  parameter  int VendorTestOffset = 0,
  parameter  int VendorTestSize   = 0
) (
  input                              clk_i,
  input                              rst_ni,
  input  ast_pkg::ast_obs_ctrl_t     obs_ctrl_i,
  output logic [7:0]                 otp_obs_o,
  output logic [PwrSeqWidth-1:0]     pwr_seq_o,
  input        [PwrSeqWidth-1:0]     pwr_seq_h_i,
  inout  wire                        ext_voltage_io,
  input        [TestCtrlWidth-1:0]   test_ctrl_i,
  output logic [TestStatusWidth-1:0] test_status_o,
  output logic [TestVectWidth-1:0]   test_vect_o,
  input  tlul_pkg::tl_h2d_t          test_tl_i,
  output tlul_pkg::tl_d2h_t          test_tl_o,
  input  prim_mubi_pkg::mubi4_t      scanmode_i,
  input                              scan_en_i,
  input                              scan_rst_ni,
  output logic                       fatal_alert_o,
  output logic                       recov_alert_o,
  output logic                       ready_o,
  input                              valid_i,
  input        cmd_e                 cmd_i,
  input        [SizeWidth-1:0]       size_i,
  input        [AddrWidth-1:0]       addr_i,
  input        [IfWidth-1:0]         wdata_i,
  output logic                       valid_o,
  output logic [IfWidth-1:0]         rdata_o,
  output       err_e                 err_o
);

  prim_generic_otp #(
    .Width            (Width),
    .Depth            (Depth),
    .SizeWidth        (SizeWidth),
    .PwrSeqWidth      (PwrSeqWidth),
    .TestCtrlWidth    (TestCtrlWidth),
    .TestStatusWidth  (TestStatusWidth),
    .TestVectWidth    (TestVectWidth),
    .MemInitFile      (MemInitFile),
    .VendorTestOffset (VendorTestOffset),
    .VendorTestSize   (VendorTestSize)
  ) u_impl_generic (.*);

endmodule
