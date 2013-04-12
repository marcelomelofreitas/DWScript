{**************************************************************************}
{                                                                          }
{    This Source Code Form is subject to the terms of the Mozilla Public   }
{    License, v. 2.0. If a copy of the MPL was not distributed with this   }
{     file, You can obtain one at http://mozilla.org/MPL/2.0/.             }
{                                                                          }
{    Software distributed under the License is distributed on an           }
{    "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express           }
{    or implied. See the License for the specific language                 }
{    governing rights and limitations under the License.                   }
{                                                                          }
{    Copyright Eric Grange / Creative IT                                   }
{                                                                          }
{**************************************************************************}
unit dwsJITx86Intrinsics;

{$I ../dws.inc}

interface

uses
   Types,
   dwsDataContext,
   dwsUtils;

type
   TxmmRegister = (
      xmmNone = -1,
      xmm0 = 0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, xmm7
   );

   TxmmRegisters = set of xmm0..xmm7;

   TxmmOp = (
      xmm_cvtsi2sd   = $2A,
      xmm_sqrtsd     = $51,
      xmm_addsd      = $58,
      xmm_multsd     = $59,
      xmm_subsd      = $5C,
      xmm_minsd      = $5D,
      xmm_divsd      = $5E,
      xmm_maxsd      = $5F
   );

   TgpRegister = (
      gprEAX = 0,
      gprECX = 1,
      gprEDX = 2,
      gprEBX = 3,
      gprESP = 4,
      gprEBP = 5,
      gprESI = 6,
      gprEDI = 7
   );

   TboolFlags = (
      flagsNone = 0,
      flagsA = $77,     // if above (CF=0 and ZF=0)
      flagsAE = $73,    // if above or equal (CF=0)
      flagsB = $72,     // if below (CF=1)
      flagsBE = $76,    // if below or equal (CF=1 or ZF=1)
      flagsC = $72,     // if carry (CF=1)
      flagsE = $74,     // if equal (ZF=1)
      flagsG = $7F,     // if greater (ZF=0 and SF=OF)
      flagsGE = $7D,    // if greater or equal (SF=OF)
      flagsL = $7C,     // if less (SF<>OF)
      flagsLE = $7E,    // if less or equal (ZF=1 or SF<>OF)
      flagsNA = $76,    // if not above (CF=1 or ZF=1)
      flagsNAE = $72,   // if not above or equal (CF=1)
      flagsNB = $73,    // if not below (CF=0)
      flagsNBE = $77,   // if not below or equal (CF=0 and ZF=0)
      flagsNC = $73,    // if not carry (CF=0)
      flagsNE = $75,    // if not equal (ZF=0)
      flagsNG = $7E,    // if not greater (ZF=1 or SF<>OF)
      flagsNGE = $7C,   // if not greater or equal (SF<>OF)
      flagsNL = $7D,    // if not less (SF=OF)
      flagsNLE = $7F,   // if not less or equal (ZF=0 and SF=OF)
      flagsNO = $71,    // if not overflow (OF=0)
      flagsNP = $7B,    // if not parity (PF=0)
      flagsNS = $79,    // if not sign (SF=0)
      flagsNZ = $75,    // if not zero (ZF=0)
      flagsO = $70,     // if overflow (OF=1)
      flagsP = $7A,     // if parity (PF=1)
      flagsPE = $7A,    // if parity even (PF=1)
      flagsPO = $7B,    // if parity odd (PF=0)
      flagsS = $78,     // if sign (SF=1)
      flagsZ = $74      // if zero (ZF = 1)
   );

   TgpOp = packed record
      Short1, SIB : Byte;
      Long1 : Byte;
      LongEAX : Byte;
   end;

   Tx86WriteOnlyStream = class(TWriteOnlyBlockStream)
      private
         procedure _modRMSIB_reg_reg(const opCode : array of Byte; dest, src : TxmmRegister);
         procedure _modRMSIB_reg_execmem(const opCode : array of Byte; reg : TxmmRegister; stackAddr : Integer); overload;
         procedure _modRMSIB_reg_execmem(const opCode : array of Byte; reg : TgpRegister; stackAddr, offset : Integer); overload;
         procedure _modRMSIB_reg_absmem(const opCode : array of Byte; reg : TxmmRegister; ptr : Pointer);
         procedure _modRMSIB_op_execmem_int32(code1, code2 : Byte; stackAddr, offset, value : Integer);
         procedure _modRMSIB_regnum_ptr_reg(const opCode : array of Byte; destNum : Integer; src : TgpRegister; offset : Integer);
         procedure _modRMSIB_ptr_reg(rm : Integer; reg : TgpRegister; offset : Integer);
         procedure _modRMSIB_ptr_reg_reg(rm : Integer; base, index : TgpRegister; scale, offset : Integer);

      public
         procedure WritePointer(const p : Pointer);

         procedure _xmm_reg_reg(op : TxmmOp; dest, src : TxmmRegister);
         procedure _xmm_reg_execmem(op : TxmmOp; reg : TxmmRegister; stackAddr : Integer);
         procedure _xmm_reg_absmem(op : TxmmOp; reg : TxmmRegister; ptr : Pointer);

         procedure _xorps_reg_reg(dest, src : TxmmRegister);

         procedure _comisd_reg_reg(dest, src : TxmmRegister);
         procedure _comisd_reg_execmem(reg : TxmmRegister; stackAddr : Integer);
         procedure _comisd_reg_absmem(reg : TxmmRegister;  ptr : Pointer);

         procedure _movsd_reg_execmem(reg : TxmmRegister; stackAddr : Integer);
         procedure _movsd_execmem_reg(stackAddr : Integer; reg : TxmmRegister);
         procedure _movsd_reg_absmem(reg : TxmmRegister; ptr : Pointer);
         procedure _movsd_reg_esp(reg : TxmmRegister; offset : Integer = 0);
         procedure _movsd_esp_reg(reg : TxmmRegister); overload;
         procedure _movsd_esp_reg(offset : Integer; reg : TxmmRegister); overload;
         procedure _movsd_qword_ptr_reg_reg(dest : TgpRegister; offset : Integer; src : TxmmRegister);
         procedure _movsd_reg_qword_ptr_reg(dest : TxmmRegister; src : TgpRegister; offset : Integer);
         procedure _movsd_reg_qword_ptr_indexed(dest : TxmmRegister; base, index : TgpRegister; scale, offset : Integer);
         procedure _movsd_qword_ptr_indexed_reg(base, index : TgpRegister; scale, offset : Integer; src : TxmmRegister);

         procedure _movq_execmem_reg(stackAddr : Integer; reg : TxmmRegister);
         procedure _movq_reg_absmem(reg : TxmmRegister; ptr : Pointer);

         procedure _mov_reg_execmem(reg : TgpRegister; stackAddr : Integer; offset : Integer = 0);
         procedure _mov_execmem_reg(stackAddr, offset : Integer; reg : TgpRegister);
         procedure _mov_eaxedx_execmem(stackAddr : Integer);
         procedure _mov_execmem_eaxedx(stackAddr : Integer);
         procedure _mov_execmem_imm(stackAddr : Integer; const imm : Int64);
         procedure _mov_eaxedx_imm(const imm : Int64);
         procedure _mov_reg_reg(dest, src : TgpRegister);
         procedure _mov_reg_dword_ptr_reg(dest, src : TgpRegister; offset : Integer = 0);
         procedure _mov_dword_ptr_reg_reg(dest : TgpRegister; offset : Integer; src : TgpRegister);
         procedure _mov_qword_ptr_reg_eaxedx(dest : TgpRegister; offset : Integer);
         procedure _mov_eaxedx_qword_ptr_reg(src : TgpRegister; offset : Integer);
         procedure _mov_reg_dword(reg : TgpRegister; imm : DWORD);

         procedure _inc_eaxedx_imm(const imm : Int64);

         procedure _cmp_execmem_int32(stackAddr, offset, value : Integer);
         procedure _cmp_execmem_reg(stackAddr, offset : Integer; reg : TgpRegister);
         procedure _cmp_dword_ptr_reg_reg(dest : TgpRegister; offset : Integer; reg : TgpRegister);

         procedure _set_al_flags(flags : TboolFlags);

         procedure _op_reg_int32(const op : TgpOP; reg : TgpRegister; value : Integer);
         procedure _add_reg_int32(reg : TgpRegister; value : Integer);
         procedure _adc_reg_int32(reg : TgpRegister; value : Integer);
         procedure _sub_reg_int32(reg : TgpRegister; value : Integer);
         procedure _sbb_reg_int32(reg : TgpRegister; value : Integer);

         procedure _add_execmem_int32(stackAddr, offset, value : Integer);
         procedure _adc_execmem_int32(stackAddr, offset, value : Integer);
         procedure _sub_execmem_int32(stackAddr, offset, value : Integer);
         procedure _sbb_execmem_int32(stackAddr, offset, value : Integer);
         procedure _int64_inc(stackAddr : Integer; const imm : Int64);
         procedure _int64_dec(stackAddr : Integer; const imm : Int64);

         procedure _fild_execmem(stackAddr : Integer);
         procedure _fistp_esp;
         procedure _fld_esp;
         procedure _fstp_esp;

         procedure _push_reg(reg : TgpRegister);
         procedure _pop_reg(reg : TgpRegister);

         procedure _xor_reg_reg(dest, src : TgpRegister);

         procedure _call_reg(reg : TgpRegister; offset : Integer);
         procedure _call_absmem(ptr : Pointer);

         procedure _test_al_al;
         procedure _nop(nb : Integer);
         procedure _ret;
   end;

const
   gpOp_add : TgpOp = (Short1: $83; SIB: $C0; Long1: $81; LongEAX: $05);
   gpOp_adc : TgpOp = (Short1: $83; SIB: $D0; Long1: $81; LongEAX: $15);
   gpOp_sub : TgpOp = (Short1: $83; SIB: $E8; Long1: $81; LongEAX: $2D);
   gpOp_sbb : TgpOp = (Short1: $83; SIB: $D8; Long1: $81; LongEAX: $1D);
   gpOp_xor : TgpOp = (Short1: $83; SIB: $F0; Long1: $81; LongEAX: $35);
   gpOp_and : TgpOp = (Short1: $83; SIB: $E0; Long1: $81; LongEAX: $25);
   gpOp_or  : TgpOp = (Short1: $83; SIB: $C8; Long1: $81; LongEAX: $0D);
   gpOp_cmp : TgpOp = (Short1: $83; SIB: $F8; Long1: $81; LongEAX: $3D);

const
   cStackMixinBaseDataOffset = 8;
   cVariant_DataOffset = 8;
   cgpRegisterName : array [TgpRegister] of String = (
      'eax', 'ecx', 'edx', 'ebx', 'esp', 'ebp', 'esi', 'edi'
      );
   cExecMemGPR = gprEBX;

function NegateBoolFlags(flags : TboolFlags) : TboolFlags;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

// StackAddrToOffset
//
function StackAddrToOffset(addr : Integer) : Integer;
begin
   Result:=addr*SizeOf(Variant)+cVariant_DataOffset;
end;

// NegateBoolFlags
//
function NegateBoolFlags(flags : TboolFlags) : TboolFlags;
begin
   case flags of
      flagsA : Result:=flagsNA;
      flagsAE : Result:=flagsNAE;
      flagsB : Result:=flagsNB;
      flagsBE : Result:=flagsNBE;
      flagsE : Result:=flagsNE;
      flagsG : Result:=flagsNG;
      flagsGE : Result:=flagsNGE;
      flagsL : Result:=flagsNL;
      flagsLE : Result:=flagsNLE;
      flagsNE : Result:=flagsE;
      flagsNO : Result:=flagsO;
      flagsNP : Result:=flagsP;
      flagsNS : Result:=flagsS;
      flagsO : Result:=flagsNO;
      flagsP : Result:=flagsNP;
      flagsS : Result:=flagsNS;
   else
      Result:=flags;
   end;
end;

// ------------------
// ------------------ Tx86WriteOnlyStream ------------------
// ------------------

// _modRMSIB_reg_reg
//
procedure Tx86WriteOnlyStream._modRMSIB_reg_reg(const opCode : array of Byte; dest, src : TxmmRegister);
begin
   Assert(dest in [xmm0..High(TxmmRegister)]);
   Assert(src in [xmm0..High(TxmmRegister)]);

   WriteBytes(opCode);

   WriteByte($C0+Ord(src)+Ord(dest)*8);
end;

// _modRMSIB_reg_execmem (xmm)
//
procedure Tx86WriteOnlyStream._modRMSIB_reg_execmem(const opCode : array of Byte; reg : TxmmRegister; stackAddr : Integer);
begin
   Assert(reg in [xmm0..High(TxmmRegister)]);

   _modRMSIB_regnum_ptr_reg(opCode, Ord(reg), cExecMemGPR, StackAddrToOffset(stackAddr));
end;

// _modRMSIB_reg_execmem (gpr)
//
procedure Tx86WriteOnlyStream._modRMSIB_reg_execmem(const opCode : array of Byte; reg : TgpRegister; stackAddr, offset : Integer);
begin
   Assert(reg in [gprEAX..High(gprEDI)]);

   _modRMSIB_regnum_ptr_reg(opCode, Ord(reg), cExecMemGPR, StackAddrToOffset(stackAddr)+offset);
end;

// _modRMSIB_reg_absmem
//
procedure Tx86WriteOnlyStream._modRMSIB_reg_absmem(const opCode : array of Byte; reg : TxmmRegister; ptr : Pointer);
begin
   Assert(reg in [xmm0..High(TxmmRegister)]);

   WriteBytes(opCode);

   WriteByte($05+Ord(reg)*8);
   WritePointer(ptr);
end;

// _modRMSIB_op_execmem_int32
//
procedure Tx86WriteOnlyStream._modRMSIB_op_execmem_int32(code1, code2 : Byte; stackAddr, offset, value : Integer);
begin
   offset:=StackAddrToOffset(stackAddr)+offset;

   Inc(code2, Ord(cExecMemGPR));

   if (offset>=-128) and (offset<=127) then begin

      if (value>=-128) and (value<=127) then
         WriteBytes([code1, code2, offset, value])
      else begin
         WriteBytes([code1-2, code2, offset]);
         WriteInt32(value);
      end;

   end else begin

      if (value>=-128) and (value<=127) then begin
         WriteBytes([code1, code2+$40]);
         WriteInt32(offset);
         WriteByte(value);
      end else begin
         WriteBytes([code1-2, code2+$40]);
         WriteInt32(offset);
         WriteInt32(value);
      end;

   end;
end;

// _modRMSIB_regnum_ptr_reg
//
procedure Tx86WriteOnlyStream._modRMSIB_regnum_ptr_reg(const opCode : array of Byte; destNum : Integer; src : TgpRegister; offset : Integer);
begin
   WriteBytes(opCode);
   _modRMSIB_ptr_reg(destNum*8, src, offset)
end;

// _modRMSIB_ptr_reg
//
procedure Tx86WriteOnlyStream._modRMSIB_ptr_reg(rm : Integer; reg : TgpRegister; offset : Integer);
begin
   Inc(rm, Ord(reg));
   if (offset<>0) or (reg=gprEBP) then begin
      if (offset>=-128) and (offset<=127) then
         Inc(rm, $40)
      else Inc(rm, $80);
   end;
   WriteByte(rm);
   if reg=gprESP then
      WriteByte($24);
   if (rm and $40)<>0 then
      WriteByte(offset)
   else if (rm and $80)<>0 then
      WriteInt32(offset);
end;

// _modRMSIB_ptr_reg_reg
//
procedure Tx86WriteOnlyStream._modRMSIB_ptr_reg_reg(rm : Integer; base, index : TgpRegister; scale, offset : Integer);
var
   sib : Integer;
begin
   Assert(scale in [1, 2, 4, 8]);

   if (index=gprESP) and (base<>gprESP) then begin
      Assert(scale=1);
      _modRMSIB_ptr_reg_reg(rm, index, base, 1, offset);
   end;

   if (offset=0) and (base<>gprEBP) then
      Inc(rm, $04)
   else if (offset>=-128) and (offset<127) then
      Inc(rm, $44)
   else Inc(rm, $84);
   WriteByte(rm);

   sib:=Ord(index)*8+Ord(base);
   case scale of
      2 : Inc(sib, $40);
      4 : Inc(sib, $80);
      8 : Inc(sib, $C0);
   end;
   WriteByte(sib);

   if (rm and $40)<>0 then
      WriteByte(offset)
   else if (rm and $80)<>0 then
      WriteInt32(offset);
end;

// WritePointer
//
procedure Tx86WriteOnlyStream.WritePointer(const p : Pointer);
begin
   Write(p, 4);
end;

// _xmm_reg_reg
//
procedure Tx86WriteOnlyStream._xmm_reg_reg(op : TxmmOp; dest, src : TxmmRegister);
begin
   _modRMSIB_reg_reg([$F2, $0F, Ord(op)], dest, src);
end;

// _xmm_reg_execmem
//
procedure Tx86WriteOnlyStream._xmm_reg_execmem(op : TxmmOp; reg : TxmmRegister; stackAddr : Integer);
begin
   _modRMSIB_reg_execmem([$F2, $0F, Ord(op)], reg, stackAddr);
end;

// _xmm_reg_absmem
//
procedure Tx86WriteOnlyStream._xmm_reg_absmem(op : TxmmOp; reg : TxmmRegister;  ptr : Pointer);
begin
   _modRMSIB_reg_absmem([$F2, $0F, Ord(op)], reg, ptr);
end;

// _xorps_reg_reg
//
procedure Tx86WriteOnlyStream._xorps_reg_reg(dest, src : TxmmRegister);
begin
   _modRMSIB_reg_reg([$0F, $57], dest, src);
end;

// _comisd_reg_reg
//
procedure Tx86WriteOnlyStream._comisd_reg_reg(dest, src : TxmmRegister);
begin
   _modRMSIB_reg_reg([$66, $0F, $2F], dest, src);
end;

// _comisd_reg_execmem
//
procedure Tx86WriteOnlyStream._comisd_reg_execmem(reg : TxmmRegister; stackAddr : Integer);
begin
   _modRMSIB_reg_execmem([$66, $0F, $2F], reg, stackAddr);
end;

// _comisd_reg_absmem
//
procedure Tx86WriteOnlyStream._comisd_reg_absmem(reg : TxmmRegister;  ptr : Pointer);
begin
   _modRMSIB_reg_absmem([$66, $0F, $2F], reg, ptr);
end;

// _movsd_reg_execmem
//
procedure Tx86WriteOnlyStream._movsd_reg_execmem(reg : TxmmRegister; stackAddr : Integer);
begin
   _modRMSIB_reg_execmem([$F2, $0F, $10], reg, stackAddr);
end;

// _movsd_execmem_reg
//
procedure Tx86WriteOnlyStream._movsd_execmem_reg(stackAddr : Integer; reg : TxmmRegister);
begin
   _modRMSIB_reg_execmem([$F2, $0F, $11], reg, stackAddr);
end;

// _movsd_reg_absmem
//
procedure Tx86WriteOnlyStream._movsd_reg_absmem(reg : TxmmRegister; ptr : Pointer);
begin
   _modRMSIB_reg_absmem([$F2, $0F, $10], reg, ptr);
end;

// _movsd_reg_esp
//
procedure Tx86WriteOnlyStream._movsd_reg_esp(reg : TxmmRegister; offset : Integer = 0);
begin
   _movsd_reg_qword_ptr_reg(reg, gprESP, offset);
end;

// _movsd_esp_reg
//
procedure Tx86WriteOnlyStream._movsd_esp_reg(reg : TxmmRegister);
begin
   _movsd_qword_ptr_reg_reg(gprESP, 0, reg);
end;

// _movsd_esp_reg
//
procedure Tx86WriteOnlyStream._movsd_esp_reg(offset : Integer; reg : TxmmRegister);
begin
   _movsd_qword_ptr_reg_reg(gprESP, offset, reg);
end;

// _movsd_qword_ptr_reg_reg
//
procedure Tx86WriteOnlyStream._movsd_qword_ptr_reg_reg(dest : TgpRegister; offset : Integer; src : TxmmRegister);
begin
   Assert(src in [xmm0..High(TxmmRegister)]);

   _modRMSIB_regnum_ptr_reg([$F2, $0F, $11], Ord(src), dest, offset);
end;

// _movsd_reg_qword_ptr_reg
//
procedure Tx86WriteOnlyStream._movsd_reg_qword_ptr_reg(dest : TxmmRegister; src : TgpRegister; offset : Integer);
begin
   Assert(dest in [xmm0..High(TxmmRegister)]);

   _modRMSIB_regnum_ptr_reg([$F2, $0F, $10], Ord(dest), src, offset);
end;

// _movsd_reg_qword_ptr_indexed
//
procedure Tx86WriteOnlyStream._movsd_reg_qword_ptr_indexed(dest : TxmmRegister; base, index : TgpRegister; scale, offset : Integer);
begin
   Assert(dest in [xmm0..High(TxmmRegister)]);

   WriteBytes([$F2, $0F, $10]);

   _modRMSIB_ptr_reg_reg(Ord(dest)*8, base, index, scale, offset);
end;

// _movsd_qword_ptr_indexed_reg
//
procedure Tx86WriteOnlyStream._movsd_qword_ptr_indexed_reg(base, index : TgpRegister; scale, offset : Integer; src : TxmmRegister);
begin
   Assert(src in [xmm0..High(TxmmRegister)]);

   WriteBytes([$F2, $0F, $11]);

   _modRMSIB_ptr_reg_reg(Ord(src)*8, base, index, scale, offset);
end;

// _movq_execmem_reg
//
procedure Tx86WriteOnlyStream._movq_execmem_reg(stackAddr : Integer; reg : TxmmRegister);
begin
   _modRMSIB_reg_execmem([$66, $0F, $D6], reg, stackAddr);
end;

// _movq_reg_absmem
//
procedure Tx86WriteOnlyStream._movq_reg_absmem(reg : TxmmRegister; ptr : Pointer);
begin
   _modRMSIB_reg_absmem([$F3, $0F, $7E], reg, ptr);
end;

// _mov_reg_execmem
//
procedure Tx86WriteOnlyStream._mov_reg_execmem(reg : TgpRegister; stackAddr : Integer; offset : Integer = 0);
begin
   _modRMSIB_regnum_ptr_reg([$8B], Ord(reg), cExecMemGPR, StackAddrToOffset(stackAddr)+offset);
end;

// _mov_execmem_reg
//
procedure Tx86WriteOnlyStream._mov_execmem_reg(stackAddr, offset : Integer; reg : TgpRegister);
begin
   _modRMSIB_reg_execmem([$89], reg, stackAddr, offset);
end;

// _mov_eaxedx_execmem
//
procedure Tx86WriteOnlyStream._mov_eaxedx_execmem(stackAddr : Integer);
begin
   _mov_reg_execmem(gprEAX, stackAddr, 0);
   _mov_reg_execmem(gprEDX, stackAddr, 4);
end;

// _mov_execmem_eaxedx
//
procedure Tx86WriteOnlyStream._mov_execmem_eaxedx(stackAddr : Integer);
begin
   _mov_execmem_reg(stackAddr, 0, gprEAX);
   _mov_execmem_reg(stackAddr, 4, gprEDX);
end;

// _mov_execmem_imm
//
procedure Tx86WriteOnlyStream._mov_execmem_imm(stackAddr : Integer; const imm : Int64);
var
   v : DWORD;
begin
   v:=DWORD(imm);
   if v=(imm shr 32) then begin

      _mov_reg_dword(gprEAX, v);

      _mov_execmem_reg(stackAddr, 0, gprEAX);
      _mov_execmem_reg(stackAddr, 4, gprEAX);

   end else begin

      _mov_eaxedx_imm(imm);
      _mov_execmem_eaxedx(stackAddr);

   end;
end;

// _mov_eaxedx_imm
//
procedure Tx86WriteOnlyStream._mov_eaxedx_imm(const imm : Int64);
begin
   _mov_reg_dword(gprEAX, DWORD(imm));
   _mov_reg_dword(gprEDX, DWORD(imm shr 32));
end;

// _mov_reg_reg
//
procedure Tx86WriteOnlyStream._mov_reg_reg(dest, src : TgpRegister);
begin
   WriteBytes([$89, $C0+Ord(dest)+8*Ord(src)]);
end;

// _mov_reg_dword_ptr_reg
//
procedure Tx86WriteOnlyStream._mov_reg_dword_ptr_reg(dest, src : TgpRegister; offset : Integer = 0);
begin
   _modRMSIB_regnum_ptr_reg([$8B], Ord(dest), src, offset);
end;

// _mov_dword_ptr_reg_reg
//
procedure Tx86WriteOnlyStream._mov_dword_ptr_reg_reg(dest : TgpRegister; offset : Integer; src : TgpRegister);
begin
   _modRMSIB_regnum_ptr_reg([$89], Ord(src), dest, offset);
end;

// _mov_qword_ptr_reg_eaxedx
//
procedure Tx86WriteOnlyStream._mov_qword_ptr_reg_eaxedx(dest : TgpRegister; offset : Integer);
begin
   _mov_dword_ptr_reg_reg(dest, offset, gprEAX);
   _mov_dword_ptr_reg_reg(dest, offset+4, gprEDX);
end;

// _mov_eaxedx_qword_ptr_reg
//
procedure Tx86WriteOnlyStream._mov_eaxedx_qword_ptr_reg(src : TgpRegister; offset : Integer);
begin
   _mov_reg_dword_ptr_reg(gprEAX, src, offset);
   _mov_reg_dword_ptr_reg(gprEDX, src, offset+4);
end;

// _mov_reg_dword
//
procedure Tx86WriteOnlyStream._mov_reg_dword(reg : TgpRegister; imm : DWORD);
begin
   if imm=0 then
      _xor_reg_reg(reg, reg)
   else begin
      WriteBytes([$B8+Ord(reg)]);
      WriteDWord(imm);
   end;
end;

// _inc_eaxedx_imm
//
procedure Tx86WriteOnlyStream._inc_eaxedx_imm(const imm : Int64);
begin
   if imm=0 then Exit;

   _add_reg_int32(gprEAX, imm);
   _adc_reg_int32(gprEDX, imm shr 32);
end;

// _cmp_execmem_int32
//
procedure Tx86WriteOnlyStream._cmp_execmem_int32(stackAddr, offset, value : Integer);
begin
   _modRMSIB_op_execmem_int32($83, $78, stackAddr, offset, value);
end;

// _cmp_execmem_reg
//
procedure Tx86WriteOnlyStream._cmp_execmem_reg(stackAddr, offset : Integer; reg : TgpRegister);
begin
   _cmp_dword_ptr_reg_reg(cExecMemGPR, StackAddrToOffset(stackAddr)+offset, reg);
end;

// _cmp_execmem_reg
//
procedure Tx86WriteOnlyStream._cmp_dword_ptr_reg_reg(dest : TgpRegister; offset : Integer; reg : TgpRegister);
begin
   _modRMSIB_regnum_ptr_reg([$39], Ord(reg), dest, offset);
end;

// _set_al_flags
//
procedure Tx86WriteOnlyStream._set_al_flags(flags : TboolFlags);
begin
   WriteBytes([$0F, Ord(flags)+$20, $C0]);
end;

// _op_reg_int32
//
procedure Tx86WriteOnlyStream._op_reg_int32(const op : TgpOP; reg : TgpRegister; value : Integer);
begin
   if (value>=-128) and (value<=127) then
      WriteBytes([op.Short1, op.SIB+Ord(reg), value])
   else begin
      if reg=gprEAX then
         WriteBytes([op.LongEAX+Ord(reg)])
      else WriteBytes([op.Long1, op.SIB+Ord(reg)]);
      WriteInt32(value);
   end;
end;

// _add_reg_int32
//
procedure Tx86WriteOnlyStream._add_reg_int32(reg : TgpRegister; value : Integer);
begin
   _op_reg_int32(gpOp_add, reg, value);
end;

// _adc_reg_int32
//
procedure Tx86WriteOnlyStream._adc_reg_int32(reg : TgpRegister; value : Integer);
begin
   _op_reg_int32(gpOp_adc, reg, value);
end;

// _sub_reg_int32
//
procedure Tx86WriteOnlyStream._sub_reg_int32(reg : TgpRegister; value : Integer);
begin
   _op_reg_int32(gpOp_sub, reg, value);
end;

// _sbb_reg_int32
//
procedure Tx86WriteOnlyStream._sbb_reg_int32(reg : TgpRegister; value : Integer);
begin
   _op_reg_int32(gpOp_sbb, reg, value);
end;

// _add_execmem_int32
//
procedure Tx86WriteOnlyStream._add_execmem_int32(stackAddr, offset, value : Integer);
begin
   _modRMSIB_op_execmem_int32($83, $40, stackAddr, offset, value);
end;

// _adc_execmem_int32
//
procedure Tx86WriteOnlyStream._adc_execmem_int32(stackAddr, offset, value : Integer);
begin
   _modRMSIB_op_execmem_int32($83, $50, stackAddr, offset, value);
end;

// _sub_execmem_int32
//
procedure Tx86WriteOnlyStream._sub_execmem_int32(stackAddr, offset, value : Integer);
begin
   _modRMSIB_op_execmem_int32($83, $68, stackAddr, offset, value);
end;

// _sbb_execmem_int32
//
procedure Tx86WriteOnlyStream._sbb_execmem_int32(stackAddr, offset, value : Integer);
begin
   _modRMSIB_op_execmem_int32($83, $58, stackAddr, offset, value);
end;

// _int64_inc
//
procedure Tx86WriteOnlyStream._int64_inc(stackAddr : Integer; const imm : Int64);
begin
   _add_execmem_int32(stackAddr, 0, imm);
   _adc_execmem_int32(stackAddr, 4, imm shr 32);
end;

// _int64_dec
//
procedure Tx86WriteOnlyStream._int64_dec(stackAddr : Integer; const imm : Int64);
begin
   _sub_execmem_int32(stackAddr, 0, imm);
   _sbb_execmem_int32(stackAddr, 4, imm shr 32);
end;

// _fild_execmem
//
procedure Tx86WriteOnlyStream._fild_execmem(stackAddr : Integer);
var
   offset : Integer;
begin
   offset:=StackAddrToOffset(stackAddr);

   if (offset>=-128) and (offset<=127) then

      WriteBytes([$DF, $68+Ord(cExecMemGPR), offset])

   else begin

      WriteBytes([$DF, $A8+Ord(cExecMemGPR)]);
      WriteInt32(offset);

   end;
end;

// _fistp_esp
//
procedure Tx86WriteOnlyStream._fistp_esp;
begin
   WriteBytes([$DF, $3C, $24]);
end;

// _fld_esp
//
procedure Tx86WriteOnlyStream._fld_esp;
begin
   // fld qword ptr [esp]
   WriteBytes([$DD, $04, $24]);
end;

// _fstp_esp
//
procedure Tx86WriteOnlyStream._fstp_esp;
begin
   // fstp qword ptr [esp]
   WriteBytes([$DD, $1C, $24]);
end;

// _push_reg
//
procedure Tx86WriteOnlyStream._push_reg(reg : TgpRegister);
begin
   WriteBytes([$50+Ord(reg)]);
end;

// _pop_reg
//
procedure Tx86WriteOnlyStream._pop_reg(reg : TgpRegister);
begin
   WriteBytes([$58+Ord(reg)]);
end;

// _xor_reg_reg
//
procedure Tx86WriteOnlyStream._xor_reg_reg(dest, src : TgpRegister);
begin
   WriteBytes([$31, $C0+Ord(dest)+Ord(src)*8]);
end;

// _call_reg
//
procedure Tx86WriteOnlyStream._call_reg(reg : TgpRegister; offset : Integer);
begin
   WriteByte($FF);
   _modRMSIB_ptr_reg($10, reg, offset)
end;

// _call_absmem
//
procedure Tx86WriteOnlyStream._call_absmem(ptr : Pointer);
begin
   WriteBytes([$FF, $15]);
   WritePointer(ptr);
end;

// _test_al_al
//
procedure Tx86WriteOnlyStream._test_al_al;
begin
   WriteBytes([$84, $C0]);
end;

// _nop
//
procedure Tx86WriteOnlyStream._nop(nb : Integer);
begin
   while nb>=3 do begin
      WriteBytes([$66, $66, $90]);
      Dec(nb, 3);
   end;
   case nb of
      1 : WriteBytes([$90]);
      2 : WriteBytes([$66, $90]);
   end;
end;

// _ret
//
procedure Tx86WriteOnlyStream._ret;
begin
   WriteBytes([$C3]);
end;

end.