// tiny8 v6 — a minimal 8-bit accumulator CPU (multi-cycle, 2 cycles/instruction)
// ---------------------------------------------------------------------------
// Architecture:
//   - 8-bit accumulator A, 8-bit program counter PC, 16-bit instruction reg IR
//   - Harvard memory: 64K-word instruction ROM (16-bit words), 64KB data RAM
//     (v5/v6). Zero-page LDA/STA/ADD/etc. use addresses 0..255 as in v1;
//     v5 LDAX/STAX use the full 16-bit address (B << 8) | operand, so
//     B is the RAM page register. LDAX/STAX touch RAM only, never the
//     ports — so RAM[254] and RAM[255] (shadowed by the ports in
//     zero-page mode) are reachable only through LDAX/STAX with B = 0.
//   - v6 program counter is 16-bit, so programs can live anywhere in
//     the 64K ROM. Old jumps (JMP/JZ/JNZ/CALL/JC/JNC) still target
//     addresses 0..255; v6 JMPF/JZF target (B << 8) | operand, using
//     the [11:8] field of JMP/JZ, which was always 0 in v1-v5.
//     CALL/RET now push/pop a 16-bit return address (high byte first,
//     then low byte); old programs still work, since their return
//     addresses are < 256 and the stack still balances.
//   - One flag: Z (set when an ALU/load result is zero; STA/JMP/JZ/JNZ/CALL/RET/
//     HLT/NOP keep it)
//   - Memory-mapped ports: reading 0xFE = input pins, writing 0xFF = output pins
//   - v2 stack: SP register, reset to 0xFE (empty). CALL pushes the return
//     address to RAM[SP-1] and decrements SP; RET pops it and increments SP.
//     The stack grows down from the top of RAM, away from program data —
//     keep program data below 0xF0 so deep calls never collide with it.
//
// Instruction word: [15:12] opcode, [11:8] extension (v2, see below),
//   [7:0] operand (operand = data address, or immediate for LDI/ADDI)
//   v1 programs have extension 0 and run unchanged on v2.
//
//   opcode  mnemonic  behaviour
//   0x0     NOP       do nothing
//   0x1     LDI imm   A <- imm
//   0x2     LDA addr  A <- MEM[addr]          (addr 0xFE reads in_port)
//   0x3     STA addr  MEM[addr] <- A          (addr 0xFF writes out_port)
//   0x4     ADD addr  A <- A + MEM[addr]
//   0x5     ADDI imm  A <- A + imm
//   0x6     SUB addr  A <- A - MEM[addr]
//   0x7     AND addr  A <- A & MEM[addr]
//   0x8     OR  addr  A <- A | MEM[addr]
//   0x9     XOR addr  A <- A ^ MEM[addr]
//   0xA     NOT       A <- ~A
//   0xB     SHL       A <- A << 1
//   0xC     SHR       A <- A >> 1 (logical)
//   0xD     JMP addr  PC <- addr
//   0xE     JZ  addr  if (Z) PC <- addr
//   0xF     HLT       halt forever (halted = 1)
//
//   v2 extended instructions (opcode 0x0, extension in [11:8]):
//   ext 0   NOP       do nothing
//   ext 1   JNZ addr  if (!Z) PC <- addr
//   ext 2   CALL addr push PC; PC <- addr
//   ext 3   RET       PC <- pop()
//
//   v3 extended instructions (same opcode/extension scheme):
//   ext 4   TAB       B <- A (flags untouched)
//   ext 5   TBA       A <- B (flags untouched)
//   ext 6   ADDB      A <- A + B (sets Z, C on carry)
//   ext 7   SUBB      A <- A - B (sets Z, C on borrow)
//   ext 8   PUSH      push A (flags untouched)
//   ext 9   POP       A <- pop() (sets Z like a load)
//
//   v4 extended instructions (same opcode/extension scheme):
//   ext A   CMP addr  compare A with MEM[addr]: A unchanged,
//                     Z = (A == MEM), C = (A < MEM, unsigned borrow)
//   ext B   JC addr   if (C) PC <- addr
//   ext C   JNC addr  if (!C) PC <- addr
//   ext D   MUL       A <- A * B, low byte only (sets Z, C untouched)
//
//   v5 extended instructions (same opcode/extension scheme):
//   ext E   LDAX addr A <- RAM[(B << 8) | addr] (sets Z, RAM only)
//   ext F   STAX addr RAM[(B << 8) | addr] <- A (flags untouched)
//
//   v6 far jumps (JMP/JZ with [11:8] == 1, B = program page):
//   JMPF addr PC <- (B << 8) | addr
//   JZF addr  if (Z) PC <- (B << 8) | addr
//   A far call needs no new opcode: push the return address (high byte,
//   then low byte, with PUSH), set B to the subroutine's page, JMPF to
//   it, and let RET pop the 16-bit address back.
//


