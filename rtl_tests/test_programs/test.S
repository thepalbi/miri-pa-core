    add x2, x0, x0 # x2 accum
    addi x1, x0, 10 # x1 = counter
loop:
    addi x2, x2, 2   # x2 += 2
    addi x1, x1, -1 # x1 -= 1
    beq x1, x0, end # check loop end
    jal x0, loop    # continue
end:
    jal x0, end
