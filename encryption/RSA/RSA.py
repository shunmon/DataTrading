from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.asymmetric import padding

# 生成秘钥，并保存到文件
def generate_key():
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        #key_size=2048,
        key_size=1024,
        backend=default_backend()
    )
    public_key = private_key.public_key()

    # 存储私钥到文件
    pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    with open('private_key.pem', 'wb') as f:
        f.write(pem)

    # 打印私钥
    print("Private Key:")
    print(pem.decode())

    # 存储公钥到文件
    pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    with open('public_key.pem', 'wb') as f:
        f.write(pem)

    # 打印公钥
    print("\nPublic Key:")
    print(pem.decode())

# 从文件读取秘钥
def load_private_key():
    with open("private_key.pem", "rb") as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None,
            backend=default_backend()
        )
    return private_key

# 加密
def encrypt(message, public_key):
    encrypted = public_key.encrypt(
        message,
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None
        )
    )
    return encrypted

# 解密
def decrypt(encrypted, private_key):
    original_message = private_key.decrypt(
        encrypted,
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None
        )
    )
    return original_message

if __name__ == '__main__':
    # 生成秘钥，并保存到文件
    generate_key()

    # 加载私钥
    private_key = load_private_key()

    # 加密
    message = b'QmPaoos7ZVJuhdcnZwWqMfQQHH8SLagV9xe7SnhCZyc8wB'
    encrypted = encrypt(message, private_key.public_key())
    print("\nEncrypted:", encrypted)

    # 解密
    decrypted = decrypt(encrypted, private_key)
    print("Decrypted:", decrypted.decode())
