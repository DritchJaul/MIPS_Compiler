	.data
		.globl	processData
text:		.asciiz	".text"
data:		.asciiz	".data"

align:		.asciiz	".align"
ascii:		.asciiz	".ascii"
asciiz:		.asciiz	".asciiz"
byte:		.asciiz	".byte"
space:		.asciiz	".space"
word:		.asciiz	".word"
	

	.text
	
	

	
	
# $v0 = sourceBuffer, $v1 = labelBuffer, $a0 = dataBuffer end
processData:	#Function to be made 1
	addi	$sp,	$sp,	-20
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)
	sw	$s2,	12($sp)
	sw	$s3,	16($sp)
	
	move	$s0,	$a0	# s0 = source
	move	$s1,	$a0	# s1 = source2
	move	$s2,	$a1	# s2 = data
	move	$s3,	$a2	# s3 = label
processData_LOOP:
	move	$a0,	$s0
	addi	$a1,	$s0,	1024
	jal	getFirstNonBlank
	move	$s0,	$v0
	
	lb	$t0,	0($s0)
	beq	$t0,	0,	processData_TEXT_END
	
	
	move	$a0,	$s0
	jal	findNextLineNew
	move	$s1,	$v0
	
	move	$a0,	$s0
	move	$a1,	$s1
	jal	getLastNonBlank
	move	$s1,$v0
	
	move	$a0,	$s0
	move	$a1,	$s1
	la	$a2,	data
	addi	$a3,	$a2,	4
	jal	stringEquals
	beq	$v0,	1,	processData_DATA
	
	move	$a0,	$s0
	move	$a1,	$s1
	la	$a2,	text
	addi	$a3,	$a2,	4
	jal	stringEquals
	beq	$v0,	1,	processData_TEXT_END
	
	move	$a0,	$s0
	move	$a1,	$s1
	move	$a2,	$s2
	move	$a3,	$s3
	jal	processDataLine
	move	$s2,	$v0
	move	$s3,	$v1
	
	
	
processData_DATA:
	addi	$s0,	$s1,	1
	j	processData_LOOP
	
processData_TEXT_END:
	addi	$v0,	$s1,	1
	move	$v1,	$s3
	move	$a0,	$s2	#Non standard Return method, but needed.
	
	lw	$s3,	16($sp)
	lw	$s2,	12($sp)
	lw	$s1,	8($sp)
	lw	$s0,	4($sp)
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	20
	jr	$ra


processData_ERROR:
	li	$v0,	10
	syscall	
	
#------------------------------------------------	
	
findNextLineNew:
	lb	$t0,	0($a0)
	beq	$t0,	0,	findNextLineNew_END
	beq	$t0,	10,	findNextLineNew_END
	beq	$t0,	13,	findNextLineNew_END
	beq	$t0,	35,	findNextLineNew_END
	addi	$a0,	$a0,	1
	j	findNextLineNew
findNextLineNew_END:
	addi	$v0,	$a0,	-1
	jr	$ra	
#------------------------------------------------
getLastNonBlank:
	move 	$v0,	 $a1
getLastNonBlank_LOOP:
	blt 	$a1,	 $a0, 	getLastNonBlank_BLANK
	lb 	$t0,	 0($a1)
	addi 	$a1,	 $a1,	 -1
	beq 	$t0,	 32,	 getLastNonBlank_LOOP
	beq 	$t0,	 9, 	getLastNonBlank_LOOP
	beq 	$t0,	 10,	 getLastNonBlank_LOOP
	beq 	$t0,	 13, 	getLastNonBlank_LOOP
	j 	getLastNonBlank_NOTBLANK
getLastNonBlank_NOTBLANK:
	addi 	$v0,	 $a1,	1
getLastNonBlank_BLANK:
	jr	 $ra
#-------------------------------------------------------------	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
#	$a0 is line start, $a1 is line end, $a2 is databuffer, $a3 is labelBuffer
processDataLine:	# Function to be made 2
	addi	$sp,	$sp,	-12 
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)	
	sw	$s1,	8($sp)
	
	move	$s0,	$a0			#	s0 is start
	move	$s1,	$a1	
	move	$s2,	$a2			#	s1 is end
	
	li	$a1,	58	
	li	$a2,	46			#	find : or .
	jal findNextEither
	addi	$t0,	$v0,	0
	move	$a2,	$s2
	
	lb	$t1,	0($t0)
	beq	$t1,	46,	processDataLine_NOLBL
	#addi	$t0,	$v0,	-1
	lb	$t1,	0($t0)
	bne	$t1,	58,	processDataLine_ERR	# if no : , error
	
	addi	$s5,	$s5,	1
	
	move	$t5,	$a2
	
	sll	$t1,	$s5,	2
	addi	$t1,	$t1,	0x10010000
	move	$a2,	$t1
	
	move	$a0,	$s0			#	adds label
	move	$a1,	$t0
	jal	addLabel
	move	$s6,	$v0
	
	
	move	$a2,	$t5
	
	li	$a1,	46		#	finds .	
	jal findNext
	addi	$t0,	$v0,	1	
	lb	$t1,	0($t0)		#loads first char after .
	
	beq	$t1,	119,	processDataLine_WORD	# if w
	beq	$t1,	98,	processDataLine_BYTE	# if b
	beq	$t1,	115,	processDataLine_SPACE	# if s
	bne	$t1,	97,	processDataLine_ERR	# if not a
	
	addi	$t0,	$t0,	5			#goes to last letter of ascii(z)
	lb	$t1,	0($t0)
	
	beq	$t1,	122,	processDataLine_ASCIIZ	# if last letter is z
	beq	$t1,	32,	processDataLine_ASCII	# if last letter is _
	beq	$t1,	9,	processDataLine_ASCII	# if last letter is tab
	move	$v1,	$s6
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	addi	$sp,	$sp,	12
	jr	$ra
	
