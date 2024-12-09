# CAPOEP - Community Attested Proof of Education Protocol

CAPOEP is a decentralized protocol that enables community-driven verification of educational achievements. Users can create listings of their educational accomplishments, which are then verified through community attestations.

## Features

- **Educational Listings**: Create and manage educational achievement listings
- **Community Attestation**: Get achievements verified by community votes
- **Dual Comment System**: Separate systems for general comments and vote-comments
- **Reputation System**: Dynamic reputation points based on community interaction
- **Version Control**: Update and link different versions of achievements
- **NFT Minting**: Convert verified achievements into NFTs

## Smart Contracts

The protocol consists of several modular components:

- `CAPOEP.sol`: Main contract integrating all modules
- `ListingModule.sol`: Manages educational achievement listings
- `VotingModule.sol`: Handles attestations and refutations
- `CommentsModule.sol`: Implements dual commenting system
- `ReputationModule.sol`: Manages user reputation points
- `MetadataModule.sol`: Handles NFT metadata generation

## Getting Started

### Prerequisites

- Node.js v18+
- npm or yarn
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/capoep.git
cd capoep/hardhat
```

2. Install dependencies:
```bash
npm install
```

3. Copy environment variables:
```bash
cp env.sample .env
```

4. Configure your `.env` file with appropriate values:
- Add your private key
- Add API keys for Alchemy, Etherscan, etc.

### Development

1. Compile contracts:
```bash
npm run compile
```

2. Run tests:
```bash
npm test
```

3. Run test coverage:
```bash
npm run coverage
```

4. Start local node:
```bash
npm run node
```

### Deployment

1. Deploy to local network:
```bash
npm run deploy:local
```

2. Deploy to testnet (Sepolia):
```bash
npm run deploy:sepolia
```

3. Deploy to testnet (Mumbai):
```bash
npm run deploy:mumbai
```

### Contract Verification

After deployment, verify contracts on the blockchain explorer:

1. For Sepolia:
```bash
npm run verify:sepolia
```

2. For Mumbai:
```bash
npm run verify:mumbai
```

## Usage

### Creating a Listing

```typescript
const title = "Learning Solidity";
const details = "Completed advanced Solidity course";
const proofs = ["https://proof1.com"];
const category = "Learning";

await capoep.createListing(title, details, proofs, category);
```

### Voting on a Listing

```typescript
const listingId = 0;
const isAttest = true;
const comment = "Verified the course completion";

await capoep.castVote(listingId, isAttest, comment);
```

### Adding Comments

```typescript
const listingId = 0;
const content = "Great achievement!";
const parentId = 0; // 0 for top-level comments

await capoep.addComment(listingId, content, parentId);
```

### Minting NFT

```typescript
const listingId = 0;
await capoep.mintFromListing(listingId);
```

## Testing

The project includes comprehensive tests for all functionality:

- Unit tests for each module
- Integration tests for the complete system
- Gas usage reports
- Coverage reports

Run the full test suite:
```bash
npm test
```

## Security

- All contracts use OpenZeppelin's secure implementations
- Comprehensive access control
- Reputation-based voting restrictions
- State validation checks
- Reentrancy protection

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
