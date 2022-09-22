// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/////////////////////////////////////////////
//                                         //
//       *          *                      //
//      * *        * *                     //
//     *   *      *   *                    //
//    *     *    *     *                   //
//   *       *  *       *                  //
//  *         **         *                 //
//   *       *  *       *                  //
//    *     *    *     *                   //
//     *   *      *   *                    //
//      * *        * *         H & K       //
//       *          *                      //
//                                         //
/////////////////////////////////////////////

contract Polyfaucet is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 public merkleRoot = 0x00; // for adding future donors
    string public baseURI =
        "ipfs://bafybeib2dwszaij27n5m7adedxcdrjemf7wd5fihd565fma6b7llfnnpaq";
    uint256 public MAX_SUPPLY = 1000;
    mapping(address => bool) public claimed;

    // simple constructor. We hardcode the merkle root & base URI before.
    constructor() ERC721("Polyfaucet", "PLYF") {}

    // to bulk airdrop NFT's. Can't do it in constructor or run out of space in block (1000 addresses is a lot to mint at the same time.)
    function bulkAirdrop(address[] memory airdrops) public onlyOwner {
        if (airdrops.length > 50) {
            revert("Over gas limit, max addresses is 50");
        }
        for (uint256 i = 0; i < airdrops.length; i++) {
            claimed[airdrops[i]] = true;
            uint256 newItemId = _tokenIds.current();
            _mint(airdrops[i], newItemId);
            // construct token URI from base URI and token ID. Have to cast token ID to string because it is a uint256.
            string memory tokenURI = string.concat(
                baseURI,
                "/",
                Strings.toString(newItemId),
                ".json"
            );
            _setTokenURI(newItemId, tokenURI);
            _tokenIds.increment();
        }
    }

    // update merkle root (only callable by owner)
    // purpose of having this updateable is to allow for new snapshots in the future
    function updateMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    // update base URI (only callable by owner)
    // purpose of having this updateable is to allow for new snapshots in the future. Doesn't change previous tokens uri.
    function updateBaseURI(string calldata _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // update max supply (only callable by owner)
    // purpose of having this updateable is to allow for new snapshots in the future
    function updateMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }

    // mint function. It checks if the sender is in the whitelist and if he has not already claimed a token.
    // the whitelist check is done using a Merkle Tree.
    function mint(bytes32[] calldata _merkleProof) public returns (uint256) {
        // only allow whitelisted address to mint once
        require(!claimed[msg.sender], "already claimed");
        claimed[msg.sender] = true;
        // max Supply of 1000 tokens
        require(_tokenIds.current() < MAX_SUPPLY, "max supply reached");

        // check if the merkle proof is valid
        require(
            MerkleProof.verify(
                _merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "invalid merkle proof"
        );

        // only allow whitelisted address to mint once
        claimed[msg.sender] = true;
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);

        // construct token URI from base URI and token ID. Have to cast token ID to string because it is a uint256.
        string memory tokenURI = string.concat(
            baseURI,
            "/",
            Strings.toString(newItemId),
            ".json"
        );
        _setTokenURI(newItemId, tokenURI);

        _tokenIds.increment();
        return newItemId;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}

//   ______
//  /\__\__\
// /\/\__\__\
// \/\/__/__/
//  \/__/__/   a cool cube
//
