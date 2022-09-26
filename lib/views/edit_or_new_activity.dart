import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wgit/services/firebase/firebase_service.dart';

import '../services/firebase/firebase_ref_service.dart';
import '../services/types.dart';
import '../util/components.dart';
import '../util/util.dart';

class EditOrNewActivity extends StatefulWidget {
  final HouseHold houseHold;
  final Activity? existingActivity;

  const EditOrNewActivity({required this.houseHold, this.existingActivity, Key? key}) : super(key: key);

  @override
  State<EditOrNewActivity> createState() => _EditOrNewActivityState();
}

class _EditOrNewActivityState extends State<EditOrNewActivity> {
  HouseHold get houseHold => widget.houseHold;
  List<AppUser> get availableUsers => widget.houseHold.members;

  double get total => _contributions.values.fold(0, (p, c) => p + c);

  late Activity tempActivity = Activity.empty();
  bool isEditMode = false;

  bool working = false;

  Map<AppUser, double> get _contributions => tempActivity.contributions;

  @override
  void initState(){
    super.initState();

    if(widget.existingActivity != null){
      isEditMode = true;
      tempActivity = widget.existingActivity!.copy();
    }else{
      tempActivity.contributions = {for(var user in availableUsers) user: 0};
    }
  }



  void _close(){
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
  }

  void _submit()async{
    if(working) return;
    tempActivity.label = tempActivity.label.isEmpty ? "(Unnamed)" : tempActivity.label;
    setState(() {
      working = true;
    });

    await FirebaseService.submitActivity(houseHold: houseHold, activity: tempActivity);

    if(mounted){
      setState(() {
        working = false;
      });

      _close();
    }

  }

  void _setUserContribution(AppUser user, double contribution) {
    setState(() {
      _contributions[user] = contribution;
    });
  }

  double _getUserContribution(AppUser user) {
    if (_contributions.containsKey(user)) return _contributions[user]!;
    return 0;
  }

  /// Builds formfield to enter the users contributoins
  Widget _buildUsersContributionInputFields() {
    Widget buildField(AppUser user) {
      double contribution = _getUserContribution(user);
      double perc = contribution * 100 / total;
      String percent;
      if(total == 0){
        percent = "";
      }else{
        percent = "${perc.round()}%";
      }

      return ListTile(
        leading: buildCircularAvatar(url: user.photoURL, dimension: 40),
        trailing: Text(
          percent,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        title: SizedBox(
          height: 60,
          child: Focus(
            onFocusChange: (focus) {
              // print(
              //     "FOCUS to $focus on ${user.displayName} with $contribution");
              _setUserContribution(user, contribution);
            },
            child: TextFormField(
              initialValue: contribution == 0 ? null : contribution.toString(),
              onChanged: (c){
                contribution = double.tryParse(c) ?? 0;
                _setUserContribution(user, contribution);
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                labelText: "${user.displayName}'s contribution",
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var user in availableUsers) buildField(user),
      ],
    );
  }

  /// Builds the total display widget
  Widget _buildTotal() {
    TextStyle style = TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey[400]);
    String text = "Total: €${Util.formatAmount(total)}";
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: style),
      ],
    );
  }

  /// Builds submit / cancel actions
  Widget _buildActions(){
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
            onPressed: _close,
            child: const Text("DISCARD"),
        ),
        ElevatedButton(
            onPressed: _submit,
            child: Row(
              children: [
                Visibility(
                  visible: working,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(
                        color: Colors.grey[200],
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
                const Text("SUBMIT")
              ],
            ),

        ),

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Add Activity"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SingleChildScrollView(

          child: Column(
            children: [
              TextFormField(
                initialValue: tempActivity.label,
                autofocus: !isEditMode,
                onChanged: (text) => tempActivity.label = text,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "Label or reason",
                ),
              ),
              _buildUsersContributionInputFields(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: Divider(
                  color: Colors.grey[600],
                ),
              ),
              _buildTotal(),
              Padding(
                padding: const EdgeInsets.only(top: 70),
                child: _buildActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
