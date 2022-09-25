import 'package:flutter/material.dart';
import 'package:wgit/drawer/sign_in_widget.dart';

import '../theme.dart';
import 'households_widget.dart';

class MainPageDrawer extends StatelessWidget {
  MainPageDrawer({Key? key}) : super(key: key);

  final TextStyle itemTextStyle = TextStyle(
      color: Colors.grey[200]!, fontSize: 16, fontWeight: FontWeight.w500);
  final TextStyle headerTextStyle = TextStyle(
    color: Colors.grey[300],
    fontWeight: FontWeight.w500,
  );

  /// Builds a header widget for the drawer
  Widget _buildHeader(String title) {
    title = title.toUpperCase();
    return Container(
      margin: const EdgeInsets.only(left: 10, top: 5),
      child: Text(
        title,
        style: AppTheme.drawerText,
      ),
    );
  }

  Widget _buildItem(
      {required IconData icon, required String text, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: itemTextStyle.color,
            size: (itemTextStyle.fontSize! * 1.5),
          ),
          Container(
            margin: const EdgeInsets.only(left: 30),
            child: Text(
              text,
              style: itemTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.grey[900]),
      child: Drawer(
        child: ListView(
          primary: true,
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Colors.grey[850],
              height: 80,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 25, left: 25),
                  child: const Text(
                    "WG IT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SignInWidget(),
            const Divider(),
            HouseholdsWidget(
              header: _buildHeader("Households"),
            ),
          ],
        ),
      ),
    );
  }
}
