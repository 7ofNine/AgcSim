; TECO2_MP (file:teco2_MP.asm)
;
; Version:	1.0
; Author:	John Pultorak
; Date:		9/14/2001
;
; PURPOSE:
; Test and checkout program for the Block 1 Apollo Guidance Computer.
; Tests extracode instructions: MP
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

MPtst		EQU	%01	; MP check failed

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

	; MP test
MPindex		DS	%0
MPXTND		DS	%0	; indexed extend

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
		TCR	chkMP

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
	; TEST MP INSTRUCTION SUBROUTINE
	; L:	MP	K
	; Verifies the following
	; - Set C(A,LP) = b(A) * C(K)
	; - Take next instruction from L+1

chkMP		EQU	*
		XCH	Q
		TS	savQ	; save return address

		CAF	MPcode
		TS	curtest	; set current test code to this test

	; Decrementing loop
	;	- always executes at least once (tests at end of loop)		
	;	- loops 'MPstart+1' times; decrements MPindex
		XCH	MPstart	; initialize loop counter

	;------------------------------
	; MP check starts here
	; uses MPindex to access test values
MPloop		EQU	*
		TS	MPindex	; save new index

		CAF	EXTENDER
		AD	MPindex
		TS	MPXTND

		INDEX	MPindex
		CAF	mp1
		INDEX	MPXTND	; EXTEND using MPindex
		MP	mp2

	; verify C(A)
		COM		; get -A
		INDEX	MPindex
		AD	MPchkA	; put (-A) + expected value in A
		CCS	A	; compare
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

	; verify C(LP)
		CS	LP	; get -A
		INDEX	MPindex
		AD	MPchkLP	; put (-A) + expected value in A
		CCS	A	; compare
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

	; end of MP check
	;------------------------------

		CCS	MPindex	; done?
		TC	MPloop	; not yet, do next check

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

MPcode		DS	MPtst	; code for this test

	; MP test values
	;                          
MPstart		DS	9	; loop MPstart+1 times

	; C(A) test values
mp1		EQU	*
	; randomly selected checks (one word product)
		DS	%00007	; check #08 (7 * 17)
		DS	%00021	; check #09 (17 * 7)
		DS	%00035	; check #10 (29 * 41)
		DS	%00051	; check #11 (41 * 29)
		DS	%00065	; check #12 (53 * 67)
		DS	%00103	; check #13 (67 * 53)
		DS	%00117	; check #14 (79 * 97)
		DS	%00141	; check #15 (97 * 79)
		DS	%00153	; check #16 (107 * 127)
		DS	%00177	; check #17 (127 * 107)

	; C(K) test values
mp2		EQU	*
	; randomly selected checks (one word product)
		DS	%00021	; check #08 (7 * 17)
		DS	%00007	; check #09 (17 * 7)
		DS	%00051	; check #10 (29 * 41)
		DS	%00035	; check #11 (41 * 29)
		DS	%00103	; check #12 (53 * 67)
		DS	%00065	; check #13 (67 * 53)
		DS	%00141	; check #14 (79 * 97)
		DS	%00117	; check #15 (97 * 79)
		DS	%00177	; check #16 (107 * 127)
		DS	%00153	; check #17 (127 * 107)

	; A = upper product
MPchkA		EQU	*
	; randomly selected checks
		DS	%00000	; check #08 (7 * 17)
		DS	%00000	; check #09 (17 * 7)
		DS	%00000	; check #10 (29 * 41)
		DS	%00000	; check #11 (41 * 29)
		DS	%00000	; check #12 (53 * 67)
		DS	%00000	; check #13 (67 * 53)
		DS	%00000	; check #14 (79 * 97)
		DS	%00000	; check #15 (97 * 79)
		DS	%00000	; check #16 (107 * 127)
		DS	%00000	; check #17 (127 * 107)

	; LP = lower product
MPchkLP		EQU	*
	; randomly selected checks
		DS	%00167	; check #08 (7 * 17)
		DS	%00167	; check #09 (17 * 7)
		DS	%02245	; check #10 (29 * 41)
		DS	%02245	; check #11 (41 * 29)
		DS	%06737	; check #12 (53 * 67)
		DS	%06737	; check #13 (67 * 53)
		DS	%16757	; check #14 (79 * 97)
		DS	%16757	; check #15 (97 * 79)
		DS	%32425	; check #16 (107 * 127)
		DS	%32425	; check #17 (127 * 107)




