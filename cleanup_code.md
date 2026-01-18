# Code Cleanup & Refactoring Plan

## Übersicht

Diese Datei dokumentiert Code-Qualitätsprobleme, Duplikate und Refactoring-Möglichkeiten in der LendaMobile Codebase.

---

## Priorität 1: Kritisch (Große Dateien aufteilen)

### Dateien über 1500 Zeilen

| Datei | Zeilen | Problem |
|-------|--------|---------|
| `swap_screen.dart` | 2,129 | Enthält 4+ inner classes |
| `send_screen.dart` | 2,051 | Zu viele Verantwortlichkeiten |
| `contract_detail_screen.dart` | 1,929 | Enthält 3+ inner classes |
| `walletscreen.dart` | 1,824 | Core screen, schwer wartbar |
| `transaction_detail_sheet.dart` | 1,689 | Komplexe Logik |
| `loans_screen.dart` | 1,487 | Filter + List + Cards |
| `swap_detail_sheet.dart` | 1,401 | Ähnlich wie transaction_detail_sheet |

### Empfehlung
- Inner classes in separate Dateien extrahieren
- Ziel: Max 500-700 Zeilen pro Datei
- Beispiel: `_SwapAmountCard` → `swap_amount_card.dart`

---

## Priorität 2: Hoch (Duplizierter Code)

### 2.1 `_buildDetailRow` Duplikate (6 Dateien)

**Betroffene Dateien:**
- `lib/src/ui/screens/loans/contract_detail_screen.dart:1432`
- `lib/src/ui/screens/loans/loan_offer_detail_screen.dart:693`
- `lib/src/ui/screens/swap/swap_success_screen.dart:306`
- `lib/src/ui/screens/swap/swap_processing_screen.dart:812`
- `lib/src/ui/screens/swap/evm_swap_funding_screen.dart:811`
- `lib/src/ui/screens/transactions/history/transaction_details_dialog.dart:258`

**Aktuelles Pattern:**
```dart
Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: ...),
        Text(value, style: ...),
      ],
    ),
  );
}
```

**Lösung:** Neues Widget erstellen:
```
lib/src/ui/widgets/utility/detail_row.dart
```

---

### 2.2 Status Badge/Pill Duplikate (3 Dateien)

**Betroffene Dateien:**
- `lib/src/ui/widgets/transaction/transaction_detail_sheet.dart:253` → `_buildStatusPill`
- `lib/src/ui/screens/loans/contract_detail_screen.dart:867` → `_buildStatusBadge`
- `lib/src/ui/screens/loans/loans_screen.dart:1348` → `_buildStatusBadge`

**Aktuelles Pattern:**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: color.withValues(alpha: 0.2)),
  ),
  child: Text(status),
)
```

**Lösung:** Neues Widget erstellen:
```
lib/src/ui/widgets/utility/status_badge.dart
```

---

### 2.3 Copy-to-Clipboard Duplikate (7+ Dateien)

**Betroffene Dateien:**
- `transaction_detail_sheet.dart:135-153`
- `contract_detail_screen.dart:161-185`
- `swap_processing_screen.dart`
- `swap_success_screen.dart`
- `send_screen.dart`
- `receivescreen.dart`
- `swap_detail_sheet.dart`

**Aktuelles Pattern:**
```dart
Future<void> _copyToClipboard(String value, String label) async {
  await Clipboard.setData(ClipboardData(text: value));
  HapticFeedback.lightImpact();
  setState(() => _showCopied = true);
  Future.delayed(const Duration(seconds: 3), () {
    if (mounted) setState(() => _showCopied = false);
  });
  OverlayService().showSuccess('$label copied');
}
```

**Lösung:** Utility-Klasse erstellen:
```
lib/src/utils/clipboard_helper.dart
```

---

## Priorität 3: Mittel (Code-Qualität)

### 3.1 Multiple Loading States pro Datei

**Beispiel `swap_screen.dart`:**
```dart
bool isLoading = false;
bool _isLoadingQuote = false;
bool _isLoadingBalance = false;
bool _isFetchingFees = false;
bool _isFetchingDynamicFee = false;
```

**Beispiel `contract_detail_screen.dart`:**
```dart
bool _isLoading = true;
bool _isActionLoading = false;
bool _isRepaying = false;
bool _isMarkingPaid = false;
```

**Lösung:** Loading State Enum oder State Management Pattern

---

### 3.2 Timer/Polling Duplikate (15 Dateien)

**Betroffene Dateien:**
- `contract_detail_screen.dart`
- `send_screen.dart`
- `swap_processing_screen.dart`
- `swap_screen.dart`
- `loans_screen.dart`
- `swap_detail_sheet.dart`
- `transaction_history_widget.dart`
- ... und mehr

**Aktuelles Pattern:**
```dart
Timer? _pollTimer;

void _startPolling() {
  _pollTimer = Timer.periodic(Duration(seconds: 10), (_) => _load());
}

@override
void dispose() {
  _pollTimer?.cancel();
  super.dispose();
}
```

**Lösung:** PollingMixin oder PollingService erstellen

---

### 3.3 Wiederholte Theme Styling

**Problem:** `Theme.of(context).textTheme...copyWith()` wird 40+ mal pro Datei verwendet.

**Beispiel:**
```dart
Theme.of(context).textTheme.labelSmall?.copyWith(
  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
  fontWeight: FontWeight.bold,
  letterSpacing: 0.5,
  fontSize: 9,
)
```

**Lösung:** TextStyle Extensions in `theme.dart` definieren:
```dart
extension AppTextStyles on BuildContext {
  TextStyle get labelMuted => ...
  TextStyle get labelBold => ...
}
```

---

## Priorität 4: Niedrig (Nice-to-have)

### 4.1 Ähnliche Confirmation Sheets

- `_ConfirmationSheet` in `contract_detail_screen.dart`
- `_RepayConfirmationSheet` in `contract_detail_screen.dart`
- Ähnliche Patterns in anderen Screens

**Lösung:** Generisches `ConfirmationSheet` Widget

---

### 4.2 GlassContainer mit identischem Styling

20+ Dateien verwenden:
```dart
GlassContainer(
  padding: const EdgeInsets.all(AppTheme.cardPadding),
  child: Column(...)
)
```

**Lösung:** Vordefinierte GlassContainer Varianten (z.B. `GlassCard`, `GlassSection`)

---

## Aktionsplan

### Phase 1: Widgets extrahieren
- [ ] `DetailRow` Widget erstellen
- [ ] `StatusBadge` Widget erstellen
- [ ] `ClipboardHelper` Utility erstellen

### Phase 2: Große Dateien aufteilen
- [ ] Inner classes aus `swap_screen.dart` extrahieren
- [ ] Inner classes aus `contract_detail_screen.dart` extrahieren
- [ ] Inner classes aus `send_screen.dart` extrahieren

### Phase 3: Code-Qualität verbessern
- [ ] Loading States konsolidieren
- [ ] Polling Logic zentralisieren
- [ ] TextStyle Extensions erstellen

---

## Metriken

| Metrik | Aktuell | Ziel |
|--------|---------|------|
| Dateien > 1000 Zeilen | 12 | 0 |
| Duplizierte `_buildDetailRow` | 6 | 0 |
| Duplizierte Copy-Logik | 7+ | 0 |
| Duplizierte Status Badges | 3 | 0 |

---

*Erstellt: Januar 2026*
*Letzte Aktualisierung: Januar 2026*
