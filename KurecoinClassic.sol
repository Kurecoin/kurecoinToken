pragma solidity ^0.4.24;

/* 
 * KureCoin Token Contract
 * =======================
 * 
 * BASED on the OpenZeppelin Contracts. 
 * ASSEMBLED, MODIFIED & DELIVERED by Codemelt.
 * FOR KureCoin (https://kurecoinhub.io/).
 */



library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) { return 0; }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

}


contract Ownable {
  address public owner;
  address public pendingOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor() public {
    owner = msg.sender;
    pendingOwner = address(0);
  }



  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) onlyOwner external {
    pendingOwner = newOwner;
  }

  function claimOwnership() external {
    require(msg.sender == pendingOwner);
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused external {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused external {
    paused = false;
    emit Unpause();
  }

}


contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract TokenBase is ERC20, Pausable {
  using SafeMath for uint256;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

  modifier isValidDestination(address _to) {
    require(_to != address(0x0));
    require(_to != address(this));
    _;
  }


  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }



  function transfer(address to, uint256 value) public whenNotPaused isValidDestination(_to) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 _value) public whenNotPaused isValidDestination(_to) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function increaseApproval(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract MintableToken is TokenBase {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }


  function mint(address to, uint256 amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), to, amount);
    return true;
  }

  function finishMinting() onlyOwner canMint external returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

}


contract BurnableToken is MintableToken {
  event Burn(address indexed burner, uint256 value);


  function burn(uint256 _value) external {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
  }

}


contract KurecoinToken is BurnableToken {
  string public constant name = "Kurecoin Token";
  string public constant symbol = "KRC";
  uint8 public constant decimals = 18;


  /**
  * @dev Allows the owner to take out tokens to this contract by mistake.
  * @param _token The contract address of the token that is getting pulled out.
  * @param _amount The amount to pull out.
  */
  function pullOut(ERC20 token, uint256 amount) external onlyOwner {
    token.transfer(owner, amount);
  }

  /**
  * @dev 'tokenFallback' function in accordance to the ERC223 standard. Rejects all incoming ERC223 token transfers.
  */
  function tokenFallback(address from, uint256 value, bytes data_) public {
    from_; value_; data_;
    revert();
  }

  function() external payable {
      revert("This contract does not accept Ethereum!");
    }

}