cmake_minimum_required(VERSION 3.2)
project(g)

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
    kernel/start.c
    lib/klib.asm
    lib/string.asm
    makefile)

add_executable(g ${SOURCE_FILES})