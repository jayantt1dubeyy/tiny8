// Testbench for tiny8 v4: CMP/JC/JNC + MUL, and the full-range game.
// Run from sim/:
//   iverilog -o tb_v4.vvp ../src/tiny_cpu.v tb_v4.v && vvp tb_v4.vvp
`timescale 1ns/1ps

module tb_v4;
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
                $display("PASS: out %0d after %0d cycles, c=%0d",
                         out_port, cycles, dut.c);
            end
        end
    endtask

    task run_guess;
        input [7:0] guess;
        input [7:0] expected;
        begin
            in_port = guess;
            rst_n = 0;
            #23;
            $display("guess255 guess %0d:", guess);
            run_prog(expected);
        end
    endtask

    initial begin
        fails = 0;
        rst_n = 0;
        $readmemh("../programs/mul_demo.hex", dut.rom);
        #23;
        $display("mul_demo:");
        run_prog(8'd225);
        rst_n = 0;
        $readmemh("../programs/cmp_flags.hex", dut.rom);
        #23;
        $display("cmp_flags:");
        run_prog(8'd77);
        $readmemh("../programs/guess255.hex", dut.rom);
        run_guess(8'd20, 8'd1);    // too low
        run_guess(8'd60, 8'd2);    // too high
        run_guess(8'd42, 8'd255);  // win
        run_guess(8'd0, 8'd1);     // too low, bottom edge
        run_guess(8'd255, 8'd2);   // too high, top edge (old game failed here)
        if (fails == 0)
            $display("PASS: all v4 cases correct");
        else
            $display("FAIL: %0d case(s) failed", fails);
        $finish;
    end
endmodule
