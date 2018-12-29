; TECO2_DV (file:teco2_DV.asm)
;
; Version:	1.0
; Author:	John Pultorak
; Date:		9/14/2001
;
; PURPOSE:
; Test and checkout program for the Block 1 Apollo Guidance Computer.
; Tests extracode instructions: DV
;
; OPERATION:
; Enters an infinite loop at the end of the test. The A register contains 
; the code for the test that failed, or the PASS code if all tests 
; succeeded. See test codes below.
;
; ERRATA:
; - Written for the AGC4R assembler. The assembler directives and syntax
; differ somewhat from the original AGC assembler.
; - The tests attempt to check all threads, but are not exhaustive.
;
; SOURCES:
; Information on the Block 1 architecture: instruction set, instruction
; sequences, registers, register transfers, control pulses, memory and 
; memory addressing, I/O assignments, interrupts, and involuntary counters
; was obtained from:
;
;	A. Hopkins, R. Alonso, and H. Blair-Smith, "Logical Description 
;		for the Apollo Guidance Computer (AGC4)", R-393, 
;		MIT Instrumentation Laboratory, Cambridge, MA, Mar. 1963.
;
; Supplementary information was obtained from:
;
;	R. Alonso, J. H. Laning, Jr. and H. Blair-Smith, "Preliminary 
;		MOD 3C Programmer's Manual", E-1077, MIT Instrumentation 
;		Laboratory, Cambridge, MA, Nov. 1961.
;
;	B. I. Savage and A. Drake, "AGC4 Basic Training Manual, Volume I", 
;		E-2052, MIT Instrumentation Laboratory, Cambridge, 
;		MA, Jan. 1967.
;
;	E. C. Hall, "MIT's Role in Project Apollo, Volume III, Computer 
;		Subsystem", R-700, MIT Charles Stark Draper Laboratory, 
;		Cambridge, MA, Aug. 1972.
;
;	A. Hopkins, "Guidance Computer Design, Part VI", source unknown.
;
;	A. I. Green and J. J. Rocchio, "Keyboard and Display System Program 
;		for AGC (Program Sunrise)", E-1574, MIT Instrumentation 
;		Laboratory, Cambridge, MA, Aug. 1964.
;
;	E, C. Hall, "Journey to the Moon: The History of the Apollo 
;		Guidance Computer", AIAA, Reston VA, 1996.
;


START		EQU	%00

DVtst		EQU	%02	; DV check failed

PASS		EQU	%12345	; PASSED all checks
	; ----------------------------------------------

		ORG	EXTENDER
		DS	%47777	; needed for EXTEND

OVFCNTR		EQU	%00034	; overflow counter

	; ----------------------------------------------
	; ERASEABLE MEMORY -- DATA SEGMENT

		ORG	%100	; start of data area
curtest		DS	START	; current test
savQ		DS	%0

	; DV test
DVsavA		DS	%0
DVindex		DS	%0
DVXTND		DS	%0	; indexed extend

	; ----------------------------------------------
	; ENTRY POINTS

	; program (re)start
		ORG	GOPROG
		TC	goMAIN

	; ----------------------------------------------
	; FIXED MEMORY -- SHARED DATA SEGMENT

	; ----------------------------------------------
	; MAIN PROGRAM

goMAIN		EQU	*
		INHINT		; disable interrupts

		TCR	begin

	; Test extracode instructions.
		TCR	chkDV

	; Passed all tests.
		TCR	finish

fail		EQU	*
		XCH	curtest	; load last passed test into A
		TS	curtest

end		EQU	*
		TC	end	; finished, TC trap

	; ----------------------------------------------
	; INITIALIZE FOR START OF TESTING

STRTcode	DS	START

begin		EQU	*
		XCH	STRTcode
		TS	curtest	; set current test code to START
		RETURN

	; ----------------------------------------------
	; TEST DV INSTRUCTION SUBROUTINE
	; L:	DV	K
	; Verifies the following:
	; - Set C(A) = b(A) / C(K)
	; - Set C(Q) = - abs(remainder)
	; - Set C(LP) > 0 if quotient is positive
	; - Set C(LP) < 0 if quotient is negative
	; - Take next instruction from L+1

DVcode		DS	DVtst	; code for this test

	; DV test values
	;                          
DVstart		DS	31	; loop DVstart+1 times

	; C(A) test values
