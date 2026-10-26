; fib — Fibonacci(10) -> out_port. Expected result: 55.
; v2 JNZ demo: the loop runs while the counter is NOT zero, so no
; JZ + JMP dance is needed. No preload required: -1 is built in RAM
; with LDI 255 (0xFF) instead of relying on a testbench preload.
; a in 0x10, b in 0x11, count in 0x12, next in 0x13, -1 in 0x14.
; Start (a,b) = (0,1) = F0,F1; 9 steps reach (34,55) = F9,F10.

        LDI 0
        STA 0x10        ; a = 0
        LDI 1
        STA 0x11        ; b = 1
        LDI 9
        STA 0x12        ; count = 9
        LDI 255
        STA 0x14        ; -1
loop:   LDA 0x10        ; A = a
        ADD 0x11        ; A = a + b
        STA 0x13        ; next = A
        LDA 0x11        ; A = b
        STA 0x10        ; a = b
        LDA 0x13        ; A = next
        STA 0x11        ; b = next
        LDA 0x12        ; A = count
        ADD 0x14        ; A = count - 1 (sets Z when it hits 0)
        STA 0x12        ; count = A (STA leaves Z alone)
        JNZ loop        ; loop while count != 0
        LDA 0x11        ; A = b (55)
        STA 0xFF        ; out_port = A
        HLT
