// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LilypadEventsUpgradeable.sol";
import "./LilypadCallerInterface.sol";

/**
    @notice An experimental contract for POC work to call Bacalhau jobs from FVM smart contracts
*/
contract Decenter is LilypadCallerInterface, Ownable {
    address public bridgeAddress;
    LilypadEventsUpgradeable bridge;
    uint256 public lilypadFee; 
    string constant lighthouseUrl = "https://gateway.lighthouse.storage/ipfs/";


    struct JobProfile {
        uint jobId;
        string errorMsg;
        string cid;
        bool status;
    }
   
    mapping (uint => string) prompts;
    mapping (uint => JobProfile) report;
    mapping (address => uint[]) userJobIds;
    mapping(address => uint) userLatestId;

    constructor(address _bridgeContractAddress) {
        console.log("Deploying Decenter contract");
        bridgeAddress = _bridgeContractAddress;
        bridge = LilypadEventsUpgradeable(_bridgeContractAddress);
        uint fee = bridge.getLilypadFee();
        lilypadFee = fee;
    }

    function setBridgeAddress(address _newAddress) public onlyOwner {
      bridgeAddress= _newAddress;
    }

    function setLPEventsAddress(address _eventsAddress) public onlyOwner {
        bridge = LilypadEventsUpgradeable(_eventsAddress);
    }

    function getLilypadFee() external {
        uint fee = bridge.getLilypadFee(); 
        console.log("fee", fee);
        lilypadFee = fee;
    }

    function setLilypadFee(uint256 _fee) public onlyOwner {
        require(_fee > 0, "Lilypad fee must be greater than 0");
        lilypadFee = _fee;
    }

    function lilypadFulfilled(address _from, uint _jobId, LilypadResultType _resultType, string calldata _result) external override {
        //need some checks here that it a legitimate result
        require(_from == address(bridge)); //really not secure
        require(_resultType == LilypadResultType.CID);

        report[_jobId] = JobProfile({
            jobId : _jobId,
            errorMsg : "",
            cid : _result,
            status : true
        });
        // TODO: emit JOB
        delete prompts[_jobId];
    }

    function lilypadCancelled(address _from, uint _jobId, string calldata _errorMsg) external override {
        require(_from == address(bridge)); //really not secure
        console.log(_errorMsg);
        report[_jobId] = JobProfile({
            jobId : _jobId,
            errorMsg : _errorMsg,
            cid : "",
            status : false
        });
        delete prompts[_jobId];
    }

    function getUserReports(address _owner) view public returns(JobProfile[] memory) {
        JobProfile[] memory result = new JobProfile[](userJobIds[_owner].length);
        uint[] memory userIds = userJobIds[_owner];
        
         for(uint i; i < userIds.length; i++){
            result[i] = report[userIds[i]];
         }


        return result;
    }

    function getUserLatestId(address _owner) view public returns(uint) {
        return userLatestId[_owner];
    }

    string constant specStart = '{'
        '"Engine": "docker",'
        '"Verifier": "noop",'
        '"PublisherSpec": {"Type": "ipfs"},'
        '"Docker": {'
        '"Image": "ghcr.io/decenter-ai/compute:v1.5.0",'
        '"Entrypoint": ["/app/venv/bin/python", "main.py", "train_v2",';

    string constant specEnd =
        ']},'
        '"Resources": {"GPU": "0"},'
        '"Outputs": [{"Name": "outputs", "Path": "/outputs"}],'
        '"Deal": {"Concurrency": 1}'
        '}';
    string constant specClose = '}';

    event Refund(address indexed recipient, uint256 amount);

    function TrainV2(string calldata train_script, string calldata input_archive, string calldata input_cid) public payable returns (uint){
        require(msg.value >= lilypadFee, "Not enough to run Lilypad job");
        uint256 refundAmount = msg.value - lilypadFee;
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
            emit Refund(msg.sender, refundAmount);
        }

        require(bytes(train_script).length > 0, "train_script is compulsory");

        require(bytes(input_archive).length > 0 || bytes(input_cid).length > 0, "Either input_archive or input_cid must be provided");
        
        string memory inputSpec = "";
        // TODO: input_cid
        if(bytes(input_cid).length>0){
            console.log("input_cid found");
            input_archive = input_cid;
            string memory inputUrl = string.concat(lighthouseUrl,input_cid);
            console.log(inputUrl);
            // TODO: concatenate specInput
            inputSpec = this.createInputString(input_cid);
            console.log(inputSpec);
        }
        
        string memory specMiddle = string.concat('"',train_script,'"',',"',input_archive,'"');

        string memory spec = string.concat(specStart,specMiddle ,specEnd,inputSpec,specClose);

        console.log(spec);

        // TODO: refactor the code bellow to another function called callLilypad
        uint id = bridge.runLilypadJob{value: lilypadFee}(address(this), spec, uint8(LilypadResultType.CID));
        require(id > 0, "job didn't return a value");
        return id;
    }
    // FIXME: change to https
    function createInputString(string calldata inputCID) public pure returns (string memory) {
        // Create the "inputs" object as a JSON string
        string memory inputsJson = '{"StorageSource": "IPFS","Name": "inputs","CID": "';

        // Concatenate the inputCID to the JSON string
        string memory concatenatedJson = string(abi.encodePacked(inputsJson, inputCID, '","path": "/inputs"}'));

        return concatenatedJson;    
   }
}