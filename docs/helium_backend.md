# ARM Helium/MVE Backend for ISPC

## Overview

This document describes the ARM Helium (M-profile Vector Extension - MVE) backend implementation for Intel® ISPC. Helium is ARM's vector extension specifically designed for Cortex-M processors, providing SIMD capabilities for embedded and IoT applications.

## Target Architecture

ARM Helium/MVE is available on:
- ARMv8.1-M processors (Cortex-M55, Cortex-M85)
- 32-bit architecture only
- 128-bit vector width
- Supports both integer and floating-point operations

## Supported Targets

The following ISPC targets are available for Helium:

- `helium-i8x16`: 16-wide 8-bit integer operations
- `helium-i16x8`: 8-wide 16-bit integer operations  
- `helium-i32x4`: 4-wide 32-bit integer/float operations (default)

Use `helium` as a shorthand for `helium-i32x4`.

## Usage

To compile ISPC code for Helium targets:

```bash
ispc --target=helium-i32x4 input.ispc -o output.o
```

Or use the shorthand:

```bash
ispc --target=helium input.ispc -o output.o
```

## Features

### Supported Operations

The Helium backend provides optimized implementations for:

1. **Arithmetic Operations**
   - Vector add, subtract, multiply
   - Fused multiply-add (FMA)
   - Reciprocal and reciprocal square root

2. **Data Type Conversions**
   - Half-precision (fp16) to single-precision (fp32) conversion
   - Integer to float conversions

3. **Reduction Operations**
   - Horizontal add/sum
   - Min/max reductions

4. **Memory Operations**
   - Aligned and unaligned loads/stores
   - Gather/scatter operations (limited)

### LLVM Intrinsics

The implementation uses LLVM's ARM MVE intrinsics with the `llvm.arm.mve.*` prefix:

- `llvm.arm.mve.vrecpe.f32`: Reciprocal estimate
- `llvm.arm.mve.vrsqrte.f32`: Reciprocal square root estimate
- `llvm.arm.mve.vcvt.*`: Type conversion operations
- `llvm.arm.mve.vdot`: Dot product operations

## Implementation Details

### Architecture Mapping

Helium targets are mapped to the ARM architecture with specific constraints:
- Only 32-bit ARM mode is supported (no 64-bit)
- Requires ARMv8.1-M or later
- Uses FPSCR register for floating-point control

### Predication

Helium supports predicated execution through its VPR (Vector Predication Register), allowing efficient handling of ISPC's varying control flow.

## Performance Considerations

1. **Vector Width**: Helium uses 128-bit vectors, providing:
   - 4 x 32-bit operations
   - 8 x 16-bit operations
   - 16 x 8-bit operations

2. **Memory Access**: Best performance with aligned memory accesses

3. **Reciprocal Operations**: Hardware provides fast reciprocal estimates with refinement steps for accuracy

## Building ISPC with Helium Support

To build ISPC with Helium backend support:

```bash
cmake .. -DARM_ENABLED=ON
make
```

Ensure you have LLVM 18.1 or later with ARM target support.

## Limitations

1. **Platform**: Only available on 32-bit ARM Cortex-M processors
2. **OS Support**: Primarily for embedded systems (not Windows)
3. **Gather/Scatter**: Limited compared to x86 AVX512
4. **Double Precision**: Not supported (Helium is single-precision only)

## Example Code

```ispc
export void vector_multiply_helium(uniform float a[], uniform float b[], 
                                   uniform float result[], uniform int count) {
    foreach (i = 0 ... count) {
        result[i] = a[i] * b[i];
    }
}
```

When compiled with `--target=helium-i32x4`, this generates optimized MVE vector instructions.

## Testing

Test files are provided in `tests/helium_test.ispc` demonstrating various Helium-specific optimizations.

## Future Work

- Enhanced gather/scatter support
- Better predication optimization
- Additional intrinsic mappings
- Performance tuning for specific Cortex-M variants

## References

- [ARM MVE Intrinsics Reference](https://developer.arm.com/architectures/instruction-sets/intrinsics/#f:@navigationhierarchiessimdisa=[MVE])
- [ARM Helium Technology](https://www.arm.com/technologies/helium)
- [LLVM ARM Backend Documentation](https://llvm.org/docs/ARMBackend.html)