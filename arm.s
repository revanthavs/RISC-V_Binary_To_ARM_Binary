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

.data

.align 2
# Space to store contents of RISC-V to ARM Table
RATTable:	.space 2048

# Space to store contents of Branch Table
BranchTable:	.space 2048

.include "common.s"
# NOTE: for the below to work, you must delete the .include "common.s" from your arm_alu.s file
.include "arm_alu.s" 

#----------------------------------------------------------------------------
# This function translates RISC-V code in memory at address found in a0 into
# ARM code and stores that ARM code into the memory address found in a1.
# 
# Arguments:
#	a0: pointer to memory containing a RISC-V function. The end of the
#	 RISC-V instructions is marked by the sentinel word 0xFFFFFFFF.
#	
#	a1: a pointer to preallocated memory where you will have to write
#	 ARM instructions.
#
# Return Value:
#	a0: number of bytes worth of instructions generated by RISCVtoARM.
#
#----------------------------------------------------------------------------
RISCVtoARM:

	# Preparing Stack to store Registers
	addi	sp, sp, -40	# Moving stack by 10 words or 40 bytes
	sw	ra, 0(sp)
	sw	s0, 4(sp)	# To store a0 Pointer to memory containing a RISC-V Function
	sw	s1, 8(sp)	# To store a1 Pointer to memory to write the translated RISC-V Instruction
	sw	s2, 12(sp)	# To store Pointer to RISC-V to ARM Table (RAT Table)
	sw	s3, 16(sp)	# To store Pointer to Branch Table (Branch Table)
	sw	s4, 20(sp)	# To count the number of bytes read from a0 memory address
	sw	s5, 24(sp)	# To count the number of bytes written to a1 memory address
	sw	s6, 28(sp)	# To store sentinal value (Oxffffffff)
	sw	s7, 32(sp)	# To store current Instruction being translated
	sw	s8, 36(sp)	# To count number of bytes written to Tables
	
	mv	s0, a0
	mv	s1, a1
	la	s2, RATTable
	la	s3, BranchTable
	mv	s4, zero
	mv	s5, zero
	addi	s6, zero, -1	# Since -1 is equal to 0xffffffff
	lw	s7, 0(s0)	# First RISC-V Instruction to translate
	mv	s8, zero	
	addi	s4, s4, 4	# Since we have read one RISC-V Instruction(4 bytes)
	
	FirstPass:
		beq	s7, s6, FirstPassDone	# Since we need to calculate Branch Offset
		
		slli	t0, s7, 25	# To get the opcode of RISC-V Instruction
		srli	t0, t0, 25	# To get the opcode of RISC-V Instruction
		addi	t1, zero, 19
		beq	t0, t1, ALUInstruction
		addi	t1, zero, 51
		beq	t0, t1, ALUInstruction
		
		mv	a0, s7		# Untranslated RISC-V Instruction
		jal	translateControl
		# a0: Contains the first translated ARM Instruction
		# a1: 0 or second translated ARM Instruction
		bne	a1, zero, BranchInstruction
		
		add	t0, s1, s5	# Moving the s1 pointer to right memory location to write translated instruction
		sw	a0, 0(t0)	# Storing the translated ARM Instruction
		addi	s5, s5, 4	# Since we wrote a word(4 bytes) to memory
		
		add	t1, s2, s8	# Moving the s2 pointer to right memory location to store address of ARM Binary
		sw	t0, 0(t1)	# Storing the s1 pointer in RAT Table
		
		add	t1, s3, s8	# Moving the s3 pointer to right memory location to store zero
		sw	zero, 0(t1)	# Since it's not a BranchInstruction we are storing zero
		addi	s8, s8, 4	# Since we wrote a word(4 bytes) to RAT and Branch tables
		
		add	t0, s0, s4	# Moving the s0 pointer to right memory location to read next instruction
		lw	s7, 0(t0)	# Loading the next instruction to translate
		addi	s4, s4, 4	# Since we have read one RISC-V Instruction(4 bytes)
		
		b	FirstPass
		
		BranchInstruction:
			
			add	t0, s1, s5	# Moving the s1 pointer to right memory location to write translated instruction
			sw	a0, 0(t0)	# Storing the First translated ARM Instruction
			sw	a1, 4(t0)	# Storing the Second translated ARM Instruction
			addi	s5, s5, 8	# Since we wrote two words(8 bytes) to memory
			
			add	t1, s2, s8	# Moving the s2 pointer to right memory location to store address of ARM Binary
			sw	t0, 0(t1)	# Storing the s0 pointer in RAT Table
			
			mv	a0, s7		# Untranslated RISC-V Instruction
			jal	calculateRISCVBranchOffset
			# a0: contains the branch offset
			
			add	t0, s2, s8	# Moving the s2 pointer to right memory location
			add	t0, t0, a0	# To get the target address
			
			add	t1, s3, s8	# Moving the s3 pointer to right memory location
			sw	t0, 0(t1)	# Storing the target address in Branch Table
			
			addi	s8, s8, 4	# Since we wrote a word(4 bytes) to RAT and Branch Tables
			
			add	t0, s0, s4	# Moving the s0 pointer to right memory location to read next instruction
			lw	s7, 0(t0)	# Loading the next instruction to translate
			addi	s4, s4, 4	# Since we have read one RISC-V Instruction(4 bytes)
			
			b	FirstPass
		
		ALUInstruction:
			mv	a0, s7		# First Argument to translateALU Function
			
			jal	translateALU
			add	t0, s1, s5	# Moving the s1 pointer to right memory location to write translated instruction
			sw	a0, 0(t0)	# Storing the translated ARM Instruction
			addi	s5, s5, 4	# Since we wrote a word(4 bytes) to memory
		
			add	t1, s2, s8	# Moving the s2 pointer to right memory location to store address of ARM Binary
			sw	t0, 0(t1)	# Storing the s1 pointer in RAT Table
		
			add	t1, s3, s8	# Moving the s3 pointer to right memory location to store zero
			sw	zero, 0(t1)	# Since it's not a BranchInstruction we are storing zero
			addi	s8, s8, 4	# Since we wrote a word(4 bytes) to RAT and Branch tables
		
			add	t0, s0, s4	# Moving the s0 pointer to right memory location to read next instruction
			lw	s7, 0(t0)	# Loading the next instruction to translate
			addi	s4, s4, 4	# Since we have read one RISC-V Instruction(4 bytes)
		
			b	FirstPass
		
			
	FirstPassDone:
		mv	s4, zero	# Since we need to read the RISC-V Instructions again
		mv	s8, zero	# Re-Using s8 to count no.of bytes read from s1 memory location
		
		lw	s7, 0(s0)	# First RISC-V Instruction
		lw	t0, 0(s2)	# First RAT Table value
		lw	t1, 0(s3)	# First Branch Table value
		lw	t2, 0(s1)	# First Translated ARM Instruction
		addi	s4, s4, 4	# Since we have read one RISC-V Instruction
		addi	s8, s8, 4	# Since we have read one Translated ARM Instruction
		
		b	SecondPass
		
	SecondPass:
		beq	s7, s6, RISCVtoARMDone
		
		bne	t1, zero, CalculateARMOffset
		
		add	t3, s0, s4	# Moving the s0 pointer to get next instruction
		lw	s7, 0(t3)	# Next RISC-V Instruction
		add	t3, s2, s4	# Moving the s2 pointer to get next correspoinds RAT Table value
		lw	t0, 0(t3)	# Next corresponding RAT Table value
		add	t3, s3, s4	# Moving the s3 pointer to get next corresponding Branch Table value
		lw	t1, 0(t3)	# Next corresponding Branch Table value
		addi	s4, s4, 4	# Since we have read one RISC-V Instruction
		add	t3, s1, s8	# Moving the s1 pointer to get next corresponding translated ARM Instruction
		lw	t2, 0(t3)	# Next Corresponding translated ARM Instruction
		addi	s8, s8, 4	# Since we have read one Translated ARM Instruction
		
		b	SecondPass
		
		CalculateARMOffset:
			
			addi	t0, t0, 4	# ARM branch address: t0 <- t0 + 0x04
			lw	t3, 0(t1)	# ARM branch target: in t1 address
			sub	t3, t3, t0	# ARM branch offset: t3 <- t3 - (t0 + 0x04)
			
			addi	t3, t3, -8	# ARM branch offset: t3 <- t3 - 0x08
			srli	t5, t3, 31	# To find if its a negative offset or a positive offset
			
			bne	t5, zero, NegativeARMOffset
			
			srai	t3, t3, 2	## Moving ARM offset by two bits
			
			lw	t4, 0(t0)	# Current value for Branch in ARM Binary
			add	t4, t4, t3	# Setting the new Branch offset
			
			sw	t4, 0(t0)	# Storing the updated value
			addi	s8, s8, 4	# Since it's a branch instruction updaing the count
			
			add	t3, s0, s4	# Moving the s0 pointer to get next instruction
			lw	s7, 0(t3)	# Next RISC-V Instruction
			add	t3, s2, s4	# Moving the s2 pointer
			lw	t0, 0(t3)	# Next corresponding RAT Table vallue
			add	t3, s3, s4	# Moving the s3 pointer to get next corresponding Branch Table value
			lw	t1, 0(t3)	# Next corresponding Branch Table Value
			addi	s4, s4, 4	# Since we have read one RISC-V Instruction
			add	t3, s1, s8	# Moving the s1 pointer to get next corresponding translated ARM Instruction
			lw	t2, 0(t3)	# Next Corresponding translated ARM Instruction
			addi	s8, s8, 8	## Since we have read one Translated ARM Instruction
			
			b	SecondPass
			
			NegativeARMOffset:
				
				slli	t3, t3, 8	
				srli	t3, t3, 10
				
				lw	t4, 0(t0)	# Current value for Branch in ARM Binary
				add	t4, t4, t3	# Setting the new Branch offset
				
				addi	t5, zero, 1
				slli	t5, t5, 23
				xor	t4, t4, t5	# To enable bit 23
				srli	t5, t5, 1
				xor	t4, t4, t5	# To enable bit 22
			
				sw	t4, 0(t0)	# Storing the updated value
				addi	s8, s8, 4	# Since it's a branch instruction updaing the count
			
				add	t3, s0, s4	# Moving the s0 pointer to get next instruction
				lw	s7, 0(t3)	# Next RISC-V Instruction
				add	t3, s2, s4	# Moving the s2 pointer
				lw	t0, 0(t3)	# Next corresponding RAT Table vallue
				add	t3, s3, s4	# Moving the s3 pointer to get next corresponding Branch Table value
				lw	t1, 0(t3)	# Next corresponding Branch Table Value
				addi	s4, s4, 4	# Since we have read one RISC-V Instruction
				add	t3, s1, s8	# Moving the s1 pointer to get next corresponding translated ARM Instruction
				lw	t2, 0(t3)	# Next Corresponding translated ARM Instruction
				addi	s8, s8, 8	## Since we have read one Translated ARM Instruction
			
				b	SecondPass
			
			
	RISCVtoARMDone:
		
		mv	a0, s5
		
		# Restoring registers
		lw	ra, 0(sp)
		lw	s0, 4(sp)
		lw	s1, 8(sp)
		lw	s2, 12(sp)
		lw	s3, 16(sp)
		lw	s4, 20(sp)
		lw	s5, 24(sp)
		lw	s6, 28(sp)
		lw	s7, 32(sp)
		lw	s8, 36(sp)
		
		addi	sp, sp, 40
		jr	ra
		# TODO: Need to check if I should use jr ra or ret
		#ret
	

