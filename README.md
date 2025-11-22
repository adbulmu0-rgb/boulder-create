# Boulder Create Smart Contract

## Description

Boulder Create is a decentralized creator economy smart contract built on Stacks blockchain using Clarity. The contract implements automated micro-royalty streams and collaborative IP ownership models through a "Creative DNA" system that tracks creative lineage, derivative works, and revenue distribution. Each creative work is tokenized with metadata tracking creators, collaborators, and parent-child relationships in an "Inspiration Graph."

The contract automates revenue distribution to all contributors based on predetermined share percentages, supports fractional ownership stakes for investors, manages licensing agreements, and handles escrow for commissioned works. Revenue automatically flows to parent works when derivatives generate income, ensuring proper attribution and compensation across complex creative chains.

## Features

- **Creative DNA System**: Track creative lineage with content fingerprinting and parent-child relationships
- **Automated Micro-Royalty Streams**: Real-time revenue distribution to contributors and stakeholders
- **Multi-Creator Collaboration**: Add multiple contributors with custom share percentages
- **Inspiration Graph**: Derivative work tracking with automatic parent royalty distribution (default 20%)
- **Fractional Ownership**: Allow investors to purchase stakes in creative works (up to 50%)
- **Licensing Marketplace**: Grant licenses with flexible terms and automated payment distribution
- **Commission Escrow**: Secure escrow system for commissioned creative works
- **Platform Fee System**: 1% platform fee on all revenue with treasury management
- **Creator Profiles**: Track works, earnings, and reputation scores
- **Usage Tracking**: Monitor and monetize work usage with pay-per-use pricing

## Contract Functions

### Public Functions

#### `initialize-creator`
Create a creator profile to start registering works.
- **Parameters**: None
- **Returns**: `(ok true)` on success, `ERR-ALREADY-EXISTS` if profile exists
- **Usage**: Required before registering any creative works

#### `register-work`
Register a new creative work with optional parent work reference.
- **Parameters**:
  - `title (string-ascii 100)`: Work title
  - `content-hash (buff 32)`: IPFS or content fingerprint hash
  - `parent-work (optional uint)`: Parent work ID if derivative
  - `category (string-ascii 50)`: Work category
  - `price-per-use (uint)`: Price for each usage
- **Returns**: `(ok work-id)` on success
- **Requires**: Must have creator profile

#### `add-contributor`
Add a collaborator to a work with revenue share percentage.
- **Parameters**:
  - `work-id (uint)`: Work to add contributor to
  - `contributor (principal)`: Contributor address
  - `share-percentage (uint)`: Share in basis points (10000 = 100%)
  - `role (string-ascii 50)`: Contributor role
- **Returns**: `(ok true)` on success
- **Requires**: Only work creator can add contributors

#### `publish-work`
Publish work to marketplace for licensing and usage.
- **Parameters**:
  - `work-id (uint)`: Work to publish
- **Returns**: `(ok true)` on success
- **Requires**: Only work creator can publish

#### `purchase-stake`
Purchase fractional ownership stake in a published work.
- **Parameters**:
  - `work-id (uint)`: Work to invest in
  - `stake-percentage (uint)`: Stake percentage (max 5000 = 50%)
- **Returns**: `(ok true)` on success
- **Requires**: Work must be published

#### `grant-license`
Grant a license to use a work with specified terms.
- **Parameters**:
  - `work-id (uint)`: Work to license
  - `licensee (principal)`: License recipient
  - `license-type (string-ascii 50)`: Type of license
  - `price (uint)`: License price
  - `expires-at (optional uint)`: Expiration block height
- **Returns**: `(ok license-id)` on success
- **Requires**: Only creator can grant licenses, work must be published

#### `create-commission`
Create a commissioned work request with escrow.
- **Parameters**:
  - `creator (principal)`: Creator to commission
  - `description (string-ascii 200)`: Commission description
  - `escrow-amount (uint)`: Payment amount held in escrow
  - `deadline (uint)`: Completion deadline block height
- **Returns**: `(ok commission-id)` on success

#### `complete-commission`
Complete a commission and release escrow payment.
- **Parameters**:
  - `commission-id (uint)`: Commission to complete
  - `work-id (uint)`: Completed work ID
- **Returns**: `(ok true)` on success
- **Requires**: Only assigned creator can complete, must own work

#### `record-usage`
Record a usage event and distribute payment.
- **Parameters**:
  - `work-id (uint)`: Work being used
- **Returns**: `(ok true)` on success
- **Requires**: Work must be published

#### `distribute-revenue`
Distribute revenue to contributors, stakeholders, and parent works.
- **Parameters**:
  - `work-id (uint)`: Work generating revenue
  - `amount (uint)`: Revenue amount to distribute
  - `source (string-ascii 50)`: Revenue source
- **Returns**: `(ok true)` on success
- **Note**: Automatically handles platform fee, parent work shares, and contributor splits

#### `acknowledge-derivative`
Acknowledge a derivative work relationship as the parent creator.
- **Parameters**:
  - `parent-id (uint)`: Parent work ID
  - `derivative-id (uint)`: Derivative work ID
- **Returns**: `(ok true)` on success
- **Requires**: Only parent work creator can acknowledge

