  1 // This is free and unencumbered software released into the public domain.
  2 
  3 // Anyone is free to copy, modify, publish, use, compile, sell, or
  4 // distribute this software, either in source code form or as a compiled
  5 // binary, for any purpose, commercial or non-commercial, and by any
  6 // means.
  7 
  8 // In jurisdictions that recognize copyright laws, the author or authors
  9 // of this software dedicate any and all copyright interest in the
 10 // software to the public domain. We make this dedication for the benefit
 11 // of the public at large and to the detriment of our heirs and
 12 // successors. We intend this dedication to be an overt act of
 13 // relinquishment in perpetuity of all present and future rights to this
 14 // software under copyright law.
 15 
 16 // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 17 // EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 18 // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 19 // IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 20 // OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 21 // ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 22 // OTHER DEALINGS IN THE SOFTWARE.
 23 
 24 // For more information, please refer to <https://unlicense.org>
 25 
 26 //!DESC Anime4K-v4.0-AutoDownscalePre-x2
 27 //!HOOK MAIN
 28 //!BIND HOOKED
 29 //!BIND NATIVE
 30 //!WHEN OUTPUT.w NATIVE.w / 2.0 < OUTPUT.h NATIVE.h / 2.0 < * OUTPUT.w NATIVE.w / 1.2 > OUTPUT.h NATIVE.h / 1.2 > * *
 31 //!WIDTH OUTPUT.w
 32 //!HEIGHT OUTPUT.h
 33 
 34 vec4 hook() {
 35     return HOOKED_tex(HOOKED_pos);
 36 }                                                                                                                       
~      