processDataLine_NOLBL:
	addi	$t0,	$t0,	1
	lb	$t1,	0($t0)
	
	beq	$t1,	97,	processDataLine_ALIGN	#if al
	
processDataLine_ERR:	#gets called if no label is found ( no ':' is found )
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	addi	$sp,	$sp,	12
	jr	$ra
processDataLine_WORD:
	addi	$t0,	$t0,	4
	move	$a0,	$t0
	move	$a1,	$s1
	jal 	getFirstNonBlank
	addi	$a0,	$v0,	0
	jal	processWord
	
	move	$v1,	$s6
	move	$v1,	$s6
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	addi	$sp,	$sp,	12
	jr	$ra

processDataLine_BYTE:
	addi	$t0,	$t0,	4
	move	$a0,	$t0
	move	$a1,	$s1
	jal 	getFirstNonBlank
	addi	$a0,	$v0,	0
	jal	processByte
	
	move	$v1,	$s6
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	addi	$sp,	$sp,	12
	jr	$ra

processDataLine_SPACE:
	addi	$t0,	$t0,	5
	move	$a0,	$t0
	move	$a1,	$s1
	jal 	getFirstNonBlank
	addi	$a0,	$v0,	0
	jal	processSpace
	move	$v1,	$s6
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	addi	$sp,	$sp,	12
	jr	$ra
processDataLine_ALIGN:
	addi	$t0,	$t0,	4
	move	$a0,	$t0
	move	$a1,	$s1
	jal 	getFirstNonBlank
	addi	$a0,	$v0,	0
	jal	processAlign
	move	$v1,	$s6
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	addi	$sp,	$sp,	12
	jr	$ra
processDataLine_ASCII:
	move	$a0,	$t0
	move	$a1,	$s1
	jal 	getFirstNonBlank
	addi	$a0,	$v0,	0
	jal	processAscii
	move	$v1,	$s6
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	addi	$sp,	$sp,	12
	jr	$ra
processDataLine_ASCIIZ:
	addi	$t0,	$t0,	1
	move	$a0,	$t0
	move	$a1,	$s1
	jal 	getFirstNonBlank
	addi	$a0,	$v0,	0
	jal	processAsciiz
	move	$v1,	$s6
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	addi	$sp,	$sp,	12
	jr	$ra
	

processByte:
	addi	$sp,	$sp,	-4	
	sw	$ra,	0($sp)
	
	move	$t3,	$a0
	li	$a1,	44
	jal	findNextInLine
	move	$t4,	$v0
	move	$a0,	$t3
	
	beq	$t4,	-1,	processByte_END
processByte_LOOP:

	addi	$a1,	$t4,	-1	
	jal	convertNumber
	move	$t6,	$v0
	jal processByte_TRUNC
	sb	$t7,	0($a2)
	addi	$a2,	$a2,	1
	
	addi	$a0,	$a1,	3
	
	move	$t3,	$a0
	li	$a1,	44
	jal	findNextInLine
	move	$t4,	$v0
	move	$a0,	$t3
	
	beq	$t4,	-1,	processByte_END
	
	j	processByte_LOOP
processByte_TRUNC:
	li	$t5,	256
	div	$t6,	$t5
	mfhi	$t7
	
	jr $ra
processByte_END:
	addi	$a1,	$s1,	0
	jal	convertNumber
	move	$t6,	$v0
	jal processByte_TRUNC
	sb	$t7,	0($a2)
	addi	$v0,	$a2,	1
	
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	4	
	jr	$ra

	
processWord:	
	addi	$sp,	$sp,	-4	
	sw	$ra,	0($sp)
	
	move	$t3,	$a0
	li	$a1,	44
	jal	findNextInLine
	move	$t4,	$v0
	move	$a0,	$t3
	
	beq	$t4,	-1,	processWord_END
	
processWord_LOOP:
	jal wordAlign
	move	$a2,	$v0

	addi	$a1,	$t4,	-1
	jal	convertNumber
	sw	$v0,	0($a2)
	addi	$a2,	$a2,	4
	
	addi	$a0,	$a1,	3
	
	move	$t3,	$a0
	li	$a1,	44
	jal	findNextInLine
	move	$t4,	$v0
	move	$a0,	$t3
	
	beq	$t4,	-1,	processWord_END
	
	j	processWord_LOOP

