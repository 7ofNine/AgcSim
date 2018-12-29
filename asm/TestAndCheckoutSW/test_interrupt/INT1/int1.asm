; TECO5 (file:teco5.asm)
;
	; program (re)start
		ORG	GOPROG
		TC	goMAIN

	; interrupt service entry points
		ORG	T3RUPT	; (RUPT1)
		NOOP
		RESUME

		ORG	DSRUPT	; (RUPT3) aka T4RUPT	
		NOOP
		RESUME

		ORG	KEYRUPT	; (RUPT4)
		NOOP
		RESUME

	; MAIN PROGRAM

goMAIN		EQU	*
infLoop		EQU	*
		INHINT		; disable interrupt
		NOOP
		RELINT		; enable interrupts
		NOOP
		TC	infLoop



