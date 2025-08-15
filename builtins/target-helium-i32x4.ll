;;
;; target-helium-i32x4.ll
;;
;;  Copyright(c) 2025 Intel
;;
;;  SPDX-License-Identifier: BSD-3-Clause

define(`WIDTH',`4')
define(`MASK',`i32')
define(`ISA',`HELIUM')

include(`util.m4')
include(`target-helium-common.ll')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; rsqrt/rcp - Using MVE specific intrinsics

declare <4 x float> @llvm.arm.mve.vrecpe.f32(<4 x float>) nounwind readnone
declare <4 x float> @llvm.arm.mve.vrecps.f32(<4 x float>, <4 x float>) nounwind readnone

define <WIDTH x float> @__rcp_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  %x0 = call <4 x float> @llvm.arm.mve.vrecpe.f32(<4 x float> %d)
  %x0_nr = call <4 x float> @llvm.arm.mve.vrecps.f32(<4 x float> %d, <4 x float> %x0)
  %x1 = fmul <4 x float> %x0, %x0_nr
  %x1_nr = call <4 x float> @llvm.arm.mve.vrecps.f32(<4 x float> %d, <4 x float> %x1)
  %x2 = fmul <4 x float> %x1, %x1_nr
  ret <4 x float> %x2
}

define <WIDTH x float> @__rcp_fast_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  %ret = call <4 x float> @llvm.arm.mve.vrecpe.f32(<4 x float> %d)
  ret <4 x float> %ret
}

declare <4 x float> @llvm.arm.mve.vrsqrte.f32(<4 x float>) nounwind readnone
declare <4 x float> @llvm.arm.mve.vrsqrts.f32(<4 x float>, <4 x float>) nounwind readnone

define <WIDTH x float> @__rsqrt_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  %x0 = call <4 x float> @llvm.arm.mve.vrsqrte.f32(<4 x float> %d)
  %x0_2 = fmul <4 x float> %x0, %x0
  %x0_nr = call <4 x float> @llvm.arm.mve.vrsqrts.f32(<4 x float> %d, <4 x float> %x0_2)
  %x1 = fmul <4 x float> %x0, %x0_nr
  %x1_2 = fmul <4 x float> %x1, %x1
  %x1_nr = call <4 x float> @llvm.arm.mve.vrsqrts.f32(<4 x float> %d, <4 x float> %x1_2)
  %x2 = fmul <4 x float> %x1, %x1_nr
  ret <4 x float> %x2
}

define float @__rsqrt_uniform_float(float) nounwind readnone alwaysinline {
  %v1 = bitcast float %0 to <1 x float>
  %vs = shufflevector <1 x float> %v1, <1 x float> undef,
          <4 x i32> <i32 0, i32 undef, i32 undef, i32 undef>
  %vr = call <4 x float> @__rsqrt_varying_float(<4 x float> %vs)
  %r = extractelement <4 x float> %vr, i32 0
  ret float %r
}

define <WIDTH x float> @__rsqrt_fast_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  %ret = call <4 x float> @llvm.arm.mve.vrsqrte.f32(<4 x float> %d)
  ret <4 x float> %ret
}

define float @__rsqrt_fast_uniform_float(float) nounwind readnone alwaysinline {
  %vs = insertelement <4 x float> undef, float %0, i32 0
  %vr = call <4 x float> @__rsqrt_fast_varying_float(<4 x float> %vs)
  %r = extractelement <4 x float> %vr, i32 0
  ret float %r
}

define float @__rcp_uniform_float(float) nounwind readnone alwaysinline {
  %v1 = bitcast float %0 to <1 x float>
  %vs = shufflevector <1 x float> %v1, <1 x float> undef,
          <4 x i32> <i32 0, i32 undef, i32 undef, i32 undef>
  %vr = call <4 x float> @__rcp_varying_float(<4 x float> %vs)
  %r = extractelement <4 x float> %vr, i32 0
  ret float %r
}

define float @__rcp_fast_uniform_float(float) nounwind readnone alwaysinline {
  %vs = insertelement <4 x float> undef, float %0, i32 0
  %vr = call <4 x float> @__rcp_fast_varying_float(<4 x float> %vs)
  %r = extractelement <4 x float> %vr, i32 0
  ret float %r
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; half conversion routines

half_uniform_conversions()

define <4 x float> @__half_to_float_varying(<4 x i16> %v) nounwind readnone alwaysinline {
  %r = call <4 x float> @HELIUM_PREFIX.vcvthf2fp(<4 x i16> %v)
  ret <4 x float> %r
}

define <4 x i16> @__float_to_half_varying(<4 x float> %v) nounwind readnone alwaysinline {
  %r = call <4 x i16> @HELIUM_PREFIX.vcvtfp2hf(<4 x float> %v)
  ret <4 x i16> %r
}