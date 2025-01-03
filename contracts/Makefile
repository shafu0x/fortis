include .env

deploy:
	forge clean
	forge script script/Deploy.s.sol \
		--broadcast \
		--sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
		-i 1 \
		-vvvv 

forkAnvil:
	anvil --chain-id 10 --fork-url $(OPTIMISM_INFURA_URL) --auto-impersonate --gas-price 0