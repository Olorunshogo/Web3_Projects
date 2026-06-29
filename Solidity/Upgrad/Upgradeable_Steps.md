# Steps

1. Initialize a new foundry project and run the following commands:

Installation using open zeppelin v5:

```bash
  forge install foundry-rs/forge-std
  forge install OpenZeppelin/openzeppelin-foundry-upgrades
  forge install OpenZeppelin/openzeppelin-contracts-upgradeable
```
2. Set the following in the remappings.txt file:

```bash
  forge-std/=lib/forge-std/src/
  @openzeppelin/contracts/=lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/
  @openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/
```

3. Deploy a proxy
Deploy a UUPS proxy:

```bash
  forge script script/DeployProxy.s.sol --broadcast

  address proxy = Upgrades.deployUUPS
```


