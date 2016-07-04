################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
ASM_SRCS += \
../kernel/kernel.asm 

C_SRCS += \
../kernel/8259A.c \
../kernel/global.c \
../kernel/main.c \
../kernel/protect.c \
../kernel/start.c 

OBJS += \
./kernel/8259A.o \
./kernel/global.o \
./kernel/kernel.o \
./kernel/main.o \
./kernel/protect.o \
./kernel/start.o 

C_DEPS += \
./kernel/8259A.d \
./kernel/global.d \
./kernel/main.d \
./kernel/protect.d \
./kernel/start.d 


# Each subdirectory must supply rules for building sources it contributes
kernel/%.o: ../kernel/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	gcc -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

kernel/%.o: ../kernel/%.asm
	@echo 'Building file: $<'
	@echo 'Invoking: GCC Assembler'
	as  -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


