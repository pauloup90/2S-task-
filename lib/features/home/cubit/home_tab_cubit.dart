import 'package:flutter_bloc/flutter_bloc.dart';

class HomeTabCubit extends Cubit<int> {
  HomeTabCubit() : super(0);

  void select(int index) => emit(index);
}
