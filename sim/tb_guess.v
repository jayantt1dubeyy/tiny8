// Testbench for tiny8 guess-the-number (programs/guess.asm, secret 42).
// One CPU run per guess: reset between cases, set in_port to the guess,
// check out_port: 1 = TOO LOW, 2 = TOO HIGH, 255 = WIN.
// Run from sim/:
//   cp ../programs/guess.hex program.hex
//   iverilog -o tb_guess.vvp ../src/tiny_cpu.v tb_guess.v && vvp tb_guess.vvp
`timescale 1ns/1ps

module tb_guess;
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

    task run_case;
        input [7:0] guess;
        input [7:0] expected;
        begin
            in_port = guess;
            rst_n = 0;
            #23;
            rst_n = 1;
            cycles = 0;
            while (!halted && cycles < 10000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!halted) begin
                $display("FAIL: guess %0d did not halt", guess);
                fails = fails + 1;
            end else if (out_port !== expected) begin
                $display("FAIL: guess %0d -> out %0d, expected %0d", guess, out_port, expected);
                fails = fails + 1;
            end else begin
                $display("PASS: guess %0d -> out %0d", guess, out_port);
            end
        end
    endtask

    initial begin
        $readmemh("program.hex", dut.rom);
        fails = 0;
        run_case(8'd20, 8'd1);    // too low
        run_case(8'd60, 8'd2);    // too high
        run_case(8'd42, 8'd255);  // win
        run_case(8'd1, 8'd1);     // too low, edge
        run_case(8'd100, 8'd2);   // too high, edge
        if (fails == 0)
            $display("PASS: all guess cases correct");
        else
            $display("FAIL: %0d case(s) failed", fails);
        $finish;
    end
endmodule
