import 'package:aps/config/view.dart';
import 'package:aps/investors/investors_screen.dart';
import 'package:aps/views/allotment/allotment_letter.dart';
import 'package:aps/views/cashflow/cashflow_screen.dart';
import 'package:aps/views/clients/clients_refund.dart';
import 'package:aps/views/installment_data.dart';
import 'package:aps/views/land_payments/land_payments.dart';
import 'package:aps/views/setting.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:sizer/sizer.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<SideBar> {
  final _sidebarKey = GlobalKey<_MyHomePageState>();

  int _selectedIndex = 0;

  void _onIndexChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SidebarX(
            showToggleButton: false,
            key: _sidebarKey,
            controller: SidebarXController(selectedIndex: _selectedIndex),
            theme: SidebarXTheme(
              itemMargin: EdgeInsets.all(6.sp),
              itemPadding: EdgeInsets.all(0),
              selectedItemMargin: EdgeInsets.all(0),
              selectedItemPadding: EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              textStyle: TextStyle(color: Colors.black),
              selectedTextStyle: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
              selectedIconTheme: IconThemeData(color: AppColors.lightgolden),
            ),
            items: [
              SidebarXItem(
                icon: Icons.dashboard_customize,
                label: 'Dashboard',
                onTap: () => _onIndexChanged(0),
              ),
              SidebarXItem(
                icon: Icons.person,
                label: 'Clients',
                onTap: () => _onIndexChanged(1),
              ),
              SidebarXItem(
                icon: FontAwesome.person_walking_arrow_loop_left_solid,
                label: 'Refund',
                onTap: () => _onIndexChanged(2),
              ),

              SidebarXItem(
                icon: Icons.receipt_long_outlined,
                label: 'Slips',
                onTap: () => _onIndexChanged(3),
              ),
              SidebarXItem(
                icon: FontAwesomeIcons.crown,
                label: 'Allotment',
                onTap: () => _onIndexChanged(4),
              ),
              SidebarXItem(
                icon: FontAwesomeIcons.peopleRobbery,
                label: 'Investors',
                onTap: () => _onIndexChanged(5),
              ),
              SidebarXItem(
                icon:
                    Icons
                        .landscape_outlined, // Use a built-in IconData as a placeholder
                label: 'Land Payments',
                onTap: () => _onIndexChanged(6),
              ),
              SidebarXItem(
                icon: BoxIcons.bx_money_withdraw,
                label: 'Cashflows',
                onTap: () => _onIndexChanged(7),
              ),
              SidebarXItem(
                icon: FontAwesomeIcons.peopleArrows,
                label: 'Dealers',
                onTap: () => _onIndexChanged(8),
              ),
            ],
            footerItems: [
              SidebarXItem(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () {
                  _onIndexChanged(9);
                },
              ),
            ],
          ),
          // Main Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeScreen(),
                Clients(),
                ClientsRefund(),
                InstallmentData(),
                AllotmentLetter(),
                CustomersScreen(),
                LandPaymentRecordScreen(),
                CashflowScreen(),
                DealerScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
