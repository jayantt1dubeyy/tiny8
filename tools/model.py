#!/usr/bin/env python3
"""Python behavioural model of tiny8 — cross-checks the Verilog by running
the same hex program. Usage: python3 model.py program.hex"""
import sys

OPS = {0x0: "NOP", 0x1: "LDI", 0x2: "LDA", 0x3: "STA", 0x4: "ADD",
       0x5: "ADDI", 0x6: "SUB", 0x7: "AND", 0x8: "OR", 0x9: "XOR",
       0xA: "NOT", 0xB: "SHL", 0xC: "SHR", 0xD: "JMP", 0xE: "JZ", 0xF: "HLT"}


def run(hexfile, in_port=0, preload=None, trace=False):
    # v6: ROM is now 64K words and PC is 16-bit. Short programs are padded
    # with HLT, so a runaway PC halts instead of falling off the end.
    rom = [int(l.strip(), 16) for l in open(hexfile) if l.strip()]
    rom += [0xF000] * (65536 - len(rom))
    # v5: RAM is now 64KB. Zero-page LDA/STA still use addresses 0..255;
    # LDAX/STAX use the full 16-bit address (B << 8) | operand.
    ram = [0] * 65536
    if preload:
        for k, v in preload.items():
            ram[k] = v
    # v2: stack pointer, empty stack = 0xFE (one past the top of RAM;
    # pushes write to 0xFD, 0xFC, ... growing down, away from program data).
    # v3: second register B, reset to 0.
    # v4: carry/borrow flag C: 1 on ADD/ADDI/ADDB carry, 1 on SUB/SUBB/CMP
    # borrow (A < other); left alone by every other instruction.
    pc, a, b, z, c, out, halted, steps, sp = 0, 0, 0, False, False, 0, False, 0, 0xFE
    while not halted and steps < 100000:
        ir = rom[pc]
        pc = (pc + 1) & 0xFFFF  # v6: 16-bit PC
        op, ext, operand = ir >> 12, (ir >> 8) & 0xF, ir & 0xFF
        mem = in_port if operand == 0xFE else ram[operand]
        # v6 far jumps: JMP/JZ with [11:8] == 1 use (B << 8) | operand.
        if op == 0xD and ext == 1:
            name_far = "JMPF"
        elif op == 0xE and ext == 1:
            name_far = "JZF"
        else:
            name_far = None
        # v2/v3/v4/v5 extended instructions live in opcode 0 with ext in [11:8].
        if op == 0 and ext:
            name = {1: "JNZ", 2: "CALL", 3: "RET",
                    4: "TAB", 5: "TBA", 6: "ADDB", 7: "SUBB",
                    8: "PUSH", 9: "POP",
                    0xA: "CMP", 0xB: "JC", 0xC: "JNC", 0xD: "MUL",
                    0xE: "LDAX", 0xF: "STAX"}.get(ext, "NOP")
        else:
            name = OPS[op]
        if name_far:
            name = name_far
        if trace:
            print(f"pc={pc - 1:3d} {name:4s} {operand:#04x} A={a}")
        if name in ("LDI", "LDA", "ADD", "ADDI", "SUB", "AND", "OR", "XOR",
                    "NOT", "SHL", "SHR"):
            old_a = a
            a = {"LDI": operand, "LDA": mem, "ADD": (a + mem) & 0xFF,
                 "ADDI": (a + operand) & 0xFF, "SUB": (a - mem) & 0xFF,
                 "AND": a & mem, "OR": a | mem, "XOR": a ^ mem,
                 "NOT": (~a) & 0xFF, "SHL": (a << 1) & 0xFF,
                 "SHR": a >> 1}[name]
            z = (a == 0)
            # v4: only ADD/ADDI/SUB touch C; the rest leave it alone.
            if name == "ADD":
                c = (old_a + mem > 0xFF)
            elif name == "ADDI":
                c = (old_a + operand > 0xFF)
            elif name == "SUB":
                c = (old_a < mem)
        elif name == "STA":
            if operand == 0xFF:
                out = a
            else:
                ram[operand] = a
        elif name == "JMP":
            pc = operand
        elif name == "JZ":
            if z:
                pc = operand
        elif name == "JMPF":  # v6: PC <- (B << 8) | operand
            pc = (b << 8) | operand
        elif name == "JZF":
            if z:
                pc = (b << 8) | operand
        elif name == "JNZ":
            if not z:
                pc = operand
        elif name == "CALL":
            # v6: return address is 16-bit, pushed high byte first, then
            # low byte, so RET pops low first, then high. Old programs
            # still work: their return addresses are < 256, so the high
            # byte is 0, and the stack balances exactly as before.
            sp = (sp - 1) & 0xFF
            ram[sp] = (pc >> 8) & 0xFF
            sp = (sp - 1) & 0xFF
            ram[sp] = pc & 0xFF
            pc = operand
        elif name == "RET":
            low = ram[sp]
            sp = (sp + 1) & 0xFF
            high = ram[sp]
            sp = (sp + 1) & 0xFF
            pc = (high << 8) | low
        elif name == "TAB":  # B <- A, flags untouched (like STA)
            b = a
        elif name == "TBA":  # A <- B, flags untouched
            a = b
        elif name == "ADDB":  # A <- A + B, sets Z and C
            c = (a + b > 0xFF)
            a = (a + b) & 0xFF
            z = (a == 0)
        elif name == "SUBB":  # A <- A - B, sets Z and C (borrow)
            c = (a < b)
            a = (a - b) & 0xFF
            z = (a == 0)
        elif name == "CMP":  # compare A with MEM, A unchanged, sets Z and C
            z = (a == mem)
            c = (a < mem)
        elif name == "JC":
            if c:
                pc = operand
        elif name == "JNC":
            if not c:
                pc = operand
        elif name == "MUL":  # A <- A * B (low byte), sets Z, C untouched
            a = (a * b) & 0xFF
            z = (a == 0)
        elif name == "LDAX":  # A <- RAM[(B << 8) | operand], sets Z, RAM only
            a = ram[(b << 8) | operand]
            z = (a == 0)
        elif name == "STAX":  # RAM[(B << 8) | operand] <- A, flags untouched
            ram[(b << 8) | operand] = a
        elif name == "PUSH":  # push A, flags untouched
            sp = (sp - 1) & 0xFF
            ram[sp] = a
        elif name == "POP":  # A <- pop(), sets Z like a load
            a = ram[sp]
            sp = (sp + 1) & 0xFF
            z = (a == 0)
        elif name == "HLT":
            halted = True
        steps += 1
    return {"A": a, "B": b, "C": c, "out": out, "halted": halted,
            "steps": steps, "ram": ram, "sp": sp}


if __name__ == "__main__":
    r = run(sys.argv[1], preload={0x12: 0xFF}, trace="-v" in sys.argv)
    print(f"halted={r['halted']} steps={r['steps']} A={r['A']} out={r['out']} "
          f"RAM[0x11]={r['ram'][0x11]}")
