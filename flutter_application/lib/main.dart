import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Events
abstract class QuoteEvent {}
class FetchQuote extends QuoteEvent {}
class ResetQuote extends QuoteEvent {}

// States
abstract class QuoteState {}
class QuoteInitial extends QuoteState {}
class QuoteLoading extends QuoteState {}
class QuoteLoaded extends QuoteState {
  final String quote;
  QuoteLoaded(this.quote);
}
class QuoteError extends QuoteState {}

// Bloc
class QuoteBloc extends Bloc<QuoteEvent, QuoteState> {
  QuoteBloc() : super(QuoteInitial()) {
    on<FetchQuote>(_onFetchQuote);
    on<ResetQuote>(_onResetQuote);
  }

  Future<void> _onFetchQuote(FetchQuote event, Emitter<QuoteState> emit) async {
    emit(QuoteLoading());
    try {
      final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        emit(QuoteLoaded(data[0]['q'] + " - " + data[0]['a']));
      } else {
        emit(QuoteError());
      }
    } catch (_) {
      emit(QuoteError());
    }
  }

  void _onResetQuote(ResetQuote event, Emitter<QuoteState> emit) {
    emit(QuoteInitial());
  }
}

// UI
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bloc Quotes',
      home: BlocProvider(
        create: (context) => QuoteBloc(),
        child: QuoteScreen(),
      ),
    );
  }
}

class QuoteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Zen Quotes')),
      body: Center(
        child: BlocBuilder<QuoteBloc, QuoteState>(
          builder: (context, state) {
            if (state is QuoteInitial) {
              return Text('Obtener una nueva reseña');
            } else if (state is QuoteLoading) {
              return CircularProgressIndicator();
            } else if (state is QuoteLoaded) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(state.quote, textAlign: TextAlign.center),
              );
            } else {
              return Text('Error al obtener la reseña');
            }
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => context.read<QuoteBloc>().add(FetchQuote()),
            child: Icon(Icons.refresh),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => context.read<QuoteBloc>().add(ResetQuote()),
            child: Icon(Icons.clear),
          ),
        ],
      ),
    );
  }
}
