# Tests

A contract is a logic on-chain that performs CRUD operations on state variables.
Upon deployment, contsructtors need to be tested for its states.

These are the steps to help us test adequately.
+ Deployment
  - Tests for all default variables/values during deployments
  - Test for all view functions
  - Test for reader function for private too
+ Transactions
  - You may start with Vaidations - require and checks
  - inc()
  - incBy()
  - decrease()
+ Events

If you're putting money, toWei (parseEther), if you're getting money, igNumberish fromWei to 1.

# Assignment
Have an util function that loops through the array of vaults to get all the instances
Deposit multiple times





