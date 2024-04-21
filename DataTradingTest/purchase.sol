// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Seller.sol";
import "./Buyer.sol";
import "DataTradingTest/StorageData.sol";

contract purchase {
    
    Seller private sellerContract; // 实例化 Seller 合约
    Buyer private buyerContract; // 实例化 Buyer 合约
    StorageData private storageDataContract; //实例化存储合约

    address payable public Person;

    uint256 public deposit;
    uint256 public itemPrice;
    bool public isItemSold;

    //传输信息
    bytes32[] public EncryptedInfo;
    
    //用户押金支付绑定
    mapping(address => uint256) public deposits;
    mapping(address => bool) public depositPaid;

    // 事件用于记录交易
    event DepositReceived(address indexed _from, uint256 _value);
    event ItemPurchased(address indexed _from, uint256 _value);

    constructor(address _storageContractAddress) {
        storageDataContract =  StorageData(_storageContractAddress); // 实例化 Buyer 合约
    }

    // 用户支付押金
    function payDeposit(uint256 _fixedItemPrice) external payable returns (bool){
        require(!depositPaid[msg.sender], "Deposit already paid");
        require(msg.value >= _fixedItemPrice, "Deposit amount insufficient");

        deposits[msg.sender] = msg.value;
        depositPaid[msg.sender] = true;
        
        // 将itemPrice设置为固定的价格
        itemPrice = _fixedItemPrice;
        // 将调用者地址设置为卖家地址
        Person = payable(msg.sender);

        emit DepositReceived(msg.sender, msg.value);
        return true;
    }

    
    // 用户取回押金
    function refundDeposit() external {
        //判断是否支付押金
        require(depositPaid[msg.sender], "Deposit not paid yet");
        //判断合约余额是否足够
        require(address(this).balance >= deposits[msg.sender], "Contract balance insufficient");

        uint256 depositAmount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        depositPaid[msg.sender] = false;

        payable(msg.sender).transfer(depositAmount);
    }




    
}