div1		EQU	*
		DS	%00000	; check #00 (+0/+0)
		DS	%00000	; check #01 (+0/-0)
		DS	%77777	; check #02 (-0/+0)
		DS	%77777	; check #03 (-0/-0)

		DS	%00000	; check #04 (+0/+1)
		DS	%00000	; check #05 (+0/-1)
		DS	%77777	; check #06 (-0/+1)
		DS	%77777	; check #07 (-0/-1)

		DS	%00000	; check #08 (+0/+16383)
		DS	%00000	; check #09 (+0/-16383)
		DS	%77777	; check #10 (-0/+16383)
		DS	%77777	; check #11 (-0/-16383)

		DS	%37776	; check #12 (+16382/+16383)
		DS	%37776	; check #13 (+16382/-16383)
		DS	%40001	; check #14 (-16382/+16383)
		DS	%40001	; check #15 (-16382/-16383)

		DS	%37777	; check #16 (+16383/+16383)
		DS	%37777	; check #17 (+16383/-16383)
		DS	%40000	; check #18 (-16383/+16383)
		DS	%40000	; check #19 (-16383/-16383)

		DS	%00001	; check #20 (+1/+2)
		DS	%00001	; check #21 (+1/+3)
		DS	%00001	; check #22 (+1/+4)
		DS	%00001	; check #23 (+1/+5)
		DS	%00001	; check #24 (+1/+6)
		DS	%00001	; check #25 (+1/+7)
		DS	%00001	; check #26 (+1/+8)

		DS	%00001	; check #27 (+1/+6)
		DS	%00002	; check #28 (+2/+12)
		DS	%00004	; check #29 (+4/+24)
		DS	%00010	; check #30 (+8/+48)
		DS	%00020	; check #31 (+16/+96)

	; C(K) test values
div2		EQU	*
		DS	%00000	; check #00 (+0/+0)
		DS	%77777	; check #01 (+0/-0)
		DS	%00000	; check #02 (-0/+0)
		DS	%77777	; check #03 (-0/-0)

		DS	%00001	; check #04 (+0/+1)
		DS	%77776	; check #05 (+0/-1)
		DS	%00001	; check #06 (-0/+1)
		DS	%77776	; check #07 (-0/-1)

		DS	%37777	; check #08 (+0/+16383)
		DS	%40000	; check #09 (+0/-16383)
		DS	%37777	; check #10 (-0/+16383)
		DS	%40000	; check #11 (-0/-16383)

		DS	%37777	; check #12 (+16382/+16383)
		DS	%40000	; check #13 (+16382/-16383)
		DS	%37777	; check #14 (-16382/+16383)
		DS	%40000	; check #15 (-16382/-16383)

		DS	%37777	; check #16 (+16383/+16383)
		DS	%40000	; check #17 (+16383/-16383)
		DS	%37777	; check #18 (-16383/+16383)
		DS	%40000	; check #19 (-16383/-16383)

		DS	%00002	; check #20 (+1/+2)
		DS	%00003	; check #21 (+1/+3)
		DS	%00004	; check #22 (+1/+4)
		DS	%00005	; check #23 (+1/+5)
		DS	%00006	; check #24 (+1/+6)
		DS	%00007	; check #25 (+1/+7)
		DS	%00010	; check #26 (+1/+8)

		DS	%00006	; check #27 (+1/+6)
		DS	%00014	; check #28 (+2/+12)
		DS	%00030	; check #29 (+4/+24)
		DS	%00060	; check #30 (+8/+48)
		DS	%00140	; check #31 (+16/+96)

	; A = quotient
DVchkA		EQU	*
		DS	%37777	; check #00 (+0/+0)
		DS	%40000	; check #01 (+0/-0)
		DS	%40000	; check #02 (-0/+0)
		DS	%37777	; check #03 (-0/-0)

		DS	%00000	; check #04 (+0/+1)
		DS	%77777	; check #05 (+0/-1)
		DS	%77777	; check #06 (-0/+1)
		DS	%00000	; check #07 (-0/-1)

		DS	%00000	; check #08 (+0/+16383)
		DS	%77777	; check #09 (+0/-16383)
		DS	%77777	; check #10 (-0/+16383)
		DS	%00000	; check #11 (-0/-16383)

		DS	%37776	; check #12 (+16382/+16383)
		DS	%40001	; check #13 (+16382/-16383)
		DS	%40001	; check #14 (-16382/+16383)
		DS	%37776	; check #15 (-16382/-16383)

		DS	%37777	; check #16 (+16383/+16383)
		DS	%40000	; check #17 (+16383/-16383)
		DS	%40000	; check #18 (-16383/+16383)
		DS	%37777	; check #19 (-16383/-16383)

		DS	%20000	; check #20 (+1/+2)
		DS	%12525	; check #21 (+1/+3)
		DS	%10000	; check #22 (+1/+4)
		DS	%06314	; check #23 (+1/+5)
		DS	%05252	; check #24 (+1/+6)
		DS	%04444	; check #25 (+1/+7)
		DS	%04000	; check #26 (+1/+8)

		DS	%05252	; check #27 (+1/+6)
		DS	%05252	; check #28 (+2/+12)
		DS	%05252	; check #29 (+4/+24)
		DS	%05252	; check #30 (+8/+48)
		DS	%05252	; check #31 (+16/+96)

	; Q = remainder
