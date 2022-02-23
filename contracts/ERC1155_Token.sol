/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ERC1155Token is ERC1155, Ownable {
    /// VARIABLES
    /**
     *  @notice String used for store name and symbol of the token
     */
    string public name;
    string public symbol;

    /**
     *  @notice Mapping used for store the URI of every token
     */
    mapping(uint => string) public tokenURI;

    /// FUNCTIONS
    /**
     *  @notice Constructor function that initialice the name and symbol of the token
     */
    constructor() ERC1155("") {
        name = "EyesItems";
        symbol = "EYES";
    }

    /**
     *  @notice Function that allows the owner to mint one type of token at one address
     *  @param _to is the address that will receive the mint
     *  @param _id is the ID of the token that will be minted
     *  @param _amount is the amount of the token that will be minted
     */
    function mint(address _to, uint _id, uint _amount) external onlyOwner {
        _mint(_to, _id, _amount, "");
    }

    /**
     *  @notice Function that allows the owner to mint several types of tokens at one address
     *  @notice It must have the same amount of ID's and Amounts
     *  @param _to is the address that will receive the mint
     *  @param _ids are the ID's of the tokens that will be minted
     *  @param _amounts are the amounts for each token that will be minted
     */
    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external onlyOwner {
        _mintBatch(_to, _ids, _amounts, "");
    }

    /**
     *  @notice Function that allows burn an amount of one type of token
     *  @param _id is the ID of the token that will be burned
     *  @param _amount is the amount of the token that will be burned
     */
    function burn(uint _id, uint _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    /**
     *  @notice Function that allows burn an amount of several types of tokens
     *  @notice It must have the same amount of ID's and Amounts
     *  @param _ids are the ID's of the tokens that will be burned
     *  @param _amounts are the amounts for each token that will be burned
     */
    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    /**
     *  @notice Function that allows the owner to burn an amount of several types of tokens at one address
     *  @notice Also allows mint an amount of several types of tokens at same address
     *  @notice It must have the same amount of ID's and Amounts for burn
     *  @notice It must have the same amount of ID's and Amounts for mint
     *  @param _from is the address that will receive the mint and will have the tokens burned
     *  @param _burnIds are the ID's of the tokens that will be burned
     *  @param _burnAmounts are the amounts for each token that will be burned
     *  @param _mintIds are the ID's of the tokens that will be minted
     *  @param _mintAmounts are the amounts for each token that will be minted
     */
    function burnForMint(
        address _from,
        uint[] memory _burnIds,
        uint[] memory _burnAmounts,
        uint[] memory _mintIds,
        uint[] memory _mintAmounts
    ) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    /**
     *  @notice Function that allows the owner to set the URI for a token
     *  @param _id is the ID of the token that will have the URI setted up
     *  @param _uri is the string that will be setted as the URI of the token
     */
    function setURI(uint _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    /**
     *  @notice Function that allows to retrieve the URI of a token
     *  @param _id is the ID of the token that is trying to retreive it's URI
     *  @return An string with the URI of the token
     */
    function uri(uint _id) public override view returns (string memory) {
        return tokenURI[_id];
    }
}