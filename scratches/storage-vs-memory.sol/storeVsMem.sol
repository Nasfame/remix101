pragma solidity ^0.4.17;
 
// Creating a contract
contract helloGeeks
{
  // Initialising array numbers
  int[] public numbers;
  int [] public  memNumbers;

  constructor(){
    numbers = [1,2,3];
    memNumbers = [1,2,3];
  }
 
  // Function to insert values
  // in the array numbers
  function NumbersWithStorage() public
  {
    numbers.push(1);
    numbers.push(2);
 
    //Creating a new instance
    int[] storage myArray = numbers;
     
    // Adding value to the
    // first index of the new Instance
    myArray[0] = 0;
  } 
  function getAllNumbers() external  returns int[]{
        return numbers;
  }

  function getAllNumbersInMemory() external  returns int[]{
        return memNumbers;
  }

   function NumbersWithMemory() public
  {
    numbers.push(1);
    numbers.push(2);
     
    //creating a new instance
    int[] memory myArray = numbers;
     
    // Adding value to the first
    // index of the array myArray
    myArray[0] = 0;
  } 
}