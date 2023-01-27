#include <iostream>
#include <system_error>
#include <errno.h>
#include <Windows.h>
#include <limits>

struct Tmr1 {
  double maxCount;
  double overflowTime;
  double desiredDelay;
  double counter;
  double prescaler;
  double crystalFreq;
  double timer1Val;
};

Tmr1 timer1;
//--------------------------------------------------------------------------------
void header();
void getUserData();
double validateInput(double& value);
void calculateTMR1();
void decToHex(double& num);
void showResult();

//--------------------------------------------------------------------------------
int main(int argc, char** argv){

 system("color 3e");

 header();
 getUserData();

 calculateTMR1();
 Sleep(500);
 
 showResult();
 system("pause");

 return 0;
}

//--------------------------------------------------------------------------------
void header(){
  std::cout << "\t ============================================== " << std::endl;
  std::cout << "\t ===  PIC MICROCONTROLER : TMR1 calculator  === " << std::endl;
  std::cout << "\t ==============================================\n " << std::endl;
  Sleep(1000);
}

//---------------------------------------------------------
double validateInput(double& value){
   while(1){
      if(std::cin.fail()){
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
        std::cout << "\t Please try again! You have entered the wrong input.\n";
        std::cout << "\t   ==> Type it again: ";
        std::cin >> value;
      }
      if(!std::cin.fail()) return value;
   }
}

//---------------------------------------------------------
void getUserData(){
  
   std::cout << "\t  Hello, please enter below the parameters\n";
   Sleep(500);
   std::cout << "\t   for the TMR1 value calculation.\n";
   Sleep(1000);

   double param {0};
 
   std::cout << "\t   ==> max count: ";
   std::cin >> param;
   timer1.maxCount = validateInput(param);
   Sleep(500);

   std::cout << "\t   ==> desired overflow time: ";
   std::cin >> param;
   timer1.overflowTime = validateInput(param);
   Sleep(500);

   std::cout << "\t   ==> prescaler: ";
   std::cin >> param;
   timer1.prescaler = validateInput(param);
   Sleep(500);
 
   std::cout << "\t   ==> crystal frequency: ";
   std::cin >> param;
   timer1.crystalFreq = validateInput(param);
   Sleep(500);

   std::cout << "\t   ==> desired delay: ";
   std::cin >> param;
   timer1.desiredDelay = validateInput(param);
   Sleep(500);

   timer1.timer1Val = 0;
 
   std::cout << "\n\n\t   Processing input...\n";
   Sleep(1000);
}

void decToHex(double& num) {
   std::string hexVal("");
   char arr[6];
   int i = 0;
   int DIVIDER = 16;
   int factor1 = 48;
   int factor2 = 55;
   int DEC_BASE = 10;

   while(num!=0) {
      int temp = 0;
      temp = static_cast<int>(num) % DIVIDER;
      if(temp < DEC_BASE) {
         arr[i] = temp + factor1;
         i++;
      } else {
         arr[i] = temp + factor2;
         i++;
      }
      num = num/DIVIDER;
   }
   for(int j=i-1; j>=0; j--){
        std::cout << arr[j];
   }
   std::cout << std::endl;
}

//--------------------------------------------------------------------------------float calculateDutyCycle(const int& degree){
void calculateTMR1(){
   if((timer1.maxCount > 65536) || (timer1.overflowTime < 0)){
     throw std::system_error(errno, 
           std::system_category(), " Some parameters set for timer1 value calculation are wrong!!!\n"); 
   }    
   timer1.timer1Val = (timer1.maxCount - (timer1.overflowTime / (timer1.prescaler * (1 / timer1.crystalFreq))));
   timer1.counter = timer1.desiredDelay / timer1.overflowTime;
}

//--------------------------------------------------------------------------------
void showResult(){
  std::string line("\t ---------------------------------------\n");
  std::cout << line << std::endl;
  std::cout << "\n\t  According to calculation, the \n\t  needed value to be set\n"; 
  Sleep(500);
  std::cout << "\tthe counter variable will be: " << timer1.counter << " cycles.\n";
  Sleep(250);
 
  std::cout << "\tand for TMR1 is: " << timer1.timer1Val << ", i.e. \'0x";
  decToHex(timer1.timer1Val);
  Sleep(500);
  std::cout << "\'. \n";
}

//--------------------------------------------------------------------------------