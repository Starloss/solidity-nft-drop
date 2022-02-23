/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

contract ERC1155Token is ERC1155 {
    constructor() ERC1155("") {}
}