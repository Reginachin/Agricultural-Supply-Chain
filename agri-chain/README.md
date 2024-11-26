# Agriculture Supply Chain Management Smart Contract

## Overview

This Clarity smart contract provides a comprehensive solution for managing agricultural product supply chains on the Stacks blockchain. It enables tracking, quality control, and stakeholder management throughout the product lifecycle.

## Key Features

### Participant Management
- Register supply chain participants with specific roles
- Track participant status and reputation
- Manage participant authorization

### Product Tracking
- Register agricultural products with unique identifiers
- Track product status, location, and ownership
- Record quality assessments and certifications

### Transaction Logging
- Comprehensive transaction history for each product
- Capture detailed information about product transfers, status updates, and quality changes

## Contract Functions

### Administrative Functions
- `register-supply-chain-participant`: Add new participants to the system
- `update-participant-status`: Activate or deactivate participants

### Product Management Functions
- `register-agricultural-product`: Add a new product to the supply chain
- `update-product-status`: Change the status of a product
- `transfer-product-ownership`: Transfer a product between participants
- `update-product-quality`: Update and certify product quality
- `update-product-location`: Track product location changes

### Read-Only Functions
- `get-agricultural-product-details`: Retrieve product information
- `get-participant-details`: Retrieve participant information
- `get-supply-chain-transaction`: Retrieve transaction details

## Key Components

### Maps
- `supply-chain-participants`: Stores participant information
- `agricultural-products`: Stores product details
- `supply-chain-transactions`: Logs all product-related transactions

### Error Handling
- Custom error codes for various scenarios:
  - Unauthorized access
  - Product not found
  - Invalid status update
  - Duplicate entries

## Quality Control
- Configurable minimum quality threshold
- Quality certification based on quality score
- Product quality tracking and reporting

## Security Measures
- Only contract administrator can register and manage participants
- Strict authorization checks for all critical operations
- Transaction logging for audit and traceability

## Usage Example

```clarity
;; Register a participant
(register-supply-chain-participant farmer-address "Producer")

;; Register an agricultural product
(register-agricultural-product u1 "Organic Wheat" "Farm A, California" u1000)

;; Transfer product ownership
(transfer-product-ownership u1 distributor-address "Batch transfer to distributor")

;; Update product quality
(update-product-quality u1 u85 "Quality assessment completed")
```

## Requirements
- Stacks blockchain
- Clarity smart contract support
- Participant wallet addresses

## Limitations
- Quality scores are limited to 0-100
- Product identifiers must be unique
- Requires manual participant and product management