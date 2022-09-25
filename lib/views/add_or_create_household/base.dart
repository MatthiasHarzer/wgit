import 'package:flutter/material.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/services/types.dart';

import '../../util/components.dart';


class JoinOrCreateHouseholdView extends StatefulWidget {
  final Function(HouseHold) onFinished;

  const JoinOrCreateHouseholdView({required this.onFinished, Key? key}) : super(key: key);

  @override
  State<JoinOrCreateHouseholdView> createState() =>
      _JoinOrCreateHouseholdViewState();
}

class _JoinOrCreateHouseholdViewState extends State<JoinOrCreateHouseholdView> {
  ThemeData get theme => Theme.of(context);
  TextStyle get buttonStyle => TextStyle(
      color: theme.colorScheme.primary,
    fontSize: 18,
  );

  void _onCreateConfirm(String name)async{
    if(name.isEmpty) return;
    HouseHold? household = await FirebaseService.createHousehold(name);
    if(household != null){
      if(mounted){
        Navigator.pop(context);
      }
      widget.onFinished(household);
    }else{
      print("An error occurred creating household $name");
    }
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
