# import json
# import os
# import random
# import hashlib
# import binascii
#
# from ecdsa import SigningKey, SECP256k1, VerifyingKey
#
#
# class Voting:
#     def __init__(self):
#         self.id = None
#         self.candidates = []
#         self.voters = []
#
#     def to_dict(self):
#         return {
#             "id": self.id,
#             "candidates": [binascii.hexlify(sk.to_string()).decode() for sk in self.candidates],
#             "voters": [binascii.hexlify(sk.to_string()).decode() for sk in self.voters]
#         }
#
#     @classmethod
#     def from_dict(cls, data):
#         obj = cls()
#         obj.id = data["id"]
#         obj.candidates = [SigningKey.from_string(binascii.unhexlify(sk), curve=SECP256k1) for sk in data["candidates"]]
#         obj.voters = [SigningKey.from_string(binascii.unhexlify(sk), curve=SECP256k1) for sk in data["voters"]]
#         return obj
#
#
# def create_rand_vote(candidates_count, voters_count):
#     vote = Voting()
#     vote.id = random.getrandbits(64)
#     vote.candidates = [SigningKey.generate(curve=SECP256k1) for _ in range(candidates_count)]
#     vote.voters = [SigningKey.generate(curve=SECP256k1) for _ in range(voters_count)]
#     return vote
#
#
# def write_json_file(data, filename):
#     with open(filename, 'w') as f:
#         json.dump(data, f)
#
#
# def read_json_file(filename):
#     with open(filename, 'r') as f:
#         return json.load(f)
#
#
# from web3 import Web3
# import hashlib
#
# def generate_ethereum_address(seed):
#     # 生成私钥
#     private_key = hashlib.sha256(seed.encode()).hexdigest()
#     # 将私钥转换为公钥
#     public_key = Web3.keccak(hexstr=private_key)
#     # 取公钥的最后20字节（以太坊地址的基础是公钥的最后20字节）
#     address = Web3.to_checksum_address('0x' + public_key.hex()[-40:])
#     return address
#
# def prepare_solidity_create_args(voting):
#     args = {
#         "voting_id": generate_ethereum_address(str(voting.id)),
#         "candidates": [generate_ethereum_address(sk.verifying_key.to_string().hex()) for sk in voting.candidates]
#     }
#     return args
#
#
#
# def prepare_solidity_vote_args(voting):
#     args = []
#     for i, voter in enumerate(voting.voters):
#         vote_args = {
#             "voter_id": binascii.hexlify(voter.verifying_key.to_string()).decode(),
#             "candidates": [binascii.hexlify(sk.verifying_key.to_string()).decode() for sk in voting.candidates],
#             "Ix": generate_ethereum_address(str(voting.id) + str(i) + "Ix"),  # 生成 Ix 的逻辑
#             "Iy": generate_ethereum_address(str(voting.id) + str(i) + "Iy"),  # 生成 Iy 的逻辑
#             "c": generate_ethereum_address(str(voting.id) + str(i) + "c"),   # 生成 c 的逻辑
#             "threshold": len(voting.voters),
#             "ready": "true"
#         }
#         args.append(vote_args)
#     return args
#
#
# def sign_vote(vote_id, candidate_id, voter_key, voter_position):
#     candidate_id_str = str(candidate_id)
#     sig = voter_key.sign(str(vote_id).encode() + candidate_id_str.encode() +
#                          str(voter_position).encode(), hashfunc=hashlib.sha256)
#     return binascii.hexlify(sig).decode()
#
#
# def main():
#     rand_vote = create_rand_vote(3, 3)
#     write_json_file(rand_vote.to_dict(), 'test.json')
#
#     vote_data = read_json_file('test.json')
#     vote_obj = Voting.from_dict(vote_data)
#
#     voting_id = f'"{vote_obj.id}"'  # 使用相同的投票 ID
#
#     create_args = prepare_solidity_create_args(vote_obj)
#     vote_args = prepare_solidity_vote_args(vote_obj)
#
#     with open("solargs.txt", 'w') as f:
#         f.write("arguments for createVote(...)\n")
#         f.write(f'voting_id={voting_id}\n')
#         f.write(f'candidates={create_args["candidates"]}\n\n')
#         f.write("arguments for addVotersToVote(...)\n")
#         f.write(f'voting_id={voting_id}\n')
#         # 写入时移除单引号
#         # 使用 repr() 函数处理字符串
#         allowed_voters_x = [x.strip("\"") for x in vote_args[0]["candidates"]]
#         allowed_voters_y = [y.strip("\"") for y in vote_args[1]["candidates"]]
#         f.write(f'allowedVotersX={repr(allowed_voters_x)}\n')
#         f.write(f'allowedVotersY={repr(allowed_voters_y)}\n')
#         f.write(f'threshold={vote_args[0]["threshold"]}\n')
#         f.write(f'ready={vote_args[0]["ready"]}\n')
#
#     with open("vote.txt", 'w') as f:
#         f.write("arguments for VoteAnnonymous(...)\n\n")
#         for i, vote_arg in enumerate(vote_args):
#             candidate = random.choice(vote_obj.candidates)
#             sig = sign_vote(vote_obj.id, candidate, vote_obj.voters[i], i)
#             f.write(f'Voter {i} votes for candidate {candidate}\n')
#             f.write(
#                 f'{vote_arg["voter_id"]},{vote_arg["candidates"]},{vote_arg["Ix"]},{vote_arg["Iy"]},{vote_arg["c"]},{vote_arg["threshold"]},{vote_arg["ready"]}\n')
#
# if __name__ == "__main__":
#     main()




