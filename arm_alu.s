#
# CMPUT 229 Student Submission License
# Version 1.0
#
# Copyright 2021 <Revanth Atmakuri>
#
# Redistribution is forbidden in all circumstances. Use of this
# software without explicit authorization from the author or CMPUT 229
# Teaching Staff is prohibited.
#
# This software was produced as a solution for an assignment in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. This solution is confidential and remains confidential 
# after it is submitted for grading.
#
# Copying any part of this solution without including this copyright notice
# is illegal.
#
# If any portion of this software is included in a solution submitted for
# grading at an educational institution, the submitter will be subject to
# the sanctions for plagiarism at that institution.
#
# If this software is found in any public website or public repository, the
# person finding it is kindly requested to immediately report, including 
# the URL or other repository locating information, to the following email
# address:
#
#          cmput229@ualberta.ca

.include "common.s"

#----------------------------------------------------------------
# This function translates RISC-V code that is stored in memory 
# at address found in a0 into ARM code and stores that ARM code
# into the memory address found in a1
#
# Arguments:
#	* a0: pointer to memory containing a RISC-V function.
#	  The end of the RISC-V instructions is marked by
#         the sentinel word 0xFFFFFFFF.
#	* a1: a pointer to pre-allocated memory where you will
#	  have to write ARM instructions.
# Return Values:
#	* a0: number of bytes that the instructions generated
#	  by RISCVtoARM_ALU occupy.
#-----------------------------------------------------------------
RISCVtoARM_ALU:

	# Preparing stack to store registers
	addi	sp, sp, -24	# Moving Stack Pointer by 6 Words or 24 Bytes
	sw	ra, 0(sp)
	sw	s0, 4(sp)	# To store the pointer to memroy containing a RISC-V Function
	sw	s1, 8(sp)	# To store the pointer to pre-allocated memory to write arm instructions
	sw	s2, 12(sp)	# To count the number of bytes written to pre-allocated memory
	sw	s3, 16(sp)	# To store the sentinal word
	sw	s4, 20(sp)	# To use as Temporary register who's value is needed after a function call
	
	mv	s0, a0		# Storing the pointer to memory containing a RISC-V Fucntion
	mv	s1, a1		# Storing the pointer to pre-allocated memory to write arm instructions
	add	s2, zero, zero	# To count the number of bytes written to pre-allocated memory
	addi	s3, zero, -1	# Sentinal value
	lw	s4, 0(s0)	# First instruction to translate
	
	Current_Instruction:
		beq	s3, s4, RISCVtoARM_ALUDone	# Since s3 is a sentinal value which indicate end of instructions
		mv	a0, s4	# Current RISC-V Instruction to be translated to ARM instruction
		jal 	translateALU	# To translate the current instruction
		slli	t0, s2, 2	# t0 <- s2 * 4 = word offset
		add	t0, s1, t0	# Moving the pointer to right memory location to store the translated ALU instruction
		sw	a0, 0(t0)	# Storing the translated ALU instruction
		addi	s2, s2, 1	# Incrementing the count since we wrote one byte
		
		slli	t0, s2, 2	# t0 <- s2 * 4 = word offset
		add	t0, s0, t0	# Moving the pointer to right memory location to read the next RISC-V instruction
		lw	s4, 0(t0)	# Next Instruction to translate
		b	Current_Instruction
		
	RISCVtoARM_ALUDone:
	
	slli	s2, s2, 2	# s2 <- s2 * 4 = word offset
	mv	a0, s2		# Number of byte written to memory location pointed by a1
	
	
	# Restoring registers
	lw	ra, 0(sp)
	lw	s0, 4(sp)
	lw	s1, 8(sp)
	lw	s2, 12(sp)
	lw	s3, 16(sp)
	lw	s4, 20(sp)
	addi	sp, sp, 24
	
	jr	ra

