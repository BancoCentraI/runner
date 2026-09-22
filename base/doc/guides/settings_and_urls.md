# Settings & URL Update Guide

Use this guide to update the URL/contact information on the Settings page and About page.

## Information to update

All values are in a single file: `lib/product/const/app_string.dart`

### Store URLs
App store links. The "Rate the App" button uses these URLs.

| Field | Description | Example |
|-------|-------------|---------|
| `appStoreUrl` | iOS App Store link | `https://apps.apple.com/app/<app-name>/id<APP_ID>` |
| `playStoreUrl` | Google Play Store link | `https://play.google.com/store/apps/details?id=<PACKAGE_NAME>` |

### Contact
The "Contact Us" button uses this address.

| Field | Description | Example |
|-------|-------------|---------|
| `contactEmail` | Support email address | `support@example.com` |

### Legal Document URLs
Legal document links on the About page. Each opens in an in-app browser.

| Field | Description |
|-------|-------------|
| `privacyPolicyUrl` | Privacy Policy |
| `termsOfServiceUrl` | Terms of Service |
| `kvkkClarificationUrl` | KVKK Clarification Text (Turkish legal requirement) |
| `consentDeclarationUrl` | Explicit Consent Declaration |
| `acceptableUsePolicyUrl` | Acceptable Use Policy |
| `refundPolicyUrl` | Refund Policy |
| `copyrightNoticeUrl` | Copyright Notice |

## What should the user say?

Tell the field you want to update and the new value. Examples:

- "Set contact email to `info@company.com`"
- "Update Play Store link to `https://play.google.com/store/apps/details?id=com.company.app`"
- "Set privacy policy URL to `https://company.com/privacy`"
- "Update all legal document URLs: privacy → ..., terms → ..."

## File map

```
lib/product/const/app_string.dart       # All URL and string constants
lib/feature/settings/settings_view.dart  # Settings main page
lib/feature/about/about_view.dart        # Legal documents page
```
