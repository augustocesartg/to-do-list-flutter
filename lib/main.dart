import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() => runApp(ListaTarefes());

class ListaTarefes extends StatefulWidget {
  ListaTarefes({Key key}) : super(key: key);

  @override
  _ListaTarefesState createState() => _ListaTarefesState();
}

class _ListaTarefesState extends State<ListaTarefes> {
  final _textToDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo['tarefa'] = _textToDoController.text;
      newToDo['status'] = false;

      _textToDoController.text = '';
      _toDoList.add(newToDo);

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lista de Tarefas',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Lista de Tarefas'),
          backgroundColor: Colors.blueAccent[400],
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(15.0, 2.0, 7.0, 2.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _textToDoController,
                      decoration: InputDecoration(
                          labelText: 'Nova tarefa',
                          labelStyle: TextStyle(color: Colors.blueAccent[400])),
                      onSubmitted: (context) {
                        this._addToDo();
                      },
                    ),
                  ),
                  RaisedButton(
                    color: Colors.blueAccent[400],
                    child: Text('adicionar'),
                    textColor: Colors.white,
                    onPressed: _addToDo,
                  )
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 24.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.endToStart,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['tarefa']),
        value: _toDoList[index]['status'],
        secondary: CircleAvatar(
          child: Icon(
            _toDoList[index]['status'] ? Icons.check : null,
            color: Colors.white,
          ),
          backgroundColor:
              _toDoList[index]['status'] ? Colors.green : Colors.black12,
        ),
        onChanged: (status) {
          setState(() {
            _toDoList[index]['status'] = status;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          if (direction == DismissDirection.endToStart) {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPosition = index;

            _toDoList.removeAt(index);
            _saveData();

            final snack = SnackBar(
              duration: Duration(seconds: 5),
              content: Text('A tarefa ${_lastRemoved['tarefa']} foi removida!'),
              action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  });
                },
              ),
            );

            Scaffold.of(context).removeCurrentSnackBar();
            Scaffold.of(context).showSnackBar(snack);
          }
        });
      },
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((x, y) {
        if (x['status'] && !y['status'])
          return 1;
        else if (!x['status'] && y['status'])
          return -1;
        else
          return 0;
      });

      _saveData();
    });
    return null;
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
