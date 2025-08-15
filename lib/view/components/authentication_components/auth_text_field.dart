import 'package:flutter/material.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/myColors.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          focusNode: focusNode,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
              borderSide: BorderSide(
                color: inputBorderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
              borderSide: BorderSide(
                color: inputFocusedBorderColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
              borderSide: BorderSide(
                color: inputErrorBorderColor,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
              borderSide: BorderSide(
                color: inputErrorBorderColor,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
              borderSide: BorderSide(
                color: inputBorderColor.withOpacity(0.5),
              ),
            ),
            filled: true,
            fillColor: enabled 
                ? inputBackgroundColor
                : inputBackgroundColor.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AuthConstants.defaultPadding,
              vertical: AuthConstants.defaultPadding,
            ),
            labelStyle: TextStyle(
              color: inputLabelColor,
            ),
            hintStyle: TextStyle(
              color: textHintColor,
            ),
            errorStyle: TextStyle(
              color: errorColor,
              fontSize: 12,
            ),
          ),
          style: TextStyle(
            color: textPrimaryColor,
            fontSize: 16,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AuthConstants.smallPadding),
          Text(
            errorText!,
            style: TextStyle(
              color: errorColor,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
} 