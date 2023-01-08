// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./userDetails.sol";
import "./bankDetails.sol";

//will be using IPFS for file storage and uploads

//Make userDetails and bankDetails too
//When making calls to other contracts, msg.sender is set to that contract caller!
//Maybe you can also mix msg.sender (the caller, can be any)
// with tx.origin (original caller, not the contract caller)
//What I needed is actually called a delegateCall! https://solidity-by-example.org/delegatecall/
//Ex:
// (bool success, bytes memory data) = _contract.delegatecall(
//             abi.encodeWithSignature("setVars(uint256)", _num)
//         );

//Wait, you can just use the creator address as the requirements for msg.sender in userDetails and bankDetails!
// No need to use something like delegatecall which is more complicated.
// https://medium.com/coinmonks/delegatecall-calling-another-contract-function-in-solidity-b579f804178c
//Why? Because the creator address is the only one who can call the functions in userDetails and bankDetails
// and in creator contract (KYC contract), it will check for the user/bank msg.sender address.
//Try to solve the security access problems in the view functions.
//Well, maybe everything of msg.sender,
// must come from the contract creator address which is the KYC contract address.

//Non-existent external function calls of a non-deployed contract would just result in a revert,
// returning all remaining gas to the original caller address (tx.origin).
//Hence, accessing a non-existent userDetails or bankDetails contract functions
// would just revert the transaction.

