// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 安全数学库
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow"); // 防止溢出
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "Addition overflow"); // 防止溢出
        return c;
    }
}

// secp256k 接口
interface secp256k {
    function ScalarMult(
        uint256 px,
        uint256 py,
        uint256 scalar
    ) external pure returns (uint256 qx, uint256 qy);

    function ScalarBaseMult(uint256 scalar)
        external
        pure
        returns (uint256 qx, uint256 qy);

    function HashToEcc(uint256 x1, uint256 y1)
        external
        pure
        returns (uint256 qx, uint256 qy);

    function Add(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) external pure returns (uint256 x3, uint256 y3);
}

// 不可追踪投票合约
contract UntraceableVoting {
    secp256k Curve;
    address owner;
    mapping(uint256 => voting) public votings;

    constructor(address curveDest) {
        require(curveDest != address(0), "Invalid curve destination"); // 检查曲线目标地址不为空
        Curve = secp256k(curveDest); // 设置曲线
        owner = msg.sender; // 设置合约所有者
    }

    // 创建投票
    function createVote(uint64 id, address[] calldata candidatesIDs)
        external
        payable
    {
        require(votings[id].id == 0, "Vote with this ID already exists"); // 检查投票是否已经存在
        require(id != 0, "Invalid ID"); // 检查ID是否有效
        votings[id].creator = msg.sender;
        votings[id].candidatesIDs = candidatesIDs;
        votings[id].id = id;
        votings[id].val = msg.value;
        votings[id].threashold = 1;
        // 设置初始值为空数组
        votings[id].votersX = new uint256[](0);
        votings[id].votersY = new uint256[](0);
        votings[id].done = false;
        votings[id].ready = false;

        // 初始化候选人映射
        for (uint256 i = 0; i < candidatesIDs.length; i++) {
            address candidate = candidatesIDs[i];
            // 如果候选人不存在，则设置初始值为 1
            if (votings[id].candidates[candidate] == 0) {
                votings[id].candidates[candidate] = 1;
            }
        }
    }

    // 添加选民到投票
    function addVotersToVote(
        uint64 id,
        uint256[] calldata allowedVotersX,
        uint256[] calldata allowedVotersY,
        uint256 threashold,
        bool ready
    ) external {
        require(votings[id].id != 0, "Vote does not exist"); // 检查投票是否存在
        require(!votings[id].ready, "Vote is already ready"); // 检查投票是否已准备好
        require(
            msg.sender == votings[id].creator,
            "Only the creator can add voters"
        ); // 检查调用者是否为创建者
        require(
            allowedVotersX.length == allowedVotersY.length,
            "Invalid voters coordinates"
        ); // 检查选民坐标是否有效
        require(
            votings[id].threashold < threashold,
            "New threshold must be greater than current threshold"
        ); // 检查新阈值是否大于当前阈值
        require(
            threashold <= allowedVotersX.length + votings[id].votersX.length,
            "Threshold exceeds allowed voters"
        ); // 检查阈值是否超过允许的选民数

        // 添加选民
        for (uint256 i = 0; i < allowedVotersX.length; i++) {
            votings[id].votersX.push(allowedVotersX[i]);
            votings[id].votersY.push(allowedVotersY[i]);
        }
        votings[id].ready = ready; // 设置投票状态为准备好
        votings[id].threashold = threashold; // 设置投票阈值
    }

    // 投票结构体
    struct voting {
        address creator;
        address[] candidatesIDs;
        uint64 id;
        uint256 val;
        uint256 threashold;
        uint256 votecounter;
        uint256[] votersX;
        uint256[] votersY;
        bool done;
        bool ready;
        mapping(uint256 => bool) keyimageHashMap;
        mapping(address => uint256) candidates;
    }

    // 定义结构体存储 L 和 R 值
    struct LRValues {
        uint256 Lix;
        uint256 Liy;
        uint256 Rix;
        uint256 Riy;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed"); // 仅所有者允许
        _;
    }

    // 自毁函数
    function oops() external onlyOwner {
        payable(owner).transfer(address(this).balance); // 转移合约余额给所有者
    }

    // 更新曲线地址
    function updateCurve(address curveDest) external onlyOwner {
        Curve = secp256k(curveDest); // 更新曲线
    }

    // 获取投票状态
    function VoteState(uint64 id, address candidate)
        external
        view
        returns (bool, uint256)
    {
        require(votings[id].id != 0, "Vote does not exist"); // 检查投票是否存在
        require(votings[id].candidates[candidate] != 0, "Candidate not found"); // 检查候选人是否存在
        return (
            votings[id].votecounter >= votings[id].threashold,
            votings[id].candidates[candidate]
        ); // 返回投票状态
    }

    // 完成投票
    function CompleteVote(uint64 id) external {
        require(votings[id].id != 0, "Vote does not exist"); // 检查投票是否存在
        require(votings[id].ready, "Vote is not ready"); // 检查投票是否已准备好
        require(!votings[id].done, "Vote is already completed"); // 检查投票是否已完成
        require(
            votings[id].votecounter >= votings[id].threashold,
            "Not enough votes"
        ); // 检查是否有足够的投票

        votings[id].done = true; // 设置投票为完成

        address[15] memory res;
        uint8 anz;
        (res, anz) = VoteLeaders(id); // 获取领导者
        uint256 reward = votings[id].val / anz; // 计算奖励
        for (uint8 i = 0; i < anz; i++) {
            payable(res[i]).transfer(reward); // 分配奖励
        }
    }

    // 获取领导者
    function VoteLeaders(uint64 id)
        public
        view
        returns (address[15] memory, uint8)
    {
        require(votings[id].id != 0, "Vote does not exist"); // 检查投票是否存在
        require(votings[id].ready, "Vote is not ready"); // 检查投票是否已准备好
        uint256 max = 0;
        address[15] memory res;
        uint8 counter = 1;

        for (uint256 i = 0; i < votings[id].candidatesIDs.length; i++) {
            uint256 val = votings[id].candidates[votings[id].candidatesIDs[i]];
            if (val > max) {
                res = [
                    votings[id].candidatesIDs[i],
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0)
                ]; // 设置领导者数组
                max = val;
                counter = 1;
            } else if (val == max) {
                res[counter] = votings[id].candidatesIDs[i]; // 设置领导者数组
                counter++;
                if (counter == 14) {
                    counter = 1;
                }
            }
        }
        return (res, counter); // 返回领导者数组和领导者数量
    }

    // 匿名投票
    function VoteAnnonymous(
        uint64 id,
        address candidateId,
        uint256 Ix,
        uint256 Iy,
        uint256 c,
        uint256[] calldata s
    ) external payable {
        require(votings[id].id != 0, "Vote does not exist"); // 检查投票是否存在
        require(votings[id].ready, "Vote is not ready"); // 检查投票是否已准备好
        require(!votings[id].done, "Vote is already completed"); // 检查投票是否已完成
        require(
            s.length == votings[id].votersX.length,
            "Invalid signature length"
        ); // 检查签名长度是否正确
        require(votings[id].candidates[candidateId] >= 1, "Invalid candidate"); // 检查候选人是否有效
        require(votings[id].keyimageHashMap[Ix] == false, "Vote already cast"); // 检查是否重复投票

        require(
            verifyRingSignature(candidateId, id, Ix, Iy, c, s),
            "Invalid signature"
        ); // 验证环签名

        votings[id].val += msg.value; // 增加投票总金额
        votings[id].candidates[candidateId] += 1; // 增加候选人得票数
        votings[id].votecounter += 1; // 增加总投票数
        votings[id].keyimageHashMap[Ix] = true; // 记录投票
    }

    // 验证环签名
    function verifyRingSignature(
        address candidateId,
        uint64 id,
        uint256 Ix,
        uint256 Iy,
        uint256 c,
        uint256[] calldata s
    ) internal view returns (bool) {
        uint256[] memory ci = new uint256[](2);
        ci[0] = c;
        LRValues memory lrValues;

        for (uint256 i = 0; i < s.length; i++) {
            // 计算 L 和 R 值
            lrValues = computeLRValues(s[i], id, i, ci[i % 2], Ix, Iy);
            ci[(i + 1) % 2] = uint256(
                keccak256(
                    abi.encodePacked(
                        id,
                        candidateId,
                        lrValues.Lix,
                        lrValues.Liy,
                        lrValues.Rix,
                        lrValues.Riy
                    )
                )
            ); // 计算下一个哈希值
        }

        return (ci[s.length % 2] == c); // 检查最终哈希值是否等于 c
    }

    // 计算 L 和 R 值
    function computeLRValues(
        uint256 s,
        uint64 id,
        uint256 i,
        uint256 ci,
        uint256 Ix,
        uint256 Iy
    ) internal view returns (LRValues memory) {
        LRValues memory lrValues;
        (lrValues.Lix, lrValues.Liy) = l(s, id, i, ci); // 计算 L 值
        (lrValues.Rix, lrValues.Riy) = r(s, id, i, ci, Ix, Iy); // 计算 R 值
        return lrValues;
    }

    // 计算 R 值
    function r(
        uint256 s,
        uint64 id,
        uint256 i,
        uint256 ci,
        uint256 Ix,
        uint256 Iy
    ) internal view returns (uint256, uint256) {
        uint256 t1;
        uint256 t2;
        uint256 x3;
        uint256 x4;
        (t1, t2) = Curve.HashToEcc(
            votings[id].votersX[i],
            votings[id].votersY[i]
        );
        (t1, t2) = Curve.ScalarMult(t1, t2, s);
        (x3, x4) = Curve.ScalarMult(Ix, Iy, ci);

        return Curve.Add(t1, t2, x3, x4);
    }

    // 计算 L 值
    function l(
        uint256 s,
        uint64 id,
        uint256 i,
        uint256 ci
    ) internal view returns (uint256, uint256) {
        uint256 x1;
        uint256 x2;
        uint256 x3;
        uint256 x4;
        (x1, x2) = Curve.ScalarBaseMult(s);
        (x3, x4) = Curve.ScalarMult(
            votings[id].votersX[i],
            votings[id].votersY[i],
            ci
        );
        (x1, x2) = Curve.Add(x1, x2, x3, x4); // 将 L 值直接计算为 ScalarBaseMult(s) + ScalarMult(votings[id].votersX[i], votings[id].votersY[i], ci)
        return (x1, x2);
    }
}
