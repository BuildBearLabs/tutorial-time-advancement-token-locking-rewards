SHELL := /bin/bash

# Makefile

.PHONY: install build deploy dd

install:
	@echo "Installing dependencies..."
	forge install

build:
	@echo "Building project..."
	forge build


deploy-sourcify:
	forge script script/SignedQuestManager.Deploy.s.sol \
	--rpc-url buildbear \
	--verifier sourcify \
	--verify --verifier-url https://rpc.buildbear.io/verify/sourcify/server/SANDBOX_ID \
	--broadcast

deploy-etherscan:
	forge script script/SignedQuestManager.Deploy.s.sol \
	--rpc-url buildbear \
	--etherscan-api-key "verifyContract" \
	--verifier-url "https://rpc.buildbear.io/verify/etherscan/SANDBOX_ID" \
	--broadcast \
	--verify

create-new-quest:
	forge script script/CreateQuest.s.sol \
	--rpc-url buildbear \
	--broadcast


claim-quest-reward:
	 forge script script/SignAndClaim.s.sol \
	 --rpc-url buildbear \
	 --broadcast
