// Basic AMDGPU test - vector addition
// This tests basic SIMD operations on AMD GPU

export void vector_add(uniform float input1[], uniform float input2[], 
                      uniform float output[], uniform int count) {
    foreach (i = 0 ... count) {
        output[i] = input1[i] + input2[i];
    }
}

export void vector_multiply(uniform float input1[], uniform float input2[], 
                           uniform float output[], uniform int count) {
    foreach (i = 0 ... count) {
        output[i] = input1[i] * input2[i];
    }
}

// Test half-precision support (FP16)
export void half_precision_test(uniform float16 input[], uniform float16 output[], 
                               uniform int count) {
    foreach (i = 0 ... count) {
        output[i] = input[i] * 2.0h;
    }
}

// Test transcendental functions
export void transcendental_test(uniform float input[], uniform float output[], 
                               uniform int count) {
    foreach (i = 0 ... count) {
        output[i] = sin(input[i]) + cos(input[i]);
    }
}

// Test gather/scatter operations
export void gather_scatter_test(uniform float input[], uniform int indices[], 
                               uniform float output[], uniform int count) {
    foreach (i = 0 ... count) {
        float value = input[indices[i]];
        output[i] = value * value;
    }
}