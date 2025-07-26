-include .env

.PHONY: deploy enter balance state lastTimestamp

install:; forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 && forge install foundry-rs/forge-std@v1.9.7 && forge install Cyfrin/foundry-devops@0.4.0

NETWORK_ARGS := --rpc-url $(LOCAL_RPC_URL) --private-key $(LOCAL_PRIVATE_KEY) --broadcast
CAST_SEND_NETWORK_ARGS := --rpc-url $(LOCAL_RPC_URL) --private-key $(LOCAL_PRIVATE_KEY) --broadcastent
CAST_CALL_NETWORK_ARGS := --rpc-url $(LOCAL_RPC_URL)
ifeq ($(findstring sepolia,$(ARGS)),sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_KEY)
	CAST_SEND_NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast
	CAST_CALL_NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL)
endif

deploy:;
	forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)

enter:;
	forge script script/Interactions.s.sol:RaffleEnter $(CAST_SEND_NETWORK_ARGS)

balance:;
	forge balance $(CAST_CALL_NETWORK_ARGS)

state:;
	forge script script/Interactions.s.sol:RaffleGetRaffleState $(CAST_CALL_NETWORK_ARGS)

checkUpkeep:;
	forge script script/Interactions.s.sol:RaffleCheckUpkeep $(CAST_CALL_NETWORK_ARGS)

lastTimestamp:;
	forge script script/Interactions.s.sol:RaffleGetLastTimestamp $(CAST_CALL_NETWORK_ARGS)

entranceFee:;
	forge script script/Interactions.s.sol:RaffleGetEntranceFee $(CAST_CALL_NETWORK_ARGS)

player:;
	forge script script/Interactions.s.sol:RaffleGetPlayer $(CAST_CALL_NETWORK_ARGS)

lastWinner:;
	forge script script/Interactions.s.sol:RaffleGetLastWinner $(CAST_CALL_NETWORK_ARGS)
