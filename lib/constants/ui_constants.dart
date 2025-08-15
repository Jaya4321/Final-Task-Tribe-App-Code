import 'package:flutter/material.dart';
import 'myColors.dart';

// General UI Constants
class UIConstants {
  // Spacing System
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;
  static const double borderRadiusCircular = 50.0;

  // Typography
  static const String fontFamily = 'Roboto';
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeXXXL = 32.0;

  // Button Heights
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;

  // Input Heights
  static const double inputHeightS = 40.0;
  static const double inputHeightM = 48.0;
  static const double inputHeightL = 56.0;

  // Icon Sizes
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Elevation
  static const double elevationS = 1.0;
  static const double elevationM = 2.0;
  static const double elevationL = 4.0;
  static const double elevationXL = 8.0;

  // Screen Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
}

// Text Styles
class TextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: UIConstants.fontSizeXXXL,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: UIConstants.fontSizeXXL,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: UIConstants.fontSizeXL,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: UIConstants.fontSizeL,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: UIConstants.fontSizeM,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );

  static const TextStyle caption = TextStyle(
    fontSize: UIConstants.fontSizeS,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );

  static const TextStyle button = TextStyle(
    fontSize: UIConstants.fontSizeM,
    fontWeight: FontWeight.w500,
    color: buttonTextColor,
  );
}

// Common Widget Styles
class WidgetStyles {
  static const BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.all(Radius.circular(UIConstants.borderRadiusL)),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 4.0,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const InputDecoration inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(UIConstants.borderRadiusM)),
      borderSide: BorderSide(color: inputBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(UIConstants.borderRadiusM)),
      borderSide: BorderSide(color: inputBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(UIConstants.borderRadiusM)),
      borderSide: BorderSide(color: inputFocusedBorderColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(UIConstants.borderRadiusM)),
      borderSide: BorderSide(color: inputErrorBorderColor),
    ),
    filled: true,
    fillColor: inputBackgroundColor,
    contentPadding: EdgeInsets.symmetric(
      horizontal: UIConstants.spacingM,
      vertical: UIConstants.spacingS,
    ),
  );

  static const ButtonStyle primaryButtonStyle = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(buttonPrimaryColor),
    foregroundColor: WidgetStatePropertyAll(buttonTextColor),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(
        horizontal: UIConstants.spacingL,
        vertical: UIConstants.spacingM,
      ),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(UIConstants.borderRadiusM)),
      ),
    ),
  );

  static const ButtonStyle secondaryButtonStyle = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(Colors.transparent),
    foregroundColor: WidgetStatePropertyAll(primaryColor),
    side: WidgetStatePropertyAll(
      BorderSide(color: primaryColor),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(
        horizontal: UIConstants.spacingL,
        vertical: UIConstants.spacingM,
      ),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(UIConstants.borderRadiusM)),
      ),
    ),
  );
} 