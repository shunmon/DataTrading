// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
 /* 4个ipfs CID：
    ["QmeMobhLKedMFfqJPPHnNzdzddTZMEyL2hophvEfC1VJ1g", "QmZwfk1FE5RtDdeNKVSjUThowiar6MrW3rQkhskxNr6vU5",
    "QmawhkymwbLQUjuyQVUraTjjUujo2MQMVTxAEAzAQyn8p6","QmYE1KM8GEFYRncuu2YsBp9VJzbAH1F6DQ91ui561C5vG7"]
 
   错误id：
   ["QmPaoos7ZVJuhdcnZwWqMfQQHH8SLagV9xe7SnhCZyc8wB", "QmZwfk1FE5RtDdeNKVSjUThowiar6MrW3rQkhskxNr6vU5",
    "QmawhkymwbLQUjuyQVUraTjjUujo2MQMVTxAEAzAQyn8p6","QmYE1KM8GEFYRncuu2YsBp9VJzbAH1F6DQ91ui561C5vG7"]
    
 
 * Merkle root: 0xb95d5e341e95319fc91b7a2fe66fd17b038cee5f74ebd3a3cb59bc118db6e760
 */

// 0xb3dc17cedb8e27042cb2b3f5f2ad154d5bed87c2ecbac96de76bdf1f59d46029,
// 0x5b35d3eb51100a148052e2929effe2fe4eb9ad9347888482b2899ac3d1763cbf,
// 0xbfe33a37c40020eeaae1844fc5e5971f5f2d903aaaefa6d4c51bf7d75a14981c,
// 0x363373d9d03d5922318b953ba8a1cae0a4ffecbe371d8978f05393105e090af6,
// 0x56929eeb90c635a3ad2da24cbd63645b0e719c2b5075205caa95318d78d5e381,
// 0x01c5774fe2597b80b5949d2145d7f444fa5dbdd19a8ab5c72c037c82b2a7fd05,
// 0xb95d5e341e95319fc91b7a2fe66fd17b038cee5f74ebd3a3cb59bc118db6e760

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleTree{
    bytes32[] public merkleTree;
    bytes32 public roothash;
    string[] public leaf;
    //string[] public Wleaf;
    
    //leaf赋值
    function fillLeafArray(string[] memory data) private {
        delete leaf;
    // 将 data 数组的内容复制到 leaf 数组中
        for (uint256 i = 0; i < data.length; i++) {
            leaf.push(data[i]);
            }
    }

    // 转换数据结构
    function constructMerkleTreeFromString(string[] memory data) public  returns (bytes32) {
        fillLeafArray(data);
        require(leaf.length > 0, "Data should not be empty");
        
        bytes32[] memory convertedData = new bytes32[](leaf.length);
        for (uint256 i = 0; i < leaf.length; i++) {
            convertedData[i] = keccak256(abi.encodePacked(leaf[i]));
        }

        // Call constructMerkleTree with convertedData
        return constructMerkleTree(convertedData);
    }

    //构建merkle tree，返回roothash
    function constructMerkleTree(bytes32[] memory data) private  returns (bytes32) {
        uint256 len = data.length;
        uint256 nextLevelLength = len;
        
        // Calculate the total number of nodes in the Merkle tree
        while (nextLevelLength > 1) {
            len += (nextLevelLength + 1) / 2;
            nextLevelLength = (nextLevelLength + 1) / 2;
        }
        //merkleTree = new bytes32[](len);
        bytes32[] memory tree = new bytes32[](len);
        uint256 offset = 0;

        // Calculate leaf nodes
        for (uint256 i = 0; i < data.length; i++) {
            tree[offset + i] = keccak256(abi.encodePacked(data[i]));
        }

        // Calculate internal nodes
        uint256 levelLength = data.length;
        while (levelLength > 1) {
            for (uint256 i = 0; i < levelLength; i += 2) {
                bytes32 leftChild = tree[offset + i];
                bytes32 rightChild = (i + 1 < levelLength) ? tree[offset + i + 1] : bytes32(0);
                tree[offset + levelLength + i / 2] = keccak256(abi.encodePacked(leftChild, rightChild));
            }
            offset += levelLength;
            levelLength = (levelLength + 1) / 2;
        }
        merkleTree = tree;
        //返回根hash
        roothash = tree[tree.length-1];
        return roothash;
    }
    
    //返回merkle树
    function getMerkleTree() public view returns (bytes32[] memory) {
        return merkleTree ;
    }

    //验证root hash就行
    function verfied(string[] memory current) public returns(bool) {
        bytes32  roothash1 = roothash;
        bytes32 calculatedRootHash = constructMerkleTreeFromString(current);
        return calculatedRootHash == roothash1;
    }

//     // 根据上面函数得到的MerkleTree，输入string[] public leaf的编号，获取 Merkle Proof 的值（兄弟节点和父兄弟节点）
//     function getMerkleProof(uint index) public pure returns (bytes32[] memory) {

    
// }


    // //验证数据是否在merkle tree中
    // function verifyMerkleProof(bytes32 merkleroot, string memory current) public pure returns (bool) {
    //     // 验证数据是否属于 Merkle 树中  proof = merkleTree
    //     bytes32[] memory Merkle_Proof = getMerkleProof();
    //     bytes32 result = keccak256(abi.encodePacked(current));
    //     return MerkleProof.verify(Merkle_Proof, merkleroot, result);
    // }   
}
