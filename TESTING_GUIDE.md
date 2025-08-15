# Testing Guide for ARM Helium/MVE Backend

This guide explains how to test the ARM Helium/MVE backend implementation for ISPC.

## Prerequisites

### 1. Install LLVM with ARM Support

#### Option A: Using Homebrew (macOS)
```bash
# Install LLVM with all targets
brew install llvm

# Add to PATH
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export LLVM_CONFIG="/opt/homebrew/opt/llvm/bin/llvm-config"
```

#### Option B: Using Package Manager (Linux)
```bash
# Ubuntu/Debian
sudo apt-get install llvm-18-dev clang-18 llvm-18-tools

# CentOS/RHEL
sudo yum install llvm-devel clang-devel

# Set environment
export LLVM_CONFIG="/usr/bin/llvm-config-18"
```

#### Option C: Build from Source
```bash
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
mkdir build && cd build

cmake -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DLLVM_TARGETS_TO_BUILD="ARM;AArch64;X86" \
  ../llvm

make -j$(nproc)
sudo make install
```

### 2. Verify LLVM Installation
```bash
llvm-config --version
llvm-config --targets-built | grep ARM
```

## Testing Steps

### Step 1: Basic Compilation Test

```bash
# Create build directory
mkdir build && cd build

# Configure with ARM support
cmake .. -DARM_ENABLED=ON -DCMAKE_BUILD_TYPE=Release

# Build ISPC
make -j$(nproc)
```

### Step 2: Verify Helium Targets

```bash
# Check if Helium targets are recognized
./bin/ispc --help | grep -i target
./bin/ispc --target=helium --help 2>&1 | head -10
```

### Step 3: Test Target Parsing

```bash
# Test target parsing
echo "export void test() {}" > test.ispc

# Test each Helium target
./bin/ispc --target=helium-i32x4 test.ispc -o test_i32x4.o --emit-llvm-text
./bin/ispc --target=helium-i16x8 test.ispc -o test_i16x8.o --emit-llvm-text  
./bin/ispc --target=helium-i8x16 test.ispc -o test_i8x16.o --emit-llvm-text
./bin/ispc --target=helium test.ispc -o test_default.o --emit-llvm-text
```

### Step 4: Test Helium-Specific Features

Create a comprehensive test file:

```bash
cat > helium_comprehensive_test.ispc << 'EOF'
// Comprehensive Helium test
export void vector_add(uniform float a[], uniform float b[], 
                       uniform float result[], uniform int count) {
    foreach (i = 0 ... count) {
        result[i] = a[i] + b[i];
    }
}

export void reciprocal_test(uniform float input[], uniform float output[], 
                           uniform int count) {
    foreach (i = 0 ... count) {
        output[i] = rcp(input[i]);
    }
}

export void rsqrt_test(uniform float input[], uniform float output[], 
                       uniform int count) {
    foreach (i = 0 ... count) {
        output[i] = rsqrt(input[i]);
    }
}

export void fma_test(uniform float a[], uniform float b[], uniform float c[],
                     uniform float result[], uniform int count) {
    foreach (i = 0 ... count) {
        result[i] = a[i] * b[i] + c[i];
    }
}
EOF
```

Compile and examine output:

```bash
# Compile for Helium with verbose output
./bin/ispc --target=helium-i32x4 --emit-llvm-text -O2 \
  helium_comprehensive_test.ispc -o helium_test.ll

# Check for MVE intrinsics in output
grep -i "arm.mve" helium_test.ll
grep -i "vrecpe\|vrsqrte" helium_test.ll
```

### Step 5: Assembly Output Verification

```bash
# Generate assembly to see actual ARM instructions
./bin/ispc --target=helium-i32x4 --emit-asm \
  helium_comprehensive_test.ispc -o helium_test.s

# Look for MVE instructions
grep -E "vrecpe|vrsqrte|vmul|vadd" helium_test.s
```

### Step 6: Cross-Compilation Test

```bash
# Test cross-compilation for ARM
./bin/ispc --target=helium-i32x4 --arch=arm --target-os=linux \
  helium_comprehensive_test.ispc -o helium_arm_test.o

# Verify object file format
file helium_arm_test.o
objdump -h helium_arm_test.o
```

## Expected Results

### 1. Successful Target Recognition
```
✓ --target=helium should be accepted
✓ --target=helium-i32x4 should be accepted  
✓ --target=helium-i16x8 should be accepted
✓ --target=helium-i8x16 should be accepted
```

