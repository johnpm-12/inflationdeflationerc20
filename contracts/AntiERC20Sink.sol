pragma solidity ^0.4.23;

// prevent a contract from being an ERC20 sink by allowing a manager to transfer any ERC20 token from the contract
// if used on contracts that hold ERC20 balances by design, override the notRequiredToken modifier to revert so the manager can't steal funds

import "./Managed.sol";
import "./ERC20Interface.sol";

contract AntiERC20Sink is Managed {

    constructor() public {}

    modifier notRequiredToken(address _token) {
        _;
    }

    function transferERC20Token(ERC20Interface _token, address _to, uint256 _amount) public managerOnly notRequiredToken(_token) {
        assert(_token.transfer(_to, _amount));
    }

}
