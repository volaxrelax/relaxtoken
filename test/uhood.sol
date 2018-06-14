// ----------------------------------------------------------------------------
// Uhodchain Dapp
// 
// https://github.com/vincentshangjin/uhoodchain
// Based on ClubEth.App Project https://github.com/bokkypoobah/ClubEth
// 
// the Uhoodchain Dapp Project - 2018. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------

pragma solidity ^0.4.24;

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
// UhoodToken Interface = ERC20 + symbol + decimals + burn
// + approveAndCall
// ----------------------------------------------------------------------------
contract UhoodTokenInterface is ERC20Interface {
    function symbol() public view returns (string);
    // function location() public view returns (string);
    function decimals() public view returns (uint8);
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);
    // function mint(address tokenOwner, uint tokens) public returns (bool success);
    function burn(address tokenOwner, uint tokens) public returns (bool success);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    event LogBytes(bytes data);

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public {
        ERC20Interface(token).transferFrom(from, address(this), tokens);
        emit LogBytes(data);
    }
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
    string _name;
    uint8 _decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor(string symbol, string name, uint8 decimals, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    function symbol() public view returns (string) {
        return _symbol;
    }
    function name() public view returns (string) {
        return _name;
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
    // function mint(address tokenOwner, uint tokens) public onlyOwner returns (bool success) {
    //     balances[tokenOwner] = balances[tokenOwner].add(tokens);
    //     _totalSupply = _totalSupply.add(tokens);
    //     emit Transfer(address(0), tokenOwner, tokens);
    //     return true;
    // }
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
        bool exists;
        uint index;
        string location;
    }
    struct Data {
        bool initialised;
        mapping(address => Property) entries;
        address[] index;
    }

    event PropertyAdded(address indexed ownerAddress, string location, uint totalAfter);
    event PropertyRemoved(address indexed ownerAddress, string location, uint totalAfter);
    event propertyLocationUpdated(address indexed ownerAddress, string oldLocation, string newLocation);

    function init(Data storage self) public {
        require(!self.initialised);
        self.initialised = true;
    }
    function isPropertyOwner(Data storage self, address ownerAddress) public view returns (bool) {
        return self.entries[ownerAddress].exists;
    }
    function add(Data storage self, address ownerAddress, string propertyLocation) public {
        require(!self.entries[ownerAddress].exists);
        self.index.push(ownerAddress);
        self.entries[ownerAddress] = Property(true, self.index.length - 1, propertyLocation);
        emit PropertyAdded(ownerAddress, propertyLocation, self.index.length);
    }
    function remove(Data storage self, address ownerAddress) public {
        require(self.entries[ownerAddress].exists);
        uint removeIndex = self.entries[ownerAddress].index;
        emit PropertyRemoved(ownerAddress, self.entries[ownerAddress].location, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        address lastIndexAddress = self.index[lastIndex];
        self.index[removeIndex] = lastIndexAddress;
        self.entries[lastIndexAddress].index = removeIndex;
        delete self.entries[ownerAddress];
        if (self.index.length > 0) {
            self.index.length--;
        }
    }
    function setLocation(Data storage self, address ownerAddress, string propertyLocation) public {
        Property storage property = self.entries[ownerAddress];
        require(property.exists);
        emit propertyLocationUpdated(ownerAddress, property.location, propertyLocation);
        property.location = propertyLocation;
    }
    function length(Data storage self) public view returns (uint) {
        return self.index.length;
    }
}

// ----------------------------------------------------------------------------
// Uhood
// ----------------------------------------------------------------------------
contract Uhood is Owned {
    // TODO: create multiple owner/admins to approve property listing
    using SafeMath for uint;
    using Properties for Properties.Data;
    // using Proposals for Proposals.Data;

    // string public name;

    UhoodTokenInterface public token;
    Properties.Data properties;
    // Proposals.Data public proposals;
    bool public initialised;

    uint public tokensToAddNewProperties = 100;
    // uint public tokensGivenToNewUser = 500;

    // uint public quorum = 80;
    // uint public quorumDecayPerWeek = 10;
    // uint public requiredMajority = 70;


    // Must be copied here to be added to the ABI
    event PropertyAdded(address indexed ownerAddress, string name, uint totalAfter);
    event PropertyRemoved(address indexed ownerAddress, string name, uint totalAfter);
    event PropertyNameUpdated(address indexed ownerAddress, string oldName, string newName);

    // event NewProposal(uint indexed proposalId, Proposals.ProposalType indexed proposalType, address indexed proposer); 
    // event Voted(uint indexed proposalId, address indexed voter, bool vote, uint votedYes, uint votedNo);
    // event VoteResult(uint indexed proposalId, bool pass, uint votes, uint quorumPercent, uint PropertiesLength, uint yesPercent, uint requiredMajority);
    // event TokenUpdated(address indexed oldToken, address indexed newToken);
    event tokensToAddNewPropertiesUpdated(uint oldTokens, uint newTokens);
    // event EtherDeposited(address indexed sender, uint amount);
    // event EtherTransferred(uint indexed proposalId, address indexed sender, address indexed recipient, uint amount);


    modifier onlyPropertyOwner {
        require(properties.isPropertyOwner(msg.sender));
        _;
    }

    constructor(address uhoodToken, uint _tokensToAddNewProperties) public {
        properties.init();        
        token = UhoodTokenInterface(uhoodToken);
        tokensToAddNewProperties = _tokensToAddNewProperties;
    }
    // function init(address ownerAddress, string propertyLocation) public {
    // address ownerAddress
    function init() public {
        require(!initialised);
        initialised = true;
        // properties.add(ownerAddress, propertyLocation);
        // token.mint(ownerAddress, tokensGivenToNewUser);
    }
    function addProperty(address propertyOwner, string propertyLocation) public {
        Properties.Property memory Property = properties.entries[msg.sender];
        require(!Property.exists);
        // require(token.approveAndCall(address(this), tokensToAddNewProperties, ""));
        // require(token.balanceOf(msg.sender) > tokensToAddNewProperties);        
        require(token.transferFrom(msg.sender, address(this), tokensToAddNewProperties) == true);
        properties.add(propertyOwner, propertyLocation);
    }
    function setPropertyLocation(string propertyLocation) public {
        properties.setLocation(msg.sender, propertyLocation);
    }

    function numberOfProperties() public view returns (uint) {
        return properties.length();
    }
    function getProperties() public view returns (address[]) {
        return properties.index;
    }
    function getPropertyData(address ownerAddress) public view returns (bool _exists, uint _index, string _name) {
        Properties.Property memory Property = properties.entries[ownerAddress];
        return (Property.exists, Property.index, Property.location);
    }
    function getPropertyByIndex(uint _index) public view returns (address _Property) {
        return properties.index[_index];
    }

}


