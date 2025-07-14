# Escrow Freelance Contract System

A comprehensive smart contract system built on the Stacks blockchain for managing freelance work agreements with built-in reputation tracking.

## Features

### Enhanced Escrow Contract
- **Milestone-based payments**: Track project progress through milestones
- **Deadline management**: Automatic release after deadline expiry
- **Dispute resolution**: Built-in dispute raising mechanism
- **Emergency release**: Freelancer can claim funds after deadline
- **Project cancellation**: Client can cancel and get refund before work completion
- **Security improvements**: Enhanced validation and error handling

### Reputation Management
- **Rating system**: 1-5 star rating system for both clients and freelancers
- **Average score calculation**: Automatic calculation of reputation scores
- **Project completion tracking**: Track completed projects for each user
- **Comment system**: Leave detailed feedback with ratings

## Bug Fixes from Phase 1

1. **Fixed initialization bug**: Added proper contract initialization with project details
2. **Enhanced validation**: Added comprehensive input validation and error handling
3. **Security improvements**: Added checks for self-transactions and duplicate operations
4. **State management**: Improved state variable management and consistency

## New Security Features

- **Deadline enforcement**: Prevents late releases and ensures timely payments
- **Dispute mechanism**: Both parties can raise disputes for conflict resolution
- **Emergency release**: Protects freelancers from non-paying clients
- **Reputation system**: Incentivizes good behavior through reputation tracking
- **Enhanced error handling**: Comprehensive error codes and validation

## Contract Architecture

### Escrow Contract (`contracts/escrow.clar`)
- Manages the core escrow functionality
- Handles fund transfers and milestone tracking
- Implements security checks and deadline management

### Reputation Contract (`contracts/reputation.clar`)
- Tracks user reputation scores
- Manages project ratings and feedback
- Calculates average ratings and completion statistics

## Usage

### For Clients

1. **Initialize Project**: Set up a new freelance project with details
```clarity
(contract-call? .escrow initialize-project 
  'SP1FREELANCER-ADDRESS 
  u1000000  ;; 1 STX in microSTX
  u1000     ;; Deadline block height
  "Website Development" 
  u3)       ;; 3 milestones
```

2. **Fund Escrow**: Deposit STX tokens into escrow
```clarity
(contract-call? .escrow fund-escrow)
```

3. **Release Funds**: Release funds when work is completed
```clarity
(contract-call? .escrow release-funds)
```

4. **Rate Freelancer**: Leave feedback after project completion
```clarity
(contract-call? .reputation rate-user 
  u1 
  'SP1FREELANCER-ADDRESS 
  u5 
  "Excellent work, delivered on time!")
```

### For Freelancers

1. **Complete Milestones**: Mark milestones as completed
```clarity
(contract-call? .escrow complete-milestone u1)
```

2. **Emergency Release**: Claim funds after deadline if client doesn't release
```clarity
(contract-call? .escrow emergency-release)
```

3. **Rate Client**: Leave feedback about the client
```clarity
(contract-call? .reputation rate-user 
  u1 
  'SP1CLIENT-ADDRESS 
  u4 
  "Good communication, clear requirements")
```

## Development Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) v1.0.0+
- [Stacks CLI](https://docs.stacks.co/build-apps/references/stacks-cli)

### Installation

1. Clone the repository
```bash
git clone https://github.com/midorichie/escrow-freelance-contract.git
cd escrow-freelance-contract
```

2. Install dependencies
```bash
clarinet install
```

3. Run tests
```bash
clarinet test
```

4. Start local devnet
```bash
clarinet devnet start
```

## Testing

The project includes comprehensive test suites for both contracts:

- **Unit tests**: Test individual functions and edge cases
- **Integration tests**: Test contract interactions and workflows
- **Security tests**: Validate security measures and error handling

Run tests with:
```bash
clarinet test
```

## Deployment

### Testnet Deployment

1. Configure your wallet with testnet STX
2. Deploy contracts in order:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure your wallet with mainnet STX
2. Deploy contracts:
```bash
clarinet deploy --mainnet
```

## Smart Contract Functions

### Escrow Contract Functions

#### Read-Only Functions
- `get-client()`: Get the client address
- `get-freelancer()`: Get the freelancer address
- `get-amount()`: Get the escrow amount
- `is-funded()`: Check if escrow is funded
- `is-released()`: Check if funds are released
- `get-deadline()`: Get the project deadline
- `get-project-details(project-id)`: Get project information

#### Public Functions
- `initialize-project()`: Set up a new project
- `fund-escrow()`: Deposit funds into escrow
- `complete-milestone()`: Mark milestone as completed
- `release-funds()`: Release funds to freelancer
- `emergency-release()`: Emergency fund release after deadline
- `raise-dispute()`: Raise a dispute
- `cancel-contract()`: Cancel contract and refund

### Reputation Contract Functions

#### Read-Only Functions
- `get-user-reputation(user)`: Get user's reputation data
- `get-project-rating()`: Get specific project rating
- `calculate-reputation-score(user)`: Calculate user's average score

#### Public Functions
- `rate-user()`: Rate a user and leave feedback
- `update-project-completion()`: Update project completion status

## Error Codes

### Escrow Contract
- `u100`: Not client
- `u101`: Not freelancer
- `u102`: Not funded
- `u103`: Already released
- `u104`: Insufficient amount
- `u105`: Invalid freelancer
- `u106`: Already funded
- `u107`: Deadline passed
- `u108`: Deadline not reached

### Reputation Contract
- `u200`: Not authorized
- `u201`: Invalid rating
- `u202`: Already rated
- `u203`: Self rating not allowed

## Security Considerations

- All functions include proper authorization checks
- Input validation prevents malicious inputs
- Deadline enforcement prevents fund locking
- Dispute mechanism provides conflict resolution
- Emergency release protects freelancers
- Reputation system incentivizes good behavior

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Join our Discord community
- Email: midorichie@example.com

## Roadmap

- [ ] Multi-signature dispute resolution
- [ ] Escrow fee management
- [ ] Advanced milestone tracking
- [ ] Integration with external oracles
- [ ] Mobile app interface
- [ ] Analytics dashboard
