// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Seller {
    address[] public sellers;

    constructor() {
        // 初始化售卖者列表
        sellers.push(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        sellers.push(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        // 添加其他售卖者...
    }

    // 添加售卖者到列表
    function addSeller(address seller) public {
        sellers.push(seller);
    }

    // 获取售卖者列表长度
    function getSellerCount() public view returns (uint) {
        return sellers.length;
    }
    // 获取所有售卖者地址
    function getAllSellers() public view returns (address[] memory) {
        return sellers;
    }

    // 获取 Seller 合约中的指定索引的售卖者地址
    function getSellerById(uint index) public view returns (address) {
        require(index < sellers.length, "Index out of bounds");
        return sellers[index];
    }
}
