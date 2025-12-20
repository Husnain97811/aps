import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

Widget textMembershipFormField({
  required String label,
  required TextEditingController controller,
  int maxLines = 1,
  String initialvalue = '',
  bool enabled = true,
  double? width,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
  TextInputType? keyboardType,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
      ),
      SizedBox(width: 2.w),
      Expanded(
        child: TextFormField(
          enabled: enabled,
          textAlign: TextAlign.center,
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.4),
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: 1.h,
              horizontal: 2.w,
            ),
          ),
          onChanged: onChanged,
          validator:
              validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              },
        ),
      ),
    ],
  );
}

Widget textRemarksMembershipFormField({
  required String label,
  required TextEditingController controller,
  int maxLines = 1,
  String initialvalue = '',
  bool enabled = true,
  double? width,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
      ),
      SizedBox(width: 2.w),
      Expanded(
        child: TextFormField(
          enabled: enabled,
          textAlign: TextAlign.center,
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.4),
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: 1.h,
              horizontal: 2.w,
            ),
          ),
          // validator: (value) {
          //   // if (value == null || value.isEmpty) {
          //   //   return 'Please enter $label';
          //   // }
          //   return null;
          // },
        ),
      ),
    ],
  );
}

Widget cnicMembershipFormField({
  required String label,
  required List<TextEditingController> controllers, // Must match the type
  required List<FocusNode> focusNodes,
  required BuildContext context,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
      ),
      SizedBox(width: 2.w),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(13, (index) {
          return SizedBox(
            // height: 13,
            width: 2.5.w,
            child: Focus(
              onKey: (node, event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.backspace &&
                      controllers[index].text.isEmpty &&
                      index > 0) {
                    FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.enter &&
                      index < 14) {
                    FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextFormField(
                textAlignVertical: TextAlignVertical.center,
                controller: controllers[index],
                focusNode: focusNodes[index],
                maxLength: 1,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 2,
                  ),
                ),
                keyboardType: TextInputType.text,
                textInputAction:
                    index < 14 ? TextInputAction.next : TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                onChanged: (value) {
                  if (value.isNotEmpty && index < 14) {
                    FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                  }
                },

                onEditingComplete: () {
                  if (index < 14) {
                    FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                  }
                },
              ),
            ),
          );
        }),
      ),
    ],
  );
}
