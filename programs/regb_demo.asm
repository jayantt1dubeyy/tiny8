; regb_demo — TAB/TBA/ADDB/SUBB in one short run. Expected: out 10.
; B = 20 (TAB), then A = 10, ADDB makes A = 30, SUBB makes A = 10.
; LDI overwrites A only, so B survives across it — that is the point
; of having a second register at all.

        LDI 20
        TAB             ; B = 20
        LDI 10
        ADDB            ; A = 10 + 20 = 30
        SUBB            ; A = 30 - 20 = 10
        STA 0xFF        ; out_port = A
        HLT
