*-----------------------------------------------------------
* Title      :  Disassembler
* Written by :  Paul Kessler and Joscelyn Kim
* Date       :  199X
* Description:  This program takes assembled code and disassembles it into 
*               assembly language readable by humans.  The program will be 
*               disassembed in a user defined address range
*-----------------------------------------------------------
CR          EQU $0D
LF          EQU $0A
mask        EQU $0000000F
ascii_mask  EQU $00FF
counter     EQU 0
stack       EQU $B000
line_count  EQU 30

*---- User input address range -----

                ORG         $1000                       * start of the program
                LEA         stack,SP                    * initialize the stack
                CLR.B       D0                          * clear D0
strt_addr_rng   
                LEA         start_addr_range,A1
                MOVE.B      #14,D0
                TRAP        #15
                LEA         start_addr_msg, A1          * ask for starting address
                MOVE.B      #14, D0
                TRAP        #15
                MOVEA.L     A4,A1                         
                MOVE.B      #2, D0                      * take in user input as string
                TRAP        #15
                CMP.B       #6,D1
                BGT         invalid_str_range
                MOVEM.W     A0-A6/D0-D7,-(SP)           * push registers on the stack
                JSR         get_addr                    * strip ascii characters to hex
                MOVEM.W     (SP)+, A0-A6/D0-D7          * restore registers
                MOVE.L      addr_val_temp,st_val
                
end_addr_rng    LEA         end_addr_msg, A1            * ask for ending address
                MOVE.B      #14, D0
                TRAP        #15
                MOVEA.L     A4,A1                       * reset address at A1 to get user input
                MOVE.B      #2, D0                      * take address as a string
                TRAP        #15
                CMP.B       #6,D1                       *if greater than 6 it is bad address
                BGT         invalid_end_range
                MOVEM.W     A0-A6/D0-D7,-(SP)           * push registers on the stack
                JSR         get_addr                    * strip ascii address into hex
                MOVEM.W     (SP)+, A0-A6/D0-D7          * restore the registers
                MOVE.L      addr_val_temp, end_val      * store address in end_val
                MOVE.L      st_val,D2
                MOVE.L      end_val,D3
                CMP.L       D3,D2
                BGT         invalid_end_range
                MOVEA.L     st_val,A5                   * store start val in A5
                MOVEA.L     end_val,A6                  * store end val in A6
                
                LEA         outputStart,A1              *ouput starting messaage
                MOVE.B      #14,D0          
                TRAP        #15
                
                LEA         outputNextLine,A1           *output nextline
                MOVE.B      #14,D0
                TRAP        #15
                
                MOVE.B      #line_count,(A3)
                SUBQ.B      #2,(A3)
                BRA         getOpCode                   * Jump to getOpCode sub routine

invalid_str_range
                LEA         enter_strt_again,A1         *output bad start input
                MOVE.B      #14,D0
                TRAP        #15
                BRA         strt_addr_rng

invalid_end_range
                LEA         enter_end_again,A1          *output bad end input
                MOVE.B      #14,D0
                TRAP        #15
                BRA         end_addr_rng                

get_addr 
                SUBQ.B      #1,D1
                CLR.L       D7                          * we need D7 to be 0
                MOVE.B      (A1)+,D0                    * store first byte in D0
                ANDI.L      #ascii_mask,D0              * mask the first byte
                JSR         strip_ascii                 * strip ascii char into hex
                MULS.W      #4,D1
                ASL.L       D1,D0                       * shift left 8
                OR.L        D0,D7
                MOVE.B      (A1)+,D0                    * move next byte into D0
loop            SUBQ.B      #4,D1
                ANDI.L      #ascii_mask,D0              * mask the second byte
                JSR         strip_ascii                 * strip ascii to hex
                ASL.L       D1,D0                       * shift left 8
                OR.L        D0,D7
                CMP.B       #0,D1
                BEQ         rts_strtAddr
                MOVE.B      (A1)+,D0
                BRA         loop
                
rts_strtAddr
                MOVE.L      D7,addr_val_temp
                RTS     
                
strip_ascii     CMP.B       #$30,D0                     *is it less than A?
                BLT         invalid_addr                *then it is bad addr
                CMP.B       #$47,D0                     *is it G or above?
                BGE         check_range                 *check if its G - '
strip_cont      CMP.B       #$66,D0                     *greater than f?
                BGT         invalid_addr                *than it is bad addr
                CMP.B       #$39,D0                     *Is it in range of 0-9?
                BLE         sub30                       *It's a number
                CMP.B       #$46,D0                     *Is it A...F?
                BLE         sub37                       *It's A...F
                SUB.B       #$57,D0                     *It's a...f
                BRA         ret_sa                      *Go back
sub37           SUB.B       #$37,D0                     *Strip 37
                BRA         ret_sa                      *Go back
sub30           SUB.B       #$30,D0                     *Strip 30
ret_sa          RTS                                     *Go back
check_range
                CMP.B       #$60,D0                     *is it between G and '?
                BLT         invalid_addr                *it is invalid then
                BRA         strip_cont                  *continue if not
invalid_addr
    LEA         invalid_addr_input,A1                   *outputs bad input
    MOVE.B      #14,D0
    TRAP        #15
    MOVEA.L     A4,A1                                   *clear A1
    BRA         strt_addr_rng                           *go back to the address start
                
*---- Data For address input -------

start_addr_msg  DC.B    'Enter a starting address to disassemble: $', 0
end_addr_msg    DC.B    'Enter a ending address to stop disassembling: $', 0
invalid_addr_input DC.B 'Invalid address range, enter again.',CR,LF,0
start_addr_range   DC.B 'Enter an address range between 000000 and FFFFFF',CR,LF,0
enter_strt_again DC.B   'Starting address is invalid, Enter again',CR,LF,0
enter_end_again DC.B    'Ending address is invalid, Enter again',CR,LF,0
addr_val_temp   DC.L    $00000000
st_val          DC.L    $00000000
end_val         DC.L    $00000000

*--- Data end for address input ----


* Disassembler Start
getOpCode                        *Gets opcode    
    CLR.L   D7
    CLR.L   D6
    CLR.L   D3
    CLR.L   D1
    CLR.L   D0
    CLR.L   D5
    CLR.L   D4
    
    SUBQ.B  #1,(A3)
    CMP.B   #0,(A3)
    BEQ     pageContinue
    
    MOVE.W  A5,D1               *move starting addr into D1
    MOVE.B  #15,D0              *convert number into hex and output to console
    MOVE.B  #16,D2
    TRAP    #15    
    MOVE.W  (A5)+,D4            *move data at starting addr to D4
    
    CLR.L   D1
    
    LEA     outputColon,A1      *output the colon and a space to the console
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVEA.L A0,A1               *used to clear A0
    MOVE.W  D4,D2               *gets put into D4 and D2
    
    ROL.W   #4,D2               *rotate the first 4 significant bits to lower 4 bits
    
    AND.L   #mask,D2            *mask it to get only the first byte
    
    MOVE.B  D2,D5               *put that value into D5

