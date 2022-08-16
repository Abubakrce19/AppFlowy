import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/protobuf.dart';

import 'group_listener.dart';

abstract class GroupControllerDelegate {
  void removeRow(String groupId, String rowId);
  void insertRow(String groupId, RowPB row, int? index);
  void updateRow(String groupId, RowPB row);
}

class GroupController {
  final GroupPB group;
  final GroupListener _listener;
  final GroupControllerDelegate delegate;

  GroupController({required this.group, required this.delegate})
      : _listener = GroupListener(group);

  void startListening() {
    _listener.start(onGroupChanged: (result) {
      result.fold(
        (GroupRowsChangesetPB changeset) {
          for (final insertedRow in changeset.insertedRows) {
            final index = insertedRow.hasIndex() ? insertedRow.index : null;
            delegate.insertRow(
              group.groupId,
              insertedRow.row,
              index,
            );
          }

          for (final deletedRow in changeset.deletedRows) {
            delegate.removeRow(group.groupId, deletedRow);
          }

          for (final updatedRow in changeset.updatedRows) {
            delegate.updateRow(group.groupId, updatedRow);
          }
        },
        (err) => Log.error(err),
      );
    });
  }

  Future<void> dispose() async {
    _listener.stop();
  }
}
