; page_demo — 64KB paged memory in one run. Expected: out 99.
; Zero-page: RAM[0x10] = 42 via STA/LDA as in v1.
; Page 1: B = 1, STAX 0x20 writes RAM[0x0120] = 99 (address 288).
; Page 2: B = 2, STAX 0xFF writes RAM[0x02FF] = 7 (address 767).
; Then B = 1 again, LDAX 0x20 reads RAM[288] back and outputs it.
; The testbench also checks RAM[0x10] = 42 and RAM[767] = 7, so
; all three writes must have landed in the right places.

        LDI 42
        STA 0x10        ; zero-page RAM[16] = 42
        LDI 1
        TAB             ; B = 1 (page 1)
        LDI 99
        STAX 0x20       ; RAM[288] = 99
        LDI 2
        TAB             ; B = 2 (page 2)
        LDI 7
        STAX 0xFF       ; RAM[767] = 7
        LDI 1
        TAB             ; B = 1 again
        LDAX 0x20       ; A = RAM[288] = 99
        STA 0xFF        ; out_port = A
        HLT
