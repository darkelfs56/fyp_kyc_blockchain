// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

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

contract KYC {
  address[] private users;
  mapping(address => uint) private userCount;
  mapping(uint => address) private userMapping;
  address private owner;
  mapping(address => userDetails) private registeredUser;
  mapping(address => bankDetails) private registeredBank;

  struct userKYCDetails {
    address userPublicAddress;
    string[] bankNames;
    bool[] KYCStatus;
  }

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function.");
    _;
  }

  function getOwner() public view returns (address) {
    return owner;
  }

  function getUserCount(address user) internal view returns (uint) {
    return userCount[user];
  }

  function getOwnUserCount(address user) public view returns (uint) {
    require(userCount[user] > 0, "User does not exist.");
    require(msg.sender == user, "Only user can call this function.");
    return userCount[user];
  }

  function getUsers() public view returns (address[] memory) {
    return users;
  }

  function addUsers(
    string memory name,
    string memory homeAddress,
    string memory dateOfBirth
  ) public {
    require(userCount[msg.sender] == 0, "User already exists.");
    users.push(msg.sender);
    userCount[msg.sender] = users.length;
    userMapping[users.length] = msg.sender;
    registeredUser[msg.sender] = new userDetails(msg.sender, name, homeAddress, dateOfBirth);
  }

  function addBanks(string memory name) public {
    require(userCount[msg.sender] == 0, "User already exists.");
    users.push(msg.sender);
    userCount[msg.sender] = users.length;
    userMapping[users.length] = msg.sender;
    registeredBank[msg.sender] = new bankDetails(msg.sender, name);
  }

  function getUserDetails(
    address user
  ) public view returns (address, string memory, string memory, string memory) {
    require(userCount[user] > 0, "User does not exist.");
    require(msg.sender == user, "Only user can call this function.");
    return registeredUser[user].getUserDetails(msg.sender);
  }

  function getPermissionedUserDetails(
    address user
  ) public view returns (address, string memory, string memory, string memory) {
    require(userCount[user] > 0, "User does not exist.");
    return registeredUser[user].getPermissionedUserDetails(getUserCount(msg.sender), msg.sender);
  }

  function sendKYCViewPermission(address bankAddress) public {
    require(userCount[msg.sender] > 0, "User does not exist.");
    require(userCount[bankAddress] > 0, "Bank does not exist.");
    require(
      registeredUser[msg.sender].getBankAccount(getUserCount(bankAddress)) == address(0),
      "KYC view permission already sent."
    );
    registeredUser[msg.sender].addKYCViewPermission(bankAddress, getUserCount(bankAddress));
  }

  //Want to be able to send change notifications to related parties here
  function changeUserDetails(
    string memory name,
    string memory homeAddress,
    string memory dateOfBirth
  ) public {
    require(userCount[msg.sender] > 0, "User does not exist.");
    require(msg.sender == userMapping[userCount[msg.sender]], "Only user can call this function.");
    registeredUser[msg.sender].changeUserDetails(name, homeAddress, dateOfBirth);
  }

  function getBankAccount(address bankAddress) public view returns (address) {
    require(userCount[msg.sender] > 0, "User does not exist.");
    require(userCount[bankAddress] > 0, "Bank does not exist.");
    return registeredUser[msg.sender].getBankAccount(getUserCount(bankAddress));
  }

  function getAllBankAccounts(address user) public view returns (address[] memory) {
    require(userCount[msg.sender] > 0, "User does not exist.");
    require(msg.sender == userMapping[userCount[msg.sender]], "Only user can call this function.");
    return registeredUser[msg.sender].getAllBankAccounts(user);
  }

  //Should only bank be able to call this?
  //How to retrieve bankDetails for users then?
  //Maybe use the getAllBankAccounts function?
  function getBankDetails(address bankAddress) public view returns (string memory, address) {
    require(userCount[msg.sender] > 0, "User does not exist.");
    require(userCount[bankAddress] > 0, "Bank does not exist.");
    return registeredBank[bankAddress].getBankDetails(msg.sender);
  }

  function getAllUserBankDetails(
    address user
  ) public view returns (string[] memory, address[] memory) {
    require(userCount[msg.sender] > 0, "User does not exist.");
    require(msg.sender == userMapping[userCount[msg.sender]], "Only user can call this function.");
    address[] memory allBankAccounts = getAllBankAccounts(user);
    string[] memory allBankNames = new string[](allBankAccounts.length);
    address[] memory allBankPublicAddress = new address[](allBankAccounts.length);
    for (uint i = 0; i < allBankAccounts.length; i++) {
      (allBankNames[i], allBankPublicAddress[i]) = registeredBank[allBankAccounts[i]]
        .getBankDetails(allBankAccounts[i]);
    }
    return (allBankNames, allBankPublicAddress);
  }

  //Need to implement a function that enables cross-view of KYCs approved between banks
  function getCrossViewKYCs(address bankAddress) public view returns (userKYCDetails[] memory) {
    require(userCount[msg.sender] > 0, "User does not exist.");
    require(userCount[bankAddress] > 0, "Bank does not exist.");
    require(msg.sender == bankAddress, "Only bank can call this function.");
    address[] memory allUserAccounts = registeredBank[msg.sender].getAllUserAccounts(msg.sender);
    userKYCDetails[] memory allUserKYCDetails = new userKYCDetails[](allUserAccounts.length);
    for (uint i = 0; i < allUserAccounts.length; i++) {
      address[] memory allBankAddress;
      bool[] memory allKYCStatus;
      string[] memory allBankNames;
      (allBankAddress, allKYCStatus) = registeredUser[allUserAccounts[i]].getAllBanksKYCApprovals(
        allUserAccounts[i]
      );
      for (uint j = 0; j < allBankAddress.length; j++) {
        allBankNames[j] = registeredBank[allBankAddress[j]].getBankName(allBankAddress[j]);
      }
      allUserKYCDetails[i] = userKYCDetails(allUserAccounts[i], allBankNames, allKYCStatus);
    }
    return allUserKYCDetails;
  }

  function setUserKYCApprovals(address userAddress, bool status) public {
    require(userCount[msg.sender] > 0, "User requester does not exist.");
    require(userCount[userAddress] > 0, "User searched does not exist.");
    registeredBank[msg.sender].setUserKYCApproval(msg.sender, userAddress, status);
  }
}

