# Backend Prestige Calculation Implementation Guide

## Overview
This document provides the complete implementation for moving prestige tier calculations to the backend. This includes both dev/testing thresholds (extremely low for quick testing) and production thresholds (realistic values).

## Current iOS Implementation Context

The iOS app currently has a dual-threshold system:
- **Dev Mode**: Ultra-low thresholds for quick testing (enabled during development)
- **Production Mode**: Realistic thresholds for real users

### Dev vs Production Threshold Comparison

#### Track Thresholds (Minutes)
```
Tier          | Dev Mode | Production Mode
--------------|----------|----------------
Bronze        |    2     |      60
Silver        |    5     |     150  
Gold          |    8     |     3001
Sapphire      |   12     |     500
Emerald       |   18     |     800
Diamond       |   25     |    1200
Opal          |   35     |    1600
Obsidian      |   50     |    2200
Void          |   75     |    3000
Quantum       |   90     |    6000
Dark Matter   |  120     |   15000
```

#### Album Thresholds (Minutes)  
```
Tier          | Dev Mode | Production Mode
--------------|----------|----------------
Bronze        |    5     |     200
Silver        |   10     |     350
Gold          |   15     |     500
Sapphire      |   20     |    1000
Emerald       |   30     |    2000
Diamond       |   40     |    4000
Opal          |   55     |    6000
Obsidian      |   70     |   10000
Void          |   85     |   15000
Quantum       |  100     |   30000
Dark Matter   |  120     |   50000
```

#### Artist Thresholds (Minutes)
```
Tier          | Dev Mode | Production Mode  
--------------|----------|----------------
Bronze        |   10     |     400
Silver        |   15     |     750
Gold          |   20     |    1200
Sapphire      |   30     |    2000
Emerald       |   40     |    3000
Diamond       |   50     |    6000
Opal          |   65     |   10000
Obsidian      |   80     |   15000
Void          |   95     |   25000
Quantum       |  110     |   50000
Dark Matter   |  120     |  100000
```

## Backend Implementation

### 1. Configuration Management

Create a configuration system that can be easily toggled between dev and production:

```javascript
// config/prestigeThresholds.js
const PRESTIGE_CONFIG = {
  // Toggle between dev and production thresholds
  USE_DEV_THRESHOLDS: process.env.USE_DEV_PRESTIGE_THRESHOLDS === 'true',
  
  // Development thresholds (ultra-low for quick testing)
  DEV_THRESHOLDS: {
    track:  [2, 5, 8, 12, 18, 25, 35, 50, 75, 90, 120],
    album:  [5, 10, 15, 20, 30, 40, 55, 70, 85, 100, 120], 
    artist: [10, 15, 20, 30, 40, 50, 65, 80, 95, 110, 120]
  },
  
  // Production thresholds (realistic values)
  PRODUCTION_THRESHOLDS: {
    track:  [60, 150, 300, 500, 800, 1200, 1600, 2200, 3000, 6000, 15000],
    album:  [200, 350, 500, 1000, 2000, 4000, 6000, 10000, 15000, 30000, 50000],
    artist: [400, 750, 1200, 2000, 3000, 6000, 10000, 15000, 25000, 50000, 100000]
  }
};

// Prestige tier names in order (matches iOS enum)
const PRESTIGE_TIERS = [
  "None",
  "Bronze", 
  "Silver",
  "Gold", 
  "Sapphire",
  "Emerald",
  "Diamond",
  "Opal",
  "Obsidian", 
  "Void",
  "Quantum",
  "Dark Matter"
];

function getThresholds(itemType) {
  const thresholds = PRESTIGE_CONFIG.USE_DEV_THRESHOLDS 
    ? PRESTIGE_CONFIG.DEV_THRESHOLDS 
    : PRESTIGE_CONFIG.PRODUCTION_THRESHOLDS;
    
  return thresholds[itemType.toLowerCase()] || [];
}

function calculatePrestigeTier(totalTimeMinutes, itemType) {
  const thresholds = getThresholds(itemType);
  
  // Find the highest tier the user has achieved
  let tierIndex = 0;
  for (let i = 0; i < thresholds.length; i++) {
    if (totalTimeMinutes >= thresholds[i]) {
      tierIndex = i + 1; // +1 because index 0 is "None"
    } else {
      break;
    }
  }
  
  return PRESTIGE_TIERS[tierIndex];
}

module.exports = {
  PRESTIGE_CONFIG,
  PRESTIGE_TIERS,
  getThresholds,
  calculatePrestigeTier
};
```

