# Foundry


##
`forge`: Build, test, debug, deploy, and verify smart contracts
`cast`: Interact with contracts, send transactions, and query chain data
`anvil`:	Run a local Ethereum node with forking capabilities	Reference
`chisel`:	Solidity REPL for rapid prototyping

### Remappings
Customize import paths with remappings in `foundry.toml`:

```foundry.toml
[profile.default]
remappings = [
  "@openzeppelin/=lib/openzeppelin-contracts/",
]
```

### Soldeer
Soldeer is a Solidity-native package manager that provides an alternative to git submodules. It offers versioned dependencies, a package registry, and simpler dependency management.

#### Installation
Soldeer comes bundled with Foundry. Initialize it in your project:

```solidity
$ forge soldeer init
```
This creates a `soldeer.toml` configuration file.

```solidity
[soldeer]
remappings_generate = true
remappings_regenerate = false
remappings_version = true
remappings_prefix = "@"
remappings_location = "config"

[dependencies]
"@openzeppelin-contracts" = "5.0.0"
"@solmate" = "6.7.0"
```

<!-- git log --oneline --graph --decorate --all -->
