INTRODUCTION
============
The DHT-11 is a small humidity and temperature sensor that you can connect to your arduino and get readings for temperature and humidity in the environment. But I'm not going to be using an arduino in this example. Instead I will use the AVR microcontroller directly and make an example that will read data from the DHT 11 sensor and send it to the computer over the serial port. 

![Schematic](http://s17.postimg.org/h2axzvbpb/schema.jpg)

WHAT YOU WILL NEED
============
First things first - the basic setup is the ATMega88 chip sitting on a breadboard, connected to a power supply and having the sensor pluged in to it. The TX/RX pins of the chip are connected directly to a TTL-USB adapter that connects the to the computer through USB. On the computer side, the software can communicate with the chip through the virtual USB serial interface (/dev/ttyUSB0 on linux). The USB to serial adapter converts usb signals to a stream of serial data that can be read by the microcontroller.

http://www.ebay.co.uk/sch/i.html?_odkw=PL2303&_osacat=0&_from=R40&_trksid=p2045573.m570.l1313.TR2.TRC0&_nkw=PL2303HX&_sacat=0

We are also using the USBasp USB programmer that ocnnects to the MOSI, MISO, SCK and RESET pins on the microcontroller. You can also use USBasp as a power supply to power the chip directly from USB while testing the code. So it's a very good setup for quickly testing new code on the avr withough the need to have an Arduino or any development board. 

![USBasp](http://d1gsvnjtkwr6dd.cloudfront.net/large/AC-PG-USBASP_LRG.jpg) 
http://www.ebay.co.uk/sch/i.html?_odkw=usbasp&_osacat=0&_from=R40&_trksid=m570.l1313&_nkw=usbasp&_sacat=0

Image of the sensor we will be using: 

![DHT-11 Sensor](http://learning.grobotronics.com/images/Tutorials/DHT11_Pins.png)

Ebay: http://www.ebay.co.uk/sch/i.html?_odkw=PL2303HX&_osacat=0&_from=R40&_trksid=p2045573.m570.l1313.TR3.TRC0&_nkw=DHT-11&_sacat=0

So let's make a list: 
You will need an AVR chip such as ATMEGA88,
- a DHT11 sensor (Datasheet: http://www.micro4you.com/files/sensor/DHT11.pdf)
- a serial to usb adapter
- USBasp serial programmer
- avrdude software
- avr-gcc to compile the code. 

You can compile your own avr-gcc toolchain by getting the "fanta-tools" package from https://github.com/fantachip/fanta-tools

HOW DOES IT WORK
================
The DHT-11 sensor works like this: the sensor waits for a low level and then a high level on it's data line. Once it detects a low level that lasts at least 18ms and then a transition to a high level again, it initializes it's transmission circuitry and pulls the data pin low for 80 microseconds as an indication that it will now start sending data. Then it starts the transmission of the readings. It's a total of 40 bits and each bit (1 or 0) is transmitted as a pulse of variable length. If the high level of the pulse is longer than 30us then it's a one. If the pulse is less than 26-28us then it's a zero. 

To read this data at the microcontroller side, we first need to pull the line low for at least 18ms (thats MILLI-seconds in this case). Then we need to pull the line high (internal pullup resistors will do this) and wait for the sensor to pull the line low again. If we detect that the line goes low after between 40 and 120 us (it's MICRO-seconds this time!) then we know that the sensor will start sending out data after pulling the data line high again for 80us. 

We can achieve this protocol by using simple delays. On an AVR it is not recommended to use interrupts for this kind of thing because interrupts tend to introduce latency (such as if another interrupt occurs befor it's time to process reception and that other interrupt takes too much time to finish). When timings to be measured are so small (80us is quite small), any kind of delay can push the CPU out of synch with the data that the sensor is transmitting. So instead it's better to turn off all interrupts and let the CPU init communication with the DHT and finish receiving a reading before continuing. That is exactly what happens in the DHT library. 

THE CODE
========
The code consists of a library "dht.c" that implements communication protocol with the DHT sensor, a file "uart.c" that implements UART functions and connects them to STDIO and a main file "main.c" that is the example applicaiton. On the PC side we will be using "processing language" to read data from serial and display it as a string on screen. You can of course use a C program that reads from the serial port and processes the data in C. Have a look at other fantachip code for an example of how to do this (at github). 

To use the DHT library, you need to define a function called "dhtproc" that will be called by the dht library while it is running. The purpose of this function is to provide application speciffic services to the DHT library, such as reading the value of the pin that the DHT sensor is connected to. This way the library code is independent of the application speciffic configuraiton. 

	static inline int16_t dhtproc(dht_request_t req, uint16_t arg){
		switch(req){
			case DHT_READ_PIN: 
				..
				break;
			case DHT_WRITE_PIN:
				..
				break;
			case DHT_DELAY_MS:
				..
				break;
			case DHT_DELAY_US:
				..
				break;
			default:
				return -1;
		}
		return 0;
	}

the dht library will call this function with one of the following values for the "req" parameter: 
- DHT_READ_PIN - to read the value of pin that dht is connected to
-	DHT_WRITE_PIN - write value to the pin
-	DHT_DELAY_MS - delay for "arg" number of milliseconds
-	DHT_DELAY_US - delay for "arg" number of microseconds
	
Since our "uart.c" code in the UART_Init function also connects the stdio to UART, we can also now use printf ans scanf to read and write to and from the serial port. This is very handy because we don't need to write any functions to implement printf functionality for the serial port. 

The mcu sends the temperature data to the PC application as two 16 bit integers encoded as hex numbers. Hex encoding is chosen simply so that we can use other characters that are not part of [0-9a-f] group as control characters. When a temperature reading is successful, the MCU will send letter 'y' followed by two hex encoded integers representing the temperature and humidity reading. Like this: y01af03de\r\n. Each such sequence ends with a line feed (the line feed is used to detect a reading). 

THE APPLICATION
===============
The PC application is written in "processing language" and is located in the main.ps file. You can download the processing language from https://www.processing.org/. Just copy and paste the contents of the main.ps file into a new processing sketch and run it. It should automatically connect to the first available serial port and attempt to read the data from there. If you get a null pointer exception, just make sure that a USB to serial adapter is connected to the computer and that it's TX/RX pins are connected to TX/RX on the ATMega88.

	import processing.serial.*; 
	 
	Serial myPort;    // The serial port
	PFont myFont;     // The display font
	String inString;  // Input string from serial port
	int lf = 10;      // ASCII linefeed 
	 
	void setup() { 
		size(400,200); 
		myFont = createFont("SansSerif",18); 
		textFont(myFont, 18); 
		println(Serial.list()); 
		
		if(Serial.list().length == 0){
			println("No serial interface found!"); 
			exit();
		} 
		
		println("Using serial interface: "+Serial.list()[0]);
		myPort = new Serial(this, Serial.list()[0], 9600); 
		myPort.bufferUntil(lf); 
		inString = "";
	} 
	 
	void draw() { 
		background(0); 
		if(inString.length() == 0){
			text("Waiting for data...", 10, 50);
		} else if(inString.charAt(0) == 'y'){
			text(
				"Temperature: " + unhex(inString.substring(1, 5)) + 
				"\nHumidity: " + unhex(inString.substring(5, 9)), 10,50);
		} else if(inString.charAt(0) == 'n'){
			text("Sensor error!", 10, 50);
		} else {
			text("Unknown error!", 10, 50);
		}
	} 
	 
	void serialEvent(Serial p) { 
		inString = p.readString(); 
	} 

When everything is connected correctly, you should see the current temperature and humidity displayed on the computer screen. 
