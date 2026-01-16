# On-Ramp & Off-Ramp Testing Guide

This document explains how to test Bitcoin on-ramps (buy) and off-ramps (sell) locally during development vs in production.

## Overview

The app supports multiple payment providers for buying Bitcoin:

- **Coinbase** (active) - Primary provider
- **MoonPay** (coming soon)
- **Bringin** (coming soon)

## Architecture

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   Mobile App    │ ──── │  LendaSat Hub   │ ──── │ Payment Provider│
│   (Flutter)     │      │   (Backend)     │      │   (Coinbase)    │
└─────────────────┘      └─────────────────┘      └─────────────────┘
     localhost:7337           API calls            External API
```

## Local Development Setup

### 1. Start the LendaSat Backend

```bash
cd /home/weltitob/lendasat/lendasat
set -a; source .env; set +a
./target/debug/hub
```

The backend runs on `0.0.0.0:7337` by default.

### 2. ADB Port Forwarding (Android)

**IMPORTANT**: For the mobile app to reach your local backend, you must set up ADB reverse port forwarding.

#### Check connected devices:

```bash
adb devices
```

#### Set up port forwarding:

**Single device:**

```bash
adb reverse tcp:7337 tcp:7337
```

**Multiple devices (specify device):**

```bash
adb -s <device-id> reverse tcp:7337 tcp:7337
```

Example with physical device:

```bash
adb -s adb-R5CRB28QKVD-oD73CP._adb-tls-connect._tcp reverse tcp:7337 tcp:7337
```

#### Verify forwarding is active:

```bash
adb reverse --list
```

Expected output:

```
host-53 tcp:7337 tcp:7337
```

#### Remove port forwarding:

```bash
adb reverse --remove tcp:7337
```

### 3. Environment Configuration

The app uses build-time environment variables to determine which backend to use.

#### Local Development (Flutter run):

```bash
flutter run --dart-define=MOONPAY_BACKEND_API=http://127.0.0.1:7337
```

#### Production Build:

```bash
flutter build apk --dart-define=MOONPAY_BACKEND_API=https://apiborrow.lendasat.com
```

### 4. Service Configuration

In `lib/src/services/coinbase_service.dart`:

```dart
static const String _backendUrl = String.fromEnvironment(
  'MOONPAY_BACKEND_API',
  defaultValue: 'https://apiborrow.lendasat.com',
);
```

## Testing Coinbase On-Ramp

### Local Testing Flow:

1. **Start backend** with Coinbase credentials in `.env`:
   ```
   COINBASE_API_KEY_ID=your_key_id
   COINBASE_API_KEY_SECRET=your_secret
   COINBASE_PROJECT_ID=your_project_id
   ```

2. **Set up ADB forwarding** (see above)

3. **Run the app** with local backend:
   ```bash
   flutter run --dart-define=MOONPAY_BACKEND_API=http://127.0.0.1:7337
   ```

4. **Navigate to Buy Bitcoin** screen

5. **Enter amount** and tap "Buy Bitcoin"

6. App will:
   - Request session token from backend (`/borrower/coinbase/session`)
   - Open Coinbase Onramp URL in browser
   - User completes purchase on Coinbase
   - Funds sent to app's Bitcoin address

### Expected Behavior:

- **Login redirect**: Normal - Coinbase requires authentication
- **Minimum amount**: ~$2 USD equivalent
- **Currency**: Amount passed as BTC, Coinbase handles fiat conversion

## Production vs Local Differences

| Aspect               | Local Development       | Production                       |
| -------------------- | ----------------------- | -------------------------------- |
| Backend URL          | `http://127.0.0.1:7337` | `https://apiborrow.lendasat.com` |
| ADB Forwarding       | Required                | Not needed                       |
| SSL                  | Not used                | Required (HTTPS)                 |
| Coinbase Environment | Sandbox (optional)      | Production                       |

## Troubleshooting

### "Endless loading" on Buy Bitcoin screen

1. **Check ADB forwarding**:
   ```bash
   adb reverse --list
   ```
   Should show `tcp:7337 tcp:7337`

2. **Verify backend is running**:
   ```bash
   curl http://127.0.0.1:7337/health
   ```

3. **Check for multiple devices**:
   ```bash
   adb devices
   ```
   If multiple devices, specify the target device explicitly.

### "FormatException: Unexpected end of input"

- Backend returned empty response
- Check backend logs for errors
- Verify Coinbase credentials in `.env`

### Connection refused

- Backend not running
- ADB forwarding not set up
- Wrong port number

## Backend Endpoints

### Coinbase Onramp

```
POST /borrower/coinbase/session
```

Request:

```json
{
  "address": "tb1q...",
  "amount": "0.001"
}
```

Response:

```json
{
  "url": "https://pay.coinbase.com/buy/select-asset?sessionToken=..."
}
```

## Restarting Services

### Restart Backend:

```bash
# Find and kill existing process
ps aux | grep hub
kill <PID>

# Start again
cd /home/weltitob/lendasat/lendasat
set -a; source .env; set +a
./target/debug/hub
```

### Reset ADB Forwarding:

```bash
adb reverse --remove-all
adb reverse tcp:7337 tcp:7337
```

## Provider-Specific Notes

### Coinbase

- Uses CDP API with Ed25519 JWT authentication
- Session tokens valid for limited time
- Supports: Credit/Debit, Google Pay, Apple Pay, PayPal, SEPA
- Fees: ~1.99% (SEPA) to ~4.49% (Card)

### MoonPay (Coming Soon)

- Has separate limits endpoint
- Requires API key validation
- Minimum: ~0.000017 BTC

### Bringin (Coming Soon)

- European focus
- Lower fees for SEPA transfers
