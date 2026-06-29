# Cairo

Types
+ Scalar/Primitive Types

  - felt252: A field element that can represent integers up to 2^252 - 1. It is the most commonly used type in Cairo for representing numbers.
  - short string: A string type that can hold up to 31 characters. It is used for representing short text values.
  - integer: A type that can represent whole numbers, both positive and negative. It is used for arithmetic operations and counting.
  - bool: A boolean type that can be either true or false.

+ Compound Type

## Deployment

To deploy a Cairo contract, you need to follow these steps:

1. Write your Cairo contract code in a .cairo file.
2. Compile the contract using the Cairo compiler to generate the necessary artifacts for deployment.
3. Use a deployment tool, such as sncast, to deploy the compiled contract to the desired network (e.g., Sepolia).
4. Provide the necessary parameters, such as the contract name and the account to use for deployment.

<!-- sncast --account my_account \
    declare \
    --network sepolia \
    --contract-name HelloSncast

    sncast account create --network --name shogo

     -->

     Account contract: The account contract is a special type of contract in Cairo that represents an account on the blockchain. It is used to manage the ownership and control of the account, as well as to execute transactions and interact with other contracts.
     Deployment of target contract: To deploy a target contract, you need to first declare the contract using the sncast tool. This involves providing the necessary parameters, such as the contract name and the network to deploy on. Once the contract is declared, you can then proceed to deploy it using the same tool, specifying the account to use for deployment and any additional parameters required by the contract.

Success: Account created

Address: 0x0374a224fec9b5af86675b15453cd12238398dc4d6a60f2b387dcbb24baa77ca

Account successfully created but it needs to be deployed. The estimated deployment fee is 0.019653617276340352 STRK. Prefund the account to cover deployment transaction fee

After prefunding the account, run:
sncast account deploy --network sepolia --name shogo

To see account creation details, visit:
account: https://sepolia.voyager.online/contract/0x0374a224fec9b5af86675b15453cd12238398dc4d6a60f2b387dcbb24baa77ca


olorunshogo@olorunshogo:~/Projects/Web3/Cairo/Cairo_class/counter_v1$ sncast account deploy --network sepolia --name shogo
? Do you want to make this account default? ›
❯ Yes, global default (~/.config/starknet-foundry/snf
✔ Do you want to make this account default? · Yes, global default (~/.config/starknet-foundry/snfoundry.toml)
Success: Account deployed

Transaction Hash: 0x64cdcdca264becc5c5c063ad0c12edc128d07bad2b2e5aa215a2b37b90ebd07

To see account deployment details, visit:
transaction: https://sepolia.voyager.online/tx/0x064cdcdca264becc5c5c063ad0c12edc128d07bad2b2e5aa215a2b37b90ebd07

### Accoount Created
olorunshogo@olorunshogo:~/Projects/Web3/Cairo/Cairo_class/counter_v1$ sncast --account sh
ogo declare --network sepolia --contract-name Counter
   Compiling counter_v1 v0.1.0 (/home/olorunshogo/Projects/Web3/Cairo/Cairo_class/counter_v1/Scarb.toml)
    Finished `release` profile target(s) in 2 seconds
Success: Declaration completed

Class Hash:       0x66a429ba6329ffafe50807ff7b8a748f9cbda745792c101bb97d23caf1ad928
Transaction Hash: 0x33af2c62c81ccaaec0b6d15380ae6f0c8307005e9737b05cf4cee80097f6981

To see declaration details, visit:
class: https://sepolia.voyager.online/class/0x066a429ba6329ffafe50807ff7b8a748f9cbda745792c101bb97d23caf1ad928
transaction: https://sepolia.voyager.online/tx/0x033af2c62c81ccaaec0b6d15380ae6f0c8307005e9737b05cf4cee80097f6981

To deploy a contract of this class, run:
sncast --account shogo deploy --class-hash 0x66a429ba6329ffafe50807ff7b8a748f9cbda745792c101bb97d23caf1ad928 --network sepolia

### Account Deployment


