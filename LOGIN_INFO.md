# Login Information

## Creating Your First Account

Since this is a fresh setup, you need to create an account first:

1. **Sign Up in the App:**
   - Open the app in your browser (http://localhost:8080)
   - Click the "Sign Up" tab
   - Enter any email address (e.g., `test@example.com`)
   - Enter a password (minimum 6 characters, e.g., `test123`)
   - Click "Sign Up"

2. **Email Confirmation (if enabled):**
   - Check your email for a confirmation link
   - Click the link to verify your account
   - Return to the app and log in

3. **Disable Email Confirmation (for testing):**
   - Go to Supabase Dashboard → Your Project
   - Navigate to Authentication → Settings
   - Under "Email Auth", toggle off "Confirm email"
   - This allows immediate login after signup (useful for development)

## Testing Credentials (Create These)

You can create test accounts with any email/password combination. Examples:

- Email: `test@example.com` | Password: `test123`
- Email: `demo@test.com` | Password: `demo123`
- Email: `user@reseller.com` | Password: `password123`

## Finding Existing Users

To see existing users in your Supabase project:

1. Go to https://supabase.com/dashboard
2. Select your project: `pzhpkoiqcutkcaudrazn`
3. Navigate to: **Authentication** → **Users**
4. You'll see a list of all registered users

## Notes

- All user accounts are stored in Supabase's `auth.users` table
- Passwords are securely hashed (never stored in plain text)
- The app uses Row Level Security (RLS) to ensure users can only access their own data
- Session tokens are automatically managed by Supabase Flutter SDK
