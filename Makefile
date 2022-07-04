all: update install build

# Update Dependencies
update:; forge update

# Install the Modules
install :; forge install

# Build project
build :; forge build

# Tests
test:; forge test
test-full:; forge test -vvvv
test-gas:; forge test --gas-report