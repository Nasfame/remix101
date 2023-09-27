// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "./LilypadEventsUpgradeable.sol";
import "./LilypadCallerInterface.sol";

/** === User Contract Example === **/
contract StableDiffusionContract is LilypadCallerInterface {
  address public bridgeAddress; // Variable for interacting with the deployed LilypadEvents contract
  LilypadEventsUpgradeable bridge;
  uint256 public lilypadFee; //=30000000000000000;
  mapping (uint256=>string) public prompts;

  uint[] public promptArr;

  struct SuccessStatus {
    address _from;
    uint _jobId;   
    LilypadResultType _resultType;
    string   _result;
  }

  struct ErrorStatus{
    address _from;
    uint _jobId;
    string _errorMsg;
  }

  mapping(address => SuccessStatus[]) jobRecord;
  mapping(address => ErrorStatus[]) errorRecord;
  
  constructor(address _bridgeContractAddress) {
    bridgeAddress = _bridgeContractAddress;
    bridge = LilypadEventsUpgradeable(_bridgeContractAddress);
    uint fee = bridge.getLilypadFee(); // you can fetch the fee amount required for the contract to run also
    lilypadFee = fee;
  }
  
  //** Define the Bacalhau Specification */
  string constant specStart = '{'
      '"Engine": "docker",'
      '"Verifier": "noop",'
      '"PublisherSpec": {"Type": "estuary"},'
      '"Docker": {'
      '"Image": "ghcr.io/bacalhau-project/examples/stable-diffusion-gpu:0.0.1",'
      '"Entrypoint": ["python", "main.py", "--o", "./outputs", "--p", "';

  string constant specEnd =
      '"]},'
      '"Resources": {"GPU": "1"},'
      '"Outputs": [{"Name": "outputs", "Path": "/outputs"}],'
      '"Deal": {"Concurrency": 1}'
      '}';
  
  event Refund(address indexed recipient, uint256 amount);

  /** Call the runLilypadJob() to generate a stable diffusion image from a text prompt*/
  function StableDiffusion(string calldata _prompt) external payable {
      require(msg.value >= lilypadFee, "Not enough to run Lilypad job");
      uint256 refundAmount = msg.value - lilypadFee;
      if (refundAmount > 0) {
        payable(msg.sender).transfer(refundAmount);
        emit Refund(msg.sender, refundAmount);
      }

      // TODO: spec -> do proper json encoding, look out for quotes in _prompt
      string memory spec = string.concat(specStart, _prompt, specEnd);
      uint id = bridge.runLilypadJob{value: lilypadFee}(address(this), spec, uint8(LilypadResultType.CID));
      //require(id > 0, "job didn't return a value");
      prompts[id] = _prompt;
      promptArr.push(id);
  }

  /** LilypadCaller Interface Implementation */
  function lilypadFulfilled(address _from, uint _jobId,   
    LilypadResultType _resultType, string calldata _result)        
    external override {
    // Do something when the LilypadEvents contract returns    
    // results successfully

      SuccessStatus memory newJob = SuccessStatus({
             _from: _from,
            _jobId: _jobId,
            _resultType : _resultType,
            _result: _result
        });
        jobRecord[_from].push(newJob);
  }

  function getSuccessStatus(address _owner)external view returns(SuccessStatus[] memory){
      return jobRecord[_owner];
  }
  
  function lilypadCancelled(address _from, uint _jobId, string 
    calldata _errorMsg) external override {
    // Do something if there's an error returned by the
    // LilypadEvents contract
     ErrorStatus memory newJob = ErrorStatus({
         _from: _from,
        _jobId: _jobId,
        _errorMsg: _errorMsg
    });
    errorRecord[_from].push(newJob);
  }

   function getErrorStatus(address _owner)external view returns(ErrorStatus[] memory){
      return errorRecord[_owner];
  }

  // Function to get all prompts
  function getAllPrompts() public view returns (uint[] memory) {
      return promptArr;
  }
}
