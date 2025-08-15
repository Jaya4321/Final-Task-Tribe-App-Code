import 'package:flutter/material.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/myColors.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool isOutlined;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? buttonPrimaryColor;
    final effectiveTextColor = textColor ?? buttonTextColor;

    Widget buttonChild = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                ),
              ),
              const SizedBox(width: AuthConstants.defaultPadding),
              Text(
                'Loading...',
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: effectiveTextColor,
                  size: 20,
                ),
                const SizedBox(width: AuthConstants.smallPadding),
              ],
              Text(
                text,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            side: BorderSide(
              color: isEnabled ? effectiveBackgroundColor : buttonDisabledColor,
              width: 2,
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: isEnabled ? effectiveBackgroundColor : buttonTextDisabledColor,
            padding: EdgeInsets.symmetric(
              horizontal: AuthConstants.largePadding,
              vertical: AuthConstants.defaultPadding,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? effectiveBackgroundColor : buttonDisabledColor,
            foregroundColor: isEnabled ? effectiveTextColor : buttonTextDisabledColor,
            padding: EdgeInsets.symmetric(
              horizontal: AuthConstants.largePadding,
              vertical: AuthConstants.defaultPadding,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
            ),
            elevation: isEnabled ? 2 : 0,
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 52,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isEnabled && !isLoading ? onPressed : null,
              style: buttonStyle,
              child: buttonChild,
            )
          : ElevatedButton(
              onPressed: isEnabled && !isLoading ? onPressed : null,
              style: buttonStyle,
              child: buttonChild,
            ),
    );
  }
}

class AuthTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? textColor;
  final TextStyle? textStyle;

  const AuthTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.textColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? linkColor;

    return TextButton(
      onPressed: (isEnabled && !isLoading) ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: color.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AuthConstants.defaultPadding,
          vertical: AuthConstants.smallPadding,
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          : Text(
              text,
              style: textStyle ??
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
    );
  }
}

class AuthIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final String? tooltip;

  const AuthIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? 48.0;
    final color = iconColor ?? iconPrimaryColor;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: IconButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(
                icon,
                color: color,
                size: 24,
              ),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledForegroundColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
          ),
        ),
      ),
    );
  }
} 