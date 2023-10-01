pragma solidity ^0.4.17;
 
// Creating a contract
contract helloGeeks
{
  // Initialising array numbers
  int[] public numbers;

  constructor(){
    numbers = [1,2,3];
  }
 
  // Function to insert values
  // in the array numbers
  function NumbersWithStorage() public
  {
    numbers.push(100);
    numbers.push(200);
 
    //Creating a new instance
    int[] storage myArray = numbers;
    // But actually a pointer
     
    // Adding value to the
    // first index of the new Instance
    myArray[0] = 1200;
  } 
  function getAllNumbers() external view  returns(int[] memory){
        return numbers;
  }

   function NumbersWithMemory() public
  {
    numbers.push(-1);
    numbers.push(-2);
     
    //creating a new instance
    int[] memory myArray = numbers;
     
    // Adding value to the first
    // index of the array myArray
    myArray[0] = 1500;
    // not reflected in numbers
  } 
}