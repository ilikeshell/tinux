cmake_minimum_required(VERSION 3.2)
project(h)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES
    include/const.h
    include/global.h
    include/protect.h
    include/proto.h
    include/string.h
    include/tinux.h
    include/type.h
    kernel/8259A.c
    kernel/global.c
    kernel/kernel.asm
    kernel/protect.c
    kernel/start.c
    lib/klib.asm
    lib/klibc.c
    lib/string.asm
    makefile)

include_directories(.)
include_directories(include)

add_executable(h ${SOURCE_FILES})