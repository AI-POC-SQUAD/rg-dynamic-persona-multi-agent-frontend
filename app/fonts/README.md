# Custom Fonts for Orizon UI

This directory should contain the NouvelR font files:

- NouvelR-Regular.ttf (weight: 400)
- NouvelR-Light.ttf (weight: 300) 
- NouvelR-Book.ttf (weight: 350)
- NouvelR-Bold.ttf (weight: 700)

The fonts are referenced in the Figma design but need to be obtained from the design system.
If the fonts are not available, the app will fall back to system fonts.

To add the fonts:
1. Obtain the NouvelR font files from the design team
2. Place them in this fonts/ directory
3. Run `flutter pub get` to update dependencies
4. Run `flutter clean` and rebuild the app