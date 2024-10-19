        .data   0x10008000      # start of Dynamic Data (pointed by $gp)
        .word   0x0             # 0($gp)
        .word   0x1             # 4($gp)
        .word   0x2             # 8($gp)
        .word   0x3             # 12($gp)

        .text   0x00400000      # start of Text (pointed by PC), 
                                # Be careful there might be some other instructions in JsSPIM.
                                # Recommend at least 9 instructions to cover out those other instructions.
main:   lw      $a0, 0($gp)
        lw      $a1, 4($gp)
        add     $t0, $a1, $gp   # t0 = gp, since `lw $a1` is at ID
        lw      $a2, 8($gp)
        add     $t1, $a1, $a1   # t1 = 2, since `lw $a1` is at MEM (when this enter ID, lw enter WB)
        lw      $a3, 12($gp)
        sub     $t2, $0, $t1    # t2 = 0, since `add $t1` is at MEM
        nop
        slt     $t3, $a2, $a3   # t3 = 1, Read after write need to wait for ? more instructions?
        slt     $t4, $a1, $a2   # t4 = 1
        or      $t5, $gp, $t3   # t5 = gp, since t3 has not been written yet
        and     $t6, $a1, $t3   # t6 = 1, since t3 is written in this cycle
        beq     $t3, $t4, end   # taken
        add     $s1, $0, $a1    # will this executed even branch is taken? How about others?
        add     $s2, $0, $a2
        add     $s3, $0, $a3
        add     $s4, $a2, $a2
        add     $s5, $a2, $a3
        add     $s6, $a3, $a3
end:    add     $s7, $s4, $a2   # s7 = 2
