/*  _______________________________________________________________________________
   |                          2-bit control signal tables                          |
   |-------------------------------------------------------------------------------|
   |    ALUOP    | Bitwise |     Arith &     |  Shift  |   PC Write    |    LSU    |
   |   Category  |  ALUOP  |    Flag ALUOP   |  ALUOP  |     Mode      |   Width   |
   |-------------|---------|-----------------|---------|---------------|-----------|
 00|Bitwise ALUBT| ALU_NOP |Signed Sub AFSUBS|SLL SHSLL|Inc      PCINC |LSU Nop LSN|
 01|Add/Sub ALUAS|XOR BTXOR|       Add AFADD |Undefined|Branch   PCBRCH|Word    LSW|
 10|Shift   ALUSH|OR  BTOR |Unsign Sub AFSUBU|SRL SHSRL|Jump Reg PCJREG|Half    LSH|
 11|Flag    ALUFL|AND BTAND|Equality   AFEQU |SRA SHSRA|Jump Imm PCJIMM|Byte    LSB|
   \------------------------------------------------------------------------------/
*/
typedef enum bit[1:0] {
    ALUBT,
    ALUAS,
    ALUSH,
    ALUFL
} LookupALUOPCategory;
typedef enum bit[1:0] {
    ALU_NOP,
    BTXOR,
    BTOR,
    BTAND
} LookupBitwiseALUOP;
typedef enum bit[1:0] {
    AFSUBS,
    AFADD,
    AFSUBU,
    AFEQU
} LookupArithALUOP;
typedef enum bit[1:0] {
    SHSLL,
    SH_BAD_SHIFT,
    SHSRL,
    SHSRA
} LookupShiftALUOP;
typedef enum bit[1:0] {
    PCINC,
    PCBRCH,
    PCJREG,
    PCJIMM
} LookupPCWriteMode;
typedef enum bit[1:0] {
    LSN,
    LSW,
    LSH,
    LSB
} LookupLSUWidth;
typedef enum bit {
    LO,
    HI
} LookupSingleBit;