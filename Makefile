all: update install build

# Update Dependencies
update:; forge update

# Install the Modules
install :; forge install

# Build project
build :; forge build

# Tests
test:; forge test --optimize
test-full:; forge test --optimize -vvvv
test-gas:; forge test --optimize --gas-report