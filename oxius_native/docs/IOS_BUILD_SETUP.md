# iOS Build Setup Guide for Codemagic

## 📋 Prerequisites

### 1. Apple Developer Account
- **Apple Developer Program** membership ($99/year)
- Access to [Apple Developer Portal](https://developer.apple.com)
- Access to [App Store Connect](https://appstoreconnect.apple.com)

### 2. Required Information
- **Bundle ID**: `com.adsyclub.app`
- **Team ID**: Your Apple Developer Team ID
- **App Name**: AdsyClub

---

## 🔐 Step 1: Apple Developer Portal Setup

### Create App ID
1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
2. Click **+** to create new Identifier
3. Select **App IDs** → Continue
4. Select **App** → Continue
5. Fill in:
   - **Description**: AdsyClub
   - **Bundle ID**: `com.adsyclub.app` (Explicit)
6. Enable Capabilities:
   - ✅ Push Notifications
   - ✅ Associated Domains (if using deep links)
   - ✅ Sign In with Apple (if using)
7. Click **Continue** → **Register**

### Create Push Notification Key (APNs)
1. Go to **Keys** section
2. Click **+** to create new key
3. **Key Name**: AdsyClub APNs Key
4. Enable **Apple Push Notifications service (APNs)**
5. Click **Continue** → **Register**
6. **Download the .p8 file** (you can only download once!)
7. Note down:
   - **Key ID**: (shown on the key page)
   - **Team ID**: (from Membership page)

### Create Distribution Certificate
1. Go to **Certificates** section
2. Click **+** to create new certificate
3. Select **Apple Distribution** → Continue
4. Upload CSR (Certificate Signing Request)
5. Download and install the certificate

### Create Provisioning Profile
1. Go to **Profiles** section
2. Click **+** to create new profile
3. Select **App Store** → Continue
4. Select your App ID (`com.adsyclub.app`)
5. Select your Distribution Certificate
6. **Profile Name**: AdsyClub App Store Profile
7. Click **Generate** → **Download**

---

## 🏪 Step 2: App Store Connect Setup

### Create App
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platforms**: iOS
   - **Name**: AdsyClub
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: com.adsyclub.app
   - **SKU**: adsyclub-ios-app
   - **User Access**: Full Access
4. Click **Create**

### App Information
1. Fill in app details:
   - **Subtitle**: Your Business Network
   - **Category**: Business / Social Networking
   - **Content Rights**: Does not contain third-party content
   - **Age Rating**: Complete the questionnaire

### Prepare for Submission
1. **App Privacy**: Fill out privacy details
2. **Screenshots**: Prepare for all device sizes
3. **App Description**: Write compelling description
4. **Keywords**: Add relevant keywords
5. **Support URL**: Your support page URL
6. **Marketing URL**: Your website URL

---

## 🔥 Step 3: Firebase Setup for iOS

### Add iOS App to Firebase
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click **Add app** → **iOS**
4. **Bundle ID**: `com.adsyclub.app`
5. **App nickname**: AdsyClub iOS
6. Click **Register app**

### Download GoogleService-Info.plist
1. Download `GoogleService-Info.plist`
2. Place it in `ios/Runner/` directory
3. **Important**: Add to Xcode project:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Right-click on `Runner` folder
   - Select **Add Files to "Runner"**
   - Select `GoogleService-Info.plist`
   - Ensure **Copy items if needed** is checked

### Configure APNs in Firebase
1. Go to **Project Settings** → **Cloud Messaging**
2. Under **Apple app configuration**:
   - Upload your APNs Authentication Key (.p8 file)
   - Enter **Key ID**
   - Enter **Team ID**

---

## ⚙️ Step 4: Codemagic Setup

### Connect Repository
1. Go to [Codemagic](https://codemagic.io)
2. Sign in with your Git provider
3. Add your repository
4. Select the repository containing your Flutter app

### Configure App Store Connect Integration
1. Go to **Teams** → **Integrations**
2. Click **App Store Connect**
3. Choose **API Key** authentication (recommended)
4. Create API Key in App Store Connect:
   - Go to **Users and Access** → **Keys**
   - Click **+** to generate new key
   - **Name**: Codemagic CI/CD
   - **Access**: App Manager
   - Download the .p8 file
5. In Codemagic, enter:
   - **Issuer ID**: (from App Store Connect)
   - **Key ID**: (from the key you created)
   - **API Key**: Upload the .p8 file
6. Name the integration: `AdsyClub App Store Connect`

### Configure Code Signing
1. Go to your app in Codemagic
2. Click **Settings** → **Code signing**
3. **iOS code signing**:
   - Upload your Distribution Certificate (.p12)
   - Upload your Provisioning Profile (.mobileprovision)
   - Or use **Automatic code signing** with App Store Connect integration

### Add Environment Variables
1. Go to **Environment variables**
2. Create a group named `firebase_credentials`
3. Add variable:
   - **Name**: `GOOGLE_SERVICE_INFO_PLIST`
   - **Value**: Base64 encoded content of GoogleService-Info.plist
   ```bash
   # To encode:
   base64 -i ios/Runner/GoogleService-Info.plist
   ```
   - Check **Secure** checkbox

### Update codemagic.yaml
Update the following in `codemagic.yaml`:
1. Replace `YOUR_APP_STORE_APP_ID` with your App Store app ID
2. Replace `your-email@example.com` with your email
3. Ensure `bundle_identifier` matches your Bundle ID

---

## 📱 Step 5: Update Xcode Project

### Update Bundle Identifier
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project
3. Select **Runner** target
4. Go to **Signing & Capabilities**
5. Set **Bundle Identifier**: `com.adsyclub.app`
6. Select your **Team**
7. Enable **Automatically manage signing**

### Add Capabilities
1. In **Signing & Capabilities**, click **+ Capability**
2. Add:
   - **Push Notifications**
   - **Background Modes** (already in Info.plist)

### Update ExportOptions.plist
Edit `ios/ExportOptions.plist`:
1. Replace `YOUR_TEAM_ID` with your Apple Team ID
2. Update provisioning profile name if different

---

## 🚀 Step 6: Build and Deploy

### Manual Build (Local)
```bash
# Clean and get packages
flutter clean
flutter pub get

# Install pods
cd ios
pod install --repo-update
cd ..

# Build IPA
flutter build ipa --release
```

### Codemagic Build
1. Push your code to the repository
2. Go to Codemagic dashboard
3. Select your app
4. Choose **ios-production** workflow
5. Click **Start new build**

### First TestFlight Build
1. Build will be uploaded automatically
2. Go to App Store Connect → TestFlight
3. Wait for processing (can take 15-30 minutes)
4. Add testers or submit for review

---

## 📝 Checklist Before Submission

### App Store Requirements
- [ ] App icon (1024x1024 PNG, no alpha)
- [ ] Screenshots for all required device sizes
- [ ] App description and keywords
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] Age rating completed
- [ ] App category selected

### Technical Requirements
- [ ] Bundle ID matches everywhere
- [ ] Version and build number set
- [ ] All permissions have descriptions in Info.plist
- [ ] Firebase configured correctly
- [ ] Push notifications working
- [ ] No crashes on launch

### Code Signing
- [ ] Distribution certificate valid
- [ ] Provisioning profile valid
- [ ] Team ID correct
- [ ] Automatic signing enabled (or manual profiles uploaded)

---

## 🔧 Troubleshooting

### Common Issues

**Pod install fails**
```bash
cd ios
pod deintegrate
pod cache clean --all
pod install --repo-update
```

**Code signing errors**
- Ensure certificate and profile match
- Check Team ID is correct
- Try deleting derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`

**Firebase errors**
- Verify GoogleService-Info.plist is in correct location
- Ensure Bundle ID matches Firebase configuration
- Check APNs key is uploaded to Firebase

**Build number issues**
- App Store requires unique build numbers
- Increment build number for each upload

---

## 📞 Support

For issues with:
- **Codemagic**: [Codemagic Documentation](https://docs.codemagic.io)
- **App Store Connect**: [Apple Developer Support](https://developer.apple.com/support/)
- **Firebase**: [Firebase Documentation](https://firebase.google.com/docs)
