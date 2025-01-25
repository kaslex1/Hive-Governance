# Hive Governance

A decentralized governance and treasury management system built on Stacks blockchain using Clarity smart contracts.

## Overview

Hive Governance enables community-driven decision making and treasury management through a weighted voting system. Citizens (members) can propose motions, vote on them, and collectively manage community funds.

## Features

- **Motion Management**: Create, vote on, and execute community proposals
- **Weighted Voting**: Citizens have different voting powers based on their contribution/stake
- **Treasury Management**: Secure handling of community funds
- **Staking Integration**: Built-in functionality to stake treasury funds in external pools
- **Governance Controls**: Timelocks and minimum thresholds for responsible governance

## Contract Details

### Key Parameters

- Decision Window: 144 blocks (~24 hours)
- Minimum Motion Value: 1,000,000 microSTX
- Maximum Citizen Power: 1,000,000
- Minimum Citizen Power: 1

### Core Functions

```clarity
(define-public (propose-motion (title (string-ascii 50)) 
                             (details (string-ascii 500)) 
                             (value uint)
                             (target principal)))

(define-public (cast-vote (motion-id uint) (support bool)))

(define-public (complete-motion (motion-id uint)))
```

### Treasury Functions

```clarity
(define-public (stake-funds (amount uint) (vault-contract <staking-vault-trait>)))
(define-public (unstake-funds (amount uint) (vault-contract <staking-vault-trait>)))
```

### Administrative Functions

```clarity
(define-public (add-citizen (address principal) (power uint)))
(define-public (update-power (address principal) (new-power uint)))
(define-public (transfer-admin (new-admin principal)))
```

## Error Handling

The contract includes comprehensive error handling for:
- Unauthorized access
- Invalid inputs
- Insufficient funds
- Duplicate votes
- Expired motions
- Resource limitations

## Security Features

- Timelocked voting periods
- Minimum thresholds for proposals
- Power limits for citizens
- Double-vote prevention
- Balance checks before transfers
- Admin-only privileged operations

## Getting Started

1. Deploy the contract to Stacks blockchain
2. Set initial admin address
3. Add citizens with their respective voting powers
4. Begin creating and voting on motions

## Integration

The contract includes a staking vault trait for integration with external staking pools:

```clarity
(define-trait staking-vault-trait
    (
        (stake (uint) (response bool uint))
        (unstake (uint) (response bool uint))
        (get-staked-balance (principal) (response uint uint))
    )
)
```

## Contributing

Contributions are welcome! Please ensure you:
1. Test all changes thoroughly
2. Document new features or modifications
3. Follow Clarity best practices
4. Consider backwards compatibility

## License

This project is licensed under the MIT License - see the LICENSE file for details

## Security Considerations

- Ensure proper access control when deploying
- Regularly audit treasury balances
- Monitor voting patterns for manipulation
- Test extensively before mainnet deployment
- Keep admin keys secure
- Consider implementing emergency pause functionality

## Contact

For questions, issues, or contributions, please open an issue in the repository.