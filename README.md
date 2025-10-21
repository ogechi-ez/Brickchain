# Brickchain

## Overview

**Brickchain** is a **tokenized real estate smart contract** built in **Clarity** that enables the registration of properties as digital assets, allowing investors to buy and sell fractional ownership (shares) in those properties. It also supports dividend distribution to investors based on their shareholdings.

This contract aims to provide **transparency, liquidity, and automation** in property investment by leveraging blockchain-based ownership records.

---

## Features

### 1. **Property Registration**

Property owners can tokenize their real estate by registering property details:

* Property value
* Total shares to issue
* Share price per unit

Each registered property receives a unique property ID.

**Function:**

```clarity
(register-property (property-value uint) (total-shares uint) (share-price uint))
```

* Validates non-zero inputs.
* Stores property details in the `properties` map.
* Emits a `"property-registered"` event.
* Returns the unique property ID.

---

### 2. **Buying Shares**

Investors can purchase fractional ownership in a property by buying its shares.
Funds are automatically transferred to the property owner upon purchase.

**Function:**

```clarity
(buy-shares (property-id uint) (shares uint))
```

* Validates property existence and sufficient STX balance.
* Calculates cost = `shares * share-price`.
* Updates investor balance in the `investors` map.
* Emits a `"shares-purchased"` event.
* Returns number of shares bought.

---

### 3. **Selling Shares**

Investors can sell their shares back to the property owner for a refund equivalent to current share price.

**Function:**

```clarity
(sell-shares (property-id uint) (shares uint))
```

* Verifies investor ownership and share sufficiency.
* Calculates refund = `shares * share-price`.
* Updates investor’s balance after sale.
* Transfers STX refund from property owner to investor.
* Emits a `"shares-sold"` event.
* Returns refund amount.

---

### 4. **Dividend Distribution**

Property owners can distribute income (e.g., rent or profits) to investors proportionally based on their owned shares.

**Function:**

```clarity
(distribute-dividend (property-id uint) (investor-wallet principal) (total-income uint))
```

* Validates ownership and non-zero income.
* Calculates dividend per share = `total-income / total-shares`.
* Transfers proportional STX dividend to the investor.
* Emits a `"dividends-distributed"` event.
* Returns amount distributed to the investor.

---

## Data Structures

### Maps

* **`properties`** – Stores property details

  ```clarity
  {property-id: uint} => {
    owner: principal,
    property-value: uint,
    total-shares: uint,
    share-price: uint
  }
  ```

* **`investors`** – Tracks each investor’s share balance

  ```clarity
  {property-id: uint, wallet: principal} => {share-balance: uint}
  ```

### Variables

* **`property-counter`** – Tracks the total number of properties registered.
* **`last-event-id`** – Used for sequential event tracking.

---

## Events

All major actions emit event logs for transparency and traceability:

* `"property-registered"`
* `"shares-purchased"`
* `"shares-sold"`
* `"dividends-distributed"`

Each event includes identifiers, principals, and transaction details.

---

## Error Codes

| Code   | Description                                |
| ------ | ------------------------------------------ |
| `u100` | Insufficient balance for purchase          |
| `u101` | Not enough shares to sell                  |
| `u400` | Invalid input (zero or missing parameters) |
| `u401` | Unauthorized (not property owner)          |
| `u403` | Investor not found                         |
| `u404` | Property not found                         |

---

## Security & Validation

* Strict validation on property attributes before registration.
* Balance and ownership checks before transactions.
* Use of `try!` and `unwrap!` ensures proper error handling.
* No hidden state mutations; all updates are explicit and auditable.

---

## Summary

**Brickchain** provides a decentralized and transparent framework for property tokenization, enabling investors to buy, sell, and earn from real estate assets without intermediaries.

It serves as a foundational protocol for decentralized property markets, real estate DAOs, and fractional ownership platforms built on the Stacks blockchain.
