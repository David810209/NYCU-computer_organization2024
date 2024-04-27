        .data   0x10008000      # start of Dynamic Data (pointed by $gp)
val1:   .word   0x00114514      # Some test data
val2:   .word   0xf1919810
        .word   0x1
        .word   0x2
        .word   0x3             # Data array

        .text   0x00400000      # start of Text (program code)
start:  lui     $t0, 0x1000     # Load upper immediate for address calculation
        ori     $t0, $t0, 0x8000 # Form address in $t0

        add     $t1, $t0, $zero # $t1 = $t0 (copy base address)
        lw      $t2, 0($t1)     # Load word from address in $t1
        lw      $t3, 4($t1)     # Load next word

        add     $t4, $t2, $t3   # $t4 = $t2 + $t3
        sub     $t5, $t2, $t3   # $t5 = $t2 - $t3
        and     $t6, $t2, $t3   # $t6 = $t2 & $t3
        or      $t7, $t2, $t3   # $t7 = $t2 | $t3
        slt     $t8, $t2, $t3   # Set $t8 = 1 if $t2 < $t3, else 0

        sw      $t4, 8($t1)     # Store result of add at address $t1 + 8
        sw      $t5, 12($t1)    # Store result of sub at address $t1 + 12

        nop                     # No operation (useful for delay slots)

        beq     $t2, $t3, equal # Branch to "equal" if $t2 == $t3
        j       end             # Jump to end if not equal

equal:  li      $t9, 0xAABB     # Load immediate (pseudoinstruction)
        j       end             # Jump to end

end:    nop                     # End of the program, do nothing