contract KYC {
  address private owner;
  address[] private users;
  address[] private banks;
  mapping(address => uint) private entityCount;
  mapping(address => userDetails) private registeredUser;
  mapping(address => bankDetails) private registeredBank;
  kycBanks private allBanks;

  constructor() {
    owner = msg.sender;
  }

  struct userBankAccountDetails {
    address userPublicAddress;
    userDetails.userBankAccountDetails[] userBankAccountDetailsArr;
  }

  struct kycBanks {
    address[] bankAddress;
    string[] bankName;
  }

  modifier userExists(address user) {
    require(entityCount[user] > 0, "User does not exist.");
    _;
  }

  function getOwner() public view returns (address) {
    return owner;
  }

  function getEntityCount(address user) internal view returns (uint) {
    return entityCount[user];
  }

  function getOwnEntityCount(address user) public view userExists(user) returns (uint) {
    require(msg.sender == user, "Only user.");
    return entityCount[user];
  }

  function getUsers() public view returns (address[] memory) {
    return users;
  }

  function getBanks() view public returns (kycBanks memory) {
    return allBanks;
  }

  function modUsers(address user, uint8 userType) internal {
    require(entityCount[user] == 0, "User exists.");
    require(userType == 1 || userType == 2, "Invalid mode value");
    if (userType == 1) users.push(user);
    else if (userType == 2) banks.push(user);
    entityCount[user] = users.length + banks.length;
  }

  function addUsers(string memory name, string memory homeAddress, string memory dateOfBirth) public {
    require(bytes(name).length > 0, "Name is required.");
    require(bytes(homeAddress).length > 0, "Home address is required.");
    require(bytes(dateOfBirth).length > 0, "Date of birth is required.");
    modUsers(msg.sender, 1);
    registeredUser[msg.sender] = new userDetails(msg.sender, name, homeAddress, dateOfBirth);
  }

  function addBanks(string memory name) public {
    require(bytes(name).length > 0, "Name is required.");
    modUsers(msg.sender, 2);
    registeredBank[msg.sender] = new bankDetails(msg.sender, name);
    allBanks.bankAddress.push(msg.sender);
    allBanks.bankName.push(name);
  }

  function getPermissionedUserDetails(
    address user
  ) public view userExists(user) returns (address, string memory, string memory, string memory) {
    return registeredUser[user].getUserDetails(msg.sender, getEntityCount(msg.sender));
  }

  //viewSentKYC
  //Should check if it is the user owner OR a registered bank for user
  //Banks should not be able to directly access this function.
  // Uses crossViewKYC function instead.
  function getDetailedBankAccounts(
    address user
  ) public view userExists(user) returns (userDetails.userBankAccountDetails[] memory) {
    return registeredUser[user].getDetailedBankAccounts(msg.sender, 0);
  }

  //Want to be able to send change notifications to related parties here
  function changeUserDetails(
    string memory name,
    string memory homeAddress,
    string memory dateOfBirth
  ) public userExists(msg.sender) {
    require(
      bytes(name).length > 0 || bytes(homeAddress).length > 0 || bytes(dateOfBirth).length > 0,
      "No data provided to changeUserDetails"
    );
    registeredUser[msg.sender].changeUserDetails(name, homeAddress, dateOfBirth);
  }

  function sendViewPermission(address bankAddress, uint mode) public userExists(msg.sender) {
    require(entityCount[bankAddress] > 0, "Bank does not exist.");
    require(mode == 1 || mode == 2, "Invalid mode value.");
    string memory bankName = registeredBank[bankAddress].getBankName(bankAddress);
    if (mode == 1) {
      //sends user unique proof view access
      registeredUser[msg.sender].sendUniqueProofAccess(bankAddress, getEntityCount(bankAddress), bankName);
      registeredBank[bankAddress].receiveKYCInfo(bankAddress, msg.sender, getEntityCount(msg.sender), 1);
    } else if (mode == 2) {
      //sends user KYC info view access
      registeredUser[msg.sender].addKYCViewPermission(bankAddress, getEntityCount(bankAddress), bankName);
      registeredBank[bankAddress].receiveKYCInfo(bankAddress, msg.sender, getEntityCount(msg.sender), 2);
    }
  }

  function setUserUniqueProofApproval(address userAddress, bool uniqueProofApproval) public userExists(msg.sender) {
    require(entityCount[userAddress] > 0, "No user found.");
    registeredUser[userAddress].setUniqueProofApproval(msg.sender, uniqueProofApproval);
    registeredBank[msg.sender].setUniqueProofApproval(msg.sender, userAddress, uniqueProofApproval);
  }

  function setUserKYCApprovals(address userAddress, bool KYCApproval) public userExists(msg.sender) {
    require(entityCount[userAddress] > 0, "No user found.");
    registeredUser[userAddress].setKYCApproval(msg.sender, KYCApproval);
    registeredBank[msg.sender].setUserKYCApproval(msg.sender, userAddress, KYCApproval);
  }

  function setUserUniqueProof(address userAddress, string memory proof) public userExists(userAddress) {
    registeredUser[userAddress].setUniqueProof(msg.sender, proof);
  }

  function getUniqueProof(address userAddres) public view userExists(userAddres) returns (string memory) {
    return registeredUser[userAddres].getUniqueProof(msg.sender);
  }

  function viewAllBankUserInfo(
    address bankAddress
  ) public view userExists(msg.sender) returns (bankDetails.userAccountDetails[] memory) {
    require(entityCount[bankAddress] > 0, "No bank found.");
    return registeredBank[bankAddress].viewAllUserInfo(msg.sender);
  }

  function crossViewKYC(
    address bankAddress
  ) public view userExists(bankAddress) returns (userBankAccountDetails[] memory) {
    require(msg.sender == bankAddress, "Only bank.");
    address[] memory allBankUsers = registeredBank[msg.sender].getAllUserAccounts(msg.sender);
    uint bankID = getEntityCount(msg.sender);
    userBankAccountDetails[] memory allBankUserDetails = new userBankAccountDetails[](allBankUsers.length);
    for (uint i = 0; i < allBankUsers.length; i++) {
      address user = allBankUsers[i];
      userDetails.userBankAccountDetails[] memory details = registeredUser[user].getDetailedBankAccounts(
        msg.sender,
        bankID
      );
      allBankUserDetails[i] = userBankAccountDetails(user, details);
    }
    return allBankUserDetails;
  }
}
