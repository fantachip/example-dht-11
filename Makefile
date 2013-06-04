# replace this with path to avr related standard libraries and include files
AVRLIB = /usr/local/avr/

CC = avr-gcc -mmcu=atmega88 -Wall 
CCFLAGS = -Ofast -DNDEBUG -std=c99 -I$(AVRLIB)/include/ 
LDFLAGS = -lm -L$(AVRLIB)/lib/avr4/ 
AVRDUDE = avrdude -p m88 -c usbasp -e 

APP = dhtread

%.o: %.c *.h
	$(CC) $(CCFLAGS) $< -c
	
all:
	make $(APP)
	
$(APP): main.o dht.o uart.o
	$(CC) $^ -o $@.elf $(LDFLAGS)
	avr-objcopy -j .text -j .data -O ihex $(APP).elf $(APP).hex

#gui: 
	#gcc -o control gtk-control.c `pkg-config --libs --cflags gtk+-2.0`
	
install:
	$(AVRDUDE) -U flash:w:$(APP).hex 

# Fuse high byte:
# 0xc9 = 1 1 0 1   1 1 1 1 <-- BOOTRST (boot reset vector at 0x0000)
#        ^ ^ ^ ^   ^ ^ ^------ BOOTSZ0
#        | | | |   | +-------- BOOTSZ1
#        | | | |   + --------- EESAVE (don't preserve EEPROM over chip erase)
#        | | | +-------------- CKOPT (full output swing)
#        | | +---------------- SPIEN (allow serial programming)
#        | +------------------ WDTON (WDT not always on)
#        +-------------------- RSTDISBL (reset pin is enabled)
# Fuse low byte:
# 0x9f = 1 1 1 0   0 1 1 1
#        ^ ^ \ /   \--+--/
#        | |  |       +------- CKSEL 3..0 (external >8M crystal)
#        | |  +--------------- SUT 1..0 (crystal osc, BOD enabled)
#        | +------------------ CKOUT 
#        +-------------------- DIV8 
fuse:
	$(AVRDUDE) -U hfuse:w:0xdf:m -U lfuse:w:0xe7:m 
	
clean:
	rm -rf *.o *.elf *.hex
