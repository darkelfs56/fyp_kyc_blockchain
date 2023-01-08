// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./KYC.sol";

contract userDetails {
  address private creator;
  string private uniqueProof;
  address private userPublicAddress;
  string private name;
  string private homeAddress;
  string private dateOfBirth;
  mapping(uint => address) private bankAccounts;
  mapping(address => bool) private bankHaveKYCAccess;
  mapping(address => bool) private bankHaveUniqueProof;
  address[] private arr_bankAccounts; //just store all bankAddresses
  mapping(address => uint) private bankIndex; //To access the index in userBankAccountDetails
  userBankAccountDetails[] private userBankAccountDetailsArr; //To store all bank details of a user

  struct userBankAccountDetails {
    address bankPublicAddress;
    string bankName;
    bool sentUniqueProof;
    bool uniqueProofApproval;
    bool sentKYCAccess;
    bool KYCStatus;
  }

  constructor(address _userPublicAddress, string memory _name, string memory _homeAddress, string memory _dateOfBirth) {
    creator = msg.sender;
    userPublicAddress = _userPublicAddress;
    name = _name;
    homeAddress = _homeAddress;
    dateOfBirth = _dateOfBirth;
  }

  modifier onlyCreator() {
    require(msg.sender == creator, "Only creator can call this function.");
    _;
  }

  function getUniqueProof(address requester) public view onlyCreator returns (string memory) {
    require(requester == userPublicAddress || bankHaveUniqueProof[requester], "User is not authorized to view.");
    require(bytes(uniqueProof).length > 0, "Unique proof not set yet.");
    return uniqueProof;
  }

  function getUserDetails(
    address requester,
    uint bankID
  ) public view onlyCreator returns (address, string memory, string memory, string memory) {
    require(requester == userPublicAddress || bankAccounts[bankID] != address(0), "User is not authorized to view.");
    return (userPublicAddress, name, homeAddress, dateOfBirth);
  }

  //Should check if it is the user owner OR a registered bank for user
  function getDetailedBankAccounts(
    address requester,
    uint bankID
  ) public view onlyCreator returns (userBankAccountDetails[] memory) {
    require(requester == userPublicAddress || bankAccounts[bankID] != address(0), "User is not authorized to view.");
    return userBankAccountDetailsArr;
  }

  function changeUserDetails(
    string memory _name,
    string memory _homeAddress,
    string memory _dateOfBirth
  ) public onlyCreator {
    if(bytes(_name).length > 0) {name = _name;}
    if(bytes(_homeAddress).length > 0) {homeAddress = _homeAddress;}
    if(bytes(_dateOfBirth).length > 0) {dateOfBirth = _dateOfBirth;}
  }

  function addKYCViewPermission(address bankAddress, uint bankId, string memory bankName) public onlyCreator {
    // require(bankAccounts[bankId] == address(0), "KYC view permission already sent.");
    require(bankHaveKYCAccess[bankAddress] == false, "KYC view permission already sent.");
    bankHaveKYCAccess[bankAddress] = true;
    if (bankAccounts[bankId] == address(0)) {
      bankAccounts[bankId] = bankAddress;
      bankIndex[bankAddress] = arr_bankAccounts.length;
      arr_bankAccounts.push(bankAddress);
      userBankAccountDetailsArr.push(userBankAccountDetails(bankAddress, bankName, false, false, true, false));
    } else if (bankAccounts[bankId] != address(0)) {
      userBankAccountDetailsArr[bankIndex[bankAddress]].sentKYCAccess = true;
    }
  }

  function sendUniqueProofAccess(address bankAddress, uint bankId, string memory bankName) public onlyCreator {
    require(bankHaveUniqueProof[bankAddress] == false, "Bank already have access.");
    require(bytes(uniqueProof).length > 0, "Unique proof not set yet.");
    bankHaveUniqueProof[bankAddress] = true;
    if (bankAccounts[bankId] == address(0)) {
      bankAccounts[bankId] = bankAddress;
      bankIndex[bankAddress] = arr_bankAccounts.length;
      arr_bankAccounts.push(bankAddress);
      userBankAccountDetailsArr.push(userBankAccountDetails(bankAddress, bankName, true, false, false, false));
    } else if (bankAccounts[bankId] != address(0)) {
      userBankAccountDetailsArr[bankIndex[bankAddress]].sentUniqueProof = true;
    }
  }

  function setKYCApproval(address bankAddress, bool status) public onlyCreator {
    require(bankHaveKYCAccess[bankAddress] == true, "Bank does not have KYC access.");
    userBankAccountDetailsArr[bankIndex[bankAddress]].KYCStatus = status;
  }

  function setUniqueProofApproval(address bankAddress, bool status) public onlyCreator {
    require(bankHaveUniqueProof[bankAddress] == true, "Bank does not have unique proof access.");
    userBankAccountDetailsArr[bankIndex[bankAddress]].uniqueProofApproval = status;
  }

  function setUniqueProof(address bankAddress, string memory _uniqueProof) public onlyCreator {
    require(bytes(uniqueProof).length == 0, "Unique proof has already been set.");
    require(bankHaveKYCAccess[bankAddress] == true, "Bank does not have KYC access.");
    require(userBankAccountDetailsArr[bankIndex[bankAddress]].KYCStatus == true, "Bank have not approved user's KYC.");
    uniqueProof = _uniqueProof;
  }
}
