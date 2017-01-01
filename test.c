//goes on sector 3 of floppy

typedef unsigned char byte;
#define VIDEO_MEM_START 0x000B8000				   // not all of these are used, but they are included here for reference
#define KEYBOARD_ONBOARD_CONTROLLER 0x64
#define KEYBOARD_MICROCONTROLLER 0x60


void clearScreen();
void putChar(byte *, byte, byte);
void printString(const char *);
byte getKeypress();
byte getScanCodeAscii(byte scan_code);
void getUserString();
int getPassword();
int testPassword(char *);
unsigned test_function();


int main() 
{	
	int password_rv = getPassword();
	if (password_rv != 0)
	{
		printString("BOOTED");
		while(1);
	}
	printString("Access granted.");	
	while(1);

	getUserString(5);

	return 0;
}

void clearScreen()
{
	byte *VGA_mem_ptr = (byte *)VIDEO_MEM_START;
	while ( VGA_mem_ptr < (byte *)(VIDEO_MEM_START + 4000) )
	{
		*VGA_mem_ptr = 0x20;
		*(VGA_mem_ptr + 1) = 0x04;
		VGA_mem_ptr += 2;
	}
}

void putChar(byte *memory_location, byte ascii_value, byte color) 
{
	*memory_location = ascii_value;
	*(memory_location + 1) = color;
}

void printString(const char *string)
{
	clearScreen();

	byte color = (byte)0x04;
	byte *VGA_mem_ptr = (byte *)VIDEO_MEM_START;
	int counter = 0;
	while (string[counter] != '\0')
	{
		putChar(VGA_mem_ptr, string[counter], color);
		VGA_mem_ptr += 2;
		counter++;
	}
	putChar(VGA_mem_ptr, 0x20, color);
	VGA_mem_ptr += 2;
}
	
byte getKeypress()
{	
		byte key_pressed;

		byte status_byte = 0x00;
		while (status_byte != 0x1D)
		{
			asm ("xor %%eax, %%eax; \
				  inb $0x64, %%al"				 //Could use the defined KEYBOARD_ constants instead of 0x64, 0x60, but that might not be any clearer
				   : "=r"(status_byte) 
				);
		}
		asm ("inb $0x60, %%al"
				   : "=r"(key_pressed)
			);
	
		return key_pressed;
}

byte getScanCodeAscii(byte scan_code)			//Assumes scan code set 1
{
	static byte pressed_scan_codes[36]   =   {0x1E, 0x30, 0x2E, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17, 0x24, 0x25, 0x26,
									  		  0x32, 0x31, 0x18, 0x19, 0x10, 0x13, 0x1F, 0x14, 0x16, 0x2F, 0x11, 0x2D,
									  		  0x15, 0x2C, 0x0B, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A};

	static byte pressed_ascii_values[36] =   {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
									  		  'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
									  		  'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};

	unsigned counter = 0;
	while (counter < 36)
	{
		if (scan_code == pressed_scan_codes[counter])
		{
			return (pressed_ascii_values[counter]);
		}
		counter++;
	}
	return '*';		//If no corresponding scancode was found
}

void getUserString()
{
	clearScreen();
	byte key_pressed;
	byte key_pressed_ascii;
	static char user_string[100 + 1];
	byte counter = 0;
	while(counter < 100)
	{
		key_pressed_ascii = 0;
		while (key_pressed_ascii < 0x61 || key_pressed_ascii > 0x7A) 		//Only allow letters for now
		{
			key_pressed = getKeypress();
			if (key_pressed == 0x1C)				//"Enter" pressed
			{
				user_string[counter] = '\0';
				printString(user_string);
				return;
			}

			key_pressed_ascii = getScanCodeAscii(key_pressed);
		}
		user_string[counter] = key_pressed_ascii;
		counter++;
	}
	user_string[counter] = '\0';
	
	printString(user_string);
}

int getPassword()
{
	clearScreen();
	byte key_pressed;
	byte key_pressed_ascii;
	char attempted_password[100 + 1];
	int counter = 0;
	while(counter < 100)
	{
		key_pressed_ascii = 0;
		while (key_pressed_ascii < 0x61 || key_pressed_ascii > 0x7A) 		//Only allow letters for now
		{
			key_pressed = getKeypress();
			if (key_pressed == 0x1C)				//"Enter" pressed
			{
				attempted_password[counter] = '\0';
				return testPassword(attempted_password);
			}

			key_pressed_ascii = getScanCodeAscii(key_pressed);
		}
		attempted_password[counter] = key_pressed_ascii;
		counter++;
	}
	attempted_password[counter] = '\0';
	
	return testPassword(attempted_password);
}

int testPassword(char *attempted_password)
{
	char real_password[] = {'t', 'e', 's', 't', 'p', 'a', 's', 's'};

	int counter = 0;
	while (attempted_password[counter] != '\0')
	{
		counter++;
	}

	if (counter != 8)
	{
		return -1;
	}

	counter = 0;
	while (counter < 8)
	{
		if (attempted_password[counter] != real_password[counter])
		{
			return -1;
		}

		counter++;
	}

	return 0;
}

unsigned test_function()
{
	int some_bytes[3] = {0x01, 0x02, 0x03};

	int counter = 0;
	while (counter < 3)
	{
		if (some_bytes[counter] == (int)0x03)
		{
			return 1;
		}

		counter++;
	}

	return 0;
}

