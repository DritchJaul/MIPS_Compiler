		.data
format:			.asciiz	"add:R:2310:CA\naddi:I:21:AI\naddiu:I:21:AJ\naddu:R:2310:CB\nand:R:2310:CE\nandi:I:21:AM\nbeq:I:12:AE\nbne:I:12:AF\nj:J:AC\njal:J:AD\njr:R:1000:AI\nlbu:L:CE\nlhu:L:CF\nll:L:DA\nlui:I:01:AP\nlw:L:CD\nnor:R:2310:CH\nor:R:2310:CF\nori:I:21:AN\nslt:R:2310:CK\nslti:I:21:AK\nsltiu:I:21:AL\nsltu:R:2310:CL\nsll:R:0213:AA\nsrl:R:0213:AC\nsb:L:CI\nsc:L:DI\nsh:L:CJ\nsw:L:CL\nsub:R:2310:CC\nsubu:R:2310:CD"
nextOperandCode:	.asciiz " ,\n\r#"
syscallOp:		.asciiz	"syscall"


			.align	2
metaInfo:		.word	0, 0 #instruction number, instruction type

line:			.asciiz	"add $a0, $a1, $a2"

binaryGuide:		.asciiz	"[ OP ][ S ][ T ][ D ][ < ][funct]\n"

newLine:		.asciiz	"\n"
		.text
		.globl	findNext, processLine, stringEquals, findNextEither, convertNumber, ERROR
main:
	
	la	$a0,	line

	jal	processLine
	move	$a0,	$v0
	
	li	$v0,	34
	syscall
	
	move	$t0,	$a0
	la	$a0,	newLine
	li	$v0,	4
	syscall
	
	la	$a0,	binaryGuide
	li	$v0,	4
	syscall
	
	move	$a0,	$t0
	li	$v0,	35
	syscall
	
	li	$v0,	10
	syscall

# lineStart $a0, $a1 lineEnd, instruction number $a2
processLine:
	la	$t0,	metaInfo
	sw	$a2,	0($t0)
	
	addi	$sp,	$sp,	-4
	sw	$ra,	0($sp)
	
	addi	$sp,	$sp,	-8
	sw	$s0,	4($sp)
	sw	$s1,	0($sp)
	move	$s0,	$a0
	move	$s1,	$a1

	####################
	move	$a0,	$s0
	jal	findNextBlank
	
	move	$a0,	$s0
	addi	$a1,	$v0,	-1
	la	$a2,	syscallOp
	addi	$a3,	$a2,	6
	jal	stringEquals
	beq	$v0,	1,	returnSyscall
	########################
	
	li	$a1,	32
	jal	findNext
	move	$a0,	$s0
	move	$a1,	$v0
	addi	$a1,	$v0,	-1
	addi	$s0,	$v0,	1
	
	
	la	$a2,	format
	addi	$a3,	$a2,	364

	jal	findFormat
	beq	$v0,	$v1,	ERROR
	
	move	$a0,	$s0
	move	$a1,	$s1
	addi	$a2,	$v0,	2
	move	$a3,	$v1

	lb	$t0,	0($v0)
	
	beq	$t0,	82,	convertR
	beq	$t0,	73,	convertI
	beq	$t0,	76,	convertL
	beq	$t0,	74,	convertJ
processLine_RETURN:
	lw	$s1,	0($sp)
	lw	$s0,	4($sp)
	addi	$sp,	$sp,	8
	
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	4
	jr	$ra



# textStart $a0, textEnd $a1, formatStart $a2, formatEnd $a3
convertJ:
	la	$t0,	metaInfo	# Define the type of instruction for labeling
	li	$t1,	3
	sw	$t1,	4($t0)
	

	addi	$sp,	$sp,	-4
	sw	$s2,	0($sp)
	
	move	$s0,	$a0
	move	$s1,	$a2
	li	$s2,	0
	
	li	$a1,	1
	move	$a0,	$s0
	jal	getOperand
	or 	$s2, 	$v0, 	$s2

	lb 	$a1, 	0($s1)
	addi	$a1,	$a1,	-65
	sll	$a1,	$a1,	30
	or 	$s2, 	$a1, 	$s2
	lb 	$a1, 	1($s1)
	addi	$a1,	$a1,	-65
	sll	$a1,	$a1,	26
	or 	$s2, 	$a1, 	$s2
	
	move	$v0,	$s2
	
	lw	$s2,	0($sp)
	addi	$sp,	$sp,	4
	
	j	processLine_RETURN