#### `update-price`
Update the price-per-use for a work.
- **Parameters**:
  - `work-id (uint)`: Work to update
  - `new-price (uint)`: New price per use
- **Returns**: `(ok true)` on success
- **Requires**: Only work creator can update

### Read-Only Functions

#### `get-work`
Retrieves creative work details.
- **Parameters**: `work-id (uint)`
- **Returns**: Work data or `none`

#### `get-contributor-share`
Retrieves contributor share information for a work.
- **Parameters**: `work-id (uint)`, `contributor (principal)`
- **Returns**: Contributor data or `none`

#### `get-stake`
Retrieves ownership stake information.
- **Parameters**: `work-id (uint)`, `stakeholder (principal)`
- **Returns**: Stake data or `none`

#### `get-license`
Retrieves license details.
- **Parameters**: `license-id (uint)`
- **Returns**: License data or `none`

#### `get-commission`
Retrieves commission details.
- **Parameters**: `commission-id (uint)`
- **Returns**: Commission data or `none`

#### `get-creator-profile`
Retrieves creator profile information.
- **Parameters**: `creator (principal)`
- **Returns**: Profile data or `none`

#### `get-derivative-relationship`
Retrieves parent-derivative relationship data.
- **Parameters**: `parent-id (uint)`, `derivative-id (uint)`
- **Returns**: Relationship data or `none`

#### `get-platform-stats`
Retrieves platform-wide statistics.
- **Parameters**: None
- **Returns**: Object with total-works, total-licenses, total-commissions, total-revenue, platform-treasury

## Usage Examples

### Initialize as a creator
```clarity
(contract-call? .boulder-create initialize-creator)
```

### Register an original work
```clarity
(contract-call? .boulder-create register-work
  "My First Song"
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  none
  "music"
  u1000000)
```

### Register a derivative work (remix)
```clarity
(contract-call? .boulder-create register-work
  "Remix of First Song"
  0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
  (some u1)
  "music"
  u500000)
```

### Add a collaborator
```clarity
(contract-call? .boulder-create add-contributor
  u1
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  u2000
  "producer")
```

### Publish a work
```clarity
(contract-call? .boulder-create publish-work u1)
```

### Purchase a stake in a work
```clarity
(contract-call? .boulder-create purchase-stake u1 u1000)
```

### Grant a license
```clarity
(contract-call? .boulder-create grant-license
  u1
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  "commercial"
  u5000000
  (some u10000))
```

### Create a commission
```clarity
(contract-call? .boulder-create create-commission
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  "Need album artwork"
  u10000000
  u1000)
```

### Complete a commission
```clarity
(contract-call? .boulder-create complete-commission u1 u2)
```

### Record usage and distribute payment
```clarity
(contract-call? .boulder-create record-usage u1)
```

### Acknowledge a derivative work
```clarity
(contract-call? .boulder-create acknowledge-derivative u1 u2)
```

### Update work price
```clarity
(contract-call? .boulder-create update-price u1 u2000000)
```

### Get creator profile
```clarity
(contract-call? .boulder-create get-creator-profile tx-sender)
```

### Get platform statistics
```clarity
(contract-call? .boulder-create get-platform-stats)
```

## Testing

To test the Boulder Create smart contract:

1. Navigate to the project directory:
```bash
cd boulder-create/boulder-create
```

2. Run Clarinet check to validate syntax:
```bash
clarinet check
```

3. Run the test suite:
```bash
npm install
npm test
```

4. Test in Clarinet console:
```bash
clarinet console
```

5. Example test sequence in console:
```clarity
;; Initialize creator
(contract-call? .boulder-create initialize-creator)

;; Register original work
(contract-call? .boulder-create register-work "Original Song" 0x1111111111111111111111111111111111111111111111111111111111111111 none "music" u1000000)

;; Publish work
(contract-call? .boulder-create publish-work u1)

;; Record usage
(contract-call? .boulder-create record-usage u1)

;; Check creator profile
(contract-call? .boulder-create get-creator-profile tx-sender)

;; Get platform stats
(contract-call? .boulder-create get-platform-stats)
```

6. Multi-creator collaboration test:
```clarity
;; Creator 1: Initialize and register work
(contract-call? .boulder-create initialize-creator)
(contract-call? .boulder-create register-work "Collaborative Track" 0xaaaa000000000000000000000000000000000000000000000000000000000000 none "music" u2000000)

;; Creator 1: Add collaborator with 30% share
(contract-call? .boulder-create add-contributor u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG u3000 "vocalist")

;; Creator 1: Publish
(contract-call? .boulder-create publish-work u1)

;; Record usage - revenue distributes to both creators
(contract-call? .boulder-create record-usage u1)

;; Check both creator profiles
(contract-call? .boulder-create get-creator-profile tx-sender)
```

7. Derivative work test:
```clarity
;; Register derivative work (references parent u1)
(contract-call? .boulder-create register-work "Remix Version" 0xbbbb000000000000000000000000000000000000000000000000000000000000 (some u1) "music" u1500000)

;; Publish derivative
(contract-call? .boulder-create publish-work u2)

;; Record usage - 20% goes to parent work creator
(contract-call? .boulder-create record-usage u2)

;; Parent creator acknowledges derivative
(contract-call? .boulder-create acknowledge-derivative u1 u2)
```
