## Uniswap <> zkFi adaptor 🔌
The adaptor implements `zkFi::IConvertProxy` interface to allow users to route their Uniswap swaps using zkFi's privacy layer.

## Usage

### Build

```shell
$ forge build
```

> You will also have to upgrade the Uniswap's `ISwapRouter` and `TransferHelper` contract versions to `0.8.23` to avoid solc compiler version incompatibility issues before building the project.

### Test on Anvil mainnet fork
```shell
$ anvil --fork-url $(CHAIN_NODE_URL) --fork-block-number 19846421 --fork-chain-id 1 --chain-id 1
$ make test
```

### Deploy

```
make deploy
```