from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
from RSA import generate_key as generate_rsa_key, encrypt as rsa_encrypt, decrypt as rsa_decrypt
from ECC import generate_ec_key_pair as generate_ec_key, ecc_sign, ecc_verify, generate_shared_secret, encrypt_data, decrypt_data
import os
import random

# 生成环签名
def ring_signature(message, ecc_private_keys, rsa_public_keys):
    num_keys = len(ecc_private_keys)
    ring_order = list(range(num_keys))
    random.shuffle(ring_order)

    r = [None] * num_keys
    s = [None] * num_keys

    for i in range(num_keys):
        index = ring_order[i]
        ecc_private_key = ecc_private_keys[index]
        rsa_public_key = rsa_public_keys[index]

        # 使用ECC私钥签名
        r[i] = ecc_sign(message, ecc_private_key)

        # 使用RSA公钥加密ECC签名
        s[i] = rsa_encrypt(r[i], rsa_public_key)

    return r, s

# 验证环签名
def verify_ring_signature(message, r, s, ecc_public_keys, rsa_private_keys):
    num_keys = len(ecc_public_keys)

    for i in range(num_keys):
        ecc_public_key = ecc_public_keys[i]
        rsa_private_key = rsa_private_keys[i]

        # 使用RSA私钥解密ECC签名
        decrypted_r = rsa_decrypt(s[i], rsa_private_key)

        # 使用ECC公钥验证解密后的ECC签名
        if not ecc_verify(message, decrypted_r, ecc_public_key):
            return False

    return True

if __name__ == "__main__":
    # 生成 RSA 密钥对和 ECC 密钥对
    rsa_private_key1, rsa_public_key1 = generate_rsa_key()
    rsa_private_key2, rsa_public_key2 = generate_rsa_key()
    ecc_private_key1, ecc_public_key1 = generate_ec_key()
    ecc_private_key2, ecc_public_key2 = generate_ec_key()

    # 消息
    message = b"Hello, world!"

    # 环签名
    r, s = ring_signature(message, [ecc_private_key1, ecc_private_key2], [rsa_public_key1, rsa_public_key2])
    print("r",r,"\n", "s",s)
    # 验证环签名
    verified = verify_ring_signature(message, r, s, [ecc_public_key1, ecc_public_key2], [rsa_private_key1, rsa_private_key2])

    if verified:
        print("Ring signature verified successfully!")
    else:
        print("Failed to verify ring signature.")
