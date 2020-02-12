/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            string.h
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    langfeng, 2015
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* 所需的函数声明 */
PUBLIC void* memcpy(void* pDst, void* pSrc, int iSize);
PUBLIC void  memset(void* pdest, char ch, int size);
PUBLIC char* itoa(char *str, u32 num);
PUBLIC char*  strcpy(void* pdest, void* psource);