//   v4 flag C: 1 on ADD/ADDI/ADDB carry, 1 on SUB/SUBB/CMP borrow;
//   every other instruction leaves C alone. Z is set by ALU/load results
//   and by CMP/POP/MUL, as listed above.
//


// Cycle model: FETCH (IR <- ROM[PC]; PC <- PC + 1), then EXECUTE (do the op).
// Reset (rst_n = 0) clears PC, A, Z and halted; the CPU restarts at ROM[0].
// ---------------------------------------------------------------------------

module tiny_cpu (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] in_port,
    output reg  [7:0] out_port,
    output reg        halted
);

    // State encoding
    localparam FETCH = 1'b0;
    localparam EXEC  = 1'b1;

    // Opcodes
    localparam OP_NOP  = 4'h0;
    localparam OP_LDI  = 4'h1;
    localparam OP_LDA  = 4'h2;
    localparam OP_STA  = 4'h3;
    localparam OP_ADD  = 4'h4;
    localparam OP_ADDI = 4'h5;
    localparam OP_SUB  = 4'h6;
    localparam OP_AND  = 4'h7;
    localparam OP_OR   = 4'h8;
    localparam OP_XOR  = 4'h9;
    localparam OP_NOT  = 4'hA;
    localparam OP_SHL  = 4'hB;
    localparam OP_SHR  = 4'hC;
    localparam OP_JMP  = 4'hD;
    localparam OP_JZ   = 4'hE;
    localparam OP_HLT  = 4'hF;

    reg  [15:0] pc;   // v6: 16-bit program counter
    reg  [7:0]  a;
    reg  [7:0]  b;    // v3 second register
    reg  [15:0] ir;
    reg         z;
    reg         c;    // v4 carry/borrow flag
    reg         state;
    reg  [7:0]  sp;   // v2 stack pointer, 0xFE = empty

    reg  [7:0]  ram [0:65535];  // v5: 64KB data RAM
    reg  [15:0] rom [0:65535];  // v6: 64K-word instruction ROM

    wire [3:0] opcode  = ir[15:12];
    wire [3:0] ext     = ir[11:8];   // v2 extension, only used with opcode 0
    wire [7:0] operand = ir[7:0];

    // Combinational data read (0xFE = input port, everything else = RAM)
    wire [7:0] mem_read = (operand == 8'hFE) ? in_port : ram[operand];

    // ALU result for the current instruction (used in EXEC state)
    reg [7:0] alu_out;
    always @* begin
        case (opcode)
            OP_LDI:  alu_out = operand;
            OP_LDA:  alu_out = mem_read;
            OP_ADD:  alu_out = a + mem_read;
            OP_ADDI: alu_out = a + operand;
            OP_SUB:  alu_out = a - mem_read;
            OP_AND:  alu_out = a & mem_read;
            OP_OR:   alu_out = a | mem_read;
            OP_XOR:  alu_out = a ^ mem_read;
            OP_NOT:  alu_out = ~a;
            OP_SHL:  alu_out = a << 1;
            OP_SHR:  alu_out = a >> 1;
            default: alu_out = a;
        endcase
    end

    // Does this opcode write the ALU result into A (and update Z)?
    wire alu_writes_a = (opcode == OP_LDI)  || (opcode == OP_LDA)  ||
                        (opcode == OP_ADD)  || (opcode == OP_ADDI) ||
                        (opcode == OP_SUB)  || (opcode == OP_AND)  ||
                        (opcode == OP_OR)   || (opcode == OP_XOR)  ||
                        (opcode == OP_NOT)  || (opcode == OP_SHL)  ||
                        (opcode == OP_SHR);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc      <= 16'd0;
            a       <= 8'd0;
            b       <= 8'd0;
            ir      <= 16'd0;
            z       <= 1'b0;
            c       <= 1'b0;
            state   <= FETCH;
            halted  <= 1'b0;
            out_port <= 8'd0;
            sp      <= 8'hFE;
        end else if (!halted) begin
            case (state)
                FETCH: begin
                    ir    <= rom[pc];
                    pc    <= pc + 8'd1;
                    state <= EXEC;
                end
                EXEC: begin
                    state <= FETCH;
                    if (alu_writes_a) begin
                        a <= alu_out;
                        z <= (alu_out == 8'd0);
                        // v4: only ADD/ADDI/SUB touch C; the rest leave it.
                        case (opcode)
                            OP_ADD:  c <= (a > (8'hFF - mem_read));
                            OP_ADDI: c <= (a > (8'hFF - operand));
                            OP_SUB:  c <= (a < mem_read);
                            default: begin end
                        endcase
                    end
                    case (opcode)
                        OP_STA: begin
                            if (operand == 8'hFF)
                                out_port <= a;
                            else
                                ram[operand] <= a;
                        end
                        OP_JMP: begin
                            if (ext == 4'h1) pc <= {b, operand};  // JMPF
                            else pc <= operand;
                        end
                        OP_JZ: begin
                            if (z) begin
                                if (ext == 4'h1) pc <= {b, operand};  // JZF
                                else pc <= operand;
                            end
                        end
                        OP_HLT: halted <= 1'b1;
                        OP_NOP: begin
                            // v2 extended instructions (extension in [11:8])
                            case (ext)
                                4'h1: if (!z) pc <= operand;              // JNZ
                                4'h2: begin                              // CALL
                                    // v6: 16-bit return address, high first
                                    ram[sp - 8'd1] <= pc[15:8];
                                    ram[sp - 8'd2] <= pc[7:0];
                                    sp <= sp - 8'd2;
                                    pc <= operand;
                                end
                                4'h3: begin                              // RET
                                    pc <= {ram[sp + 8'd1], ram[sp]};
                                    sp <= sp + 8'd2;
                                end
                                4'h4: b <= a;                            // TAB
                                4'h5: a <= b;                            // TBA
                                4'h6: begin                              // ADDB
                                    a <= a + b;
                                    z <= ((a + b) == 8'd0);
                                    c <= (a > (8'hFF - b));
                                end
                                4'h7: begin                              // SUBB
                                    a <= a - b;
                                    z <= ((a - b) == 8'd0);
                                    c <= (a < b);
                                end
                                4'hA: begin                              // CMP
                                    z <= (a == mem_read);
                                    c <= (a < mem_read);
                                end
                                4'hB: if (c) pc <= operand;              // JC
                                4'hC: if (!c) pc <= operand;             // JNC
                                4'hD: begin                              // MUL
                                    a <= a * b;
                                    z <= ((a * b) == 8'd0);
                                end
                                4'hE: begin                              // LDAX
                                    a <= ram[{b, operand}];
                                    z <= (ram[{b, operand}] == 8'd0);
                                end
                                4'hF: begin                              // STAX
                                    ram[{b, operand}] <= a;
                                end
                                4'h8: begin                              // PUSH
                                    ram[sp - 8'd1] <= a;
                                    sp <= sp - 8'd1;
                                end
                                4'h9: begin                              // POP
                                    a <= ram[sp];
                                    z <= (ram[sp] == 8'd0);
                                    sp <= sp + 8'd1;
                                end
                                default: begin end                       // NOP
                            endcase
                        end
                        default: begin end
                    endcase
                end
                default: state <= FETCH;
            endcase
        end
    end

endmodule
