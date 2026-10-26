// Testbench for tiny8 v6: 16-bit PC, far jumps, 2-byte return addresses.
// Run from sim/:
//   iverilog -o tb_v6.vvp ../src/tiny_cpu.v tb_v6.v && vvp tb_v6.vvp
`timescale 1ns/1ps

module tb_v6;
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

    task run_prog;
        input [7:0] expected;
        begin
            rst_n = 1;
            cycles = 0;
            while (!halted && cycles < 10000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!halted) begin
                $display("FAIL: did not halt");
                fails = fails + 1;
            end else if (out_port !== expected) begin
                $display("FAIL: out %0d, expected %0d", out_port, expected);
                fails = fails + 1;
            end else begin
                $display("PASS: out %0d after %0d cycles, pc=%0d sp=%0d",
                         out_port, cycles, dut.pc, dut.sp);
            end
        end
    endtask

    initial begin
        fails = 0;
        rst_n = 0;
        $readmemh("../programs/far_demo.hex", dut.rom);
        #23;
        $display("far_demo:");
        run_prog(8'd7);
        if (dut.ram[8'h11] !== 8'd7) begin
            $display("FAIL: far_demo RAM[0x11] = %0d, expected 7", dut.ram[8'h11]);
            fails = fails + 1;
        end else begin
            $display("PASS: far_demo RAM[0x11] = 7 (subroutine ran)");
        end
        rst_n = 0;
        $readmemh("../programs/far_cond.hex", dut.rom);
        #23;
        $display("far_cond:");
        run_prog(8'd88);
        if (fails == 0)
            $display("PASS: all v6 cases correct");
        else
            $display("FAIL: %0d case(s) failed", fails);
        $finish;
    end
endmodule
