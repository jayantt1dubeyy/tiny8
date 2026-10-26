// TinyTapeout wrapper for tiny8 v6 (NOT a submitted tapeout — see below).
//
// Maps the CPU onto the TinyTapeout digital interface:
//   ui_in[7:0]  -> in_port  (one input byte per run, as in the testbenches)
//   uo_out[7:0] -> out_port (the CPU's single output byte)
//   uio_out[0]  -> halted
//   uio_oe      -> 0 (all uio pins are inputs in this design)
//   rst_n       -> active-low reset, clk -> CPU clock, ena -> ignored
//
// What this is and is not: this file compiles and elaborates against
// tiny_cpu.v, so the CPU is structurally ready to be wrapped for a
// shuttle. It is NOT a submission: a real TinyTapeout submission needs
// the project config, pin documentation, and a shuttle slot from
// Jayant's own TinyTapeout account, plus synthesis with the SkyWater
// 130nm PDK (the 64KB RAM/ROM arrays here are simulation memories and
// would need to be mapped to SRAM macros for a real chip).
`default_nettype none

module tt_um_tiny8 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ena,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe
);
    wire halted;
    wire unused = &{ena, uio_in};

    tiny_cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_port(ui_in),
        .out_port(uo_out),
        .halted(halted)
    );

    assign uio_out = {7'b0, halted};
    assign uio_oe = 8'b0;

endmodule
