# Feedback Feature Implementation

This document describes the feedback/bug reporting feature implementation and the steps required for production deployment.

## Overview

The feedback feature allows users to:

- Report bugs
- Request features
- Provide general feedback
- Attach screenshots (optional)
- Include device information for debugging

## Current Implementation

### Files Created/Modified

1. **`lib/src/services/feedback_service.dart`** - Service handling feedback submission
2. **`lib/src/ui/screens/settings/feedback_screen.dart`** - UI for feedback form
3. **`lib/src/ui/screens/settings/settings.dart`** - Added 'feedback' tab case
4. **`lib/src/ui/screens/settings/settings_view.dart`** - Added menu item
5. **`lib/l10n/app_*.arb`** - Added localization strings

### Dependencies Added

```yaml
url_launcher: ^6.2.5
```

### How It Works (Current)

The current implementation uses the `mailto:` URI scheme to open the user's email client:

1. User fills out the feedback form
2. Selects feedback type (Bug Report, Feature Request, General Feedback, Other)
3. Optionally attaches screenshots
4. Optionally includes device information
5. Clicks "Send Feedback"
6. System opens the native email client with pre-filled subject and body
7. User manually attaches screenshots if needed

**Limitations:**

- Screenshots cannot be automatically attached via `mailto:` on most platforms
- Requires user to have an email app configured
- User must manually send the email

## Production Setup Options

### Option 1: Email Service via Backend API (Recommended)

For full functionality including automatic screenshot attachments, implement a backend API endpoint.

#### Backend Requirements

Create an API endpoint (e.g., `POST /api/feedback`) that:

1. Accepts multipart form data:
   - `type`: String (Bug Report, Feature Request, etc.)
   - `message`: String
   - `deviceInfo`: String (optional)
   - `attachments[]`: Files (optional, max 5)

2. Sends email using a service like:
   - **SendGrid** - Easy to set up, good free tier
   - **AWS SES** - Cost-effective for high volume
   - **Mailgun** - Developer-friendly
   - **Postmark** - Great deliverability

#### Example Backend Implementation (Node.js with SendGrid)

```javascript
const sgMail = require("@sendgrid/mail");
const multer = require("multer");

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

app.post("/api/feedback", upload.array("attachments", 5), async (req, res) => {
  const { type, message, deviceInfo } = req.body;
  const attachments = req.files?.map(file => ({
    content: file.buffer.toString("base64"),
    filename: file.originalname,
    type: file.mimetype,
    disposition: "attachment",
  })) || [];

  const msg = {
    to: "support@lendasat.com",
    from: "noreply@lendasat.com", // Must be verified sender
    subject: `[${type}] Lenda App Feedback`,
    text: `${message}\n\n---\nDevice Info:\n${deviceInfo || "Not provided"}`,
    attachments,
  };

  try {
    await sgMail.send(msg);
    res.json({ success: true });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, error: "Failed to send feedback" });
  }
});
```

#### Flutter Integration

Update `feedback_service.dart` to use the API:

```dart
Future<bool> sendFeedbackViaApi({
  required String feedbackType,
  required String message,
  List<File>? attachments,
  String? deviceInfo,
}) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.lendasat.com/feedback'),
    );

    request.fields['type'] = feedbackType;
    request.fields['message'] = message;
    request.fields['deviceInfo'] = deviceInfo ?? '';

    if (attachments != null) {
      for (var i = 0; i < attachments.length; i++) {
        request.files.add(await http.MultipartFile.fromPath(
          'attachments',
          attachments[i].path,
        ));
      }
    }

    final response = await request.send();
    return response.statusCode == 200;
  } catch (e) {
    logger.e('Error sending feedback via API: $e');
    return false;
  }
}
```

### Option 2: Firebase Functions + Email

If already using Firebase:

```javascript
// Firebase Cloud Function
exports.sendFeedback = functions.https.onCall(async (data, context) => {
  const { type, message, deviceInfo, attachments } = data;

  // Use nodemailer with Gmail or SendGrid
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  await transporter.sendMail({
    from: "noreply@lendasat.com",
    to: "support@lendasat.com",
    subject: `[${type}] Lenda App Feedback`,
    text: message,
    attachments: attachments?.map(a => ({
      filename: a.name,
      content: Buffer.from(a.data, "base64"),
    })),
  });

  return { success: true };
});
```

### Option 3: Third-Party Feedback Services

Consider using dedicated feedback services:

- **Instabug** - Full feedback SDK with screenshots, logs, network traces
- **Shake** - Similar to Instabug, good for bug reporting
- **Sentry** - Error tracking with user feedback
- **UserVoice** - Product feedback management

These services provide:

- Automatic screenshot capture
- Session recordings
- Crash logs
- User context
- Dashboard for managing feedback

## Environment Variables Required (Production)

```env
# For SendGrid
SENDGRID_API_KEY=your_api_key

# Or for AWS SES
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1

# Email settings
FEEDBACK_EMAIL=support@lendasat.com
FROM_EMAIL=noreply@lendasat.com
```

## Testing

1. Run `flutter pub get` to install dependencies
2. Test the mailto functionality locally
3. Verify email client opens with correct subject/body
4. Test screenshot attachment flow
5. Deploy backend API for full functionality

## Future Improvements

1. **In-App Screenshot Capture** - Add a button to capture current screen
2. **Automatic Crash Reports** - Send feedback on app crashes
3. **Feedback Categories** - Add more granular categories
4. **Ticket Tracking** - Show users their submitted feedback status
5. **Response Channel** - Allow support to respond directly in-app

## Summary of Required Steps

### Immediate (Current Implementation Works)

- [x] Add `url_launcher` dependency
- [x] Create feedback UI screen
- [x] Add to settings menu
- [x] Add localizations
- [ ] Run `flutter pub get`
- [ ] Test mailto functionality

### For Production (Full Functionality)

- [ ] Set up email service (SendGrid/AWS SES/etc.)
- [ ] Create backend API endpoint for feedback
- [ ] Update Flutter app to use API
- [ ] Configure environment variables
- [ ] Set up verified sender domain for emails
- [ ] Test end-to-end flow with attachments
