from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hmac
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
import os

def generate_ec_key_pair():
    # Generate ECC key pair
    private_key = ec.generate_private_key(ec.SECP256R1(), default_backend())
    public_key = private_key.public_key()
    return private_key, public_key

def generate_shared_secret(private_key, public_key):
    # Derive shared secret
    shared_secret = private_key.exchange(ec.ECDH(), public_key)
    return shared_secret

def encrypt_data(data, shared_secret):
    # Generate a random initialization vector
    iv = os.urandom(16)

    # Derive encryption key from shared secret using HKDF
    derived_key = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=None,
        info=b'',
        backend=default_backend()
    ).derive(shared_secret)

    # Encrypt data using AES in GCM mode
    encryptor = Cipher(algorithms.AES(derived_key), modes.GCM(iv), backend=default_backend()).encryptor()
    ciphertext = encryptor.update(data) + encryptor.finalize()

    # Return IV and ciphertext
    return iv, ciphertext, encryptor.tag

def decrypt_data(iv, ciphertext, tag, shared_secret):
    # Derive decryption key from shared secret using HKDF
    derived_key = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=None,
        info=b'',
        backend=default_backend()
    ).derive(shared_secret)

    # Decrypt data using AES in GCM mode
    decryptor = Cipher(algorithms.AES(derived_key), modes.GCM(iv, tag), backend=default_backend()).decryptor()
    decrypted_data = decryptor.update(ciphertext) + decryptor.finalize()

    return decrypted_data

def ecc_sign(message, private_key):
    # 使用 ECC 私钥对消息进行签名
    signature = private_key.sign(
        message,
        ec.ECDSA(hashes.SHA256())
    )
    return signature

def ecc_verify(message, signature, public_key):
    # 使用 ECC 公钥验证消息的签名
    try:
        public_key.verify(
            signature,
            message,
            ec.ECDSA(hashes.SHA256())
        )
        return True
    except Exception as e:
        print("Verification failed:", e)
        return False


if __name__ == "__main__":
    # 生成 Alice 和 Bob 的 ECC 密钥对，并输出它们的公钥和私钥。
    # Generate key pair for Alice
    alice_private_key, alice_public_key = generate_ec_key_pair()

    # Generate key pair for Bob
    bob_private_key, bob_public_key = generate_ec_key_pair()

    # Output Alice's public and private keys
    alice_private_pem = alice_private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    alice_public_pem = alice_public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    print("Alice's private key:\n", alice_private_pem.decode())
    print("Alice's public key:\n", alice_public_pem.decode())

    # Output Bob's public and private keys
    bob_private_pem = bob_private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    bob_public_pem = bob_public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    print("\nBob's private key:\n", bob_private_pem.decode())
    print("Bob's public key:\n", bob_public_pem.decode())

    # Alice 将她的公钥发送给 Bob. Bob 使用 Alice 的公钥和自己的私钥生成共享密钥。
    # Alice sends her public key to Bob
    shared_secret = generate_shared_secret(bob_private_key, alice_public_key)


    # Encrypt data using shared secret
    plaintext = b"Hello, Bob!"
    iv, ciphertext, tag = encrypt_data(plaintext, shared_secret)

    # Output encrypted ciphertext
    print("\nEncrypted ciphertext:")
    print("IV:", iv.hex())
    print("Ciphertext:", ciphertext.hex())
    print("Tag:", tag.hex())

    # Alice decrypts data using shared secret
    decrypted_data = decrypt_data(iv, ciphertext, tag, shared_secret)

    print("\nDecrypted data:", decrypted_data.decode())
