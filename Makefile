all: update build

# Update Dependencies
update:; forge update

# Install the Modules
install :; forge install

# Tests
test:; forge test --optimize
test-fullv:; forge test --optimize -vvvv
test-gas:; forge test --optimize --gas-report

.PHONY: test build