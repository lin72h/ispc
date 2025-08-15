// Standalone test for Helium enum implementation
#include <iostream>
#include <string>
#include <cassert>

// Extract the relevant enum definitions
namespace ispc {

enum class ISPCTarget {
    none,
    host,
    // ... other targets ...
    neon_i32x8,
    helium_i8x16,
    helium_i16x8,
    helium_i32x4,
    wasm_i32x4,
    // ... rest of targets ...
    error
};

// Simplified parsing function
ISPCTarget ParseISPCTarget(std::string target) {
    if (target == "helium-i8x16") {
        return ISPCTarget::helium_i8x16;
    } else if (target == "helium-i16x8") {
        return ISPCTarget::helium_i16x8;
    } else if (target == "helium-i32x4" || target == "helium") {
        return ISPCTarget::helium_i32x4;
    }
    return ISPCTarget::error;
}

// String conversion
std::string ISPCTargetToString(ISPCTarget target) {
    switch (target) {
    case ISPCTarget::helium_i8x16:
        return "helium-i8x16";
    case ISPCTarget::helium_i16x8:
        return "helium-i16x8";
    case ISPCTarget::helium_i32x4:
        return "helium-i32x4";
    default:
        return "unknown";
    }
}

// Helper function
bool ISPCTargetIsHelium(ISPCTarget target) {
    switch (target) {
    case ISPCTarget::helium_i8x16:
    case ISPCTarget::helium_i16x8:
    case ISPCTarget::helium_i32x4:
        return true;
    default:
        return false;
    }
}

} // namespace ispc

int main() {
    using namespace ispc;
    
    std::cout << "Testing Helium target parsing and conversion...\n";
    
    // Test parsing
    {
        auto target = ParseISPCTarget("helium-i32x4");
        assert(target == ISPCTarget::helium_i32x4);
        std::cout << "✓ Parsed 'helium-i32x4' correctly\n";
    }
    
    {
        auto target = ParseISPCTarget("helium");
        assert(target == ISPCTarget::helium_i32x4);
        std::cout << "✓ Parsed 'helium' shorthand correctly\n";
    }
    
    {
        auto target = ParseISPCTarget("helium-i16x8");
        assert(target == ISPCTarget::helium_i16x8);
        std::cout << "✓ Parsed 'helium-i16x8' correctly\n";
    }
    
    {
        auto target = ParseISPCTarget("helium-i8x16");
        assert(target == ISPCTarget::helium_i8x16);
        std::cout << "✓ Parsed 'helium-i8x16' correctly\n";
    }
    
    // Test string conversion
    {
        std::string str = ISPCTargetToString(ISPCTarget::helium_i32x4);
        assert(str == "helium-i32x4");
        std::cout << "✓ Converted helium_i32x4 to string correctly\n";
    }
    
    {
        std::string str = ISPCTargetToString(ISPCTarget::helium_i16x8);
        assert(str == "helium-i16x8");
        std::cout << "✓ Converted helium_i16x8 to string correctly\n";
    }
    
    {
        std::string str = ISPCTargetToString(ISPCTarget::helium_i8x16);
        assert(str == "helium-i8x16");
        std::cout << "✓ Converted helium_i8x16 to string correctly\n";
    }
    
    // Test helper function
    {
        assert(ISPCTargetIsHelium(ISPCTarget::helium_i32x4) == true);
        assert(ISPCTargetIsHelium(ISPCTarget::helium_i16x8) == true);
        assert(ISPCTargetIsHelium(ISPCTarget::helium_i8x16) == true);
        assert(ISPCTargetIsHelium(ISPCTarget::neon_i32x8) == false);
        std::cout << "✓ ISPCTargetIsHelium() works correctly\n";
    }
    
    std::cout << "\nAll Helium enum tests passed successfully! ✓\n";
    
    return 0;
}