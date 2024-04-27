        .data   0x10008000      # start of Dynamic Data (pointed by $gp)
hun:    .word   0x00114514      # 0($gp)
hah:    .word   0xf1919810
        .word   0x1
        .word   0x2
        .word   0x3             # 16($gp)

        .text   0x00400000      # start of Text (pointed by PC), 
                                # Be careful there might be some other instructions in JsSPIM.
                                # Recommend at least 9 instructions to cover out those other instructions.
main:   li      $t0, 0x12345678
        sub     $t1, $gp, $t0   
        slt     $a0, $t1, $gp   
        add     $t2, $t1, $gp   # $t0 = $gp
        nop                     # test NOP
        and     $t4, $t1, $t2   # test AND
        or      $t5, $t1, $t2   # test OR
        nop                     # test NOP
        lw      $t5, hun     # test LW
        sw      $t5, 8($gp)     # test SW
        nop                     # test NOP
        j       end             # [btg] should jump
end:    lw      $t5, hah        # [end]
        sw      $t5, 12($gp)
        nop                     # test NOP
        li      $a3, 0xa114514a # test li (lui, ori)
        slt     $t6, $t2, $t3
        beq     $zero, $t6, func
func:   li      $t6, 0x18476502
