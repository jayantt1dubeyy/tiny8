// Testbench for tiny8 v3: register B + PUSH/POP.
// Loads each program from ../programs/ in turn, resetting between runs.
// Run from sim/:
//   iverilog -o tb_v3.vvp ../src/tiny_cpu.v tb_v3.v && vvp tb_v3.vvp
`timescale 1ns/1ps

module tb_v3;
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
                $display("PASS: out %0d after %0d cycles, b=%0d sp=%0d",
                         out_port, cycles, dut.b, dut.sp);
            end
        end
    endtask

    initial begin
        fails = 0;
        rst_n = 0;
        $readmemh("../programs/multiply.hex", dut.rom);
        #23;
        $display("multiply:");
        run_prog(8'd42);
        rst_n = 0;
        $readmemh("../programs/push_pop.hex", dut.rom);
        #23;
        $display("push_pop:");
        run_prog(8'd42);
        // push_pop only counts if the subroutine actually ran:
        if (dut.ram[8'h11] !== 8'd7) begin
            $display("FAIL: push_pop RAM[0x11] = %0d, expected 7", dut.ram[8'h11]);
            fails = fails + 1;
        end else begin
            $display("PASS: push_pop RAM[0x11] = 7 (subroutine ran)");
        end
        rst_n = 0;
        $readmemh("../programs/regb_demo.hex", dut.rom);
        #23;
        $display("regb_demo:");
        run_prog(8'd10);
        if (fails == 0)
            $display("PASS: all v3 cases correct");
        else
            $display("FAIL: %0d case(s) failed", fails);
        $finish;
    end
endmodule
