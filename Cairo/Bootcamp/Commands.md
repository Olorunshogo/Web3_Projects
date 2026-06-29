
# Commands

```bash
sncast account list
```

1. Create account
```bash
sncast \
    account create \
    --network sepolia \
    --name new_account

```

2. Deploy the account:
```bash
sncast \
    account deploy \
    --network sepolia \
    --name new_account

```
NOTE: This command will throw an error if not funded before running it.

Transaction Hash: 0x47608b4ee66a29f8df418879f00b9fcd2927b6fef4e5905e1b27f6b04729c7b

3. Get Balance:
```bash
sncast --account cairo_account get balance --network sepolia
```

4. Declare this contract:

sncast --account my_account \
    declare \
    --network sepolia \
    --contract-name HelloSncast

--account cairo_account declare --network sepolia --contract-name Counter

```text
Compiling lib(starknet_contracts) starknet_contracts v0.1.0 (/home/olorunshogo/Projects/Web3/Cairooo/cairo-bootcamp-6/starknet_contracts/Scarb.toml)
warn: artefacts produced by this build may be hard to utilize due to the build configuration
please make sure your build configuration is correct
help: if you want to use your build with a specialized tool that runs Sierra code (for
instance with a test framework like Forge), please make sure all required dependencies
are specified in your package manifest.
help: if you want to compile a Starknet contract, make sure to use the `starknet-contract`
target, by adding following excerpt to your package manifest
-> Scarb.toml
    [[target.starknet-contract]]
help: if you want to read the generated Sierra code yourself, consider enabling
the debug names, by adding the following excerpt to your package manifest.
-> Scarb.toml
    [cairo]
    sierra-replace-ids = true
   Compiling starknet-contract(starknet_contracts) starknet_contracts v0.1.0 (/home/olorunshogo/Projects/Web3/Cairooo/cairo-bootcamp-6/starknet_contracts/Scarb.toml)
    Finished `release` profile target(s) in 9 seconds
Success: Declaration completed

Class Hash:       0x7fad7c689303db38f7acbdab3488e9e62493667635fa96a0ba1f0b81e956a22
Transaction Hash: 0x19ec4c8cd578263fc28bb402420d6980db29e31d3788d6a07b26e1276c1955e

To see declaration details, visit:
class: https://sepolia.voyager.online/class/0x07fad7c689303db38f7acbdab3488e9e62493667635fa96a0ba1f0b81e956a22
transaction: https://sepolia.voyager.online/tx/0x019ec4c8cd578263fc28bb402420d6980db29e31d3788d6a07b26e1276c1955e

To deploy a contract of this class, replace the placeholders in `--arguments` with your actual values, then run:
sncast --account cairo_account deploy --class-hash 0x7fad7c689303db38f7acbdab3488e9e62493667635fa96a0ba1f0b81e956a22 --arguments '<owner: ContractAddress>' --network sepolia
```

You can fetch it from Starknet instance using this command:
```bash
sncast --account my_account \
    declare-from \
    --class-hash 0x283a4f96ee7de15894d9205a93db7cec648562cfe90db14cb018c039e895e78 \
    --source-network sepolia \
    --url http://127.0.0.1:5055/rpc
```

4. Deploy the contract:

```bash
sncast \
    --account my_account \
    deploy \
    --network sepolia \
    --class-hash 0x0227f52a4d2138816edf8231980d5f9e6e0c8a3deab45b601a1fcee3d4427b02
```

5. Call the get count function:
```bash
sncast call --network sepolia --contract-address 0x070b299a5852d3ff6342e8480ff345cee294a31a80acd770eed80c7d1e088c1c --function get_count
```

6. Call the get owner function:
```bash
sncast call --network sepolia --contract-address 0x070b299a5852d3ff6342e8480ff345cee294a31a80acd770eed80c7d1e088c1c --function get_owner
```

7. Invoke the increase_count function:
```bash
sncast invoke --network sepolia --contract-address 0x070b299a5852d3ff6342e8480ff345cee294a31a80acd770eed80c7d1e088c1c --function increase_count --calldata 10
```

8. Invoke the decrease_count function:
```bash
sncast invoke --network sepolia --contract-address 0x070b299a5852d3ff6342e8480ff345cee294a31a80acd770eed80c7d1e088c1c --function decrease_count --calldata 5
```

9. Invoke the reset_count function:
```bash
sncast invoke --network sepolia --contract-address 0x070b299a5852d3ff6342e8480ff345cee294a31a80acd770eed80c7d1e088c1c --function reset_count
```

- Send funds from `shogo` -> `cairo_account`:
```bash
sncast invoke \
  --account shogo \
  --network sepolia \
  --contract-address <ETH_OR_STRK_TOKEN_ADDRESS> \
  --function transfer \
  --calldata <cairo_account_address> <amount>
```

sncast deploy \
  --network alpha-sepolia \
  --account cairo_account \
  --class-hash 0x7fad7c689303db38f7acbdab3488e9e62493667635fa96a0ba1f0b81e956a22 \
  --constructor-calldata 0x198ba527bb28bebefddf52f2609c35dd91a769a3fea12492267e7b443525c98

```text
olorunshogo@olorunshogo:~/Projects/Web3/Cairooo/cairo-bootcamp-6/starknet_contracts$ sncast --account cairo_account deploy --network sepolia --class-hash 0x7fad7c689303db38f7acbdab3488e9e62493667635fa96a0ba1f0b81e956a22 --constructor-calldata 0x198ba527bb28bebefddf52f2609c35dd91a769a3fea12492267e7b443525c98
Success: Deployment completed

Contract Address: 0x070b299a5852d3ff6342e8480ff345cee294a31a80acd770eed80c7d1e088c1c
Transaction Hash: 0x017859ccccf6918e416c5f2c2b43f0868e1d2057c73cf1b9cf5aa464fe1e4dac

To see deployment details, visit:
contract: https://sepolia.voyager.online/contract/0x070b299a5852d3ff6342e8480ff345cee294a31a80acd770eed80c7d1e088c1c
transaction: https://sepolia.voyager.online/tx/0x017859ccccf6918e416c5f2c2b43f0868e1d2057c73cf1b9cf5aa464fe1e4dac

```
Get current count:
sncast call \
  --network alpha-sepolia \
  --contract-address <YOUR_CONTRACT_ADDRESS> \
  --function get_count

Get Owner:
sncast call \
  --network alpha-sepolia \
  --contract-address <YOUR_CONTRACT_ADDRESS> \
  --function get_owner

Increase Count:
sncast invoke \
  --network alpha-sepolia \
  --account cairo_account \
  --contract-address <YOUR_CONTRACT_ADDRESS> \
  --function increase_count \
  --calldata 5

Decrease Count:
sncast invoke \
  --network alpha-sepolia \
  --account cairo_account \
  --contract-address <YOUR_CONTRACT_ADDRESS> \
  --function decrease_count \
  --calldata 2