processWord_END:
	
	jal wordAlign
	move	$a2,	$v0

	addi	$a1,	$s1,	0
	jal	convertNumber
	sw	$v0,	0($a2)
	addi	$v0,	$a2,	4
	
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	4	
	jr	$ra



# takes pointer of databuffer, $a2, and finds the next open word block, returns address in $v0	
wordAlign:
	addi	$t0,	$a2,	0
	li	$t1,	4
	
	j	wordAlign_LOOP
	
wordAlign_LOOP:
	div	$t0,	$t1
	
	mfhi	$t2
	beq	$t2,	0,	wordAlign_END
	
	addi	$t0,	$t0,	1
	
	j	wordAlign_LOOP
	
wordAlign_END:
	addi	$v0,	$t0,	0
	
	jr $ra


findNextInLine:
	lb	$t0,	0($a0)
	beq	$t0,	$a1,	findNextInLine_END
	bge	$a0,	$s1,	findNextInLine_FAIL
	addi	$a0,	$a0,	1
	j	findNextInLine
findNextInLine_END:
	add	$v0,	$a0,	$0
	jr	$ra
findNextInLine_FAIL:
	add	$v0,	$0,	-1
	jr	$ra







processAsciiz:
	addi	$sp,	$sp,	-16	
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)
	sw	$s2,	12($sp)	

	move	$s0,	$a0
	move	$s1,	$a1
	move	$s2,	$a2
	jal	processAscii
	sb	$0,	1($v0)
	addi	$v0,	$v0,	1
	
	lw	$s2,	12($sp)	
	lw	$s1,	8($sp)
	lw	$s0,	4($sp)
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	16
	jr	$ra
	
# inputs: argumentString $a0-$a1, dataBuffer $a2
# returns: dataBuffer $v0	
	
processAscii:	
	addi	$sp,	$sp,	-16	
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)
	sw	$s2,	12($sp)	
	
	move	$s0,	$a0
	move	$s1,	$a1
	move	$s2,	$a2
	
	lb	$t0,	0($s0)
	bne	$t0,	34,	ERROR
	addi	$s0,	$s0,	1
	
	lb	$t0,	0($s1)
	bne	$t0,	34,	ERROR
	addi	$s1,	$s1,	-1
	
processAscii_LOOP:
	bgt	$s0,	$s1,	processAscii_END
	
	lb	$t0,	0($s0)
	bne	$t0,	92,	processAscii_Continue
	
processAscii_Escape:
	addi	$s0,	$s0,	1
	lb	$t1,	0($s0)
	
	li	$t0,	10	# \n
	beq	$t1,	110,	processAscii_Continue
	
	li	$t0,	9	# \t
	beq	$t1,	116,	processAscii_Continue
		
	li	$t0,	13	# \r
	beq	$t1,	114,	processAscii_Continue
	
	li	$t0,	92	# \\
	beq	$t1,	92,	processAscii_Continue

	li	$t0,	34	# \"
	beq	$t1,	34,	processAscii_Continue
	
processAscii_Continue:
	
	sb	$t0,	0($s2)
	addi	$s0,	$s0,	1
	addi	$s2,	$s2,	1
	j	processAscii_LOOP
processAscii_END:

	move	$v0,	$s2

	lw	$s2,	12($sp)	
	lw	$s1,	8($sp)
	lw	$s0,	4($sp)
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	16
	jr	$ra





	
	
processSpace:	
	addi	$sp,	$sp,	-4	
	sw	$ra,	0($sp)

	jal	convertNumber
	add	$v0,	$a2,	$v0

	lw	$ra,	0($sp)
	addi	$sp,	$sp,	4	
	jr	$ra
	
	


processAlign:	
	addi	$sp,	$sp,	-4
	sw	$ra,	0($sp)

	lb	$t1,	0($a0)
	addi	$t1,	$t1,	-48
	

	move	$t2,$a2
		
	li	$t0,0x00000000
	beq	$t1,0,processAlign_LOOP
		
	li	$t0,0x00000001
	beq	$t1,1,processAlign_LOOP
		
	li	$t0,0x00000003
	beq	$t1,2,processAlign_LOOP
		
	li	$t0,0x00000007
	beq	$t1,3,processAlign_LOOP
		
	#$t0 = 0x00000...
	#$t1 = .align value
	#$t2 = buffer address
	#$t3 = whatever you get when you compare $t0 and $t2
processAlign_LOOP:
	and	$t3,$t0,$t2		#$compare $t2 with 0x0000...whatever; 
	beq	$t3,0,processAlign_END	#if the comparison returns 0, it is aligned
	addi	$t2,$t2,1		#if the comparison is not 0, add 1 to $t2 repeatedly until it is
	j	processAlign_LOOP
		
processAlign_END:
	move	$v0,$t2			#return the aligned address

	lw	$ra,	0($sp)
	addi	$sp,	$sp,	4	# Retrieve $ra and jump back
	jr	$ra







