addi x1, x1, 1
nop; nop; nop; # 3 NOPS should get next instruction to fetch, while prev. is in write-back
add  x2, x1, x1

# !rf[1] == 1
# !rf[2] == 2
