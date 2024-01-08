// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PFG {
    struct Strategy {
        ufixed LONG; // Eg: 0.01 for 1%
        ufixed SHORT; 
        ufixed lev;
    }

    ufixed immutable maxLev = 50; 
    ufixed immutable minLev = 1.1; 

    constructor(){

    }

    modifier validStrategy (Strategy memory _s) {
        require((_s.LONG>=0) && (_s.LONG<=1), "Invalid LONG");
        require((_s.SHORT>=0) && (_s.SHORT<=1), "Invalid SHORT");
        require(_s.LONG + _s.SHORT == 1, "Invalid LONG SHORT configuration");
        
        ufixed lev = _s.lev;
        require((lev>=minLev) && (lev<=maxLev), "Invalid Leverage");
        _; 
    }


    uint256 private id = 0;

    modifier validId(uint256 _id) {
        require(_id > 0, "Invalid id");
        _; 
    }

    function deposit(Strategy memory _s) public validStrategy(_s) payable returns (uint256 depositId)  {  
        uint256 amt = msg.value;
        require(amt > 0, "Deposit amount must be greater than zero");

        // OPEN SHORT, LONG POS via gmx contracts. 
        id++;
        depositId = id;
    }

    function withdraw(uint256 _id, uint256 amt) public validId(_id) {
        require(amt > 0, "Withdrawal amount must be greater than zero");

        // Retrieve POS by _id
        
        Strategy memory pos = getPositions(_id);
        
        ufixed closeAmt = amt * pos.SHORT;
        ufixed longAmt = amt* pos.LONG;
        
        // CLOSE MARKET POS 

        payable(msg.sender).transfer(amt);
    }

    function getPositions(uint256 _id) public validId(_id) pure returns (Strategy memory) {
        // Get positions from gmx contracts
        Strategy memory s_ = Strategy({
            LONG: 100,
            SHORT: 100,
            lev: 10
        });

        return s_;
    }
}
