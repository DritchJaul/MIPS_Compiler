		.data  
		.globl  labelRefBuffer, addLabel, copyString, getFirstNonBlank, findNextBlank, findNextLine, sourceBuffer, codeBuffer, labelBuffer, dataBuffer
file:			.asciiz	"asm.dat"
codeOutput:		.asciiz	"instructions.dat"
dataOutput:		.asciiz	"dataSegment.dat"
newLine:		.asciiz	"\n"
		.align	2
sourceBuffer:		.space	1024
codeBuffer:		.space	1024
outputBuffer:		.space	2048
labelBuffer:		.space	1024
labelRefBuffer:		.space	1024
dataBuffer:		.space	1024

		.text


main:
	la	$a0,	file
	jal	getFile
	move	$s0,	$v0
	
	
	move	$a0,	$s0
	la	$a1,	dataBuffer
	la	$a2,	labelBuffer
	
	jal	processData
	move	$s6,	$a0
	move	$s0,	$v0
	move	$s4,	$v1


	move	$a0,	$s0
	li	$a1,	0
	jal	findNext
	move	$s1,	$v0
	
	li	$s3,	1	# $s3 = instruction count
	
main_LOOP:
	
	move	$a0,	$s0
	move	$a1,	$s1
	jal	getFirstNonBlank
	move	$s0,	$v0	# Start of line
	
	lb	$t0,	0($v0)
	beq	$t0,	0,	main_END
	
	move	$a0,	$s0
	move	$a1,	$s1
	jal	findNextLine
	move	$s2,	$v0	# End of line
	
	move	$a0,	$s0	# Check if instruction is a label
	move	$a1,	$s1
	jal	findNextBlank
	lb	$t0,	-1($v0)
	beq	$t0,	58,	main_LABL
	
	j	main_INSTRUCTION


main_LABL:
	move	$a0,	$s0
	move	$a1,	$v0
	
	sll	$t0,	$s3,	2
	addi	$t0,	$t0,	0x00400000
	move	$a2,	$t0
	
	move	$a3,	$s4
	
	jal	addLabel
	
	move	$s4,	$v0	#new position in labelBuffer
	move	$s2,	$v1	#s2 will be moved to s0, which is where the next line is
	
	j	main_NEXT

main_INSTRUCTION:

	move	$a0,	$s0
	move	$a1,	$s2
	move	$a2,	$s3
	jal	processLine
	
	move	$a0,	$v0
	li	$v0,	35
	syscall
	move	$t2,	$a0
	la	$a0,	newLine
	li	$v0,	4
	syscall
	
	addi	$t0,	$s3,	-1
	sll	$t0,	$t0,	2
	la	$t1,	codeBuffer
	add	$t0,	$t1,	$t0
	sw	$t2,	0($t0)
	addi	$s3,	$s3,	1	# Add 1 to instruction count
	
	j	main_NEXT

main_NEXT:
	bge	$s2,	$s1,	main_END
	move	$s0,	$s2
	j	main_LOOP
main_END:
	jal	addLabels
	
	jal	printCodeBuffer
	
	
	
	la	$a0,	codeBuffer
	addi	$s3,	$s3,	-2
	sll	$a1,	$s3,	2
	add	$a1,	$a0,	$a1
	jal	convertForOutput
	
	la	$a0,	outputBuffer
	move	$a1,	$v0
	la	$a2,	codeOutput
	jal	writeToFile
	
	
	la	$a0,	dataBuffer
	move	$a1,	$s6
	jal	convertForOutput
	
	la	$a0,	outputBuffer
	move	$a1,	$v0
	la	$a2,	dataOutput
	jal	writeToFile
	

	li $v0, 33
	li $a0, 69
	li $a1, 1000
	li $a2, 55
	li $a3, 60
	syscall 
	
	li	$v0,	10
	syscall


# $a0-$a1 block to put into buffer, $v0 end of outputBuffer
convertForOutput:
	addi	$sp,	$sp,	-12
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)
	sw	$s2,	12($sp)
	
	move	$s0,	$a0
	move	$s1,	$a1
	la	$s2,	outputBuffer
	
convertForOutput_LOOP:
	bgt	$s0,	$s1,	convertForOutput_END
	lw	$t0,	0($s0)
	
	addi	$t2,	$s2,	7
convertForOutput_LOOP2:
	blt	$t2,	$s2,	convertForOutput_LOOP2_END
	
	andi	$t1,	$t0,	0x0000000F

	bge	$t1,	10,	convertForOutput_A
	addi	$t1,	$t1,	48
	j	convertFotOutput_B
	convertForOutput_A:
	addi	$t1,	$t1,	55
	convertFotOutput_B:
	sb	$t1,	0($t2)
	
	addi	$t2,	$t2,	-1
	srl	$t0,	$t0,	4
	
	j	convertForOutput_LOOP2
	
