// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzepplin/contracts/access/Ownable.sol";

contract Fish is Ownable {
    uint256 public value;

    function store(uint256 _newValue) public onlyOwner {
        value = _newValue;
    }
}
