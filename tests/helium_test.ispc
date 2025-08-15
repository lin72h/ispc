// Test file for ARM Helium/MVE SIMD backend
// Copyright (c) 2025 Intel
// SPDX-License-Identifier: BSD-3-Clause

// Basic vector add operation
export void vector_add_helium(uniform float a[], uniform float b[], 
                              uniform float result[], uniform int count) {
    foreach (i = 0 ... count) {
        result[i] = a[i] + b[i];
    }
}

// Test reciprocal square root using Helium intrinsics
export void rsqrt_test_helium(uniform float input[], uniform float output[], 
                              uniform int count) {
    foreach (i = 0 ... count) {
        output[i] = rsqrt(input[i]);
    }
}

// Test reciprocal using Helium intrinsics
export void rcp_test_helium(uniform float input[], uniform float output[], 
                            uniform int count) {
    foreach (i = 0 ... count) {
        output[i] = rcp(input[i]);
    }
}

// Test dot product operation
export uniform float dot_product_helium(uniform float a[], uniform float b[], 
                                        uniform int count) {
    float sum = 0.0f;
    foreach (i = 0 ... count) {
        sum += a[i] * b[i];
    }
    return reduce_add(sum);
}

// Test half precision conversion
export void half_conversion_test(uniform float input[], uniform int16 output[], 
                                 uniform int count) {
    foreach (i = 0 ... count) {
        output[i] = float_to_half(input[i]);
    }
}

// Test vector multiply-add operation (FMA)
export void fma_test_helium(uniform float a[], uniform float b[], 
                            uniform float c[], uniform float result[], 
                            uniform int count) {
    foreach (i = 0 ... count) {
        result[i] = a[i] * b[i] + c[i];
    }
}