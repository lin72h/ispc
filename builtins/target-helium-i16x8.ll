;;
;; target-helium-i16x8.ll
;;
;;  Copyright(c) 2025 Intel
;;
;;  SPDX-License-Identifier: BSD-3-Clause

define(`WIDTH',`8')
define(`MASK',`i16')
define(`ISA',`HELIUM')

include(`util.m4')
include(`target-helium-common.ll')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; rsqrt/rcp - Using MVE specific intrinsics (split into 4-wide operations)

declare <4 x float> @llvm.arm.mve.vrecpe.f32(<4 x float>) nounwind readnone
declare <4 x float> @llvm.arm.mve.vrecps.f32(<4 x float>, <4 x float>) nounwind readnone

define <WIDTH x float> @__rcp_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  ; Split 8 elements into two 4-element groups
  %d_lo = shufflevector <8 x float> %d, <8 x float> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %d_hi = shufflevector <8 x float> %d, <8 x float> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  
  ; Process low group
  %x0_lo = call <4 x float> @llvm.arm.mve.vrecpe.f32(<4 x float> %d_lo)
  %x0_nr_lo = call <4 x float> @llvm.arm.mve.vrecps.f32(<4 x float> %d_lo, <4 x float> %x0_lo)
  %x1_lo = fmul <4 x float> %x0_lo, %x0_nr_lo
  %x1_nr_lo = call <4 x float> @llvm.arm.mve.vrecps.f32(<4 x float> %d_lo, <4 x float> %x1_lo)
  %x2_lo = fmul <4 x float> %x1_lo, %x1_nr_lo
  
  ; Process high group
  %x0_hi = call <4 x float> @llvm.arm.mve.vrecpe.f32(<4 x float> %d_hi)
  %x0_nr_hi = call <4 x float> @llvm.arm.mve.vrecps.f32(<4 x float> %d_hi, <4 x float> %x0_hi)
  %x1_hi = fmul <4 x float> %x0_hi, %x0_nr_hi
  %x1_nr_hi = call <4 x float> @llvm.arm.mve.vrecps.f32(<4 x float> %d_hi, <4 x float> %x1_hi)
  %x2_hi = fmul <4 x float> %x1_hi, %x1_nr_hi
  
  ; Combine results
  %result = shufflevector <4 x float> %x2_lo, <4 x float> %x2_hi, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ret <8 x float> %result
}

define <WIDTH x float> @__rcp_fast_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  ; Split and process
  %d_lo = shufflevector <8 x float> %d, <8 x float> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %d_hi = shufflevector <8 x float> %d, <8 x float> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  
  %ret_lo = call <4 x float> @llvm.arm.mve.vrecpe.f32(<4 x float> %d_lo)
  %ret_hi = call <4 x float> @llvm.arm.mve.vrecpe.f32(<4 x float> %d_hi)
  
  %result = shufflevector <4 x float> %ret_lo, <4 x float> %ret_hi, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ret <8 x float> %result
}

declare <4 x float> @llvm.arm.mve.vrsqrte.f32(<4 x float>) nounwind readnone
declare <4 x float> @llvm.arm.mve.vrsqrts.f32(<4 x float>, <4 x float>) nounwind readnone

define <WIDTH x float> @__rsqrt_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  ; Split and process like rcp
  %d_lo = shufflevector <8 x float> %d, <8 x float> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %d_hi = shufflevector <8 x float> %d, <8 x float> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  
  ; Process low group
  %x0_lo = call <4 x float> @llvm.arm.mve.vrsqrte.f32(<4 x float> %d_lo)
  %x0_2_lo = fmul <4 x float> %x0_lo, %x0_lo
  %x0_nr_lo = call <4 x float> @llvm.arm.mve.vrsqrts.f32(<4 x float> %d_lo, <4 x float> %x0_2_lo)
  %x1_lo = fmul <4 x float> %x0_lo, %x0_nr_lo
  %x1_2_lo = fmul <4 x float> %x1_lo, %x1_lo
  %x1_nr_lo = call <4 x float> @llvm.arm.mve.vrsqrts.f32(<4 x float> %d_lo, <4 x float> %x1_2_lo)
  %x2_lo = fmul <4 x float> %x1_lo, %x1_nr_lo
  
  ; Process high group
  %x0_hi = call <4 x float> @llvm.arm.mve.vrsqrte.f32(<4 x float> %d_hi)
  %x0_2_hi = fmul <4 x float> %x0_hi, %x0_hi
  %x0_nr_hi = call <4 x float> @llvm.arm.mve.vrsqrts.f32(<4 x float> %d_hi, <4 x float> %x0_2_hi)
  %x1_hi = fmul <4 x float> %x0_hi, %x0_nr_hi
  %x1_2_hi = fmul <4 x float> %x1_hi, %x1_hi
  %x1_nr_hi = call <4 x float> @llvm.arm.mve.vrsqrts.f32(<4 x float> %d_hi, <4 x float> %x1_2_hi)
  %x2_hi = fmul <4 x float> %x1_hi, %x1_nr_hi
  
  ; Combine results
  %result = shufflevector <4 x float> %x2_lo, <4 x float> %x2_hi, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ret <8 x float> %result
}

define float @__rsqrt_uniform_float(float) nounwind readnone alwaysinline {
  %v1 = bitcast float %0 to <1 x float>
  %vs = shufflevector <1 x float> %v1, <1 x float> undef,
          <8 x i32> <i32 0, i32 undef, i32 undef, i32 undef, i32 undef, i32 undef, i32 undef, i32 undef>
  %vr = call <8 x float> @__rsqrt_varying_float(<8 x float> %vs)
  %r = extractelement <8 x float> %vr, i32 0
  ret float %r
}

define <WIDTH x float> @__rsqrt_fast_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  %d_lo = shufflevector <8 x float> %d, <8 x float> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %d_hi = shufflevector <8 x float> %d, <8 x float> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  
  %ret_lo = call <4 x float> @llvm.arm.mve.vrsqrte.f32(<4 x float> %d_lo)
  %ret_hi = call <4 x float> @llvm.arm.mve.vrsqrte.f32(<4 x float> %d_hi)
  
  %result = shufflevector <4 x float> %ret_lo, <4 x float> %ret_hi, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ret <8 x float> %result
}

