# -PCI-communication-protocol
PCI communication protocol in verilog. You have two main modules :  1- Device 2- Arbiter
i have at least 3 devices (A,B,C). A has highest priority, then B, then C is the least important. 
 
Model the following scenario  ::  
 
1- Device A requests the bus in order to communicate with device B and send 3 data words in the transaction. Assume that Device A always sends the word “AAAAAAAA”. So after this, we should have 3 rows of device B having the values “AAAAAAAA”. 
 
2- Device B requests the bus in order to communicate with device A and send two data words.  Assume that device B always sends the word “BBBBBBBB” 
 
3- Device C requests the bus for two transactions, and at the same time device A requests the bus again to communicate with Device C. What should happen here is as follows :  - The arbiter will grant device A since it has a higher priority, then device A will send two data words to device C. - The arbiter must then grant the bus to device C, C now wants to send data to device A, send one word. - Device C still wants the bus to communicate with device B, and send another data word to B. So it will have the bus for a second transaction since both A & B don’t request the bus any more 
