-include .env

.PHONY: all test clean deploy-anvil

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install smartcontractkit/chainlink-brownie-contracts && forge install rari-capital/solmate && forge install foundry-rs/forge-std && forge install openzeppelin/openzeppelin-contracts && forge install dapphub/ds-test

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

# use the "@" to hide the command from your shell 
deploy-fuji :; @forge create --rpc-url ${FUJI_RPC_URL} \
    --constructor-args \
	428  \
	0x2eD832Ba664535e5886b75D64C46EB9a228C2610 \
	0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 \
	0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61 \
    --private-key ${PRIVATE_KEY} src/Contract.sol:TLCNFT \
    --etherscan-api-key ${SNOWTRACE_API_KEY} \
    --verify
