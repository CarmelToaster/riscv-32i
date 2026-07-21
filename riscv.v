`timescale 1ns / 1ps
module riscv(
    input wire clk,
    input wire reset
    );
 
    wire [31:0] instr;
 
    // control signals, flowing from control_unit into datapath
    wire        reg_write;
    wire        alu_src;
    wire        mem_write;
    wire [2:0]  result_src;
    wire [2:0]  imm_src;
    wire        branch;
    wire        jump;
    wire        jalr;
    wire [3:0]  alu_control;
 
    control_unit cu(
        .opcode(instr[6:0]),
        .funct3(instr[14:12]),
        .funct7_5(instr[30]),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .result_src(result_src),
        .imm_src(imm_src),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .alu_control(alu_control)
    );
 
    datapath dp(
        .clk(clk),
        .reset(reset),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .result_src(result_src),
        .imm_src(imm_src),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .alu_control(alu_control),
        .instr(instr)
    );
 
endmodule
