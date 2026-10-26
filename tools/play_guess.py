#!/usr/bin/env python3
"""Play "guess the number" on tiny8.

The game logic lives in the CPU (programs/guess.asm): each run takes one
guess through in_port and returns one hint through out_port:
  1 = TOO LOW, 2 = TOO HIGH, 255 = WIN.
This script is only the console: it feeds guesses one per CPU run and
prints the hints. It does not decide anything itself.

Usage:
  python3 tools/play_guess.py                  # interactive, random secret 1..100
  python3 tools/play_guess.py --secret 42      # interactive, fixed secret
  python3 tools/play_guess.py --secret 42 --guesses 20,60,42
                                               # scripted, no typing needed
  python3 tools/play_guess.py --max-attempts 7

Guesses must be 1..100 in the original game: the CPU's high/low test
(diff >= 128 after the mod-256 subtraction) is only valid in that range.
With --full-range, the v4 game (guess255.asm) compares for real with
CMP + JC, so guesses may be 0..255.
"""
import argparse
import random
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))
from model import run  # noqa: E402

HINTS = {1: "TOO LOW  ^  go higher", 2: "TOO HIGH  v  go lower", 255: "WIN!"}


def build_hex(secret, full_range=False):
    """Assemble guess.asm (or guess255.asm with --full-range) with the
    given secret, return the hex path."""
    src_name = "guess255.asm" if full_range else "guess.asm"
    src = (ROOT / "programs" / src_name).read_text()
    new, n = re.subn(r"LDI 42", f"LDI {secret}", src, count=1)
    if n != 1:
        raise SystemExit("guess.asm no longer starts with 'LDI 42' — refusing to guess at the secret line")
    import tempfile
    tmpdir = Path(tempfile.gettempdir())
    tmp_asm = tmpdir / "tiny8_guess_game.asm"
    tmp_hex = tmpdir / "tiny8_guess_game.hex"
    tmp_asm.write_text(new)
    subprocess.run([sys.executable, str(HERE / "asm.py"), str(tmp_asm), str(tmp_hex)],
                   check=True, capture_output=True)
    return tmp_hex


def one_turn(hexfile, guess):
    r = run(str(hexfile), in_port=guess)
    if not r["halted"]:
        raise SystemExit("CPU did not halt on this guess — game logic is broken")
    return r["out"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--secret", type=int, default=None)
    ap.add_argument("--guesses", default=None, help="comma-separated, e.g. 20,60,42")
    ap.add_argument("--max-attempts", type=int, default=7)
    ap.add_argument("--full-range", action="store_true",
                    help="v4 game: secret/guesses 0..255 via CMP+JC (default 1..100)")
    args = ap.parse_args()

    hi = 255 if args.full_range else 100
    lo = 0 if args.full_range else 1
    secret = args.secret if args.secret is not None else random.randint(lo, hi)
    if not lo <= secret <= hi:
        raise SystemExit(f"secret must be {lo}..{hi}")
    hexfile = build_hex(secret, full_range=args.full_range)

    print(f"tiny8 guess-the-number — I'm thinking of a number {lo}..{hi}.")
    print(f"You get {args.max_attempts} attempts. The CPU decides every hint.")
    if args.secret is not None:
        print(f"(fixed secret for testing: {secret})")

    scripted = None
    if args.guesses is not None:
        scripted = [int(x) for x in args.guesses.split(",") if x.strip()]

    for attempt in range(1, args.max_attempts + 1):
        if scripted is not None:
            if attempt - 1 >= len(scripted):
                break
            guess = scripted[attempt - 1]
            print(f"Attempt {attempt}: {guess}")
        else:
            try:
                guess = int(input(f"Attempt {attempt}/{args.max_attempts} — your guess: "))
            except (EOFError, KeyboardInterrupt):
                print("\nGame stopped. The secret was", secret)
                return 1
            except ValueError:
                print("That's not a number — try again (doesn't count).")
                continue
        if not lo <= guess <= hi:
            print(f"Out of range — guesses must be {lo}..{hi} (doesn't count).")
            continue
        out = one_turn(hexfile, guess)
        print("  tiny8 says:", HINTS.get(out, f"unknown output {out}"))
        if out == 255:
            print(f"You won in {attempt} attempt(s)! The number was {secret}.")
            return 0
    print(f"Out of attempts! The number was {secret}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
