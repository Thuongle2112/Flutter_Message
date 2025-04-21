// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../domain/usecases/auth/register_usecase.dart';
// import 'register_event.dart';
// import 'register_state.dart';
//
// class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
//   final RegisterUseCase registerUseCase;
//
//   RegisterBloc(this.registerUseCase) : super(RegisterInitial()) {
//     on<RegisterSubmitted>(_onSubmitted);
//   }
//
//   void _onSubmitted(
//       RegisterSubmitted event, Emitter<RegisterState> emit) async {
//     emit(RegisterLoading());
//     try {
//       await registerUseCase(event.email, event.password);
//       emit(RegisterSuccess());
//     } catch (e) {
//       emit(RegisterFailure(e.toString()));
//     }
//   }
// }
