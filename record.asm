;SE X1 SW-R3AA007
;Mixed mode recording patch for Sony Ericsson X1
;Requires original wavedev.dll.
include "x.inc"

;-------------------------------
;virtual addresses
codezone = 0x10033980
newsection = 0x100CC000
;-------------------------------
;functions
memcpy = 0x100810DC
dataready_inner = 0x100339EC
waitagain = 0x10033674
;-------------------------------
;consts
result_waitagain = 5
result_dataready = 6
;-------------------------------


code32
org codezone
    BL newsection
    CMP R0, result_dataready
    BEQ dataready_inner
    CMP R0, result_waitagain
    B waitagain
;-------------------------------


code32
org newsection
    STMFD   SP!, {R1-R11,LR}
    LDR R4, [SP,0x0C] 
    LDR R5, [SP,0x10]
    LDR R6, [SP,0x14]
    LDR R8, [SP,0x1C]
    LDR R9, [SP,0x20]
    LDR R10,[SP,0x24]

    LDR R1, [SP,0x40]               ;0x30+0x10
    CMP R1, 2                       ;if current recorder isn't second one, 
    MOVNE R0, result_waitagain      ;it shouldn't be processed
    BNE exit                        ;and we wait for next handles.

    ;TODO: loading fake channels.
    LDR R11, dword_B00              ;!!!not safe!!!
    LDR R9, dword_600               ;!!!not safe!!!
    MOV R0, 0

Mixing:                             ;if current recorder is second, we mix channels
    MOV		R0, R11
    MOV		R1, R9
    BL		PerformMixing
    LDR 	R11, dword_B00	
    BL		PerformCopy
    MOV 	R0, result_dataready
exit:
    LDMFD   SP!, {R1-R11,LR}
    BX      LR
;-------------------------------
PerformCopy:                        ;and then copy everything to output
    STMFD	SP!, {R1-R6,LR}
    LDR 	R5, dword_fromStartVocoderInput
    LDR		R6, dword_100A6B4C
    LDR     R2, [R5]
    LDR     R3, dword_100A6AAC
    ;copying
    MOV		R1, R0                  ; void *
    LDR     R0, [R3, R2, lsl 0x2]   ; void *
    MOV     R2, 0x140               ; size_t
    BL      memcpy
    LDR     R3, [R5]
    ;Setting size
    MOV     R2, 0x140 
    STR     R2, [R6, R3, lsl 0x2]
    ;
    ADD     R3, R3, 1
    STR     R3, [R5]
    CMP     R3, 9
    BLS		PerformCopy_exit		
    MOV     R3, 0
    STR     R3, [R5]
PerformCopy_exit:
    LDMFD	SP!, {R1-R6,LR}
    BX		LR
;-------------------------------
PerformMixing:
    STMFD	SP!, {R0-R5,LR}
    MOV		R4, R0
    MOV		R5, R1

__MixAgain:
    MOV 	R1, R4
    MOV		R3, R5
    LDRSH   R2, [R1,R0]!
    LDRSH   R3, [R3,R0]
    ADD     R0, R0, 2
    CMP     R0, 0x140
    ADD     R3, R3, R2
    STRH    R3, [R1]
    BLT     __MixAgain

    LDMFD	SP!, {R0-R5,LR}
    BX		LR
;-------------------------------
align 4
dword_600 dw 0xBC0EF600
dword_880 dw 0xBC0EF880
dword_B00 dw 0xBC0EFB00
dword_D80 dw 0xBC0EFD80
dword_fromStartVocoderInput dw 0x10098AE4
dword_100A6AAC dw 0x100A6AAC
dword_100A6B4C dw 0x100A6B4C
