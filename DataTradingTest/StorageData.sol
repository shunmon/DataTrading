// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./Seller.sol";
import "./Buyer.sol";

contract StorageData{
    Seller public sellerContract; // 实例化 Seller 合约
    Buyer public buyerContract; // 实例化 Buyer 合约
    // 存储的信息列表
    string[][] public informationList;// [[dec,……],[],[]]
    mapping(address => string[][]) private userInformation;
    
    address[] public sellers; //售卖者地址
    address[] public buyers; //购买者地址

    constructor(address _sellerContractAddress,address _buyerContractAddress) {
        sellerContract = Seller(_sellerContractAddress); // 实例化 Seller 合约
        buyerContract = Buyer(_buyerContractAddress); // 实例化 Buyer 合约
    }
    

    // 定义Seller modifier
   modifier SellerAddress(){
       bool isSeller = false;
       uint SellerCount = sellerContract.getSellerCount();
        for (uint i = 0; i < SellerCount; i++) {
            if (msg.sender == sellerContract.getSellerById(i)) {
                isSeller = true;
                break;
            }
        }
        require(isSeller, "Only seller can call this function");
        _;
   }
    //定义Buyer modifier
   modifier BuyerAddress(){
       bool isbuyer = false;
       uint BuyCount = buyerContract.getbuyerCount();
        for (uint i = 0; i < BuyCount; i++) {
            if (msg.sender == buyerContract.getBuyerById(i)) {
                isbuyer = true;
                break;
            }
        }
        require(isbuyer, "Only buyer can call this function");
        _;
   }

    // // 获取 Seller 合约中的所有售卖者地址
    // function getAllSellersFromSellerContract() public view returns (address[] memory) {
    //     return sellerContract.getAllSellers();
    // }

   // 添加信息列表到存储列表中
    function addInformationList(string[] memory infoList) external SellerAddress{
        informationList.push(infoList);
        userInformation[msg.sender].push(infoList);
    }

    // 获取列表数量
    function getListCount() public view returns (uint) {
        return informationList.length;
    }


    // 获取地址索引的信息列表
    function getUserInformation(address user) public view returns (string[][] memory) {
        return userInformation[user];
    }

    // 更新地址中的信息列表中的信息
    function updateInformation(uint listIndex, uint infoIndex, string memory newInfo) public  returns (uint){
        require(listIndex < userInformation[msg.sender].length, "List index out of bounds");
        require(infoIndex < userInformation[msg.sender][listIndex].length, "Info index out of bounds");
        userInformation[msg.sender][listIndex][infoIndex] = newInfo;
        return userInformation[msg.sender][listIndex].length;
    }


    //删除指定索引的信息列表中的信息
    function deleteInformationList(uint listIndex) public {
        require(listIndex < userInformation[msg.sender].length, "List index out of bounds");
        // 直接删除指定索引的信息列表
        delete userInformation[msg.sender][listIndex];
}

}