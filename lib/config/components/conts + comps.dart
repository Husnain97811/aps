// // ignore_for_file: camel_case_types, must_be_immutable

// import 'package:apld_reliable_marketing/config/colors/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:sizer/sizer.dart';

// // AUTHENTICATION ROUND BUTTON

// // class authRoundBtn extends StatelessWidget {
// //   final String text;
// //   final VoidCallback onTap;
// //   TextStyle? textStyle;
// //   Color? color;
// //   bool isLoading;
// //   authRoundBtn({
// //     super.key,
// //     required this.text,
// //     this.textStyle,
// //     this.color,
// //     required this.onTap,
// //     this.isLoading = false,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         alignment: Alignment.center,
// //         height: 8.5.h,
// //         width: 50.sp,
// //         decoration: BoxDecoration(
// //           color: color,
// //           border: Border.all(color: Colors.white, style: BorderStyle.solid),
// //           borderRadius: const BorderRadius.only(
// //             bottomRight: Radius.circular(23),
// //             topLeft: Radius.circular(23),
// //           ),
// //         ),
// //         child:
// //             isLoading == true
// //                 ? const Center(
// //                   child: CircularProgressIndicator(color: Colors.white),
// //                 )
// //                 : Text(
// //                   text,
// //                   style: GoogleFonts.inter(
// //                     color: Colors.white,
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 16.sp,
// //                   ),
// //                 ),
// //       ),
// //     );
// //   }
// // }

// //  SOCAIL IMAGE BUTTONS
// class socailbutton extends StatelessWidget {
//   final Image socialimage;
//   const socailbutton({super.key, required this.socialimage});
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.basecolor,
//         borderRadius: BorderRadius.circular(23.sp),
//       ),
//       width: 45 * 2.sp,
//       height: 5.h,
//       child: Padding(
//         padding: EdgeInsets.only(top: 0.8.h, bottom: 0.8.h),
//         child: Image(height: 7.h, width: 7.w, image: socialimage.image),
//       ),
//     );
//   }
// }

// // TEXTFORMFIELD FOR AUTHENTICATION SCREENS
// class textForm extends StatelessWidget {
//   final TextEditingController textformcontroller;
//   final String labeltext;
//   final TextInputType keyboardType;

//   const textForm({
//     super.key,
//     required this.textformcontroller,
//     required this.labeltext,
//     required this.keyboardType,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: textformcontroller,
//       cursorColor: Colors.black,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         filled: true,
//         labelStyle: TextStyle(color: AppColors.textcolor),
//         fillColor: Colors.white,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         labelText: labeltext,
//       ),
//     );
//   }
// }

// //  DROP DOWN MENU

// class SelectedOptionNotifier extends ChangeNotifier {
//   String _selectedOption = 'Video';

//   String get selectedOption => _selectedOption;

//   void updateSelectedOption(String newOption) {
//     _selectedOption = newOption;
//     notifyListeners();
//   }
// }