import json
import os
import random
import hashlib
import binascii

from ecdsa import SigningKey, SECP256k1, VerifyingKey
from web3 import Web3

class Voting:
    def __init__(self):
        self.id = None
        self.candidates = []
        self.voters = []

    def to_dict(self):
        return {
            "id": self.id,
            "candidates": [binascii.hexlify(sk.to_string()).decode() for sk in self.candidates],
            "voters": [binascii.hexlify(sk.to_string()).decode() for sk in self.voters]
        }

    @classmethod
    def from_dict(cls, data):
        obj = cls()
        obj.id = data["id"]
        obj.candidates = [SigningKey.from_string(binascii.unhexlify(sk), curve=SECP256k1) for sk in data["candidates"]]
        obj.voters = [SigningKey.from_string(binascii.unhexlify(sk), curve=SECP256k1) for sk in data["voters"]]
        return obj

def create_rand_vote(candidates_count, voters_count):
    vote = Voting()
    vote.id = random.getrandbits(64)
    vote.candidates = [SigningKey.generate(curve=SECP256k1) for _ in range(candidates_count)]
    vote.voters = [SigningKey.generate(curve=SECP256k1) for _ in range(voters_count)]
    return vote

def write_json_file(data, filename):
    with open(filename, 'w') as f:
        json.dump(data, f)

def read_json_file(filename):
    with open(filename, 'r') as f:
        return json.load(f)

def generate_ethereum_address(seed):
    private_key = hashlib.sha256(seed.encode()).hexdigest()
    public_key = hashlib.sha256(private_key.encode()).hexdigest()
    address = '0x' + public_key[-40:]
    return address

def prepare_solidity_create_args(voting):
    args = {
        "voting_id": generate_ethereum_address(str(voting.id)),
        "candidates": [generate_ethereum_address(sk.verifying_key.to_string().hex()) for sk in voting.candidates]
    }
    return args

def sign_vote(vote_id, candidate_id, voter_key, voter_position):
    candidate_id_str = str(candidate_id)
    sig = voter_key.sign(str(vote_id).encode() + candidate_id_str.encode() +
                         str(voter_position).encode(), hashfunc=hashlib.sha256)
    return binascii.hexlify(sig).decode()

def generate_random_uint256():
    # 生成一个随机的 uint256 范围内的整数
    return random.randint(0, 2**256 - 1)


def prepare_solidity_vote_args(voting):
    args = []
    candidate_ids = [binascii.hexlify(sk.verifying_key.to_string()).decode() for sk in voting.candidates]
    for i, voter in enumerate(voting.voters):
        # 随机选择一个候选者
        selected_candidate = random.choice(voting.candidates)
        selected_candidate_address = generate_ethereum_address(selected_candidate.verifying_key.to_string().hex())

        # 生成随机的 uint256 类型的 Ix、Iy 和 c 的值
        Ix_value = generate_random_uint256()
        Iy_value = generate_random_uint256()
        c_value = generate_random_uint256()

        # 生成选民对所选候选者的签名
        signature = sign_vote(voting.id, selected_candidate, voter, i)
        s_str = ",".join(s for s in signature)
        vote_args = {
            "voter_id": voter.verifying_key.to_string().hex(),
            "candidate_id": selected_candidate_address,
            "Ix": str(Ix_value),
            "Iy": str(Iy_value),
            "c": str(c_value),
            "s": s_str,
            "candidates": candidate_ids,  # 将所有候选人的 ID 存储在 "candidates" 键中
            "threshold": len(voting.voters),
            "ready": "true"
        }
        args.append(vote_args)
    return args



def main():
    rand_vote = create_rand_vote(3, 3)
    write_json_file(rand_vote.to_dict(), 'test.json')

    vote_data = read_json_file('test.json')
    vote_obj = Voting.from_dict(vote_data)

    voting_id = f'"{vote_obj.id}"'

    create_args = prepare_solidity_create_args(vote_obj)
    vote_args = prepare_solidity_vote_args(vote_obj)

    # 写入 solargs.txt
    with open("solargs.txt", 'w') as f:
        f.write("arguments for createVote(...)\n")
        f.write(f'voting_id={voting_id}\n')
        f.write(f'candidates={create_args["candidates"]}\n\n')
        f.write("arguments for addVotersToVote(...)\n")
        f.write(f'voting_id={voting_id}\n')
        allowed_voters_x = [x.strip("\"") for vote_arg in vote_args for x in vote_arg["candidates"]]
        allowed_voters_y = [y.strip("\"") for vote_arg in vote_args for y in vote_arg["candidates"]]
        f.write(f'allowedVotersX={repr(allowed_voters_x)}\n')
        f.write(f'allowedVotersY={repr(allowed_voters_y)}\n')

        f.write(f'threshold={vote_args[0]["threshold"]}\n')
        f.write(f'ready={vote_args[0]["ready"]}\n')

    # 写入 vote.txt
    with open("vote.txt", 'w') as f:
        f.write("arguments for VoteAnnonymous(...)\n\n")
        for i, vote_arg in enumerate(vote_args):
            candidate_id = vote_arg["candidate_id"]
            voter_id = vote_arg["voter_id"]
            f.write(f'Voter {i} votes for candidate {candidate_id}\n')
            f.write(
                f' "{vote_arg["Ix"]}","{vote_arg["Iy"]}","{vote_arg["c"]}","{vote_arg["s"]}"\n')


if __name__ == "__main__":
    main()
