; mul_demo — hardware multiply in one instruction. Expected: out 225.
; B = 15, A = 15, MUL makes A = 15 * 15 = 225 (low byte).
; Compare with multiply.asm, which needed a whole loop for 6 * 7.

        LDI 15
        TAB             ; B = 15
        LDI 15
        MUL             ; A = A * B = 225
        STA 0xFF        ; out_port = A
        HLT
