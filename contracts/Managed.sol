pragma solidity ^0.4.23;

// simple managed contract

contract Managed {

    address public manager;
    address public newManager;

    constructor() public {
        manager = msg.sender;
    }

    modifier managerOnly() {
        require(msg.sender == manager);
        _;
    }

    modifier newManagerOnly() {
        require(msg.sender == newManager);
        _;
    }

    function setManager(address _manager) public managerOnly {
        newManager = _manager;
    }

    function acceptManager() public newManagerOnly {
        manager = newManager;
        newManager = 0x0;
    }

}
