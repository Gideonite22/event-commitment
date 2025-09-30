# Event Commitment

A blockchain-based system for tracking and verifying event commitments, providing transparency, accountability, and optional third-party validation on Stacks.

## Overview

Event Commitment leverages blockchain technology to create a decentralized platform for managing event-related promises and commitments. Users can:

- Create event commitments with specific details and deadlines
- Break down commitments into verifiable stages
- Stake tokens to demonstrate commitment
- Assign "validators" for third-party verification
- Track progress transparently
- Choose between public and private commitment visibility

## Architecture

```mermaid
graph TD
    A[User] -->|Creates| B[Goal]
    B -->|Contains| C[Milestones]
    B -->|Optional| D[Stake]
    B -->|Optional| E[Witness]
    E -->|Verifies| C
    C -->|Completion| F[Goal Completion]
    F -->|Triggers| G[Stake Release]
```

The system is built around two main data structures:
- Goals: Track high-level goal information and metadata
- Milestones: Track individual steps toward goal completion

## Contract Documentation

### Core Components

#### Goals Map
Stores goal information including:
- Title and description
- Deadline
- Privacy settings
- Witness address
- Stake amount
- Milestone completion tracking

#### Milestones Map
Tracks individual milestones with:
- Title and description
- Completion status
- Verification details
- Completion timestamp

### Key Features

1. **Goal Privacy**
   - Public goals visible to all
   - Private goals visible only to owner and witness

2. **Staking Mechanism**
   - Optional token staking
   - Tokens released upon goal completion

3. **Witness System**
   - Optional third-party verification
   - Witnesses must verify milestone completion

## Getting Started

### Prerequisites
- Clarinet
- Stacks wallet
- STX tokens (for staking)

### Basic Usage

1. Create a new goal:
```clarity
(contract-call? .pathpulse create-goal 
    "Learn Clarity" 
    "Master Clarity smart contract development" 
    (some u144000) ;; Deadline
    u1 ;; Public
    none ;; No witness
    u100) ;; Stake 100 STX
```

2. Add a milestone:
```clarity
(contract-call? .pathpulse add-milestone 
    u1 
    "Complete basic tutorial" 
    "Finish the Clarity basics tutorial")
```

3. Complete a milestone:
```clarity
(contract-call? .pathpulse complete-milestone u1 u1)
```

## Function Reference

### Goal Management

```clarity
(create-goal (title (string-ascii 100)) 
            (description (string-utf8 500))
            (deadline (optional uint))
            (privacy uint)
            (witness (optional principal))
            (stake-amount uint))

(add-milestone (goal-id uint)
              (title (string-ascii 100))
              (description (string-utf8 500)))

(complete-milestone (goal-id uint) (milestone-id uint))

(verify-milestone (user principal) (goal-id uint) (milestone-id uint))
```

### Commitment Administration

```clarity
(update-commitment-privacy (commitment-id uint) (privacy uint))
(update-commitment-validator (commitment-id uint) (validator (optional principal)))
(claim-commitment-stake (commitment-id uint))
```

## Development

### Testing
1. Install Clarinet
2. Run tests:
```bash
clarinet test
```

### Local Development
1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```bash
clarinet deploy
```

## Security Considerations

### Known Limitations
- Goal deadlines are based on block height
- Witnesses cannot be changed after milestone verification begins
- No partial stake withdrawal

### Best Practices
- Always verify goal privacy settings before sharing sensitive information
- Use witnesses for important goals requiring verification
- Set realistic deadlines (in block height)
- Consider token stake amounts carefully
- Review goal and milestone details before creation as they cannot be modified