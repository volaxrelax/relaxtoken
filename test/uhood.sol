// ----------------------------------------------------------------------------
// Uhodchain Dapp
// https://github.com/vincentshangjin/uhoodchain
// Based on ClubEth.App Project https://github.com/bokkypoobah/ClubEth
// https://github.com/saurfang/erc809-billboard/blob/master/contracts/BasicBillboard.sol
// the Uhoodchain Dapp Project - 2018. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------

pragma solidity 0.4.24;

/* import "./ERC721Token/ERC721Basic.sol";
import "./ERC721Token/ERC721BasicToken.sol"; */
import "./ERC721Token/ERC721Token.sol";


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


/// @title ERC809: a standard interface for renting rival non-fungible tokens.
contract ERC809 is ERC721Basic {
    /// @dev This emits when a successful rhttps://github.com/saurfang/erc809-billboard/blob/master/contracts/BasicBillboard.soleservation is made for accessing any NFT.
    event Reserve(address indexed _renter, uint256 _tokenId, uint256 _start, uint256 _stop);

    /// @dev This emits when a successful cancellation is made for a reservation.
    event CancelReservation(address indexed _renter, uint256 _tokenId, uint256 _start, uint256 _stop);

    /// @notice Reserve access to token `_tokenId` from time `_start` to time `_stop`
    /// @dev A successful reservation must ensure each time slot in the range _start to _stop
    ///  is not previously reserved (by calling the function checkAvailable() described below)
    ///  and then emit a Reserve event.
    function reserve(uint256 _tokenId, uint256 _start, uint256 _stop) external payable returns (bool success);

    /// @notice Cancel reservation for `_tokenId` between `_start` and `_stop`
    /// @dev All reservations between `_start` and `_stop` are cancelled. `_start` and `_stop` do not guarantee
    //   to be the ends for any one of the reservations
    function cancelReservation(uint256 _tokenId, uint256 _start, uint256 _stop) external returns (bool success);

    /// @notice Revoke access to token `_tokenId` from `_renter` and settle payments
    /// @dev This function should be callable by either the owner of _tokenId or _renter,
    ///  however, the owner should only be able to call this function if now >= _stop to
    ///  prevent premature settlement of funds.
    function settle(uint256 _tokenId, address _renter, uint256 _stop) external returns (bool success);

    /// @notice Find the renter of an NFT token as of `_time`
    /// @dev The renter is who made a reservation on `_tokenId` and the reservation spans over `_time`.
    function renterOf(uint256 _tokenId, uint256 _time) public view returns (address);


    /// @notice Query if token `_tokenId` if available to reserve between `_start` and `_stop` time
    function checkAvailable(uint256 _tokenId, uint256 _start, uint256 _stop) public view returns (bool available);
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


/* /// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
contract ERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets.
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
} */


// ----------------------------------------------------------------------------
// PropertyToken
// ----------------------------------------------------------------------------
contract PropertyToken is ERC721Token {

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

    event PropertyAdded(bytes32 propertyHash, address indexed ownerAddress, string name, uint totalAfter);
    event PropertyRemoved(bytes32 propertyHash, address indexed ownerAddress, string name, uint totalAfter);

    mapping(bytes32 => Property) public entries;
    bytes32[] public index;
    uint public test;

    modifier onlyOwner (uint _tokenId) {
        require(ownerOf(uint(_tokenId)) == msg.sender);
        _;
    }

    constructor() public ERC721Token("Property Token", "PTY") {
        test = 123;
    }

    function changeTest (uint newTest) {
        test = newTest;
    }

    function addProperty(
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

        require(entries[propertyHash].exists);
        require(_ownerAddress != 0x0);
        require(bytes(_propertyLocation).length > 0);

        index.push(propertyHash);
        entries[propertyHash] = Property(true, index.length - 1,
                                            _ownerAddress, _propertyLocation, _propertyType, _bedrooms,
                                            _bathrooms, _garageSpaces, _comments, _nextAvailableDate);
        _mint(_ownerAddress, uint(propertyHash));
        emit PropertyAdded(propertyHash, _ownerAddress, _propertyLocation, index.length);
    }

    function removeProperty(bytes32 _propertyHash) public onlyOwner(uint(_propertyHash)) {
        require(entries[_propertyHash].exists);
        uint removeIndex = entries[_propertyHash].index;
        address _ownerAddress = entries[_propertyHash].owner;
        string memory _propertyLocation = entries[_propertyHash].location;
        emit PropertyRemoved(_propertyHash, _ownerAddress, _propertyLocation, index.length - 1);
        uint lastIndex = index.length - 1;
        bytes32 lastIndexAddress = index[lastIndex];
        index[removeIndex] = lastIndexAddress;
        entries[lastIndexAddress].index = removeIndex;
        delete entries[_propertyHash];
        if (index.length > 0) {
            index.length--;
        }
        _burn(_ownerAddress, uint(_propertyHash));
        emit PropertyRemoved(_propertyHash, _ownerAddress, _propertyLocation, index.length);
    }
}


/* // ----------------------------------------------------------------------------
// PropertyToken
// ----------------------------------------------------------------------------
contract PropertyToken is ERC809, ERC721Token {

    struct Reservation {
        address renter;
        // total price
        uint256 amount;
        // access period
        uint256 startTimestamp;
        uint256 stopTimestamp;
        // whether reservation has been settled
        bool settled;
    }

    struct Token {
        // iterable of all reservations
        Reservation[] reservations;
        // mapping from start and end timestamps for each reservation to reservation id
        uint startTimestamps;
        uint stopTimestamps;
    }

    // mapping of all tokens
    mapping(uint => Token) public tokens;
    // mapping of token owner's money
    mapping(address => uint) public payouts;

    constructor(uint _tokens) public ERC721Token("PropertyToken", "PRT") {
        for (uint i = 0; i < _tokens; i++) {
            super._mint(msg.sender, i);
        }
    }

    /// @dev Guarantees msg.sender is owner of the given token
    /// @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
    modifier onlyRenterOf(uint256 _tokenId, uint256 _time) {
        require(renterOf(_tokenId, _time) == msg.sender);
        _;
    }

    /// @notice Find the renter of an NFT token as of `_time`
    /// @dev The renter is who made a reservation on `_tokenId` and the reservation spans over `_time`.
    function renterOf(uint256 _tokenId, uint256 _time)
        public
        view
        returns(address)
    {
        Token storage token = tokens[_tokenId];
        bool found;
        uint256 startTime;
        uint256 reservationId;
        (found, startTime, reservationId) = token.startTimestamps.floorEntry(_time);
        if (found) {
            Reservation storage reservation = token.reservations[reservationId];
            if (reservation.stopTimestamp > _time) {
                return reservation.renter;
            }
        }
    }

  /// @notice Reserve access to token `_tokenId` from time `_start` to time `_stop`
  /// @dev A successful reservation must ensure each time slot in the range _start to _stop
  ///  is not previously reserved (by calling the function checkAvailable() described below)
  ///  and then emit a Reserve event.
    function reserve(uint256 _tokenId, uint256 _start, uint256 _stop)
        external
        payable
        returns(bool success)
    {
        if (checkAvailable(_tokenId, _start, _stop)) {
            Token storage token = tokens[_tokenId];
            Reservation[] storage reservations = token.reservations;
            uint id = reservations.length++;
            reservations[id] = Reservation(msg.sender, msg.value, _start, _stop, false, "");
            token.startTimestamps.put(_start, id);
            token.stopTimestamps.put(_stop, id);
            return true;
        }
    }

    /// @notice Revoke access to token `_tokenId` from `_renter` and settle payments
    /// @dev This function should be callable by either the owner of _tokenId or _renter,
    ///  however, the owner should only be able to call this function if now >= _stop to
    ///  prevent premature settlement of funds.
    function settle(uint256 _tokenId, address _renter, uint256 _stop)
        external
        returns(bool success)
    {
        address tokenOwner = ownerOf(_tokenId);
        // TODO: implement iterator in TreeMap for more efficient batch retrival
        Token storage token = tokens[_tokenId];
        Reservation[] storage reservations = token.reservations;

        bool found = true;
        uint stopTime = _stop;
        uint reservationId;
        while (found) {
        // FIXME: a token should also have a `renter => stopTimestamps` mapping to skip
        //   reservations that don't belong to a renter
            (found, stopTime, reservationId) = token.stopTimestamps.ceilingEntry(stopTime);
            Reservation storage reservation = reservations[reservationId];
            if (found && !reservation.settled && reservation.renter == _renter) {
                if (msg.sender == tokenOwner) {
                    if (now < reservation.stopTimestamp) {
                        revert("Reservation has yet completed and currently can only be settled by the renter!");
                    }

                    reservation.settled = true;
                    payouts[tokenOwner] += reservation.amount;
                    success = true;
                } else if (msg.sender == _renter) {
                    reservation.settled = true;
                    payouts[tokenOwner] += reservation.amount;
                    success = true;
                }
            }
        }
    }
    /// @notice Query if token `_tokenId` if available to reserve between `_start` and `_stop` time
    /// @dev For the requested token, we examine its current resertions, check
    ///   1. whether the last reservation that has `startTime` before `_start` already ended before `_start`
    ///                Okay                            Bad
    ///           *startTime*   stopTime        *startTime*   stopTime
    ///             |---------|                  |---------|
    ///                          |-------               |-------
    ///                          _start                 _start
    ///   2. whether the soonest reservation that has `endTime` after `_end` will start after `_end`.
    ///                Okay                            Bad
    ///          startTime   *stopTime*         startTime   *stopTime*
    ///             |---------|                  |---------|
    ///    -------|                           -------|
    ///           _stop                              _stop
    ///
    //   NB: reservation interval are [start time, stop time] i.e. closed on both ends.
    function checkAvailable(uint256 _tokenId, uint256 _start, uint256 _stop)
        public
        view
        returns(bool available)
    {
        Token storage token = tokens[_tokenId];
        Reservation[] storage reservations = token.reservations;
        if (reservations.length > 0) {
            bool found;
            uint reservationId;

            uint stopTime;
            (found, stopTime, reservationId) = token.stopTimestamps.floorEntry(_stop);
            if (found && stopTime >= _start) {
                return false;
            }

            uint startTime;
            (found, startTime, reservationId) = token.startTimestamps.ceilingEntry(_start);
            if (found && startTime <= _stop) {
                return false;
            }
        }

        return true;
    }

    /// @notice Cancel reservation for `_tokenId` between `_start` and `_stop`
    function cancelReservation(uint256 _tokenId, uint256 _start, uint256 _stop)
        external
        returns (bool success)
    {
        // TODO: implement iterator in TreeMap for more efficient batch removal
        Token storage token = tokens[_tokenId];
        Reservation[] storage reservations = token.reservations;

        bool found = true;
        uint startTime = _start;
        uint stopTime;
        uint reservationId;
        // FIXME: a token should also have a `renter => startTimestamps` mapping to skip
        //   reservations that don't belong to a renter more efficiently
        (found, startTime, reservationId) = token.startTimestamps.ceilingEntry(startTime);
        while (found) {
            Reservation storage reservation = reservations[reservationId];
            stopTime = reservation.stopTimestamp;
            if (found) {
                if (stopTime <= _stop && reservation.renter == msg.sender) {
                    token.startTimestamps.remove(startTime);
                    token.stopTimestamps.remove(stopTime);
                    delete reservations[reservationId];

                    success = true;
                }

                (found, startTime, reservationId) = token.startTimestamps.higherEntry(startTime);
            }
        }
    }

} */
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
