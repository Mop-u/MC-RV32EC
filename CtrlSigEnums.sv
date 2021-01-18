/*  _______________________________________________________________________________
   |                          2-bit control signal tables                          |
   |-------------------------------------------------------------------------------|
   |    ALUOP    | Bitwise |     Arith &     |  Shift  |   PC Write    |    LSU    |
   |   Category  |  ALUOP  |    Flag ALUOP   |  ALUOP  |     Mode      |   Width   |
   |-------------|---------|-----------------|---------|---------------|-----------|
 00|Bitwise ALUBT|Undefined|Signed Sub ASSUBS|Undefined|Inc      PCINC |LSU Nop LSN|
 01|Add/Sub ALUAS|XOR BTXOR|Signed Add ASADDS|SLL SHSLL|Branch   PCBRCH|Word    LSW|
 10|Shift   ALUSH|OR  BTOR |Unsign Sub ASSUBU|SRL SHSRL|Jump Reg PCJREG|Half    LSH|
 11|Flag    ALUFL|AND BTAND|Unsign Add ASADDU|SRA SHSRA|Jump Imm PCJIMM|Byte    LSB|
   \------------------------------------------------------------------------------/
*/
typedef enum bit[1:0] {
    ALUBT,
    ALUAS,
    ALUSH,
    ALUFL
} LookupALUOPCategory;
typedef enum bit[1:0] {
    BT_BAD_BITWISE,
    BTXOR,
    BTOR,
    BTAND
} LookupBitwiseALUOP;
typedef enum bit[1:0] {
    ASSUBS,
    ASADDS,
    ASSUBU,
    ASADDU
} LookupArithALUOP;
typedef enum bit[1:0] {
    SH_BAD_SHIFT,
    SHSLL,
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