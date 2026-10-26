; sum 1..10 -> out_port. Expected result: 55.
; Needs RAM[0x12] = 0xFF (i.e. -1) preloaded by the testbench.
; count in 0x10, sum in 0x11.

        LDI 10
        STA 0x10        ; count = 10
        LDI 0
        STA 0x11        ; sum = 0
loop:   LDA 0x11        ; A = sum
        ADD 0x10        ; A = sum + count
        STA 0x11        ; sum = A
        LDA 0x10        ; A = count
        ADD 0x12        ; A = count - 1
        STA 0x10        ; count = A
        JZ done         ; if count == 0, finished
        JMP loop
done:   LDA 0x11        ; A = sum (55)
        STA 0xFF        ; out_port = A
        HLT
