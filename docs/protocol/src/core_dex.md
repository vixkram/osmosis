# Spot-Only Decentralized Exchange

This Osmosis fork is a spot-only decentralized automated market maker (AMM) protocol built using Cosmos SDK that represents a flexible building block for programmable liquidity focused exclusively on spot trading.

**This fork removes all leveraged trading capabilities and focuses on secure spot trading only.**

By separating the AMM curve logic and math from the core swapping functionality, this spot-only fork becomes an extensible AMM that can incorporate any number of swap curves and pool types for spot trading. This includes:

- Traditional 50/50  weighted pools
- Custom weights like 80/20 for controlled exposure
- Solidly-style Stableswap curve
- Concentrated Liquidity pools
- CosmWasm pools

