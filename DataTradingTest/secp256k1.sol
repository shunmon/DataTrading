// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract secp256k {
    //gx, gy, n, a, b: 这些常量定义了椭圆曲线的参数，其中 (gx, gy) 是基点（生成元）的坐标，n 是曲线上的阶，a 和 b 是曲线的参数。
    uint256 constant private gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 constant private gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 constant private n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 constant private a = 0;
    uint256 constant private b = 7;
    
    //这个函数实现了 Jacobian 坐标系下的椭圆曲线点加法。它接受两个椭圆曲线上的点 (x1, z1) 和 (x2, z2)，并返回它们的和 (x3, z3)。
    function _jAdd(uint256 x1, uint256 z1, uint256 x2, uint256 z2) private pure returns (uint256 x3, uint256 z3) {
        (x3, z3) = (addmod(mulmod(z2, x1, n), mulmod(x2, z1, n), n), mulmod(z1, z2, n));
    }

    //类似于 _jAdd，这个函数实现了 Jacobian 坐标系下的椭圆曲线点减法。
    function _jSub(uint256 x1, uint256 z1, uint256 x2, uint256 z2) private pure returns (uint256 x3, uint256 z3) {
        (x3, z3) = (addmod(mulmod(z2, x1, n), mulmod(n - x2, z1, n), n), mulmod(z1, z2, n));
    }

    //这个函数实现了 Jacobian 坐标系下的椭圆曲线点乘法。
    function _jMul(uint256 x1, uint256 z1, uint256 x2, uint256 z2) private pure returns (uint256 x3, uint256 z3) {
        (x3, z3) = (mulmod(x1, x2, n), mulmod(z1, z2, n));
    }

    //类似于 _jMul，这个函数实现了 Jacobian 坐标系下的椭圆曲线点除法。
    function _jDiv(uint256 x1, uint256 z1, uint256 x2, uint256 z2) private pure returns (uint256 x3, uint256 z3) {
        (x3, z3) = (mulmod(x1, z2, n), mulmod(z1, x2, n));
    }

    //计算一个数的模逆。
    function _inverse(uint256 inewrq) private pure returns (uint256 invA) {
        uint256 t = 0;
        uint256 newT = 1;
        uint256 r = n;
        uint256 newR = inewrq;
        uint256 q;
        while (newR != 0) {
            q = r / newR;
            (t, newT) = (newT, addmod(t, (n - mulmod(q, newT, n)), n));
            (r, newR) = (newR, r - q * newR);
        }
        return t;
    }
    
    //这个函数实现了仿射坐标系下的椭圆曲线点加法。
    function _ecAdd(uint256 x1, uint256 y1, uint256 z1, uint256 x2, uint256 y2, uint256 z2) private pure returns (uint256 x3, uint256 y3, uint256 z3) {
        uint256 l;
        uint256 lz;
        uint256 da;
        uint256 db;

        if ((x1 == 0) && (y1 == 0)) {
            return (x2, y2, z2);
        }

        if ((x2 == 0) && (y2 == 0)) {
            return (x1, y1, z1);
        }

        if ((x1 == x2) && (y1 == y2)) {
            (l, lz) = _jMul(x1, z1, x1, z1);
            (l, lz) = _jMul(l, lz, 3, 1);
            (l, lz) = _jAdd(l, lz, a, 1);
            (da, db) = _jMul(y1, z1, 2, 1);
        } else {
            (l, lz) = _jSub(y2, z2, y1, z1);
            (da, db) = _jSub(x2, z2, x1, z1);
        }

        (l, lz) = _jDiv(l, lz, da, db);

        (x3, da) = _jMul(l, lz, l, lz);
        (x3, da) = _jSub(x3, da, x1, z1);
        (x3, da) = _jSub(x3, da, x2, z2);

        (y3, db) = _jSub(x1, z1, x3, da);
        (y3, db) = _jMul(y3, db, l, lz);
        (y3, db) = _jSub(y3, db, y1, z1);

        if (da != db) {
            x3 = mulmod(x3, db, n);
            y3 = mulmod(y3, da, n);
            z3 = mulmod(da, db, n);
        } else {
            z3 = da;
        }
    }

    //类似于 _ecAdd，这个函数实现了椭圆曲线上点的倍乘。
    function _ecDouble(uint256 x1, uint256 y1, uint256 z1) private pure returns (uint256 x3, uint256 y3, uint256 z3) {
        (x3, y3, z3) = _ecAdd(x1, y1, z1, x1, y1, z1);
    }

    //这个函数实现了椭圆曲线上点的标量乘法。
    function _ecMul(uint256 d, uint256 x1, uint256 y1, uint256 z1) private pure returns (uint256 x3, uint256 y3, uint256 z3) {
        uint256 remaining = d;
        uint256 px = x1;
        uint256 py = y1;
        uint256 pz = z1;
        uint256 acx = 0;
        uint256 acy = 0;
        uint256 acz = 1;

        if (d == 0) {
            return (0, 0, 1);
        }

        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (acx, acy, acz) = _ecAdd(acx, acy, acz, px, py, pz);
            }
            remaining = remaining / 2;
            (px, py, pz) = _ecDouble(px, py, pz);
        }

        (x3, y3, z3) = (acx, acy, acz);
    }
    
    //对给定的基点进行标量乘法运算。
    function ScalarMult(uint256 px, uint256 py, uint256 scalar) external pure returns (uint256 qx, uint256 qy) {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = _ecMul(scalar, px, py, 1);
        z = _inverse(z);
        qx = mulmod(x, z, n);
        qy = mulmod(y, z, n);
    }
    
    //对椭圆曲线的基点 (gx, gy) 进行标量乘法运算。
    function ScalarBaseMult(uint256 scalar) external pure returns (uint256 qx, uint256 qy) {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = _ecMul(scalar, gx, gy, 1);
        z = _inverse(z);
        qx = mulmod(x, z, n);
        qy = mulmod(y, z, n);
    }
    
    //将一个字段元素映射到椭圆曲线上，并返回曲线上的点坐标。
    function HashToEcc(uint256 x1, uint256 y1) external pure returns (uint256 qx, uint256 qy) {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = _ecMul(uint256(keccak256(abi.encodePacked(x1, y1))), gx, gy, 1);
        z = _inverse(z);
        qx = mulmod(x, z, n);
        qy = mulmod(y, z, n);
    }
    
    //
    function Add(uint256 x1, uint256 y1, uint256 x2, uint256 y2) external pure returns (uint256 x3, uint256 y3) {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = _ecAdd(x1, y1, 1, x2, y2, 1);
        z = _inverse(z);
        x3 = mulmod(x, z, n);
        y3 = mulmod(y, z, n);
    }
}