# textStart $a0, textEnd $a1, formatStart $a2, formatEnd $a3
convertL:

	la	$t0,	metaInfo	# Define the type of instruction for labeling
	li	$t1,	2
	sw	$t1,	4($t0)

	addi	$sp,	$sp,	-4	#save $s2 because we need it
	sw	$s2,	0($sp)
	
	move	$s0,	$a0
	move	$s1,	$a2
	li	$s2,	0
	
	li	$a1,	1	# find, convert, rt (which is operand 1)
	move	$a0,	$s0
	jal	getOperand
	sll 	$v0, 	$v0, 	16	# shift it to the rt spot
	or 	$s2, 	$v0, 	$s2

	lb 	$a1, 	0($s1)		# Convert the opcode from the format
	addi	$a1,	$a1,	-65
	sll	$a1,	$a1,	30
	or 	$s2, 	$a1, 	$s2	
	lb 	$a1, 	1($s1)
	addi	$a1,	$a1,	-65
	sll	$a1,	$a1,	26	# shift it to the opcode spot
	or 	$s2, 	$a1, 	$s2

	move	$a0,	$s0
	li	$a1,	32	# Find the first space in the text
	jal	findNext
	move	$s1,	$v0
	move	$a0,	$s0
	li	$a1,	40	# Find the open parenthesis
	jal	findNext	
	
	addi	$a0,	$s1,	1
	addi	$a1,	$v0,	-1	# Between those two things lies the immediate e.g "lw $s0, XXX($s0)"
	jal	convertNumber
	and	$v0,	$v0,	0x0000FFFF
	or 	$s2, 	$v0, 	$s2
	
	
	
	move	$a0,	$s0
	li	$a1,	40	# Find the open parenthesis
	jal	findNext
	move	$s1,	$v0
	move	$a0,	$s0
	li	$a1,	41	# Find the closed parenthesis
	jal	findNext
	addi	$a1,	$v0,	-1
	addi	$a0,	$s1,	1
	jal	convertOperand		# Between those two things lies RS
	sll 	$v0,	$v0, 	21	# Shift rs to its correct placement
	or 	$s2, 	$v0, 	$s2
	
	move	$v0,	$s2
	
	lw	$s2,	0($sp)
	addi	$sp,	$sp,	4
	
	j	processLine_RETURN



# textStart $a0, textEnd $a1, formatStart $a2, formatEnd $a3 
convertI:

	la	$t0,	metaInfo	# Define the type of instruction for labeling
	li	$t1,	2
	sw	$t1,	4($t0)


	addi	$sp,	$sp,	-4
	sw	$s2,	0($sp)

	
	move	$s0,	$a0
	move	$s1,	$a2
	li	$s2,	0
	
	lb 	$a1, 	0($s1)
	addi	$a1,	$a1,	-48
	move	$a0,	$s0
	jal	getOperand
	sll 	$v0,	$v0, 	21
	or 	$s2, 	$v0, 	$s2
	
	lb 	$a1, 	1($s1)
	addi	$a1,	$a1,	-48
	move	$a0,	$s0
	jal	getOperand
	sll 	$v0, 	$v0, 	16
	or 	$s2, 	$v0, 	$s2

	lb 	$a1, 	3($s1)	# Convert Opcode
	addi	$a1,	$a1,	-65
	sll	$a1,	$a1,	30
	or 	$s2, 	$a1, 	$s2
	lb 	$a1, 	4($s1)
	addi	$a1,	$a1,	-65
	sll	$a1,	$a1,	26
	or 	$s2, 	$a1, 	$s2

	lb	$t0,	3($s1)	# Check if Opcode is LUI
	sll	$t0,	$t0	16
	lb	$t1,	4($s1)
	or	$t0,	$t0,	$t1
	beq	$t0,	0x00410050,	convertI_LUI
	
	li	$a1,	3	# If it's not LUI convert the last operand
	move	$a0,	$s0
	jal	getOperand
	or 	$s2, 	$v0, 	$s2
	
	j	convertI_END
