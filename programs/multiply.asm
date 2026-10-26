; multiply — 6 * 7 -> out_port. Expected result: 42.
; v3 demo: B holds the loop counter, so the result and the
; multiplicand can both live in RAM without a counter variable.
; multiplicand in 0x10, result in 0x11, counter in B.
; Loop: result += 6; B -= 1 (via TBA + ADDI 255 + TAB, which leaves
; Z from the ADDI alone, since TAB touches no flags); JNZ loops.

        LDI 6
        STA 0x10        ; multiplicand = 6
        LDI 0
        STA 0x11        ; result = 0
        LDI 7
        TAB             ; B = 7 (counter)
loop:   LDA 0x11        ; A = result
        ADD 0x10        ; A = result + 6
        STA 0x11        ; result = A
        TBA             ; A = B
        ADDI 255        ; A = B - 1 (sets Z when B hits 0)
        TAB             ; B = A (TAB leaves Z alone)
        JNZ loop        ; loop while B != 0
        LDA 0x11        ; A = result (42)
        STA 0xFF        ; out_port = A
        HLT
