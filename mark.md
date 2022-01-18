## Problems encountered

### timing loop

Most of the debug time is put on eliminating the timing loop. Finally it is found 2 days before the dead line. It is caused by reading the Q value from and put the Q value into ROB when sending the instruction to EX directly in the case there is no executable entry in RS. After removing this optimization the timing loop was gone.

**tips**: When I try to find the reason why timing loops occur, I remove some part of the code and run the synthesis. It is difficult to find the loop through checking the digital design.

### latch

Though not critical warning, latch must be removed.

I try to cut off a circle using `assign tmp[7:0] = (counter==0) mem_in:tmp[7:0]`, which will definitely cause timing loop. With this problem we can run synthesis, but will be dead loop in runing fpga.

### can not read from io

IO read/write will cause hci to change between mem and io buffer, which will cause the information miss (e.g. circle 1 io, we can not receive circle 0's mem read result because hci switches to io buffer). So make sure there is no read in the circle before and after the very io read/write.

### other han han problem

Remember to turn on the fpga switch, or it can not be detected by the vivado.