#include <iostream>
#include <system_error>
#include <cmath>
#include <errno.h>
#include <Windows.h>
#include <limits>

//--------------------------------------------------------------------------------
struct USART {
   double desiredBaudRate;
   double oscillationFreq;
   double SPBRGH_SPBRG;
   double bitMode;
   std::string speed;
   double calculBaudRate;
   double error;
};

USART pic16f887;

//--------------------------------------------------------------------------------

//--------------------------------------------------------------------------------
auto header() -> void;
auto getData() -> void;
auto validateString(std::string& input) -> std::string;
auto validateInput(double& data) -> double;
auto calculateValue() -> void;
auto calculateError() -> void;
auto showResult() -> void;

//--------------------------------------------------------------------------------
auto main(int argc, char** argv) -> int {

 header();
 getData();

 calculateValue();
 calculateError();

 showResult();
  
 return 0;
}

//--------------------------------------------------------------------------------
auto header() -> void {
  std::cout << "  ======================================== " << std::endl;
  std::cout << "  ===  PIC16F887 BAUD RATE calculator  === " << std::endl;
  std::cout << "  ========================================\n " << std::endl;
  Sleep(1000);
}

//---------------------------------------------------------
auto validateString(std::string& input) -> std::string {
   while(1){
      if(std::cin.fail()){
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
        std::cout << " Please try again! You have entered the wrong input...\n";
        std::cout << "   ==> requested value: ";
        std::cin >> input;
      }
      if(!std::cin.fail()) break;
   }
  return input;
}

auto validateInput(double& data) -> double {
   while(1){
      if(std::cin.fail()){
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
        std::cout << " Please try again! You have entered the wrong input...\n";
        std::cout << "   ==> requested value: ";
        std::cin >> data;
      }
      if(!std::cin.fail()) break;
   }
  return data;
}

//---------------------------------------------------------
auto getData() -> void {
   double data;	
   std::string option;

   std::cout << "  Please enter below the needed data for calculation.\n";
   Sleep(500);
   
   std::cout << "   ==> desired baud rate: ";
   std::cin >> data;
   pic16f887.desiredBaudRate = validateInput(data);
   Sleep(500);
  
   std::cout << "   ==> clock frequency (MHz): ";
   std::cin >> data;
   pic16f887.oscillationFreq = validateInput(data);
   Sleep(500);

   std::cout << "   ==> resolution (8 bits | 16 bits): ";
   std::cin >> data;
   pic16f887.bitMode = validateInput(data);
   Sleep(500);

   std::cout << "   ==> speed (low | high): ";
   std::cin >> option;
   pic16f887.speed = validateString(option);
   Sleep(500);
 
   std::cout << "\n\n   Processing input...\n";
   Sleep(1000);
}

//--------------------------------------------------------------------------------float calculateDutyCycle(const int& degree){
auto calculateValue() -> void {
   if((pic16f887.desiredBaudRate < 0.0) || (pic16f887.oscillationFreq > 16000000.0)){
     throw std::system_error(errno, 
           std::system_category(), " Neither can the baud rate value be less then 0 \n  nor can the clock frequency be greater than 16 MHz!!\n"); 
   }
   if(pic16f887.bitMode == 16){    
	if(pic16f887.speed == "high"){
   		pic16f887.SPBRGH_SPBRG = ((pic16f887.oscillationFreq/pic16f887.desiredBaudRate)/4) - 1;
   		pic16f887.calculBaudRate = pic16f887.oscillationFreq/(4*(std::round(pic16f887.SPBRGH_SPBRG) + 1));

	} else if(pic16f887.speed == "low") {
		pic16f887.SPBRGH_SPBRG = ((pic16f887.oscillationFreq/pic16f887.desiredBaudRate)/16) - 1;
   		pic16f887.calculBaudRate = pic16f887.oscillationFreq/(16*(std::round(pic16f887.SPBRGH_SPBRG) + 1));
        } else {
 	   throw std::system_error(errno, 
              std::system_category(), " Speed should be either \'low\' or \'high\'!!!\n"); 
	}
  } else if(pic16f887.bitMode == 8){
	if(pic16f887.speed == "high"){
   		pic16f887.SPBRGH_SPBRG = ((pic16f887.oscillationFreq/pic16f887.desiredBaudRate)/16) - 1;
   		pic16f887.calculBaudRate = pic16f887.oscillationFreq/(16*(std::round(pic16f887.SPBRGH_SPBRG) + 1));

	} else if(pic16f887.speed == "low") {
	   	pic16f887.SPBRGH_SPBRG = ((pic16f887.oscillationFreq/pic16f887.desiredBaudRate)/64) - 1;
	   	pic16f887.calculBaudRate = pic16f887.oscillationFreq/(64*(std::round(pic16f887.SPBRGH_SPBRG) + 1));
        } else {
	   throw std::system_error(errno, 
               std::system_category(), " Speed should be either \'low\' or \'high\'!!!\n"); 
        }
  } else {
     throw std::system_error(errno, 
           std::system_category(), " Resolution should be either 8 or 16 bits!!\n"); 
  }
}

auto calculateError() -> void {
   pic16f887.error = (pic16f887.calculBaudRate - pic16f887.desiredBaudRate) / pic16f887.desiredBaudRate;	
}
//--------------------------------------------------------------------------------
auto showResult() -> void {
  std::string line("\n  ---------------------------------------\n");
  std::cout << line << std::endl;
  std::cout << "\n According to calculations, \n  >>> the value to be set for SPBRGH:SPBRG is: " << pic16f887.SPBRGH_SPBRG << "\n"; 
  Sleep(500);

  std::cout << "    >>> the desired baud rate is " << pic16f887.desiredBaudRate << "\n";
  Sleep(500);

  std::cout << "    >>> the crystal frequency equals " << pic16f887.oscillationFreq << " Hz\n";
  Sleep(500);

  std::cout << "    >>> the calculated baud rate is " << pic16f887.calculBaudRate << "\n";
  std::cout << "    >>> the calculation error is " << (pic16f887.error*100) << " %.\n";
  Sleep(500);
  std::cout << line << std::endl;
  header();
}

//--------------------------------------------------------------------------------