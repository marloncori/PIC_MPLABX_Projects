#include <iostream>
#include <iomanip>
#include <system_error>
#include <errno.h>
#include <Windows.h>
#include <limits>

#define  Million  1000000

struct TmrA {
  double resolution;
  double inputDivider;
  double clockFrequency;
  double period;
  double TACCR0;
  double option;
  double delay;
  double counter;
  double answer;
};

TmrA timerA;

//--------------------------------------------------------------------------------
void header();
void getUserData();
double validateInput(double& value);
void calculateTmrA();
void showResult();

//--------------------------------------------------------------------------------
int main(int argc, char** argv){

 system("color 3e");

 header();
 getUserData();

 calculateTmrA();
 Sleep(500);
 
 showResult();
 system("pause");

 return 0;
}

//--------------------------------------------------------------------------------
void header(){
  std::cout << "\n\t =========================================== " << std::endl;
  std::cout << "\t ===  MSP430G2553 TIMER_A  Calculations  === " << std::endl;
  std::cout << "\t ===========================================\n " << std::endl;
  Sleep(1000);
}

//---------------------------------------------------------
double validateInput(double& value){
   while(1){
      if(std::cin.fail()){
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
        std::cout << "\t Please try once more! You have entered the wrong input.\n";
        std::cout << "\t   ==> Type it again: ";
        std::cin >> value;
      }
      if(!std::cin.fail()) return value;
   }
}

//---------------------------------------------------------
void getUserData(){

   double param;  

   std::cout << "\t  Hello, please choose one option below.\n";
   Sleep(500);
   std::cout << "\t     1. calculate timerA resolution(us) and period(sec)\n";
   std::cout << "\t     2. find TACCR0 value for a given period (sec)\n";
   std::cout << "\n\t     option: ";
   std::cin >> param; 
   timerA.option = validateInput(param);
   Sleep(1000);

   if(timerA.option == 1){
      std::cout << "\t  Now provide us with the needed data for calculation.\n";
      Sleep(500);

      std::cout << "\t   ==> clock frequency (Hz): ";
      std::cin >> param;
      timerA.clockFrequency = validateInput(param);
      Sleep(500);

      std::cout << "\t   ==> input clock divider (0|1|2|4|8): ";
      std::cin >> param;
      timerA.inputDivider = validateInput(param);
      Sleep(500);

      std::cout << "\t   ==> TACCR0 value (max. 65535): ";
      std::cin >> param;
      timerA.TACCR0 = validateInput(param);
      Sleep(500);

      std::cout << "\n\t  And you want to calculate an overflow counter value? [Y/N]\n";
      std::cout << "\t   --> answer: ";
      std::cin >> param;
      timerA.answer = validateInput(param);
      if(timerA.answer){
          std::cout << "\t  What is the desired delay?\n";
          std::cout << "\t   --> seconds: ";
          std::cin >> param;
          timerA.delay = validateInput(param);
      }
      Sleep(500);

      std::cout << "\n\n\t   Processing data...\n";
      Sleep(2000);
   }
   else if(timerA.option == 2){
      std::cout << "\t  Okay, so you chose option 2. Now give below the needed data.\n";
      Sleep(500);

      std::cout << "\t   ==> clock frequency (Hz): ";
      std::cin >> param;
      timerA.clockFrequency = validateInput(param);
      Sleep(500);

      std::cout << "\t   ==> input clock divider (0|1|2|4|8): ";
      std::cin >> param;
      timerA.inputDivider = validateInput(param);
      Sleep(500);

      std::cout << "\t   ==> desired overflow time: ";
      std::cin >> param;
      timerA.period = validateInput(param);
      Sleep(500);

      std::cout << "\n\n\t   Processing data...\n";
      Sleep(2000);
   }
   else {
      std::cout << "\t  Sorry, invalid option! Try it again!\n";
      Sleep(1000);
      getUserData();
   }
}

//--------------------------------------------------------------------------------float calculateDutyCycle(const int& degree){
void calculateTmrA(){
   if((timerA.TACCR0 > 65535) || (timerA.inputDivider > 8)){
     throw std::system_error(errno, 
           std::system_category(), " Some parameters set for timerA-related calculations are wrong!!!\n"); 
   }    

   if(timerA.option == 1){
     /* calculate delay per TAR count
     * ID_0 = 0, ID_1 = 2, ID_2 = 4, ID_3 = 8 */
     //---------------------------------------------------------------------
      if(timerA.inputDivider == 0){
         timerA.resolution = 1 / timerA.clockFrequency;
  	 timerA.period = (timerA.TACCR0 + 1) / timerA.clockFrequency;    
      }
      else {
         timerA.resolution = timerA.inputDivider / timerA.clockFrequency;
         timerA.period = (timerA.inputDivider * (timerA.TACCR0 + 1)) / timerA.clockFrequency;
      }
      //---------------------------------------------------------------------
      if(timerA.answer){ 
        timerA.counter = timerA.delay / timerA.period;
      }
      else {
        timerA.counter = 0;
        timerA.delay = 0;
      }
   }
   else if(timerA.option == 2){
     timerA.TACCR0 = ((timerA.period * timerA.clockFrequency) / timerA.inputDivider) - 1;
   }
}

//--------------------------------------------------------------------------------
void showResult(){
  std::string line("\t ---------------------------------------\n");
  std::cout << line << std::endl;
  std::cout << "\n\t   These are the results of all calculations:\n"; 
  Sleep(500);
 
  if(timerA.option == 1){
     std::cout << "\t"<< std::setw(10) << "---------------------------------------------------\n";	
     Sleep(500);
     std::cout << "\t"<< std::setw(10) << "| timerA overflow time: | " << timerA.period << " seconds | \n";
     Sleep(500);
     std::cout << "\t"<< std::setw(10) << "| delay per TAR count:  | " << timerA.resolution << " us        | \n";
     if(timerA.answer){
         std::cout << "\t"<< std::setw(10) << "| desired delay (sec)   | " << timerA.delay << " s             | \n";
         std::cout << "\t"<< std::setw(10) << "|   overflow counter    | " << timerA.counter << "         | \n";
     }
     std::cout << "\t"<< std::setw(10) << "---------------------------------------------------\n\n";	   
     Sleep(250);
  }
  else if (timerA.option == 2){
     std::cout << "\t  For a " << (timerA.clockFrequency/Million) << " MHz input clock \n\t a divider of " << timerA.inputDivider << " and a " << timerA.period << " sec overflow timer -->\n";
     std::cout << "\t"<< std::setw(10) << "----------------------------------------------\n";	
     Sleep(500);
     std::cout << "\t"<< std::setw(10) << "| TACCR0 count value  | " << timerA.TACCR0 << " |\n";
     std::cout << "\t"<< std::setw(10) << "---------------------------------------------------\n\n";	   
     Sleep(250);
  }
  else {
    throw std::system_error(errno, 
      std::system_category(), " Unable to show result. Choose either option 1 or 2 for calculations!\n"); 
  }
  header();
}

//--------------------------------------------------------------------------------