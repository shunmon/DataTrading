from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
from Crypto.Random import get_random_bytes

# 定义文件内容和属性
file_contents = {
    "file1": {"attribute": "blood sugar", "data": [0.2, 0.5, 0.6]},
    "file2": {"attribute": "blood pressure", "data": [100, 200, 300]}
}

# 定义加密密钥
file_keys = {
    "file1": get_random_bytes(16),
    "file2": get_random_bytes(16)
}

# 加密文件
def encrypt_file(content, key):
    cipher = AES.new(key, AES.MODE_CBC)
    ciphertext = cipher.encrypt(pad(content.encode(), AES.block_size))
    return cipher.iv, ciphertext

# 解密文件（仅当用户购买了特定属性时）
def decrypt_file(iv, ciphertext, attribute, key):
    if attribute in file_contents.values():
        cipher = AES.new(key, AES.MODE_CBC, iv)
        plaintext = unpad(cipher.decrypt(ciphertext), AES.block_size)
        return plaintext.decode()
    else:
        return "Access Denied"

# 模拟购买者输入要购买的属性
def simulate_user_purchase():
    purchased_attribute = input("Enter the attribute you want to purchase (e.g., blood sugar, blood pressure): ")
    return purchased_attribute

# 模拟购买者尝试解密文件
def simulate_user_decryption(purchased_attribute, file_iv, file_ciphertext, file_key):
    decrypted_content = decrypt_file(file_iv, file_ciphertext, purchased_attribute, file_key)
    print("Decrypted Content:", decrypted_content)

# 加密并分别保存两个文件
file1_iv, file1_ciphertext = encrypt_file(','.join(map(str, file_contents["file1"]["data"])), file_keys["file1"])
file2_iv, file2_ciphertext = encrypt_file(','.join(map(str, file_contents["file2"]["data"])), file_keys["file2"])

# 模拟购买者尝试解密文件
purchased_attribute = simulate_user_purchase()
if purchased_attribute == file_contents["file1"]["attribute"]:
    simulate_user_decryption(purchased_attribute, file1_iv, file1_ciphertext, file_keys["file1"])
elif purchased_attribute == file_contents["file2"]["attribute"]:
    simulate_user_decryption(purchased_attribute, file2_iv, file2_ciphertext, file_keys["file2"])
else:
    print("Attribute not found. Access Denied.")