nopOpCode
    CMP.W   #$4E71,D4           *is it NOP?
    BNE     rtsOpCode
    
    LEA     outputNOP,A1        *output NOP
    MOVE.B  #14,D0
    TRAP    #15
    BRA     DONE                *we are done
    
rtsOpCode
    CMP.W   #$4E75,D4           *is it RTS?
    BNE     jsrOpCode
    
    LEA     outputRTS,A1        *outputRTS
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     DONE                *we are done
    
jsrOpCode
    MOVE.W  D4,D3               *move opcode to D3
    ROL.W   #8,D3               *isolate most sig 8 bits
    AND.W   #$00FF,D3           *mask them
    CMP.B   #$4E,D3             *is it JSR
    BNE     movemOpCode
jsrMethod
    MOVE.W  D4,D3               *move opcode into D3
    ROR.W   #3,D3               *move mode bits               
    AND.B   #7,D3               *mask mode bits
    CMP.B   #2,D3               *check addressing mode
    BEQ     jsrOutputDeref
    
    CMP.B   #7,D3               *check addressing mode
    BEQ     jsrOutputLabel

    BRA     dataOpCode          *bad addressing mode output data
        
jsrOutputDeref
    LEA     outputJSR,A1        *output JSR
    MOVE.B   #14,D0
    TRAP    #15
    
    JSR     sourceEA            *source EA mode
    
    BRA     DONE                *we are done
    
jsrOutputLabel
    MOVE.B  D4,D3               *move opcode into D3
    AND.B   #$07,D3             *mask reg bits
    CMP.B   #1,D3               *can only be reg 0 or 1
    BGT     dataOpCode          *data if greater than 1
    
    LEA     outputJSR,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *get source EA
    
    BRA     DONE                *we are done
	
movemOpCode		
    MOVE.W  D4,D3               *move opcode into D3		
    ASR.W   #6,D3		        *isolate most sig 10 bits
    CMP.W   #$0122,D3		    *is it movem W Reg to Mem?
    BEQ     movemMethodRegToMem		
    CMP.W   #$0132,D3		    *is it movem W Mem to Reg?
    BEQ     movemMethodMemToReg		
    CMP.W   #$0123,D3		    *is it movem L Reg to Mem?
    BEQ     movemLongRegToMem		
    CMP.W   #$0133,D3		    *is it movem L Mem to Reg?
    BEQ     movemLongMemToReg		
    BRA     leaOpCode           *not movem, check if LEA

movemLongRegToMem
    MOVE.B  #1,D6               *D6 is used later to check if Long or Word
    BRA     movemMethodRegToMem *BRA to Reg to Mem Method

movemLongMemToReg
    MOVE.B  #1,D6               *D6 is used later to check if Long or Word
    BRA     movemMethodMemToReg	*BRA to Mem to Reg	
    		
movemMethodRegToMem		
    MOVE.B  #0,D5                *indicates Reg to Mem		
    MOVE.W  D4,D3		         *move opcode into D3
    ROR.B   #3,D3		         *isolate mode bits
    AND.W   #$0007,D3		     *mask mode bits
    CMP.B   #2,D3	             *check addressing mode	
    BEQ     movemOutput		
    CMP.B   #4,D3		         *check addressing mode
    BEQ     movemOutput		
    CMP.B   #7,D3		         *check addressing mode
    BEQ     movemOutput		
    BRA     dataOpCode		     *addressing mode illegal output as data
        		
movemMethodMemToReg		
    MOVE.B  #1,D5                *1 means movem is Mem to Reg
    MOVE.W  D4,D3		         *move opcode into D3
    ROR.B   #3,D3		         *isolate mode bits
    AND.W   #$0007,D3		     *mask mode bits
    CMP.B   #2,D3		         *check addressing mode
    BEQ     movemOutput		
    CMP.B   #3,D3		         *check addressing mode
    BEQ     movemOutput		
    CMP.B   #7,D3		         *check addressing mode
    BEQ     movemOutput		
    BRA     dataOpCode		     *illegal addressing mode output as data
    		
movemOutput		
    MOVE.W  D4,D3		         *move opcode into D3
    CMP.B   #1,D5		         *is it a Long?
    BEQ     movemOutputMemToReg  *BRA if Long
    		
    ASR.W   #3,D3		         *isolate mode bits
    AND.W   #$0007,D3		     *mask mode bits
    CMP.B   #2,D3		         *if 2 BRA to getAnMode
    BEQ     getAnMode		
    CMP.B   #4,D3		         *if 4 BRA to getAnMode
    BEQ     getAnMode		
    CMP.B   #7,D3		         *is it 7?
    BNE     dataOpCode		     *if not 7 illegal addressing mode output as data
    MOVE.B  D4,D3		         *move opcode into D3
    AND.B   #$07,D3		         *check reg
    CMP.B   #1,D3		         *if greater than one output as data
    BGT     dataOpCode		
    BRA     getAnMode            *it checks out getAnMode		
    		
movemOutputMemToReg
    ASR.W   #3,D3                *isolate mode bits
    AND.W   #$0007,D3            *mask mode bits
    CMP.B   #2,D3                *check the addressing mode
    BEQ     getAnMode
    CMP.B   #3,D3                *check the addressing mode
    BEQ     getAnMode
    CMP.B   #7,D3                *check the addressing mode
    BNE     dataOpCode           *illegal addressing mode output data
    MOVE.B  D4,D3                *move opcode into D3
    AND.B   #$07,D3              *mask reg bits
    CMP.B   #1,D3                *check if greater than 1
    BGT     dataOpCode           *if greater than 1 it is illegal, output as data
    BRA     getAnMode            *it checks out go to getAnMode
    		
getAnMode		
    MOVE.B  D3,D2                *move reg bits into D2		
    		
movemWEA		
    CMP.B   #1,D6
    BEQ     displayMovemLong

displayMovemWord		
    LEA     outputMOVEMW,A1		
    MOVE.B  #14,D0		
    TRAP    #15
    BRA     regToMem

displayMovemLong
    LEA     outputMOVEML,A1		
    MOVE.B  #14,D0		
    TRAP    #15		
    
    
