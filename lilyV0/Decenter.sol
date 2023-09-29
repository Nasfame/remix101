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

    struct StableDiffusionImage {
        string prompt;
        string ipfsResult;
    }

    struct JobProfile {
        uint jobId;
        string errorMsg;
        string cid;
        bool status;
    }

    StableDiffusionImage[] public images;
   
    mapping (uint => string) prompts;
    mapping (uint => JobProfile) report;
    mapping (address => uint[]) userJobIds;
    mapping(address => uint) userLatestId;

    event NewImageGenerated(StableDiffusionImage image);

    constructor(address _bridgeContractAddress) {
        console.log("Deploying StableDiffusion contract");
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

    // not recommended
    function setLilypadFee(uint256 _fee) public onlyOwner {
        require(_fee > 0, "Lilypad fee must be greater than 0");
        lilypadFee = _fee;
    }

    string constant specStart = '{'
        '"Engine": "docker",'
        '"Verifier": "noop",'
        '"PublisherSpec": {"Type": "ipfs"},'
        '"Docker": {'
        '"Image": "ghcr.io/bacalhau-project/examples/stable-diffusion-gpu:0.0.1",'
        '"Entrypoint": ["python", "main.py", "--o", "./outputs", "--p", "';

    string constant specEnd =
        '"]},'
        '"Resources": {"GPU": "1"},'
        '"Outputs": [{"Name": "outputs", "Path": "/outputs"}],'
        '"Deal": {"Concurrency": 1}'
        '}';

    
    
    function StableDiffusion(string calldata _prompt) external payable  {
        require(msg.value >= lilypadFee, "Not enough to run Lilypad job");
        // TODO: spec -> do proper json encoding, look out for quotes in _prompt
        string memory spec = string.concat(specStart, _prompt, specEnd);
        uint id = bridge.runLilypadJob{value: lilypadFee}(address(this), spec, uint8(LilypadResultType.CID));
        require(id > 0, "job didn't return a value");
        userJobIds[msg.sender].push(id);
        prompts[id] = _prompt;
        userLatestId[msg.sender] = id;
    }

    function allImages() public view returns (StableDiffusionImage[] memory) {
        return images;
    }

    function lilypadFulfilled(address _from, uint _jobId, LilypadResultType _resultType, string calldata _result) external override {
        //need some checks here that it a legitimate result
        require(_from == address(bridge)); //really not secure
        require(_resultType == LilypadResultType.CID);

        StableDiffusionImage memory image = StableDiffusionImage({
            ipfsResult: _result,
            prompt: prompts[_jobId]
        });
        report[_jobId] = JobProfile({
            jobId : _jobId,
            errorMsg : "",
            cid : _result,
            status : true
        });
        images.push(image);
        emit NewImageGenerated(image);
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

    event Refund(address indexed recipient, uint256 amount);

    function TrainV2(string train_script, input_archive) payable returns (uint){
        require(msg.value >= lilypadFee, "Not enough to run Lilypad job");
        uint256 refundAmount = msg.value - lilypadFee;
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
            emit Refund(msg.sender, refundAmount);
        }

        specMiddle = string.concat('"',train_script,'"',',"',input_archive,'"');

        string spec = string.concat(specStart,specMiddle ,specEnd);

        console.log(spec);

        // TODO: refactor the code bellow to another function called callLilypad
        uint id = bridge.runLilypadJob{value: lilypadFee}(address(this), spec, uint8(LilypadResultType.CID));
        require(id > 0, "job didn't return a value");
        return id;
    }
}