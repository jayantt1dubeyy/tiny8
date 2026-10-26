; guess — tiny8 plays "guess the number".
; One CPU run = one guess. The console driver (tools/play_guess.py) feeds
; one guess per run through in_port and reads the hint from out_port.
; Secret is in RAM 0x20 (set here by LDI; the driver can rebuild this file
; with a different secret for a fresh game).
; Guess range is 1..100. That range matters: see the diff test below.
;
; Output codes (out_port):
;   1   = TOO LOW  (guess < secret)
;   2   = TOO HIGH (guess > secret)
;   255 = WIN      (guess == secret)
;
; How it works, with only the Z flag and no compare instruction:
;   diff = secret - guess  (mod 256, via SUB)
;   diff == 0            -> WIN
;   diff in 1..99        -> guess < secret, because secret,guess <= 100
;   diff in 157..255    -> guess > secret, because the subtraction wrapped
;   So diff >= 128 means TOO HIGH. Test that by shifting right 7 times:
;   diff >> 7 is 1 if diff >= 128, else 0, and SHR sets Z, so JZ can branch.
; Secret in 0x20, guess in 0x21, diff in 0x22.

        LDI 42
        STA 0x20        ; secret = 42
        LDA 0xFE        ; A = guess (in_port)
        STA 0x21        ; guess
        LDA 0x20        ; A = secret
        SUB 0x21        ; A = secret - guess
        JZ win          ; diff == 0 -> WIN
        STA 0x22        ; diff
        LDA 0x22        ; A = diff
        SHR             ; >> 1
        SHR             ; >> 2
        SHR             ; >> 3
        SHR             ; >> 4
        SHR             ; >> 5
        SHR             ; >> 6
        SHR             ; >> 7  (A = 1 if diff >= 128, else 0)
        JZ low          ; A == 0 -> diff < 128 -> TOO LOW
        LDI 2           ; TOO HIGH
        STA 0xFF
        HLT
low:    LDI 1           ; TOO LOW
        STA 0xFF
        HLT
win:    LDI 255         ; WIN
        STA 0xFF
        HLT
