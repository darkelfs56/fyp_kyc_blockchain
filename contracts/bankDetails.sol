// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./KYC.sol";

contract bankDetails {
  address private creator;
  address private bankPublicAddress;
  string private bankName;
  mapping(uint => address) private userAccounts;
  mapping(address => uint) private userIndex;
  mapping(address => bool) private KYCApprovedUsers;
  mapping(address => bool) private uniqueProofApprovedUsers;
  userAccountDetails[] private userAccountDetailsArr;
  address[] arr_userAccounts;

  struct userAccountDetails {
    address userPublicAddress;
    bool sentUniqueProof;
    bool uniqueProofApproval;
    bool sentKYCAccess;
    bool userKYCApproval;
  }

  constructor(address _bankPublicAddress, string memory _bankName) {
    creator = msg.sender;
    bankPublicAddress = _bankPublicAddress;
    bankName = _bankName;
  }

  modifier onlyCreator() {
    require(msg.sender == creator, "Only contract creator can call this function.");
    _;
  }

  function getBankName(address requester) public view onlyCreator returns (string memory) {
    require(requester == bankPublicAddress, "Only bank can call this function.");
    return bankName;
  }

  function getBankDetails(address requester) public view onlyCreator returns (string memory, address) {
    require(requester == bankPublicAddress, "Only bank can call this function.");
    return (bankName, bankPublicAddress);
  }

  function getAllUserAccounts(address requester) public view onlyCreator returns (address[] memory) {
    require(requester == bankPublicAddress, "Only bank can call this function");
    return arr_userAccounts;
  }

  function setUniqueProofApproval(address requester, address user, bool status) public onlyCreator {
    require(requester == bankPublicAddress, "Only bank can call this function.");
    uniqueProofApprovedUsers[user] = status;
    userAccountDetailsArr[userIndex[user]].uniqueProofApproval = status;
  }

  function setUserKYCApproval(address requester, address userAddress, bool status) public onlyCreator {
    require(requester == bankPublicAddress, "Only bank can call this function.");
    KYCApprovedUsers[userAddress] = status;
    userAccountDetailsArr[userIndex[userAddress]].userKYCApproval = status;
  }

  function sentUniqueProof(address userAddress, uint userId) internal {
    if (userAccounts[userId] == address(0)) {
      userAccounts[userId] = userAddress;
      userIndex[userAddress] = arr_userAccounts.length;
      arr_userAccounts.push(userAddress);
      userAccountDetailsArr.push(userAccountDetails(userAddress, true, false, false, false));
    } else {
      userAccountDetailsArr[userIndex[userAddress]].sentUniqueProof = true;
    }
  }

  function sentKYC(address userAddress, uint userId) internal {
    if (userAccounts[userId] == address(0)) {
      userAccounts[userId] = userAddress;
      userIndex[userAddress] = arr_userAccounts.length;
      arr_userAccounts.push(userAddress);
      userAccountDetailsArr.push(userAccountDetails(userAddress, false, false, true, false));
    } else {
      userAccountDetailsArr[userIndex[userAddress]].sentKYCAccess = true;
    }
  }

  //Would not execute more than once for a user, since a require statement
  // is present, to detect if the bank already has KYC access or sent Unique Proof.
  function receiveKYCInfo(address requester, address userAddress, uint userId, uint mode) public onlyCreator {
    require(requester == bankPublicAddress, "Only bank can call this function.");
    if (mode == 1) sentUniqueProof(userAddress, userId);
    else if (mode == 2) sentKYC(userAddress, userId);
  }

  function viewAllUserInfo(address requester) public view onlyCreator returns (userAccountDetails[] memory) {
    require(requester == bankPublicAddress, "Only bank can call this function.");
    return userAccountDetailsArr;
  }
}