### 2. LLVM IR Should Contain
```
✓ calls to @llvm.arm.mve.vrecpe.f32
✓ calls to @llvm.arm.mve.vrsqrte.f32
✓ vector types like <4 x float>, <8 x i16>, <16 x i8>
✓ ARM-specific metadata
```

### 3. Assembly Output Should Show
```
✓ MVE instructions: vrecpe.f32, vrsqrte.f32
✓ Vector load/store: vldr, vstr
✓ ARM Thumb-2 encoding
```

## Troubleshooting

### Common Issues

#### 1. LLVM Not Found
```bash
# Error: Failed to find llvm-config
export PATH="/path/to/llvm/bin:$PATH"
export LLVM_CONFIG="/path/to/llvm-config"
```

#### 2. ARM Target Missing
```bash
# Check LLVM targets
llvm-config --targets-built

# If ARM missing, rebuild LLVM with ARM support
```

#### 3. MVE Intrinsics Not Found
```bash
# Check LLVM version (need 18.1+)
llvm-config --version

# Check for ARM MVE support
echo '#include <arm_mve.h>' | clang -E -march=armv8.1-m.main+mve -
```

#### 4. Compilation Errors
```bash
# Check for syntax errors in builtins
m4 -Ibuiltins -DBUILD_OS=UNIX -DRUNTIME=32 \
  builtins/target-helium-i32x4.ll | llvm-as - -o /dev/null
```

## Performance Testing

### Create Benchmark
```bash
cat > helium_benchmark.ispc << 'EOF'
export void saxpy_helium(uniform float a, uniform float x[], 
                         uniform float y[], uniform float result[], 
                         uniform int count) {
    foreach (i = 0 ... count) {
        result[i] = a * x[i] + y[i];
    }
}
EOF
```

### Compare with NEON
```bash
# Compile for Helium
./bin/ispc --target=helium-i32x4 --emit-asm helium_benchmark.ispc -o helium.s

# Compile for NEON  
./bin/ispc --target=neon-i32x4 --emit-asm helium_benchmark.ispc -o neon.s

# Compare instruction counts
echo "Helium instructions:" && wc -l helium.s
echo "NEON instructions:" && wc -l neon.s
```

## Integration with C++

### Create Test Harness
```cpp
// test_helium_integration.cpp
#include <iostream>
#include <vector>
#include <chrono>

// Include generated header
extern "C" {
    void vector_add(float a[], float b[], float result[], int count);
    void reciprocal_test(float input[], float output[], int count);
}

int main() {
    const int N = 1024;
    std::vector<float> a(N, 1.0f);
    std::vector<float> b(N, 2.0f);
    std::vector<float> result(N);
    
    auto start = std::chrono::high_resolution_clock::now();
    vector_add(a.data(), b.data(), result.data(), N);
    auto end = std::chrono::high_resolution_clock::now();
    
    std::cout << "Helium vector add time: " 
              << std::chrono::duration_cast<std::chrono::microseconds>(end - start).count() 
              << " µs" << std::endl;
              
    // Verify results
    for (int i = 0; i < 10; i++) {
        std::cout << "result[" << i << "] = " << result[i] << std::endl;
    }
    
    return 0;
}
```

### Compile and Test
```bash
# Generate header and object
./bin/ispc --target=helium-i32x4 --header=helium_test.h \
  helium_comprehensive_test.ispc -o helium_test.o

# Compile C++ test  
clang++ -I. test_helium_integration.cpp helium_test.o -o test_integration

# Run test (on ARM device or emulator)
./test_integration
```

## Continuous Integration

### Add to CI Pipeline
```yaml
# .github/workflows/helium-test.yml
name: Test Helium Backend
on: [push, pull_request]

jobs:
  test-helium:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Install LLVM
      run: |
        sudo apt-get update
        sudo apt-get install llvm-18-dev clang-18
    - name: Build ISPC
      run: |
        mkdir build && cd build
        cmake .. -DARM_ENABLED=ON
        make -j$(nproc)
    - name: Test Helium Targets
      run: |
        cd build
        echo "export void test() {}" > test.ispc
        ./bin/ispc --target=helium test.ispc -o test.o
        ./bin/ispc --target=helium-i16x8 test.ispc -o test16.o
        ./bin/ispc --target=helium-i8x16 test.ispc -o test8.o
```

This comprehensive testing approach will validate that the Helium backend is working correctly and generating proper ARM MVE code.