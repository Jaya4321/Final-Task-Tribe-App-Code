import 'package:flutter/material.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/myColors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    required this.child,
    this.backgroundColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? loadingOverlayColor,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AuthConstants.largePadding),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        indicatorColor ?? primaryColor,
                      ),
                    ),
                    // if (message != null) ...[
                    //   const SizedBox(height: AuthConstants.defaultPadding),
                    //   Text(
                    //     message!,
                    //     style: TextStyle(
                    //       color: textPrimaryColor,
                    //       fontWeight: FontWeight.normal,
                    //       decoration: TextDecoration.none,
                    //       fontFamily: null,
                    //       fontSize: 18,
                    //     ),
                    //     textAlign: TextAlign.center,
                    //   ),
                    // ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LoadingDialog extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingDialog({
    super.key,
    required this.message,
    this.backgroundColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor ?? surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(AuthConstants.largePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                indicatorColor ?? primaryColor,
              ),
            ),
            const SizedBox(height: AuthConstants.defaultPadding),
            Text(
              message,
              style: TextStyle(color: textPrimaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final String? loadingText;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.loadingText,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? AuthConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? buttonPrimaryColor,
          foregroundColor: textColor ?? buttonTextColor,
          disabledBackgroundColor: buttonDisabledColor,
          disabledForegroundColor: buttonTextDisabledColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AuthConstants.defaultPadding,
            vertical: AuthConstants.defaultPadding,
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textColor ?? buttonTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AuthConstants.defaultPadding),
                  Text(
                    loadingText ?? 'Loading...',
                    style: TextStyle(
                      color: textColor ?? buttonTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: textColor ?? buttonTextColor,
                      ),
                      const SizedBox(width: AuthConstants.smallPadding),
                      Text(
                        text,
                        style: TextStyle(
                          color: textColor ?? buttonTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? buttonTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
      ),
    );
  }
} 