DVchkQ		EQU	*
		DS	%77777	; check #00 (+0/+0)
		DS	%77777	; check #01 (+0/-0)
		DS	%77777	; check #02 (-0/+0)
		DS	%77777	; check #03 (-0/-0)

		DS	%77777	; check #04 (+0/+1)
		DS	%77777	; check #05 (+0/-1)
		DS	%77777	; check #06 (-0/+1)
		DS	%77777	; check #07 (-0/-1)

		DS	%77777	; check #08 (+0/+16383)
		DS	%77777	; check #09 (+0/-16383)
		DS	%77777	; check #10 (-0/+16383)
		DS	%77777	; check #11 (-0/-16383)

		DS	%40001	; check #12 (+16382/+16383)
		DS	%40001	; check #13 (+16382/-16383)
		DS	%40001	; check #14 (-16382/+16383)
		DS	%40001	; check #15 (-16382/-16383)

		DS	%40000	; check #16 (+16383/+16383)
		DS	%40000	; check #17 (+16383/-16383)
		DS	%40000	; check #18 (-16383/+16383)
		DS	%40000	; check #19 (-16383/-16383)

		DS	%77777	; check #20 (+1/+2)
		DS	%77776	; check #21 (+1/+3)
		DS	%77777	; check #22 (+1/+4)
		DS	%77773	; check #23 (+1/+5)
		DS	%77773	; check #24 (+1/+6)
		DS	%77773	; check #25 (+1/+7)
		DS	%77777	; check #26 (+1/+8)

		DS	%77773	; check #27 (+1/+6)
		DS	%77767	; check #28 (+2/+12)
		DS	%77757	; check #29 (+4/+24)
		DS	%77737	; check #30 (+8/+48)
		DS	%77677	; check #31 (+16/+96)

	; LP = sign
DVchkLP		EQU	*
		DS	%00001	; check #00 (+0/+0)
		DS	%40000	; check #01 (+0/-0)
		DS	%40001	; check #02 (-0/+0)
		DS	%00001	; check #03 (-0/-0)

		DS	%00001	; check #04 (+0/+1)
		DS	%40000	; check #05 (+0/-1)
		DS	%40001	; check #06 (-0/+1)
		DS	%00001	; check #07 (-0/-1)

		DS	%00001	; check #08 (+0/+16383)
		DS	%40000	; check #09 (+0/-16383)
		DS	%40001	; check #10 (-0/+16383)
		DS	%00001	; check #11 (-0/-16383)

		DS	%00001	; check #12 (+16382/+16383)
		DS	%40000	; check #13 (+16382/-16383)
		DS	%40001	; check #14 (-16382/+16383)
		DS	%00001	; check #15 (-16382/-16383)

		DS	%00001	; check #16 (+16383/+16383)
		DS	%40000	; check #17 (+16383/-16383)
		DS	%40001	; check #18 (-16383/+16383)
		DS	%00001	; check #19 (-16383/-16383)

		DS	%00001	; check #20 (+1/+2)
		DS	%00001	; check #21 (+1/+3)
		DS	%00001	; check #22 (+1/+4)
		DS	%00001	; check #23 (+1/+5)
		DS	%00001	; check #24 (+1/+6)
		DS	%00001	; check #25 (+1/+7)
		DS	%00001	; check #26 (+1/+8)

		DS	%00001	; check #27 (+1/+6)
		DS	%00001	; check #28 (+2/+12)
		DS	%00001	; check #29 (+4/+24)
		DS	%00001	; check #30 (+8/+48)
		DS	%00001	; check #31 (+16/+96)


chkDV		EQU	*
		XCH	Q
		TS	savQ	; save return address

		CAF	DVcode
		TS	curtest	; set code identifying current test


		; Decrementing loop
		;	- always executes at least once (tests at end of loop)		
		;	- loops 'DVstart+1' times; decrements DVindex
		XCH	DVstart	; initialize loop counter

		;------------------------------

		; DV check starts here
		; uses DVindex to access test values
DVloop		EQU	*
		TS	DVindex	; save new index

		CAF	EXTENDER
		AD	DVindex
		TS	DVXTND

		INDEX	DVindex
		CAF	div1
		INDEX	DVXTND	; EXTEND using DVindex
		DV	div2
		TS	DVsavA
		
	; verify C(Q)
		CS	Q	; get -A
		INDEX	DVindex
		AD	DVchkQ	; put (-A) + expected value in A
		CCS	A	; compare
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

	; verify C(A)
		CS	DVsavA	; get -A
		INDEX	DVindex
		AD	DVchkA	; put (-A) + expected value in A
		CCS	A	; compare
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

	; verify C(LP)
		CS	LP	; get -A
		INDEX	DVindex
		AD	DVchkLP	; put (-A) + expected value in A
		CCS	A	; compare
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

		; end of DV check
		;------------------------------

		CCS	DVindex	; done?
		TC	DVloop	; not yet, do next check

		XCH	savQ
		TS	Q	; restore return address
		RETURN

	; ----------------------------------------------
	; PASSED ALL TESTS!

PASScode	DS	PASS

finish		EQU	*
		CAF	PASScode
		TS	curtest	; set current test code to PASS
		RETURN

	; ----------------------------------------------



