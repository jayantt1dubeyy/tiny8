; guess255 — guess-the-number, full 0..255 range. v4 demo.
; The old guess.asm only worked for 1..100, because it told high from
; low by whether the mod-256 difference was >= 128. With CMP + JC,
; the CPU compares for real: Z = equal, C = guess < secret (borrow).
; One CPU run = one guess, same console-driver pattern as guess.asm.
; Secret in 0x20, guess in 0x21.
; Output codes: 1 = TOO LOW, 2 = TOO HIGH, 255 = WIN.

        LDI 42
        STA 0x20        ; secret = 42
        LDA 0xFE        ; A = guess (in_port)
        STA 0x21        ; guess
        LDA 0x21        ; A = guess
        CMP 0x20        ; compare guess with secret (A unchanged)
        JZ win          ; equal -> WIN
        JC low          ; borrow -> guess < secret -> TOO LOW
        LDI 2           ; TOO HIGH
        STA 0xFF
        HLT
low:    LDI 1           ; TOO LOW
        STA 0xFF
        HLT
win:    LDI 255         ; WIN
        STA 0xFF
        HLT
