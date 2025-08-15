;;
;; target-helium-common.ll
;;
;;  Copyright(c) 2025 Intel
;;
;;  SPDX-License-Identifier: BSD-3-Clause

;; ARM Helium/MVE common definitions for Cortex-M processors

declare i1 @__is_compile_time_constant_mask(<WIDTH x MASK> %mask)

declare i64 @__movmsk(<WIDTH x MASK>) nounwind readnone alwaysinline

declare i32 @llvm.ctpop.i32(i32) nounwind readnone
declare i64 @llvm.ctpop.i64(i64) nounwind readnone

;; Helium/MVE intrinsics use llvm.arm.mve prefix for ARMv8.1-M
define(`HELIUM_PREFIX', `llvm.arm.mve')

;; Helium/MVE specific reciprocal intrinsics
define(`HELIUM_PREFIX_RECPEQ',
`llvm.arm.mve.vrecpe')

define(`HELIUM_PREFIX_RECPSQ',
`llvm.arm.mve.vrecps')

define(`HELIUM_PREFIX_RSQRTEQ',
`llvm.arm.mve.vrsqrte')

define(`HELIUM_PREFIX_RSQRTSQ',
`llvm.arm.mve.vrsqrts')

;; Helium/MVE dot product intrinsics
define(`HELIUM_PREFIX_UDOT',
`llvm.arm.mve.udot')

define(`HELIUM_PREFIX_SDOT',
`llvm.arm.mve.sdot')

define(`HELIUM_PREFIX_USDOT',
`llvm.arm.mve.usdot')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; half conversion routines

define(`half_uniform_conversions',
`declare <4 x i16> @HELIUM_PREFIX.vcvtfp2hf(<4 x float>) nounwind readnone
declare <4 x float> @HELIUM_PREFIX.vcvthf2fp(<4 x i16>) nounwind readnone

define float @__half_to_float_uniform(i16 %v) nounwind readnone alwaysinline {
  %v1 = bitcast i16 %v to <1 x i16>
  %vec = shufflevector <1 x i16> %v1, <1 x i16> undef, 
           <4 x i32> <i32 0, i32 0, i32 0, i32 0>
  %h = call <4 x float> @HELIUM_PREFIX.vcvthf2fp(<4 x i16> %vec)
  %r = extractelement <4 x float> %h, i32 0
  ret float %r
}

define i16 @__float_to_half_uniform(float %v) nounwind readnone alwaysinline {
  %v1 = bitcast float %v to <1 x float>
  %vec = shufflevector <1 x float> %v1, <1 x float> undef, 
           <4 x i32> <i32 0, i32 0, i32 0, i32 0>
  %h = call <4 x i16> @HELIUM_PREFIX.vcvtfp2hf(<4 x float> %vec)
  %r = extractelement <4 x i16> %h, i32 0
  ret i16 %r
}
')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; math - ARM Helium uses FPSCR register for FP control

define(`math_flags_functions',
`
  declare void @llvm.arm.set.fpscr(i32) nounwind
  declare i32 @llvm.arm.get.fpscr() nounwind

  define void @__fastmath() nounwind alwaysinline {
    %x = call i32 @llvm.arm.get.fpscr()
    ; Turn on FTZ (bit 24) and default NaN (bit 25)
    %y = or i32 %x, 50331648
    call void @llvm.arm.set.fpscr(i32 %y)
    ret void
  }

  define i32 @__set_ftz_daz_flags() nounwind alwaysinline {
    %x = call i32 @llvm.arm.get.fpscr()
    ; Turn on FTZ (bit 24) and default NaN (bit 25)
    %y = or i32 %x, 50331648
    call void @llvm.arm.set.fpscr(i32 %y)
    ret i32 %x
  }

  define void @__restore_ftz_daz_flags(i32 %oldVal) nounwind alwaysinline {
    ; restore value to previously saved
    call void @llvm.arm.set.fpscr(i32 %oldVal)
    ret void
  }
')

aossoa()
packed_load_and_store(FALSE)
math_flags_functions()