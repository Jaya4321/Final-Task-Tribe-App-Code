import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';

class SkeletonCard extends StatelessWidget {
  final double height;
  final double? width;

  const SkeletonCard({
    super.key,
    required this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      margin: const EdgeInsets.only(bottom: UIConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title skeleton
            Container(
              height: 20,
              width: double.infinity * 0.7,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
              ),
            ),
            const SizedBox(height: UIConstants.spacingS),
            
            // Description skeleton
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
              ),
            ),
            const SizedBox(height: UIConstants.spacingS),
            
            Container(
              height: 16,
              width: double.infinity * 0.8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
              ),
            ),
            const Spacer(),
            
            // Footer skeleton
            Row(
              children: [
                // Avatar skeleton
                Container(
                  height: 16,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
                  ),
                ),
                const Spacer(),
                
                // Name skeleton
                Container(
                  height: 16,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor ?? Colors.grey[300]!,
                widget.highlightColor ?? Colors.grey[100]!,
                widget.baseColor ?? Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: loadingOverlayColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitSpinningLines(
                    color: primaryColor,
                    size: 50.0,
                    lineWidth: 3.0,
                  ),
                  // if (message != null) ...[
                  //   const SizedBox(height: UIConstants.spacingM),
                  //   Text(
                  //     message!,
                  //     style: const TextStyle(
                  //       color: Colors.white,
                  //       fontSize: UIConstants.fontSizeM,
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //     textAlign: TextAlign.center,
                  //   ),
                  // ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class PullToRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const PullToRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primaryColor,
      backgroundColor: Colors.white,
      child: child,
    );
  }
}

class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: UIConstants.buttonHeightM,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style ?? WidgetStyles.primaryButtonStyle,
        child: isLoading
            ? const SpinKitSpinningLines(
                color: Colors.white,
                size: 24.0,
                lineWidth: 2.0,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    const SizedBox(width: UIConstants.spacingS),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}

class CenterLoading extends StatelessWidget {
  final String? message;
  final double size;

  const CenterLoading({
    super.key,
    this.message,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitSpinningLines(
            color: primaryColor,
            size: size,
            lineWidth: 3.0,
          ),
          if (message != null) ...[
            const SizedBox(height: UIConstants.spacingM),
            Text(
              message!,
              style: const TextStyle(
                color: textSecondaryColor,
                fontSize: UIConstants.fontSizeM,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class SmallLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const SmallLoading({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SpinKitSpinningLines(
      color: color ?? primaryColor,
      size: size,
      lineWidth: 2.0,
    );
  }
}

class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SpinKitSpinningLines(
              color: primaryColor,
              size: 40.0,
              lineWidth: 3.0,
            ),
            const SizedBox(height: UIConstants.spacingM),
            Text(
              message,
              style: const TextStyle(
                fontSize: UIConstants.fontSizeM,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showLoadingDialog({
  required BuildContext context,
  required String message,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return LoadingDialog(message: message);
    },
  );
}

void hideLoadingDialog(BuildContext context) {
  Navigator.of(context).pop();
} 