convertForOutput_LOOP2_END:
	addi	$s0,	$s0,	4
	addi	$s2,	$s2,	8
	
	li	$t0,	10
	sb	$t0,	1($s2)
	li	$t0,	13
	sb	$t0,	2($s2)
	addi	$s2,	$s2,	3
	
	j	convertForOutput_LOOP

convertForOutput_END:

	move	$v0,	$s2

	lw	$s2,	12($sp)
	lw	$s1,	8($sp)
	lw	$s0,	4($sp)
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	12
	jr	$ra









# $a0-$a1 string to write, $a2 file name
writeToFile:
	addi	$sp,	$sp,	-16
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)
	sw	$s2,	12($sp)
	move	$s0,	$a0
	move	$s1,	$a1
	move	$s2,	$a2
	
    	li	$v0,	13
    	move	$a0,	$s2
    	li	$a1,	1
    	li	$a2,	0
    	syscall  # File descriptor gets returned in $v0

    	move	$a0,	$v0  # Syscall 15 requieres file descriptor in $a0
    	li	$v0,	15
    	move	$a1,	$s0
    	subu 	$a2,	$s1,	$s0  # computes the length of the string, this is really a constant
    	syscall
    	
    	li $v0, 16  # $a0 already has the file descriptor
   	syscall
	lw	$s2,	12($sp)
	lw	$s1,	8($sp)
	lw	$s0,	4($sp)
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	16
	jr	$ra


#	labelTextStart $a0, labelTextEnd $a1, address $a2, labelBuffer $a3
addLabel:
	addi	$sp,	$sp,	-16
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s4,	8($sp)
	sw	$s2,	12($sp)
	
	move	$s0,	$a0
	move	$s4,	$a3
	move	$s2,	$a2
	
	move	$v0,	$a1
	move	$t1,	$v0

	move	$a0,	$s0
	move	$a1,	$t1
	move	$a2,	$s4
	jal	copyString
	
	li	$t0,	58
	sb	$t0,	0($v0)
	add	$v0,	$v0,	1
addLabel_LOOP:	
	andi	$t0,	$v0,	0x00000003
	beqz	$t0,	addLabel_LOOP_END
	
	li	$t0,	58
	sb	$t0,	0($v0)
	add	$v0,	$v0,	1
	j	addLabel_LOOP
addLabel_LOOP_END:
	sb	$0,	-1($v0)

	sw	$s2,	0($v0)
	add	$v0,	$v0,	4

	move	$s4,	$v0
	move	$s2,	$t1
	
	move	$v0,	$s4
	move	$v1,	$t1
	
	
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s4,	8($sp)
	lw	$s2,	12($sp)
	addi	$sp,	$sp,	16
	jr	$ra








printCodeBuffer:
	la	$t0,	codeBuffer

printCodeBuffer_Loop:
	lw	$t1,	0($t0)
	beq	$t1,	$0,	printCodeBuffer_END
	
	move	$a0,	$t1
	li	$v0,	34
	syscall
	
	li	$a0,	45
	li	$v0,	11
	syscall
	
	move	$a0,	$t1
	li	$v0,	35
	syscall
	
	move	$t2,	$a0
	la	$a0,	newLine
	li	$v0,	4
	syscall
	
	addi	$t0,	$t0,	4
	j	printCodeBuffer_Loop
printCodeBuffer_END:
	jr	$ra






addLabels:
	addi	$sp,	$sp,	-8
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	
 	la	$s0,	labelRefBuffer

addLabels_LOOP:
	lw	$t0,	0($s0)
	beq	$t0,	0,	addLabels_END
	
	lw	$a0,	4($s0)
	lw	$a1,	8($s0)
	jal	findLabel		# $v0 = address of label address
	
	#IF $v0 is 0 here its error
	
	lw	$t0,	0($s0)	
	addi	$t0,	$t0,	-1
	sll	$t0,	$t0,	2
	
	la	$t1,	codeBuffer
	add	$t1,	$t1,	$t0	# $t1 = instruction address
	lw	$t0,	0($t1)		# $t0 = instruction
	
	lw	$t2,	12($s0)
	beq	$t2,	2,	addLabels_I
	beq	$t2,	3,	addLabels_J
	#also R, but thats error
	j	addLabels_NEXT
	
addLabels_I:
	lw	$t2,	0($s0)
	addi	$t2,	$t2,	-1
	sll	$t2,	$t2,	2

	sub	$v0,	$v0,	$t2
	srl	$v0, 	$v0,	2
	
	addi	$v0,	$v0,	-2
	andi	$v0,	$v0,	0x0000FFFF
	
	or	$t0,	$t0,	$v0
	
	sw	$t0,	0($t1)
	
	j	addLabels_NEXT
	
addLabels_J:
	srl	$v0,	$v0,	2
	addi	$v0,	$v0,	-1
	andi	$v0,	$v0,	0x03FFFFFF
	or	$t0,	$v0,	$t0
	sw	$t0,	0($t1)
	j	addLabels_NEXT
	
