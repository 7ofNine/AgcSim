; TECO1_CCS (file:teco1_CCCS.asm)
;
; Version:	1.0
; Author:	John Pultorak
; Date:		9/14/2001
;
; PURPOSE:
; Test and checkout program for the Block 1 Apollo Guidance Computer.
; Tests basic instructions: CCS.
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

CCStst		EQU	%02	; CCS check failed

PASS		EQU	%12345	; PASSED all checks
	; ----------------------------------------------

OVFCNTR		EQU	%00034	; overflow counter

	; ----------------------------------------------
	; ERASEABLE MEMORY -- DATA SEGMENT

		ORG	%100	; start of data area
curtest		DS	START	; current test
savQ		DS	%0

	; CCS test
CCSk		DS	%0

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

	; Test basic instructions.
		TCR	chkCCS

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
	; TEST CCS INSTRUCTION SUBROUTINE
	; L:	CCS	K
	; Verifies the following:
	; - take next instruction from L+n and proceed from there, where:
	; -- n = 1 if C(K) > 0
	; -- n = 2 if C(K) = +0
	; -- n = 3 if C(K) < 0
	; -- n = 4 if C(K) = -0
	; - set C(A) = DABS[C(K)], where DABS (diminished abs value):
	; -- DABS(a) = abs(a) - 1,	if abs(a) > 1
	; -- DABS(a) = +0, 		if abs(a) <= 1

CCScode		DS	CCStst	; code for this test
	; test values (K)
CCSkM2		DS	-2
CCSkM1		DS	-1
CCSkM0		DS	-0
CCSkP0		DS	+0
CCSkP1		DS	+1
CCSkP2		DS	+2

	; expected DABS values
CCSdM2		DS	1 	; for K=-2, DABS = +1
CCSdM1		DS	0	; for K=-1, DABS = +0
CCSdM0		DS	0	; for K=-0, DABS = +0
CCSdP0		DS	0	; for K=+0, DABS = +0
CCSdP1		DS	0	; for K=+1, DABS = +0
CCSdP2		DS	1	; for K=+2, DABS = +1

chkCCS		EQU	*
		XCH	Q
		TS	savQ	; save return address

		CAF	CCScode
		TS	curtest	; set current test code to this test

	; set K to -2 and execute CCS: 
	; check for correct branch
		CAF	CCSkM2	; set K = -2
		TS	CCSk
		CCS	CCSk	; A = DABS[C(K)]
		TC	fail	; K > 0
		TC	fail	; K= +0
		TC	*+2	; K < 0
		TC	fail	; K= -0
	; check for correct DABS in A (for K=-2, it should be 1)
		COM		; 1's compliment of A
		AD	CCSdM2	; put (-A) + expected value in A
		CCS	A	; A = DABS
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

	; set K to -1 and execute CCS: 
	; check for correct branch
		CAF	CCSkM1	; set K = -1
		TS	CCSk
		CCS	CCSk	; A = DABS[C(K)]
		TC	fail	; K > 0
		TC	fail	; K= +0
		TC	*+2	; K < 0
		TC	fail	; K= -0
	; check for correct DABS in A (for K=-1, it should be +0)
		COM		; 1's compliment of A
		AD	CCSdM1	; put (-A) + expected value in A
		CCS	A	; A = DABS
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

	; set K to -0 and execute CCS: 
	; check for correct branch
		CAF	CCSkM0	; set K = -0
		TS	CCSk
		CCS	CCSk	; A = DABS[C(K)]
		TC	fail	; K > 0
		TC	fail	; K= +0
		TC	fail	; K < 0
	; check for correct DABS in A (for K=-0, it should be +0)
		COM		; 1's compliment of A
		AD	CCSdM0	; put (-A) + expected value in A
		CCS	A	; A = DABS
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

	; set K to +0 and execute CCS: 
	; check for correct branch
		CAF	CCSkP0	; set K = +0
		TS	CCSk
		CCS	CCSk	; A = DABS[C(K)]
		TC	fail	; K > 0
		TC	*+3	; K= +0
		TC	fail	; K < 0
		TC	fail	; K= -0
	; check for correct DABS in A (for K=+0, it should be +0)
		COM		; 1's compliment of A
		AD	CCSdP0	; put (-A) + expected value in A
		CCS	A	; A = DABS
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

	; set K to +1 and execute CCS: 
	; check for correct branch
		CAF	CCSkP1	; set K = +1
		TS	CCSk
		CCS	CCSk	; A = DABS[C(K)]
		TC	*+4	; K > 0
		TC	fail	; K= +0
		TC	fail	; K < 0
		TC	fail	; K= -0
	; check for correct DABS in A (for K=+1, it should be +0)
		COM		; 1's compliment of A
		AD	CCSdP1	; put (-A) + expected value in A
		CCS	A	; A = DABS
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

	; set K to +2 and execute CCS: 
	; check for correct branch
		CAF	CCSkP2	; set K = +2
		TS	CCSk
		CCS	CCSk	; A = DABS[C(K)]
		TC	*+4	; K > 0
		TC	fail	; K= +0
		TC	fail	; K < 0
		TC	fail	; K= -0
	; check for correct DABS in A (for K=+2, it should be +1)
		COM		; 1's compliment of A
		AD	CCSdP2	; put (-A) + expected value in A
		CCS	A	; A = DABS
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

	; passed the test
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