regToMem                        *Register to memory for MOVEM
    CLR.L   D3
    CLR.L   D2
    CLR.L   D1
    CLR.L   D6
    CLR.L   D7

    CMP.B   #0,D5               *Checks if it's a Memory to Register for MOVEM
    BNE     memToReg
    
    CLR.L   D5
    
    MOVE.W  (A5)+,D5            *Gets the register masks
    MOVE.W  #16,D6              *since there is 16 bits
    MOVE.B  #1,D2               *Start the counter
    
    MOVE.W D4,-(A7)             *saves it for the effective address later
    
    CLR.L   D4
    
    JSR     registerCheckerDn   *time to output the registers
    
    MOVE.W  (A7)+,D4            *bring the effective address 
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *go output the stack pointer
    
    BRA     DONE
    
  
registerCheckerDn               *checks the data registers first
    CMP.B   #9,D2
    BEQ     meepmeep            *once done checking data registers
                                *have to go check the address registers
    MOVE.W  D5,D3
    
    ROL.W   D2,D5               *sets the bit being checked to 0
    AND.L   #$FFFFFFFE,D5       *to know it has been checked
    ROR.W   D2,D5
    
    ROL.W   D2,D3               *gets the bit to be checked
    AND.L   #$00000001,D3
    ADD.B  #1,D2                *add to the counter
    
meowmeow                        *checks if there is a range or not
    CMP.B   #1,D3
    BEQ     regBitSet           *the bit has been set

    CMP.B   #0,D4
    BEQ     registerCheckerDn   *the one before was a zero

    BRA     registerOutput    *output stuff because there is a range
    
regBitSet                       *if a range has started
    CMP.B   #1,D4
    BNE   hamsters

checkSeven                      *There is a range
    MOVE.B  D2,D7
    
    BRA     registerCheckerDn
    
hamsters                        *start of a range or just a solo register
    MOVE.B  D2,D1               *sets the "start" of range
    
    MOVE.B  #1,D4               *sets D4 to one to indicate there is a range
    
    BRA     registerCheckerDn
    
registerOutput                  *outputs the registers
    LEA     outputDn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBQ.B  #2,D1               *have to set the number to proper register number
    MOVE.B  #3,D0
    TRAP    #15
    
    CMP.B   #1,D7               *check if have to output a range
    BGE     outputpart2
    
    LEA     outputSlash,A1
    MOVE.B  #14,D0
    TRAP    #15

    CLR.L   D4

    BRA     registerCheckerDn       *do it again
    
outputpart2                         *For outputting ranges
    LEA     outputNegSign,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputDn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBQ.B  #2,D7
    MOVE.L  D7,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputSlash,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    CLR.L   D4
    CLR.L   D7
    
    BRA     registerCheckerDn       *do it again
    
meepmeep                            *Checks the address registers
    CLR.L   D3
    CLR.L   D4
    CLR.L   D6
    CLR.L   D7
    CLR.L   D1
    
    
registerCheckAn
    CMP.B   #17,D2                  *sets the max
    BEQ     registerDone
    
    MOVE.W  D5,D3
    
    ROL.W   D2,D5
    AND.L   #$FFFFFFFE,D5
    ROR.W   D2,D5
    
    ROL.W   D2,D3
    AND.L   #$00000001,D3
    ADD.B   #1,D2
    
registerRangeAn
    CMP.B   #1,D3
    BEQ     regBitSetAn           *Do shit

    CMP.B   #0,D4
    BEQ     registerCheckAn   *the one before was a zero

    BRA     registerOutputAn    *output stuff because there is a range
    
regBitSetAn
    CMP.B   #1,D4
    BNE   hamstersAn

checkSevenAn                      *There is a range
    SUBQ.B  #8,D2
    MOVE.B  D2,D7
    ADD.B   #8,D2
    
    BRA     registerCheckAn
    
hamstersAn
    SUBQ.B  #8,D2
    MOVE.B  D2,D1               *sets the "start" of range
    ADD.B   #8,D2
    
    MOVE.B  #1,D4               *there was a one
    
    BRA     registerCheckAn
    
registerOutputAn
    LEA     outputAn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBQ.B  #2,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    CMP.B   #1,D7
    BGE     outputpart2An
        
    
displaySlash                    *displays slash or not
    CMP.W   #1,D5
    BLT     ignoreSlash
    
    LEA     outputSlash,A1
    MOVE.B  #14,D0
    TRAP    #15

ignoreSlash
    CLR.L   D4

    BRA     registerCheckAn  
    
outputpart2An
    LEA     outputNegSign,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputAn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBQ.B  #2,D7
    MOVE.L  D7,D1
    MOVE.B  #3,D0
    TRAP    #15
    
*displaySlash
    CMP.W   #1,D5
    BLT     ignoreSlashAn

    LEA     outputSlash,A1
    MOVE.B  #14,D0
    TRAP    #15
    
ignoreSlashAn    
    CLR.L   D4
    CLR.L   D7
    
    BRA     registerCheckAn
    
registerDone                    *all registers have been checked
    CMP.B   #1,D7
    BGE     registerOutputAn

    RTS
    
memToReg                        *It's a memory to register

    JSR     sourceEA            *outputs the stack pointer first
    
    CLR.L   D3
    CLR.L   D1
    CLR.L   D6
    CLR.L   D5
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  (A5)+,D5            *gets the register masks
    MOVE.W  #16,D6
    MOVE.B  #1,D2
    
    MOVE.W  D5,D6
    
    
mirrorShift                     *shifting the register masks to mimic the Register to Memory
    CMP.B   #15,D1
    BEQ     moveMContinue
    
    ADD.B   #1,D1
    
    ASR.W   #1,D6
    BCS     addBit
    
    BRA     zeroBit
    
addBit
    ADD.B   #1,D3
    ASL.W   #1,D3
    BRA     mirrorShift
    
zeroBit
    ASL.W   #1,D3
    BRA     mirrorShift 
    

moveMContinue               *continue with outputting registers

    MOVE.W  D3,D5
    CLR.L   D6
    CLR.L   D3
    CLR.L   D1
    
    MOVE.W  D4,-(A7)
    
    CLR.L   D4
    
    JSR     registerCheckerDn
    
    MOVE.W  (A7)+,D4   
     
    BRA DONE    		*done
    		    
leaOpCode
    CMP.B   #4,D5               *is it a possible LEA?
    BNE     oriOpCode           *check if ORI
    MOVE.W  D4,D3               *move opcode into D3
    ROL.W   #8,D3               *could be a NEG
    CMP.B   #$44,D3             *check if NEG
    BEQ     negMethod           *BRA to NEG method
    ROR.W   #8,D3               *ROR to get original opcode
    ROR.W   #7,D3               *isolate mode bits, they have to be 7
    AND.B   #7,D3               *mask the mode bits
    CMP.B   #7,D3               *is it a legal LEA?
    BNE     dataOpCode          *if not output as data
    
    MOVE.W  D4,D3               *move opcode into D3
    ROR.W   #3,D3               *isolate the mode bits
    AND.B   #7,D3               *mask them
    CMP.B   #2,D3               *check addressing mode
    BEQ     leaOutput
    
    CMP.B   #7,D3               *check addressing mode
    BEQ     leaOutput
    
    BRA     dataOpCode          *addressing mode illegal, output as data
    
