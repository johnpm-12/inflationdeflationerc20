pragma solidity ^0.4.23;

// token with constantly changing total supply where everyone's balances scale accordingly
// eventually total supply will over or underflow

// TODO: figure out why inheriting the interface doesn't allow compiling
// import "./ERC20Interface.sol";
import "./AntiERC20Sink.sol";
import "./SafeMath.sol";

contract MovingSupplyToken is AntiERC20Sink {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public baseSupply;
    mapping (address => uint256) public baseBalanceOf;
    mapping (address => mapping (address => uint256)) public baseAllowance;

    // how much to change total supply per block
    uint256 public supplyBuffer;
    // whether buffer is positive or negative (inflation or deflation)
    bool public positive;
    uint256 public createdBlock;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _baseSupply, uint256 _supplyBuffer, bool _positive) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        baseBalanceOf[msg.sender] = _baseSupply;
        baseSupply = _baseSupply;
        supplyBuffer = _supplyBuffer;
        positive = _positive;
        createdBlock = block.number;
    }

    function totalSupply() public view returns (uint256) {
        return fromBase(baseSupply);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return fromBase(baseBalanceOf[_owner]);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        uint256 baseValue = toBase(_value);
        baseBalanceOf[msg.sender] = baseBalanceOf[msg.sender].minus(baseValue);
        baseBalanceOf[_to] = baseBalanceOf[_to].plus(baseValue);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 baseValue = toBase(_value);
        baseAllowance[_from][msg.sender] = baseAllowance[_from][msg.sender].minus(baseValue);
        baseBalanceOf[_from] = baseBalanceOf[_from].minus(baseValue);
        baseBalanceOf[_to] = baseBalanceOf[_to].plus(baseValue);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value == 0 || baseAllowance[msg.sender][_spender] == 0);
        uint256 baseValue = toBase(_value);
        baseAllowance[msg.sender][_spender] = baseValue;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return fromBase(baseAllowance[_owner][_spender]);
    }

    // TODO: are these backwards?
    function toBase(uint256 _value) private view returns (uint256) {
        if (positive) {
            return _value / (block.number.minus(createdBlock).times(supplyBuffer) / baseSupply).plus(1);
        } else {
            return _value / (block.number.minus(createdBlock).times(supplyBuffer) / baseSupply).minus(1);
        }
    }

    function fromBase(uint256 _baseValue) private view returns (uint256) {
        if (positive) {
            return (block.number.minus(createdBlock).times(supplyBuffer) / baseSupply).plus(1).times(_baseValue);
        } else {
            return (block.number.minus(createdBlock).times(supplyBuffer) / baseSupply).minus(1).times(_baseValue);
        }
    }

}