convertI_LUI:
	li	$a1,	2
	move	$a0,	$s0
	jal	getOperand
	or 	$s2, 	$v0, 	$s2
convertI_END:
	move	$v0,	$s2
	

	lw	$s2,	0($sp)
	addi	$sp,	$sp,	4
	
	j	processLine_RETURN




# textStart $a0, textEnd $a1, formatStart $a2, formatEnd $a3 
convertR:

	la	$t0,	metaInfo	# Define the type of instruction for labeling
	li	$t1,	1
	sw	$t1,	4($t0)


	addi	$sp,	$sp,	-4
	sw	$s2,	0($sp)

	move	$s0,	$a0
	move	$s1,	$a2
	li	$s2,	0

	lb 	$a1, 	0($s1)
	addi	$a1,	$a1,	-48
	move	$a0,	$s0
	jal	getOperand
	sll 	$v0,	$v0, 	21
	or 	$s2, 	$v0, 	$s2
	
	lb 	$a1, 	1($s1)
	addi	$a1,	$a1,	-48
	move	$a0,	$s0
	jal	getOperand
	sll 	$v0, 	$v0, 	16
	or 	$s2, 	$v0, 	$s2


	lb 	$a1, 	2($s1)
	addi	$a1,	$a1,	-48
	move	$a0,	$s0
	jal	getOperand
	sll 	$v0, 	$v0, 	11
	or 	$s2, 	$v0, 	$s2

	lb 	$a1, 	3($s1)
	addi	$a1,	$a1,	-48
	move	$a0,	$s0
	jal	getOperand
	sll 	$v0, 	$v0, 	6
	or 	$s2, 	$v0, 	$s2
	
	lb 	$a1, 	5($s1)
	addi	$a1,	$a1,	-65
	sll	$a1,	$a1,	4
	or 	$s2, 	$a1, 	$s2
	lb 	$a1, 	6($s1)
	addi	$a1,	$a1,	-65
	or 	$s2, 	$a1, 	$s2

	move	$v0,	$s2
	
	lw	$s2,	0($sp)
	addi	$sp,	$sp,	4
	
	j	processLine_RETURN



# textStart $a0, Nth-Operand $a1
getOperand:
	addi	$sp,	$sp,	-4
	sw	$ra,	0($sp)
	
	li	$v0,	0
	beq	$a1,	0,	getOperand_END
	move	$a2,	$a1
getOperand_LOOP:
	beq	$a2,	1,	getOperand_OP
	addi	$a2,	$a2,	-1
	li	$a1,	44
	jal	findNext
	addi	$a0,	$v0,	2
	j	getOperand_LOOP
getOperand_OP:
	addi	$sp,	$sp,	-4
	sw	$a0,	0($sp)
	la	$a1,	nextOperandCode
	jal	findNextOp

	addi	$a1,	$v0,	-1
	lw	$a0,	0($sp)
	addi	$sp,	$sp,	4
	jal	convertOperand
getOperand_END:
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	4
	jr	$ra
	
	
	
	
	
	
	
	
	
# opStart $a0, opEnd $a1
convertOperand:
	addi	$sp,	$sp,	-4
	sw	$ra,	0($sp)

	lb	$t0,	0($a0)
	beq	$t0,	36,	convertOperand_REGISTER
	jal	convertNumber
	and	$v0,	$v0,	0x0000FFFF # only return first 16 bits
	j	convertOperand_RETURN

