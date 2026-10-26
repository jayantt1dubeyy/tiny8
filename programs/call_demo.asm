; call_demo — nested CALL/RET demo. Expected result: 112.
; main sets x=7 (0x10), y=5 (0x11) and CALLs outer. outer CALLs inner
; (which adds x+y into 0x12), then adds 100 to the result and RETurns.
; main outputs 0x12. Two return addresses live on the stack at once,
; so this proves CALL/RET nesting, not just one call.
; x in 0x10, y in 0x11, result in 0x12.

        LDI 7
        STA 0x10        ; x = 7
        LDI 5
        STA 0x11        ; y = 5
        CALL outer
        LDA 0x12        ; A = result (7 + 5 + 100 = 112)
        STA 0xFF        ; out_port = A
        HLT
outer:  CALL inner      ; nested call: stack depth 2 here
        LDA 0x12        ; A = x + y
        ADDI 100        ; A = x + y + 100
        STA 0x12        ; result = A
        RET
inner:  LDA 0x10        ; A = x
        ADD 0x11        ; A = x + y
        STA 0x12        ; result = A
        RET
