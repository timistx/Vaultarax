# Vaultarax

A decentralized treasure hunt protocol on the Stacks blockchain where adventurers create encrypted challenges and others solve cryptographic riddles to unlock STX rewards.

## Overview

Vaultarax combines puzzle-solving with secure smart contract logic to create immersive treasure hunting experiences. Players can create vaults with encrypted clues, set difficulty levels, and watch as the community competes to solve their challenges.

## Features

- **Vault Creation**: Deploy treasure vaults with custom riddles and STX rewards
- **Cryptographic Challenges**: Multi-layered puzzle system with hash-based verification
- **Fair Distribution**: Transparent reward mechanisms with anti-gaming protections
- **Community Events**: Perfect for gamified marketing and educational challenges
- **Leaderboard System**: Track top treasure hunters and vault creators

## Smart Contracts

- `vaultarax-core.clar`: Main vault creation and solving logic
- `vaultarax-registry.clar`: Vault discovery and metadata management
- `vaultarax-rewards.clar`: Reward distribution and leaderboard tracking

## Quick Start

1. Clone the repository
2. Install Clarinet: `clarinet --version`
3. Run tests: `clarinet test`
4. Deploy locally: `clarinet integrate`

## Usage

### Creating a Vault
```clarity
(contract-call? .vaultarax-core create-vault 
  "Your cryptographic riddle" 
  u1000000 ;; 1 STX reward
  u3 ;; difficulty level
)
```

### Solving a Vault
```clarity
(contract-call? .vaultarax-core solve-vault 
  u1 ;; vault-id
  "solution-hash"
)
```

## Testing

Run the complete test suite:
```bash
clarinet test
clarinet check
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make meaningful commits
4. Submit a pull request


## Future Roadmap

1. **Multi-Token Rewards**: Support BTC, custom SIP-010 tokens, and NFT prizes beyond STX for diverse treasure hunt experiences
2. **Team Challenges**: Enable collaborative vault solving with automatic reward splitting among team members and group leaderboards
3. **Recurring Vaults**: Implement subscription-based vaults that reset periodically with new riddles, creating ongoing treasure hunt series
4. **Dynamic Hint System**: Time-locked hint reveals that progressively reduce reward amounts, balancing accessibility with challenge difficulty
5. **Tournament Mode**: Bracket-style competitions with elimination rounds, grand prizes, and seasonal championship events
6. **Social Features**: Vault rating system, creator profiles, community leaderboards, and social sharing of successful solves
7. **Advanced Cryptography**: Support for zero-knowledge proofs, multi-signature puzzles, and cross-referenced challenge dependencies
8. **Mobile Integration**: REST API endpoints for mobile treasure hunt apps with GPS integration and augmented reality clues
9. **Governance Token**: $VAULT token for protocol governance, premium feature access, and community-driven vault curation
10. **Cross-Chain Bridges**: Enable treasure hunts across Bitcoin Layer 2 networks and integration with other blockchain ecosystems

