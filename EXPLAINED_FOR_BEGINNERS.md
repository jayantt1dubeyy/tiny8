# tiny8 CPU — A Tiny Computer Built From Zero, Explained for Beginners

This is a beginner explainer for this project, in plain language with one simple analogy. It is not a replacement for the technical paper or report.

**How to read the honesty labels:**

- **Verified** = the number or result is in a file Jayant actually produced, and it was checked here.
- **Reported, not verified** = the number comes from Jayant's own summary or slides. No seeds, no confidence intervals, and no test code were given with it. Treat it as "he says so", not "proven".
- **Plan only** = an idea or a target. It has not happened yet.

---


**In one line:** Jayant built a tiny 8-bit computer processor from scratch, in hardware-description language, and proved it works.

**Analogy:** A normal computer processor is like a whole city. This one is like a single-room workshop. It has one workbench, a small set of tools, and it can still do real work.

**What Jayant actually did (verified):**

- He wrote the processor in Verilog. Verilog is a language for describing hardware.
- The processor has an 8-bit accumulator, which is its one main workbench register.
- It has 256 words of program memory and 256 bytes of data memory.
- It has 16 instructions, including load, store, add, subtract, AND, OR, XOR, NOT, shifts, jumps, and halt.
- He also wrote a two-pass assembler and a Python model of the same processor. That gave him two independent ways to check the answer.

**The real result (verified):**

- The first program adds 1 + 2 + 3 + ... + 10.
- Both the Python model and the Icarus Verilog simulation agreed: the answer is 55, the processor halted, and it took 86 instructions and 173 cycles.
- Two independent checks agreeing is the point. A bug in one check would likely show up in the other.

**What is NOT proved / still open:**

- This is not a real manufactured chip yet. It is a simulated design.
- The next steps are only a roadmap: more programs, then synthesis with Yosys to count gates, then possibly a TinyTapeout tile. None of those steps are claimed as done here.
- It is tiny on purpose. It does not compete with a phone or laptop processor. Its value is that it was built and verified from zero.