convertOperand_REGISTER:
	lb	$t0,	2($a0)
	slti	$t1,	$t0,	58
	slti	$t2,	$t0,	56
	slti	$t0,	$t0,	48
	add	$t0,	$t0,	$t1
	add	$t0,	$t0,	$t2
	beq	$t0,	2,	convertOperand_NUMBERED
	beq	$t0,	1,	convertOperand_NUMBERED_t89
	
	lb	$t0,	1($a0)
	
	li	$v0,	0
	beq	$t0,	48,	convertOperand_RETURN
	
	li	$v0,	1
	beq	$t0,	97,	convertOperand_RETURN
	
	li	$v0,	28
	beq	$t0,	103,	convertOperand_RETURN
	
	li	$v0,	29
	beq	$t0,	115,	convertOperand_RETURN
	
	li	$v0,	30
	beq	$t0,	102,	convertOperand_RETURN
	
	li	$v0,	31
	beq	$t0,	114,	convertOperand_RETURN
	
	
convertOperand_NUMBERED:
	lb	$t1,	1($a0)
	
	li	$t0,	2
	beq	$t1,	118,	convertOperand_NUMBERED_END # v
	
	li	$t0,	4
	beq	$t1,	97,	convertOperand_NUMBERED_END # a
	
	li	$t0,	8
	beq	$t1,	116,	convertOperand_NUMBERED_END # t 0-7
	
	li	$t0,	16
	beq	$t1,	115,	convertOperand_NUMBERED_END # s
	
	li	$t0,	26
	beq	$t1,	107,	convertOperand_NUMBERED_END # k
	
convertOperand_NUMBERED_t89: 
	li	$t0,	16 # t 8-9
	
convertOperand_NUMBERED_END:
	lb	$t1,	2($a0)
	addi	$t1,	$t1,	-48
	add	$t0,	$t1,	$t0
	move	$v0,	$t0
	j	convertOperand_RETURN
	
convertOperand_RETURN:
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	4
	jr	$ra




# textStart $a0, textEnd $a1,
convertLabel:

	la	$t0,	labelRefBuffer
convertLabel_LOOP:
	lw	$t1,	0($t0)
	addi	$t0,	$t0,	4
	bnez	$t1,	convertLabel_LOOP
	addi	$t0,	$t0,	-4
	
	la	$t1,	metaInfo
	lw	$t2,	0($t1)
	
	sw	$t2,	0($t0)
	sw	$a0,	4($t0)
	sw	$a1,	8($t0)
	lw	$t2,	4($t1)
	sw	$t2,	12($t0)

	jr	$ra





# textStart $a0, textEnd $a1,
convertNumber:
	addi	$sp,	$sp,	-12
	sw	$a1,	8($sp)
	sw	$a0,	4($sp)
	sw	$ra,	0($sp)
	move	$v0,	$0
	lb	$t0,	0($a0)
	bne	$t0,	45,	convertNumber_LOOP
	addi	$a0,	$a0,	1
	
convertNumber_LOOP:
	bgt	$a0,	$a1,	convertNumber_END
	lb	$t0,	0($a0)
	addi	$t0,	$t0,	-48
	
	blt	$t0,	0,	convertNumber_LABEL
	bgt	$t0,	9,	convertNumber_LABEL
	
	sll	$t1,	$v0,	3
	sll	$v0,	$v0,	1
	add	$v0,	$t1,	$v0
	add	$v0,	$v0,	$t0
	addi	$a0,	$a0,	1
	j	convertNumber_LOOP

convertNumber_LABEL:	#If the number is a label
	lw	$ra,	0($sp)
	lw	$a0,	4($sp)
	lw	$a1,	8($sp)
	addi	$sp,	$sp,	12
	
	addi	$sp,	$sp,	-4
	sw	$ra,	0($sp)
	jal	convertLabel
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	4
	j	convertNumber_END2