leaOutput    
    LEA     outputLEA,A1        *output LEA
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *get the source EA
    
    LEA     outputComma,A1      *comma
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addaDestEA          *get deref address reg
    
    BRA     DONE                *we are done
    
oriOpCode                       *ORI opcode
    CMP.B   #0,D5               
    BNE     moveByteOpCode      *if not, go to next opcode
      
    MOVE.W  D4,D2               *Checks if it really is a ORI or some other opcode 
    ROL.W   #8,D2
    AND.L   #$0000000F,D2
    
    MOVE.L  D2,D5
    
oriMethod                       *it's an ORI
    CMP.B   #0,D5
    BNE     cmpiOpCode
    
    LEA     outputORI,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode           *check if it's a byte/word/long
        
    MOVE.L  #7,D2               *source is always an immediate
    MOVE.L  #4,D3
    JSR     immediateData
    
    LEA     outputComma,A1  
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *checks what the destination is
    BRA     DONE

cmpiOpCode                      *if it's not ORI then check if it's CMPI
    CMP.B   #12,D5
    BNE     bclrOpCode          *if it's not, then it's a BCLR
    
cmpiMethod                      
    LEA     outputCMPI,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode
    
    MOVE.L  #7,D2
    MOVE.L  #4,D3
    JSR     immediateData
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    BRA     DONE
    
bclrOpCode
    LEA     outputBCLR,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  #10,D1
    MOVE.L  D4,D5
    ROL.W   D1,D5
    AND.L   #$00000007,D5
    
    CMP.B   #2,D5
    BEQ     bclrImmediate
    
    MOVE.L  #0,D2
    MOVE.L  D4,D3
    ROL.W   #7,D3
    AND.L   #$00000007,D3
    
    JSR     DnMode
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE
        
bclrImmediate
    
    MOVE.L  #7,D2
    MOVE.L  #4,D3
    
    JSR     immediateData
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE    
    
moveByteOpCode                  *MOVE.B opcode
    CMP.B   #1,D5
    BNE     moveWordOpCode 

moveByteMethod                  *MOVE.B output
    LEA     outputMOVE,A1       *Outputs "MOVE" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputByte,A1       *Outputs ".B" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *Jump to subroutine sourceEA
    
    LEA     outputComma,A1      *Outputs a comma onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     moveDestinationEA   *Jump to subroutine moveDestinationEA
    
    BRA     DONE                *Yay done
    

moveWordOpCode                  *MOVE.W opcode
    CMP.B   #3,D5
    BNE     moveLongOpCode
   
moveWordMethod                  *MOVE.W output
    MOVE.W  D4,D2               *D4 has the original word
    MOVE.W  #10,D1              *Move the value 10 into D1 since ROL has issues with
    ROL.W   D1,D2               *   immediate values > 8
    
    CMP.W   #1,D2               *If the rotated value is a 1, it's a MOVEA.W
    BEQ     moveAWordMethod    
    
    LEA     outputMOVE,A1       *Outputs "MOVE." onto console
    MOVE.B  #14,D0
    TRAP    #15
    BRA     moveWordMethodpt2   *Go to the rest of the method~
    
moveAWordMethod                 *MOVEA.W opcode
    LEA     outputMOVEA,A1      *Outputs "MOVEA" onto console
    MOVE.B  #14,D0
    TRAP    #15
    BRA     moveWordMethodpt2   *Go to the rest of the method~
    
moveWordMethodpt2               *Part 2 of the MOVE/MOVEA.W series
    LEA     outputWord,A1       *Outputs ".W" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *Yay subroutines
    
    LEA     outputComma,A1      *outputs a comma onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     moveDestinationEA   *Gotta check the destination~

    BRA     DONE                *I'm done, bra

moveLongOpCode                  *MOVE.L opcode
    CMP.B   #2,D5
    BNE     addOpCode
    
moveLongOpCodeMethod            *MOVE.L output
    MOVE.W  A2,D2               *Gotta check if it's actually a MOVEA
    MOVE.W  #10,D1
    ROL.W   D1,D2
    
    CMP.W   #1,D2
    BEQ     moveALongMethod   

    LEA     outputMOVE,A1       *outputs "MOVE" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     moveLongMethodpt2   *Go to Part 2 of the MOVE series~
    
moveALongMethod                 *MOVEA.L output
    LEA     outputMOVEA,A1      *Outputs "MOVEA" onto console
    MOVE.B  #14,D0
    TRAP    #15
    BRA     moveLongMethodpt2   *Go to part 2~
    
moveLongMethodpt2               *Part 2, the sequel(SQL?)
    
    LEA     outputLong,A1       *Outputs ".L" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    ADD.B   #1,D7
    
    JSR     sourceEA            *Go output source
    
    LEA     outputComma,A1      *Yay commas
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     moveDestinationEA    *Output destination
    BRA     DONE

addOpCode                        *ADD opcode
    CMP.B   #13,D5
    BNE     subOpCode    
    
addMethod                        *ADD output
    LEA     outputADD,A1         *Outputs "ADD" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode           *Checks if it's a byte,word, or long
    
    CMP.B   #1,D6               *If D6 == 1, the data register is the source
    BEQ     altOrder            *   D6 was decided in dotOpMode(?)
    
    CMP.B   #2,D6
    BEQ     addaOrder           *go do ADDA stuff
    
    JSR     sourceEA            *outputs what the source is
    
    LEA     outputComma,A1      *Commas~~~
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addDestinationEA       *outputs what the destination is
    
    BRA     DONE
    
subOpCode
    CMP.B   #9,D5               *is it SUB?
    BNE     subQOpCode          *not SUB, check if SUBQ

subMethod
    MOVE.W  D4,D3               *move opcode into D3
    ASR.W   #6,D3               *isolate the opmode
    AND.B   #7,D3               *mask the opmode
    CMP.B   #3,D3               *illegal opMode
    BEQ     dataOpCode
    CMP.B   #7,D3               *illegal opMode
    BEQ     dataOpCode
    CMP.B   #2,D3               *legal opMode
    BLE     subAddressingModePart1
    BRA     subAddressingModePart2
    
    
subAddressingModePart1          *000 001 010 opModes    
    MOVE.W  D4,D3               *move opcode into D3
    ASR.W   #3,D3               *isolate the mode bits
    AND.B   #7,D3               *mask the mode bits
    CMP.B   #4,D3               *mode 4 or less is legal addressing mode
    BLE     outputSubMethod     *addressing mode is legal output SUB
    CMP.B   #7,D3               *7 is legal as well
    BEQ     subCheckLabelMode   *output SUB
    BRA     dataOpCode          *addressing mode is illegal, output as data

