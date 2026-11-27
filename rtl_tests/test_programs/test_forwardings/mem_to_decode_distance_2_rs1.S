# !dmem[0x10] = 40

li x5, 0x10 # This fwd should work
lw x6, 0(x5)
nop # Force bubble
addi x6, x6, 2

# ?rf[6] == 42
