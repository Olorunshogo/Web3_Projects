// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// === ERC165 Interface ===
interface IERC165 {
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// === ERC721 Interface inheriting IERC165 ===
interface IERC721 is IERC165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool tokenId);

  function balanceOf(address owner) external view returns (uint256);

  function ownerOf(uint256 tokenId) external view returns (address);

  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  function transferFrom(address from, address to, uint256 _tokenId) external;

  function approve(address to, uint256 tokenId) external;

  function setApprovalForAll(address operator, bool approved) external;

  function getApproved(uint256 tokenId) external view returns (address);

  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// === ERC721Metadata Interface inheriting IERC721 ===
interface IERC721Metadata is IERC721 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// === ERC721Metadata Interface inheriting IERC721 ===
interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

contract ERC721 is IERC721Metadata {
  string private _name;
  string private _symbol;
  string private _baseURI;

  mapping(uint => address) private _owners;
  mapping(address => uint256) private _balances;

  mapping(uint256 => address) private _tokenApprovals;

  // Passing in owner address and in the spender address, give the approval status of the spender
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_, string memory baseURI_) {
    _name = name_;
    _symbol = symbol_;
    _baseURI = baseURI_;
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // IERC 165
      interfaceId == 0x80ac58cd || // IERC721
      interfaceId == 0x5b5e139f; // IERC721Metadata
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "Real address");

    return _balances[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "Zero address");
    return owner;
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId), "Invalid token");
    if (bytes(_baseURI).length == 0) return "";
    return string(abi.encodePacked(_baseURI, tokenId));
  }

  function approve(address to, uint256 tokenId) external {
    address owner = ownerOf(tokenId);
    require(to != owner, "Cannot approve to current owner");
    require(msg.sender == owner, "Unauthorized");
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), "Token does not exist");
    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) external {
    require(operator != msg.sender, "Cannot approve to self");
    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    address owner = ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
  }

  function _transfer(address from, address to, uint256 tokenId) internal {
    delete _tokenApprovals[tokenId];
    emit Approval(from, address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  // function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data) internal returns (bool) {

  // }

  function transferFrom(address from, address to, uint tokenId) public {
    require(_isApprovedOrOwner(msg.sender, tokenId), "Unauthorized");
    require(ownerOf(tokenId) == from, "Wrong from");
    require(to != address(0), "Transfer to zero address");
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) external {
    bytes memory emptyData = "";
    safeTransferFrom(from, to, tokenId, emptyData);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
    require(_isApprovedOrOwner(msg.sender, tokenId), "Unauthorized");
    require(ownerOf(tokenId) == from, "Wrong from");
    require(to != address(0), "Transfer to zero address");
    _safeTransfer(from, to, tokenId, data);
  }

  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal returns (bool) {
    if (to.code.length == 0) {
      return true; // EOA
    }
    try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (
      bytes4 retval
    ) {
      return retval == IERC721Receiver.onERC721Received.selector;
    } catch {
      return false;
    }
  }

  // Mint
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0), "Mint to zero address");
    require(!_exists(tokenId), "Token already minted");

    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);
  }

  function mint(address to, uint256 tokenId) external {
    _mint(to, tokenId);
  }

  function setBaseURI(string calldata newBaseURI) external {
    _baseURI = newBaseURI;
  }

  function burn(uint256 tokenId) external {
    address owner = ownerOf(tokenId);
    require(_isApprovedOrOwner(msg.sender, tokenId), "unauthorized");

    delete _tokenApprovals[tokenId];
    emit Approval(owner, address(0), tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }
}
