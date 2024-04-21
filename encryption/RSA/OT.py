# 1-out-of-n OT


import random
from Crypto.Util.number import getPrime

# 生成一个大素数
def generate_prime(bits):
    return getPrime(bits)

# 生成随机数
def generate_random_number(bits):
    return random.getrandbits(bits)

# 计算 g^x mod p
def mod_exp(g, x, p):
    return pow(g, x, p)

# 生成 g 和 p，其中 g 是 p 的原根
def generate_gp(bits):
    p = generate_prime(bits)
    g = random.randint(2, p - 1)
    while pow(g, (p - 1) // 2, p) == 1 or pow(g, 2, p) == 1:
        g = random.randint(2, p - 1)
    return g, p

# Alice 生成发送给 Bob 的数据
def generate_data(g, p, n):
    data = []
    for i in range(n):
        xi = generate_random_number(256) # 生成随机数 xi
        yi = mod_exp(g, xi, p) # 计算 g^xi mod p
        data.append(yi)
    return data

# Bob 选择一个选项并获取相应的数据
def choose_data(data, choice):
    return data[choice]

# Bob 生成一个随机数并计算 C = g^r mod p
def generate_ciphertext(g, p):
    r = generate_random_number(256)
    C = mod_exp(g, r, p)
    return C, r

# Bob 解密获取选择的数据
def decrypt_data(C, r, yi, p):
    return (yi * pow(C, -r, p)) % p

# 测试
def text():
    # 生成 g 和 p
    g, p = generate_gp(1024)

    # Alice 生成数据
    n = 5 # 数据个数
    data = generate_data(g, p, n)

    # Bob 选择一个选项
    choice = random.randint(0, n - 1)

    # Bob 生成一个随机数并计算 C
    C, r = generate_ciphertext(g, p)

    # Bob 获取选择的数据
    selected_data = choose_data(data, choice)

    # Bob 解密获取选择的数据
    decrypted_data = decrypt_data(C, r, selected_data, p)

    print("Bob 选择的选项:", choice)
    print("Bob 解密后得到的数据:", decrypted_data)

if __name__ == "__main__":
    text()