convertNumber_END:
	lw	$ra,	0($sp)
	lw	$a0,	4($sp)
	lw	$a1,	8($sp)
	addi	$sp,	$sp,	12
	
	lb	$t0,	0($a0)		# negative number conversion
	bne	$t0,	45,	convertNumber_END2
	nor	$v0,	$v0,	$0
	addi	$v0,	$v0,	1

convertNumber_END2:
	jr	$ra


# startString $a0, endString $a1, startFormat $a2
findFormat:
	addi	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)
	sw	$s2,	12($sp)
	sw	$s3,	16($sp)
	
	move	$s0,	$a0
	move	$s1,	$a1
	
	move	$s2,	$a2
	
	sub	$s3,	$s1,	$s0
	add	$s3,	$s3,	$s2
	
findFormat_LOOP:
	
	move	$a0,	$s0
	move	$a1,	$s1
	move	$a2,	$s2
	move	$a3,	$s3
	
	jal	stringEquals
	
	li	$t0,	1
	beq	$t0,	$v0,	findFormat_END_found
	
	move	$a0,	$s2
	li	$a1,	10
	li	$a2,	0
	
	jal	findNextEither
	lb	$t0,	0($v0)
	beq	$t0,	$0,	findFormat_END_notFound
	
	addi	$s2,	$v0,	1
	
	sub	$s3,	$s1,	$s0
	add	$s3,	$s3,	$s2

	j	findFormat_LOOP

findFormat_END_found:
	move	$a0,	$s2
	li	$a1,	10
	li	$a2,	0
	jal	findNextEither
	
	addi	$v1,	$v0,	-1
	addi	$v0,	$s3,	2
	j	findFormat_END
findFormat_END_notFound:
	li	$v0,	0
	li	$v1,	0
	j	findFormat_END
findFormat_END:
	lw	$s3,	16($sp)
	lw	$s2,	12($sp)
	lw	$s1,	8($sp)
	lw	$s0,	4($sp)
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	20
	jr	$ra









# str1Start $a0, str1End $a1, str2Start $a2, str2End $a3
stringEquals:
	li	$v0,	0
	sub	$t0,	$a1,	$a0
	sub	$t1,	$a3,	$a2
	bne	$t0,	$t1,	stringEquals_END_false
stringEquals_LOOP:
	lb	$t0,	0($a0)
	lb	$t1,	0($a2)
	bne	$t0,	$t1,	stringEquals_END_false
	addi	$a0,	$a0,	1
	addi	$a2,	$a2,	1
	bgt	$a0,	$a1,	stringEquals_END_true
	bgt	$a2,	$a3,	stringEquals_END_true
	j	stringEquals_LOOP
stringEquals_END_true:
	li	$v0,	1
stringEquals_END_false:
	jr	$ra




# start $a0
findNextOp:
	la	$t0,	nextOperandCode
	lb	$t2,	0($a0)
	beqz	$t2,	findNextOp_END
findNextOp_Loop:
	lb	$t1,	0($t0)
	beqz	$t1,	findNextOp_Loop_END
	beq	$t1,	$t2,	findNextOp_END
	addi	$t0,	$t0,	1
	j	findNextOp_Loop
findNextOp_Loop_END:
	addi	$a0,	$a0,	1
	j	findNextOp
findNextOp_END:
	move	$v0,	$a0
	jr	$ra
	
	


# start $a0, char $a1, char $a2
findNextEither:
	lb	$t0,	0($a0)
	beq	$t0,	$a1,	findNextEither_END
	beq	$t0,	$a2,	findNextEither_END
	addi	$a0,	$a0,	1
	j	findNextEither
findNextEither_END:
	add	$v0,	$a0,	$0
	jr	$ra

# start $a0, char $a1
findNext:
	lb	$t0,	0($a0)
	beq	$t0,	$a1,	findNext_END
	addi	$a0,	$a0,	1
	j	findNext
findNext_END:
	add	$v0,	$a0,	$0
	jr	$ra
	


returnSyscall:
	li	$v0,	0x0000000C
	j	processLine_RETURN


	
ERROR:
	li	$v0,	10
	syscall
