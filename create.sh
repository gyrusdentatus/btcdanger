#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# User input for directory name
read -p "Enter directory name to store keys: " DIR
mkdir -p $DIR

# Generate Private and Public Keys
openssl ecparam -genkey -name secp256k1 -out $DIR/private_key.pem
openssl ec -in $DIR/private_key.pem -pubout -out $DIR/public_key.pem

echo -e "${GREEN}Private and Public keys generated and stored in $DIR${NC}"

# Extract the Public Key in Hex
PUBKEY=$(openssl ec -in $DIR/private_key.pem -pubout -outform DER | tail -c 65 | xxd -p -c 65)

# Perform SHA-256 Hashing
SHA256=$(echo $PUBKEY | xxd -r -p | openssl dgst -sha256 -binary | xxd -p -c 32)

# Perform RIPEMD-160 Hashing
RIPEMD160=$(echo $SHA256 | xxd -r -p | openssl dgst -ripemd160 -binary | xxd -p -c 20)

# Add Network Byte
NETWORK_BYTE="00"
EXTENDED_KEY="${NETWORK_BYTE}${RIPEMD160}"

# Double SHA-256 Checksum
CHECKSUM=$(echo $EXTENDED_KEY | xxd -r -p | openssl dgst -sha256 -binary | openssl dgst -sha256 -binary | xxd -p -c 32 | cut -c 1-8)

# Append Checksum and Perform Base58 Encoding
FINAL_KEY="${EXTENDED_KEY}${CHECKSUM}"
ADDRESS=$(echo $FINAL_KEY | xxd -r -p | base58)

echo -e "Your Bitcoin Address: ${GREEN}$ADDRESS${NC}"
echo -e "$ADDRESS${NC}" >> "${DIR}/addr.txt"
