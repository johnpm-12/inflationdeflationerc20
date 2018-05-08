pragma solidity ^0.4.23;

// token with constantly changing total supply where everyone's balances scale accordingly
// eventually total supply will over or underflow

// TODO: figure out why inheriting the interface doesn't allow compiling
// import "./ERC20Interface.sol";
import "./AntiERC20Sink.sol";
import "./SafeMath.sol";

contract MovingSupplyToken is AntiERC20Sink {

    using SafeMath for uint256;
    using SafeMath for int256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 private baseSupply;
    mapping (address => uint256) private baseBalanceOf;
    mapping (address => mapping (address => uint256)) private baseAllowance;
    mapping (address => mapping (address => uint256)) private _allowance;

    // how much to change total supply per block
    int256 public supplyBuffer;
    // offset from base supply that is recalculated every time the supply buffer is changed
    int256 private retargetOffset;
    uint256 private lastRetargetBlock;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event SupplyBufferChange(int256 _supplyBuffer);

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _baseSupply, int256 _supplyBuffer) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        baseBalanceOf[msg.sender] = _baseSupply;
        baseSupply = _baseSupply;
        supplyBuffer = _supplyBuffer;
        lastRetargetBlock = block.number;
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
        if (_allowance[_from][msg.sender] > 0) {
            _allowance[_from][msg.sender] = _allowance[_from][msg.sender].minus(_value);
        } else {
            baseAllowance[_from][msg.sender] = baseAllowance[_from][msg.sender].minus(baseValue);
        }
        baseBalanceOf[_from] = baseBalanceOf[_from].minus(baseValue);
        baseBalanceOf[_to] = baseBalanceOf[_to].plus(baseValue);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value == 0 || _allowance[msg.sender][_spender] == 0);
        baseAllowance[msg.sender][_spender] = 0;
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // base approve does the same as approve but this approval scales with total supply
    // only one of the two allowances can be non-zero at any time
    function baseApprove(address _spender, uint256 _value) public returns (bool) {
        require(_value == 0 || baseAllowance[msg.sender][_spender] == 0);
        uint256 baseValue = toBase(_value);
        _allowance[msg.sender][_spender] = 0;
        baseAllowance[msg.sender][_spender] = baseValue;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        if (_allowance[_owner][_spender] > 0) {
            return _allowance[_owner][_spender];
        } else {
            return fromBase(baseAllowance[_owner][_spender]);
        }
    }

    function toBase(uint256 _value) private view returns (uint256) {
        return _value.times(baseSupply) / (baseSupply.toInt256().plus(retargetOffset).plus(supplyBuffer.times((block.number.minus(lastRetargetBlock)).toInt256())).toUint256());
    }

    function fromBase(uint256 _baseValue) private view returns (uint256) {
        return (baseSupply.toInt256().plus(retargetOffset).plus(supplyBuffer.times((block.number.minus(lastRetargetBlock)).toInt256())).toUint256()).times(_baseValue) / baseSupply;
    }

    function newSupplyBuffer(int256 _supplyBuffer) public {
        retargetOffset = retargetOffset.plus(supplyBuffer.times((block.number.minus(lastRetargetBlock)).toInt256()));
        lastRetargetBlock = block.number;
        supplyBuffer = _supplyBuffer;
        emit SupplyBufferChange(_supplyBuffer);
    }

}
