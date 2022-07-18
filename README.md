# RISC-V_Binary_To_ARM_Binary

Hello,

This github repository contains the project I worked on called "RISC-V Binary To ARM Binary".

Project Information:-

arm-alu.s


A binary translator from RISC-V to ARM for a subset of RISC-V assembly instructions.
The subset implemented in this program is not Turing complete because it only consists
of arithmetic and logic operators. The next program (arm.s) is translating conditional 
operators with two programs togeather we get a Turing-complete set of operators and could
as such, theoretically, compute anything with that subset.

The following are all of the RISC-V instructions that are handled in arm-alu.s binary translator.
Additional constraints are put on some instructions to ensure simple translation to ARM instructions.
In the encoding, s specifies a source register, t a target register, d a destination register and i an immediate value.
<pre>
Instruction         Encoding	                                Type

ANDI    d, s, imm   iiii iiii iiii ssss s111 dddd d001 0011	  I
AND     d, s, t     0000 000t tttt ssss s111 dddd d011 0011       R
ORI     d, s, imm   iiii iiii iiii ssss s110 dddd d001 0011       I
OR      d, s, t     0000 000t tttt ssss s110 dddd d011 0011    	  R
ADDI    d, s, imm   iiii iiii iiii ssss s000 dddd d001 0011       I
ADD     d, s, t     0000 000t tttt ssss s000 dddd d011 0011       R
SUB     d, s, t     0100 000t tttt ssss s000 dddd d011 0011       R
SRAI    d, s, imm   0100 000i iiii ssss s101 dddd d001 0011       I
SRLI    d, s, imm   0000 000i iiii ssss s101 dddd d001 0011       I
SLLI    d, s, imm   0000 000i iiii ssss s001 dddd d001 0011       I
SRA     d, s, t     0100 000t tttt ssss s101 dddd d011 0011       R
SRL     d, s, t     0000 000t tttt ssss s101 dddd d011 0011       R
SLL     d, s, t     0000 000t tttt ssss s001 dddd d011 0011       R
</pre>

RISC-V destination registers were encoded as Rds in ARM. For all instructions but shifts,
translated source and target registers were encoded as Rn and Rm respectively.

For shift instructions, the source register were encoded as Rm and the target register 
were encoded within the Shift field as described above.

arm.s


This program is to translate RISC-V's branches and unconditional jump instructions,
while utilizing the translateALU function, imported from arm_alu.s, to translsate ALU instructions.


The following are all of the new RISC-V instructions that this program translates. In the encoding,
s specifies a source register, t a target register, d a destination register and i an immediate value.


<pre>

Instruction           Encoding                                              Type
JALR    d, imm(s)     iiii iiii iiii ssss s000 dddd d110 0111                 I
BEQ     s, t, offset  imm[12|10:5]t tttt ssss s000 imm[4:1|11]110 0011        SB
BGE     s, t, offset  imm[12|10:5]t tttt ssss s101 imm[4:1|11]110 0011        SB
</pre>

