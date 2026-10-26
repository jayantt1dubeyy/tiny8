#!/bin/bash
# Build + test tiny8 end to end (v6). Run from the tiny-cpu directory.
set -e
cd "$(dirname "$0")"
python3 tools/asm.py programs/sum1to10.asm programs/sum1to10.hex
python3 tools/asm.py programs/guess.asm programs/guess.hex
python3 tools/asm.py programs/fib.asm programs/fib.hex
python3 tools/asm.py programs/call_demo.asm programs/call_demo.hex
python3 tools/asm.py programs/multiply.asm programs/multiply.hex
python3 tools/asm.py programs/push_pop.asm programs/push_pop.hex
python3 tools/asm.py programs/regb_demo.asm programs/regb_demo.hex
python3 tools/asm.py programs/guess255.asm programs/guess255.hex
python3 tools/asm.py programs/mul_demo.asm programs/mul_demo.hex
python3 tools/asm.py programs/cmp_flags.asm programs/cmp_flags.hex
python3 tools/asm.py programs/page_demo.asm programs/page_demo.hex
python3 tools/asm.py programs/far_demo.asm programs/far_demo.hex
python3 tools/asm.py programs/far_cond.asm programs/far_cond.hex
python3 tools/model.py programs/sum1to10.hex
python3 tools/play_guess.py --secret 42 --guesses 20,60,42
python3 tools/play_guess.py --full-range --secret 42 --guesses 0,255,42
cd sim
cp ../programs/sum1to10.hex program.hex
iverilog -o tb_cpu.vvp ../src/tiny_cpu.v tb_cpu.v
vvp tb_cpu.vvp
cp ../programs/guess.hex program.hex
iverilog -o tb_guess.vvp ../src/tiny_cpu.v tb_guess.v
vvp tb_guess.vvp
iverilog -o tb_v2.vvp ../src/tiny_cpu.v tb_v2.v
vvp tb_v2.vvp
iverilog -o tb_v3.vvp ../src/tiny_cpu.v tb_v3.v
vvp tb_v3.vvp
iverilog -o tb_v4.vvp ../src/tiny_cpu.v tb_v4.v
vvp tb_v4.vvp
iverilog -o tb_v5.vvp ../src/tiny_cpu.v tb_v5.v
vvp tb_v5.vvp
iverilog -o tb_v6.vvp ../src/tiny_cpu.v tb_v6.v
vvp tb_v6.vvp
iverilog -o /tmp/tt_check.vvp -s tt_um_tiny8 ../src/tiny_cpu.v ../src/tt_tiny8.v && echo 'TT wrapper compiles OK'
