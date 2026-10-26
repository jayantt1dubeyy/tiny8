// Testbench for tiny_cpu: runs programs/sum1to10, expects out_port = 55.
// Run from sim/:  cp ../programs/sum1to10.hex program.hex
//                iverilog -o tb_cpu.vvp -I ../src ../src/tiny_cpu.v tb_cpu.v && vvp tb_cpu.vvp
`timescale 1ns/1ps

module tb_cpu;
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
    initial begin
        $readmemh("program.hex", dut.rom);
        dut.ram[8'h12] = 8'hFF;   // the -1 constant sum1to10 needs
        #23 rst_n = 1;
        cycles = 0;
        while (!halted && cycles < 10000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        if (!halted) begin
            $display("FAIL: CPU did not halt within %0d cycles", cycles);
        end else if (out_port !== 8'd55) begin
            $display("FAIL: out_port = %0d, expected 55", out_port);
        end else if (dut.ram[8'h11] !== 8'd55) begin
            $display("FAIL: RAM[0x11] = %0d, expected 55", dut.ram[8'h11]);
        end else begin
            $display("PASS: sum 1..10 = %0d, halted after %0d cycles", out_port, cycles);
        end
        $finish;
    end
endmodule
