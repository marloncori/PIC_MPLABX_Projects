#include <stdio.h>
#include <Windows.h>

#define WORD_SIZE 7

unsigned char* msg = "Hello!";
unsigned char i;
unsigned char DONE = 0;

void writeSerial(unsigned char data);

int main(void) {

   for(i=0; i<WORD_SIZE; i++){
      writeSerial(msg[i]);
      Sleep(500);
   }
   DONE = 1;
   Sleep(1000);

   for(i=WORD_SIZE; i>0 ; i--){
      writeSerial(msg[i-1]);
      Sleep(500);
   }
   
    printf("\n -------------------- \n");
    printf("\n  GOOD NIGHT, MASTER!\n");
    printf("\n -------------------- \n");

  return 0;
}

void writeSerial(unsigned char data){
   if(DONE){
      printf("\n -------------------- \n");
      Sleep(500);
   }
   DONE = 0;
   printf(" %c", data);
}
