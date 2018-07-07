#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

SOURCEDIR=`grep ^SOURCEDIR= settings.txt | sed "s/^.*=//"`
TOKENDIR=`grep ^TOKENDIR= settings.txt | sed "s/^.*=//"`

UHOODSOL=`grep ^UHOODSOL= settings.txt | sed "s/^.*=//"`
UHOODJS=`grep ^UHOODJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`
JSONSUMMARY=`grep ^JSONSUMMARY= settings.txt | sed "s/^.*=//"`
JSONEVENTS=`grep ^JSONEVENTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`perl -le "print scalar localtime $CURRENTTIME"`
START_DATE=`echo "$CURRENTTIME+45" | bc`
START_DATE_S=`perl -le "print scalar localtime $START_DATE"`
END_DATE=`echo "$CURRENTTIME+60*2" | bc`
END_DATE_S=`perl -le "print scalar localtime $END_DATE"`

printf "MODE               = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT    = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD           = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "SOURCEDIR          = '$SOURCEDIR'\n" | tee -a $TEST1OUTPUT
printf "TOKENDIR          = '$TOKENDIR'\n" | tee -a $TEST1OUTPUT
printf "UHOODSOL     = '$UHOODSOL'\n" | tee -a $TEST1OUTPUT
printf "CLUBFACTORYJS      = '$CLUBFACTORYJS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA     = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS          = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT        = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS       = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "JSONSUMMARY        = '$JSONSUMMARY'\n" | tee -a $TEST1OUTPUT
printf "JSONEVENTS         = '$JSONEVENTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME        = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "START_DATE         = '$START_DATE' '$START_DATE_S'\n" | tee -a $TEST1OUTPUT
printf "END_DATE           = '$END_DATE' '$END_DATE_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
# `cp modifiedContracts/SnipCoin.sol .`
`cp $SOURCEDIR/$UHOODSOL .`
`cp -a $SOURCEDIR/$TOKENDIR .`

# --- Modify parameters ---
# `perl -pi -e "s/START_DATE \= 1525132800.*$/START_DATE \= $START_DATE; \/\/ $START_DATE_S/" $CROWDSALESOL`
# `perl -pi -e "s/endDate \= 1527811200;.*$/endDate \= $END_DATE; \/\/ $END_DATE_S/" $CROWDSALESOL`

DIFFS1=`diff $SOURCEDIR/$UHOODSOL $UHOODSOL`
echo "--- Differences $SOURCEDIR/$UHOODSOL $UHOODSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

solc_0.4.24 --version | tee -a $TEST1OUTPUT

echo "var uhoodOutput=`solc_0.4.24 --optimize --pretty-json --combined-json abi,bin,interface $UHOODSOL`;" > $UHOODJS


geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$UHOODJS");
loadScript("functions.js");


var uhoodAbi = JSON.parse(uhoodOutput.contracts["$UHOODSOL:Uhood"].abi);
var uhoodBin = "0x" + uhoodOutput.contracts["$UHOODSOL:Uhood"].bin;
var tokenAbi = JSON.parse(uhoodOutput.contracts["$UHOODSOL:UhoodToken"].abi);
var tokenBin = "0x" + uhoodOutput.contracts["$UHOODSOL:UhoodToken"].bin;
var propertiesLibAbi = JSON.parse(uhoodOutput.contracts["$UHOODSOL:Properties"].abi);
var propertiesLibBin = "0x" + uhoodOutput.contracts["$UHOODSOL:Properties"].bin;
var propertyTokenAbi = JSON.parse(uhoodOutput.contracts["$UHOODSOL:PropertyToken"].abi);
var propertyTokenBin = "0x" + uhoodOutput.contracts["$UHOODSOL:PropertyToken"].bin;


console.log("DATA: uhoodAbi=" + JSON.stringify(uhoodAbi));
console.log("DATA: uhoodBin=" + JSON.stringify(uhoodBin));
console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));
console.log("DATA: propertiesLibAbi=" + JSON.stringify(propertiesLibAbi));
console.log("DATA: propertiesLibBin=" + JSON.stringify(propertiesLibBin));
console.log("DATA: propertyTokenAbi=" + JSON.stringify(propertyTokenAbi));
console.log("DATA: propertyTokenBin=" + JSON.stringify(propertyTokenBin));


unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Deploy UhoodToken";
var tokenSymbol = "UHT";
var tokenName = "Uhood Token";
var tokenDecimal = 18;
var totalSupply = new BigNumber("500000000").shift(18);
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var tokenContract = web3.eth.contract(tokenAbi);
// console.log(JSON.stringify(clubContract));
// console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;
var token = tokenContract.new(tokenSymbol, tokenName, tokenDecimal, totalSupply, {from: contractOwnerAccount, data: tokenBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    console.log(e);
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
        addAccount(tokenAddress, "token");
        console.log("DATA: tokenAddress=" + tokenAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
// console.log(tokenAddress);
// console.log(JSON.stringify(tokenAbi));

printBalances();
failIfTxStatusError(tokenTx, msg);
printTxData("tokenTx", tokenTx);
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Deploy PropertyToken";
var tokenSymbol = "PTY";
var tokenName = "Property Token";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var propertyTokenContract = web3.eth.contract(propertyTokenAbi);
console.log(JSON.stringify(propertyTokenContract));
var propertyTokenTx = null;
var propertyTokenAddress = null;
var minRentTime = 3600*24; // Minimum 1 day;
var propertyToken = propertyTokenContract.new(tokenAddress, new BigNumber("100").shift(18), minRentTime, {from: contractOwnerAccount, data: propertyTokenBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    console.log(e);
    if (!e) {
      if (!contract.address) {
        propertyTokenTx = contract.transactionHash;
      } else {
        propertyTokenAddress = contract.address;
        addAccount(propertyTokenAddress, "Property Token");
        console.log("DATA: propertyTokenAddress=" + propertyTokenAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
// addTokenContractAddressAndAbi(propertyTokenAddress, propertyTokenAbi);
// console.log(propertyTokenAddress);
// console.log(JSON.stringify(propertyTokenAbi));

// printBalances();
failIfTxStatusError(propertyTokenTx, msg);
printTxData("propertyTokenTx", propertyTokenTx);
console.log("RESULT: ");


// console.log(propertyToken.test());
// tx1 = propertyToken.changeTest(999, {from: owner1Account, gas: 5000000, gasPrice: defaultGasPrice});
// while (txpool.status.pending > 0) {
// }
// console.log(propertyToken.test());

// -----------------------------------------------------------------------------
var msg = "Transfer 20000 tokens to owner 1, owner 2, renter 1 and renter 2";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var transferTokensTx1 = token.transfer(owner1Account, new BigNumber("20000").shift(18), {from: contractOwnerAccount, gas: 500000, gasPrice: defaultGasPrice});
var transferTokensTx2 = token.transfer(owner2Account, new BigNumber("20000").shift(18), {from: contractOwnerAccount, gas: 500000, gasPrice: defaultGasPrice});
var transferTokensTx3 = token.transfer(renter1Account, new BigNumber("20000").shift(18), {from: contractOwnerAccount, gas: 500000, gasPrice: defaultGasPrice});
var transferTokensTx4 = token.transfer(renter2Account, new BigNumber("20000").shift(18), {from: contractOwnerAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(transferTokensTx1, " - transfer 20000 tokens to owner 1");
failIfTxStatusError(transferTokensTx2, " - transfer 20000 tokens to owner 2");
failIfTxStatusError(transferTokensTx3, " - transfer 20000 tokens to retner 1");
failIfTxStatusError(transferTokensTx4, " - transfer 20000 tokens to renter 2");
printTxData("transferTokensTx1", transferTokensTx1);
console.log("RESULT: ");

printBalances();


// -----------------------------------------------------------------------------
var msg = "Owner 1 adds property 1 to the smart contract";
// -----------------------------------------------------------------------------
var propertyOwner1 = owner1Account;
var propertyLocation1 = "96/71 Victoria Street, Potts Point NSW 2011";
var propertyType = 1; // apartment
var bedrooms = 3;
var bathrooms = 2;
var garageSpaces = 1;
var comments = "city and harbour view";
var initialAvailableDate = $START_DATE;

console.log("RESULT: ----- " + msg + " -----");
printBalances();

console.log("RESULTS: initialAvailableDate = " + initialAvailableDate);
// var hashOf = "0x" + bytes4ToHex(functionSig) + addressToHex(tokenContractAddress) + addressToHex(from) + addressToHex(to) + uint256ToHex(tokens) + uint256ToHex(fee) + uint256ToHex(nonce);
var propertyHashJS1 = web3.sha3("0x" + addressToHex(propertyOwner1) + stringToHex(propertyLocation1), {encoding: "hex"})
console.log("RESULT: propertyHashJS1 = " + propertyHashJS1);

var listingTx1a = token.approve(propertyTokenAddress, new BigNumber("200").shift(18), {from: owner1Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var listingTx1b = propertyToken.addProperty(propertyOwner1, propertyLocation1, propertyType, bedrooms, bathrooms, garageSpaces, comments, initialAvailableDate, new BigNumber("123").shift(18), 0x0, {from: owner1Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx1a, "listingTx1a");
failIfTxStatusError(listingTx1b, "listingTx1b");
printTxData("listingTx1a", listingTx1a);
printTxData("listingTx1b", listingTx1b);


printBalances();

var propertyHashUint1 = propertyToken.hashToInt(propertyHashJS1);
console.log("RESULT: PropertyToken.ownerOf(propertyHashUint1) = " + propertyToken.ownerOf(propertyHashUint1));
printPropertyTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 2 adds property 2 to the smart contract";
// -----------------------------------------------------------------------------
var propertyOwner2 = owner2Account;
var propertyLocation2 = "136 Raglan Street, Mosman NSW 2088";
var propertyType = 0; // apartment
var bedrooms = 5;
var bathrooms = 3;
var garageSpaces = 2;
var comments = "Swimming Pool - Inground";
var now = Date.now();
var future = parseInt(now/1000) + (90*24*60*60);
var initialAvailableDate = future;

console.log("RESULT: ----- " + msg + " -----");
// printBalances();
console.log("RESULTS: initialAvailableDate = " + initialAvailableDate);
// var hashOf = "0x" + bytes4ToHex(functionSig) + addressToHex(tokenContractAddress) + addressToHex(from) + addressToHex(to) + uint256ToHex(tokens) + uint256ToHex(fee) + uint256ToHex(nonce);
var propertyHashJS2 = web3.sha3("0x" + addressToHex(propertyOwner2) + stringToHex(propertyLocation2), {encoding: "hex"})
console.log("RESULT: propertyHashJS2 = " + propertyHashJS2);

var listingTx2a = token.approve(propertyTokenAddress, new BigNumber("200").shift(18), {from: owner2Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var listingTx2b = propertyToken.addProperty(propertyOwner2, propertyLocation2, propertyType, bedrooms, bathrooms, garageSpaces, comments, initialAvailableDate, new BigNumber("456").shift(18), 0x0, {from: owner2Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx2a, "listingTx2a");
failIfTxStatusError(listingTx2b, "listingTx2b");
printTxData("listingTx2a", listingTx2a);
printTxData("listingTx2b", listingTx2b);

var propertyHashUint2 = propertyToken.hashToInt(propertyHashJS2);
// var propertyHashUint2_ = new BigNumber(propertyHashJS2.substring(2), 16);
var propertyHashUint2_ = hexToInt(propertyHashJS2);
console.log(propertyHashUint2_);
console.log(propertyHashUint2);

console.log("RESULT: PropertyToken.ownerOf(propertyHashUint2) = " + propertyToken.ownerOf(propertyHashUint2_));
printPropertyTokenContractDetails();
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 2 transfers property 2 to owner 1";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
// printBalances();
console.log("RESULT: propertyHashJS2 = " + propertyHashJS2);
// console.log("RESULT: Before transfer: propertyToken.ownerOf(propertyHashUint2) = " + propertyToken.ownerOf(propertyHashUint2_));
// console.log("RESULT: Before transfer: propertyToken.balanceOf(propertyOwner1) = " + propertyToken.balanceOf(propertyOwner1));
// console.log("RESULT: Before transfer: propertyToken.balanceOf(propertyOwner2) = " + propertyToken.balanceOf(propertyOwner2));
var listingTx3 = propertyToken.safeTransferFrom(propertyOwner2, propertyOwner1, propertyHashUint2, {from: owner2Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx3, "listingTx3");
printTxData("listingTx3", listingTx3);
// console.log("RESULT: After transfer: propertyToken.ownerOf(propertyHashUint2) = " + propertyToken.ownerOf(propertyHashUint2_));
// console.log("RESULT: After transfer: propertyToken.balanceOf(propertyOwner1) = " + propertyToken.balanceOf(propertyOwner1));
// console.log("RESULT: After transfer: propertyToken.balanceOf(propertyOwner2) = " + propertyToken.balanceOf(propertyOwner2));
printPropertyTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 2 cannot remove property 2";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
// printBalances();
console.log("RESULT: propertyHashJS2 = " + propertyHashJS2);
// console.log("RESULT: Before removal: propertyToken.ownerOf(propertyHashUint2_) = " + propertyToken.ownerOf(propertyHashUint2_));
// console.log("RESULT: Before removal: propertyToken.balanceOf(propertyOwner1) = " + propertyToken.balanceOf(propertyOwner1));
// console.log("RESULT: Before removal: propertyToken.balanceOf(propertyOwner2) = " + propertyToken.balanceOf(propertyOwner2));
var listingTx4 = propertyToken.removeProperty(propertyHashJS2, {from: owner2Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
passIfTxStatusError(listingTx4, "listingTx4");
printTxData("listingTx4", listingTx4);
// console.log("RESULT: After removal: propertyToken.ownerOf(propertyHashUint2_) = " + propertyToken.ownerOf(propertyHashUint2_));
// console.log("RESULT: After removal: propertyToken.balanceOf(propertyOwner1) = " + propertyToken.balanceOf(propertyOwner1));
// console.log("RESULT: After removal: propertyToken.balanceOf(propertyOwner2) = " + propertyToken.balanceOf(propertyOwner2));
printPropertyTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 1 removes property 2";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
// printBalances();
console.log("RESULT: propertyHashJS2 = " + propertyHashJS2);
// console.log("RESULT: Before removal: propertyToken.ownerOf(propertyHashUint2_) = " + propertyToken.ownerOf(propertyHashUint2_));
// console.log("RESULT: Before removal: propertyToken.balanceOf(propertyOwner1) = " + propertyToken.balanceOf(propertyOwner1));
// console.log("RESULT: Before removal: propertyToken.balanceOf(propertyOwner2) = " + propertyToken.balanceOf(propertyOwner2));
var listingTx5 = propertyToken.removeProperty(propertyHashJS2, {from: owner1Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx5, "listingTx1");
printTxData("listingTx5", listingTx5);
// console.log("RESULT: After removal: propertyToken.ownerOf(propertyHashUint2_) = " + propertyToken.ownerOf(propertyHashUint2_));
// console.log("RESULT: After removal: propertyToken.balanceOf(propertyOwner1) = " + propertyToken.balanceOf(propertyOwner1));
// console.log("RESULT: After removal: propertyToken.balanceOf(propertyOwner2) = " + propertyToken.balanceOf(propertyOwner2));
printPropertyTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 1 updates initial available date for property 1";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");

var now = Date.now();
var future = parseInt(now/1000) + (30*24*60*60);
console.log("RESULT: future = " + timestampToStr(future));

var listingTx6 = propertyToken.updateInitialAvailableDate(propertyHashJS1, future, {from: owner1Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx6, "listingTx6");
// printBalances();

var propertyData = propertyToken.getPropertyData(propertyHashJS1);
var initialAvailableDateStr = timestampToStr(propertyData[9]);

printTxData("listingTx6", listingTx6);
printPropertyTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 1 updates property data";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");

var propertyType = 1; // apartment
var bedrooms = 3;
var bathrooms = 6;
var garageSpaces = 2;
var comments = "city and harbour view, school zone";

var listingTx7 = propertyToken.updatePropertyData(propertyHashJS1, propertyType, bedrooms, bathrooms, garageSpaces, comments, new BigNumber("789").shift(18), renter1Account, {from: owner1Account, gas: 5000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx7, "listingTx7");
printTxData("listingTx7", listingTx7);
printPropertyTokenContractDetails();
// printBalances();

console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Renter 1 confirms the intention to rent the property and approves the smart contract to charge the bond amount";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var aYearLater = parseInt(now/1000) + (365*24*60*60);

var rentingTx1a = token.approve(propertyTokenAddress, new BigNumber("1000").shift(18), {from: renter1Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var rentingTx1b = propertyToken.updateRentalIntention(propertyHashUint1, {from: renter1Account, gas: 6000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(rentingTx1a, "rentingTx1a");
failIfTxStatusError(rentingTx1b, "rentingTx1b");
printTxData("rentingTx1a", rentingTx1a);
printTxData("rentingTx1b", rentingTx1b);
printPropertyTokenContractDetails();
console.log("RESULT: propertyToken.balanceOfRental(renter1Account, propertyHashUint1, now, aYearLater) = " + propertyToken.balanceOfRental(renter1Account, propertyHashUint1, now, aYearLater));
console.log("RESULT: propertyToken.balanceOfRental(renter2Account, propertyHashUint1, now, aYearLater) = " + propertyToken.balanceOfRental(renter2Account, propertyHashUint1, now, aYearLater));
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 1 mints rental tokens to renter 1 and charges renter 1the bond which is held by the smart contract ";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var rentalStart = parseInt(now/1000) + (31*24*60*60);
var rentalEnd = parseInt(now/1000) + (40*24*60*60);

var rentingTx2 = propertyToken.mintRental(propertyHashUint1, rentalStart, rentalEnd, renter1Account, {from: owner1Account, gas: 6000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(rentingTx2, "rentingTx2");
printTxData("rentingTx2", rentingTx2);
// printPropertyTokenContractDetails();
console.log("RESULT: propertyToken.balanceOfRental(renter1Account, propertyHashUint1, rentalStart, aYearLater) = " + propertyToken.balanceOfRental(renter1Account, propertyHashUint1, now, aYearLater));
// console.log("RESULT: propertyToken.balanceOfRental(renter2Account, propertyHashUint1, now, aYearLater) = " + propertyToken.balanceOfRental(renter2Account, propertyHashUint1, now, aYearLater));

console.log("RESULT: " + propertyToken.ownerOfRental(propertyHashUint1, rentalStart - (1*24*60*60)));
console.log("RESULT: " + propertyToken.ownerOfRental(propertyHashUint1, rentalStart));
console.log("RESULT: " + propertyToken.ownerOfRental(propertyHashUint1, rentalStart + (1*24*60*60)));
console.log("RESULT: " + propertyToken.ownerOfRental(propertyHashUint1, rentalStart + (5*24*60*60)));
console.log("RESULT: " + propertyToken.ownerOfRental(propertyHashUint1, rentalEnd));
console.log("RESULT: " + propertyToken.ownerOfRental(propertyHashUint1, rentalEnd + (1*24*60*60)));

// printBalances();
// console.log("RESULT: ");


exit;

// -----------------------------------------------------------------------------
var msg = "Renter 2 reserves the property for a period";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
// var rentalStart = parseInt(now/1000) + (30*24*60*60);
var rentalStart = parseInt(now/1000);
var rentalEnd = parseInt(now/1000) + (210*24*60*60);

var rentingTx1a = token.approve(propertyTokenAddress, new BigNumber("1000").shift(18), {from: renter2Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var rentingTx1b = propertyToken.reserve(propertyHashUint1, rentalStart, rentalEnd, {from: renter2Account, gas: 6000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(rentingTx1a, "rentingTx1a");
failIfTxStatusError(rentingTx1b, "rentingTx1b");
printTxData("rentingTx1a", rentingTx1a);
printTxData("rentingTx1b", rentingTx1b);

printPropertyTokenContractDetails();
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Renter 2 accesses the property";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var rentalStart = parseInt(now/1000) + (30*24*60*60);

var rentingTx2 = propertyToken.access(propertyHashUint1, {from: renter2Account, gas: 6000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(rentingTx2, "rentingTx2");
printTxData("rentingTx2", rentingTx2);

printPropertyTokenContractDetails();
printBalances();

console.log("RESULT: bond is " + bond);
console.log("RESULT: ");

exit;



































// -----------------------------------------------------------------------------
var deployPropertiesLibMessage = "Deploy Properties Library";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + deployPropertiesLibMessage + " -----");
var propertiesLibContract = web3.eth.contract(propertiesLibAbi);
var propertiesLibTx = null;
var propertiesLibAddress = null;
var currentBlock = eth.blockNumber;
var propertiesLibContract = propertiesLibContract.new({from: contractOwnerAccount, data: propertiesLibBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        propertiesLibTx = contract.transactionHash;
      } else {
        propertiesLibAddress = contract.address;
        addAccount(propertiesLibAddress, "Properties Library");
        console.log("DATA: propertiesLibAddress=" + propertiesLibAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(propertiesLibTx, deployPropertiesLibMessage);
printTxData("propertiesLibTx", propertiesLibTx);
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployUhoodMessage = "Deploy Uhood";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + deployUhoodMessage + " -----");
// console.log("RESULT: clubFactoryBin='" + clubFactoryBin + "'");
var newUhoodBin = uhoodBin.replace(/__uhood\.sol\:Properties__________________/g, propertiesLibAddress.substring(2, 42));
// console.log("RESULT: newUhoodBin='" + newUhoodBin + "'");
var uhoodContract = web3.eth.contract(uhoodAbi);
// console.log(JSON.stringify(uhoodAbi));
// console.log(newClubFactoryBin);
var uhoodTx = null;
var uhoodAddress = null;
var uhood = uhoodContract.new(tokenAddress, new BigNumber("100").shift(18), {from: contractOwnerAccount, data: newUhoodBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    console.log(e);
    if (!e) {
      if (!contract.address) {
        uhoodTx = contract.transactionHash;
      } else {
        uhoodAddress = contract.address;
        addAccount(uhoodAddress, "uhood");
        addClubFactoryContractAddressAndAbi(uhoodAddress, uhoodAbi);
        console.log("DATA: uhoodAddress=" + uhoodAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
eth.getTransactionReceipt(uhoodTx).status;
failIfTxStatusError(uhoodTx, deployUhoodMessage);
printTxData("uhoodTx", uhoodTx);
// printClubFactoryContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Transfer 1000000 tokens to airdrop account";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var transferTokensTx = token.transfer(airdropAccount, new BigNumber("1000000").shift(18), {from: contractOwnerAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(transferTokensTx, msg + " - transfer 1000 tokens to airdrop account");
printTxData("transferTokensTx", transferTokensTx);
console.log("RESULT: ");

printBalances();


// -----------------------------------------------------------------------------
var msg = "Allows airdrop account to take 1000000 tokens";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var transferTokensTx2 = token.approve(airdropAccount, new BigNumber("1000000").shift(18), {from: contractOwnerAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(transferTokensTx2, msg);
printTxData("transferTokensTx2", transferTokensTx2);
printBalances();
console.log("RESULT: ");


var transferTokensTx3 = token.transferFrom(contractOwnerAccount, airdropAccount, new BigNumber("1000000").shift(18), {from: airdropAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(transferTokensTx3, msg);
printTxData("transferTokensTx3", transferTokensTx3);
printBalances();
console.log("RESULT: ");


// var approveAndCallTest1Tx = token.approveAndCall(airdropAccount,  new BigNumber("1000000").shift(18), "Hello", {from: contractOwnerAccount, gas: 6000000, gasPrice: defaultGasPrice});
// while (txpool.status.pending > 0) {
// }
// failIfTxStatusError(approveAndCallTest1Tx, msg);
// printTxData("approveAndCallTest1Tx", approveAndCallTest1Tx);
// printBalances();
// console.log("RESULT: ");
// -----------------------------------------------------------------------------
var msg = "Transfer 2000000 tokens to exchange";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var transferTokensTx2 = token.transfer(exchangeAccount, new BigNumber("2000000").shift(18), {from: contractOwnerAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(transferTokensTx2, msg + " - transfer 1000 tokens to Exchange Account");
printTxData("transferTokensTx2", transferTokensTx2);
console.log("RESULT: ");

printBalances();


// -----------------------------------------------------------------------------
var msg = "Airdrop transfers 200 tokens to each property owner 1";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var transferTokensTx3 = token.transfer(owner1Account, new BigNumber("200").shift(18), {from: airdropAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(transferTokensTx3, msg + " - transfer 200 tokens to owner 1");
printTxData("transferTokensTx3", transferTokensTx3);
console.log("RESULT: ");

printBalances();


// -----------------------------------------------------------------------------
var msg = "Airdrop transfers 200 tokens to each property owner 2";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var transferTokensTx4 = token.transfer(owner2Account, new BigNumber("200").shift(18), {from: airdropAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(transferTokensTx4, msg + " - transfer 200 tokens to owner 1");
printTxData("transferTokensTx4", transferTokensTx4);
console.log("RESULT: ");

printBalances();


// -----------------------------------------------------------------------------
var msg = "Renter 1 buys 10000 tokens from the exchange";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var transferTokensTx5 = token.transfer(renter1Account, new BigNumber("10000").shift(18), {from: exchangeAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(transferTokensTx5, msg + " - transfer 10000 tokens to renter 1");
printTxData("transferTokensTx5", transferTokensTx5);
console.log("RESULT: ");

printBalances();


// -----------------------------------------------------------------------------
var msg = "Renter 2 buys 10000 tokens from the exchange";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");
var transferTokensTx6 = token.transfer(renter2Account, new BigNumber("10000").shift(18), {from: exchangeAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(transferTokensTx6, msg + " - transfer 10000 tokens to renter 2");
printTxData("transferTokensTx6", transferTokensTx6);
console.log("RESULT: ");

printBalances();


// // -----------------------------------------------------------------------------
// var approveAndCallTestMessage = "Test approveAndCall 123.456 tokens with 'Hello' message";
// // -----------------------------------------------------------------------------
// console.log("RESULT: --- " + approveAndCallTestMessage + " ---");
// var approveAndCallTest1Tx = token.approveAndCall(uhoodAddress,  "123456000000000000000", "Hello", {from: owner1Account, gas: 400000, gasPrice: defaultGasPrice});
// while (txpool.status.pending > 0) {
// }
// printBalances();
// failIfTxStatusError(approveAndCallTest1Tx, approveAndCallTestMessage);
// printTxData("approveToken1Tx", approveAndCallTest1Tx);
// printTokenContractDetails();
// printTestContractDetails();
// console.log("RESULT: ");

// -----------------------------------------------------------------------------
var msg = "Owner 1 deposits 100 tokens to add property 1 to the smart contract";
// -----------------------------------------------------------------------------
var propertyOwner1 = owner1Account;
var propertyLocation1 = "96/71 Victoria Street, Potts Point NSW 2011";
var propertyType = 1; // apartment
var bedrooms = 3;
var bathrooms = 2;
var garageSpaces = 1;
var comments = "city and harbour view";
var initialAvailableDate = $START_DATE;

console.log("RESULT: ----- " + msg + " -----");
// printBalances();

console.log("RESULTS: initialAvailableDate = " + initialAvailableDate);
// var hashOf = "0x" + bytes4ToHex(functionSig) + addressToHex(tokenContractAddress) + addressToHex(from) + addressToHex(to) + uint256ToHex(tokens) + uint256ToHex(fee) + uint256ToHex(nonce);
var propertyHashJS1 = web3.sha3("0x" + addressToHex(propertyOwner1) + stringToHex(propertyLocation1), {encoding: "hex"})
console.log("RESULT: propertyHashJS1 = " + propertyHashJS1);

var propertyHashSol1 = uhood.getPropertyHash(propertyOwner1, propertyLocation1);
console.log("RESULT: propertyHashSol1 = " + propertyHashSol1);

var listingTx1a = token.approve(uhoodAddress, new BigNumber("200").shift(18), {from: owner1Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx1a, "listingTx1a");

var listingTx1b = uhood.addProperty(propertyOwner1, propertyLocation1, propertyType, bedrooms, bathrooms, garageSpaces, comments, initialAvailableDate, {from: owner1Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx1b, "listingTx1b");

printBalances();

// var propertyData = uhood.getPropertyData(owner1Account, "96/71 Victoria Street, Potts Point NSW 2011")
var propertyData = uhood.getPropertyData(propertyHashJS1);
var initialAvailableDateStr = timestampToStr(propertyData[9]);

printTxData("listingTx1a", listingTx1a);
printTxData("listingTx1b", listingTx1b);
console.log("RESULT: uhood.getPropertyData = " + JSON.stringify(propertyData));
printUhoodContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 1 updates initial available date";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");

var now = Date.now();
var future = parseInt(now/1000) + (30*24*60*60);
console.log("RESULT: future = " + timestampToStr(future));

var listingTx2 = uhood.updateInitialAvailableDate(propertyHashJS1, future, {from: owner1Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx2, "listingTx2");

printBalances();

var propertyData = uhood.getPropertyData(propertyHashJS);
var initialAvailableDateStr = timestampToStr(propertyData[9]);

printTxData("listingTx2", listingTx2);
printUhoodContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 2 deposits 100 tokens to add property 2 to the smart contract";
// -----------------------------------------------------------------------------
var propertyOwner2 = owner2Account;
var propertyLocation2 = "136 Raglan Street, Mosman NSW 2088";
var propertyType = 0; // apartment
var bedrooms = 5;
var bathrooms = 3;
var garageSpaces = 2;
var comments = "Swimming Pool - Inground";
var now = Date.now();
var future = parseInt(now/1000) + (90*24*60*60);
var initialAvailableDate = future;

console.log("RESULT: ----- " + msg + " -----");
printBalances();

console.log("RESULTS: initialAvailableDate = " + initialAvailableDate);
// var hashOf = "0x" + bytes4ToHex(functionSig) + addressToHex(tokenContractAddress) + addressToHex(from) + addressToHex(to) + uint256ToHex(tokens) + uint256ToHex(fee) + uint256ToHex(nonce);
var propertyHashJS2 = web3.sha3("0x" + addressToHex(propertyOwner2) + stringToHex(propertyLocation2), {encoding: "hex"})
console.log("RESULT: propertyHashJS = " + propertyHashJS2);

var propertyHashSol2 = uhood.getPropertyHash(propertyOwner2, propertyLocation2);
console.log("RESULT: propertyHashSol = " + propertyHashSol2);

var listingTx3a = token.approve(uhoodAddress, new BigNumber("200").shift(18), {from: owner2Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx3a, "listingTx3");

var listingTx3b = uhood.addProperty(propertyOwner2, propertyLocation2, propertyType, bedrooms, bathrooms, garageSpaces, comments, initialAvailableDate, {from: owner2Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx3b, "listingTx3b");

printBalances();
printUhoodContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 1 cannot remove property 2 as he is not the owner";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");

var listingTx4a = uhood.removeProperty(propertyHashJS2, {from: owner1Account, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
passIfTxStatusError(listingTx4a, "listingTx4a");

// printBalances();
printUhoodContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var msg = "Owner 2 removes the property";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + msg + " -----");

var listingTx4b = uhood.removeProperty(propertyHashJS2, {from: owner2Account, gas: 6000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(listingTx4b, "listingTx4b");

// printBalances();
printUhoodContractDetails();
console.log("RESULT: ");


exit;














while (txpool.status.pending > 0) {
}
var results = getClubAndTokenListing();
var clubs = results[0];
var tokens = results[1];
console.log("RESULT: clubs=#" + clubs.length + " " + JSON.stringify(clubs));
console.log("RESULT: tokens=#" + tokens.length + " " + JSON.stringify(tokens));
// Can check, but the rest will not work anyway - if (bttsTokens.length == 1)
var clubAddress = clubs[0];
var tokenAddress = tokens[0];
var club = web3.eth.contract(clubAbi).at(clubAddress);
console.log("DATA: clubAddress=" + clubAddress);
var token = web3.eth.contract(tokenAbi).at(tokenAddress);
console.log("DATA: tokenAddress=" + tokenAddress);
addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
addAccount(clubAddress, "Club '" + club.name() + "'");
addClubContractAddressAndAbi(clubAddress, clubAbi);
addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
printBalances();
failIfTxStatusError(deployClubTx, deployClubMessage);
printTxData("deployClubTx", deployClubTx);
printClubFactoryContractDetails();
printTokenContractDetails();
printClubContractDetails();
console.log("RESULT: ");

exit;



// -----------------------------------------------------------------------------
var setMemberNameMessage = "Set Member Name";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + setMemberNameMessage + " -----");
var setMemberNameTx = club.setMemberName("Alice in Blockchains", {from: aliceAccount, gas: 4000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
failIfTxStatusError(setMemberNameTx, setMemberNameMessage);
printTxData("setMemberNameTx", setMemberNameTx);
printClubContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var addMemberProposal1_Message = "Add Member Proposal #1";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + addMemberProposal1_Message + " -----");
var addMemberProposal1_1Tx = club.proposeAddMember("Bob", bobAccount, {from: aliceAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(addMemberProposal1_1Tx, addMemberProposal1_Message + " - Alice addMemberProposal(ac3, 'Bob')");
printTxData("addMemberProposal1_1Tx", addMemberProposal1_1Tx);
printClubContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var addMemberProposal2_Message = "Add Member Proposal #2";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + addMemberProposal2_Message + " -----");
var addMemberProposal2_1Tx = club.proposeAddMember("Carol", carolAccount, {from: aliceAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}

getVotingStatus();
var addMemberProposal2_2Tx = club.voteNo(1, {from: aliceAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
getVotingStatus();

var addMemberProposal2_3Tx = club.voteYes(1, {from: bobAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
getVotingStatus();

var addMemberProposal2_4Tx = club.voteYes(1, {from: aliceAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
getVotingStatus();

// printBalances();
failIfTxStatusError(addMemberProposal2_1Tx, addMemberProposal2_Message + " - Alice addMemberProposal(ac4, 'Carol')");
failIfTxStatusError(addMemberProposal2_2Tx, addMemberProposal2_Message + " - Alice voteNo(1)");
failIfTxStatusError(addMemberProposal2_3Tx, addMemberProposal2_Message + " - Bob voteYes(1)");
failIfTxStatusError(addMemberProposal2_4Tx, addMemberProposal2_Message + " - Alice voteYes(1)");
printTxData("addMemberProposal2_1Tx", addMemberProposal2_1Tx);
printTxData("addMemberProposal2_2Tx", addMemberProposal2_2Tx);
printTxData("addMemberProposal2_3Tx", addMemberProposal2_3Tx);
printTxData("addMemberProposal2_4Tx", addMemberProposal2_4Tx);
printClubContractDetails();
printTokenContractDetails();
console.log("RESULT: ");

exit;

// -----------------------------------------------------------------------------
var removeMemberProposal1_Message = "Remove Member Proposal #1";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + removeMemberProposal1_Message + " -----");
var removeMemberProposal1_1Tx = club.proposeRemoveMember("Remove Bob", bobAccount, {from: carolAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var removeMemberProposal1_2Tx = club.voteYes(2, {from: aliceAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(removeMemberProposal1_1Tx, removeMemberProposal1_Message + " - Carol removeMemberProposal(ac3, 'Bob')");
failIfTxStatusError(removeMemberProposal1_2Tx, removeMemberProposal1_Message + " - Alice voteYes(2)");
printTxData("removeMemberProposal1_1Tx", removeMemberProposal1_1Tx);
printTxData("removeMemberProposal1_2Tx", removeMemberProposal1_2Tx);
printClubContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var mintTokensProposal1_Message = "Mint Tokens";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + mintTokensProposal1_Message + " -----");
var mintTokensProposal1_1Tx = club.proposeMintTokens("Mint tokens Alice", aliceAccount, new BigNumber("100000").shift(18), {from: aliceAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var mintTokensProposal1_2Tx = club.voteYes(3, {from: bobAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var mintTokensProposal1_3Tx = club.voteYes(3, {from: carolAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(mintTokensProposal1_1Tx, mintTokensProposal1_Message + " - Alice proposeMintTokens(Alice, 100000 tokens)");
passIfTxStatusError(mintTokensProposal1_2Tx, mintTokensProposal1_Message + " - Bob voteYes(3) - Expecting failure as not a member");
failIfTxStatusError(mintTokensProposal1_3Tx, mintTokensProposal1_Message + " - Carol voteYes(3)");
printTxData("mintTokensProposal1_1Tx", mintTokensProposal1_1Tx);
printTxData("mintTokensProposal1_2Tx", mintTokensProposal1_2Tx);
printTxData("mintTokensProposal1_3Tx", mintTokensProposal1_3Tx);
printClubContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var burnTokensProposal1_Message = "Burn Tokens";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + burnTokensProposal1_Message + " -----");
var burnTokensProposal1_1Tx = club.proposeBurnTokens("Burn tokens Alice", aliceAccount, new BigNumber("50000").shift(18), {from: aliceAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var burnTokensProposal1_2Tx = club.voteYes(4, {from: bobAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var burnTokensProposal1_3Tx = club.voteYes(4, {from: carolAccount, gas: 500000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(burnTokensProposal1_1Tx, burnTokensProposal1_Message + " - Alice proposeBurnTokens(Alice, 100000 tokens)");
passIfTxStatusError(burnTokensProposal1_2Tx, burnTokensProposal1_Message + " - Bob voteYes(4) - Expecting failure as not a member");
failIfTxStatusError(burnTokensProposal1_3Tx, burnTokensProposal1_Message + " - Carol voteYes(4)");
printTxData("burnTokensProposal1_1Tx", burnTokensProposal1_1Tx);
printTxData("burnTokensProposal1_2Tx", burnTokensProposal1_2Tx);
printTxData("burnTokensProposal1_3Tx", burnTokensProposal1_3Tx);
printClubContractDetails();
printTokenContractDetails();
console.log("RESULT: ");



exit;



// -----------------------------------------------------------------------------
var deployLibDAOMessage = "Deploy DAO Library";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + deployLibDAOMessage + " -----");
var membersLibContract = web3.eth.contract(membersLibAbi);
// console.log(JSON.stringify(membersLibContract));
var membersLibTx = null;
var membersLibAddress = null;
var membersLibBTTS = membersLibContract.new({from: contractOwnerAccount, data: membersLibBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        membersLibTx = contract.transactionHash;
      } else {
        membersLibAddress = contract.address;
        addAccount(membersLibAddress, "DAO Library - Members");
        console.log("DATA: membersLibAddress=" + membersLibAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(membersLibTx, deployLibDAOMessage);
printTxData("membersLibTx", membersLibTx);
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployDAOMessage = "Deploy DAO Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + deployDAOMessage + " -----");
var newDAOBin = daoBin.replace(/__DecentralisedFutureFundDAO\.sol\:Membe__/g, membersLibAddress.substring(2, 42));
var daoContract = web3.eth.contract(daoAbi);
var daoTx = null;
var daoAddress = null;
var dao = daoContract.new({from: contractOwnerAccount, data: newDAOBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        daoTx = contract.transactionHash;
      } else {
        daoAddress = contract.address;
        addAccount(daoAddress, "DFF DAO");
        addDAOContractAddressAndAbi(daoAddress, daoAbi);
        console.log("DATA: daoAddress=" + daoAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(daoTx, deployDAOMessage);
printTxData("daoAddress=" + daoAddress, daoTx);
printDAOContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var initSetBTTSToken_Message = "Initialisation - Set BTTS Token";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + initSetBTTSToken_Message + " -----");
var initSetBTTSToken_1Tx = dao.initSetBTTSToken(tokenAddress, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var initSetBTTSToken_2Tx = token.setMinter(daoAddress, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var initSetBTTSToken_3Tx = token.transferOwnershipImmediately(daoAddress, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var initSetBTTSToken_4Tx = eth.sendTransaction({from: contractOwnerAccount, to: daoAddress, value: web3.toWei("100", "ether"), gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(initSetBTTSToken_1Tx, initSetBTTSToken_Message + " - dao.initSetBTTSToken(bttsToken)");
failIfTxStatusError(initSetBTTSToken_2Tx, initSetBTTSToken_Message + " - token.setMinter(dao)");
failIfTxStatusError(initSetBTTSToken_3Tx, initSetBTTSToken_Message + " - token.transferOwnershipImmediately(dao)");
failIfTxStatusError(initSetBTTSToken_4Tx, initSetBTTSToken_Message + " - send 100 ETH to dao");
printTxData("initSetBTTSToken_1Tx", initSetBTTSToken_1Tx);
printTxData("initSetBTTSToken_2Tx", initSetBTTSToken_2Tx);
printTxData("initSetBTTSToken_3Tx", initSetBTTSToken_3Tx);
printTxData("initSetBTTSToken_4Tx", initSetBTTSToken_4Tx);
printDAOContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var initAddMembers_Message = "Initialisation - Add Members";
var name1 = "0x" + web3.padLeft(web3.toHex("two").substring(2), 64);
var name2 = "0x" + web3.padLeft(web3.toHex("three").substring(2), 64);
var name3 = "0x" + web3.padLeft(web3.toHex("four").substring(2), 64);
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + initAddMembers_Message + " -----");
var initAddMembers_1Tx = dao.initAddMember(account2, name1, true, {from: contractOwnerAccount, gas: 300000, gasPrice: defaultGasPrice});
var initAddMembers_2Tx = dao.initAddMember(account3, name2, true, {from: contractOwnerAccount, gas: 300000, gasPrice: defaultGasPrice});
var initAddMembers_3Tx = dao.initAddMember(account4, name3, false, {from: contractOwnerAccount, gas: 300000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(initAddMembers_1Tx, initAddMembers_Message + " - dao.initAddMember(account2, 'two', true)");
failIfTxStatusError(initAddMembers_2Tx, initAddMembers_Message + " - dao.initAddMember(account3, 'three', true)");
failIfTxStatusError(initAddMembers_3Tx, initAddMembers_Message + " - dao.initAddMember(account4, 'four', false)");
printTxData("initAddMembers_1Tx", initAddMembers_1Tx);
printTxData("initAddMembers_2Tx", initAddMembers_2Tx);
printTxData("initAddMembers_3Tx", initAddMembers_3Tx);
printDAOContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


if (false) {
// -----------------------------------------------------------------------------
var initRemoveMembers_Message = "Initialisation - Remove Members";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + initRemoveMembers_Message + " -----");
var initRemoveMembers_1Tx = dao.initRemoveMember(account2, {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
var initRemoveMembers_2Tx = dao.initRemoveMember(account3, {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
var initRemoveMembers_3Tx = dao.initRemoveMember(account4, {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(initRemoveMembers_1Tx, initRemoveMembers_Message + " - dao.initRemoveMember(account2)");
failIfTxStatusError(initRemoveMembers_2Tx, initRemoveMembers_Message + " - dao.initRemoveMember(account3)");
failIfTxStatusError(initRemoveMembers_3Tx, initRemoveMembers_Message + " - dao.initRemoveMember(account4)");
printTxData("initRemoveMembers_1Tx", initRemoveMembers_1Tx);
printTxData("initRemoveMembers_2Tx", initRemoveMembers_2Tx);
printTxData("initRemoveMembers_3Tx", initRemoveMembers_3Tx);
printDAOContractDetails();
printTokenContractDetails();
console.log("RESULT: ");
}


// -----------------------------------------------------------------------------
var initialisationComplete_Message = "Initialisation - Complete";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + initialisationComplete_Message + " -----");
var initialisationComplete_1Tx = dao.initialisationComplete({from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(initialisationComplete_1Tx, initialisationComplete_Message + " - dao.initialisationComplete()");
printTxData("initialisationComplete_1Tx", initialisationComplete_1Tx);
printDAOContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var etherPaymentProposal_Message = "Ether Payment Proposal";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + etherPaymentProposal_Message + " -----");
var etherPaymentProposal_1Tx = dao.proposeEtherPayment("payment to ac2", account2, new BigNumber("12").shift(18), {from: account2, gas: 300000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(etherPaymentProposal_1Tx, etherPaymentProposal_Message + " - dao.proposeEtherPayment(ac2, 12 ETH)");
printTxData("etherPaymentProposal_1Tx", etherPaymentProposal_1Tx);
printDAOContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var vote1_Message = "Vote - Ether Payment Proposal";
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + vote1_Message + " -----");
var vote1_1Tx = dao.voteYes(0, {from: account3, gas: 300000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(vote1_1Tx, vote1_Message + " - ac3 dao.voteYes(proposal 0)");
printTxData("vote1_1Tx", vote1_1Tx);
printDAOContractDetails();
printTokenContractDetails();
console.log("RESULT: ");



EOF
#grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
#cat $DEPLOYMENTDATA
#grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
#cat $TEST1RESULTS
