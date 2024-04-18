        .data   0x10008000      # start of Dynamic Data (pointed by $gp)
hun:    .word   0x00114514      # 0($gp)
hah:    .word   0xf1919810
        .word   0x1
        .word   0x2
        .word   0x3             # 16($gp)

        .text   0x00400000      # start of Text (pointed by PC), 
                                # Be careful there might be some other instructions in JsSPIM.
                                # Recommend at least 9 instructions to cover out those other instructions.
main:   add     $t1, $gp, $gp   # $t1 = 2 * $gp
        sub     $t2, $gp, $t1   # $t2 = - $gp
        slt     $a0, $t1, $gp   # $a0 = 0
        slt     $a1, $gp, $t1   # $a1 = 1
        slt     $v0, $t4, $gp   # $v0 = 1 (since $t4 is negative)
        slt     $v1, $gp, $t4   # $v1 = 0
        sub     $t0, $t1, $gp   # $t0 = $gp
        slt     $s0, $t0, $gp   # $s0 = 0
        slt     $s1, $gp, $t0   # $s1 = 0
        or      $zero, $t1, $t2 # test write to zero
        and     $zero, $t1, $t2
        or      $t3, $t1, $t2   # test OR
        and     $t4, $t1, $t2   # test AND
        nop                     # test NOP
        lw      $t5, hun     # test LW
        sw      $t5, 8($gp)     # test SW
bst:    beq     $t0, $gp, btg   # [bst] should branch
        or      $t9, $zero, $gp # should not execute
        lw      $t8, 0($gp)     # should not execute
btg:    j       end             # [btg] should jump
        or      $t7, $zero, $gp # should not execute
        lw      $t6, 0($gp)     # should not execute
end:    lw      $t5, hah        # [end]
        sw      $t5, 12($gp)
        beq     $zero, $gp, bst # should not branch
        li      $a3, 0xa114514a # test li (lui, ori)
