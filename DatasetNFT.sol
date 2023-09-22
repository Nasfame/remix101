// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DatasetNFT is ERC721, ERC721URIStorage, Ownable {
     using Counters for Counters.Counter;
     Counters.Counter private _tokenIds;

    struct NftData {
        uint tokenId;
        string  uri;
    }

    mapping (address => NftData[]) nftRecord;

    constructor() ERC721("DatasetNFT", "DSN") {}

    //mint NFT using  dynamic URI
    function mintNFT(string memory customURI) public{
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, customURI);
        NftData[] storage data = nftRecord[msg.sender];
        data.push(NftData({tokenId:newItemId, uri:customURI}));
        nftRecord[msg.sender] = data;
     
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function getNFTS(address _owner) external view returns( NftData[] memory ){
        return nftRecord[_owner];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}