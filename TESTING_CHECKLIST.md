# Testing Checklist

Use this checklist to verify the authentication changes work correctly.

## Prerequisites

- [ ] Flutter is installed and in PATH (`flutter --version`)
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Freezed code generated (`flutter pub run build_runner build --delete-conflicting-outputs`)
- [ ] Supabase credentials configured in `lib/main.dart`

## Code Structure Verification ✅

The following has been verified:
- ✅ Authentication screen created (`lib/screens/auth_screen.dart`)
- ✅ Main app updated with `AuthWrapper` (`lib/main.dart`)
- ✅ Logout functionality added to scanner screen
- ✅ All imports are correct
- ✅ No Dart syntax errors

## Manual Testing Steps

### 1. Compile and Run
```bash
flutter run
```

The app should:
- [ ] Launch without compilation errors
- [ ] Show the authentication screen first (since user is not logged in)
- [ ] Display the login/signup toggle correctly

### 2. Sign Up Flow
- [ ] Click "Sign Up" tab
- [ ] Enter an email address
- [ ] Enter a password (minimum 6 characters)
- [ ] Click "Sign Up" button
- [ ] See success message about checking email
- [ ] Verify email in Supabase (if email confirmation is enabled)
- [ ] After confirming, should automatically navigate to scanner screen

### 3. Login Flow
- [ ] Enter valid credentials
- [ ] Click "Login" button
- [ ] Should navigate to scanner screen
- [ ] Scanner screen should display with logout button in AppBar

### 4. Logout Flow
- [ ] Click logout icon in scanner screen AppBar
- [ ] Should return to authentication screen
- [ ] Should not be able to access scanner screen without re-authenticating

### 5. Error Handling
- [ ] Try logging in with invalid credentials → should show error message
- [ ] Try signing up with invalid email → should show validation error
- [ ] Try submitting empty form → should show validation errors

### 6. State Persistence
- [ ] Login to the app
- [ ] Close the app completely
- [ ] Reopen the app
- [ ] Should remain logged in (if session is still valid)
- [ ] If session expired, should show auth screen

## Expected Behavior Summary

1. **Unauthenticated State**: Shows `AuthScreen` with login/signup options
2. **Authenticated State**: Shows `ScannerScreen` with logout button
3. **Navigation**: Automatic navigation based on auth state via `StreamBuilder`
4. **Error Display**: Error messages shown in red container above form
5. **Loading States**: Loading indicator during authentication requests

## Known Limitations

- Email verification may be required depending on Supabase settings
- Session persistence depends on Supabase configuration
- The app will fail if Freezed code is not generated (missing `*.freezed.dart` files)
