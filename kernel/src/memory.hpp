#ifndef MEMORY_HPP
#define MEMORY_HPP

#include <cstdint>
#include <cstddef>

extern "C" {

void *memcpy(void *__restrict dest, const void *__restrict src, std::size_t n);
void *memset(void *s, int c, std::size_t n);
void *memmove(void *dest, const void *src, std::size_t n);
int memcmp(const void *s1, const void *s2, std::size_t n);

}

// Make uses of these functions go through the compiler builtins, which the
// compiler can optimise (e.g. inline) even when building freestanding code,
// falling back to calling the implementations in memory.cpp otherwise.
#define memcpy __builtin_memcpy
#define memset __builtin_memset
#define memmove __builtin_memmove
#define memcmp __builtin_memcmp

#endif
