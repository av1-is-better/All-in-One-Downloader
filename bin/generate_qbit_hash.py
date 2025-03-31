#!/usr/local/bin/python3.11

import hashlib
import os
import base64

def generate_qbittorrent_hash():
    # Prompt user for password
    password = os.getenv("GLOBAL_PASSWORD")

    # Generate a random salt
    salt = os.urandom(16)
    iterations = 100000  # Number of iterations
    algorithm = 'sha512' # Hashing algorithm

    # Generate PBKDF2 hash
    dk = hashlib.pbkdf2_hmac(algorithm, password.encode(), salt, iterations)

    # Base64 encode the salt and hash
    encoded_salt = base64.b64encode(salt).decode()
    encoded_hash = base64.b64encode(dk).decode()

    # Format for qBittorrent
    qbittorrent_hash = f'@ByteArray({encoded_salt}:{encoded_hash})'

    return qbittorrent_hash

# Print the result
print(f'WebUI\\Password_PBKDF2="{generate_qbittorrent_hash()}"')
