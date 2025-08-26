# 📦 Shared Cargo DAO

A decentralized platform enabling small businesses to tokenize and trade unused cargo space peer-to-peer for more affordable logistics solutions.

## 🚀 Features

- **🏢 Business Registration**: Small businesses can register and create profiles
- **📦 Cargo Space Tokenization**: Convert unused logistics capacity into tradeable assets
- **💰 Peer-to-Peer Marketplace**: Direct trading between cargo space providers and buyers  
- **⭐ Reputation System**: Rate and review businesses for trust and quality assurance
- **💸 Automated Payments**: Secure STX-based transactions with platform fees
- **📊 Real-time Tracking**: Monitor cargo space availability and bookings

## 🛠 Usage

### For Cargo Space Providers

**1. Register Your Business**
```clarity
(register-business "My Logistics Co" "New York, NY")
```

**2. Create Cargo Space Offerings**
```clarity
(create-cargo-space 
    "refrigerated"     ;; space-type
    u1000             ;; capacity in kg
    u50               ;; price per kg in microSTX
    "New York, NY"    ;; from-location
    "Los Angeles, CA" ;; to-location
    u1000000          ;; departure-date (block height)
    u1000500          ;; arrival-date (block height)
)
```

**3. Complete Bookings**
```clarity
(complete-booking u1)
```

### For Cargo Space Buyers

**1. Browse Available Spaces**
```clarity
(get-cargo-space u1)
```

**2. Book Cargo Space**
```clarity
(book-cargo-space u1 u500)  ;; space-id, weight in kg
```

**3. Rate Service Provider**
```clarity
(rate-business u1 u5 "Excellent service, fast delivery!")
```

### Administrative Functions

**Update Platform Fee (Owner Only)**
```clarity
(update-platform-fee u300)  ;; 3% fee
```

## 📖 Contract Functions

### Public Functions
- `register-business` - Register a new logistics business
- `create-cargo-space` - List available cargo space for booking
- `book-cargo-space` - Reserve cargo space and make payment
- `complete-booking` - Mark a booking as completed
- `rate-business` - Rate and review a business
- `toggle-business-status` - Activate/deactivate business
- `update-platform-fee` - Modify platform fee (admin only)

### Read-Only Functions
- `get-business` - Retrieve business details
- `get-cargo-space` - Get cargo space information
- `get-booking` - View booking details
- `get-business-by-owner` - Find business by owner address
- `get-user-rating` - Check user ratings
- `get-platform-fee` - Current platform fee percentage
- `get-contract-stats` - Overall platform statistics

## 🔧 Development

**Check Contract Syntax**
```bash
clarinet check
```

**Run Tests**
```bash
clarinet test
```

**Deploy Contract**
```bash
clarinet deploy
```

## 💡 How It Works

1. **🏢 Registration**: Businesses register on the platform with their details
2. **📦 Space Creation**: Providers list unused cargo capacity with routes and pricing
3. **🛒 Marketplace**: Buyers browse and book available cargo space
4. **💳 Payment**: Automatic STX transfers handle payments and platform fees
5. **⭐ Reputation**: Rating system builds trust between participants
6. **📈 Growth**: Network effects create more efficient logistics marketplace

## 🌟 Benefits

- **💰 Cost Savings**: Up to 40% reduction in shipping costs
- **🌍 Sustainability**: Maximize existing transport capacity
- **🤝 Community**: Direct peer-to-peer business relationships
- **🔒 Security**: Blockchain-based transparency and payments
- **📊 Efficiency**: Smart contract automation reduces overhead

## 🚦 Getting Started

1. Clone the repository
2. Install Clarinet: `npm install -g @hirosystems/clarinet-cli`
3. Run `clarinet check` to validate the contract
4. Deploy to testnet for testing
5. Start registering businesses and creating cargo space!

---

*Built with ❤️ on Stacks blockchain*
