# CloudKit Setup Instructions

## ✅ Code Implementation: COMPLETE

All code has been written. Follow these steps to enable CloudKit in Xcode.

---

## Step 1: Add CloudKitManager.swift to Xcode

**IMPORTANT:** You need to manually add the new file to your Xcode project:

1. In Xcode, right-click on the "Services" folder
2. Select "Add Files to 'Notes to self'..."
3. Navigate to: `Services/CloudKitManager.swift`
4. Check "Copy items if needed" 
5. Make sure "Notes to self" target is checked
6. Click "Add"

---

## Step 2: Enable CloudKit Capability

1. **Open your project in Xcode**
2. **Select your project** in the left navigator (blue "Notes to self" icon at top)
3. **Select your app target** ("Notes to self" under TARGETS)
4. **Click the "Signing & Capabilities" tab** at the top
5. **Click "+ Capability"** button
6. **Search for and add "iCloud"**
7. **In the iCloud section that appears:**
   - ✅ Check "CloudKit"
   - A container should auto-create: `iCloud.co.uk.cursive.NotesToSelf` (or similar)
   - If it doesn't, click "+" and create one

---

## Step 3: Verify Your Apple Developer Account

**CloudKit requires:**
- ✅ Signed in with your Apple ID in Xcode (Preferences → Accounts)
- ✅ Apple Developer account (free or paid)
- ✅ Your device/simulator signed into iCloud (Settings → iCloud)

**To check:**
1. Xcode → Preferences → Accounts
2. Make sure your Apple ID is listed
3. Click on it → View Details → Should show team info

---

## Step 4: Build & Run

1. **Clean build** (⌘+Shift+K)
2. **Build** (⌘+B)
3. **Run on your device** (not simulator for first test)

---

## What to Expect

### First Launch After CloudKit Switch:
- ✅ App will try to load from CloudKit
- ✅ CloudKit is empty = App appears empty (expected!)
- ✅ This is normal - your old data was in UserDefaults

### If CloudKit Fails:
- ✅ Falls back to UserDefaults automatically
- ✅ Check console for error messages
- ✅ Usually means: not signed into iCloud or capability not enabled

### To Get Your Data Back:
1. Use the import feature you created
2. Paste your backup JSON
3. Import → Data goes to CloudKit!
4. Now it syncs across devices

---

## Testing Cross-Device Sync

**Once CloudKit is working on one device:**

1. **On iPhone:** Add a new entry
2. **On iPad:** Open app → Should see the entry appear within 5-10 seconds
3. **Offline test:** Turn off WiFi, add entry, turn WiFi back on → Should sync

---

## Troubleshooting

### "Account not available" error:
- Sign into iCloud on your device (Settings → iCloud)
- Make sure you're using the same Apple ID in Xcode

### Data not syncing:
- Check console logs for errors
- Verify both devices signed into same iCloud account
- Try force-quitting and reopening the app

### Build errors:
- Make sure CloudKitManager.swift is added to target
- Clean build folder (⌘+Shift+K)
- Check that CloudKit capability is enabled

### "Container not found":
- Create container manually in Signing & Capabilities
- Use format: `iCloud.co.uk.cursive.NotesToSelf`

---

## Fallback Safety

**Your data is safe:**
- If CloudKit fails → Falls back to UserDefaults
- Old data still in UserDefaults (just not visible)
- Can always import from your backup JSON
- Export/Import feature still works regardless of CloudKit

---

## Next Steps After Setup

1. ✅ Enable CloudKit capability
2. ✅ Build and run
3. ✅ App will be empty (expected)
4. ✅ Import your backup to restore data
5. ✅ Test on second device
6. ✅ Verify sync is working
7. ✅ You're done! 🎉

---

## Questions?

Check Xcode console logs - they show:
- "Loaded X notes from CloudKit" = ✅ Working
- "CloudKit not available, loading from UserDefaults fallback" = ⚠️ Not signed in
- Errors will show what went wrong


