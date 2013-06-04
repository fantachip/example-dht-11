/* AVR DHT-11 sensor example. 
  for more information visit: 
  
*/

#include <avr/io.h>

#define F_CPU 18432000UL

#include <util/delay.h>
#include <stdio.h>

#include "dht.h"
#include "util.h"
#include "uart.h"

#define DHT_PIN(reg) BIT(C, 0, reg)

static inline int16_t dhtproc(dht_request_t req, uint16_t arg){
	switch(req){
		case DHT_READ_PIN: 
			DHT_PIN(DDR) = INPUT;
			return DHT_PIN(PIN); 
			break;
		case DHT_WRITE_PIN:
			DHT_PIN(DDR) = OUTPUT;
			DHT_PIN(PORT) = (arg)?HIGH:LOW;
			return 0;
			break;
		case DHT_DELAY_MS:
			while(arg--) {
				_delay_ms(1);
			}
			break;
		case DHT_DELAY_US:
			while(arg--) {
				_delay_us(1);
			}
			break;
		default:
			return -1;
	}
	return 0;
}

#define BAUD_RATE 9600
uint16_t BAUD_PRESCALE() {return (F_CPU/(BAUD_RATE*16L)-1);}

int main(){
	dht_t dht; 
	UART_Init(BAUD_PRESCALE());
	
	DHT_Init(&dht, dhtproc);
	while(1){
		if(DHT_Read11(&dht) == DHTLIB_OK){
			printf("Temperature: %d, Humidity: %d\r\n", (int)dht.temperature * 100, (int)dht.humidity * 100);
		} else {
			printf("DHT ERROR!\r\n");
			_delay_ms(1000);
		}
	}
}