#----------------------------------------------------------------
# This function translates a single ALU R-type or I-type
# instruction into an ARM instruction.
#
# Arguments:
#	* a0: untranslated RISC-V instruction
# Return Values:
#	* a0: translated ARM instruction
#----------------------------------------------------------------
translateALU:
	
	# Preparing stack to store registers
	addi	sp, sp, -12	# Moving Stack Pointer by 3 Words or 12 Bytes
	sw	ra, 0(sp)
	sw	s0, 4(sp)	# To store the untranslated RISC-V Instruction
	sw	s1, 8(sp)	# To store any temporary value needed
	
	mv	s0, a0		# s0 <- untranslated RISC-V Instruction
	
	add	s1, zero, zero	
	addi	t0, zero, 14	# Condition bits for ARM Instructions (1110 = 14)
		
	slli	s1, t0, 28 	# Setting the Condition bits for ARM Instructions in right place
	
	slli	t0, s0, 25	# To get the opcode of RISC-V Instruction
	srli	t0, t0, 25	# To get the opcode of RISC-V Instruction
	
	addi	t1, zero, 19	# Opcode of a I Type instruction in RISC-V
	beq	t0, t1, I_Type	# Since it's a I_Type Instruction
	
	R_Type:
		srli	t0, s0, 12	# To get the FUNCT 3 code of the current RISC-V Instruction
		slli	t0, t0, 29	# To get the FUNCT 3 code of the current RISC-V Instruction
		srli	t0, t0, 29	# To get the FUNCT 3 code of the current RISC-V Instruction
		mv	a1, zero	# Flag to indicate it's a R-Type Instruction
		
		srli	t1, s0, 25	# To get the FUNCT 7 code of the current RISC-V Instruction
		
		add	t2, t0, t1	# FUNCT3 + FUNCT7
		
		addi	t3, zero, 7	# 7 is the sum of FUNCT3 and FUNCT7 of AND In RISC-V
		beq	t2, t3, ToAND
		
		addi	t3, zero, 6	# 6 is the sum of FUNCT3 and FUNCT7 of OR in RISC-V
		beq	t2, t3, ToOR
		
		beq	t2, zero, ToADD	# zero is the sum of FUNCT3 and FUNCT7 of ADD in RISC-V
		
		addi	t3, zero, 32	# 32 is the sum of FUNCT3 and FUNCT7 of SUB in RISC-V
		beq	t2, t3, ToSUB
		
		addi	t3, zero, 37	# 37 is the sum of FUNCT3 and FUNCT7 of SRA in RISC-V
		beq	t2, t3, ToASR
		
		addi	t3, zero, 5	# 5 is the sum of FUNCT3 and FUNCT7 of LSR in RISC-V
		beq	t2, t3, ToLSR
		
		addi	t3, zero, 1	# 1 is the sum of FUNCT3 and FUNCT7 of LSL in RISC-V
		beq	t2, t3, ToLSL
		
	
	I_Type:
		srli	t0, s0, 12	# To get the FUNCT 3 code of the current RISC-V Instruction
		slli	t0, t0, 29	# To get the FUNCT 3 code of the current RISC-V Instruction
		srli	t0, t0, 29	# To get the FUNCT 3 code of the current RISC-V Instruction
		addi	a1, zero, 1	# Flag to indicate it's a I-Type Instruction
		
		addi	t1, zero, 7	# 7 is the FUNCT 3 code for AND In RISC-V 
		beq	t0, t1, ToAND
		
		addi	t1, zero, 6	# 6 is the FUNCT 3 code for OR in RISC-V
		beq	t0, t1, ToOR
		
		beq	t0, zero, ToADD	# 0 is the FUNCT 3 code for ADD in RISC-V
		
		addi	t1, zero, 1	# 1 is the FUNCT 3 code for SLLI in RISC-V
		beq	t0, t1, ToLSL
		
		srli	t1, s0, 25	# To get the FUNCT 7 code of the current RISC-V Instruction
		add	t1, t0, t1	# Adding both FUNCT 3 AND FUNCT 7
		
		beq	t0, t1, ToLSR	# Since FUNCT7 + FUNCT3 = FUNCT3 for SRLI in RISC-V
		
		addi	t0, zero, 37	# Since FUNCT7 + FUNCT3 = 37 for SRAI in RISC-V
		beq	t0, t1, ToASR
		
	ToAND:
		
		addi	t0, zero, 1
		beq	a1, t0, ToANDI
		
		srli	a0, s0, 15	# To get the source register number
		slli	a0, a0, 27	# To get the source register number
		srli	a0, a0, 27	# To get the source register number
		jal	translateRegister
			
		slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 20	# To get the target register number
		slli	a0, a0, 27	# To get the target register number
		srli	a0, a0, 27	# To get the target register number
		jal	translateRegister
		
		add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 7	# To get the destination register number
		slli	a0, a0, 27	# To get the destination register number
		srli	a0, a0, 27	# To get the destination register number
			
		jal	translateRegister
			
		slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
		
		mv	a0, s1
		b	translateALUDone
		
		ToANDI:
			addi	t0, zero, 1
			slli	t0, t0, 25	# To set bit 25 to 1
			#addi	t0, zero, 33554432	# To set bit 25 to 1
			add	s1, s1, t0	# Since it's a immediate instruction setting bit 25 to 1
			
			srli	a0, s0, 15	# To get the source register number
			slli	a0, a0, 27	# To get the source register number
			srli	a0, a0, 27	# To get the source register number
			
			jal	translateRegister
			
			slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
			add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	a0, s0, 7	# To get the destination register number
			slli	a0, a0, 27	# To get the destination register number
			srli	a0, a0, 27	# To get the destination register number
			
			jal	translateRegister
			
			slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
			add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	a0, s0, 20	# To get the immediate value of RISC-V Instruction
			
			jal	computeRotation
			
			add	s1, s1, a0	# Setting the translated immediate and rotate value to ARM Instruction format
			
			mv	a0, s1		# To return the translated RISC-V Instruction
			
			b	translateALUDone
	
	ToOR:
		addi	t0, zero, 1
		beq	a1, t0, ToORI
		
		addi	t0, zero, 12		# Opcode for ARM OR Instruction
		slli	t0, t0, 21		# Setting the Opcode in right place
		add	s1, s1, t0		# Setting the Opcode in ARM Instruction
			
		srli	a0, s0, 15	# To get the source register number
		slli	a0, a0, 27	# To get the source register number
		srli	a0, a0, 27	# To get the source register number
		jal	translateRegister
			
		slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 20	# To get the target register number
		slli	a0, a0, 27	# To get the target register number
		srli	a0, a0, 27	# To get the target register number
		jal	translateRegister
		
		add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 7	# To get the destination register number
		slli	a0, a0, 27	# To get the destination register number
		srli	a0, a0, 27	# To get the destination register number
			
		jal	translateRegister
			
		slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
		
		mv	a0, s1
		b	translateALUDone
		
		ToORI:
			
			addi	t0, zero, 12		# Opcode for ARM OR Instruction
			slli	t0, t0, 21		# Setting the Opcode in right place
			add	s1, s1, t0		# Setting the Opcdoe in ARM Instruction
			
			
			addi	t0, zero, 1
			slli	t0, t0, 25	# To set bit 25 to 1
			#addi	t0, zero, 33554432	# To set bit 25 to 1
			add	s1, s1, t0	# Since it's a immediate instruction setting bit 25 to 1
			
			srli	a0, s0, 15	# To get the source register number
			slli	a0, a0, 27	# To get the source register number
			srli	a0, a0, 27	# To get the source register number
			
			jal	translateRegister
			
			slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
			add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	a0, s0, 7	# To get the destination register number
			slli	a0, a0, 27	# To get the destination register number
			srli	a0, a0, 27	# To get the destination register number
			
			jal	translateRegister
			
			slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
			add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	a0, s0, 20	# To get the immediate value of RISC-V Instruction
			
			jal	computeRotation
			
			add	s1, s1, a0	# Setting the translated immediate and rotate value to ARM Instruction format
			
			mv	a0, s1		# To return the translated RISC-V Instruction
			
			b	translateALUDone
			
		
	ToADD:
		addi	t0, zero, 1
		beq	a1, t0, ToADDI
		
		addi	t0, zero, 4		# Opcode for ARM ADD Instruction
		slli	t0, t0, 21		# Setting the Opcode in right place
		add	s1, s1, t0		# Setting the Opcode in ARM Instruction
			
		srli	a0, s0, 15	# To get the source register number
		slli	a0, a0, 27	# To get the source register number
		srli	a0, a0, 27	# To get the source register number
		jal	translateRegister
			
		slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 20	# To get the target register number
		slli	a0, a0, 27	# To get the target register number
		srli	a0, a0, 27	# To get the target register number
		jal	translateRegister
		
		add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 7	# To get the destination register number
		slli	a0, a0, 27	# To get the destination register number
		srli	a0, a0, 27	# To get the destination register number
			
		jal	translateRegister
			
		slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
		
		mv	a0, s1
		b	translateALUDone
		
		
		ToADDI:
			addi	t0, zero, 1
			slli	t0, t0, 31	# To set bit 31 to 1
			#addi	t0, zero, 2147483648	# To get the MSB of RISC-V Instruction
			and	t0, s0, t0	# To check for the MSB
			bne	t0, zero, ToSUB	# Since Immediate value is negative translating to a SUB Instrution
			
			addi	t0, zero, 4		# Opcode for ARM ADD Instruction
			slli	t0, t0, 21		# Setting the Opcode in right place
			add	s1, s1, t0		# Setting the Opcdoe in ARM Instruction
			
			addi	t0, zero, 1
			slli	t0, t0, 25	# To set bit 25 to 1
			#addi	t0, zero, 33554432	# To set bit 25 to 1
			add	s1, s1, t0	# Since it's a immediate instruction setting bit 25 to 1
			
			srli	a0, s0, 15	# To get the source register number
			slli	a0, a0, 27	# To get the source register number
			srli	a0, a0, 27	# To get the source register number
			
			jal	translateRegister
			
			slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
			add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	a0, s0, 7	# To get the destination register number
			slli	a0, a0, 27	# To get the destination register number
			srli	a0, a0, 27	# To get the destination register number
			
			jal	translateRegister
			
			slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
			add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	a0, s0, 20	# To get the immediate value of RISC-V Instruction
			
			jal	computeRotation
			
			add	s1, s1, a0	# Setting the translated immediate and rotate value to ARM Instruction format
			
			mv	a0, s1		# To return the translated RISC-V Instruction
			
			b	translateALUDone
	
	ToSUB:
		addi	t0, zero, 2		# Opcode for ARM SUB Instruction
		slli	t0, t0, 21		# Setting the Opcode in right place
		add	s1, s1, t0		# Setting the Opcode in ARM Instruction
			
		srli	a0, s0, 15	# To get the source register number
		slli	a0, a0, 27	# To get the source register number
		srli	a0, a0, 27	# To get the source register number
		jal	translateRegister
			
		slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 20	# To get the target register number
		slli	a0, a0, 27	# To get the target register number
		srli	a0, a0, 27	# To get the target register number
		jal	translateRegister
		
		add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 7	# To get the destination register number
		slli	a0, a0, 27	# To get the destination register number
		srli	a0, a0, 27	# To get the destination register number
			
		jal	translateRegister
			
		slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
		
		mv	a0, s1
		b	translateALUDone
		
	ToASR:
		addi	t0, zero, 1
		beq	a1, t0, ToASRI
		
		addi	t0, zero, 16
		add	s1, s1, t0
		addi	t0, zero, 13		# Opcode for ARM ASR Instruction
		slli	t0, t0, 21		# Setting the Opcode in right place
		add	s1, s1, t0		# Setting the Opcode in ARM Instruction
			
		srli	a0, s0, 15	# To get the source register number
		slli	a0, a0, 27	# To get the source register number
		srli	a0, a0, 27	# To get the source register number
		jal	translateRegister
		
		add	s1, s1, a0
				
		#slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
		#add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 20	# To get the target register number
		slli	a0, a0, 27	# To get the target register number
		srli	a0, a0, 27	# To get the target register number
		jal	translateRegister
		
		slli	a0, a0, 8
		add	s1, s1, a0
		#add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		addi	t0, zero, 2
		slli	t0, t0, 5	# Shift type for ASR instruction
		
		add	s1, s1, t0	# Setting the shift type for ARM Instruction format
		
		srli	a0, s0, 7	# To get the destination register number
		slli	a0, a0, 27	# To get the destination register number
		srli	a0, a0, 27	# To get the destination register number
			
		jal	translateRegister
			
		slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
		
		mv	a0, s1
		b	translateALUDone
		
		ToASRI:
			addi	t0, zero, 13		# Opcode for ARM LSR Instruction
			slli	t0, t0, 21		# Setting the Opcode in right place
			add	s1, s1, t0		# Setting the Opcdoe in ARM Instruction
			
			srli	a0, s0, 15	# To get the source register number
			slli	a0, a0, 27	# To get the source register number
			srli	a0, a0, 27	# To get the source register number
			
			jal	translateRegister
			
			add	s1, s1, a0
		
			#slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
			#add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	a0, s0, 7	# To get the destination register number
			slli	a0, a0, 27	# To get the destination register number
			srli	a0, a0, 27	# To get the destination register number
			
			jal	translateRegister
			
			slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
			add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	t0, s0, 20	# To get the immediate value of RISC-V Instruction
			
			slli	t0, t0, 7
			
			add	s1, s1, t0	# Setting the translated immediate and rotate value to ARM Instruction format
			
			addi	t0, zero, 2
			
			slli	t0, t0, 5	# Shift type for ASR instruction
		
			add	s1, s1, t0	# Setting the shift type for ARM Instruction format
			
			mv	a0, s1		# To return the translated RISC-V Instruction
			
			b translateALUDone
		
		
	
	ToLSR:
		addi	t0, zero, 1
		beq	a1, t0, ToLSRI
		
		addi	t0, zero, 16
		add	s1, s1, t0
		
		addi	t0, zero, 13		# Opcode for ARM LSR Instruction
		slli	t0, t0, 21		# Setting the Opcode in right place
		add	s1, s1, t0		# Setting the Opcode in ARM Instruction
			
		srli	a0, s0, 15	# To get the source register number
		slli	a0, a0, 27	# To get the source register number
		srli	a0, a0, 27	# To get the source register number
		jal	translateRegister
			
		add	s1, s1, a0
			
		#slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
		#add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 20	# To get the target register number
		slli	a0, a0, 27	# To get the target register number
		srli	a0, a0, 27	# To get the target register number
		jal	translateRegister
		
		slli	a0, a0, 8
		add	s1, s1, a0
		#add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		addi	t0, zero, 1
		slli	t0, t0, 5	# Shift type for ASR instruction
		
		add	s1, s1, t0	# Setting the shift type for ARM Instruction format
		
		srli	a0, s0, 7	# To get the destination register number
		slli	a0, a0, 27	# To get the destination register number
		srli	a0, a0, 27	# To get the destination register number
			
		jal	translateRegister
			
		slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
		
		mv	a0, s1
		b	translateALUDone
		
		ToLSRI:
			
			addi	t0, zero, 13		# Opcode for ARM LSR Instruction
			slli	t0, t0, 21		# Setting the Opcode in right place
			add	s1, s1, t0		# Setting the Opcdoe in ARM Instruction
			
			srli	a0, s0, 15	# To get the source register number
			slli	a0, a0, 27	# To get the source register number
			srli	a0, a0, 27	# To get the source register number
			
			jal	translateRegister
			
			add	s1, s1, a0
		
			#slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
			#add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	a0, s0, 7	# To get the destination register number
			slli	a0, a0, 27	# To get the destination register number
			srli	a0, a0, 27	# To get the destination register number
			
			jal	translateRegister
			
			slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
			add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	t0, s0, 20	# To get the immediate value of RISC-V Instruction
			
			slli	t0, t0, 7
			
			add	s1, s1, t0	# Setting the translated immediate and rotate value to ARM Instruction format
			
			addi	t0, zero, 1
			
			slli	t0, t0, 5	# Shift type for ASR instruction
		
			add	s1, s1, t0	# Setting the shift type for ARM Instruction format
			
			mv	a0, s1		# To return the translated RISC-V Instruction
			
			b translateALUDone
	
	ToLSL:
		addi	t0, zero, 1
		beq	a1, t0, ToLSLI
		
		addi	t0, zero, 16
		add	s1, s1, t0
		
		addi	t0, zero, 13		# Opcode for ARM LSR Instruction
		slli	t0, t0, 21		# Setting the Opcode in right place
		add	s1, s1, t0		# Setting the Opcode in ARM Instruction
			
		srli	a0, s0, 15	# To get the source register number
		slli	a0, a0, 27	# To get the source register number
		srli	a0, a0, 27	# To get the source register number
		jal	translateRegister
		
		add	s1, s1, a0
			
		#slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
		#add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		srli	a0, s0, 20	# To get the target register number
		slli	a0, a0, 27	# To get the target register number
		srli	a0, a0, 27	# To get the target register number
		jal	translateRegister
		
		slli	a0, a0, 8
		add	s1, s1, a0
		#add	s1, s1, a0	# Setting the translated ARM register to ARM Instruction format
		
		mv	t0, zero
		slli	t0, t0, 5	# Shift type for ASR instruction
		
		add	s1, s1, t0	# Setting the shift type for ARM Instruction format
		
		srli	a0, s0, 7	# To get the destination register number
		slli	a0, a0, 27	# To get the destination register number
		srli	a0, a0, 27	# To get the destination register number
			
		jal	translateRegister
			
		slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
		add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
		
		mv	a0, s1
		b	translateALUDone
		
		
		ToLSLI:
			addi	t0, zero, 13		# Opcode for ARM LSR Instruction
			slli	t0, t0, 21		# Setting the Opcode in right place
			add	s1, s1, t0		# Setting the Opcdoe in ARM Instruction
			
			srli	a0, s0, 15	# To get the source register number
			slli	a0, a0, 27	# To get the source register number
			srli	a0, a0, 27	# To get the source register number
			
			jal	translateRegister
		
			add	s1, s1, a0
			#slli	a0, a0, 16	# a0 contains the ARM register number setting it to right bits
			#add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	a0, s0, 7	# To get the destination register number
			slli	a0, a0, 27	# To get the destination register number
			srli	a0, a0, 27	# To get the destination register number
			
			jal	translateRegister
			
			slli	a0, a0, 12	# a0 contains the ARM register number setting it to right bits
			add	s1, s1, a0	# Setting the ARM register to ARM Instruction format
			
			srli	t0, s0, 20	# To get the immediate value of RISC-V Instruction
			
			slli	t0, t0, 7
			
			add	s1, s1, t0	# Setting the translated immediate and rotate value to ARM Instruction format
			
			mv	t0, zero
			slli	t0, t0, 5	# Shift type for ASR instruction
		
			add	s1, s1, t0	# Setting the shift type for ARM Instruction format
			
			mv	a0, s1		# To return the translated RISC-V Instruction
			
			b translateALUDone
	
	
	translateALUDone:
		# Restoring registers
		lw	ra, 0(sp)
		lw	s0, 4(sp)
		lw	s1, 8(sp)
		
		addi	sp, sp, 12
		
		jr	ra
	
	
