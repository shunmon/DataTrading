import os
import json
import hashlib
import random
import ecdsa
import binascii
from Crypto.Hash import keccak
from Crypto.Random import get_random_bytes

class Voting:
    def __init__(self):
        self.Id = 0
        self.candidates = []
        self.voters = []
        self.Candidates = []
        self.Voters = []

class Vote:
    def __init__(self):
        self.Id = 0
        self.Candidate = ""
        self.PubKeys = []
        self.SignerKey = ecdsa.SigningKey.generate(curve=ecdsa.SECP256k1)
        self.SignerPosition = 0

def create_rand_vote(candidates, voters):
    v = Voting()
    v.Id = random.randint(0, 2**64 - 1)
    v.candidates = rand_private_keys(candidates)
    v.voters = rand_private_keys(voters)
    v.Candidates = keys_to_string(v.candidates)
    v.Voters = keys_to_string(v.voters)
    return v

def keys_to_string(keys):
    return [binascii.hexlify(sk.to_string()).decode() for sk in keys]

def string_to_keys(strings):
    return [ecdsa.SigningKey.from_string(binascii.unhexlify(s), curve=ecdsa.SECP256k1) for s in strings]

def rand_private_keys(n):
    return [ecdsa.SigningKey.generate(curve=ecdsa.SECP256k1) for _ in range(n)]

def main():

    RandVote = create_rand_vote(3, 3)
    RandVote.candidates = keys_to_serializable(RandVote.candidates)
    RandVote.voters = keys_to_serializable(RandVote.voters)

    with open("test.json", "w") as f:
        json.dump(RandVote.__dict__, f, indent=4)

    with open("test.json", "r") as f:
        vote_data = json.load(f)

    vote = Voting()
    vote.__dict__.update(vote_data)
    vote.candidates = string_to_keys(vote.Candidates)
    vote.voters = string_to_keys(vote.Voters)
    prepare_solidity_create_args(vote)
    prepare_solidity_vote_args(vote)

def sign_vote(vote_id, candidate, voter_key, position):
    message = f"{vote_id}{candidate}{voter_key.to_string().hex()}{position}"
    message_hash = keccak.new(data=message.encode(), digest_bits=256).digest()
    signature = voter_key.sign(message_hash)
    return signature

def prepare_solidity_vote_args(voting):
    with open("vote.txt", "w") as f:
        f.write("arguments for VoteAnnonymous(...)\n")
        for pos, voter in enumerate(voting.voters):
            selected_candidate = random.choice(voting.candidates)
            selected_candidate_address = hashlib.sha256(selected_candidate.to_string()).hexdigest()
            Ix_value = generate_random_uint256()
            Iy_value = generate_random_uint256()
            c_value = generate_random_uint256()
            signature = sign_vote(voting.Id, selected_candidate, voter, pos)
            s_str = ",".join(str(s) for s in signature)
            vote_args = {
                "voter_id": binascii.hexlify(voter.to_string()).decode(),
                "candidate_id": selected_candidate_address,
                "Ix": str(Ix_value),
                "Iy": str(Iy_value),
                "c": str(c_value),
                "s": s_str,
                "candidates": voting.Candidates,
                "threshold": len(voting.voters),
                "ready": "true"
            }
            f.write("\n\n")
            f.write(f"Voter {voter.to_string().hex()} votes for candidate {selected_candidate_address}\n")
            for key, value in vote_args.items():
                f.write(f"{key}={value}\n")
def keys_to_serializable(in_keys):
    out_keys = []
    for key in in_keys:
        out_keys.append(key.verifying_key.to_string().hex())
    return out_keys
def prepare_solidity_create_args(voting):
    with open("solargs.txt", "w") as f:
        f.write("arguments for createVote(...)\n")
        f.write(f"Id={voting.Id}\n")
        f.write(f"candidates={voting.Candidates}\n")
        f.write("\narguments for addVotersToVote(...)\n")
        f.write(f"Id={voting.Id}\n")
        f.write(f"voters={voting.Voters}\n")
        f.write(f"threshold={len(voting.voters)}\n")
        f.write("ready=true\n")

def generate_random_uint256():
    return int.from_bytes(get_random_bytes(32), byteorder="big")

if __name__ == "__main__":
    main()
