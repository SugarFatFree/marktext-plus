import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/update_service.dart';

class UpdateState {
  final UpdateInfo? availableUpdate;
  final bool dismissed;
  const UpdateState({this.availableUpdate, this.dismissed = false});
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  UpdateNotifier() : super(const UpdateState());

  void setUpdate(UpdateInfo info) {
    state = UpdateState(availableUpdate: info);
  }

  void dismiss() {
    state = UpdateState(availableUpdate: state.availableUpdate, dismissed: true);
  }
}

final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>(
  (ref) => UpdateNotifier(),
);