#----------------------------------------------------------------
# This function converts the number of a RISC-V register passed
# in a0 into the number of a corresponding ARM register.
#
# Arguments:
#	* a0: RISC-V register to translate.
# Return Values:
#	* a0: translated ARM register.
#----------------------------------------------------------------
translateRegister:

	mv	t0, a0	# Moving the RISC-V register number to t0
	
	addi	t1, zero, 1
	beq	t0, t1, R14	# Since, x1 == R14
	
	addi	t1, zero, 2
	beq	t0, t1, R13	# Since, x2 == R13
	
	addi	t1, zero, 10
	beq	t0, t1, R10	# Since, x10 == R10
	
	addi	t1, zero, 11
	beq	t0, t1, R11	# Since, x11 == R11
	
	addi	t1, zero, 12
	beq	t0, t1, R12	# Since, x12 == R12
	
	addi	t1, zero, 10
	blt	t0, t1, lessThan10
	
	bgt	t0, t1, GreaterThan10
	
	R14:
		addi	t1, zero, 14
		mv	a0, t1
		jr	ra
	
	R13:
		addi	t1, zero, 13
		mv	a0, t1
		jr	ra
	
	R10:
		jr	ra
		
	R11:
		jr	ra
		
	R12:
		jr	ra
		
	lessThan10:
		addi	t1, zero, 5
		sub	t0, t0, t1
		mv	a0, t0
		jr	ra
	
	GreaterThan10:
		addi	t1, zero, 13
		sub	t0, t0, t1
		mv	a0, t0
		jr	ra
	
	
