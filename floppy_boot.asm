	;***BEGIN SECTOR 1 OF FLOPPY***
	BITS 16
	ORG 0x7C00				; standard bootloader location
	
	 JMP main
	 nop
;------------------------------------------;
;  Standard BIOS Parameter Block, "BPB".   ;
;------------------------------------------;
    bpbBytesPerSector:      DW 512
	bpbSectorsPerCluster:   DB 1
	bpbReservedSectors:     DW 1
	bpbNumberOfFATs:        DB 2
	bpbRootEntries:         DW 224
	bpbTotalSectors:        DW 2880
	bpbMedia:               DB 0xF0
	bpbSectorsPerFAT:       DW 9
	bpbSectorsPerTrack:     DW 18
	bpbHeadsPerCylinder:    DW 2
	bpbHiddenSectors:       DD 0
	bpbTotalSectorsBig:     DD 0
	bsDriveNumber:          DB 0
	bsUnused:               DB 0
	bsExtBootSignature:     DB 0x29
	bsSerialNumber:         DD 0xa0a1a2a3
	bsVolumeLabel:          DB "AOS Floppy "
	bsFileSystem:           DB "FAT12   "


	main:
		CLI				
		XOR AX, AX			; zero the segments (relative to ORG)
		MOV DS, AX
		MOV ES, AX
        MOV AX, 0x9000			; stack begins at 0x9000-0xFFFF
		MOV SS, AX
		MOV SP, 0xFFFF
		STI				

	; Load the second sector of this floppy into memory at 0x07C0:0x0200 (deliberately lacks error checking)
		MOV AH, 0x02		   ; BIOS INT 0x13 "read sector" function
		MOV AL, 1		   ; Number of sectors to read
		MOV CH, 0		   ; Cylinder/track
		MOV CL, 2		   ; Sector of floppy to read
		MOV DH, 0		   ; Head
		MOV DL, 0		   ; Disk number (here, the floppy disk) (unnecessary since DL defaults to boot disk)
		MOV BX, 0x07C0		   ; Segment containing the destination buffer (i.e. the current segment)
		MOV ES, BX
		MOV BX, 0x0200		   ; Destination buffer offset
		INT 0x13

	; Load the third sector of this floppy into memory at 0x07C0:0x0400 (deliberately lacks error checking)
		MOV AH, 0x02		   ; BIOS INT 0x13 "read sector" function
		MOV AL, 1		   ; Number of sectors to read
		MOV CH, 0		   ; Cylinder/track
		MOV CL, 3		   ; Sector of floppy to read
		MOV DH, 0		   ; Head
		MOV DL, 0		   ; Disk number (here, the floppy disk) (unnecessary since DL defaults to boot disk)
		MOV BX, 0x07C0		   ; Segment containing the destination buffer (i.e. the current segment)
		MOV ES, BX
		MOV BX, 0x0400		   ; Destination buffer offset
		INT 0x13

	; Load the fourth sector of this floppy into memory at 0x07C0:0x0400 (deliberately lacks error checking)
		MOV AH, 0x02		   ; BIOS INT 0x13 "read sector" function
		MOV AL, 1		   ; Number of sectors to read
		MOV CH, 0		   ; Cylinder/track
		MOV CL, 4		   ; Sector of floppy to read
		MOV DH, 0		   ; Head
		MOV DL, 0		   ; Disk number (here, the floppy disk) (unnecessary since DL defaults to boot disk)
		MOV BX, 0x07C0		   ; Segment containing the destination buffer (i.e. the current segment)
		MOV ES, BX
		MOV BX, 0x0600		   ; Destination buffer offset
		INT 0x13

		CALL installGdt		   ; Create the global descriptor table in RAM

		CLI
		MOV EAX, CR0
		OR EAX, 1
		MOV CR0, EAX
		JMP 0x08:protected_mode_ring_0
		


	; Offset 0 in GDT: Descriptor code=0x00
	gdt_data: 
		DD 0 				; null descriptor
		DD 0 
	 
	; Offset 8 bytes from start of GDT: descriptor code 0x08
	; kernel code:				
		DW 0xFFFF			; bits 0-15 (segment limit)
		DW 0x0000 			; bits 16-31 (low 2 bytes of base address)
		DB 0x00				; bits 32-39 (middle byte of base address)
		DB 10011010B 		; bits 40-47 ("segment in memory" bit, privilege bits, descriptor bit, read/write, virtual memory access bit)
		DB 11000000B 		; bits 48-55 (granularity, segment type, bits 16-19 of segment limit)
		DB 0x00				; bits 56-63 (high byte of base address)

	; Descriptor code 0x10
	; kernel data:				
		DW 0xFFFF			; bits 0-15 (segment limit)
		DW 0x0000 			; bits 16-31 (low 2 bytes of base address)
		DB 0x00				; bits 32-39 (middle byte of base address)
		DB 10010010B 		; bits 40-47 ("segment in memory" bit, privilege bits, descriptor bit, read/write, virtual memory access bit)
		DB 11000000B 		; bits 48-55 (granularity, segment type, bits 16-19 of segment limit)
		DB 0x00				; bits 56-63 (high byte of base address)


	end_of_gdt:
	gdt_description: 
		DW end_of_gdt - gdt_data - 1 	; size of GDT minus 1 (for GDTR)
		DD gdt_data 				    ; base of GDT




	installGdt:
		CLI			
		LGDT [gdt_description]		
		STI
		RET



	print_16_bit:
		PUSHA
		MOV AH, 0x0E
		print_16_bit_loop:
			MOV BYTE AL, [BX]
			INT 0x10
			INC BX
			CMP BYTE [BX], 0
			JNE print_16_bit_loop
		POPA
		RET

	welcome_string: db "Welcome to the OS.", 0
	times 510-($-$$) DB 0		; pad rest of sector
	DW 0xAA55			; add bootloader signature
	;***END SECTOR 1 OF FLOPPY***



	;***BEGIN SECTOR 2 OF FLOPPY***
	BITS 32
	protected_mode_ring_0:
	
	CALL 0x8000
	JMP $



	times 1024-($-$$) DB 0		; pad rest of sector
	;***END SECTOR 2 OF FLOPPY***
