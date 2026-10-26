#!/usr/bin/env python3
"""tiny8 assembler: assembly text -> hex file for $readmemh.

Usage: python3 asm.py program.asm program.hex

Syntax per line: [label:] MNEMONIC [operand]   ; comments start with ; or #
Operand: decimal, 0x hex, or a label. Labels cost no space.
"""
import sys

OPS = {
    "NOP": 0x0, "LDI": 0x1, "LDA": 0x2, "STA": 0x3,
    "ADD": 0x4, "ADDI": 0x5, "SUB": 0x6, "AND": 0x7,
    "OR": 0x8, "XOR": 0x9, "NOT": 0xA, "SHL": 0xB,
    "SHR": 0xC, "JMP": 0xD, "JZ": 0xE, "HLT": 0xF,
}
# v2 extended instructions: opcode 0x0 with the formerly reserved [11:8]
# field as an extension number. NOP is ext 0, so all v1 programs assemble
# identically and run unchanged on v2.
EXT = {"JNZ": 0x1, "CALL": 0x2, "RET": 0x3,
       # v3: second register B + stack data ops
       "TAB": 0x4, "TBA": 0x5, "ADDB": 0x6, "SUBB": 0x7,
       "PUSH": 0x8, "POP": 0x9,
       # v4: carry flag, comparisons, hardware multiply
       "CMP": 0xA, "JC": 0xB, "JNC": 0xC, "MUL": 0xD,
       # v5: paged load/store — effective address = (B << 8) | operand
       "LDAX": 0xE, "STAX": 0xF}
NO_OPERAND = {"NOP", "NOT", "SHL", "SHR", "HLT", "RET",
              "TAB", "TBA", "ADDB", "SUBB", "PUSH", "POP", "MUL"}
# v6 far jumps: JMP/JZ with the [11:8] field set to 1, so the effective
# address is (B << 8) | operand instead of just operand. The field was
# always 0 for JMP/JZ in v1-v5, so old programs are unaffected.
FAR = {"JMPF": 0xD, "JZF": 0xE}


def parse(text):
    """Return list of (label, mnemonic, operand_str) for instruction lines."""
    lines = []
    for raw in text.splitlines():
        line = raw.split(";")[0].split("#")[0].strip()
        if not line:
            continue
        label = None
        if ":" in line:
            label, line = line.split(":", 1)
            label = label.strip()
            line = line.strip()
            if not line:
                lines.append((label, None, None))
                continue
        parts = line.split()
        mnem = parts[0].upper()
        # v6: ORG is a pseudo-instruction, not a real opcode: it moves the
        # assembly address forward (padding with HLT), so code can be
        # placed at a far address, e.g. "ORG 256" then a subroutine.
        if mnem in ("ORG", ".ORG"):
            operand = parts[1] if len(parts) > 1 else None
            if operand is None:
                raise ValueError("ORG needs an address")
            lines.append((label, "ORG", operand))
            continue
        if mnem not in OPS and mnem not in EXT and mnem not in FAR:
            raise ValueError(f"unknown mnemonic: {mnem}")
        operand = parts[1] if len(parts) > 1 else None
        if mnem in NO_OPERAND and operand is not None:
            raise ValueError(f"{mnem} takes no operand")
        if mnem not in NO_OPERAND and operand is None:
            raise ValueError(f"{mnem} needs an operand")
        lines.append((label, mnem, operand))
    return lines


def assemble(text):
    parsed = parse(text)
    def num_value(s):
        if s.lower().startswith("0x"):
            return int(s, 16)
        if s.lstrip("-").isdigit():
            return int(s)
        raise ValueError(f"ORG address must be numeric: {s}")

    # Pass 1: label addresses (label-only lines share the next address)
    labels, addr = {}, 0
    for label, mnem, operand in parsed:
        if mnem == "ORG":
            addr = num_value(operand)
        if label:
            if label in labels:
                raise ValueError(f"duplicate label: {label}")
            labels[label] = addr
        if mnem == "ORG":
            pass
        elif mnem is not None:
            addr += 1
    # Pass 2: emit words
    words = []
    for _, mnem, operand in parsed:
        if mnem is None:
            continue
        if mnem == "ORG":
            target = num_value(operand)
            if target < len(words):
                raise ValueError("ORG address is behind the current address")
            while len(words) < target:
                words.append(0xF000)  # HLT padding
            continue
        if operand is None:
            value = 0
        elif operand in labels:
            value = labels[operand]
        elif operand.lower().startswith("0x"):
            value = int(operand, 16)
        elif operand.lstrip("-").isdigit():
            value = int(operand) & 0xFF
        else:
            raise ValueError(f"bad operand: {operand}")
        if mnem in EXT:
            words.append((EXT[mnem] << 8) | (value & 0xFF))
        elif mnem in FAR:
            words.append((FAR[mnem] << 12) | (1 << 8) | (value & 0xFF))
        else:
            words.append((OPS[mnem] << 12) | (value & 0xFF))
    return words


def main():
    src, dst = sys.argv[1], sys.argv[2]
    words = assemble(open(src).read())
    with open(dst, "w") as fh:
        for w in words:
            fh.write(f"{w:04x}\n")
    print(f"assembled {len(words)} words -> {dst}")


if __name__ == "__main__":
    main()
