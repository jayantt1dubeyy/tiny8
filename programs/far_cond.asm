; far_cond — a conditional far jump. Expected: out 88.
; v6 demo. B = 1 first (TAB leaves flags alone), then LDI 0 sets
; Z = 1 without touching B. JZF then jumps to address 256 only
; because Z is set. If JZF failed, it would fall through and output 0.
; (Order matters: LDI 1 after setting Z would clear Z again.)

        LDI 1
        TAB             ; B = 1 (target page)
        LDI 0           ; A = 0, Z = 1, B still 1
        JZF far_ok      ; PC <- 256, because Z is set
        LDI 0
        STA 0xFF        ; (only reached if JZF failed)
        HLT
        ORG 256
far_ok: LDI 88
        STA 0xFF        ; out_port = 88
        HLT
