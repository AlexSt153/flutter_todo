import 'package:flutter/material.dart';
import 'package:flutter_todo/components/auth_required_state.dart';
import 'package:flutter_todo/utils/constants.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({Key? key}) : super(key: key);

  @override
  _TodosPageState createState() => _TodosPageState();
}

class _TodosPageState extends AuthRequiredState<TodosPage> {
  bool _isLoading = false;
  List<dynamic> _todos = [];

  Future<void> _getTodos() async {
    setState(() {
      _isLoading = true;
    });

    final res = await supabase
        .from('todos')
        .select()
        // .order('is_complete', ascending: true)
        .order('id', ascending: true)
        .execute();

    final data = res.data;
    final error = res.error;

    if (error != null) {
      context.showErrorSnackBar(message: error.message);
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _todos = data;
        _isLoading = false;
      });
    }
  }

  _addTodo(value) async {
    final user = supabase.auth.user();

    final res = await supabase.from('todos').insert({
      'user_id': user?.id,
      'task': value,
    }).execute();

    final data = res.data;
    final error = res.error;

    if (error != null) {
      context.showErrorSnackBar(message: error.message);
    } else {
      _getTodos();
    }
  }

  _completeTodo(index, value) async {
    final res = await supabase.from('todos').update(
        {'is_complete': value}).match({'id': _todos[index]['id']}).execute();

    final data = res.data;
    final error = res.error;

    if (error != null) {
      context.showErrorSnackBar(message: error.message);
    } else {
      _getTodos();
    }
  }

  _deleteTodo(index) async {
    final res = await supabase
        .from('todos')
        .delete()
        .match({'id': _todos[index]['id']}).execute();

    final data = res.data;
    final error = res.error;

    if (error != null) {
      context.showErrorSnackBar(message: error.message);
    } else {
      context.showSnackBar(message: 'Todo deleted');
      _getTodos();
    }
  }

  @override
  void initState() {
    super.initState();
    _getTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: RefreshIndicator(
          child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];

                return Dismissible(
                  key: Key(todo['id'].toString()),
                  onDismissed: (direction) {
                    _deleteTodo(index);
                  },
                  direction: DismissDirection.endToStart,
                  background: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.red,
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(8),
                      child: const Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.delete, color: Colors.white))),
                  child: Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: Container(
                          margin: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            Checkbox(
                                value: todo['is_complete'],
                                onChanged: (value) =>
                                    _completeTodo(index, value)),
                            const SizedBox(width: 8),
                            Text('${todo['task']}',
                                style: todo['is_complete']
                                    ? const TextStyle(
                                        decoration: TextDecoration.lineThrough)
                                    : null),
                          ]))),
                );
              }),
          onRefresh: _getTodos),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return Container(
                padding: EdgeInsets.fromLTRB(
                    18, 5, 18, MediaQuery.of(context).viewInsets.bottom + 30),
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'New todo',
                  ),
                  onSubmitted: (value) {
                    Navigator.pop(context);
                    _addTodo(value);
                  },
                ),
              );
            }),
        tooltip: 'Increment Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
