// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "./KYC.sol";

// contract userDetails {
//   address private userPublicAddress;
//   string private name;
//   string private homeAddress;
//   string private dateOfBirth;
//   mapping(uint => address) private bankAccounts;

//   constructor(
//     address _userPublicAddress,
//     string memory _name,
//     string memory _homeAddress,
//     string memory _dateOfBirth
//   ) {
//     userPublicAddress = _userPublicAddress;
//     name = _name;
//     homeAddress = _homeAddress;
//     dateOfBirth = _dateOfBirth;
//   }

//   modifier onlyUser() {
//     require(msg.sender == userPublicAddress, "Only user can call this function.");
//     _;
//   }

//   function getUserDetails(address requester)
//     public
//     view
//     returns (
//       address,
//       string memory,
//       string memory,
//       string memory
//     )
//   {
//     require(requester == userPublicAddress, "Only user can call this function.");
//     return (userPublicAddress, name, homeAddress, dateOfBirth);
//   }

//   function getPermissionedUserDetails(uint bankId)
//     public
//     view
//     returns (
//       address,
//       string memory,
//       string memory,
//       string memory
//     )
//   {
//     require(
//       bankAccounts[bankId] == msg.sender,
//       "Only permissioned bank can call this function."
//     );
//     return (userPublicAddress, name, homeAddress, dateOfBirth);
//   }

//   function sendKYC(address bankAddress) public onlyUser {
//     bankAccounts[KYC.getOwnUserCount(bankAddress)] = bankAddress;
//   }
// }