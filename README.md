# BuildBear Time Advancement Plugin Tutorial

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

### Fork Test

#### Base Mainnet

```solidity
forge test --match-path test/QuestManager/Base.QuestManagerTest.t.sol --fork-url "https://base.meowrpc.com" -vvv
```

### Deploying

#### Polygon Amoy

```solidity
forge script script/SignedQuestManager.Deploy.s.sol --rpc-url polygon_amoy --verify  --private-key $PRIVATE_KEY --broadcast
```

#### Base Sepolia

```solidity
forge script script/testnet/Base.SignedQuestManager.Deploy.s.sol --rpc-url base_sepolia --verify  --private-key $PRIVATE_KEY --broadcast
```

#### ETH Sepolia

```solidity
forge script script/testnet/Sepolia.SignedQuestManager.Deploy.s.sol --rpc-url eth_sepolia --verify  --private-key $PRIVATE_KEY --broadcast --legacy
```