### 2. Environment Configuration

Add to your environment variables:

```bash
# .env.development
USE_DEV_PRESTIGE_THRESHOLDS=true

# .env.production  
USE_DEV_PRESTIGE_THRESHOLDS=false
```

### 3. Enhanced Comparison Endpoint Implementation

Update your enhanced comparison endpoints to include prestige calculation:

```javascript
// controllers/friendComparison.js
const { calculatePrestigeTier } = require('../config/prestigeThresholds');

async function getEnhancedTrackComparison(req, res) {
  try {
    const { userId, trackId, friendId } = req.params;
    
    // Get listening data for both user and friend
    const userListeningData = await getUserTrackListeningTime(userId, trackId);
    const friendListeningData = await getUserTrackListeningTime(friendId, trackId);
    
    // Get rating data
    const userRating = await getUserTrackRating(userId, trackId);
    const friendRating = await getUserTrackRating(friendId, trackId);
    
    // Get track metadata
    const trackData = await getTrackMetadata(trackId);
    const friendData = await getUserData(friendId);
    
    // Calculate prestige tiers (convert seconds to minutes)
    const userListeningMinutes = Math.floor((userListeningData?.totalTime || 0) / 60);
    const friendListeningMinutes = Math.floor((friendListeningData?.totalTime || 0) / 60);
    
    const userPrestigeTier = calculatePrestigeTier(userListeningMinutes, 'track');
    const friendPrestigeTier = calculatePrestigeTier(friendListeningMinutes, 'track');
    
    const response = {
      itemId: trackId,
      itemType: 'track',
      itemName: trackData.name,
      itemImageUrl: trackData.imageUrl,
      friendId: friendId,
      friendNickname: friendData.nickname || friendData.name,
      userStats: {
        listeningTime: userListeningData?.totalTime || 0, // in seconds
        ratingScore: userRating?.score || null,
        position: userRating?.position || null,
        prestigeTier: userPrestigeTier // ← CALCULATED HERE
      },
      friendStats: {
        listeningTime: friendListeningData?.totalTime || 0, // in seconds
        ratingScore: friendRating?.score || null, 
        position: friendRating?.position || null,
        prestigeTier: friendPrestigeTier // ← CALCULATED HERE
      }
    };
    
    res.json(response);
  } catch (error) {
    console.error('Error in getEnhancedTrackComparison:', error);
    res.status(500).json({ error: 'Failed to get track comparison data' });
  }
}

async function getEnhancedAlbumComparison(req, res) {
  try {
    const { userId, albumId, friendId } = req.params;
    
    // Get listening data for both user and friend
    const userListeningData = await getUserAlbumListeningTime(userId, albumId);
    const friendListeningData = await getUserAlbumListeningTime(friendId, albumId);
    
    // Get rating data
    const userRating = await getUserAlbumRating(userId, albumId);
    const friendRating = await getUserAlbumRating(friendId, albumId);
    
    // Get album metadata
    const albumData = await getAlbumMetadata(albumId);
    const friendData = await getUserData(friendId);
    
    // Calculate prestige tiers (convert seconds to minutes)
    const userListeningMinutes = Math.floor((userListeningData?.totalTime || 0) / 60);
    const friendListeningMinutes = Math.floor((friendListeningData?.totalTime || 0) / 60);
    
    const userPrestigeTier = calculatePrestigeTier(userListeningMinutes, 'album');
    const friendPrestigeTier = calculatePrestigeTier(friendListeningMinutes, 'album');
    
    const response = {
      itemId: albumId,
      itemType: 'album',
      itemName: albumData.name,
      itemImageUrl: albumData.imageUrl,
      friendId: friendId,
      friendNickname: friendData.nickname || friendData.name,
      userStats: {
        listeningTime: userListeningData?.totalTime || 0,
        ratingScore: userRating?.score || null,
        position: userRating?.position || null,
        prestigeTier: userPrestigeTier // ← CALCULATED HERE
      },
      friendStats: {
        listeningTime: friendListeningData?.totalTime || 0,
        ratingScore: friendRating?.score || null,
        position: friendRating?.position || null, 
        prestigeTier: friendPrestigeTier // ← CALCULATED HERE
      }
    };
    
    res.json(response);
  } catch (error) {
    console.error('Error in getEnhancedAlbumComparison:', error);
    res.status(500).json({ error: 'Failed to get album comparison data' });
  }
}

async function getEnhancedArtistComparison(req, res) {
  try {
    const { userId, artistId, friendId } = req.params;
    
    // Get listening data for both user and friend
    const userListeningData = await getUserArtistListeningTime(userId, artistId);
    const friendListeningData = await getUserArtistListeningTime(friendId, artistId);
    
    // Get rating data
    const userRating = await getUserArtistRating(userId, artistId);
    const friendRating = await getUserArtistRating(friendId, artistId);
    
    // Get artist metadata  
    const artistData = await getArtistMetadata(artistId);
    const friendData = await getUserData(friendId);
    
    // Calculate prestige tiers (convert seconds to minutes)
    const userListeningMinutes = Math.floor((userListeningData?.totalTime || 0) / 60);
    const friendListeningMinutes = Math.floor((friendListeningData?.totalTime || 0) / 60);
    
    const userPrestigeTier = calculatePrestigeTier(userListeningMinutes, 'artist');
    const friendPrestigeTier = calculatePrestigeTier(friendListeningMinutes, 'artist');
    
    const response = {
      itemId: artistId,
      itemType: 'artist', 
      itemName: artistData.name,
      itemImageUrl: artistData.imageUrl,
      friendId: friendId,
      friendNickname: friendData.nickname || friendData.name,
      userStats: {
        listeningTime: userListeningData?.totalTime || 0,
        ratingScore: userRating?.score || null,
        position: userRating?.position || null,
        prestigeTier: userPrestigeTier // ← CALCULATED HERE
      },
      friendStats: {
        listeningTime: friendListeningData?.totalTime || 0,
        ratingScore: friendRating?.score || null,
        position: friendRating?.position || null,
        prestigeTier: friendPrestigeTier // ← CALCULATED HERE
      }
    };
    
    res.json(response);
  } catch (error) {
    console.error('Error in getEnhancedArtistComparison:', error);
    res.status(500).json({ error: 'Failed to get artist comparison data' });
  }
}

module.exports = {
  getEnhancedTrackComparison,
  getEnhancedAlbumComparison, 
  getEnhancedArtistComparison
};
```

