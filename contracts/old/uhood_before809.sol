// ----------------------------------------------------------------------------
// Uhodchain Dapp
// https://github.com/vincentshangjin/uhoodchain
// Based on ClubEth.App Project https://github.com/bokkypoobah/ClubEth
// the Uhoodchain Dapp Project - 2018. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------

pragma solidity 0.4.24;


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

    string public _symbol;
    string public _name;
    uint8 public _decimals;
    uint public _totalSupply;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    constructor(string symbol, string name, uint8 decimals, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function () public payable {
        revert();
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
        return _totalSupply - balances[address(0)];
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

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}


// ----------------------------------------------------------------------------
// Property Data Structure
// ----------------------------------------------------------------------------
library Properties {
    enum PropertyType {
        House,                         //  0 House
        ApartmentAndUnit,              //  1 Apartment and unit
        Townhouse,                     //  2 Townhouse
        Villa,                         //  3 Villa
        Acreage,                       //  4 Acreage
        BlockOfUnits,                  //  5 Block of units
        RetirementLiving               //  6 Retirement living
    }

    // The number of bedrooms, bathrooms, garage spaces
    enum NumberOf {
        Zero,                          //  0 Zero
        One,                           //  1 One
        Two,                           //  2 Two
        Three,                         //  3 Three
        Four,                          //  4 Four
        Five,                          //  5 Five
        SixOrMore                      //  6 Six or more
    }

    struct Property {
        bool exists;
        uint index;
        address owner;
        string location;
        PropertyType propertyType;
        NumberOf bedrooms;
        NumberOf bathrooms;
        NumberOf garageSapces;
        string comments;
        uint nextAvailableDate;
    }

    struct Data {
        bool initialised;

        // The bytes32 key is the property identifier
        mapping(bytes32 => Property) entries;
        bytes32[] index;
    }

    event PropertyAdded(bytes32 propertyHash, address indexed ownerAddress, string location, uint totalAfter);
    event PropertyRemoved(bytes32 propertyHash, address indexed ownerAddress, string location, uint totalAfter);
    // event propertyLocationUpdated(address indexed ownerAddress, string oldLocation, string newLocation);

    function init(Data storage self) public {
        require(!self.initialised);
        self.initialised = true;
    }

    function isPropertyOwner(Data storage self, address _ownerAddress,
        bytes32 _propertyHash) public view returns (bool) {
        /* bytes32 propertyHash = keccak256(abi.encodePacked(ownerAddress, propertyLocation)); */
        return (self.entries[_propertyHash].exists && self.entries[_propertyHash].owner == _ownerAddress);
    }

    function add(
        Data storage self,
        address _ownerAddress,
        string _propertyLocation,
        PropertyType _propertyType,
        NumberOf _bedrooms,
        NumberOf _bathrooms,
        NumberOf _garageSpaces,
        string _comments,
        uint _nextAvailableDate)
        public
    {
        bytes32 propertyHash = keccak256(abi.encodePacked(_ownerAddress, _propertyLocation));

        require(!self.entries[propertyHash].exists);
        require(_ownerAddress != 0x0);
        require(bytes(_propertyLocation).length > 0);

        self.index.push(propertyHash);
        self.entries[propertyHash] = Property(true, self.index.length - 1,
                                            _ownerAddress, _propertyLocation, _propertyType, _bedrooms,
                                            _bathrooms, _garageSpaces, _comments, _nextAvailableDate);
        emit PropertyAdded(propertyHash, _ownerAddress, _propertyLocation, self.index.length);
    }

    function remove(Data storage self, bytes32 _propertyHash) public {

        /* bytes32 propertyHash = keccak256(abi.encodePacked(_ownerAddress, _propertyLocation)); */

        require(self.entries[_propertyHash].exists);
        uint removeIndex = self.entries[_propertyHash].index;
        address _ownerAddress = self.entries[_propertyHash].owner;
        string memory _propertyLocation = self.entries[_propertyHash].location;
        emit PropertyRemoved(_propertyHash, _ownerAddress, _propertyLocation, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        bytes32 lastIndexAddress = self.index[lastIndex];
        self.index[removeIndex] = lastIndexAddress;
        self.entries[lastIndexAddress].index = removeIndex;
        delete self.entries[_propertyHash];
        if (self.index.length > 0) {
            self.index.length--;
        }

    }

    // TODO: implement a setOwner function by calling remove and then add
    // function setOwner(Data storage self, address ownerAddress,
    // string propertyLocation, address newOwnerAddress) public {
    //     bytes32 propertyHash = keccak256(abi.encodePacked(ownerAddress, propertyLocation));
    //     Property storage property = self.entries[ownerAddress];
    //     require(property.exists);
    //     emit propertyLocationUpdated(ownerAddress, property.location, propertyLocation);
    //     property.location = propertyLocation;
    // }
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
    Properties.Data public properties;
    // Proposals.Data public proposals;
    bool public initialised;

    uint public tokensToAddNewProperties;
    address public tokenAddress;
    // uint public tokensGivenToNewUser = 500;
    mapping(address => mapping(address => uint)) public balances;

    // uint public quorum = 80;
    // uint public quorumDecayPerWeek = 10;
    // uint public requiredMajority = 70;

    // Must be copied here to be added to the ABI
    event PropertyAdded(address indexed ownerAddress, string name, uint totalAfter);
    event PropertyRemoved(address indexed ownerAddress, string name, uint totalAfter);
    event PropertyNameUpdated(address indexed ownerAddress, string oldName, string newName);
    event TokensDeposited(address depositor, address tokenAddress, uint tokens, uint balanceAfter);
    event TokensToAddNewPropertiesUpdated(uint oldTokens, uint newTokens);
    // event EtherDeposited(address indexed sender, uint amount);
    // event EtherTransferred(uint indexed proposalId, address indexed sender, address indexed recipient, uint amount);

    modifier onlyPropertyOwner (bytes32 _propertyHash) {
        require(properties.isPropertyOwner(msg.sender, _propertyHash));
        _;
    }

    constructor(address _uhoodToken, uint _tokensToAddNewProperties) public {
        properties.init();
        token = UhoodTokenInterface(_uhoodToken);
        tokenAddress = _uhoodToken;
        tokensToAddNewProperties = _tokensToAddNewProperties;
    }

    function init() public {
        require(!initialised);
        initialised = true;
    }

    function getPropertyHash(address _propertyOwner, string _propertyLocation) public pure returns (bytes32) {
        bytes32 propertyHash = keccak256(abi.encodePacked(_propertyOwner, _propertyLocation));
        return propertyHash;
    }

    function addProperty(
        address _propertyOwner,
        string _propertyLocation,
        Properties.PropertyType _propertyType,
        Properties.NumberOf _bedrooms,
        Properties.NumberOf _bathrooms,
        Properties.NumberOf _garageSpaces,
        string _comments,
        uint _nextAvailableDate)
        public
    {
        // TODO: implement approveAndCall
        // require(token.approveAndCall(this, tokensToAddNewProperties, ""));
        require(token.transferFrom(msg.sender, this, tokensToAddNewProperties));
        balances[tokenAddress][msg.sender] = balances[tokenAddress][msg.sender].add(tokensToAddNewProperties);
        emit TokensDeposited(msg.sender, tokenAddress, tokensToAddNewProperties, balances[tokenAddress][msg.sender]);
        properties.add(_propertyOwner, _propertyLocation, _propertyType,
                        _bedrooms, _bathrooms, _garageSpaces, _comments, _nextAvailableDate);
    }

    function removeProperty(
        bytes32 _propertyHash)
        public
        onlyPropertyOwner(_propertyHash)
    {
        properties.remove(_propertyHash);
    }

    /* function transferProperty(
        address _propertyOwner,
        string _propertyLocation)
        public
        onlyPropertyOwner(_propertyLocation)
    { // solhint-disable-line

        // TODO: Implementation

    } */
    function updateNextAvailableDate(
        bytes32 _propertyHash,
        /* address _propertyOwner,
        string _propertyLocation, */
        uint _nextAvailableDate)
        public
        onlyPropertyOwner(_propertyHash)
    {
        require(_nextAvailableDate > 0);
        /* bytes32 propertyHash = keccak256(abi.encodePacked(_propertyOwner, _propertyLocation)); */
        Properties.Property storage property = properties.entries[_propertyHash];
        property.nextAvailableDate = _nextAvailableDate;
    }

    // function setPropertyLocation(string propertyLocation) public {
    //     properties.setLocation(msg.sender, propertyLocation);
    // }
    function numberOfProperties() public view returns (uint) {
        return properties.length();
    }

    function getProperties() public view returns (bytes32[]) {
        return properties.index;
    }

    function getPropertyData(
        bytes32 _propertyHash
        /* address _ownerAddress,
        string _propertyLocation */
    )
        public
        view
        returns (
            bool exists,
            uint index,
            address owner,
            string location,
            Properties.PropertyType propertyType,
            Properties.NumberOf bedrooms,
            Properties.NumberOf bathrooms,
            Properties.NumberOf garageSpaces,
            string comments,
            uint nextAvailableDate)
    {
        /* bytes32 propertyHash = keccak256(abi.encodePacked(_ownerAddress, _propertyLocation)); */
        Properties.Property memory property = properties.entries[_propertyHash];
        return (property.exists, property.index, property.owner, property.location, property.propertyType,
                property.bedrooms, property.bathrooms, property.garageSapces, property.comments,
                property.nextAvailableDate);
    }

    function getPropertyByIndex(uint _index) public view returns (bytes32 property) {
        return properties.index[_index];
    }

}
