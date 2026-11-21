addi x1, x1, 1
addi x2, x2, 2
add  x3, x1, x2 # x3 == 3
mul  x4, x1, x3 # x4 should be ready in A, while this instr is in decode

# !rf[1] == 1
# !rf[3] == 3
# !rf[4] == 3
