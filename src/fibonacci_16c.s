        # overflow counter init
        c.li    a4, 0
restart:
        # fibonacci init A=0 B=1
        c.li    a0, 0
        c.li    a1, 1
main_loop:
        # shift & mask a 33-bit add, then check msb 
        c.mv    a2, a0
        c.mv    a3, a1
        c.srli  a2, 1
        c.srli  a3, 1
        c.add   a2, a3
        c.mv    a3, a1
        c.mv    a4, a0
        c.andi  a3, 1
        c.andi  a4, 1
        c.add   a3, a4
        c.srli  a3, 1
        c.add   a2, a3
        c.srli  a2, 31
        c.bnez  a2, overflow
        # the ACUTAL fibb addition
        c.add   a0, a1
        # swap A and B
        c.xor   a0, a1
        c.xor   a1, a0
        c.xor   a0, a1
        c.j     main_loop
overflow:
        # increment overflow counter and restart
        c.addi  a4, 1
        c.j     restart