#----------------------------------------------------------------
# This function uses the immediate passed in a0 to generate
# rotate and immediate fields for an ARM immediate instruction.
# The function treats the immediate as an unsigned number.
#
# Arguments:
#	* a0: RISC-V immediate in the bottom 20bits
# Return Values:
#	* a0: rotate in bits 11 to 8 and immediate in
#	  bits 7 to 0, with all other bits 0
#----------------------------------------------------------------
computeRotation:
	
	addi	t1, zero, 0	# To count the number of shift operation to be performed
	mv	t0, a0		# RISC-V immediate value in the bottom 20 bits
	
	addi	t2, zero, 255	# Since it's the maximum number that can be represented in 8-bit unsigned number
	
	Rotation:
		bleu	t0, t2, computeRotationDone	# Since it's just a 8-bit unsigned number
		
		addi	t3, zero, 1
		slli	t3, t3, 31	# To set bit 31 to 1	
		#addi	t3, zero, 2147483648	# To check for the MSB of RISC-V immediate value
		
		and	t3, t0, t3		# To check for the MSB of RISC-V immediate value
		
		bne	t3, zero, MSBisONE
		
		slli	t0, t0, 1		# Since MSB is zero we don't have to add one to the result
		
		addi	t1, t1, 1		# Incrementing count since we shifted one bit left
		
		b 	Rotation
		
		MSBisONE:
			slli	t0, t0, 1
			addi	t0, t0, 1	# Since MSB is one we have to add one to the result of shift(wraparound)
			
			addi	t1, t1, 1	# Incrementing count since we shifted one bit left
			
			b	Rotation
		
	computeRotationDone:
		addi	t3, zero, 2
		rem	t3, t1, t3
		
		bne	t3, zero, ODD
		
		srli	t1, t1, 1	# Dividing t1 by 2 or shifting it right by one bit since ARM rotation is only 4 bits
		
		slli	a0, t1, 8	# To set the ARM rotation value in right bits
		
		add	a0, a0, t0	# Setting ARM rotation value and Immediate value to right bits
		
		jr	ra
		
		ODD:
		
		slli	t0, t0, 1
		
		addi	t1, t1, 1	# Incrementing count since we shifted one bit left
		
		srli	t1, t1, 1	# Dividing t1 by 2 or shifting it right by one bit since ARM rotation is only 4 bits
		
		slli	a0, t1, 8	# To set the ARM rotation value in right bits
		
		add	a0, a0, t0	# Setting ARM rotation value and Immediate value to right bits
		
		jr	ra
		
		