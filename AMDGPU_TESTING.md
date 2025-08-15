# AMDGPU Backend Testing Guide

## Overview

This guide explains how to test the new AMDGPU backend for ISPC, including different runtime options and testing strategies.

## Build Requirements

### 1. Basic Build (IR Generation Only)
```bash
# Build ISPC with AMDGPU support
mkdir build && cd build
cmake -DAMDGPU_ENABLED=ON -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
```

### 2. Full ROCm Build (Recommended)
```bash
# Install ROCm first
wget https://repo.radeon.com/amdgpu-install/latest/ubuntu/jammy/amdgpu-install_*_all.deb
sudo dpkg -i amdgpu-install_*_all.deb
sudo amdgpu-install --usecase=rocm

# Build with ROCm support
mkdir build && cd build
cmake -DAMDGPU_ENABLED=ON -DCMAKE_BUILD_TYPE=Release \
      -DROCM_PATH=/opt/rocm ..
make -j$(nproc)
```

## Testing Levels

### Level 1: Compilation Testing (No GPU Required)
Test that ISPC can generate AMDGPU LLVM IR:

```bash
# Test basic compilation for all AMDGPU targets
./ispc --target=amdgcn9-x16 --emit-llvm tests/amdgpu_simple.ispc -o test_gcn9_x16.ll
./ispc --target=amdgcn9-x32 --emit-llvm tests/amdgpu_simple.ispc -o test_gcn9_x32.ll  
./ispc --target=amdgcn9-x64 --emit-llvm tests/amdgpu_simple.ispc -o test_gcn9_x64.ll
./ispc --target=amdrdna3-x16 --emit-llvm tests/amdgpu_simple.ispc -o test_rdna3_x16.ll
./ispc --target=amdrdna3-x32 --emit-llvm tests/amdgpu_simple.ispc -o test_rdna3_x32.ll
./ispc --target=amdrdna3-x64 --emit-llvm tests/amdgpu_simple.ispc -o test_rdna3_x64.ll

# Verify target information
./ispc --target=amdgcn9-x16 --print-target
./ispc --target=amdrdna3-x32 --print-target
```

### Level 2: LLVM IR Validation
Verify the generated IR is valid for AMDGPU:

```bash
# Use LLVM tools to validate IR
llvm-as test_gcn9_x16.ll -o test_gcn9_x16.bc
llvm-dis test_gcn9_x16.bc -o -

# Check for AMDGPU-specific attributes
grep -E "(amdgpu|target-cpu|wavefrontsize)" test_gcn9_x16.ll
```

### Level 3: ROCm Runtime Testing
Test with actual AMD GPU hardware:

```bash
# Verify ROCm installation
rocm-smi
rocminfo

# Generate object files for GPU execution
./ispc --target=amdgcn9-x32 --emit-obj tests/amdgpu_simple.ispc -o kernel.o

# Link with HIP runtime (requires additional host code)
hipcc host_program.cpp kernel.o -o gpu_test
./gpu_test
```

### Level 4: Vulkan Compute Testing (Future)
For Vulkan compute shader execution:

```bash
# Generate SPIR-V (requires additional implementation)
./ispc --target=amdgcn9-x32 --emit-spirv tests/amdgpu_simple.ispc -o kernel.spv

# Use with Vulkan compute (requires Vulkan runtime wrapper)
```

## Runtime Requirements

### ROCm Stack (Recommended)
**Required for full GPU execution:**
- ROCm driver (amdgpu-dkms)  
- ROCm runtime (rocm-dev)
- HIP programming model
- LLVM AMDGPU backend

**Installation:**
```bash
# Ubuntu/Debian
sudo amdgpu-install --usecase=rocm

# Arch Linux  
sudo pacman -S rocm-dev rocm-opencl-dev

# Verify
rocm-smi
hipcc --version
```

### Vulkan Alternative (Partial Support)
**For compute shaders:**
- Vulkan 1.3+ driver
- SPIR-V generation (not yet implemented)
- Vulkan compute wrapper

```bash
# Install Vulkan
sudo apt install vulkan-tools vulkan-validationlayers-dev

# Verify
vulkaninfo | grep "AMD"
```

### Mesa/RADV (Open Source Alternative)
**For development/testing:**
```bash
# Latest Mesa with RADV
sudo add-apt-repository ppa:oibaf/graphics-drivers
sudo apt update && sudo apt upgrade

# Verify RADV
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json vulkaninfo
```

## Test Scripts

### Automated Testing
```bash
# Run backend compilation tests
cd tests
g++ -DISPC_AMDGPU_ENABLED test_amdgpu_backend.cpp -o test_amdgpu
./test_amdgpu

# Run ISPC compilation tests  
bash test_amdgpu_compilation.sh
```

### Performance Testing
```bash
# Compare performance across vector widths
for width in 16 32 64; do
    echo "Testing vector width: $width"
    ./ispc --target=amdgcn9-x$width --emit-llvm perf_test.ispc -o perf_$width.ll
    # Analyze instruction counts, memory access patterns
done
```

## Debugging

### LLVM IR Analysis
```bash
# Verbose compilation
./ispc --target=amdgcn9-x32 -v tests/amdgpu_simple.ispc

# Dump optimization passes
./ispc --target=amdgcn9-x32 --debug-phase=1:10 tests/amdgpu_simple.ispc

# Check target machine info
./ispc --target=amdgcn9-x32 --print-target
```

### ROCm Debugging
```bash
# Profile GPU kernel execution
rocprof ./gpu_test

# Check GPU utilization
rocm-smi -a

# Validate GPU code
/opt/rocm/bin/amdgpu-dis kernel.o
```

## Expected Test Results

### Successful Compilation
- ✅ All 6 AMDGPU targets compile without errors
- ✅ Generated LLVM IR contains AMDGPU triple: `amdgcn-amd-amdhsa`
- ✅ Vector widths (16/32/64) reflected in IR
- ✅ Target-specific attributes present

### IR Validation
- ✅ Valid AMDGPU data layout with multiple address spaces
- ✅ Wavefront size attributes (64 for GCN9, 32 for RDNA3)
- ✅ GPU-specific intrinsics and function attributes
- ✅ Proper memory space usage (global, local, private)

### Runtime Execution (With ROCm)
- ✅ HIP kernels execute successfully
- ✅ Correct numerical results
- ✅ Performance comparable to hand-written GPU code
- ✅ Memory coalescing and vectorization working

## Troubleshooting

### Common Issues

1. **"Unknown target" errors:**
   ```bash
   # Ensure AMDGPU_ENABLED=ON during build
   cmake -DAMDGPU_ENABLED=ON ..
   ```

2. **ROCm not found:**
   ```bash
   # Set ROCm path explicitly
   export ROCM_PATH=/opt/rocm
   export PATH=$ROCM_PATH/bin:$PATH
   ```

3. **GPU not detected:**
   ```bash
   # Check AMDGPU driver
   lsmod | grep amdgpu
   rocm-smi
   ```

4. **Vulkan issues:**
   ```bash
   # Check Vulkan layers
   export VK_LOADER_DEBUG=all
   vulkaninfo
   ```

This testing framework allows comprehensive validation of the AMDGPU backend at multiple levels, from basic compilation to full GPU execution.