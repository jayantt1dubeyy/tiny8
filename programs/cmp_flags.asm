; cmp_flags — prove both JC and JNC work. Expected: out 77.
; mem 0x10 = 5. First A = 3 < 5, so CMP sets C and JC must jump.
; Then A = 9 > 5, so CMP clears C and JNC must jump.
; Either branch failing falls through to output 0 instead of 77.

        LDI 5
        STA 0x10        ; mem = 5
        LDI 3           ; A = 3
        CMP 0x10        ; 3 < 5 -> C = 1
        JC t1ok         ; must jump
        LDI 0
        STA 0xFF
        HLT
t1ok:   LDI 9           ; A = 9
        CMP 0x10        ; 9 > 5 -> C = 0
        JNC t2ok        ; must jump
        LDI 0
        STA 0xFF
        HLT
t2ok:   LDI 77
        STA 0xFF        ; out_port = 77
        HLT
