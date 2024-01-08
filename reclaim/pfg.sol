// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PFG {
    struct Strategy {
        uint256 LONG; // %
        uint256 SHORT; // % 
    }

    uint256 private id = 0;

    modifier validId(uint256 _id) {
        require(_id > 0, "Invalid id");
        _; 
    }

    function deposit(Strategy memory _s) public payable returns (uint256 depositId)  {  
        uint256 amt = msg.value;
        require(amt > 0, "Deposit amount must be greater than zero");
        require(_s.LONG + _s.SHORT == 100, "Invalid LONG SHORT configuration");

        // Employing gmx contracts. 
        id++;
        depositId = id;
    }

    function withdraw(uint256 _id, uint256 amt) public validId(_id) {
        require(amt > 0, "Withdrawal amount must be greater than zero");

        // Employing gmx contract based on _id
        // Issue orders to close for the amt and lev
        // Retrieve amt from gmx contracts.

        payable(msg.sender).transfer(amt);
    }

    function getPositions(uint256 _id) public validId(_id) pure returns (Strategy memory) {
        // Get positions from gmx contracts
        Strategy memory s_ = Strategy({
            LONG: 100,
            SHORT: 100
        });

        return s_;
    }
}
