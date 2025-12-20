import 'package:aps/config/components/widgets/loadin_widget.dart';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AuthRoundBtn extends StatefulWidget {
  final String title;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  bool? loading = false;
  final FocusNode? focusNode;

  AuthRoundBtn({
    super.key,
    required this.title,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.loading,
    this.focusNode,
  });

  @override
  State<AuthRoundBtn> createState() => _AuthRoundBtnState();
}

class _AuthRoundBtnState extends State<AuthRoundBtn> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HoverProvider(),
      child: Consumer<HoverProvider>(
        builder: (context, hoverProvider, child) {
          return FocusableActionDetector(
            focusNode: _focusNode,
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.enter): _EnterKeyIntent(),
            },
            actions: {
              _EnterKeyIntent: CallbackAction(
                onInvoke: (_) {
                  if (widget.onTap != null && widget.loading != true) {
                    widget.onTap!();
                  }
                  return null;
                },
              ),
            },
            child: MouseRegion(
              onEnter: (_) => hoverProvider.setHovering(true),
              onExit: (_) => hoverProvider.setHovering(false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  alignment: Alignment.center,
                  height: 7.7.h,
                  width: 50.sp,
                  padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          hoverProvider.isHovering
                              ? [AppColors.blackcolor, Colors.blue]
                              : [Colors.blue, Colors.lightBlueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: widget.borderColor ?? Colors.amber,
                      width: 2.sp,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(23),
                      topLeft: Radius.circular(23),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      widget.loading == true
                          ? LoadingWidget()
                          : Text(
                            widget.title,
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 15.sp,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }
}

class HoverProvider with ChangeNotifier {
  bool _isHovering = false;

  bool get isHovering => _isHovering;

  void setHovering(bool value) {
    _isHovering = value;
    notifyListeners();
  }
}

class _EnterKeyIntent extends Intent {
  const _EnterKeyIntent();
}
