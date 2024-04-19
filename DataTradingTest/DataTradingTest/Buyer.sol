// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Buyer {
    address[] public buyers;

    constructor() {
        // 初始化售卖者列表
        buyers.push(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        buyers.push(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        // 添加其他购买者...
    }

    // 添加购买者到列表
    function addbuyer(address buyer) public {
        buyers.push(buyer);
    }

    // 获取购买者列表长度
    function getbuyerCount() public view returns (uint) {
        return buyers.length;
    }

    // 获取指定索引的购买者地址
    function getBuyerById(uint index) public view returns (address) {
        require(index < buyers.length, "Index out of bounds");
        return buyers[index];
    }

        // 获取所有购买者地址
    function getAllBuyers() public view returns (address[] memory) {
        return buyers;
    }
}
