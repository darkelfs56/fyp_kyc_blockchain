// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./KYC.sol";
import "./userDetails.sol";

contract KYCUser {
  address private creator;
  userDetails private userDummy;

  constructor() {
    creator = msg.sender;
  }

  modifier onlyCreator() {
    require(msg.sender == creator, "Only contract creator can call this function.");
    _;
  }
}
