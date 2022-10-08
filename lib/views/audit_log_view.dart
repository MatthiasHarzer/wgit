import 'package:flutter/material.dart';
import 'package:wgit/types/audit_log_item.dart';
import 'package:wgit/util/components.dart';
import 'package:wgit/util/extensions.dart';

import '../types/household.dart';

class _AuditLogViewItem extends StatefulWidget {
  final AuditLogItem log;

  const _AuditLogViewItem({Key? key, required this.log}) : super(key: key);

  @override
  State<_AuditLogViewItem> createState() => _AuditLogViewItemState();
}

class _AuditLogViewItemState extends State<_AuditLogViewItem> {
  AuditLogItem get log => widget.log;
  List<String> text = [];

  @override
  void initState() {
    super.initState();
    loadAsync();
  }

  void loadAsync() async {
    text = await log.getText();

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ListTile(
        leading: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: double.infinity, maxWidth: 40),
          child: Align(
              alignment: Alignment.center,
              child: Icon(log.icon),
          ),
        ),
        title: buildTextWithHighlights(
            text,
            startOdd: true,
            defaultTextStle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Colors.grey[400],
            ),
        ),
        subtitle: Text(log.date.formatted),
      ),
    );
  }
}

class AuditLogView extends StatefulWidget {
  final HouseHold houseHold;

  const AuditLogView({Key? key, required this.houseHold}) : super(key: key);

  @override
  State<AuditLogView> createState() => _AuditLogViewState();
}

class _AuditLogViewState extends State<AuditLogView> {
  HouseHold get houseHold => widget.houseHold;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audit Log of \"${houseHold.name}\""),
      ),
      body: StreamBuilder(
        stream: houseHold.auditLogStream,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];

          return ListView(
            children: [for (var item in items) _AuditLogViewItem(log: item)],
          );
        },
      ),
    );
  }
}
