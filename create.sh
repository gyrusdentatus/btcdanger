plorer/LOL$ cat lol.sh 
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
echo -e "${RED}THIS SCRIPT IS NOT RESPONSIBLE FOR LOSING YOUR FUCKING KEYS, NEITHER THE AUTHOR, HANS & GPT. IF THAT HAPPENS, YOU ARE 1337 OR YOU CAN SUE/BLAME SAM ALTMAN. :p"
# Check for OpenSSL
if ! command -v openssl &> /dev/null
then
    echo -e "${RED}OpenSSL could not be found. Installing OpenSSL...${NC}"
    sudo apt-get install openssl
fi

# Check for base58
if ! command -v base58 &> /dev/null
then
    echo -e "${RED}base58 could not be found. Installing base58...${NC}"
    sudo apt-get install base58
fi

# User input for directory name
read -p "Enter directory name to store keys: " DIR
mkdir -p $DIR

# Check if files exist and ask for overwrite permission
if [[ -f "$DIR/private_key.pem" ]] || [[ -f "$DIR/public_key.pem" ]]; then
    read -p "Files already exist in $DIR. Overwrite? (y/n): " OVERWRITE
    if [[ $OVERWRITE != "y" ]]; then
        echo -e "${RED}Exiting without overwriting files.${NC}"
        exit 1
    fi
fi

# Generate Private and Public Keys
openssl ecparam -genkey -name secp256k1 -out $DIR/private_key.pem 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Error generating private key.${NC}"
    exit 1
fi

openssl ec -in $DIR/private_key.pem -pubout -out $DIR/public_key.pem 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Error generating public key.${NC}"
    exit 1
fi

echo -e "${GREEN}Private and Public keys generated and stored in $DIR${NC}"

# Extract the Public Key in Hex
PUBKEY=$(openssl ec -in $DIR/private_key.pem -pubout -outform DER 2>/dev/null | tail -c 65 | xxd -p -c 65)
if [ $? -ne 0 ]; then
    echo -e "${RED}Error extracting public key.${NC}"
    exit 1
fi

# Perform SHA-256 Hashing
SHA256=$(echo $PUBKEY | xxd -r -p | openssl dgst -sha256 -binary 2>/dev/null | xxd -p -c 32)
if [ $? -ne 0 ]; then
    echo -e "${RED}Error in SHA-256 hashing.${NC}"
    exit 1
fi

# Perform RIPEMD-160 Hashing
RIPEMD160=$(echo $SHA256 | xxd -r -p | openssl dgst -ripemd160 -binary 2>/dev/null | xxd -p -c 20)
if [ $? -ne 0 ]; then
    echo -e "${RED}Error in RIPEMD-160 hashing.${NC}"
    exit 1
fi

# Add Network Byte
NETWORK_BYTE="00"
EXTENDED_KEY="${NETWORK_BYTE}${RIPEMD160}"

# Double SHA-256 Checksum
CHECKSUM=$(echo $EXTENDED_KEY | xxd -r -p | openssl dgst -sha256 -binary 2>/dev/null | openssl dgst -sha256 -binary 2>/dev/null | xxd -p -c 32 | cut -c 1-8)
if [ $? -ne 0 ]; then
    echo -e "${RED}Error in SHA-256 checksum.${NC}"
    exit 1
fi

# Append Checksum and Perform Base58 Encoding
FINAL_KEY="${EXTENDED_KEY}${CHECKSUM}"
ADDRESS=$(echo $FINAL_KEY | xxd -r -p | base58)
if [ $? -ne 0 ]; then
    echo -e "${RED}Error in Base58 encoding.${NC}"
    exit 1
fi

echo -e "Your Bitcoin Address: ${GREEN}$ADDRESS${NC}"
echo -e "$ADDRESS${NC}" >> "${DIR}/addr.txt"
