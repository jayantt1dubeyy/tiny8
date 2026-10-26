; far_demo — a far call to address 256 and back. Expected: out 7.
; v6 demo. There is no CALLF opcode: a far call is built from pieces
; the CPU already has. Main pushes its return address by hand (high
; byte first, then low byte — the same order CALL uses), sets B to
; the subroutine's page (1), and JMPFs to it. The subroutine ends
; with RET, which pops low byte, then high byte, and jumps back.
; Main lives at 0..9; the subroutine lives at 256 (ORG 256).
; "after" is at address 7, so LDI after loads 7, the low byte.

        LDI 0
        PUSH            ; return high byte = 0
        LDI after
        PUSH            ; return low byte = 7
        LDI 1
        TAB             ; B = 1 (subroutine page)
        JMPF far_sub    ; PC <- (1 << 8) | 0 = 256
after:  LDA 0x11        ; A = result from the subroutine (7)
        STA 0xFF        ; out_port = A
        HLT
        ORG 256
far_sub: LDI 7
        STA 0x11        ; result = 7
        RET             ; back to "after"
