# Address Autocomplete Setup

## Overview
The SignupView now includes Google Places Autocomplete for address entry with a fallback to manual entry.

## What's Included

### 1. AddressAutocompleteField.swift
- Custom SwiftUI component that integrates Google Places Autocomplete
- Shows real-time address suggestions as user types
- Automatically extracts city and country from selected address
- Includes a fallback to manual entry

### 2. Updated SignupView.swift
- Added address, city, and country fields
- Toggle between autocomplete and manual entry
- Validates all address fields before signup
- Saves address data to Firestore

### 3. Updated GeoGuardApp.swift
- Initializes both Google Maps and Google Places with your API key

## Features

### Google Places Autocomplete (Default)
1. User starts typing an address
2. Google suggests matching addresses in real-time
3. User selects from dropdown
4. City and country are automatically extracted
5. User can edit city/country if needed

### Manual Entry (Fallback)
1. User clicks "Enter Manually" button
2. Manually types street address, city, and country
3. All fields are validated before signup

## SPM Dependencies Required

Make sure these packages are added to your Xcode project:

1. **GoogleMaps** 
   - URL: `https://github.com/googlemaps/ios-maps-sdk`
   - Already configured ✓

2. **GooglePlaces** (NEW - needs to be added)
   - URL: `https://github.com/googlemaps/ios-places-sdk`
   - Add this via: File → Add Package Dependencies → Search for "GooglePlaces"

## Adding GooglePlaces SDK

### Option 1: Swift Package Manager (Recommended)
1. In Xcode: File → Add Package Dependencies
2. Enter: `https://github.com/googlemaps/ios-places-sdk`
3. Select version: Latest
4. Add to target: GeoGuard

### Option 2: CocoaPods
Add to your Podfile:
```ruby
pod 'GooglePlaces'
```
Then run: `pod install`

## API Key Setup

Your existing Google Maps API key is being used for Places as well.
Make sure your API key has these APIs enabled in Google Cloud Console:

1. ✓ Maps SDK for iOS (already enabled)
2. **Places API** (needs to be enabled)
3. **Places SDK for iOS** (needs to be enabled)

### Enable Places API:
1. Go to: https://console.cloud.google.com/
2. Select your project
3. Navigate to: APIs & Services → Library
4. Search for "Places API" → Enable
5. Search for "Places SDK for iOS" → Enable

## Testing

1. Run the app
2. Go to Sign Up screen
3. Start typing an address (e.g., "1600 Pennsylvania")
4. You should see autocomplete suggestions
5. Select one and verify city/country are filled
6. Or click "Enter Manually" to type it yourself

## Firestore Data Structure

User documents now include:
```json
{
  "fullName": "John Doe",
  "initials": "JD",
  "phone": "+1234567890",
  "address": "123 Main St",
  "city": "New York",
  "country": "United States",
  "vehicle": "Car",
  "createdAt": "timestamp"
}
```

## Troubleshooting

### Autocomplete not showing?
- Check that GooglePlaces SDK is properly installed
- Verify Places API is enabled in Google Cloud Console
- Check console for API errors

### "Module not found: GooglePlaces"?
- Make sure you added the GooglePlaces package
- Clean build folder (Shift+Cmd+K)
- Rebuild project

### No suggestions appearing?
- Verify internet connection
- Check API key has Places API enabled
- Check Google Cloud Console quotas
