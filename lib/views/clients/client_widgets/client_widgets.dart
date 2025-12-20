// common_widgets.dart

import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

Widget buildDetailRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 0.5.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30.w,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
              color: AppColors.textcolor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12.sp, color: AppColors.blackcolor),
          ),
        ),
      ],
    ),
  );
}


//   clients details dialog

void showCustomClientDetailsDialog(BuildContext context, Map<String, dynamic> client, String title) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textcolor,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDetailRow('Name', client['name']?.toString() ?? 'null'),
             buildDetailRow('CNIC/Passport', client['cnic_passport_no']?.toString() ?? 'null'),
            buildDetailRow('Mobile', client['mobile_no']?.toString() ?? 'null'),
             buildDetailRow('Address', client['address']?.toString() ?? 'null'),
            buildDetailRow('Membership No', client['membership_no']?.toString() ?? 'null'),
            buildDetailRow('Date', client['date']?.toString() ?? 'null'),
            SizedBox(height: 2.h),
            Text(
              'Next of Kin Info:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: AppColors.textcolor,
              ),
            ),
              buildDetailRow('Name', client['nok_name']?.toString() ?? 'null'),
            buildDetailRow('Relation', client['relation']?.toString() ?? 'null'),
            buildDetailRow('Mobile', client['nok_mobile_no']?.toString() ?? 'null'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: TextStyle(color: AppColors.buttoncolor),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      backgroundColor: AppColors.whitecolor,
    ),
  );
}




//  search text field 


class CustomSearchTextField extends StatelessWidget {
 final TextEditingController controller;
 final Function(String) onChanged;
 const CustomSearchTextField({super.key, required this.controller, required this.onChanged});

 @override
 Widget build(BuildContext context) {
   return Padding(
     padding: EdgeInsets.all(2.h),
     child: TextField(
       controller: controller,
       decoration: InputDecoration(
         hintText: 'Search by Form No...',
         hintStyle: const TextStyle(color: Colors.grey),
         prefixIcon: const Icon(
           Icons.search,
           color: AppColors.blackcolor,
         ),
         border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(8.0),
         ),
         filled: true,
         fillColor: AppColors.whitecolor,
       ),
       onChanged: onChanged,
     ),
   );
 }
}



// reuseable appbar for clients screns

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onRefresh;
 const CustomAppBar({super.key, required this.title, required this.onRefresh});

 @override
 Widget build(BuildContext context) {
   return AppBar(
     title: Text(title, style: GoogleFonts.aBeeZee(fontSize: 18.sp)),
     backgroundColor: AppColors.darkbrown,
     actions: [
       IconButton(
         icon: const Icon(Icons.refresh, color: AppColors.whitecolor),
         onPressed: onRefresh,
       ),
     ],
   );
 }
 
   @override
 Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}





// reuseable listview for clients screens

class CustomClientListView extends StatelessWidget {
  final List<Map<String, dynamic>> clients;
  final Function(Map<String, dynamic>) showClientDetails;
  final bool isSuspended;
  final bool isWinned;


  const CustomClientListView({
    super.key,
    required this.clients,
    required this.showClientDetails,
    this.isSuspended = false,
    this.isWinned = false
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];

        return Card(
          elevation: 3,
          color: AppColors.whitecolor,
          margin: EdgeInsets.only(bottom: 1.5.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if(isWinned)
                Icon(Icons.emoji_events,
                  color: Colors.amber,
                  size: 20.sp,
                ),
                if (isSuspended)
                  Icon(Icons.dangerous,
                    color: Colors.red,
                    size: 20.sp,
                  ),
                  SizedBox(width: 1.w),
              ],
            ),
            title: Text(
              client['name'] ?? 'null',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textcolor,
              ),
            ),
            subtitle: Text(
              'Form No: ${client['form_no'] ?? 'null'}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.blackcolor,
              ),
            ),
               trailing: Text(
              client['mobile_no'] ?? 'null',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.blackcolor,
              ),
            ),
            onTap: () => showClientDetails(client),
          ),
        );
      },
    );
  }
}
