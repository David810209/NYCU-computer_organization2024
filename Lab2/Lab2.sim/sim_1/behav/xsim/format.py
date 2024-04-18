#!/usr/bin/python3

USAGE = """
Usage:  python format.py IN_PREFIX OUT_PREFIX

    IN_PREFIX   the prefix of .txt file to format (e.g. 0)
                input files:    IN_PREFIX.reg.txt, IN_PREFIX.text.txt, IN_PREFIX.data.txt, 
                                IN_PREFIX.ans_reg.txt, IN_PREFIX.ans_data.txt
    OUT_PREFIX  the prefix of .mem file output (e.g. 0)
                output files:   OUT_PREFIX.reg.mem, OUT_PREFIX.text.mem, OUT_PREFIX.data.mem, 
                                OUT_PREFIX.ans_reg.mem, OUT_PREFIX.ans_data.mem

Parse registers, instructions & memory copied from output of JsSPIM website:
    https://shawnzhong.github.io/JsSpim/

Input Formats:

    Registers: (sequentially 32 lines)
        R0 (r0)  = 00000000
        ...
        R31 (ra) = 00000000
        
    Text: (make sure instruction value is after [<address>])
        [00400000] 8f880000 lw $8, 0($28)                   ; 11: lw      $t0, 0($gp)
        [00400004] af880004 sw $8, 4($28)                   ; 12: sw      $t0, 4($gp)
        ...

    Data: (sequentially placed at memory in `data_mem.v` regardless of [<address>])
        [10008000] 00114514 f1919810 00000001 00000002 ·E··············
        [10008010] 00000003 00000000 00000000 00000000 ················
        ...
"""

import sys
from typing import List


def split_word(word: str):
    """split word into bytes"""
    return " ".join([word[i : i + 2] for i in range(0, len(word), 2)])


def format_reg(lines: List[str]) -> List[str]:
    assert len(lines) == 32
    newlines = []
    for line in lines:
        name, value = [s.strip() for s in line.strip().split("=")]
        newline = "{}  // {}\n".format(value, name)
        newlines.append(newline)
    return newlines


def format_data(lines: List[str]) -> List[str]:
    newlines = []
    for line in lines:
        addr, d0, d1, d2, d3, cmt = [s.strip() for s in line.strip().split(maxsplit=5)]
        newline = "{}  {}  {}  {}  // {} {}\n".format(
            split_word(d0), split_word(d1), split_word(d2), split_word(d3), addr, cmt
        )
        newlines.append(newline)
    return newlines


def format_text(lines: List[str]) -> List[str]:
    newlines = []
    for line in lines:
        addr, instr, cmt = [s.strip() for s in line.strip().split(maxsplit=2)]
        newline = "{}  // {} {}\n".format(split_word(instr), addr, cmt)
        newlines.append(newline)
    return newlines


if __name__ == "__main__":
    argc = len(sys.argv)
    if argc != 3:
        print(
            "allow at most 2 arguments"
            if argc > 3
            else f"missing {'IN_PREFIX, ' if argc < 2 else ''}OUT_PREFIX"
        )
        print(USAGE)
        exit(1)
    else:
        in_prefix, out_prefix = sys.argv[1], sys.argv[2]
        open(f"{out_prefix}.reg.mem", "w").writelines(
            format_reg(open(f"{in_prefix}.reg.txt").readlines())
        )
        open(f"{out_prefix}.text.mem", "w").writelines(
            format_text(open(f"{in_prefix}.text.txt").readlines())
        )
        open(f"{out_prefix}.data.mem", "w").writelines(
            format_data(open(f"{in_prefix}.data.txt").readlines())
        )
        open(f"{out_prefix}.ans_reg.mem", "w").writelines(
            format_reg(open(f"{in_prefix}.ans_reg.txt").readlines())
        )
        open(f"{out_prefix}.ans_data.mem", "w").writelines(
            format_data(open(f"{in_prefix}.ans_data.txt").readlines())
        )
