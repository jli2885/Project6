`default_nettype none

module hart #(
    // After reset, the program counter (PC) should be initialized to this
    // address and start executing instructions from there.
    parameter RESET_ADDR = 32'h00000000
) (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // Instruction fetch goes through a read only instruction memory (imem)
    // port. The port accepts a 32-bit address (e.g. from the program counter)
    // per cycle and sequentially returns a 32-bit instruction word. For
    // projects 6 and 7, this memory has been updated to be more realistic
    // - reads are no longer combinational, and both read and write accesses
    // take multiple cycles to complete.
    //
    // The testbench memory models a fixed, multi cycle memory with partial
    // pipelining. The memory will accept a new request every N cycles by
    // asserting `mem_ready`, and if a request is made, the memory perform
    // the request (read or write) after M cycles, asserting mem_valid to
    // indicate the read data is ready (or the write is complete). Requests
    // are completed in order. The values of N and M are deterministic, but
    // may change between test cases - you must design your CPU to work
    // correctly by looking at `mem_ready` and `mem_valid` rather than
    // hardcoding a latency assumption.
    //
    // Indicates that the memory is ready to accept a new read request.
    input  wire        i_imem_ready,
    // 32-bit read address for the instruction memory. This is expected to be
    // 4 byte aligned - that is, the two LSBs should be zero.
    output wire [31:0] o_imem_raddr,
    // Issue a read request to the memory on this cycle. This should not be
    // asserted if `i_imem_ready` is not asserted.
    output wire        o_imem_ren,
    // Indicates that a valid instruction word is being returned from memory.
    input  wire        i_imem_valid,
    // Instruction word fetched from memory, available sequentially some
    // M cycles after a request (imem_ren) is issued.
    input  wire [31:0] i_imem_rdata,

    // Data memory accesses go through a separate read/write data memory (dmem)
    // that is shared between read (load) and write (stored). The port accepts
    // a 32-bit address, read or write enable, and mask (explained below) each
    // cycle.
    //
    // The timing of the dmem interface is the same as the imem interface. See
    // the documentation above.
    //
    // Indicates that the memory is ready to accept a new read or write request.
    input  wire        i_dmem_ready,
    // Read/write address for the data memory. This should be 32-bit aligned
    // (i.e. the two LSB should be zero). See `o_dmem_mask` for how to perform
    // half-word and byte accesses at unaligned addresses.
    output wire [31:0] o_dmem_addr,
    // When asserted, the memory will perform a read at the aligned address
    // specified by `i_addr` and return the 32-bit word at that address
    // immediately (i.e. combinationally). It is illegal to assert this and
    // `o_dmem_wen` on the same cycle.
    output wire        o_dmem_ren,
    // When asserted, the memory will perform a write to the aligned address
    // `o_dmem_addr`. When asserted, the memory will write the bytes in
    // `o_dmem_wdata` (specified by the mask) to memory at the specified
    // address. It is illegal to assert this and `o_dmem_ren` on the same
    // cycle.
    output wire        o_dmem_wen,
    // The 32-bit word to write to memory when `o_dmem_wen` is asserted. When
    // write enable is asserted, the byte lanes specified by the mask will be
    // written to the memory word at the aligned address at the next rising
    // clock edge. The other byte lanes of the word will be unaffected.
    output wire [31:0] o_dmem_wdata,
    // The dmem interface expects word (32 bit) aligned addresses. However,
    // the processor supports byte and half-word loads and stores at unaligned
    // and 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    //
    // To perform a half-word read at address 0x00001002, align `o_dmem_addr`
    // to 0x00001000, assert `o_dmem_ren`, and set the mask to 0b1100 to
    // indicate that only the upper two bytes should be read. Only the upper
    // two bytes of `i_dmem_rdata` can be assumed to have valid data; to
    // calculate the final value of the `lh[u]` instruction, shift the rdata
    // word right by 16 bits and sign/zero extend as appropriate.
    //
    // To perform a byte write at address 0x00002003, align `o_dmem_addr` to
    // `0x00002000`, assert `o_dmem_wen`, and set the mask to 0b1000 to
    // indicate that only the upper byte should be written. On the next clock
    // cycle, the upper byte of `o_dmem_wdata` will be written to memory, with
    // the other three bytes of the aligned word unaffected. Remember to shift
    // the value of the `sb` instruction left by 24 bits to place it in the
    // appropriate byte lane.
    output wire [ 3:0] o_dmem_mask,
    // Indicates that a valid data word is being returned from memory.
    input  wire        i_dmem_valid,
    // The 32-bit word read from data memory. When `o_dmem_ren` is asserted,
    // this will immediately reflect the contents of memory at the specified
    // address, for the bytes enabled by the mask. When read enable is not
    // asserted, or for bytes not set in the mask, the value is undefined.
    input  wire [31:0] i_dmem_rdata,
    // The output `retire` interface is used to signal to the testbench that
    // the CPU has completed and retired an instruction. A single cycle
    // implementation will assert this every cycle; however, a pipelined
    // implementation that needs to stall (due to internal hazards or waiting
    // on memory accesses) will not assert the signal on cycles where the
    // instruction in the writeback stage is not retiring.
    //
    // Asserted when an instruction is being retired this cycle. If this is
    // not asserted, the other retire signals are ignored and may be left invalid.
    output wire        o_retire_valid,
    // The 32 bit instruction word of the instrution being retired. This
    // should be the unmodified instruction word fetched from instruction
    // memory.
    output wire [31:0] o_retire_inst,
    // Asserted if the instruction produced a trap, due to an illegal
    // instruction, unaligned data memory access, or unaligned instruction
    // address on a taken branch or jump.
    output wire        o_retire_trap,
    // Asserted if the instruction is an `ebreak` instruction used to halt the
    // processor. This is used for debugging and testing purposes to end
    // a program.
    output wire        o_retire_halt,
    // The first register address read by the instruction being retired. If
    // the instruction does not read from a register (like `lui`), this is
    // don't-care -- the grading testbench doesn't look at it in that case.
    output wire [ 4:0] o_retire_rs1_raddr,
    // The second register address read by the instruction being retired. If
    // the instruction does not read from a second register (like `addi`),
    // this is don't-care -- the grading testbench doesn't look at it in that
    // case.
    output wire [ 4:0] o_retire_rs2_raddr,
    // The first source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs1 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs1_rdata,
    // The second source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs2 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs2_rdata,
    // The destination register address written by the instruction being
    // retired. If the instruction does not write to a register (like `sw`),
    // this should be 5'd0.
    output wire [ 4:0] o_retire_rd_waddr,
    // The destination register data written to the register file in the
    // writeback stage by this instruction. If rd is 5'd0, this field is
    // ignored and can be treated as a don't care.
    output wire [31:0] o_retire_rd_wdata,
    output wire [31:0] o_retire_dmem_addr,
    output wire [ 3:0] o_retire_dmem_mask,
    output wire        o_retire_dmem_ren,
    output wire        o_retire_dmem_wen,
    output wire [31:0] o_retire_dmem_rdata,
    output wire [31:0] o_retire_dmem_wdata,
    // The current program counter of the instruction being retired - i.e.
    // the instruction memory address that the instruction was fetched from.
    output wire [31:0] o_retire_pc,
    // the next program counter after the instruction is retired. For most
    // instructions, this is `o_retire_pc + 4`, but must be the branch or jump
    // target for *taken* branches and jumps.
    output wire [31:0] o_retire_next_pc
);
    // flush/stall signals
    wire stall_IF;
    wire stall_IFID;
    wire stall_IDEX;
    wire stall_EXMEM;
    wire flush_IFID;
    wire flush_IDEX;

    // Wires of IF Stage
    wire [31:0] if_pc;
    wire [31:0] if_pc4;
    wire [31:0] if_inst;
    wire if_inst_valid;

    // Wires of IF/ID Register and ID Stage
    wire [31:0] id_pc;
    wire [31:0] id_pc4;
    wire [31:0] id_inst;
    wire ifid_valid;
    wire [6:0] id_funct7;
    wire [2:0] id_funct3;
    wire [4:0] id_rs1_raddr;
    wire [4:0] id_rs2_raddr;
    wire [4:0] id_rd_waddr;
    wire [31:0] id_rs1_rdata;
    wire [31:0] id_rs2_rdata;
    wire [31:0] id_imm;
    wire id_regwrite;
    wire id_memtoreg;
    wire id_memread;
    wire id_memwrite;
    wire id_branch;
    wire id_ALUsrc;
    wire id_AUIPC;
    wire [1:0] id_ALUop;
    wire [1:0] id_jump;

    // Wires of ID/EX Register and EX Stage
    wire idex_valid;
    wire [31:0] ex_pc;
    wire [31:0] ex_pc4;
    wire [31:0] ex_inst;
    wire [31:0] ex_rs1_rdata;
    wire [31:0] ex_rs2_rdata;
    wire [31:0] ex_imm;
    wire [4:0] ex_rd_waddr;
    wire [4:0] ex_rs1_raddr;
    wire [4:0] ex_rs2_raddr;
    wire [6:0] ex_funct7;
    wire [2:0] ex_funct3;
    wire [1:0] ex_ALUop;
    wire [1:0] ex_jump;
    wire ex_ALUsrc;
    wire ex_AUIPC;
    wire ex_regwrite;
    wire ex_memtoreg;
    wire ex_memread;
    wire ex_memwrite;
    wire ex_branch;
    wire [31:0] ex_ALU_result;
    wire [31:0] ex_branch_target;
    wire [31:0] ex_jump_target;
    wire ex_zero;
    wire branch_redirect;
    wire [31:0] target_pc;
    
    wire [1:0] ForwardA;
    wire [1:0] ForwardB;
    wire [31:0] forward_rs1;
    wire [31:0] forward_rs2;
    wire redirect_fire;
    wire [31:0] saved_rs1_data;
    wire [31:0] saved_rs2_data;

    // Wires of EX/MEM Register and MEM Stage
    wire exmem_valid;
    wire [31:0] mem_pc;
    wire [31:0] mem_pc4;
    wire [31:0] mem_inst;
    wire [31:0] mem_next_pc;
    wire [31:0] mem_ALU_result;
    wire [31:0] mem_rs2_rdata;
    wire [31:0] mem_rs1_rdata;
    wire [4:0] mem_rd_waddr;
    wire [4:0] mem_rs1_raddr;
    wire [4:0] mem_rs2_raddr;
    wire [2:0] mem_funct3;
    wire mem_regwrite;
    wire mem_memtoreg;
    wire mem_memread;
    wire mem_memwrite;
    wire [31:0] mem_ReadData;
    wire mem_misaligned;
    wire mem_trap;

    // Wires of MEM/WB Register and WB Stage
    wire memwb_valid;
    wire [31:0] wb_pc;
    wire [31:0] wb_next_pc;
    wire [31:0] wb_inst;
    wire [31:0] wb_ALU_result;
    wire [31:0] wb_ReadData;
    wire [31:0] wb_rs1_rdata;
    wire [31:0] wb_rs2_rdata;
    wire [31:0] wb_dmem_addr;
    wire [31:0] wb_dmem_rdata;
    wire [31:0] wb_dmem_wdata;
    wire [4:0] wb_rd_waddr;
    wire [4:0] wb_rs1_raddr;
    wire [4:0] wb_rs2_raddr;
    wire [3:0] wb_dmem_mask;
    wire wb_dmem_ren;
    wire wb_dmem_wen;
    wire wb_regwrite;
    wire wb_memtoreg;
    wire wb_trap;
    wire [31:0] wb_data;
    wire mem_stall;

    // Hazard Detection Unit
    
    HDU u_hdu(
        .IF_ID_inst(id_inst),
        .IF_ID_valid(ifid_valid),
        .ID_EX_valid(idex_valid),
        .ID_EX_MemRead(ex_memread),
        .ID_EX_rd(ex_rd_waddr),
        .redirect_ex(branch_redirect),
        .dmem_wait(mem_stall),
        .stall_IF(stall_IF),
        .stall_IFID(stall_IFID),
        .stall_IDEX(stall_IDEX),
        .stall_EXMEM(stall_EXMEM),
        .flush_IFID(flush_IFID),
        .flush_IDEX(flush_IDEX)
    );


    // Forwarding Unit
    Forwarding_Unit u_forwarding(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .stall_EX(stall_IDEX),
        .ex_rs1_raddr(ex_rs1_raddr),
        .ex_rs2_raddr(ex_rs2_raddr),
        .ex_valid(idex_valid),
        .mem_valid(exmem_valid),
        .wb_valid(memwb_valid),
        .mem_regwrite(mem_regwrite),
        .mem_memread(mem_memread),
        .wb_regwrite(wb_regwrite),
        .mem_rd_waddr(mem_rd_waddr),
        .wb_rd_waddr(wb_rd_waddr),
        .wb_data(wb_data),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .saved_rs1_data(saved_rs1_data),
        .saved_rs2_data(saved_rs2_data)
    );


    // Forwarding logic 
    assign forward_rs1 = (ForwardA == 2'b10) ? mem_ALU_result : (ForwardA == 2'b01) ? wb_data :
                         (ForwardA == 2'b11) ? saved_rs1_data : ex_rs1_rdata;

    assign forward_rs2 = (ForwardB == 2'b10) ? mem_ALU_result : (ForwardB == 2'b01) ? wb_data :
                         (ForwardB == 2'b11) ? saved_rs2_data : ex_rs2_rdata;

    // IF Stage
    IF #(.RESET_ADDR(RESET_ADDR)) u_if(
        .i_clk(i_clk),
        .i_rst(i_rst),

        .PCsrc(redirect_fire),
        .if_stall(stall_IF),

        .i_imem_ready(i_imem_ready),
        .i_imem_valid(i_imem_valid),
        .i_imem_rdata(i_imem_rdata),

        .target_pc(target_pc),

        .o_imem_raddr(o_imem_raddr),
        .o_imem_ren(o_imem_ren),

        .PC_4(if_pc4),
        .PC(if_pc),
        .inst(if_inst),
        .inst_valid(if_inst_valid)
    );

    // IF/ID register
    IF_ID_reg u_if_id_reg(
        .i_clk(i_clk),
        .i_rst(i_rst),

        .if_pc(if_pc),
        .if_pc4(if_pc4),
        .if_inst(if_inst),
        .if_inst_valid(if_inst_valid),

        .stall_IFID(stall_IFID),
        .flush_IFID(flush_IFID),

        .ifid_valid(ifid_valid),
        .id_pc(id_pc),
        .id_pc4(id_pc4),
        .id_inst(id_inst)
    );


    // ID Stage
    ID u_id(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .inst(id_inst),
        .wb_data(wb_data),
        .wb_rd_waddr(wb_rd_waddr),
        .wb_regwrite(wb_regwrite && memwb_valid && !wb_trap),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .rs1_raddr(id_rs1_raddr),
        .rs2_raddr(id_rs2_raddr),
        .rd_waddr(id_rd_waddr),
        .rs1_rdata(id_rs1_rdata),
        .rs2_rdata(id_rs2_rdata),
        .imm(id_imm),
        .regwrite(id_regwrite),
        .memtoreg(id_memtoreg),
        .memread(id_memread),
        .memwrite(id_memwrite),
        .branch(id_branch),
        .ALUop(id_ALUop),
        .ALUsrc(id_ALUsrc),
        .jump(id_jump),
        .AUIPC(id_AUIPC)
    );

    // ID/EX Register
    ID_EX_reg u_id_ex_reg(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .ifid_valid(ifid_valid),
        .id_pc(id_pc),
        .id_pc4(id_pc4),
        .id_inst(id_inst),
        .id_rs1_rdata(id_rs1_rdata),
        .id_rs2_rdata(id_rs2_rdata),
        .id_imm(id_imm),
        .id_rd_waddr(id_rd_waddr),
        .id_rs1_raddr(id_rs1_raddr),
        .id_rs2_raddr(id_rs2_raddr),
        .id_funct7(id_funct7),
        .id_funct3(id_funct3),
        .id_ALUop(id_ALUop),
        .id_jump(id_jump),
        .id_ALUsrc(id_ALUsrc),
        .id_AUIPC(id_AUIPC),
        .id_regwrite(id_regwrite),
        .id_memtoreg(id_memtoreg),
        .id_memread(id_memread),
        .id_memwrite(id_memwrite),
        .id_branch(id_branch),
        .flush_IDEX(flush_IDEX),
        .mem_stall(stall_EXMEM),
        .idex_valid(idex_valid),
        .ex_pc(ex_pc),
        .ex_pc4(ex_pc4),
        .ex_inst(ex_inst),
        .ex_rs1_rdata(ex_rs1_rdata),
        .ex_rs2_rdata(ex_rs2_rdata),
        .ex_imm(ex_imm),
        .ex_rd_waddr(ex_rd_waddr),
        .ex_rs1_raddr(ex_rs1_raddr),
        .ex_rs2_raddr(ex_rs2_raddr),
        .ex_funct7(ex_funct7),
        .ex_funct3(ex_funct3),
        .ex_ALUop(ex_ALUop),
        .ex_jump(ex_jump),
        .ex_ALUsrc(ex_ALUsrc),
        .ex_AUIPC(ex_AUIPC),
        .ex_regwrite(ex_regwrite),
        .ex_memtoreg(ex_memtoreg),
        .ex_memread(ex_memread),
        .ex_memwrite(ex_memwrite),
        .ex_branch(ex_branch)
    );

    // EX Stage
    EX u_ex(
        .ALUOp(ex_ALUop),
        .funct7(ex_funct7),
        .funct3(ex_funct3),
        .ALUSrc(ex_ALUsrc),
        .AUIPC(ex_AUIPC),
        .jump(ex_jump),
        .rs1_rdata(forward_rs1),
        .rs2_rdata(forward_rs2),
        .immediate(ex_imm),
        .pc(ex_pc),
        .zero(ex_zero),
        .ALU_result(ex_ALU_result),
        .branch_target(ex_branch_target),
        .jump_target(ex_jump_target)
    );

    // Branch and jump mux in EX Stage.
    assign redirect_fire = branch_redirect && !mem_stall;
    assign branch_redirect = idex_valid && ((ex_branch && ex_zero) || (ex_jump!=2'b00));
    assign target_pc = (ex_jump!=2'b00)?ex_jump_target:ex_branch_target;
    
    // EX/MEM Register
    EX_MEM_reg u_ex_mem_reg(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .idex_valid(idex_valid),
        .ex_pc(ex_pc),
        .ex_pc4(ex_pc4),
        .ex_inst(ex_inst),
        .branch_redirect(branch_redirect),
        .target_pc(target_pc),
        .ex_jump(ex_jump),
        .ex_ALU_result(ex_ALU_result),
        .forward_rs1(forward_rs1),
        .forward_rs2(forward_rs2),
        .ex_rd_waddr(ex_rd_waddr),
        .ex_rs1_raddr(ex_rs1_raddr),
        .ex_rs2_raddr(ex_rs2_raddr),
        .ex_funct3(ex_funct3),
        .ex_regwrite(ex_regwrite),
        .ex_memtoreg(ex_memtoreg),
        .ex_memread(ex_memread),
        .ex_memwrite(ex_memwrite),
        .exmem_valid(exmem_valid),
        .mem_stall(stall_EXMEM),
        .mem_pc(mem_pc),
        .mem_pc4(mem_pc4),
        .mem_inst(mem_inst),
        .mem_next_pc(mem_next_pc),
        .mem_ALU_result(mem_ALU_result),
        .mem_rs2_rdata(mem_rs2_rdata),
        .mem_rs1_rdata(mem_rs1_rdata),
        .mem_rd_waddr(mem_rd_waddr),
        .mem_rs1_raddr(mem_rs1_raddr),
        .mem_rs2_raddr(mem_rs2_raddr),
        .mem_funct3(mem_funct3),
        .mem_regwrite(mem_regwrite),
        .mem_memtoreg(mem_memtoreg),
        .mem_memread(mem_memread),
        .mem_memwrite(mem_memwrite)
    );
    
    // MEM Stage
    MEM u_mem(
        .i_clk(i_clk),
        .i_rst(i_rst),

        .MemRead(mem_memread && exmem_valid),
        .MemWrite(mem_memwrite && exmem_valid),

        .ALU_result(mem_ALU_result),
        .WriteData(mem_rs2_rdata),
        .funct3(mem_funct3),

        .misaligned(mem_misaligned),
        .ReadData(mem_ReadData),
        .mem_stall(mem_stall),

        .i_dmem_rdata(i_dmem_rdata),
        .i_dmem_ready(i_dmem_ready),
        .i_dmem_valid(i_dmem_valid),

        .o_dmem_ren(o_dmem_ren),
        .o_dmem_wen(o_dmem_wen),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_mask(o_dmem_mask)
    );


    // MEM trap signal
    assign mem_trap = exmem_valid && (mem_memread || mem_memwrite) && mem_misaligned;

    // MEM/WB Register
    MEM_WB_reg u_mem_wb_reg(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .exmem_valid(exmem_valid),
        .mem_pc(mem_pc),
        .mem_next_pc(mem_next_pc),
        .mem_inst(mem_inst),
        .mem_ALU_result(mem_ALU_result),
        .mem_ReadData(mem_ReadData),
        .mem_rs1_rdata(mem_rs1_rdata),
        .mem_rs2_rdata(mem_rs2_rdata),
        .mem_rd_waddr(mem_rd_waddr),
        .mem_rs1_raddr(mem_rs1_raddr),
        .mem_rs2_raddr(mem_rs2_raddr),
        .o_dmem_addr(o_dmem_addr),
        .i_dmem_rdata(i_dmem_rdata),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_mask(o_dmem_mask),
        .mem_stall(mem_stall),
        .mem_memread(mem_memread),
        .mem_memwrite(mem_memwrite),
        .mem_regwrite(mem_regwrite),
        .mem_memtoreg(mem_memtoreg),
        .mem_trap(mem_trap),
        .memwb_valid(memwb_valid),
        .wb_pc(wb_pc),
        .wb_next_pc(wb_next_pc),
        .wb_inst(wb_inst),
        .wb_ALU_result(wb_ALU_result),
        .wb_ReadData(wb_ReadData),
        .wb_rs1_rdata(wb_rs1_rdata),
        .wb_rs2_rdata(wb_rs2_rdata),
        .wb_rd_waddr(wb_rd_waddr),
        .wb_rs1_raddr(wb_rs1_raddr),
        .wb_rs2_raddr(wb_rs2_raddr),
        .wb_dmem_addr(wb_dmem_addr),
        .wb_dmem_rdata(wb_dmem_rdata),
        .wb_dmem_wdata(wb_dmem_wdata),
        .wb_dmem_mask(wb_dmem_mask),
        .wb_dmem_ren(wb_dmem_ren),
        .wb_dmem_wen(wb_dmem_wen),
        .wb_regwrite(wb_regwrite),
        .wb_memtoreg(wb_memtoreg),
        .wb_trap(wb_trap)
    );

    // WB Stage
    WB u_wb(
        .ALU_result(wb_ALU_result),
        .Mem_data(wb_ReadData),
        .MemtoReg(wb_memtoreg),
        .WB_data(wb_data)
    );
    
    // The retire signals
    assign o_retire_valid=memwb_valid;
    assign o_retire_inst=wb_inst;
    assign o_retire_trap=wb_trap;
    assign o_retire_halt=memwb_valid && wb_inst==32'h00100073;
    assign o_retire_rs1_raddr=wb_rs1_raddr;
    assign o_retire_rs2_raddr=wb_rs2_raddr;
    assign o_retire_rs1_rdata=wb_rs1_rdata;
    assign o_retire_rs2_rdata=wb_rs2_rdata;
    assign o_retire_rd_waddr=(wb_regwrite && memwb_valid)?wb_rd_waddr:5'd0;
    assign o_retire_rd_wdata=wb_data;
    assign o_retire_dmem_addr=wb_dmem_addr;
    assign o_retire_dmem_mask=wb_dmem_mask;
    assign o_retire_dmem_ren=wb_dmem_ren;
    assign o_retire_dmem_wen=wb_dmem_wen;
    assign o_retire_dmem_rdata=wb_dmem_rdata;
    assign o_retire_dmem_wdata=wb_dmem_wdata;
    assign o_retire_pc=wb_pc;
    assign o_retire_next_pc=wb_next_pc;
    
endmodule

`default_nettype wire
