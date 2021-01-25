        # overflow counter init
        add     a2, x0, x0
restart:
        # fibonacci init A=0 B=1
        c.li    a0, 0
        c.li    a1, 1
main_loop:
        add     a0, a1, a0
        bltu    a0, a1, overflow
        add     a1, a0, a1
        bltu    a1, a0, overflow
        j       main_loop
overflow:
        # increment overflow counter and restart
        c.addi  a2, 1
        c.j     restart
