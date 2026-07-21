
`timescale 1ns / 1ps
//
// Comprehensive self-checking testbench for the single-cycle RV32I core.
// Loads program.hex (49 instructions covering R-type ALU ops, I-type,
// loads/stores of all widths, all six branch types, JAL, JALR, LUI, AUIPC)
// then checks every written register against its expected value.
//
// Update REGFILE_PATH below if your register_file.v names its internal
// storage array something other than `registers`.
//
module riscv_tb;
 
    reg clk;
    reg reset;
 
    riscv dut(
        .clk(clk),
        .reset(reset)
    );
 
    // clock generation
    initial clk = 0;
    always #5 clk = ~clk;
 
    // reset sequence
    initial begin
        reset = 1;
        #12;
        reset = 0;
    end
 
    integer pass_count;
    integer fail_count;
 
    // Compares one register against its expected value, prints PASS/FAIL
    task check_reg(input [4:0] idx, input [31:0] expected, input [127:0] label);
        reg [31:0] actual;
        begin
            actual = dut.dp.rf.registers[idx];   // <-- adjust path/name if needed
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("PASS  x%0d (%0s) = %h", idx, label, actual);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL  x%0d (%0s) = %h, expected %h", idx, label, actual, expected);
            end
        end
    endtask
 
    initial begin
        pass_count = 0;
        fail_count = 0;
 
        // Let the program run. 49 instructions worst-case ~= 490ns of
        // execution plus reset overhead; 700ns gives comfortable margin,
        // and the program ends in a self-loop (idx48: beq x0,x0,0) so
        // checking any time after ~450ns is safe.
        #700;
 
        $display("---------------------------------------------");
        $display(" Register check results");
        $display("---------------------------------------------");
 
        // seed values
        check_reg(1,  32'h00000005, "addi seed x1=5");
        check_reg(2,  32'h0000000a, "addi seed x2=10");
 
        // R-type ALU coverage
        check_reg(3,  32'h0000000f, "add x1+x2");
        check_reg(4,  32'h00000005, "sub x2-x1");
        check_reg(5,  32'h00000000, "and x1&x2");
        check_reg(6,  32'h0000000f, "or x1|x2");
        check_reg(7,  32'h0000000f, "xor x1^x2");
        check_reg(8,  32'h00000001, "slt x1<x2");
        check_reg(9,  32'h00000000, "sltu x2<x1");
        check_reg(10, 32'h00000002, "addi shift amt=2");
        check_reg(11, 32'h00000014, "sll x1<<2 = 20");
        check_reg(12, 32'h00000005, "srl x11>>2 = 5");
        check_reg(13, 32'hfffffff8, "addi x13=-8");
        check_reg(14, 32'hfffffffe, "sra x13>>>2 = -2");
 
        // loads/stores round-trip
        check_reg(15, 32'h00000005, "lw mem[0] = 5");
        check_reg(16, 32'h0000000a, "lb sign-ext mem[4] = 10");
        check_reg(17, 32'h0000000a, "lbu zero-ext mem[4] = 10");
        check_reg(18, 32'h0000000f, "lh sign-ext mem[8] = 15");
        check_reg(19, 32'h0000000f, "lhu zero-ext mem[8] = 15");
 
        // branches -- each check confirms the branch was TAKEN
        // (x20-x25 land on the "target" addi, never the skipped 999 addi)
        check_reg(20, 32'h0000006f, "beq taken -> 111");
        check_reg(21, 32'h000000de, "bne taken -> 222");
        check_reg(22, 32'h0000014d, "blt taken -> 333");
        check_reg(23, 32'h000001bc, "bge taken -> 444");
        check_reg(24, 32'h0000022b, "bltu taken -> 555");
        check_reg(25, 32'h0000029a, "bgeu taken -> 666");
 
        // jumps
        check_reg(26, 32'h000000a4, "jal link addr (idx41*4=164)");
        check_reg(27, 32'h00000309, "jal taken -> 777");
        check_reg(28, 32'h000000b0, "jalr link addr (idx44*4=176)");
        check_reg(29, 32'h00000378, "jalr taken -> 888");
 
        // upper immediates
        check_reg(30, 32'h12345000, "lui x30 = 0x12345000");
        check_reg(31, 32'h000010bc, "auipc x31 = pc+0x1000 = 0x10bc");
 
        $display("---------------------------------------------");
        $display(" %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("---------------------------------------------");
 
        $finish;
    end
 
endmodule
