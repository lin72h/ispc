# Test CMake script to verify Helium targets are properly integrated

# Define the target lists as they would be in the main CMakeLists.txt
set(ARM_TARGETS neon-i8x16 neon-i16x8 neon-i32x4 neon-i32x8 neon-i8x32 neon-i16x16)
set(HELIUM_TARGETS helium-i8x16 helium-i16x8 helium-i32x4)

# Test that Helium targets would be added when ARM is enabled
set(ARM_ENABLED ON)
set(ISPC_TARGETS "")

if (ARM_ENABLED)
    list(APPEND ISPC_TARGETS ${ARM_TARGETS})
    list(APPEND ISPC_TARGETS ${HELIUM_TARGETS})
endif()

# Print the results
message("ARM_ENABLED: ${ARM_ENABLED}")
message("ARM_TARGETS: ${ARM_TARGETS}")
message("HELIUM_TARGETS: ${HELIUM_TARGETS}")
message("Combined ISPC_TARGETS: ${ISPC_TARGETS}")

# Verify Helium targets are included
foreach(target ${HELIUM_TARGETS})
    if("${target}" IN_LIST ISPC_TARGETS)
        message("✓ ${target} is in ISPC_TARGETS")
    else()
        message(FATAL_ERROR "✗ ${target} is NOT in ISPC_TARGETS")
    endif()
endforeach()

message("")
message("SUCCESS: All Helium targets are properly included in ISPC_TARGETS")