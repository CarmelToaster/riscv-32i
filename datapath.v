`timescale 1ns / 1ps
module datapath(
    input  wire        clk,
    input  wire        reset,
 
    // control signals in, from control_unit (external, peer module)
    input  wire        reg_write,
    input  wire        alu_src,
    input  wire        mem_write,
    input  wire [2:0]  result_src,
    input  wire [2:0]  imm_src,
    input  wire        branch,
    input  wire        jump,
    input  wire        jalr,
    input  wire [3:0]  alu_control,
 
    // fetched instruction out, so the top-level module can slice
    // opcode/funct3/funct7_5 for control_unit
    output wire [31:0] instr
    );
 
    // ---- Fetch ----
    wire [31:0] pc_current;
    wire [31:0] pc_plus4;
    wire [31:0] pc_plus_imm;
 
    instr_mem imem(
        .pc(pc_current),
        .instr(instr)
    );
 
    // ---- Register file ----
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] write_data_final;
 
    register_file rf(
        .clk(clk),
        .RegWrite(reg_write),
        .rs_addr(instr[19:15]),  // rs1
        .rt_addr(instr[24:20]),  // rs2
        .rd_addr(instr[11:7]),   // rd
        .rd_data(write_data_final),
        .rs_data(rs1_data),
        .rt_data(rs2_data)
    );
 
    // ---- Immediate generator ----
wire [31:0] imm_ext;   // keep this internal wire name if other modules reference imm_ext

imm_gen ig(
    .instr(instr),
    .imm_src(imm_src),
    .imm_result(imm_ext)    // connect port imm_result -> your internal wire imm_ext   
);
    // ---- ALUSrc mux ----
    wire [31:0] alu_b_in;
 
ALUSrc asrc(
    .rd2(rs2_data),
    .imm_result(imm_ext),
    .alu_src(alu_src),
    .alu_src_out(alu_b_in)
);
    // ---- ALU ----
    wire [31:0] alu_result;
    wire        alu_zero;
    wire        alu_c, alu_v, alu_n; // unused outside the ALU for now
 
    alu ex(
        .alu_a(rs1_data),
        .alu_b(alu_b_in),
        .opcode(alu_control),
        .result(alu_result),
        .z(alu_zero),
        .c(alu_c),
        .v(alu_v),
        .n(alu_n)
    );
 
    // ---- Data memory ----
    wire [31:0] mem_read_data;
 
    data_mem dmem(
        .clk(clk),
        .mem_write(mem_write),
        .funct3(instr[14:12]),
        .write_data(rs2_data),          // value to store is always rs2
        .addr(alu_result[9:0]),         // DEPTH=10 for BYTES=1024 -- truncate the ALU's full 32-bit address
        .read_data(mem_read_data)
    );
 
    // ---- PC-next logic ----
pc_next pcn(
    .clk(clk),
    .reset(reset),
    .imm_result(imm_ext),        // was .imm_ext(imm_ext)
    .alu_result(alu_result),
    .funct3(instr[14:12]),
    .zero(alu_zero),
    .branch(branch),
    .jump(jump),
    .jalr(jalr),
    .pc(pc_current),
    .pc4_result(pc_plus4),       // was .pc_plus4(pc_plus4)
    .pcimm_result(pc_plus_imm)   // was .pc_plus_imm(pc_plus_imm)
);
    // ---- Result mux (write-back) ----
    result_src rsrc(
        .result_src(result_src),
        .alu_result(alu_result),
        .mem_result(mem_read_data),
        .pc4_result(pc_plus4),
        .imm_result(imm_ext),
        .pcimm_result(pc_plus_imm),
        .write_data(write_data_final)
    );
 
endmodule