### 4. Utility Functions Implementation

You'll need these helper functions (adapt to your database structure):

```javascript
// utils/listeningTimeHelpers.js

async function getUserTrackListeningTime(userId, trackId) {
  // Query your database for user's total listening time for this track
  // Return format: { totalTime: number_in_seconds }
  const result = await db.query(`
    SELECT SUM(play_duration_ms) as total_time_ms 
    FROM user_listening_history 
    WHERE user_id = ? AND track_id = ?
  `, [userId, trackId]);
  
  return {
    totalTime: Math.floor((result[0]?.total_time_ms || 0) / 1000) // convert to seconds
  };
}

async function getUserAlbumListeningTime(userId, albumId) {
  // Query your database for user's total listening time for this album
  const result = await db.query(`
    SELECT SUM(play_duration_ms) as total_time_ms
    FROM user_listening_history ulh
    JOIN tracks t ON ulh.track_id = t.id  
    WHERE ulh.user_id = ? AND t.album_id = ?
  `, [userId, albumId]);
  
  return {
    totalTime: Math.floor((result[0]?.total_time_ms || 0) / 1000)
  };
}

async function getUserArtistListeningTime(userId, artistId) {
  // Query your database for user's total listening time for this artist
  const result = await db.query(`
    SELECT SUM(play_duration_ms) as total_time_ms
    FROM user_listening_history ulh
    JOIN tracks t ON ulh.track_id = t.id
    JOIN track_artists ta ON t.id = ta.track_id
    WHERE ulh.user_id = ? AND ta.artist_id = ?
  `, [userId, artistId]);
  
  return {
    totalTime: Math.floor((result[0]?.total_time_ms || 0) / 1000)
  };
}

module.exports = {
  getUserTrackListeningTime,
  getUserAlbumListeningTime,
  getUserArtistListeningTime
};
```

