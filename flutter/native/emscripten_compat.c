// emscripten_compat.c — arc4random shim for Emscripten (WASM)
// Uses Web Crypto API via Emscripten's EM_JS for secure randomness.
#ifdef __EMSCRIPTEN__

#include <stdint.h>
#include <emscripten.h>

// EM_JS inlines JavaScript — crypto.getRandomValues is available in all
// modern browsers and in Node.js (globalThis.crypto).
EM_JS(uint32_t, arc4random, (), {
    var buf = new Uint32Array(1);
    crypto.getRandomValues(buf);
    return buf[0];
});

uint32_t arc4random_uniform(uint32_t upper_bound) {
    if (upper_bound < 2) return 0;
    uint32_t min = (uint32_t)(-(int32_t)upper_bound) % upper_bound;
    for (;;) {
        uint32_t r = arc4random();
        if (r >= min)
            return r % upper_bound;
    }
}

#endif // __EMSCRIPTEN__
