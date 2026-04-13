# Bringin Connect — Buy Flow (EUR to BTC)

## Overview

The "Buy" button on the wallet home screen opens the Bringin Connect widget in a WebView. This creates a permanent EUR-to-BTC standing order: the user gets a deposit IBAN linked to their BTC address. Each time they send EUR to that IBAN, it's automatically converted to BTC and sent to their wallet.

## Authentication: Mode 3a (BIP-137 Wallet Signature)

The app pre-fills the user's BTC address and signs it with their wallet's private key so the Bringin widget locks the address (prevents MITM swaps).

### Signing Flow

1. **Derive BTC address** at index 0 (`m/84'/0'/0'/0/0`) from the default Bitcoin wallet
2. **Build canonical message** — sort params alphabetically, join with `&`:
   ```
   btcAddress=bc1q...&currency=BTC&direction=FIAT_TO_CRYPTO&network=BTC
   ```
3. **BIP-137 sign** the message with the private key at `m/84'/0'/0'/0/0`:
   - Bitcoin message prefix: `\x18Bitcoin Signed Message:\n` + varint(len) + message
   - Double SHA-256 hash
   - ECDSA compact signature (65 bytes: 1 header + 32 r + 32 s)
   - Header byte: `27 + recovery_id + 4` (P2PKH compressed mode, range 31-34)
   - Base64 encode
4. **Pass to widget URL**:
   ```
   https://dev-connect.bringin.xyz/?apiKey=...&direction=FIAT_TO_CRYPTO&btcAddress=bc1q...&currency=BTC&network=BTC&walletSignature=<base64>
   ```

## User Flow

1. Tap **Buy** on wallet home screen
2. BLoC checks for stored connection:
   - If connection exists → navigate to **Dashboard** (shows deposit IBAN)
   - If no connection → derive address, sign, open **WebView**
3. Bringin widget handles: KYC, email+OTP, address confirmation, connection creation
4. On success, widget fires `bringin:success` postMessage with `depositIban` + `bringinLinkId`
5. App stores the connection in secure storage and navigates to **Dashboard**

## Architecture

```
lib/features/bringin/
├── application/
│   ├── ports/
│   │   └── bringin_local_storage_port.dart     # Storage interface
│   └── usecases/
│       ├── get_bringin_address_usecase.dart     # Derive address at index 0
│       ├── sign_bringin_message_usecase.dart    # Build canonical msg + BIP-137 sign
│       ├── create_bringin_connection_usecase.dart
│       ├── get_stored_bringin_connection_usecase.dart
│       └── remove_bringin_connection_usecase.dart
├── domain/
│   ├── entities/
│   │   └── bringin_connection.dart              # depositIban, bringinLinkId, btcAddress, walletId
│   └── errors/
│       └── bringin_error.dart
├── frameworks/
│   ├── crypto/
│   │   └── bringin_message_signer.dart          # BIP-137 signing via bitcoin_base
│   └── storage/
│       └── bringin_local_storage.dart           # Secure storage (JSON in KeyValueStorage)
├── presentation/
│   └── bloc/
│       ├── bringin_bloc.dart
│       ├── bringin_event.dart                   # started, connectionCreated, removeConnection
│       └── bringin_state.dart                   # connection, btcAddress, walletSignature
├── ui/
│   ├── bringin_router.dart                      # GoRouter: bringinWebview, bringinDashboard
│   └── screens/
│       ├── bringin_webview_screen.dart           # WebView + JS bridge for postMessage
│       └── bringin_dashboard_screen.dart         # Shows deposit IBAN + remove option
└── bringin_locator.dart                         # GetIt DI registration
```

## Modified Existing Files

| File | Change |
|------|--------|
| `lib/core/widgets/cards/action_card.dart` | Buy button navigates to `BringinRoute.bringinWebview` |
| `lib/core/utils/constants.dart` | Added `bringinApiKey`, `bringinConnectUrl`, `bringinConnectSandboxUrl` |
| `lib/locator.dart` | Added `BringinLocator.setup(locator)` |
| `lib/router.dart` | Added `...BringinRouter.routes` |
| `.env.template` | Added `BRINGIN_API_KEY`, `BRINGIN_CONNECT_URL` |

## Key Dependencies

- `bitcoin_base` (v7.0.0) — `ECPrivate.signBip137()` for BIP-137 signing
- `bip32_keys` (v3.1.1) — BIP32 key derivation from seed to `m/84'/0'/0'/0/0`
- `webview_flutter` (v4.13.0) — WebView for Bringin Connect widget

## WebView Communication

The Bringin widget sends events via `window.postMessage`. Since `webview_flutter` uses JavaScript channels (not postMessage), a small JS bridge is injected after page load:

```javascript
window.addEventListener('message', function(event) {
  if (event.data && typeof event.data === 'object') {
    var type = event.data.type;
    if (type === 'bringin:success' || type === 'bringin:close' || type === 'bringin:error') {
      BringinBridge.postMessage(JSON.stringify(event.data));
    }
  }
});
```

## Environment

| Setting | Sandbox | Production |
|---------|---------|------------|
| Widget URL | `dev-connect.bringin.xyz` | `connect.bringin.xyz` |
| API key prefix | `pk_test_...` | `pk_live_...` |

## Storage

Connection data is stored in secure storage (encrypted) as JSON with key `bringin_connection`. No database migration needed.