#----------------------------------------------------------------------------
# This function translates a single RISC-V beq, bge or jalr instruction into
# either one or two ARM instructions.
# 
# Arguments:
#	a0: untranslated RISC-V instruction.
#
# Return Value:
#	a0: first translated ARM instruction. This should either be a wholly
#	 tanslated BX instruction, or a CMP instruction.
#
#	a1: 0 or second translated ARM instruction. When non-zero,
#	 it should return a branch with 0 offset.
#----------------------------------------------------------------------------
translateControl:
	
	# Preparing Stack to store registers
	addi	sp, sp, -12	# Moving stack by 3 Words or 12 bytes
	sw	ra, 0(sp)
	sw	s0, 4(sp)	# To store untranslated RISC-V Instrction
	sw	s1, 8(sp)	# To store any tempararory value need
	
	mv	s0, a0		# Untranslated RISC-V Instruction
	add	s1, zero, zero
	
	slli	t0, s0, 25	# To get the opcode
	srli	t0, t0, 25	# To get the opcode
	addi	t1, zero, 103
	beq	t0, t1, jumpInstruction
	
	# CMP Instruction
	mv	t0, s0
	srli	t0, t0, 15	# To get the RISC-V source register number
	slli	t0, t0, 27	# To get the RISC-V source register number
	srli	t0, t0, 27	# To get the RISC-V source register number
	mv	a0, t0		# RISC-V register number to translate to ARM register number
	jal	translateRegister
	mv	s1, a0		# ARM register of RISC-V source register
	
	srli	t0, s0, 20	# To get the RISC-V target register number
	slli	t0, t0, 27	# To get the RISC-V target register number
	srli	t0, t0, 27	# To get the RISC-V target register number
	mv	a0, t0		# RISC-V register number to translate to ARM register number
	jal	translateRegister
	mv	t2, a0		# ARM register of RISC-V target register
	
	# Will enable the first bit to be 1 at the last
	addi	t3, zero, 6	# Condition field for Branch Format
	slli	t3, t3, 28	# Moving to the right position
	addi	t0, zero, 21	# Setting the Opcode and Status bit for CMP instruction register
	slli	t0, t0, 20	# Moving to the right position
	add	t3, t3, t0	# Setting THE Opcode for CMP instruction and Status bit registers in right position
	slli	t1, s1, 16	# Moving the RN register to right position
	add	t3, t3, t1	# Setting the Rn register to right position
	
	add	t3, t3, t2	# Setting the Rm register to right position
	addi	t0, zero, 1
	slli	t0, t0, 31
	xor	t3, t3, t0	# To set the last bit to 1
	mv	a0, t3		# CMP Instruction
	
	srli	t4, s0, 12	# To get the FUNC 3 value for branch instruction
	slli	t4, t4, 29	# To get the FUNC 3 value
	srli	t4, t4, 29	# To get the FUNC 3 value
	beq	t4, zero, ToBEQ
	
	# Branch Instruction
	addi	t3, zero, 170	# To enable the required bits in branch Format
	slli	t3, t3, 24
	mv	a1, t3		# Since the branch offset is equal to zero for this function
	
	b	translateControlDone
	
	ToBEQ:
		addi	t3, zero, 10	# To enable the required bits in branch format
		slli	t3, t3, 24
		mv	a1, t3
		
		b	translateControlDone
	
	
	jumpInstruction:
		slli	t0, s0, 12	# To get the RISC-V source register number
		srli	t0, t0, 27	# To get the RISC-V source register number
		mv	a0, t0		# To get the ARM register number

		jal	translateRegister
		# Will enable the first bit to be 1 at the last
		addi	t1, zero, 6	# Condition field for Branch Exchange Format
		slli	t1, t1, 28	# Moving to the right position
		addi	t0, zero, 303	# Setting bits from 16 - 27
		slli	t0, t0, 16	# Setting them in right position
		add	t1, t0, t1	# Setting bits from 16 - 31 in right position
		addi	t0, zero, 255	# Setting bits from 8-15
		slli	t0, t0, 8	# Setting bits from 8-15 in right position
		add	t1, t0, t1	# Setting bits from 8-31 in right position
		addi	t0, zero, 1	# Setting bit 4
		slli	t0, t0, 4	# Setting bit 4 in right position
		add	t1, t0, t1	# Setting bits from 4-31 in right position
		add	t1, t1, a0	# Setting bits from 0 - 3 in right position
		addi	t0, zero, 1
		slli	t0, t0, 31
		xor	t1, t1, t0	# To set the last bit to 1
		mv	a0, t1		# translated Branch Exchange Instruction
		mv	a1, zero	# Since's its a jump instruction
		b	translateControlDone
		
	translateControlDone:
		
		# Restoring registers
		lw	ra, 0(sp)
		lw	s0, 4(sp)
		lw	s1, 8(sp)
		
		addi	sp, sp, 12
		
		jr	ra
		
	
