#include<tinux.h>

PUBLIC char* itoa(char *str, u32 num)
{
	char *p = str;
	char ch;
	int i;
	int flag = 1;
	
	*p++='0';
	*p++='x';
	
	if(num == 0)
		*p++='0';
	else
	{
		for(i = 28; i >=0; i-=4)
		{
			ch = (num >> i) & 0xF;
			//跳过开头的0
			if(ch == 0 && flag)
				continue;
			flag = 0;
			if(ch <= 9)
			{
				ch += '0';
			}
			else if(ch >= 10 )
			{
				ch = ch - 10 + 'A';
			}
			*p++=ch;
		}
	}
	*p = 0;
	return str;
}

PUBLIC void disp_int(u32 input)
{
	char output[16];
	itoa(output, input);
	disp_str(output);
}

/*
	stay
*/

PUBLIC void delay(int time)
{
	int i, j, k;
	for(k=0; k<time; k++)
		for(i=0; i<10; i++)
			for(j=0; j<10000; j++){}
}

