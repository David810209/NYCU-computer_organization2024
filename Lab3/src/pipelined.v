`timescale 1ns / 1ps
// 111550076


/** [Prerequisite] Lab 2: alu, control, alu_control
 * This module is the pipelined MIPS processor in FIGURE 4.51
 * You can implement it by any style you want, as long as it passes testbench
 */

/* checkout FIGURE 4.51 */
module pipelined #(
    parameter integer TEXT_BYTES = 1024,        // size in bytes of instruction memory
    parameter integer TEXT_START = 'h00400000,  // start address of instruction memory
    parameter integer DATA_BYTES = 1024,        // size in bytes of data memory
    parameter integer DATA_START = 'h10008000   // start address of data memory
) (
    input clk,  // clock
    input rstn  // negative reset
);

    /****************** [step 1] Instruction fetch (IF)*******************************
     * 1. We need a register to store PC (acts like pipeline register).
     * 2. Wire pc to instruction memory.
     * 3. Implement an adder to calculate PC+4. (combinational)
     *    Hint: use "+" operator.
     * 4. Update IF/ID pipeline registers, and reset them @(negedge rstn)
     *    a. fetched instruction
     *    b. PC+4
     *    Hint: What else should be done when reset?
     *    Hint: Update of PC can be handle later in MEM stage.
     */
        /************ Instruction Memory ***********************/
            wire [31:0] instr_mem_address, instr_mem_instr;
            instr_mem #(
                .BYTES(TEXT_BYTES),
                .START(TEXT_START)
            ) instr_mem (
                .address(instr_mem_address),
                .instr  (instr_mem_instr)
            );

        // 1.
        reg [31:0] pc;  // DO NOT change this line 
        // 2.
        assign instr_mem_address = pc;
        // 3.
        wire [31:0] pc_4 = pc + 4; 
        // 4.
        reg [31:0] IF_ID_instr, IF_ID_pc_4; 
        always @(posedge clk or negedge rstn)begin
            if (!rstn) begin
                IF_ID_instr <= 0;  // a.
                IF_ID_pc_4  <= 0;  // b.
            end
            else begin
                IF_ID_instr <= instr_mem_instr;  // a.
                IF_ID_pc_4  <= pc_4;  // b.
            end
        end


  
    /******** [step 2] Instruction decode and register file read (ID)****************************
     * From top to down in FIGURE 4.51: (instr. refers to the instruction from IF/ID)
     * 1. Generate control signals of the instr. (as Lab 2)
     * 2. Read desired registers (from register file) in the instr.
     * 3. Calculate sign-extended immediate from the instr.
     * 4. Update ID/EX pipeline registers, and reset them @(negedge rstn)
     *    a. Control signals (WB, MEM, EX)
     *    b. ??? (something from IF/ID)
     *    c. Data read from register file
     *    d. Sign-extended immediate
     *    e. ??? & ??? (WB stage needs to know which reg to write)
     */

        /******************** Register Rile ****************************************************/
            wire [4:0] reg_file_read_reg_1, reg_file_read_reg_2, reg_file_write_reg;
            wire reg_file_reg_write;
            wire [31:0] reg_file_write_data, reg_file_read_data_1, reg_file_read_data_2;
            reg_file reg_file (
                .clk        (~clk),                  // only write when negative edge
                .rstn       (rstn),
                .read_reg_1 (reg_file_read_reg_1),
                .read_reg_2 (reg_file_read_reg_2),
                .reg_write  (reg_file_reg_write),
                .write_reg  (reg_file_write_reg),
                .write_data (reg_file_write_data),
                .read_data_1(reg_file_read_data_1),
                .read_data_2(reg_file_read_data_2)
            );

        /************* (Main) Control ****************************************************/
            wire [5:0] control_opcode;
            // Execution/address calculation stage control lines
            wire control_reg_dst, control_alu_src;
            wire [1:0] control_alu_op;
            // Memory access stage control lines
            wire control_branch, control_mem_read, control_mem_write, jump_op;
            // Wire-back stage control lines
            wire control_reg_write, control_mem_to_reg;
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
            
        assign control_opcode = IF_ID_instr[31:26];
        assign reg_file_read_reg_1 = IF_ID_instr[25:21];
        assign reg_file_read_reg_2 = IF_ID_instr[20:16];
        wire [31:0] extended_instr;
        assign extended_instr = { {16{IF_ID_instr[15]}}, IF_ID_instr[15:0] };
        reg [31:0] ID_EX_pc_4, ID_EX_EXTENDED_INSTR, ID_EX_RD1, ID_EX_RD2;
        //write back
        reg ID_EX_reg_write, ID_EX_mem_to_reg;
        //mem
        reg ID_EX_mem_write, ID_EX_mem_read, ID_EX_branch;
        //ex
        reg [1:0] ID_EX_alu_op;
        reg ID_EX_alu_src, ID_EX_reg_dst;
        //write reg
        reg [9:0] ID_EX_WR;
        
        
        always @(posedge clk or negedge rstn)begin
            if (!rstn)begin
                ID_EX_pc_4 <= 0;  
                ID_EX_EXTENDED_INSTR  <= 0;  
                ID_EX_WR <= 0;
                ID_EX_RD1 <= 0;
                ID_EX_RD2 <= 0;
                ID_EX_reg_write <= 0;
                ID_EX_mem_to_reg <= 0;
                ID_EX_mem_write <= 0;
                ID_EX_mem_read <= 0;
                ID_EX_branch <= 0;
                ID_EX_alu_op <= 0;
                ID_EX_alu_src <= 0;
                ID_EX_reg_dst <= 0;
            end
            else begin
                ID_EX_pc_4 <= IF_ID_pc_4;  // a.
                ID_EX_EXTENDED_INSTR  <= extended_instr;  // b.
                ID_EX_WR <= {IF_ID_instr[20:16], IF_ID_instr[15:11]};
                ID_EX_RD1 <= reg_file_read_data_1;  
                ID_EX_RD2 <= reg_file_read_data_2;
                ID_EX_reg_write <= control_reg_write;
                ID_EX_mem_to_reg <= control_mem_to_reg;
                ID_EX_mem_write <= control_mem_write;
                ID_EX_mem_read <= control_mem_read;
                ID_EX_branch <= control_branch;
                ID_EX_alu_op <= control_alu_op;
                ID_EX_alu_src <= control_alu_src;   
                ID_EX_reg_dst <= control_reg_dst;
            end
        end
        
        

    /** [step 3] Execute or address calculation (EX)
     * From top to down in FIGURE 4.51
     * 1. Calculate branch target address from sign-extended immediate.
     * 2. Select correct operands of ALU like in Lab 2.
     * 3. Wire control signals to ALU control & ALU like in Lab 2.
     * 4. Select correct register to write.
     * 5. Update EX/MEM pipeline registers, and reset them @(negedge rstn)
     *    a. Control signals (WB, MEM)
     *    b. Branch target address
     *    c. ??? (What information dose MEM stage need to determine whether to branch?)
     *    d. ALU result
     *    e. ??? (What information does MEM stage need when executing Store?)
     *    f. ??? (WB stage needs to know which reg to write)
     */
        /* ALU Control */
            wire [1:0] alu_control_alu_op;
            wire [5:0] alu_control_funct;
            wire [3:0] alu_control_operation;
            alu_control alu_control (
                .alu_op   (alu_control_alu_op),
                .funct    (alu_control_funct),
                .operation(alu_control_operation)
            );
        /* ALU */
            wire [31:0] alu_a, alu_b, alu_result;
            wire [3:0] alu_ALU_ctl;
            wire alu_zero, alu_overflow;
            alu alu (
                .a       (alu_a),
                .b       (alu_b),
                .ALU_ctl (alu_ALU_ctl),
                .result  (alu_result),
                .zero    (alu_zero),
                .overflow(alu_overflow)
            );
        
        assign alu_ALU_ctl = alu_control_operation;
        assign alu_control_funct = ID_EX_EXTENDED_INSTR[5:0];
        assign alu_control_alu_op = ID_EX_alu_op;
         reg [31:0] EX_MEM_branch_target, EX_MEM_RD2;
        reg [4:0] EX_MEM_WR;
        //write back
        reg EX_MEM_reg_write, EX_MEM_mem_to_reg;
        //mem
        reg EX_MEM_mem_write, EX_MEM_mem_read, EX_MEM_branch;
        //alu
        reg EX_MEM_alu_zero;
        reg [31:0] EX_MEM_alu_result;
        wire [31:0] branch_target_address;
        assign alu_a = ID_EX_RD1;
        assign alu_b = ID_EX_alu_src ? ID_EX_EXTENDED_INSTR : ID_EX_RD2;
        // MUX_2to1 #(32) mux_alu_b (
        //     .data0_i(ID_EX_RD2),
        //     .data1_i(ID_EX_EXTENDED_INSTR),
        //     .select_i(ID_EX_alu_src),
        //     .data_o(alu_b)
        // );
        assign branch_target_address = ID_EX_pc_4 + (ID_EX_EXTENDED_INSTR << 2);

        // MUX_2to1  #(.size(5)) mux_write_reg (
        //     .data0_i(ID_EX_WR[9:5]),
        //     .data1_i(ID_EX_WR[4:0]),
        //     .select_i(ID_EX_reg_dst),
        //     .data_o(EX_MEM_WR)
        // );

        always @(posedge clk or negedge rstn)begin
            if (!rstn)begin
                EX_MEM_branch_target <= 0;  
                EX_MEM_RD2 <= 0;  
                EX_MEM_WR <= 0;
                EX_MEM_reg_write <= 0;
                EX_MEM_mem_to_reg <= 0;
                EX_MEM_mem_write <= 0;
                EX_MEM_mem_read <= 0;
                EX_MEM_branch <= 0;
                EX_MEM_alu_result <= 0;
                EX_MEM_alu_zero <= 0;
            end
            else begin
                EX_MEM_branch_target <= branch_target_address;  
                EX_MEM_RD2 <= ID_EX_RD2;  
                EX_MEM_WR <= (ID_EX_reg_dst ? ID_EX_WR[4:0] : ID_EX_WR[9:5]);
                EX_MEM_reg_write <= ID_EX_reg_write;
                EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
                EX_MEM_mem_write <= ID_EX_mem_write;
                EX_MEM_mem_read <= ID_EX_mem_read;
                EX_MEM_branch <= ID_EX_branch;
                EX_MEM_alu_result <= alu_result;
                EX_MEM_alu_zero <= alu_zero;
            end
        end
       
       
    
    /** [step 4] Memory access (MEM)
     * From top to down in FIGURE 4.51
     * 1. Decide whether to branch or not.
     * 2. Wire address & data to write
     * 3. Wire control signal of read/write
     * 4. Update MEM/WB pipeline registers, and reset them @(negedge rstn)
     *    a. Control signals (WB)
     *    b. ???
     *    c. ???
     *    d. ???
     * 5. Update PC.
     */
     /* Data Memory */
        wire data_mem_mem_read, data_mem_mem_write;
        wire [31:0] data_mem_address, data_mem_write_data, data_mem_read_data;
        data_mem #(
            .BYTES(DATA_BYTES),
            .START(DATA_START)
        ) data_mem (
            .clk       (~clk),                 // only write when negative edge
            .mem_read  (data_mem_mem_read),
            .mem_write (data_mem_mem_write),
            .address   (data_mem_address),
            .write_data(data_mem_write_data),
            .read_data (data_mem_read_data)
        );
        assign data_mem_address = EX_MEM_alu_result;
        assign data_mem_write_data = EX_MEM_RD2;
        assign data_mem_mem_read = EX_MEM_mem_read;
        assign data_mem_mem_write = EX_MEM_mem_write;
        wire take_branch;
        assign take_branch = EX_MEM_branch & EX_MEM_alu_zero;
        reg [31:0] pc_next;
        wire [31:0] branch_target = EX_MEM_branch_target;
        always @(*)begin
            pc_next <= take_branch ? branch_target : pc_4;
        end
        // MUX_2to1  #(.size(32)) mux_pc (
        //     .data0_i(pc_4),
        //     .data1_i(branch_target),
        //     .select_i(take_branch),
        //     .data_o(pc_next)
        // );
        always @(posedge clk or negedge rstn)begin
            if (!rstn) begin
                pc <= TEXT_START;  // 5.
            end else begin
                pc <= pc_next;  // 5.
            end
        end


        reg [31:0] MEM_WB_RD, MEM_WB_ALU_result;
        reg [4:0] MEM_WB_WR;
        reg MEM_WB_mem_to_reg, MEM_WB_reg_write;
        always @(posedge clk or negedge rstn)begin
            if (!rstn) begin
                MEM_WB_RD <= 0;  
                MEM_WB_ALU_result <= 0;  
                MEM_WB_WR <= 0;  
                MEM_WB_mem_to_reg <= 0;
                MEM_WB_reg_write <= 0;
            end
            else begin
                MEM_WB_RD <= data_mem_read_data;  
                MEM_WB_ALU_result <= EX_MEM_alu_result;  
                MEM_WB_WR <= EX_MEM_WR;  
                MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
                MEM_WB_reg_write <= EX_MEM_reg_write; 
            end
        end
        
     

    /** [step 5] Write-back (WB)
     * From top to down in FIGURE 4.51
     * 1. Wire RegWrite of register file.
     * 2. Select the data to write into register file.
     * 3. Select which register to write.
     */
        assign reg_file_reg_write = MEM_WB_reg_write;
        assign reg_file_write_data = MEM_WB_mem_to_reg ? MEM_WB_RD : MEM_WB_ALU_result;
        // MUX_2to1    #(.size(32)) mux_reg_file_write_data (
        //     .data0_i(MEM_WB_ALU_result),
        //     .data1_i(MEM_WB_RD),
        //     .select_i(MEM_WB_mem_to_reg),
        //     .data_o(reg_file_write_data)
        // );
        
        assign reg_file_write_reg = MEM_WB_WR;


endmodule  // pipelined

// module MUX_2to1(
//     data0_i,
//     data1_i,
//     select_i,
//     data_o
// );

// parameter size = 0;			   
			
// //I/O ports               
// input   [size-1:0] data0_i;          
// input   [size-1:0] data1_i;
// input              select_i;
// output  [size-1:0] data_o; 

// //Internal Signals
// reg     [size-1:0] data_o;

// //Main function
// always @(*) begin
//     data_o <= (select_i)?data1_i:data0_i;
// end

// endmodule