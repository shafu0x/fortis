include .env

forkAnvil:
	anvil --chain-id 10 --fork-url $(OPTIMISM_INFURA_URL) --auto-impersonate --gas-price 0

deploy:
	forge clean
	forge script script/Deploy.s.sol \
		--broadcast \
		--sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
		--rpc-url http://localhost:8545 \
		-i 1 \
		-vv 