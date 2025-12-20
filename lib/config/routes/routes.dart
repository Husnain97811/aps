import 'package:aps/config/view.dart';
import 'package:aps/views/allotment/allotment_letter.dart';
import 'package:aps/views/auth_Screens/reset_pass_screen.dart';
import 'package:aps/views/auth_Screens/login_screen.dart';
import 'package:aps/views/auth_Screens/signUp_Screen.dart';
import 'package:aps/views/cashflow/cashflow_screen.dart';
import 'package:aps/views/cashflow/expense/edit_expense.dart';
import 'package:aps/views/clients/clients_refund.dart';
import 'package:aps/views/clients/refund_receipts.dart';
import 'package:aps/views/forms/installment_receipt.dart';
import 'package:aps/views/forms/membership_form.dart';
import 'package:aps/views/installment_data.dart';
import 'package:aps/views/setting.dart';
import 'package:aps/views/side_bar/side_bar.dart';
import 'package:flutter/material.dart';
import '../../views/splash_screen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splashscreen:
        return MaterialPageRoute(builder: (context) => SplashScreen());

      case RouteNames.sidebar:
        return MaterialPageRoute(builder: (context) => SideBar());
      case RouteNames.dashboard:
        return MaterialPageRoute(builder: (context) => HomeScreen());
      case RouteNames.signupscreen:
        return MaterialPageRoute(builder: (context) => SignUpScreen());
      case RouteNames.loginscreen:
        return MaterialPageRoute(builder: (context) => LoginScreen());
      case RouteNames.resetpassflowScreen:
        return MaterialPageRoute(
          builder: (context) => PasswordResetFlowScreen(),
        );
      case RouteNames.forgotpass:
        return MaterialPageRoute(builder: (context) => ResetPasswordScreen());
      case RouteNames.settingscreen:
        return MaterialPageRoute(builder: (context) => SettingsScreen());
      case RouteNames.homescreen:
        return MaterialPageRoute(builder: (context) => HomeScreen());
      case RouteNames.clients:
        return MaterialPageRoute(builder: (context) => Clients());
      case RouteNames.clientsrefund:
        return MaterialPageRoute(builder: (context) => ClientsRefund());
      case RouteNames.refundreceipts:
        return MaterialPageRoute(builder: (context) => RefundReceiptsScreen());
      case RouteNames.installmentdata:
        return MaterialPageRoute(builder: (context) => InstallmentData());
      case RouteNames.allotmentletter:
        return MaterialPageRoute(builder: (context) => AllotmentLetter());
      case RouteNames.installmentreceipts:
        return MaterialPageRoute(
          builder: (context) => InstallmentReceiptScreen(),
        );
      case RouteNames.membershipform:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder:
              (context) => MembershipFormScreen(
                editMode: args?['editMode'] ?? false,
                membershipNo: args?['membershipNo'],
              ),
        );

      // case RouteNames.membershipform:
      //   return MaterialPageRoute(builder: (context) => MembershipFormScreen());
      case RouteNames.cashflowscreen:
        return MaterialPageRoute(builder: (context) => CashflowScreen());
      case RouteNames.addExpense:
        return MaterialPageRoute(builder: (context) => AddExpenseScreen());
      case RouteNames.cashIn:
        return MaterialPageRoute(builder: (context) => AddCashInScreen());
      case RouteNames.expenseEntries:
        return MaterialPageRoute(builder: (context) => ExpenseEntriesScreen());
      case RouteNames.editExpense:
        return MaterialPageRoute(builder: (context) => EditExpenseScreen());

      default:
        return MaterialPageRoute(
          builder: (context) {
            return Scaffold(body: Center(child: Text('No route generated ')));
          },
        );
    }
  }
}
