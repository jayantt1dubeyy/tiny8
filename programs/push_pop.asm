; push_pop — a subroutine that saves and restores A. Expected: out 42.
; main sets A = 42 and CALLs sub. sub PUSHes A, clobbers it with its
; own work (writing 7 to RAM 0x11), then POPs the saved value back
; and RETurns. main outputs A: 42 proves the save/restore worked,
; and RAM 0x11 = 7 proves sub actually ran.
; Work result in 0x11. Stack depth here is 2 (return + saved A).

        LDI 42
        CALL sub
        STA 0xFF        ; out_port = A (42, restored)
        HLT
sub:    PUSH            ; save A (42)
        LDI 7
        STA 0x11        ; sub's own work
        POP             ; A = 42 again
        RET
