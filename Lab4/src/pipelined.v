`timescale 1ns / 1ps
// 111550076

/** [Prerequisite] pipelined (Lab 3), forwarding, hazard_detection
 * This module is the pipelined MIPS processor "similar to" FIGURE 4.60 (control hazard is not solved).
 * You can implement it by any style you want, as long as it passes testbench.
 */

module pipelined #(
    parameter integer TEXT_BYTES = 1024,        // size in bytes of instruction memory
    parameter integer TEXT_START = 'h00400000,  // start address of instruction memory
    parameter integer DATA_BYTES = 1024,        // size in bytes of data memory
    parameter integer DATA_START = 'h10008000   // start address of data memory
) (
    input clk,  // clock
    input rstn  // negative reset
);

    /****************** [step 1] Instruction fetch (IF)*******************************/
        /************ Instruction Memory ***********************/
            reg [31:0] pc; 
            wire [31:0] instr_mem_instr;
            instr_mem #(
                .BYTES(TEXT_BYTES),
                .START(TEXT_START)
            ) instr_mem (
                .address(pc),
                .instr  (instr_mem_instr)
            );
        /************ IF/ID Registers ***********************/
            wire [31:0] pc_4 = pc + 4; 
            reg [31:0] IF_ID_instr, IF_ID_pc_4; 
            always @(posedge clk or negedge rstn)begin
                if (!rstn) begin
                    IF_ID_instr <= 0;  // a.
                    IF_ID_pc_4  <= 0;  // b.
                end
                else begin
                    IF_ID_instr <= IF_ID_write ? instr_mem_instr : IF_ID_instr;  // a.
                    IF_ID_pc_4  <= IF_ID_write ? pc_4 : IF_ID_pc_4;  // b.
                end
            end
    /******** [step 2] Instruction decode and register file read (ID)****************************/
        /******************** Register Rile ****************************************************/
            wire [4:0] reg_file_write_reg;
            wire reg_file_reg_write;
            wire [31:0] reg_file_write_data, reg_file_read_data_1, reg_file_read_data_2;
            reg_file reg_file (
                .clk        (~clk),                  // only write when negative edge
                .rstn       (rstn),
                .read_reg_1 (IF_ID_instr[25:21]),
                .read_reg_2 (IF_ID_instr[20:16]),
                .reg_write  (reg_file_reg_write),
                .write_reg  (reg_file_write_reg),
                .write_data (reg_file_write_data),
                .read_data_1(reg_file_read_data_1),
                .read_data_2(reg_file_read_data_2)
            );

        /************* (Main) Control ****************************************************/
            wire [5:0] control_opcode = IF_ID_instr[31:26];
            // Execution/address calculation stage control lines
            wire control_reg_dst, control_alu_src;
            wire [1:0] control_alu_op;
            // Memory access stage control lines
            wire control_branch, control_mem_read, control_mem_write;
            // Wire-back stage control lines
            wire control_reg_write, control_mem_to_reg;
            wire control_nop;
            control control (
                .opcode    (control_opcode),
                .funct     (IF_ID_instr[5:0]),
                .reg_dst   (control_reg_dst),
                .alu_src   (control_alu_src),
                .mem_to_reg(control_mem_to_reg),
                .reg_write (control_reg_write),
                .mem_read  (control_mem_read),
                .mem_write (control_mem_write),
                .branch    (control_branch),
                .alu_op    (control_alu_op)
            );
        /************* branch forward ****************************************************/
            wire [1:0] beq_forward_A, beq_forward_B;
            branch_forward branch_forward (
                .take_branch   (control_branch),
                .EX_MEM_reg_dst(EX_MEM_reg_dst),
                .MEM_WB_mem_to_reg(MEM_WB_mem_to_reg),
                .rs           (IF_ID_instr[25:21]),
                .rt           (IF_ID_instr[20:16]),
                .EX_MEM_rd   (EX_MEM_rd),
                .MEM_WB_rd   (MEM_WB_rd),
                .beq_forward_A(beq_forward_A),
                .beq_forward_B(beq_forward_B)
            );

        /***Branch Target Address Calculation, ProgramCounter ***********************************/
            wire [31:0] extended_instr = { {16{IF_ID_instr[15]}}, IF_ID_instr[15:0] };
            wire [31:0] branch_target_address = IF_ID_pc_4 + (extended_instr << 2);
            wire [31:0] A = (beq_forward_A == 2'b01) ?  wb_result_data :    //lw forward
                    (beq_forward_A == 2'b10) ? EX_MEM_alu_result: //operation forward
                    reg_file_read_data_1;
            wire [31:0] B = (beq_forward_B == 2'b01) ? wb_result_data : //lw forward
                    (beq_forward_B == 2'b10) ? EX_MEM_alu_result : //operation forward
                    reg_file_read_data_2;
            wire take_branch = control_branch ? ((A == B) ? 1 : 0 ) : 0;
            //pc_next
            reg [31:0] pc_next;
            always @(*)begin
                pc_next <= take_branch ? branch_target_address : pc_4;
            end
            //pc
            always @(posedge clk or negedge rstn)begin
                if (!rstn)begin
                    pc <= TEXT_START;  
                end
                else begin
                    if(pc_write) pc <= pc_next;
                    //pc <= pc_next;
                end
            end
        /** [step 4] Connect Hazard Detection unit
            * 1. use `pc_write` when updating PC
            * 2. use `IF_ID_write` when updating IF/ID stage registers
            * 3. use `stall` when updating ID/EX stage registers
            */
            wire pc_write,IF_ID_write,stall;
            hazard_detection hazard_detection (
                .control_mem_write(control_mem_write),
                .take_branch   (control_branch),
                .ID_EX_mem_read(ID_EX_mem_read),
                .EX_MEM_mem_read(EX_MEM_mem_read),
                .MEM_WB_mem_to_reg(MEM_WB_mem_to_reg),
                .EX_MEM_reg_write(EX_MEM_reg_write),
                .ID_EX_rt      (ID_EX_rt),
                .IF_ID_rs      (IF_ID_instr[25:21]),
                .IF_ID_rt      (IF_ID_instr[20:16]),
                .EX_MEM_rd     (EX_MEM_rd),
                .MEM_WB_rd     (MEM_WB_rd),
                .pc_write      (pc_write),            // implicitly declared
                .IF_ID_write   (IF_ID_write),         // implicitly declared
                .stall         (stall)                // implicitly declared
            );
         
        /************* ID/EX Registers ****************************************************/
            reg [31:0] ID_EX_EXTENDED_INSTR, ID_EX_read_data1, ID_EX_read_data2;
            //write back
            reg ID_EX_reg_write, ID_EX_mem_to_reg;
            //mem
            reg ID_EX_mem_write, ID_EX_mem_read, ID_EX_branch;
            //ex
            reg [1:0] ID_EX_alu_op;
            reg ID_EX_alu_src, ID_EX_reg_dst;
            //forwarding
            reg [4:0] ID_EX_rs, ID_EX_rt, ID_EX_rd;
            
            always @(posedge clk or negedge rstn)begin
                if (!rstn)begin
                    ID_EX_EXTENDED_INSTR  <= 0;  
                    ID_EX_read_data1 <= 0;
                    ID_EX_read_data2 <= 0;
                    ID_EX_reg_write <= 0;
                    ID_EX_mem_to_reg <= 0;
                    ID_EX_mem_write <= 0;
                    ID_EX_mem_read <= 0;
                    ID_EX_branch <= 0;
                    ID_EX_alu_op <= 0;
                    ID_EX_alu_src <= 0;
                    ID_EX_reg_dst <= 0;
                    ID_EX_rs <= 0;
                    ID_EX_rt <= 0;
                    ID_EX_rd <= 0;  
                end
                else begin
                    ID_EX_EXTENDED_INSTR <= extended_instr;
                    ID_EX_read_data1 <= reg_file_read_data_1;  
                    ID_EX_read_data2 <= reg_file_read_data_2;
                    ID_EX_reg_write <= stall ? 0 : control_reg_write;
                    ID_EX_mem_to_reg <= stall ? 0 : control_mem_to_reg;
                    ID_EX_mem_write <= stall ? 0 : control_mem_write;
                    ID_EX_mem_read <= stall ? 0 : control_mem_read;
                    ID_EX_branch <= stall ? 0 : control_branch;
                    ID_EX_alu_op <= stall ? 0 : control_alu_op;
                    ID_EX_alu_src <= stall ? 0 : control_alu_src;   
                    ID_EX_reg_dst <= stall ? 0 : control_reg_dst;
                    ID_EX_rs <= IF_ID_instr[25:21];
                    ID_EX_rt <= IF_ID_instr[20:16];
                    ID_EX_rd <= IF_ID_instr[15:11];
                end
            end
            
    /** [step 3] Execute or address calculation (EX)*/
        /* ALU Control */
            wire [3:0] alu_control_operation;
            alu_control alu_control (
                .alu_op   (ID_EX_alu_op),
                .funct    (ID_EX_EXTENDED_INSTR[5:0]),
                .operation(alu_control_operation)
            );
        /* ALU */
            wire [31:0] alu_a, alu_b, alu_result;
            wire alu_zero, alu_overflow;
            alu alu (
                .a       (alu_a),
                .b       (alu_b),
                .ALU_ctl (alu_control_operation),
                .result  (alu_result),
                .zero    (alu_zero),
                .overflow(alu_overflow)
            );
        /** [step 2] Connect Forwarding unit
            * 1. add `ID_EX_rs` into ID/EX stage registers
            * 2. Use a mux to select correct ALU operands according to forward_A/B
            *    Hint don't forget that alu_b might be sign-extended immediate!
            */
            wire [1:0] forward_A, forward_B;
            forwarding forwarding (
                .ID_EX_rs        (ID_EX_rs),
                .ID_EX_mem_write (ID_EX_mem_write),
                .ID_EX_rt        (ID_EX_rt),
                .EX_MEM_reg_write(EX_MEM_reg_write),
                .EX_MEM_rd       (EX_MEM_rd),
                .MEM_WB_reg_write(MEM_WB_reg_write),
                .MEM_WB_rd       (MEM_WB_rd),
                .forward_A       (forward_A),
                .forward_B       (forward_B)
            );
            // forward 1st operand
            assign alu_a = (forward_A == 2'b01) ?  wb_result_data :    //lw forward
                    (forward_A == 2'b10) ? EX_MEM_alu_result: //operation forward
                    ID_EX_read_data1;  
            //assign alu_a = ID_EX_read_data1 ;
            // forward 2nd operand
            assign alu_b = (forward_B == 2'b01) ? wb_result_data : //lw forward
                    (forward_B == 2'b10) ? EX_MEM_alu_result : //operation forward
                    (ID_EX_alu_src) ? ID_EX_EXTENDED_INSTR :
                    ID_EX_read_data2 ;
            //assign alu_b = ID_EX_read_data2 ;
        /*********** ID/EX Registers ************/
            //alu_b
            reg [31:0] EX_MEM_read_data2;
            //forwarding
            reg [4:0] EX_MEM_rd, EX_MEM_rt;
            //write back
            reg EX_MEM_reg_write, EX_MEM_mem_to_reg;
            //mem
            reg EX_MEM_mem_write, EX_MEM_mem_read, EX_MEM_branch;
            //alu
            reg [31:0] EX_MEM_alu_result;
            //opcode
            reg  EX_MEM_reg_dst;

            always @(posedge clk or negedge rstn)begin
                if (!rstn)begin 
                    EX_MEM_read_data2 <= 0;  
                    EX_MEM_rd <= 0;
                    EX_MEM_reg_write <= 0;
                    EX_MEM_mem_to_reg <= 0;
                    EX_MEM_mem_write <= 0;
                    EX_MEM_mem_read <= 0;
                    EX_MEM_alu_result <= 0;
                    EX_MEM_reg_dst<= 0;
                    EX_MEM_rt <= 0;
                end
                else begin
                    EX_MEM_read_data2 <= ID_EX_read_data2;  
                    EX_MEM_rd <= (ID_EX_reg_dst ? ID_EX_rd: ID_EX_rt);
                    EX_MEM_reg_write <= ID_EX_reg_write;
                    EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
                    EX_MEM_mem_write <= ID_EX_mem_write;
                    EX_MEM_mem_read <= ID_EX_mem_read;
                    EX_MEM_alu_result <= alu_result;
                    EX_MEM_reg_dst<= ID_EX_reg_dst;
                    EX_MEM_rt <= ID_EX_rt;
                end
            end
        
        
        /** [step 4] Memory access (MEM)*/
        /* Data Memory */
            wire [31:0] data_mem_read_data, data_mem_write_data;
            data_mem #(
                .BYTES(DATA_BYTES),
                .START(DATA_START)
            ) data_mem (
                .clk       (~clk),                 // only write when negative edge
                .mem_read  (EX_MEM_mem_read),
                .mem_write (EX_MEM_mem_write),
                .address   (EX_MEM_alu_result),
                .write_data(data_mem_write_data),
                .read_data (data_mem_read_data)
            );
        /*********** sw forwarding****************/
            wire [31:0] wb_result_data;
            wire sw_forward;
            sw_forward sw_forward_ (
                .EX_MEM_mem_write(EX_MEM_mem_write),
                .MEM_WB_mem_to_reg(MEM_WB_mem_to_reg),
                .EX_MEM_rt(EX_MEM_rt),
                .MEM_WB_rd(MEM_WB_rd),
                .sw_forward(sw_forward)
            );

            assign data_mem_write_data = sw_forward ? wb_result_data : EX_MEM_read_data2;
            
        /*********** MEM/WB Registers ************/
            reg [31:0] MEM_WB_read_data, MEM_WB_ALU_result;
            reg [4:0] MEM_WB_rd;
            reg MEM_WB_mem_to_reg, MEM_WB_reg_write;
            always @(posedge clk or negedge rstn)begin
                if (!rstn) begin
                    MEM_WB_read_data <= 0;  
                    MEM_WB_ALU_result <= 0;  
                    MEM_WB_rd <= 0;  
                    MEM_WB_mem_to_reg <= 0;
                    MEM_WB_reg_write <= 0;
                end
                else begin
                    MEM_WB_read_data <= data_mem_read_data;  
                    MEM_WB_ALU_result <= EX_MEM_alu_result;  
                    MEM_WB_rd <= EX_MEM_rd;  
                    MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
                    MEM_WB_reg_write <= EX_MEM_reg_write; 
                end
            end
            
        /** [step 5] Write-back (WB)*/
            assign reg_file_reg_write = MEM_WB_reg_write;
            assign wb_result_data = MEM_WB_mem_to_reg ? MEM_WB_read_data : MEM_WB_ALU_result;
            assign reg_file_write_data = wb_result_data;
            assign reg_file_write_reg = MEM_WB_rd;


    

    

    /** [step 5] Control Hazard
     * This is the most difficult part since the textbook does not provide enough information.
     * By reading p.377-379 "Reducing the Delay of Branches",
     * we can disassemble this into the following steps:
     * 1. Move branch target address calculation & taken or not from EX to ID
     * 2. Move branch decision from MEM to ID
     * 3. Add forwarding for registers used in branch decision from EX/MEM
     * 4. Add stalling:
          branch read registers right after an ALU instruction writes it -> 1 stall
          branch read registers right after a load instruction writes it -> 2 stalls
     */

endmodule  // pipelined




// module ProgramCounter(
//     input clk,
//     input rstn,
//     input pc_write,
//     input [31:0] pc_next,
//     output reg [31:0] pc
// );
//     always @(posedge clk or negedge rstn)begin
//         if (!rstn) begin
//             pc <= 32'h00400000;  // 5.
//         end else begin
//             if(pc_write) pc <= pc_next;
// 	  	    else pc<= pc;
//         end
//     end
// endmodule