#----------------------------------------------------------------------------
# This function performs simple computations to calculate the RISC-V branch
# offset. Negative values calculated by this function should be returned
# with proper sign extension.
#
# Arguments:
#	a0: RISC-V instruction.
#
# Return Value:
#	a0: branch offset
#----------------------------------------------------------------------------
calculateRISCVBranchOffset:

	srli	t0, a0, 31	# To check for the sign of Branch offset
	beq	t0, zero, PositiveOffset
	
	# Negative Offset
	srli	t0, a0, 8	# To get the bits of 1 to 4 of Branch Offset
	slli	t0, t0, 1	# To set last 0th bit(Ghost bit) to 0
	slli	t0, t0, 27
	srli	t0, t0, 27
	srli	t1, a0, 25	# To get the bits of 5 to 10 of Branch Offset
	slli	t1, t1, 26	# To get only bits of 5 to 10 of branch offset 
	srli	t1, t1, 21	# To set the bits of 5 to 10 in right position
	add	t0, t0, t1	# Setting bits from 0 to 10 in right position
	srli	t1, a0, 7	# To get 11th offset bit
	slli	t1, t1, 31	# To get only 11th offset bit
	# TODO: Need to check this
	srli	t1, t1, 20	# To set the 11th bit in right position
	add	t0, t0, t1	# Setting 11th bit
	slli	t0, t0, 19	# To sign extend the offset value
	addi	t1, zero, 1	
	slli	t1, t1, 31
	xor	t0, t0, t1	# To set the first bit to 1
	srai	t0, t0, 19	## Sign extended Branch offset
	
	mv	a0, t0		# Return Value
	jr	ra
	
	PositiveOffset:
		srli	t0, a0, 8	# To get the bits of 1 to 4 of Branch Offset
		slli	t0, t0, 1	# To set last 0th bit(Ghost bit) to 0
		slli	t0, t0, 27
		srli	t0, t0, 27
		srli	t1, a0, 25	# To get the bits of 5 to 10 of Branch Offset
		slli	t1, t1, 26	# To get only bits of 5 to 10 of branch offset 
		srli	t1, t1, 21	# To set the bits of 5 to 10 in right position
		add	t0, t0, t1	# Setting bits from 0 to 10 in right position
		srli	t1, a0, 7	# To get 11th offset bit
		slli	t1, t1, 31	# To get only 11th offset bit
		# TODO: Need to check this
		srli	t1, t1, 20	# To set the 11th bit in right position
		add	t0, t0, t1	# Setting 11th bit
		
		mv	a0, t0		# Return Value
		jr	ra
	