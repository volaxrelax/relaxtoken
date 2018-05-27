pragma solidity ^0.4.23

// ----------------------------------------------------------------------------
// Uhodchain Dapp
// 
// https://github.com/vincentshangjin/uhoodchain
// Based on Uhood.App Project https://github.com/bokkypoobah/Uhood
// 
// the Uhoodchain Dapp Project - 2018. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// ClubToken Interface = ERC20 + symbol + location + decimals + mint + burn
// + approveAndCall
// ----------------------------------------------------------------------------
contract UhoodTokenInterface is ERC20Interface {
    function symbol() public view returns (string);
    function location() public view returns (string);
    function decimals() public view returns (uint8);
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);
    function mint(address tokenOwner, uint tokens) public returns (bool success);
    function burn(address tokenOwner, uint tokens) public returns (bool success);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


// ----------------------------------------------------------------------------
// UhoodToken
// ----------------------------------------------------------------------------
contract UhoodToken is UhoodTokenInterface, Owned {
    using SafeMath for uint;

    string _symbol;
    string _location;
    uint8 _decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor(string symbol, string location, uint8 decimals) public {
        _symbol = symbol;
        _location = location;
        _decimals = decimals;
    }
    function symbol() public view returns (string) {
        return _symbol;
    }
    function location() public view returns (string) {
        return _location;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    function mint(address tokenOwner, uint tokens) public onlyOwner returns (bool success) {
        balances[tokenOwner] = balances[tokenOwner].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function burn(address tokenOwner, uint tokens) public onlyOwner returns (bool success) {
        if (tokens > balances[tokenOwner]) {
            tokens = balances[tokenOwner];
        }
        _totalSupply = _totalSupply.sub(tokens);
        balances[tokenOwner] = 0;
        emit Transfer(tokenOwner, address(0), tokens);
        return true;
    }
    function () public payable {
        revert();
    }
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}


// ----------------------------------------------------------------------------
// Property Data Structure
// ----------------------------------------------------------------------------
library Properties {
    struct Property {
        address owner;
        bool exists;
        uint index;
        string location;
    }
    struct Data {
        bool initialised;
        mapping(address => Property) entries;
        address[] index;
    }

    event PropertyAdded(address indexed OwnerAddress, string location, uint totalAfter);
    event PropertyRemoved(address indexed OwnerAddress, string location, uint totalAfter);
    event PropertyLocationUpdated(address indexed OwnerAddress, string oldLocation, string newLocation);

    function init(Data storage self) public {
        require(!self.initialised);
        self.initialised = true;
    }
    function isProperty(Data storage self, address OwnerAddress) public view returns (bool) {
        return self.entries[OwnerAddress].exists;
    }
    function add(Data storage self, address OwnerAddress, string PropertyLocation) public {
        require(!self.entries[OwnerAddress].exists);
        self.index.push(OwnerAddress);
        self.entries[OwnerAddress] = Property(true, self.index.length - 1, PropertyLocation);
        emit PropertyAdded(OwnerAddress, PropertyLocation, self.index.length);
    }
    function remove(Data storage self, address OwnerAddress) public {
        require(self.entries[OwnerAddress].exists);
        uint removeIndex = self.entries[OwnerAddress].index;
        emit PropertyRemoved(OwnerAddress, self.entries[OwnerAddress].location, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        address lastIndexAddress = self.index[lastIndex];
        self.index[removeIndex] = lastIndexAddress;
        self.entries[lastIndexAddress].index = removeIndex;
        delete self.entries[OwnerAddress];
        if (self.index.length > 0) {
            self.index.length--;
        }
    }
    function setLocation(Data storage self, address OwnerAddress, string PropertyLocation) public {
        Property storage Property = self.entries[OwnerAddress];
        require(Property.exists);
        emit PropertyLocationUpdated(OwnerAddress, Property.location, PropertyLocation);
        Property.location = PropertyLocation;
    }
    function length(Data storage self) public view returns (uint) {
        return self.index.length;
    }
}
