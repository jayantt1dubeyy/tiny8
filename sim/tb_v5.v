// Testbench for tiny8 v5: 64KB paged memory (LDAX/STAX).
// Run from sim/:
//   iverilog -o tb_v5.vvp ../src/tiny_cpu.v tb_v5.v && vvp tb_v5.vvp
`timescale 1ns/1ps

module tb_v5;
    reg clk = 0;
    reg rst_n = 0;
    reg [7:0] in_port = 0;
    wire [7:0] out_port;
    wire halted;

    tiny_cpu dut (
        .clk(clk), .rst_n(rst_n), .in_port(in_port),
        .out_port(out_port), .halted(halted)
    );

    always #5 clk = ~clk;

    integer cycles;
    integer fails;

    initial begin
        fails = 0;
        rst_n = 0;
        $readmemh("../programs/page_demo.hex", dut.rom);
        #23;
        rst_n = 1;
        cycles = 0;
        while (!halted && cycles < 10000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        if (!halted) begin
            $display("FAIL: page_demo did not halt");
            fails = fails + 1;
        end else if (out_port !== 8'd99) begin
            $display("FAIL: out %0d, expected 99", out_port);
            fails = fails + 1;
        end else begin
            $display("PASS: page_demo out 99 after %0d cycles", cycles);
        end
        if (dut.ram[16] !== 8'd42) begin
            $display("FAIL: RAM[16] = %0d, expected 42", dut.ram[16]);
            fails = fails + 1;
        end else begin
            $display("PASS: zero-page RAM[16] = 42");
        end
        if (dut.ram[288] !== 8'd99) begin
            $display("FAIL: RAM[288] = %0d, expected 99", dut.ram[288]);
            fails = fails + 1;
        end else begin
            $display("PASS: page-1 RAM[288] = 99");
        end
        if (dut.ram[767] !== 8'd7) begin
            $display("FAIL: RAM[767] = %0d, expected 7", dut.ram[767]);
            fails = fails + 1;
        end else begin
            $display("PASS: page-2 RAM[767] = 7");
        end
        if (fails == 0)
            $display("PASS: all v5 cases correct");
        else
            $display("FAIL: %0d case(s) failed", fails);
        $finish;
    end
endmodule
