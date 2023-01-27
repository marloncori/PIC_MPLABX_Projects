#include <iostream>
#include <system_error>
#include <cmath>
#include <errno.h>
#include <Windows.h>
#include <limits>

struct Tmr0 {
  double maxCount;
  double desiredTime;
  double overflowTime;
  double prescaler;
  double initValue;
  double crystalFreq;
  double realOscillation;
  double counter;
  double machineCycle;
  double newMachineCycle;
  double timesPerCount;
  double newTimesPerCount;
  double answer;
  double desiredOverflow;
  double neededCounts;
  double newNeededCounts;
  double NumOfInterrupts;
  double newPrescaler;
  double requiredCount;
  double timePerInterrupt;
  double offset;
};

Tmr0 timer0;

//--------------------------------------------------------------------------------
void header();
void getUserData();
double validateInput(double& value);
void calculateTmr0();
void showResult();

//--------------------------------------------------------------------------------
int main(int argc, char** argv){

 system("color 3f");

 header();
 getUserData();

 calculateTmr0();
 Sleep(500);
 
 showResult();
 system("pause");

 return 0;
}

//--------------------------------------------------------------------------------
void header(){
  std::cout << "\t =============================================== " << std::endl;
  std::cout << "\t ===  PIC MICROCONTROLLER : TMR0 calculator  === " << std::endl;
  std::cout << "\t ===============================================\n " << std::endl;
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

   std::cout << "\t   for the TMR0 calculation.\n";
   Sleep(1000);

   double param;
   std::cout << "\t   ==> max count (8 bits| 16bits): ";
   std::cin >> param;
   timer0.maxCount = validateInput(param);
   Sleep(500);

   std::cout << "\t   ==> desired delay time: ";
   std::cin >> param;
   timer0.desiredTime = validateInput(param);
   Sleep(500);

   std::cout << "\t   ==> tmr0 initial value: ";
   std::cin >> param;
   timer0.initValue = validateInput(param);
   Sleep(500);

   std::cout << "\t   ==> prescaler: ";
   std::cin >> param;
   timer0.prescaler = validateInput(param);
   Sleep(500);
 
   std::cout << "\t   ==> crystal frequency: ";
   std::cin >> param;
   timer0.crystalFreq = validateInput(param);
   Sleep(500);

   
 std::cout << "\n\t  Do you want to provide us with a needed overflow time value?\n";
          std::cout << "\t\t  1. \'yes\' / 2. \'no\' --> ";
          std::cin >> param;
     	  timer0.answer = validateInput(param);
    
   	  std::cout << "\t   Okay, so what is the timing?\n\t      ==> overflow time: ";
   	  std::cin >> param;
     	  timer0.desiredOverflow = validateInput(param);

	  std::cout << "\n\n\t   Processing input...\n";
   	  Sleep(1000);
}

//--------------------------------------------------------------------------------float calculateDutyCycle(const int& degree){
void calculateTmr0(){
   if((timer0.maxCount > 256) || (timer0.desiredTime < 0)){
     throw std::system_error(errno, 
           std::system_category(), " Some parameters set for tmr0 delay timing calculation are wrong!!!\n"); 
   }    
  /* calculate the timing: 
   *  - max count for 8 bits = 256
   *  - every 4 cycles increment counter (prescaler 1:4)
   *  256 x 4 = 1024
   *  4Mhz (4_000_000) / 4 = 1_000_000 MHz freq
   *  1 / 1 mi = 0.000001 = 1 us
   *   1us * (4 * 256) = 0.001024 s = 1.024 ms counter is incremented
   * but if I want something to happen every 500 ms, so
   * so 1.024 * 500 = 0.512 ms
  */

   timer0.realOscillation = timer0.crystalFreq / 4;
   timer0.machineCycle = 1 / timer0.realOscillation;
   timer0.overflowTime = timer0.machineCycle * ((timer0.maxCount - timer0.initValue) * timer0.prescaler);
   timer0.counter = timer0.desiredTime / timer0.overflowTime;

  if(timer0.answer){
     timer0.neededCounts = timer0.desiredOverflow / timer0.machineCycle;
     timer0.prescaler = timer0.neededCounts / timer0.maxCount;
     /* if result is float, ceil it or floor it and choose the next prescaler 
      value avaible. */
    timer0.timesPerCount = timer0.machineCycle * std::ceil(timer0.prescaler);
    timer0.newNeededCounts = timer0.desiredOverflow / timer0.timesPerCount;
  
    if(timer0.prescaler > 256){
       timer0.newPrescaler = timer0.maxCount;
       timer0.newTimesPerCount = timer0.machineCycle * timer0.newPrescaler;
       timer0.newMachineCycle = timer0.newTimesPerCount * timer0.maxCount;
       timer0.NumOfInterrupts = std::ceil(timer0.desiredOverflow / timer0.newMachineCycle);
       timer0.timePerInterrupt = timer0.desiredOverflow / timer0.NumOfInterrupts;
       timer0.requiredCount = timer0.timePerInterrupt / timer0.newTimesPerCount;
       timer0.offset = timer0.maxCount - timer0.requiredCount;
    }
  
  }
  else {
     timer0.neededCounts = 0;
     timer0.desiredOverflow = 0;
  }
}

//--------------------------------------------------------------------------------
void showResult(){
  std::string line("\t ---------------------------------------\n");
  std::cout << line << std::endl;
  std::cout << "\n\t  According to calculation, the \n\t  needed value for TMR0 counter\n"; 
  Sleep(500);
  std::cout << "\n\t\tfor TMR0 counter is: " << timer0.counter << ", because \n";
  Sleep(500);
  std::cout << "\t\tthe machine cycle equals: " << timer0.machineCycle << " seconds and\n";
  Sleep(250);
  std::cout << "\t\tthe TMR0 overflow time is : " << timer0.overflowTime << " seconds for a\n";
  Sleep(250);
  std::cout << "\t\t" << timer0.crystalFreq << " MHz crystal oscillator.\n\n";
  Sleep(250);
  if(timer0.answer){
    std::cout << "\t\tAnd since the desired overflow time was " << timer0.desiredOverflow << " seconds, \n\t  this means " << timer0.neededCounts << " counts are needed.\n";
    std::cout << "\t\tAccording to these requirements, the value " << timer0.prescaler << " should\n\t\tbe selected as prescaler,\n\t\tif it is available.\n";
    std::cout << "\t\tWith this new prescaler, the times per count will be " << timer0.timesPerCount << " us, so \n\t\t " << timer0.newNeededCounts << " counts are needed\n\t\t to achieve the desired overflow.\n";

     if(timer0.prescaler > 256){
       std::cout << "\n\n\t However, since the calculated prescaler\n\t is greater then 256, so new values \n\t have been calculated for you.\n";
       std::cout << "\n\t\t new prescaler = " << timer0.newPrescaler << "\n";
       std::cout << "\t\t new machine cycle = " << timer0.newTimesPerCount << "\n";
       std::cout << "\t\t times per count = " << timer0.newMachineCycle << "\n";
       std::cout << "\t\t number of interrupts = " << timer0.NumOfInterrupts << "\n\n";      
       std::cout << "\t\t time per interrupt = " <<   timer0.timePerInterrupt << "\n\n";      
       std::cout << "\t\t required count = " <<   timer0.requiredCount << "\n\n";      
       std::cout << "\t\t offset = " <<   timer0.offset << "\n\n";      

     }
 
  }   
  header();
}

//--------------------------------------------------------------------------------