define float @__rsqrt_fast_uniform_float(float) nounwind readnone alwaysinline {
  %vs = insertelement <8 x float> undef, float %0, i32 0
  %vr = call <8 x float> @__rsqrt_fast_varying_float(<8 x float> %vs)
  %r = extractelement <8 x float> %vr, i32 0
  ret float %r
}

define float @__rcp_uniform_float(float) nounwind readnone alwaysinline {
  %v1 = bitcast float %0 to <1 x float>
  %vs = shufflevector <1 x float> %v1, <1 x float> undef,
          <8 x i32> <i32 0, i32 undef, i32 undef, i32 undef, i32 undef, i32 undef, i32 undef, i32 undef>
  %vr = call <8 x float> @__rcp_varying_float(<8 x float> %vs)
  %r = extractelement <8 x float> %vr, i32 0
  ret float %r
}

define float @__rcp_fast_uniform_float(float) nounwind readnone alwaysinline {
  %vs = insertelement <8 x float> undef, float %0, i32 0
  %vr = call <8 x float> @__rcp_fast_varying_float(<8 x float> %vs)
  %r = extractelement <8 x float> %vr, i32 0
  ret float %r
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; half conversion routines - Helium/MVE supports native half precision

half_uniform_conversions()

declare <8 x half> @llvm.arm.mve.vcvt.fp.int.predicated.v8f16.v8i16.v8i1(<8 x i16>, i32, <8 x i1>, <8 x half>) nounwind readnone
declare <8 x i16> @llvm.arm.mve.vcvt.fix.predicated.v8i16.v8f16.v8i1(i32, <8 x half>, i32, <8 x i1>, <8 x i16>) nounwind readnone

define <8 x float> @__half_to_float_varying(<8 x i16> %v) nounwind readnone alwaysinline {
  ; Split into two groups of 4 for conversion
  %v_lo = shufflevector <8 x i16> %v, <8 x i16> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %v_hi = shufflevector <8 x i16> %v, <8 x i16> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  
  %f_lo = call <4 x float> @HELIUM_PREFIX.vcvthf2fp(<4 x i16> %v_lo)
  %f_hi = call <4 x float> @HELIUM_PREFIX.vcvthf2fp(<4 x i16> %v_hi)
  
  %result = shufflevector <4 x float> %f_lo, <4 x float> %f_hi, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ret <8 x float> %result
}

define <8 x i16> @__float_to_half_varying(<8 x float> %v) nounwind readnone alwaysinline {
  ; Split into two groups of 4 for conversion
  %v_lo = shufflevector <8 x float> %v, <8 x float> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %v_hi = shufflevector <8 x float> %v, <8 x float> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  
  %h_lo = call <4 x i16> @HELIUM_PREFIX.vcvtfp2hf(<4 x float> %v_lo)
  %h_hi = call <4 x i16> @HELIUM_PREFIX.vcvtfp2hf(<4 x float> %v_hi)
  
  %result = shufflevector <4 x i16> %h_lo, <4 x i16> %h_hi, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ret <8 x i16> %result
}