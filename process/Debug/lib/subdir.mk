################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
ASM_SRCS += \
../lib/klib.asm \
../lib/string.asm 

C_SRCS += \
../lib/klibc.c 

OBJS += \
./lib/klib.o \
./lib/klibc.o \
./lib/string.o 

C_DEPS += \
./lib/klibc.d 


# Each subdirectory must supply rules for building sources it contributes
lib/%.o: ../lib/%.asm
	@echo 'Building file: $<'
	@echo 'Invoking: GCC Assembler'
	as  -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

lib/%.o: ../lib/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	gcc -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


