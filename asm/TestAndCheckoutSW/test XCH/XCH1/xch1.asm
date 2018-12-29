; XCH1 (file:xch1.asm)
; test XCH instruction


		ORG	100	; start of data area
val2		EQU	*	; 100 decimal
		DS	0	; *** stores val1 here ***

		ORG	GOPROG

	; test XCH; assumes that TC works as well.
	;

		XCH	val1	; put 12345 in reg A
		XCH	val2	; store 12345 in loc 100

end		TC	end

val1		DS	%12345