### 5. Toggle Between Dev and Production

To switch between dev and production thresholds:

#### For Development/Testing:
```bash
# Set environment variable
export USE_DEV_PRESTIGE_THRESHOLDS=true
# or add to .env file
echo "USE_DEV_PRESTIGE_THRESHOLDS=true" >> .env
```

#### For Production:
```bash
# Set environment variable  
export USE_DEV_PRESTIGE_THRESHOLDS=false
# or add to .env file
echo "USE_DEV_PRESTIGE_THRESHOLDS=false" >> .env
```

#### Runtime Toggle (Advanced):
You can also create an admin endpoint to toggle this at runtime:

```javascript
// controllers/admin.js (protect with admin authentication)
app.post('/admin/toggle-dev-thresholds', authenticateAdmin, (req, res) => {
  const { enabled } = req.body;
  PRESTIGE_CONFIG.USE_DEV_THRESHOLDS = enabled;
  res.json({ 
    success: true, 
    devThresholdsEnabled: PRESTIGE_CONFIG.USE_DEV_THRESHOLDS 
  });
});

app.get('/admin/prestige-config', authenticateAdmin, (req, res) => {
  res.json({
    devThresholdsEnabled: PRESTIGE_CONFIG.USE_DEV_THRESHOLDS,
    currentThresholds: {
      track: getThresholds('track'),
      album: getThresholds('album'), 
      artist: getThresholds('artist')
    }
  });
});
```

## Testing Implementation

### 1. Test Dev Thresholds
With `USE_DEV_PRESTIGE_THRESHOLDS=true`, a user with:
- **2 minutes** on a track = Bronze tier
- **25 minutes** on a track = Diamond tier  
- **120 minutes** on a track = Dark Matter tier

### 2. Test Production Thresholds  
With `USE_DEV_PRESTIGE_THRESHOLDS=false`, a user with:
- **60 minutes** on a track = Bronze tier
- **1200 minutes** on a track = Diamond tier
- **15000 minutes** on a track = Dark Matter tier

### 3. Validation Tests
Test both flows return proper prestige data:

```bash
# Test enhanced comparison endpoint
curl -X GET "/api/friendships/user123/compare/track/track456/with/friend789"

# Expected response should include:
{
  "userStats": {
    "listeningTime": 1800,  // 30 minutes in seconds
    "prestigeTier": "Emerald"  // Based on current thresholds
  },
  "friendStats": {
    "listeningTime": 3600,  // 60 minutes in seconds  
    "prestigeTier": "Diamond"  // Based on current thresholds
  }
}
```

## Deployment Strategy

### 1. Development Phase
- Use `USE_DEV_PRESTIGE_THRESHOLDS=true`
- Test with ultra-low thresholds for quick validation
- Verify prestige backgrounds display correctly in iOS app

### 2. Staging/QA Phase  
- Test both dev and production thresholds
- Validate threshold switching works correctly
- Ensure no performance issues with calculation

### 3. Production Deployment
- Set `USE_DEV_PRESTIGE_THRESHOLDS=false`
- Deploy with production thresholds
- Monitor for any issues with realistic values

### 4. Future Updates
- Thresholds can be adjusted by modifying the arrays in config
- No iOS app updates needed for threshold changes
- Easy toggle between modes for testing

## Benefits of This Approach

1. **Centralized Calculation**: All prestige logic in backend
2. **Easy Testing**: Dev thresholds allow quick tier progression
3. **Consistent Data**: Both comparison flows use same calculation
4. **Flexible Configuration**: Easy to adjust thresholds without app updates  
5. **Environment-Specific**: Different thresholds per environment
6. **Performance**: Calculated once on server vs multiple times on client

This implementation ensures your friend comparison feature works consistently across both flows while providing the flexibility to test with realistic or accelerated progression rates.