contract userDetails {
  address private creator;
  address private userPublicAddress;
  string private name;
  string private homeAddress;
  string private dateOfBirth;
  mapping(uint => address) private bankAccounts;
  mapping(address => bool) private KYCApprovedBanks;
  address[] arr_bankAccounts;

  constructor(
    address _userPublicAddress,
    string memory _name,
    string memory _homeAddress,
    string memory _dateOfBirth
  ) {
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

  function getAllBanksKYCApprovals(
    address requester
  ) public view onlyCreator returns (address[] memory, bool[] memory) {
    require(requester == userPublicAddress, "Only user can call this function.");
    address[] memory allBanks = new address[](arr_bankAccounts.length);
    bool[] memory allKYCApprovals = new bool[](arr_bankAccounts.length);
    for (uint i = 0; i < arr_bankAccounts.length; i++) {
      allBanks[i] = arr_bankAccounts[i];
      allKYCApprovals[i] = KYCApprovedBanks[arr_bankAccounts[i]];
    }
    return (allBanks, allKYCApprovals);
  }

  function getUserDetails(
    address requester
  ) public view onlyCreator returns (address, string memory, string memory, string memory) {
    require(requester == userPublicAddress, "Only user can call this function.");
    return (userPublicAddress, name, homeAddress, dateOfBirth);
  }

  function getPermissionedUserDetails(
    uint bankId,
    address bankAddress
  ) public view onlyCreator returns (address, string memory, string memory, string memory) {
    require(
      bankAccounts[bankId] != address(0),
      "Bank does not exist/hasn't been added/hasn't been sent the KYC."
    );
    require(bankAccounts[bankId] == bankAddress, "Only bank can call this function.");
    return (userPublicAddress, name, homeAddress, dateOfBirth);
  }

  function changeUserDetails(
    string memory _name,
    string memory _homeAddress,
    string memory _dateOfBirth
  ) public onlyCreator {
    name = _name;
    homeAddress = _homeAddress;
    dateOfBirth = _dateOfBirth;
  }

  function addKYCViewPermission(address bankAddress, uint bankId) public onlyCreator {
    //no need to check if already sent KYC view permission to a bank,
    //had alaready checked it at KYC contract sendKYC function.
    bankAccounts[bankId] = bankAddress;
  }

  function getBankAccount(uint bankId) public view onlyCreator returns (address) {
    return (bankAccounts[bankId]);
  }

  function getAllBankAccounts(
    address requester
  ) public view onlyCreator returns (address[] memory) {
    require(requester == userPublicAddress, "Mismatch of user owner address.");
    return arr_bankAccounts;
  }
}

contract bankDetails {
  address private creator;
  address private bankPublicAddress;
  string private bankName;
  mapping(uint => address) private userAccounts;
  mapping(address => bool) private KYCApprovedUsers;
  address[] arr_userAccounts;

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

  function getBankDetails(
    address requester
  ) public view onlyCreator returns (string memory, address) {
    require(requester == bankPublicAddress, "Only bank can call this function.");
    return (bankName, bankPublicAddress);
  }

  function getAllUserAccounts(
    address requester
  ) public view onlyCreator returns (address[] memory) {
    require(requester == bankPublicAddress, "Mismatch of bank owner address.");
    return arr_userAccounts;
  }

  function getAllUsersKYCStatus(
    address requester
  ) public view onlyCreator returns (address[] memory, bool[] memory) {
    require(requester == bankPublicAddress, "Only bank can call this function.");
    address[] memory allUsers = new address[](arr_userAccounts.length);
    bool[] memory allKYCStatus = new bool[](arr_userAccounts.length);
    for (uint i = 0; i < arr_userAccounts.length; i++) {
      allUsers[i] = arr_userAccounts[i];
      allKYCStatus[i] = KYCApprovedUsers[arr_userAccounts[i]];
    }
    return (allUsers, allKYCStatus);
  }

  function setUserKYCApproval(
    address requester,
    address userAddress,
    bool status
  ) public onlyCreator {
    require(requester == bankPublicAddress, "Only bank can call this function.");
    KYCApprovedUsers[userAddress] = status;
  }
}
