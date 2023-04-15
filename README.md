# YORU-contracts

# Short description

YORU is a privacy-preserving DApp for social crypto payment. In order to achive the privacy requirement, YORU leverages the idea of account abstraction and stealth address. The crypto asset is sent to a new generated one-time address, which is owned by the receiver and the transfer would be only known by the sender and the receiver.

# Description

## Problem statement

There are two main challenges for crypto payment.

1. **Anyone can track transaction history**.
    - Each transaction is transparent and traceable on chain if the address is given. It's is not appropriate to expose transfer details of a crypto payment to anyone other than involved parties.
2. **Bas user experience in web3**.
    - First, it's difficult for users to memorize those lengthy and meaningless wallet addresses. It's more easy for people to recall friends’ social media accounts or email address which are usually more meaningful words.
    - Second, anyone who sends an Ethereum transaction needs to pay ETH for gas fees. If a user receives some tokens from others, he needs to buy some ETH before withdrawing the tokens.

Imagine a scenario where a merchant receives tokens from his customers, but everyone knows how much the merchant earned everyday by monitoring the receiving address. Another case is that one could know who participates in ETHTokyo hackathon by parsing the history of registration address. It's obvious that current mechanism of crypto transferring does not meet the privacy needs of crypto payment.

## Solution

Considering the user experience and privacy transfer, YORU is designed to offer social crypto payment capability. YORU is an innovation to combine stealth address scheme with account abstraction to offer privacy-preserving wallet.

As for privacy transfer, a one-time receiver address is generated every time by the sender if the sender knows the receiver’s public key. If the sender wants to send the transaction to the same receiver again, he will generate a fresh receiver address. The nice thing is that this is done without the receiver needing to generate multiple private keys or wallets. Most importantly, no one can identify which address is linked to the receiver’s wallet address.

For better wallet experience, we leverage DID and ENS for public key registration. User can bind his wallet account with his social media account, like gmail, twitter, line and so on. For example, if Bob is in Alice’s telegram contact, then Alice can make a transfer to Bob by querying Bob’s telegram profile to get his public key. Then Alice can directly send the tokens to a one-time stealth address that is only controlled by Bob. Or he can do the same thing by registering the info on ENS.

In order to withdraw the tokens without paying the gas fee, we leverage paymaster in account abstraction to sponsor transactions so the receiver does not need to deposit ETH in the one-time stealth address. This is super helpful for user onboarding.

## Future

The way our system works is really similar to a UTXO contract wallet. We believe it not only can be used as crypto payment but also is a good wallet architecture design for centralized exchange on L2.

# How it’s made

YORO is currently available on Goerli tetsnet.

In this project, we leverage

-   DID to resolve receiver’s public key
    -   ENS (web3)
    -   Lens Protocol (web2)
-   Account abstraction (EIP-4337) to make gasless transactions
-   Stealth address (EIP-5546) to create stealth accounts
-   CREATE2 (EIP-1014) to precompute abstract account addresses

For the stealth account part, we use umbra-js to create an account with the secret number.

Our DApp in composed of four smart contracts.

1. `Yoru.sol`
    - Used by the sender to send tokens to a CREATE2 precompute abstract account address which is controlled by the receiver’s stealth account
    - This contract mainly serves the purpose of storing relevant information for each transfer so receiver can recover the transfers by scanning the emitted events
2. `PayMaster.sol`
    - Used to cover the gas fee when receiver wants to spend his stealth fund
3. `StealthWallet.sol`
    - The abstract account to store receiver’s stealth fund
4. `StealthWalletFactory.sol`
    - A factory contract to create stealth wallet contract
