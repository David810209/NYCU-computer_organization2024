`timescale 1ns / 1ps
// 111550076

/** [Reading] 4.7 p.372-375
 * Understand when and how to detect stalling caused by data hazards.
 * When read a reg right after it was load from memory,
 * it is impossible to solve the hazard just by forwarding.
 */

/* checkout FIGURE 4.59 to understand why a stall is needed */
/* checkout FIGURE 4.60 for how this unit should be connected */
module hazard_detection (
    input        take_branch,
    input        ID_EX_mem_read,
    input        control_mem_write,
    input        EX_MEM_mem_read,
    input        MEM_WB_mem_to_reg,
    input        EX_MEM_reg_write,
    input  [4:0] ID_EX_rt,
    input  [4:0] IF_ID_rs,
    input  [4:0] IF_ID_rt,
    input  [4:0] EX_MEM_rd,
    input  [4:0] MEM_WB_rd,
    output       pc_write,        // only update PC when this is set
    output       IF_ID_write,     // only update IF/ID stage registers when this is set
    output       stall            // insert a stall (bubble) in ID/EX when this is set
);

    /** [step 3] Stalling
     * 1. calculate stall by equation from textbook.
     * 2. Should pc be written when stall?
     * 3. Should IF/ID stage registers be updated when stall?
     */
    wire lw_hazard = ID_EX_mem_read && ~control_mem_write && ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt));
    
    wire branch_hazard_1 = take_branch && ((EX_MEM_reg_write && (IF_ID_rs == EX_MEM_rd || IF_ID_rt == EX_MEM_rd) ) ||
                             (MEM_WB_mem_to_reg && (IF_ID_rs == MEM_WB_rd || IF_ID_rt == MEM_WB_rd) ) );
    wire branch_hazard_2 =  take_branch && (ID_EX_mem_read && (IF_ID_rs == ID_EX_rt || IF_ID_rt == ID_EX_rt) || (EX_MEM_mem_read && (IF_ID_rs == EX_MEM_rd || IF_ID_rt == EX_MEM_rd)));
    wire hazard = lw_hazard || branch_hazard_1 || branch_hazard_2 ;
    assign stall = hazard;
    assign pc_write = ~hazard;
    assign IF_ID_write = ~hazard;
endmodule
