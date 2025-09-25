# Vaultarax

A decentralized treasure hunt protocol on the Stacks blockchain where adventurers create encrypted challenges and others solve cryptographic riddles to unlock multi-token rewards including STX, SIP-010 tokens, and NFTs.

## Overview

Vaultarax combines puzzle-solving with secure smart contract logic to create immersive treasure hunting experiences. Players can create vaults with encrypted clues, set difficulty levels, and watch as the community competes to solve their challenges. The protocol now supports multiple reward types, making it perfect for diverse gaming experiences and community engagement.

## ✨ Features

### Core Functionality
- **Multi-Token Rewards**: Support for STX, SIP-010 tokens, and NFT prizes
- **Cryptographic Security**: SHA-256 hash-based riddle and solution verification
- **Difficulty-Based Expiry**: Smart expiration times based on challenge complexity
- **Anti-Gaming Protection**: Prevents self-solving and double-claiming exploits
- **Flexible Reward Recovery**: Creators can reclaim rewards from expired unsolved vaults

### Advanced Features
- **Token Whitelist Management**: Admin-controlled supported token registry
- **Comprehensive Statistics**: Track user performance across vault creation and solving
- **Dynamic Expiration System**: 
  - Easy (1-2): ~1 week expiry
  - Medium (3): ~1 month expiry  
  - Hard (4-5): ~2 months expiry
- **Community Leaderboards**: Built-in user stats tracking for gamification

## 🏗️ Smart Contract Architecture

The Vaultarax protocol consists of a single, comprehensive core contract:

- **`vaultarax.clar`**: Complete vault ecosystem with multi-token support
  - Vault creation and management
  - Solution verification and reward distribution  
  - User statistics and leaderboard tracking
  - Token whitelist administration

## 🚀 Quick Start

### Prerequisites
```bash
# Install Clarinet
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
clarinet --version
```

### Setup
```bash
git clone https://github.com/your-username/vaultarax.git
cd vaultarax
clarinet check
clarinet test
```

### Local Development
```bash
# Start local devnet
clarinet integrate

# Deploy contracts
clarinet deploy --devnet
```

## 💎 Usage Examples

### Creating Vaults

#### STX Treasure Vault
```clarity
(contract-call? .vaultarax create-stx-vault 
  0x1a2b3c4d... ;; riddle-hash (SHA-256 of your riddle)
  0x5e6f7a8b... ;; solution-hash (SHA-256 of the solution)
  u1000000     ;; 1 STX reward (in microSTX)
  u3           ;; medium difficulty
)
```

#### SIP-010 Token Vault
```clarity
(contract-call? .vaultarax create-sip010-vault
  0x1a2b3c4d... ;; riddle-hash
  0x5e6f7a8b... ;; solution-hash  
  u500         ;; token amount
  .my-token    ;; SIP-010 token contract
  u2           ;; easy difficulty
)
```

#### NFT Treasure Vault
```clarity
(contract-call? .vaultarax create-nft-vault
  0x1a2b3c4d... ;; riddle-hash
  0x5e6f7a8b... ;; solution-hash
  .my-nft      ;; NFT contract
  u42          ;; specific NFT ID
  u4           ;; hard difficulty
)
```

### Solving Vaults
```clarity
(contract-call? .vaultarax solve-vault 
  u1           ;; vault-id
  0x736f6c...  ;; solution (will be hashed and verified)
)
```

### Reclaiming Expired Vaults
```clarity
(contract-call? .vaultarax claim-expired-vault u1)
```

## 📊 Vault Information System

### Query Vault Details
```clarity
;; Get complete vault information
(contract-call? .vaultarax get-vault u1)

;; Check if vault is still active
(contract-call? .vaultarax is-vault-active u1)

;; Get reward information
(contract-call? .vaultarax get-vault-reward-info u1)
```

### User Statistics
```clarity
;; Get user performance stats
(contract-call? .vaultarax get-user-stats 'SP1234...)

;; Check total protocol activity
(contract-call? .vaultarax get-vault-count)
(contract-call? .vaultarax get-total-stx-rewards)
```

## 🔒 Security Features

### Hash-Based Verification
- **Riddle Hash**: SHA-256 hash of the encrypted clue
- **Solution Hash**: SHA-256 hash of the correct answer
- **Tamper Proof**: Immutable verification once vault is created

### Anti-Exploit Mechanisms
- **Self-Solve Prevention**: Creators cannot solve their own vaults
- **Double-Claim Protection**: Solved/expired vaults cannot be claimed again
- **Expiration Logic**: Time-based vault expiry based on difficulty
- **Input Validation**: Comprehensive validation of all user inputs

### Admin Controls
- **Token Whitelisting**: Only approved SIP-010 tokens and NFT collections
- **Contract Ownership**: Secured admin functions for protocol management

## 🧪 Testing

### Run Test Suite
```bash
# Check contract syntax and types
clarinet check

# Run unit tests
clarinet test

# Run integration tests  
clarinet integrate --epoch 2.4
```

### Test Coverage Areas
- Vault creation across all token types
- Solution verification and reward distribution
- Expiration handling and reward recovery
- Edge cases and error conditions
- User statistics tracking
- Admin functions and access control

## 📈 Protocol Statistics

Track key metrics:
- **Total Vaults Created**: Cross all token types
- **Active Vaults**: Currently solvable challenges  
- **Total STX Rewards**: Cumulative STX distributed
- **Top Solvers**: Community leaderboard data
- **Token Support**: Whitelisted asset registry

## 🛠️ Development Workflow

### Contributing Guidelines
1. Fork the repository
2. Create feature branch: `git checkout -b feature/your-feature`
3. Run tests: `clarinet test`
4. Commit changes: `git commit -m "Add your feature"`
5. Push branch: `git push origin feature/your-feature`  
6. Submit pull request with detailed description

### Code Standards
- Follow Clarity best practices and naming conventions
- Include comprehensive test coverage for new features
- Document all public functions with clear comments
- Validate all inputs and handle error cases gracefully

## 🗺️ Future Roadmap

### Phase 1: Enhanced Gaming (Q2 2024)
- **Team Challenges**: Collaborative solving with reward splitting
- **Hint System**: Progressive time-locked clues that reduce rewards
- **Tournament Mode**: Bracket-style competitions with elimination rounds

### Phase 2: Social & Mobile (Q3 2024)  
- **Community Features**: Vault rating, creator profiles, social sharing
- **Mobile API**: REST endpoints for mobile treasure hunt applications
- **GPS Integration**: Location-based clues with augmented reality support

### Phase 3: Advanced Cryptography (Q4 2024)
- **Zero-Knowledge Proofs**: Privacy-preserving solution verification
- **Multi-Signature Puzzles**: Challenges requiring multiple participants  
- **Cross-Referenced Dependencies**: Vaults that unlock other vaults

### Phase 4: Ecosystem Expansion (2025)
- **Governance Token**: $VAULT for protocol governance and premium features
- **Cross-Chain Integration**: Bitcoin Layer 2 and other blockchain support
- **Recurring Vault Series**: Subscription-based challenges with seasonal themes
- **Creator Economy**: Revenue sharing and vault monetization tools
