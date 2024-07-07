# Deployment And Configuration Procedures

It would be advisable to deploy all `YardRouter` to the same address across all chains.

1. Get `FEE_TOKEN` address.
2. Deploy `YardNFTWrapper` contract.
3. Deploy `YardFactory` contract.
4. Deploy `YardRouter` contract using the address of `FEE_TOKEN` and `YardNFTWrapper`.
5. Set `YardFactory` in `YardRouter` using the `setFactory()` function.
6. Set `YardFactory` in `YardNFTWrapper` using the `setFactory()` function.
7. Set `YardRouter` in `YardFactory` using the `setRouter()` function.
8. Set `YardNFTWrapper` in `YardFactory` using the `setWrapper()` function.
9. Do not deploy the `YardPair`.