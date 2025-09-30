# Breathing Animation Implementation - Focus Group

## Feature Overview ✅

Added a breathing animation effect to the white frame containing the discussion subject in the Focus Group Answers page. The animation cycles between colors #BF046B and #F26716, creating a glowing effect that appears only during loading.

## Implementation Details

### Added Components:

1. **Animation Controller & Animations**:
   ```dart
   // Breathing animation controller
   late AnimationController _breathingController;
   late Animation<double> _breathingAnimation;
   late Animation<Color?> _colorAnimation;
   ```

2. **Animation Initialization**:
   ```dart
   _breathingController = AnimationController(
     duration: const Duration(seconds: 3),
     vsync: this,
   );
   
   _breathingAnimation = Tween<double>(
     begin: 0.0,
     end: 1.0,
   ).animate(CurvedAnimation(
     parent: _breathingController,
     curve: Curves.easeInOut,
   ));
   
   _colorAnimation = TweenSequence<Color?>([
     TweenSequenceItem(
       tween: ColorTween(
         begin: const Color(0xFFBF046B), // #BF046B
         end: const Color(0xFFF26716),   // #F26716
       ),
       weight: 50,
     ),
     TweenSequenceItem(
       tween: ColorTween(
         begin: const Color(0xFFF26716),   // #F26716
         end: const Color(0xFFBF046B),     // #BF046B
       ),
       weight: 50,
     ),
   ]).animate(_breathingController);
   ```

### Animation Control:

1. **Start Animation**: When loading begins
   ```dart
   // Start breathing animation
   _breathingController.repeat();
   ```

2. **Stop Animation**: When loading completes (success or error)
   ```dart
   // Stop breathing animation
   _breathingController.stop();
   ```

### Visual Effect Implementation:

```dart
AnimatedBuilder(
  animation: _breathingController,
  builder: (context, child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Standard shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          // Breathing effect - only during loading
          if (_isLoading)
            BoxShadow(
              color: _colorAnimation.value?.withOpacity(0.6) ?? Colors.transparent,
              blurRadius: 30 + (20 * _breathingAnimation.value),
              spreadRadius: 5 + (10 * _breathingAnimation.value),
              offset: const Offset(0, 0),
            ),
        ],
      ),
      // ... content
    );
  },
)
```

## Animation Behavior:

### Color Sequence:
- **Phase 1**: #BF046B → #F26716 (50% of cycle)
- **Phase 2**: #F26716 → #BF046B (50% of cycle)
- **Duration**: 3 seconds per complete cycle
- **Curve**: Smooth easeInOut for natural breathing effect

### Visual Properties:
- **Blur Radius**: 30-50px (animated)
- **Spread Radius**: 5-15px (animated)
- **Opacity**: 60% for glowing effect
- **Timing**: Only active during `_isLoading = true`

## Integration Flow:

1. **Page Load** → Initialize animation controller
2. **API Request Starts** → `_breathingController.repeat()` 
3. **Loading State** → Breathing glow effect visible behind white frame
4. **API Response** → `_breathingController.stop()`
5. **Results Displayed** → Normal white frame (no glow)

## Technical Features:

- **TickerProviderStateMixin**: Required for animation controller
- **Proper Disposal**: Animation controller disposed in `dispose()`
- **Conditional Rendering**: Glow effect only shows when `_isLoading = true`
- **Performance**: Animation stops completely when not needed
- **Error Handling**: Animation stops on both success and error cases

## Visual Design:

- **Frame**: White container with rounded corners (24px)
- **Glow Effect**: Animated shadow behind frame
- **Color Breathing**: Smooth transition between brand colors
- **Natural Motion**: EaseInOut curve mimics natural breathing
- **Non-Intrusive**: Effect is subtle and professional

## User Experience:

- ✅ **Clear Loading State**: Users know system is processing
- ✅ **Engaging Visual**: Breathing effect is calming and professional
- ✅ **Brand Integration**: Uses brand colors #BF046B and #F26716
- ✅ **Performance**: Animation only runs when needed
- ✅ **Accessibility**: Visual feedback without being distracting

---
*Updated: September 30, 2025*
*Status: Successfully implemented and tested*
*Animation Duration: 3 seconds per cycle*
*Colors: #BF046B ↔ #F26716*