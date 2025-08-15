import 'package:flutter/material.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/myColors.dart';
import '../../../utils/auth_validators.dart';
import 'auth_text_field.dart';

class PasswordField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool showStrengthIndicator;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const PasswordField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.validator,
    this.onChanged,
    this.showStrengthIndicator = false,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          label: widget.label,
          hint: widget.hint,
          controller: widget.controller,
          keyboardType: TextInputType.visiblePassword,
          obscureText: !_isPasswordVisible,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          errorText: widget.errorText,
          validator: widget.validator,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
        ),
        if (widget.showStrengthIndicator && widget.controller != null) ...[
          const SizedBox(height: AuthConstants.smallPadding),
          _buildPasswordStrengthIndicator(),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = widget.controller!.text;
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = AuthValidators.getPasswordStrength(password);
    final strengthText = AuthValidators.getPasswordStrengthText(strength);
    final strengthColor = AuthValidators.getPasswordStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _getStrengthValue(strength),
                backgroundColor: dividerColor.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(Color(strengthColor)),
              ),
            ),
            const SizedBox(width: AuthConstants.smallPadding),
            Text(
              strengthText,
              style: TextStyle(
                color: Color(strengthColor),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AuthConstants.smallPadding),
        _buildPasswordRequirements(),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final password = widget.controller!.text;
    if (password.isEmpty) return const SizedBox.shrink();

    final requirements = {
      'At least 8 characters': password.length >= 8,
      'One uppercase letter': password.contains(RegExp(r'[A-Z]')),
      'One lowercase letter': password.contains(RegExp(r'[a-z]')),
      'One number': password.contains(RegExp(r'[0-9]')),
      'One special character': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirements.entries.map((entry) {
        final isMet = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Icon(
                isMet ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: isMet 
                    ? successColor
                    : textHintColor,
              ),
              const SizedBox(width: AuthConstants.smallPadding),
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 12,
                  color: isMet 
                      ? successColor
                      : textHintColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  double _getStrengthValue(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
} 