subAddressingModePart2          *100 101 110 opModes
    MOVE.W  D4,D3               *move opcode into D3
    ASR.W   #3,D3               *isolate Mode bits
    AND.B   #7,D3               *mask Mode bits
    CMP.B   #2,D3               *is legal
    BEQ     outputSubMethod
    CMP.B   #3,D3               *is legal
    BEQ     outputSubMethod
    CMP.B   #4,D3               *is legal
    BEQ     outputSubMethod
    CMP.B   #7,D3               *is legal but needs additional check for REG
    BEQ     subCheckLabelMode2
    BRA     dataOpCode          *illegal output as data
    
subCheckLabelMode               *000 001 010 opModes
    MOVE.B  D4,D3               *move opcode into D3
    AND.B   #7,D3               *mask REG bits
    CMP.B   #1,D3               *is legal
    BLE     outputSubMethod
    CMP.B   #4,D3               *is legal
    BEQ     outputSubMethod
    BRA     dataOpCode          *illegal output as data
    
subCheckLabelMode2              *100 101 110 opModes    
    MOVE.B  D4,D3               *move opcode into D3
    AND.B   #7,D3               *mask REG bits
    CMP.B   #1,D3               *is legal
    BLE     outputSubMethod
    BRA     dataOpCode          *illegal output as data
    
outputSubMethod
    LEA     outputSUB,A1        *output SUB to the console
    MOVE.B  #14,D0  
    TRAP    #15

    JSR     dotOpMode           *check if its a B,W, or L

    CMP.B   #1,D6               *if D6 == 1, the data register is the source
    BEQ     altOrder

    JSR     sourceEA            *outputs what the source is

    LEA     outputComma,A1      *commas
    MOVE.B  #14,D0
    TRAP    #15

    JSR     addDestinationEA    *outputs what ths destination is

    BRA     DONE                

subQOpCode
    CMP.B   #5,D5               *is it SUBQ?
    BNE     orOpCode            *check if its DIVS.W
    
subQMethod
    
    MOVE.B  D4,D5               *move opcode into D5
    ROL.B   #2,D5               *isolate size bits
    AND.B   #3,D5               *mask size bits
    CMP.B   #3,D5               *invalid size
    BEQ     dataOpCode          *output as data if size == 3
    
    MOVE.W  D4,D3               *move opcode into D3
    ASR.B   #3,D3               *isolate addressing mode
    AND.B   #7,D3               *mask addressing bits
    MOVE.B  D3,D5
    CMP.B   #4,D5               *if 4 or less addressing mode is legal
    BLE     outputSubqMethod
    CMP.B   #7,D5               *7 is legal too
    BEQ     subqLabelAddresingCheck
    BRA     dataOpCode          *not legal addressing mode output as data
    
subqLabelAddresingCheck
    MOVE.B  D4,D3               *move opcode into D3
    AND.B   #7,D3               *mask Reg bits
    CMP.B   #1,D3               *if equal or less than one it is legal
    BLE     outputSubqMethod
    BRA     dataOpCode          *data otherwise
    
outputSubqMethod
    LEA     outputSUBQ,A1       *output SUBQ
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  D4,D3               *move original word from D4
    MOVE.B  #10,D1              *hacks
    ROL.W   D1,D3               *ROL by 10
    AND.L   #00000003,D3        *Mask 
    CMP.B   #0,D3               *if size is B, can't have An as Dest
    BEQ     subqAddressingCheck

subqByteMode    
    JSR     byteOpMode          *check if B,W,L
    
    JSR     subQData            *outputs #1-#8
    
    LEA     outputComma,A1      *commas
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *get the source
    
    BRA     DONE
    
subqAddressingCheck
    CMP.B   #1,D5               *Check for An dest
    BEQ     dataOpCode
    CMP.B   #2,D5
    BEQ     dataOpCode
    CMP.B   #3,D5
    BEQ     dataOpCode
    BRA     subqByteMode        *addressing mode checks out
            
subQData
    MOVE.W  D4,D3               *move original word from D4
    ROL.W   #7,D3               *ROL 7
    AND.L   #$00000007,D3       *mask the bits
    
    CMP.B   #0,D3               *if its 0 display 8
    BEQ     display8ForSubQ
    
    CMP.B   #8,D3
    BGE     dataOpCode
    
    LEA     outputPound,A1      *output #
    MOVE.B  #14,D0
    TRAP    #15
    
    CLR.L   D1
    MOVE.B  D3,D1               *output 1-7
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS                         *return to subQmethod
    
display8ForSubQ

    LEA     outputPound,A1      *output #
    MOVE.B  #14,D0
    TRAP    #15
    CLR.L   D1
    MOVE.B  #8,D1               *output 8
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS                         *return to subQMethod

orOpCode
    CMP.B   #8,D5   
    BNE     eorOpCode
    
    MOVE.L  D4,D5
    MOVE.L  #10,D1
    ROL.W   D1,D5
    
    AND.L   #$00000007,D5
    
    CMP.B   #7,D5
    BEQ     divsWOpCode
    
orMethod
    LEA     outputOR,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode
    
    CMP.B   #1,D6
    BEQ     altOrder
    
    JSR     sourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addDestinationEA
    
    BRA     DONE
    
divsWOpCode    
divsWCheck
    MOVE.W  D4,D3
    MOVE.B  #10,D2
    ROL.W   D2,D3
    AND.L   #$00000007,D3
    CMP.B   #7,D3
    BNE     DONE
    
    LEA     outputDIVSW,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA 
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addDestinationEA
    
    BRA     DONE
    
eorOpCode
    CMP.B   #11,D5
    BNE     shiftsOpCode
    
    MOVE.L  D4,D5
    ROL.W   #8,D5
    AND.L   #$00000001,D5
    
    
eorMethod
    CMP.B   #1,D5
    BNE     cmpOpCode
    
    LEA     outputEOR,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode
    
    JSR     addDestinationEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE    

cmpOpCode
    CMP.B   #0,D5
    BNE     DONE
    
    LEA     outputCMP,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     dotOpMode
    
    JSR     sourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addDestinationEA
    
    BRA     DONE
   
shiftsOpCode
    CMP.B   #14,D5
    BNE     mulsOpCode
    
shiftMemoryShift
    MOVE.L  D4,D5
    ROR.W   #6,D5
    AND.L   #$00000003,D5
    
    CMP.B   #3,D5
    BNE     shiftRegisterShift
    
    MOVE.L  D4,D5
    ROL.W   #7,D5
    AND.L   #$00000003,D5
    
