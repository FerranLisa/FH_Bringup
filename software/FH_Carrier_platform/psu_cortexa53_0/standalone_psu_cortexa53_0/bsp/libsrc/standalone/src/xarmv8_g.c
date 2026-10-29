#include "xarmv8.h"

XARMv8_Config XARMv8_ConfigTable[] __attribute__ ((section (".drvcfg_sec"))) = {
	{
		0x1fca054,  /* stamp-frequency */
		0x3e95ba80,  /* cpu-frequency */
		0x0  /* reg */
	}
};