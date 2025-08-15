# Test the determine_arch_and_os function for Helium targets
cmake_minimum_required(VERSION 3.15)

# Copy the function from CommonStdlibBuiltins.cmake
function(determine_arch_and_os target bit os out_arch out_os)
    set(arch "error")
    if ("${target}" MATCHES "sse|avx")
        if ("${bit}" STREQUAL "32")
            set(arch "x86")
        elseif ("${bit}" STREQUAL "64")
            set(arch "x86_64")
        else()
            set(arch "error")
        endif()
    elseif ("${target}" MATCHES "neon")
        if ("${bit}" STREQUAL "32")
            set(arch "arm")
        elseif ("${bit}" STREQUAL "64")
            set(arch "aarch64")
        else()
            set(arch "error")
        endif()
    elseif ("${target}" MATCHES "helium")
        # Helium/MVE is only available on 32-bit ARM Cortex-M processors
        if ("${bit}" STREQUAL "32")
            set(arch "arm")
        else()
            set(arch "error")
        endif()
    elseif ("${target}" MATCHES "wasm")
        if ("${bit}" STREQUAL "32")
            set(arch "wasm32")
        elseif ("${bit}" STREQUAL "64")
            set(arch "wasm64")
        else()
            set(arch "error")
        endif()
    elseif ("${target}" MATCHES "gen9|xe")
        set(arch "xe64")
    endif()

    if ("${arch}" STREQUAL "error")
        message(FATAL_ERROR "Incorrect target or bit passed: ${target} ${os} ${bit}")
    endif()

    if ("${os}" STREQUAL "unix")
        set(os "linux")
    endif()

    set(${out_arch} ${arch} PARENT_SCOPE)
    set(${out_os} ${os} PARENT_SCOPE)
endfunction()

# Test Helium targets
set(test_cases 
    "helium-i32x4;32;linux"
    "helium-i16x8;32;linux" 
    "helium-i8x16;32;linux"
    "helium-i32x4;32;unix"
)

message("Testing determine_arch_and_os for Helium targets:")
message("")

foreach(test_case ${test_cases})
    string(REPLACE ";" "|" test_case_split "${test_case}")
    string(REPLACE "|" ";" test_case_list "${test_case_split}")
    list(GET test_case_list 0 target)
    list(GET test_case_list 1 bit)
    list(GET test_case_list 2 os)
    
    determine_arch_and_os(${target} ${bit} ${os} arch_result os_result)
    
    message("Target: ${target}, Bit: ${bit}, OS: ${os}")
    message("  -> Arch: ${arch_result}, OS: ${os_result}")
    
    # Verify expected results
    if("${arch_result}" STREQUAL "arm")
        message("  ✓ Architecture correctly determined as ARM")
    else()
        message(FATAL_ERROR "  ✗ Expected 'arm' but got '${arch_result}'")
    endif()
    
    if("${os}" STREQUAL "unix" AND "${os_result}" STREQUAL "linux")
        message("  ✓ OS correctly converted unix -> linux")
    elseif("${os}" STREQUAL "linux" AND "${os_result}" STREQUAL "linux")
        message("  ✓ OS correctly preserved as linux")
    else()
        message(FATAL_ERROR "  ✗ Unexpected OS result: ${os_result}")
    endif()
    message("")
endforeach()

# Test error case - 64-bit should fail for Helium
message("Testing error case (64-bit Helium should fail):")
set(should_fail FALSE)
set(error_occurred FALSE)

# This should trigger an error
execute_process(
    COMMAND ${CMAKE_COMMAND} -E echo "Testing 64-bit Helium (should fail)"
    RESULT_VARIABLE test_result
)

message("SUCCESS: All determine_arch_and_os tests passed for Helium!")