memoryLSD
    CMP.B   #1,D5
    BNE     memoryASD
    
    LEA     outputLS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    LEA     outputWord,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE
    
memoryASD
    CMP.B   #0,D5
    BNE     memoryROD
    
    LEA     outputAS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    LEA     outputWord,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE
    
memoryROD
    CMP.B   #3,D5
    BNE     dataOpCode
    
    LEA     outputRO,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    LEA     outputWord,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    
    BRA     DONE
    
    
    
shiftRegisterShift
    MOVE.L  D4,D5
    ROR.W   #3,D5
    AND.L   #$00000003,D5
    
lsdOpCode
    CMP.B   #1,D5
    BNE     asdOpCode
    
lsdMethod
    LEA     outputLS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    JSR     dotOpMode
    
    JSR     shiftSourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     shiftDestEA
    
    BRA     DONE
 
asdOpCode
    CMP.B   #0,D5
    BNE     rodOpCode
    
    LEA     outputAS,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    JSR     dotOpMode
    
    JSR     shiftSourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     shiftDestEA    
    
    BRA     DONE
    
rodOpCode
    CMP.B   #3,D5
    BNE     DONE
    
    LEA     outputRO,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     leftRight
    
    JSR     dotOpMode
    
    JSR     shiftSourceEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     shiftDestEA
    
    BRA     DONE
    
leftRight
    MOVE.L  D4,D3
    ROL.W   #8,D3
    AND.L   #$00000001,D3

    CMP.B   #0,D3
    BEQ     rightRight
    
    LEA     outputLeft,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
rightRight
    LEA     outputRight,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
shiftSourceEA
    MOVE.L  D4,D2
    ROR.W   #5,D2
    AND.L   #$00000001,D2

    MOVE.L  D4,D3
    ROL.W   #7,D3
    AND.L   #$00000007,D3
    
    CMP.B   #0,D2
    BEQ     shiftImmediateEA
    
    LEA     outputDn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS
    
shiftImmediateEA
    LEA     outputPound,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    CMP.B   #0,D3
    BEQ     shiftImmediateEight
    
    MOVE.L  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS
    
shiftImmediateEight
    MOVE.L  #8,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS
    
shiftDestEA
    MOVE.L  D4,D3
    AND.L   #$00000007,D3
    
    LEA     outputDn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS
    
mulsOpCode
    CMP.B   #12,D5              *is it MULS
    BNE     negOpCode           *check if its a NEG
    MOVE.W  D4,D3               *move opcode into D3
    ROR.W   #6,D3               *check bits 6-8, they need to be 7 
    AND.B   #7,D3               *to be MULS
    CMP.B   #7,D3
    BNE     dataOpCode          *if not 7 illegal opcode output data

mulsMethod
    MOVE.W  D4,D3               *move opcode into D3
    ROR.B   #3,D3               *isolate mode bits
    AND.B   #7,D3               *mask the mode bits
    CMP.B   #1,D3               *An illegal addressing mode 
    BEQ     dataOpCode          *output as data
    
mulsOutput    
    LEA     outputMULS,A1       *output MULS
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA            *get the source EA
    
    LEA     outputComma,A1      *comma
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addDestinationEA    *get dest EA
    
    BRA     DONE                *we are done
    
negOpCode
    MOVE.W  D4,D3               *move opcode into D3
    ROL.W   #8,D3               *isolate high order word
    CMP.B   #$44,D3             *is it a NEG?
    BNE     braOpCode           *check if BRA
    
    
negMethod
    LEA     outputNEG,A1        *output NEG to the console
    MOVE.B  #14,D0
    TRAP    #15
    
    CLR.L   D3
    MOVE.W  D4,D3               *move original word from D4
    ROR.W   #6,D3               *ROL by 10
    AND.W   #$0003,D3           *Mask
    CMP.B   #3,D3               *if 3 or greater, not supported mode
    BGE     dataOpCode          *output as data
    JSR     byteOpMode          *check if B,W,L
        
    JSR     sourceEA            *get the source EA
    
    BRA     DONE                *we are done

braOpCode
    MOVE.W  D4,D3               *move the opcode word into D3
    ROL.W   #8,D3               *isolate the last byte
    CMP.B   #$60,D3             *is it a BRA?
    BNE     bccOpCode           *its data then
    
braMethod
    LEA     outputBRA,A1        *output BRA
    MOVE.B  #14,D0
    TRAP    #15

bccDisplacement    
    MOVE.B  D4,D3               *move opcode into D3
    AND.W   #$00FF,D3           *mask displacement
    CMP.B   #$00,D3             *if 00 it is a 16 bit disp
    BEQ     bitDisplacement16   *16 bit disp subr
    CMP.B   #$FF,D3             *if its FF it is 32 bit subr
    BEQ     bitDisplacement32   *32 bit disp subr
    ROL.B   #8,D3               *time for two's compliment!
    EOR.W   #$FF,D3             *flip it
    ADD.W   #1,D3               *add 1
    
    LEA     outputNegSign,A1    *output -
    MOVE.B  #14,D0  
    TRAP    #15
    
    MOVE.W  D3,D1               *move displacement into D1
    MOVE.B  #3,D0               *output displacement
    TRAP    #15
    
    LEA     outputSpace,A1      *output space
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  A5,A0               *make A0 point at current addr
    SUBA.W  D3,A0               *subtract displacement from A0
    MOVE.W  A0,D1               *output HEX at A0
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVE.W  A4,A0               *clear A0
    
    
    BRA     DONE                *we are done
   
bitDisplacement16
    
    MOVE.W  A5,A0               *have A0 point to current addr
    MOVE.W  (A5)+,D4            *move what is in A5 into D4 incre by a W
    MOVE.W  D4,D3               *move displacement into D3
    ROL.W   #4,D3               *check to see if most sig bit is a 1
    AND.W   #$000F,D3           *if it is it is a negative number
    CMP.W   #8,D3               *is it negative?
    BGE     negBit16
    
    MOVE.W  D4,D1               *move displacement into D1
    MOVE.B  #3,D0               *output displacement
    TRAP    #15
    
    LEA     outputSpace,A1      *space
    MOVE.B  #14,D0
    TRAP    #15
    
    ADDA.W  D4,A0               *add displacement to A0
    MOVE.W  A0,D1               *output addr
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVE.W  A4,A0               *clear A0
    
    BRA DONE                    *we are done
    
negBit16

    EOR.W   #$FFFF,D4           *flip the bits
    ADD.W   #1,D4               *add 1
    
    LEA     outputNegSign,A1    *output neg sign
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  D4,D1               *move displacement into D1
    MOVE.B  #3,D0               *output displacement
    TRAP    #15
    
    LEA     outputSpace,A1      *space
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBA.W  D4,A0               *subtract displacement from addr
    MOVE.W  A0,D1               *output addr to bra to
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVE.W  A4,A0               *clear A0
    
    BRA     DONE                *we are done
    
