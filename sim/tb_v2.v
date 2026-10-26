// Testbench for tiny8 v2: JNZ (fib) + nested CALL/RET (call_demo).
// Loads each program from ../programs/ in turn, resetting between runs.
// Run from sim/:
//   iverilog -o tb_v2.vvp ../src/tiny_cpu.v tb_v2.v && vvp tb_v2.vvp
`timescale 1ns/1ps

module tb_v2;
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
                $display("PASS: out %0d after %0d cycles, sp=%0d", out_port, cycles, dut.sp);
            end
        end
    endtask

    initial begin
        fails = 0;
        // fib: JNZ loop, expect 55
        rst_n = 0;
        $readmemh("../programs/fib.hex", dut.rom);
        #23;
        $display("fib:");
        run_prog(8'd55);
        // call_demo: nested CALL/RET, expect 112
        rst_n = 0;
        $readmemh("../programs/call_demo.hex", dut.rom);
        #23;
        $display("call_demo:");
        run_prog(8'd112);
        if (fails == 0)
            $display("PASS: all v2 cases correct");
        else
            $display("FAIL: %0d case(s) failed", fails);
        $finish;
    end
endmodule