addLabels_NEXT:
	addi	$s0,	$s0,	16
	j	addLabels_LOOP
addLabels_END:

	lw	$s0,	4($sp)
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	8
	jr	$ra








#	labelTextStart $a0, labelTextEnd $a1
findLabel:
	addi	$sp,	$sp,	-8
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	la	$s0,	labelBuffer
	
findLabel_LOOP:
	lb	$t0,	0($s0)
	li	$v0,	0
	beqz	$t0,	findLabel_ERROR
	
	addi	$sp,	$sp,	-8
	sw	$a0,	0($sp)
	sw	$a1,	4($sp)
	
	move	$a0,	$s0
	li	$a1,	58
	jal	findNext
	
	move	$a2,	$s0
	addi	$a3,	$v0,	-1
	lw	$a1,	4($sp)
	lw	$a0,	0($sp)
	jal	stringEquals
	addi	$sp,	$sp,	-4
	sw	$v0,	0($sp)

	move	$a0,	$s0
	move	$a1,	$0
	jal	findNext
	addi	$v0,	$v0,	1
	lw	$t0,	0($sp)
	addi	$sp,	$sp,	4
	beq	$t0,	1,	findLabel_FOUND
	j	findLabel_SKIP
	
findLabel_FOUND:
	lw	$v0,	0($v0)
	
	lw	$a0,	4($sp)
	lw	$a1,	0($sp)
	addi	$sp,	$sp,	8
	j	findLabel_END
	
findLabel_SKIP:
	
	addi	$s0,	$v0,	4
	
	lw	$a1,	4($sp)
	lw	$a0,	0($sp)
	addi	$sp,	$sp,	8
	
	j	findLabel_LOOP
	
findLabel_END:
	lw	$s0,	4($sp)
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	8
	jr	$ra
findLabel_ERROR:
	li	$v0,	10
	syscall

# originalStringStart $a0, originalStringEnd $a1, newLocation $a2, returns $v0 the end of new string $a2 + ($a1 - $a0)
copyString:
	bgt	$a0,	$a1,	copyString_END
	lb	$t0,	0($a0)
	sb	$t0,	0($a2)
	addi	$a0,	$a0,	1
	addi	$a2,	$a2,	1
	j	copyString
copyString_END:
	move	$v0,	$a2
	jr	$ra





# textStart $a0, textEnd $a1
getFirstNonBlank:
	addi	$sp,	$sp,	-4
	sw	$ra,	0($sp)

	li	$v0,	0
getFirstNonBlank_LOOP:
	bgt	$a0,	$a1,	getFirstNonBlank_BLANK
	lb	$t0,	0($a0)
	addi	$a0,	$a0,	1
	beq	$t0,	32,	getFirstNonBlank_LOOP
	beq	$t0,	9,	getFirstNonBlank_LOOP
	beq	$t0,	10,	getFirstNonBlank_LOOP
	beq	$t0,	13,	getFirstNonBlank_LOOP
	beq	$t0,	35,	getFirstNonBlank_SKIPLINE
	j	getFirstNonBlank_NOTBLANK
getFirstNonBlank_SKIPLINE:
	jal	findNextLine
	move	$a0,	$v0
	j	getFirstNonBlank_LOOP
getFirstNonBlank_NOTBLANK:
	addi	$v0,	$a0,	-1
getFirstNonBlank_BLANK:
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	4
	jr	$ra



# fileName* $a0
getFile:
	# Open file
	li	$v0,	13		# system call for open file
	li	$a1,	0		# Open for reading
	li	$a2,	0
	syscall				# open a file (file descriptor returned in $v0)
	move	$t0,	$v0		# save the file descriptor 

	# Read file
	li	$v0,	14	# system call for read from file
	move	$a0,	$t0	# file descriptor 
	la	$a1,	sourceBuffer	# address of buffer to read to
	li	$a2,	1024	# buffer length
	syscall            	# read from file

	# Close file 
	li	$v0,	16	# system call for close file
	move	$a0,	$t0	# file descriptor to close
	syscall			# close file

	move	$v0,	$a1
	jr	$ra

# start $a0
findNextBlank:
	lb	$t0,	0($a0)
	beq	$t0,	0,	findNextBlank_END
	beq	$t0,	10,	findNextBlank_END
	beq	$t0,	13,	findNextBlank_END
	beq	$t0,	35,	findNextBlank_END
	beq	$t0,	32,	findNextBlank_END
	beq	$t0,	9,	findNextBlank_END
	addi	$a0,	$a0,	1
	j	findNextBlank
findNextBlank_END:
	add	$v0,	$a0,	$0
	jr	$ra

# start $a0
findNextLine:
	lb	$t0,	0($a0)
	beq	$t0,	0,	findNextLine_END
	beq	$t0,	10,	findNextLine_END
	beq	$t0,	13,	findNextLine_END
	addi	$a0,	$a0,	1
	j	findNextLine
findNextLine_END:
	add	$v0,	$a0,	$0
	jr	$ra