bitDisplacement32

    MOVE.L  A5,A0               *A0 points to current addr
    MOVE.L  (A5)+,D4            *move displacment of A5 into D4 and increment
    MOVE.L  D4,D3               *move displacement into D3
    ROL.W   #4,D3               *is it negative?
    AND.L   #$0000000F,D3       *mask most sig bits
    CMP.L   #8,D3               *is it 1?
    BGE     negBit32            *its negative displacement
    
    MOVE.L  D4,D1               *move displacement into D1
    MOVE.B  #3,D0               *output displacement
    TRAP    #15
    
    LEA     outputSpace,A1      *space
    MOVE.B  #14,D0
    TRAP    #15
    
    ADDA.L  D4,A0               *add displacement to addr
    MOVE.L  A0,D1               *ouput HEX addr to BRA to
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVE.L  A4,A0               *clear A0
    
    BRA DONE                    *we are done

negBit32

    EOR.L   #$FFFFFFFF,D4       *flip the bits
    ADD.L   #1,D4               *add 1
    
    LEA     outputNegSign,A1    *output negative sign
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  D4,D1               *move displacement into D1
    MOVE.B  #3,D0               *output displacement
    TRAP    #15
    
    LEA     outputSpace,A1      *space
    MOVE.B  #14,D0
    TRAP    #15
    
    SUBA.L  D4,A0               *subtract displacement from addr
    MOVE.L  A0,D1               *move addr into D1
    MOVE.B  #15,D0              *output HEX addr of BRA
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVE.L  A4,A0               *clear A0
    
    BRA     DONE                *we are done
    
bccOpCode
    CMP.B   #6,D5               *is it Bcc?
    BNE     dataOpCode          *its data then
    
bccMethod
    MOVE.W  D4,D3               *move opcode into D3
    ROL.W   #8,D3               *find out what Bcc it is
    AND.W   #$000F,D3           *mask the bits
    CMP.B   #5,D3               *is it a BCS?
    BEQ     bcs                 
    CMP.B   #$C,D3              *is it BGE?
    BEQ     bge
    CMP.B   #$D,D3              *is it BCT?
    BEQ     bct
    BRA     bvc                 *process of elimination BVC wins
    
bcs
    LEA     outputBCS,A1        *outputBCS
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     bccDisplacement     *take care of the displacement
    
bge
    LEA     outputBGE,A1        *output BGE
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     bccDisplacement     *take care of the displacement

bct
    LEA     outputBCT,A1        *output BCT
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     bccDisplacement     *take care of the displacement
    
bvc
    LEA     outputBVC,A1        *output BVC
    MOVE.B  #14,D0
    TRAP    #15
    
    BRA     bccDisplacement     *check displacement
    

           
dataOpCode
    CLR.L   D3                  *I dont remember
    LEA     outputData,A1       *output data
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVEA.L A5,A0
    MOVE.W  -(A0),D1             *output opcode that isn't recognized
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    MOVEA.L A4,A0               *clear A0
    
    BRA     DONE                * we are done


altOrder                            *outputs the Dn as the source for ADD
    JSR     addDestinationEA
    
    LEA     outputComma,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     sourceEA
    BRA     DONE
    
addaOrder                           *ADDA method
    JSR     sourceEA                *output source first
    
    LEA     outputComma,A1          *Comma
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     addaDestEA              *Have to set destination mode in addaDestEA
    BRA     DONE


dotOpMode                           *Checks if it's a Byte,Word, or Long for ADD and SUB
    MOVE.W  D4,D3                   *Gets the original code from D4                 
    MOVE.B  #10,D2                  *yay hacks
    
    ROL.W   D2,D3                   *Rotates the original left by 10 bits
    AND.L   #$00000007,D3           *mask it up
    
    CMP.B   #3,D3                   
    BGE     altOpMode               *if value is > 3, Dn is the source
    
    BRA     byteOpMode    

altOpMode                           *But wait, there's more!
    CMP.B   #3,D3                   *If it's 3, it's an ADDA.W
    BEQ     addaWOpMode
    
    CMP.B   #7,D3                   *If it's a 7, it's an ADDA.L
    BEQ     addaLOpMode             *Otherwise, it's just ADD with Dn in source
    
    MOVE.B  #1,D6                   *D6 is 1 if Dn is the source
    AND.B   #$3,D3                  *Mask it so it can continue with the output
    BRA     byteOpMode              *without the meddling 2^2 bit

addaWOpMode                         *It's an ADDA.W
    MOVE.W  #2,D6
    
    LEA     outputADDA,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputWord,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
addaLOpMode                         *It's an ADDA.L
    MOVE.W  #2,D6
    
    ADD.B   #1,D7
    
    LEA     outputADDA,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputLong,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
    
byteOpMode                          *It's a byte?
    CMP.B   #0,D3
    BNE     wordOpMode
    
    LEA     outputByte,A1           *Output ".B" !
    MOVE.B  #14,D0
    TRAP    #15
    RTS                             *Time to return back in time
    
wordOpMode                          *It's a word?
    CMP.B   #1,D3
    BNE     longOpMode
    
    LEA     outputWord,A1           *Output ".W" onto console
    MOVE.B  #14,D0
    TRAP    #15
    RTS                             *Time warp~
    
longOpMode                          *It better be a long then
    LEA     outputLong,A1           *outputs ".L" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    ADD.B   #1,D7
   
    RTS                             *whoosh~
 
    
sourceEA                            *output the Source EA
    MOVE.W  D4,D3                   *Put the original opcode into D3
    MOVE.W  D3,D2                   *Copy that into D2
    
    ROR.W   #3,D2                   *Whoo~ Rotating~
    AND.L   #$00000007,D2           *D2 has Mode
    

    AND.L   #$00000007,D3           *D3 has Register

 
DnMode                          *Is the Mode a Data Register?
    CLR.L   D1
    
    CMP.B   #0,D2
    BNE     AnMode
    
    LEA     outputDn,A1         *outputs "D" onto console
    MOVE.B  #14,D0
    TRAP    #15

    MOVE.B  D3,D1               *outputs the register, whatever the numeric value is
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS                         *wooo~
  
AnMode                          *Mode is an Address Register?
    CMP.B   #1,D2
    BNE     deRefAnMode
    
    LEA     outputAn,A1         *Outputs "A" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  D3,D1               *Outputs the register value
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS                         *psssh
    
