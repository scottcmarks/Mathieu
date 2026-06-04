// Public API for the M12 engine. Picks the native (dart:ffi) implementation
// off the web, and the js_interop/WASM implementation on the web.
export 'mathieu_ffi_io.dart' if (dart.library.js_interop) 'mathieu_ffi_web.dart';
