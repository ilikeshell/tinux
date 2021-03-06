#define GLOBAL_VARIABLES_HERE

#include <tinux.h>
//#include <type.h>
//#include <const.h>
#include <protect.h>
#include <proto.h>
#include <global.h>
#include <proc.h>

PUBLIC void init_disp_pos()
{
	disp_pos = 0;

}

PUBLIC PROCESS 	proc_table[NR_TASKS];
PUBLIC char 	task_stack[STACK_SIZE_TOTAL];
PUBLIC irq_handler irq_table[NR_IRQ];

/* 定义任务表 */
PUBLIC TASK 	task_table[NR_TASKS] = {
		{TestA, STACK_SIZE_TESTA, "STACK_SIZE_TESTA"},
		{TestB, STACK_SIZE_TESTB, "STACK_SIZE_TESTB"},
		{TestC, STACK_SIZE_TESTC, "STACK_SIZE_TESTC"},
};

/* 定义系统调用表 */
PUBLIC system_call sys_call_table[NR_SYS_CALL] = {sys_get_ticks};

