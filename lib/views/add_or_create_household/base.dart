import 'package:flutter/material.dart';

import '../../util/components.dart';

class AddOrCreateHouseholdView extends StatefulWidget {
  const AddOrCreateHouseholdView({Key? key}) : super(key: key);

  @override
  State<AddOrCreateHouseholdView> createState() =>
      _AddOrCreateHouseholdViewState();
}

class _AddOrCreateHouseholdViewState extends State<AddOrCreateHouseholdView> {
  ThemeData get theme => Theme.of(context);
  TextStyle get buttonStyle => TextStyle(
      color: theme.colorScheme.primary,
    fontSize: 18,
  );

  void _onCreateConfirm(String name){
    print("CRETING WITH $name");
  }


  void _onCreate(){
    var dialog = UserTextInputDialog(
      context: context,
      title: "Please enter a name for the household",
      placeHolder: "Household Name",
      onSubmit: _onCreateConfirm
    )..show();
  }

  void _onJoin(){
    print("Not implemented");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
        title: const Text("Join Or Create Household"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Do you want to join or add a household?", style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w500
              ),),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                MaterialButton(
                    onPressed: _onCreate,
                    child: Text("CREATE", style: buttonStyle)
                ),
                MaterialButton(
                    onPressed: _onJoin,
                    child: Text("JOIN", style: buttonStyle)
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
