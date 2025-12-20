# 🪙 ERC20 Token Contract Implementation

#### A minimal and educational implementation of the ERC20 token standard written in **Solidity** and tested using **Foundry**.
---

## ✨ Features

- ERC20 core functionality
  - `transfer`
  - `approve`
  - `transferFrom`
- Owner-controlled minting
- Total supply tracking
- Allowance-based spending
- Event emission (`Transfer`, `Approval`)
- Written with Solidity `^0.8.27`

---

## 📂 Project Structure
```
ERC20Token/
├── src/
│ └── ERC20Token.sol
├── script/
│ └── DeployERC20.s.sol
├── test/
│ └── ERC20Token.t.sol
├── foundry.toml
└── README.md
```
---

## Tests

```
forge test
```

16 tests passed, 0 failed

- transfer / transferFrom
- approve & allowance updates
- owner-only minting
- event emission checks
- failure cases (insufficient balance / allowance)

Coverage:
- Lines: ~88%
- Statements: ~89%
- Branches: 100%
