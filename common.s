#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2021 University of Alberta
# Copyright 2017 Kristen Newbury
# Copyright 2019 Abdulrahman Alattas
# Copyright 2021 Danila Seliayeu
#
# This software is distributed to students in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the disclaimer below in the documentation
#    and/or other materials provided with the distribution.
#
# 2. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#-------------------------------------------------------------------------------------------------------------------------
# common.s
# Author: Danila Seliayeu
# Date: June 11, 2021
#
# Adapted from common.s of Lab_WASM by Abdulrahman Alattas and Kristen Newbury.
#-------------------------------------------------------------------------------------------------------------------------

.data

.align 2
# space for the representation of the RISC-V input program
binary: 	.space 2052
# space where the representation of the generated ARM program is to be placed
codeSection: 	.space 2048

noFileStr:	.asciz "Couldn't open specified file.\n"
createFileStr:	.asciz "Couldn't create specified file.\n"
format:		.asciz "\n"
# all generated output files are named 'out.bin'
outfile:      	.asciz "out.bin"

.text
main:
    lw      a0, 0(a1)				    # put the filename pointer into a0
    li      a1, 0   		           	# read Only
    li	    a7, 1024		    		# open File
    ecall
    bltz    a0, main_err	    		# negative means open failed

    la      a1, binary	        		# write into my binary space
    li      a2, 2048	        		# read a file of at max 2kb
    li      a7, 63		            	# read File System call
    ecall

    la      t0, binary
    add     t0, t0, a0	       			# point to end of binary space

    li      t1, 0xFFFFFFFF	    		# place ending sentinel
    sw      t1, 0(t0)

    la      a0, binary
    la      a1, codeSection
    jal     ra, RISCVtoARM_ALU          # run student solution
    jal     ra, writeFile               # write student's solution result to file

    jal     zero, main_done

main_err:
    la      a0, noFileStr
    li      a7, 4
    ecall

main_done:
    li      a7, 10
    ecall

#-------------------------------------------------------------------------------------------------------------------------
# writeFile
# This function opens file and writes student's translated ARM instructions into the file.
# 
# Arguments
#   - a0: number of bytes total for the translation result, value provided by the student
#-------------------------------------------------------------------------------------------------------------------------
writeFile:
    addi    sp, sp, -4
    sw      s0, 0(sp)
    mv      s0, a0
    # open file
    la      a0, outfile         # filename for writing to
    li      a1, 1   		    # Write flag
    li      a7, 1024            # Open File
    ecall
    bltz	a0, writeOpenErr	# Negative means open failed
    # write to file
    la      a1, codeSection     # address of buffer from which to start the write from
    mv      a2, s0              # buffer length
    li      a7, 64              # system call for write to file
    ecall                       # write to file
    # close file
    la      a0, outfile         # file descriptor to close
    li      a7, 57              # system call for close file
    ecall                       # close file
    jal     zero, writeFileDone

writeOpenErr:
    la      a0, createFileStr
    li      a7, 4
    ecall

writeFileDone:
    lw      s0, 0(sp)
    addi    sp, sp 4
    jalr    zero, ra, 0
#-------------------------------------end common--------------------------------------------