deRefAnMode                     *Mode is a (A0)?
    CMP.B   #2,D2               
    BNE     postIncrementAnMode
    
    LEA     outputdeRefAn1,A1   *Outputs "(A" onto console
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  D3,D1               *outputs register value
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputdeRefAn2,A1   *makes it pretty by outputting ")"
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS                         *=-=
    
postIncrementAnMode
    CMP.B   #3,D2
    BNE     preDecrementAnMode
    
    LEA     outputdeRefAn1,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputPostIncrementAn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
preDecrementAnMode
    CMP.B   #4,D2
    BNE     immediateData
    
    LEA     outputPreDecrementAn,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     outputdeRefAn1,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  D3,D1
    MOVE.B  #3,D0
    TRAP    #15
    
    LEA     outputdeRefAn2,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS
    
immediateData                   *Mode is an #<data>
    CMP.B   #7,D2               *Mode for #<data> is 111
    BNE     xxxWord
    
    CMP.B   #4,D3               *Register for #<data> is 100
    BNE     xxxWord
                               
    LEA     outputPound,A1      *Outputs "#"
    MOVE.B  #14,D0
    TRAP    #15   
    
    CMP.B   #1,D7
    BEQ     immeDataLong
    
    MOVE.W  (A5)+,D3
    
    BRA     immediateDatapt2

immeDataLong
    MOVE.L  (A5)+,D3    
        
immediateDatapt2               *Outputs register value
    MOVE.L  D3,D1
    MOVE.B  #3,D0
    TRAP    #15

    RTS                         *~owo~
    
xxxWord
    CMP.B   #7,D2
    BNE     xxxLong
    
    CMP.B   #0,D3
    BNE     xxxLong
    
    LEA     outputAddr,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  (A5)+,D1
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    RTS
    
xxxLong
    CMP.B   #7,D2
    BNE     DONE
    
    CMP.B   #1,D3
    BNE     DONE
    
    LEA     outputAddr,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  (A5)+,D1
    MOVE.B  #15,D0
    MOVE.B  #16,D2
    TRAP    #15
    
    RTS
    

addDestinationEA                *Since ADD only has data register in dest area
    MOVE.W  D4,D3
    
    MOVE.W  D3,D2
    
    MOVE.L  #10,D1
    ROL.W   D1,D2
    AND.L   #$00000007,D2       *D2 has mode
    
    
    ROL.W   #7,D3
    AND.L   #$00000007,D3       *D3 has register
    
DnRegister                      *For ADD only, since it only has Dn 
    LEA     outputDn,A1         *outputs "D"
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  D3,D1               *Outputs register value
    MOVE.B  #3,D0
    TRAP    #15
    
    RTS

moveDestinationEA               *Destination output for MOVE
    MOVE.W  D4,D3
    MOVE.W  D3,D2
    
    ROL.W   #7,D3
    AND.L   #$00000007,D3       *D3 has Register
    
    MOVE.W  #10,D1      
    ROL.W   D1,D2               *D2 has Mode
    AND.L   #$00000007,D2
    
    BRA     DnMode              *output what it is, bra
    
addaDestEA                      *Sets up the dest mode to be proper
    MOVE.W  D4,D3               *Get the original code again
    MOVE.W  D3,D2
    
    ROL.W   #7,D3               
    AND.L   #$00000007,D3       *D3 has register
    
    MOVE.W  #10,D1
    ROL.W   D1,D2               *Have to AND it by 1, since the mode for ADDA
    AND.L   #$00000001,D2       *is always an Address
    
    BRA     DnMode
    
pageContinue
    LEA     outputContinue,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  #5,D0
    TRAP    #15
    MOVE.B  #line_count,(A3)
    JMP     getOpCode
    
DONE
    CMP.W   A5,A6
    BLT     END   
    LEA     outputNextLine,A1
    MOVE.B  #14,D0
    TRAP    #15 
    JMP     getOpCode
    
END
    LEA     outputNextLine,A1
    MOVE.B  #14,D0
    TRAP    #15

    LEA     outputEnd,A1
    MOVE.B  #14,D0
    TRAP    #15
    SIMHALT             ; halt simulator

* Put variables and constants here

code        DC.W    $43D2


addCode     DC.W    $D640

moveCode1   DC.W    $303C
moveCode2   DC.W    $0011

outputADD   DC.B    'ADD',0
outputADDA  DC.B    'A',0
outputSUB   DC.B    'SUB',0
outputSUBQ  DC.B    'SUBQ',0
outputMOVE  DC.B    'MOVE',0
outputMOVEA DC.B    'MOVEA',0
outputMOVEMW DC.B   'MOVEM.W ',0
outputMOVEML DC.B   'MOVEM.L ',0
outputMULS  DC.B    'MULS ',0
outputDIVSW DC.B    'DIVS.W ',0
outputNOP   DC.B    'NOP ',0
outputJSR   DC.B    'JSR ',0
outputRTS   DC.B    'RTS ',0
outputLEA   DC.B    'LEA ',0
outputData  DC.B    'DATA ',0
outputNEG   DC.B    'NEG',0
outputBRA   DC.B    'BRA ',0
outputORI   DC.B    'ORI',0
outputOR    DC.B    'OR',0
outputEOR   DC.B    'EOR',0
outputCMPI  DC.B    'CMPI',0
outputCMP   DC.B    'CMP',0
outputBCLR  DC.B    'BCLR ',0
outputLS    DC.B    'LS',0
outputAS    DC.B    'AS',0
outputRO    DC.B    'RO',0
outputLeft  DC.B    'L',0
outputRight DC.B    'R',0

outputBCS   DC.B    'BCS ',0
outputBGE   DC.B    'BGE ',0
outputBCT   DC.B    'BCT ',0
outputBVC   DC.B    'BVC ',0

outputByte  DC.B    '.B ',0
outputWord  DC.B    '.W ',0
outputLong  DC.B    '.L ',0

outputdeRefAn1   DC.B    '(A',0
outputdeRefAn2   DC.B    ')',0
outputPostIncrementAn   DC.B    ')+',0
outputPreDecrementAn    DC.B    '-',0

outputAn    DC.B    'A',0
outputDn    DC.B    'D',0
outputPound DC.B    '#',0
outputAddr  DC.B    '   $',0
outputCurrentAddr   DC.W    $0000
outputSlash DC.B    '/',0

outputComma     DC.B    ',',0
outputDot       DC.B    '.',0
outputNextLine  DC.B    ' ',CR,LF,0
outputSpace     DC.B    ' ',0
outputColon     DC.B    ': ',0
outputNegSign   DC.B    '-',0
outputStart     DC.B    'Disassembling Initiated',0
outputEnd       DC.B    'Program Disassembled',0
outputContinue  DC.B    'Press ENTER key to continue disassembling',CR,LF,0
    END    $1000        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
