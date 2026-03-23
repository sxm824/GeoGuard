# Quick Start: Admin Location Tracking

## For Admins

### Accessing Location Tracking

1. **Login** as Admin or Manager
2. Go to **Dashboard**
3. Tap **"Track Field Personnel"** (blue location icon)

### Using the Map View

#### View All Personnel
- Map shows red markers for all active field personnel
- Numbers in top-left show count of active personnel
- Map auto-zooms to fit all markers

#### Select a Person
**Two ways to select:**
1. Tap the marker on the map
2. Tap "X Active" button → tap person in list

**What happens:**
- Marker turns blue
- Detailed card appears at bottom
- Marker jumps to top layer

#### View Person Details
The bottom card shows:
- Profile: Name, email, avatar
- Location: Coordinates, address
- Status: Last updated time, speed
- Actions: Directions, Send Alert

#### Get Directions
1. Select a person
2. Tap **"Directions"** button
3. Apple Maps opens with navigation

#### Send Emergency Alert
1. Select a person
2. Tap **"Send Alert"** button
3. Create and send alert

#### View User List
1. Tap **"X Active"** button (top-left)
2. Drawer slides up from bottom
3. Shows all field personnel with:
   - Name and avatar
   - Last update time
   - Location availability status
4. Tap any person to select
5. Tap **X** to close drawer

#### Refresh Data
- Tap **circular arrow** icon (top-right)
- Or pull down to refresh

#### Deselect
- Tap anywhere on the map
- Selected marker turns red
- Details card disappears

## For Field Personnel

### Enable Location Sharing

1. **Login** to GeoGuard app
2. App automatically requests location permission
3. Accept **"Always"** or **"While Using"** permission
4. Location updates every 30 seconds (default)

### What Admins See

Admins can see:
- ✅ Your current location (real-time)
- ✅ Your speed and heading
- ✅ Your last update time
- ✅ Your name and contact info

Admins **cannot** see:
- ❌ Your location history beyond current position
- ❌ Your location when app is closed (depends on permissions)
- ❌ Your personal data beyond work profile

### Privacy Notes

- Location sharing is for work safety and coordination
- Only your organization's admins/managers can see your location
- Other field personnel **cannot** see each other's locations
- Location data is tied to your tenant (organization)
- Data is secured with Firebase security rules

## Troubleshooting

### "No Active Field Personnel" Message

**Possible causes:**
1. No field personnel in organization yet
2. Field personnel haven't logged in
3. Field personnel haven't granted location permissions
4. Location services disabled on device

**Solutions:**
1. Create invitations for field personnel
2. Ask field personnel to login at least once
3. Guide users to enable location permissions:
   - iPhone: Settings → Privacy & Security → Location Services → GeoGuard → "Always"
4. Enable Location Services:
   - iPhone: Settings → Privacy & Security → Location Services → ON

### Location Not Updating

**For Field Personnel:**
1. Check location permissions: Settings → GeoGuard → Location → "Always"
2. Check Location Services are ON
3. Check internet connection (WiFi or cellular)
4. Restart the app
5. Check device battery (Low Power Mode may limit updates)

**For Admins:**
1. Tap refresh button (top-right)
2. Pull down to refresh
3. Check internet connection
4. Try closing and reopening the tracking view

### Markers Not Appearing

1. Check Firestore rules are deployed
2. Verify field personnel have `role: "field_personnel"`
3. Check that locations are being written to Firestore:
   - Firebase Console → Firestore → `locations` collection
4. Check console logs for errors

### Map Not Loading

1. Verify Google Maps API key is configured
2. Check internet connection
3. Restart app
4. Check Google Maps SDK is properly installed

### "Permission Denied" Errors

1. Verify your account has Admin or Manager role
2. Check Firestore rules are properly deployed
3. Verify you're logged in
4. Check tenantId is correctly set

## Best Practices

### For Admins
- ✅ Refresh periodically for latest data
- ✅ Communicate with field personnel before tracking
- ✅ Use for legitimate business purposes only
- ✅ Respect privacy outside work hours
- ✅ Use Send Alert for urgent situations only

### For Organizations
- ✅ Have clear location tracking policy
- ✅ Inform employees about tracking
- ✅ Define business hours for tracking
- ✅ Train admins on proper usage
- ✅ Regular privacy reviews

### For Field Personnel
- ✅ Keep app running in background
- ✅ Ensure "Always" location permission
- ✅ Maintain good cellular/WiFi connection
- ✅ Keep device charged
- ✅ Report location issues immediately

## Technical Details

### Update Frequency
- **Default**: Every 30 seconds
- **When moving**: More frequent
- **When stationary**: Less frequent (battery saving)

### Data Usage
- Approximately 1-2 MB per hour of active tracking
- Uses Firebase real-time updates (minimal overhead)

### Battery Impact
- Estimated 5-10% additional battery drain per day
- Optimized for background operation
- Uses significant location change triggers

### Accuracy
- Typically 10-50 meters with GPS
- Better outdoors with clear sky view
- Less accurate indoors or in urban canyons

## Support

### Need Help?
1. Check this guide first
2. Review error messages in console
3. Check Firebase Console for data
4. Contact system administrator

### Reporting Issues
Include:
1. Your role (Admin/Manager/Field Personnel)
2. What you were trying to do
3. What happened instead
4. Screenshots if possible
5. Console log messages

## Related Features

- **Alert Center**: Send emergency alerts to field personnel
- **Geofences**: Set up location-based alerts
- **User Management**: Manage field personnel accounts
- **Company Settings**: Configure organization settings
