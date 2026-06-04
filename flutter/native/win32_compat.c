// win32_compat.c — arc4random shim for Windows (MSVC)
// macOS/iOS/Linux/Android have arc4random in libc.
#ifdef _WIN32

#include <stdint.h>
#include <windows.h>
#include <bcrypt.h>
#pragma comment(lib, "bcrypt.lib")

uint32_t arc4random(void) {
    uint32_t val;
    BCryptGenRandom(NULL, (PUCHAR)&val, sizeof(val),
                    BCRYPT_USE_SYSTEM_PREFERRED_RNG);
    return val;
}

uint32_t arc4random_uniform(uint32_t upper_bound) {
    if (upper_bound < 2) return 0;
    uint32_t min = -upper_bound % upper_bound;  // rejection threshold
    for (;;) {
        uint32_t r = arc4random();
        if (r >= min)
            return r % upper_bound;
    }
}

#endif // _WIN32
