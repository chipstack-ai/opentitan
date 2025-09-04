// Lightweight wrappers to map abstract prim modules to generic implementations for simulation.
// This file is added locally to enable standalone AES RTL simulation without FuseSoC generation.

module prim_flop_2sync #(
  parameter int               Width           = 16,
  parameter logic [Width-1:0] ResetValue      = '0,
  parameter bit               EnablePrimCdcRand = 1
) (
  input                    clk_i,
  input                    rst_ni,
  input        [Width-1:0] d_i,
  output logic [Width-1:0] q_o
);
  prim_generic_flop_2sync #(
    .Width(Width),
    .ResetValue(ResetValue),
    .EnablePrimCdcRand(EnablePrimCdcRand)
  ) u_impl (
    .*
  );
endmodule

module prim_flop_en #(
  parameter int               Width      = 1,
  parameter bit               EnSecBuf   = 0,
  parameter logic [Width-1:0] ResetValue = '0
) (
  input                    clk_i,
  input                    rst_ni,
  input                    en_i,
  input        [Width-1:0] d_i,
  output logic [Width-1:0] q_o
);
  prim_generic_flop_en #(
    .Width(Width),
    .EnSecBuf(EnSecBuf),
    .ResetValue(ResetValue)
  ) u_impl (
    .*
  );
endmodule
