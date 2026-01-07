# Common variables shared across all justfiles
# Dart define flags - loaded from environment variables
# These are injected at compile time via --dart-define

dart-defines := "--dart-define=ESPLORA_URL=$ESPLORA_URL \
    --dart-define=ARK_SERVER_URL=$ARK_SERVER_URL \
    --dart-define=ARK_NETWORK=$ARK_NETWORK \
    --dart-define=BOLTZ_URL=$BOLTZ_URL \
    --dart-define=BACKEND_URL=$BACKEND_URL \
    --dart-define=WEBSITE_URL=$WEBSITE_URL \
    --dart-define=LENDASAT_API_KEY_SIGNET=$LENDASAT_API_KEY_SIGNET \
    --dart-define=LENDASAT_API_KEY_MAINNET=$LENDASAT_API_KEY_MAINNET \
    --dart-define=POSTHOG_API_KEY=$POSTHOG_API_KEY \
    --dart-define=POSTHOG_HOST=$POSTHOG_HOST \
    --dart-define=TURNSTILE_SITE_KEY=$TURNSTILE_SITE_KEY \
    --dart-define=TURNSTILE_BASE_URL=$TURNSTILE_BASE_URL \
    --dart-define=RAPIDAPI_KEY=$RAPIDAPI_KEY"

# Check required and optional environment variables
# Fails if required vars are missing, warns about optional ones
[private]
check-env:
    #!/usr/bin/env bash
    set -e

    missing_required=()
    missing_optional=()

    # Required variables (app won't work correctly without these)
    required_vars=(
        "ESPLORA_URL"
        "ARK_SERVER_URL"
        "ARK_NETWORK"
        "BOLTZ_URL"
        "BACKEND_URL"
        "WEBSITE_URL"
    )

    # Optional variables (features degraded but app works)
    optional_vars=(
        "LENDASAT_API_KEY_SIGNET"
        "LENDASAT_API_KEY_MAINNET"
        "POSTHOG_API_KEY"
        "POSTHOG_HOST"
        "TURNSTILE_SITE_KEY"
        "TURNSTILE_BASE_URL"
        "RAPIDAPI_KEY"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_required+=("$var")
        fi
    done

    for var in "${optional_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_optional+=("$var")
        fi
    done

    if [ ${#missing_optional[@]} -gt 0 ]; then
        echo "⚠️  Optional env vars not set (some features may be disabled):"
        for var in "${missing_optional[@]}"; do
            echo "   - $var"
        done
        echo ""
    fi

    if [ ${#missing_required[@]} -gt 0 ]; then
        echo "❌ Required env vars not set:"
        for var in "${missing_required[@]}"; do
            echo "   - $var"
        done
        echo ""
        echo "Please set these in your .env file or environment."
        exit 1
    fi

    echo "✅ All required environment variables are set"
