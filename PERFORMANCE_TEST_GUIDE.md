# Performance Testing Guide

## iOS App Optimizations Testing

This guide helps validate the performance improvements implemented for the Prestige iOS app.

## 🎯 Expected Performance Gains

| Feature | Before | After | Improvement |
|---------|--------|-------|-------------|
| API Calls per screen | 30+ requests | 1 batch request | **85% reduction** |
| Image loading time | 3-8 seconds | 100-300ms | **95% faster** |
| Rating operations | 2-5 seconds | 200-500ms | **90% faster** |
| Memory usage | 200-400MB | 50-100MB | **75% reduction** |
| Cache hit ratio | 0% | 85%+ | **New capability** |

## ✅ Testing Checklist

### 1. Batch Endpoint Integration

**Test**: Open a screen with multiple music items
- [ ] Check console for "🌐 Fetching X items via batch endpoint" 
- [ ] Verify single POST to `/api/library/items/batch`
- [ ] Confirm no individual item requests
- [ ] Test fallback when batch fails

**Expected Console Output**:
```
🌐 Fetching 12 items via batch endpoint (cached: 3)
✅ Batch endpoint returned 12 items
📦 Cache hit for track_abc123
```

### 2. Image Caching Performance

**Test**: Scroll through image-heavy screens
- [ ] Images load instantly on second view
- [ ] No flickering or reloading
- [ ] Smooth scrolling performance
- [ ] Memory usage remains stable

**Manual Test**:
1. Open Home tab with album art
2. Scroll up/down multiple times
3. Switch tabs and return
4. Images should load instantly

### 3. Rate Limiting Behavior

**Test**: Make rapid API requests
- [ ] Console shows rate limit warnings before 429 errors
- [ ] Automatic retry with exponential backoff
- [ ] Graceful degradation during limits

**Expected Console Output**:
```
🚦 Rate limit reached for Library API. Wait 2.5s
⏳ Rate limited. Retrying after 2.0 seconds (attempt 2/3)
```

### 4. Response Caching

**Test**: Navigate between screens
- [ ] Second visits load instantly from cache
- [ ] Cache statistics show hits/misses
- [ ] Expired data refreshes automatically

**Console Commands** (in simulator):
```swift
// Check cache stats
print(ResponseCacheService.shared.cacheStats)

// Clear cache to test fresh loads
ResponseCacheService.shared.clearAllCache()
```

### 5. Memory Performance

**Test**: Extended app usage
- [ ] Memory usage stays under 100MB
- [ ] No memory leaks during navigation
- [ ] Image cache respects size limits

**Xcode Memory Gauge**:
1. Run app in Xcode
2. Open Memory Report
3. Navigate through app extensively
4. Memory should plateau, not continuously grow

## 🔍 Performance Monitoring

### Key Console Logs to Watch

**Good Performance Indicators**:
```
📦 All 15 items found in cache
📸 Cached image: .disk
✅ Batch endpoint returned 20 items
📊 Cache hit ratio: 87%
```

**Issues to Investigate**:
```
❌ Batch request failed: HTTP Error 429
❌ Image load failed: Network error
🔄 Falling back to individual requests for 10 items
⚠️ Rate limit reached for Rating API
```

### Xcode Instruments

**Network Activity**:
- Total requests should be 85% fewer
- Request sizes 60% smaller (compression)
- Fewer DNS lookups from caching

**Energy Impact**:
- CPU usage should be lower
- Network usage more efficient
- Background activity optimized

## 🐛 Common Issues & Solutions

### Batch Endpoint 404
**Problem**: New endpoint not deployed to backend
**Solution**: Verify backend deployment of batch endpoint

### Images Not Caching
**Problem**: Kingfisher not properly configured
**Solution**: Check KINGFISHER_SETUP.md installation

### High Memory Usage
**Problem**: Cache limits not respected
**Solution**: Verify cache configuration in ImageCacheManager

### Rate Limiting Errors
**Problem**: Client-side throttling disabled
**Solution**: Check RateLimitService configuration

## 📊 Benchmark Tests

### Load Time Test
1. Clear all caches
2. Time app startup to first content
3. **Target**: Under 2 seconds

### Navigation Performance
1. Navigate between 10 different screens
2. Measure time to load each screen
3. **Target**: Under 300ms per screen

### Memory Stress Test
1. Scroll through 100+ items with images
2. Monitor memory usage continuously
3. **Target**: Memory stable under 100MB

### Offline Capability
1. Enable airplane mode
2. Navigate to previously visited screens
3. **Target**: Cached content loads normally

## 🏆 Success Criteria

The optimizations are successful when:

- [ ] **85%+ reduction** in API requests per screen
- [ ] **95%+ faster** image loading after cache warmup
- [ ] **90%+ faster** rating operations
- [ ] **75%+ reduction** in memory usage
- [ ] **85%+ cache hit ratio** during normal usage
- [ ] **Smooth 60fps** scrolling with images
- [ ] **No network errors** from rate limiting
- [ ] **Graceful offline** experience with cached data

## 🚀 Production Readiness

Before production deployment:

- [ ] All performance targets met
- [ ] No memory leaks detected
- [ ] Rate limiting working properly
- [ ] Offline functionality tested
- [ ] Error handling comprehensive
- [ ] Logging for monitoring enabled

This testing validates that your iOS app now maximizes the performance gains from your excellent backend optimizations!