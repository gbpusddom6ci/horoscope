# Operations Checklist

## Firestore Rules / Indexes
- Update rules and indexes from:
  - `firebase/firestore.rules`
  - `firebase/firestore.indexes.json`
- Deploy with Firebase CLI:
  - `firebase deploy --only firestore:rules,firestore:indexes`

## Push Notifications (FCM + APNs)
- Enable Push Notifications capability in Apple Developer for the app id.
- Upload APNs key/cert in Firebase Console -> Project Settings -> Cloud Messaging.
- Verify device receives `fcmToken` in `users/{uid}.fcmToken`.

## StoreKit Production
- Create products in App Store Connect:
  - `rk.horoscope.premium.monthly`
  - `rk.horoscope.premium.yearly`
- If product ids change, update Build Setting `PREMIUM_PRODUCT_IDS`.

## Monitoring
- CI workflow exists at `.github/workflows/ios-ci.yml`.
- Keep unit tests green before release.
- Optional next step: add Firebase Crashlytics and Analytics package products for runtime dashboards.

## Legacy Data Migration
- First login after upgrade automatically migrates legacy UserDefaults data to Firestore.
- Migration marker key: `legacy_migrated_{uid}` in UserDefaults.
