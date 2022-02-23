/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC721Token is ERC721, Pausable, AccessControl {
    using Strings for uint256;
    using Counters for Counters.Counter;

    /// VARIABLES

    /**
     *  @notice Counter used for the total token supply
     */
    Counters.Counter private supply;

    /**
     *  @notice Strings used for the prefix of the Tokens and Unrevealed
     */
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    
    /**
     *  @notice Uint's used for the mint cost, the max amount of token and max amount of token per mint transaction
     */
    uint256 public cost = 0.01 ether;
    uint256 public maxSupply = 300;
    uint256 public maxMintAmountPerTx = 5;

    /**
     *  @notice Bool used for knowing if the tokens are revealed or not
     */
    bool public revealed = false;

    /**
     *  @notice Enum used for tracking the state of the mint
     */
    State public state = State.NOT_STARTED;

    /**
     *  @notice Mapping used for keeping a track of the users who can mint before the contract starts
     */
    mapping(address => bool) whitelist;

    /**
     *  @notice Bytes32 used for roles in the Dapp
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    /**
     *  @notice Payable account used for withdraw the balance of the contract
     */
    address payable owner;

    /// STATES
    /**
     *  @notice Enum used for tracking the state of the mint
     */
    enum State { NOT_STARTED, STARTED }

    /// MODIFIERS
    /**
     *  @notice Modifier function that verifies that you are minting the right amount
     *  @notice You cannot mint more than the max amount allowed per transaction
     *  @notice You cannot mint less than 1 token
     *  @param _mintAmount is the amount of tokens trying to be minted
     */
    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    /**
     *  @notice Modifier function that verifies if the contract is started
     *  @notice If the objective of mint is in the Whitelist state doesn't matter
     *  @param _objective is the address that is trying to mint
     */
    modifier contractStarted(address _objective) {
        require(
            state == State.STARTED || whitelist[_objective] == true,
            "The contract has not started yet!"
        );
        _;
    }

    /// FUNCTIONS
    /**
     *  @notice Constructor function that initialice the contract and set de Hidden Uri
     */
    constructor() ERC721("Eyes", "EYE") {
        setHiddenMetadataUri("ipfs://Qmetig1Cdep14CmpfyM63aiErkSovse2ge7zxzXpnxVypB/hidden.json");

        owner = payable(msg.sender);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
    }

    /**
     *  @notice Function overrider for solving collission between ERC721 and AccessControl
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     *  @notice Function that returns the current supply
     */
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    /**
     *  @notice Function that allows to mint one or more tokens
     *  @notice The contract cannot be paused
     *  @param _mintAmount is the amount of tokens to be minted by the address in this transaction
     */
    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        whenNotPaused
        contractStarted(msg.sender)
        onlyRole(MINTER_ROLE)
    {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        _mintLoop(msg.sender, _mintAmount);
    }
    
    /**
     *  @notice Function that allows the owner to mint for another address
     *  @param _mintAmount is the amount of tokens to be minted to the address by the owner
     *  @param _receiver is the address that will receive the tokens
     */
    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        whenNotPaused
        contractStarted(_receiver)
        onlyRole(ADMIN_ROLE)
    {
        _mintLoop(_receiver, _mintAmount);
    }

    /**
     *  @notice Function that allows the owner of a token to burn it
     *  @param _tokenId is the ID of the token to be burned
     */
    function burn(uint256 _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender);
        _burn(_tokenId);
    }

    /**
     *  @notice Function that allows to see the wallet for an address
     *  @param _owner is the address to consult
     *  @return an array of uint256 with all the ID's that belong to the address
     */
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    /**
     *  @notice Function that returns the URI for the token
     *  @notice If the contract has not revealed yet, this will return the hidden uri
     *  @param _tokenId is the ID of the token for retrieve his URI
     *  @return an string with the correct URI
     */
    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : "";
    }

    /**
     *  @notice Set function for the variable revealed
     */
    function setRevealed(bool _state) public onlyRole(ADMIN_ROLE) {
        revealed = _state;
    }

    /**
     *  @notice Set function for the variable cost
     */
    function setCost(uint256 _cost) public onlyRole(ADMIN_ROLE) {
        cost = _cost;
    }

    /**
     *  @notice Set function for the variable maxMintAmountPerTx
     */
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyRole(ADMIN_ROLE) {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    /**
     *  @notice Set function for the variable hiddenMetadataUri
     */
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyRole(ADMIN_ROLE) {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    /**
     *  @notice Set function for the variable uriPrefix
     */
    function setUriPrefix(string memory _uriPrefix) public onlyRole(ADMIN_ROLE) {
        uriPrefix = _uriPrefix;
    }

    /**
     *  @notice Set function for the variable uriSuffix
     */
    function setUriSuffix(string memory _uriSuffix) public onlyRole(ADMIN_ROLE) {
        uriSuffix = _uriSuffix;
    }

    /**
     *  @notice Function for pause the contract
     */
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     *  @notice Function for unpause the contract
     */
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     *  @notice Set function for the whitelist
     *  @param _objective is the address that will be setted up in the whitelist
     *  @param _included is the boolean for include or exclude the address from the whitelist
     */
    function setAddressInWhitelist(address _objective, bool _included) public onlyRole(ADMIN_ROLE) {
        whitelist[_objective] = _included;
    }

    /**
     *  @notice Function that allow the owner to grant an address the minter role
     *  @param _objective is the address that will become a minter
     */
    function grantMinterRole(address _objective) public onlyRole(ADMIN_ROLE) {
        grantRole(MINTER_ROLE, _objective);
    }

    /**
     *  @notice Function that allow the owner to revoke an address the minter role
     *  @param _objective is the address that will become a minter
     */
    function revokeMinterRole(address _objective) public onlyRole(ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, _objective);
    }

    /**
     *  @notice Function that allow the owner to withdraw all the funds
     */
    function withdraw() public onlyRole(ADMIN_ROLE) {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }

    /**
     *  @notice Function that allow to mint several tokens at once
     *  @param _receiver is the address that will receive the tokens
     *  @param _mintAmount is the ammount of tokens to be minted
     */
    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    /**
     *  @notice Internal function that returns the uriPrefix
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}