import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: TaskHomePage(),
    );
  }
}

class TaskHomePage extends StatelessWidget {
  // Muestra un diálogo para agregar una nueva tarea.
  void _showAddTaskDialog(BuildContext context) {
    final _taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Agregar Tarea'),
        content: TextField(
          controller: _taskController,
          decoration: InputDecoration(hintText: 'Nombre de la tarea'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_taskController.text.trim().isNotEmpty) {
                Provider.of<TaskProvider>(context, listen: false)
                    .addTask(_taskController.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            child: Text('Agregar'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tareas'),
        centerTitle: true,
      ),
      body: Container(
        // Fondo degradado espectacular.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade200, Colors.deepPurple.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Estadísticas en tiempo real.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Estadísticas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total: ${taskProvider.totalTasks}'),
                          Text('Completadas: ${taskProvider.completedTasks}'),
                        ],
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: taskProvider.progress,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                      SizedBox(height: 5),
                      Text(
                          '${(taskProvider.progress * 100).toStringAsFixed(1)}% completado'),
                    ],
                  ),
                ),
              ),
            ),
            // Lista de tareas.
            Expanded(
              child: taskProvider.totalTasks == 0
                  ? Center(child: Text('No hay tareas. Agrega una nueva.'))
                  : ListView.builder(
                      itemCount: taskProvider.totalTasks,
                      itemBuilder: (context, index) {
                        final task = taskProvider.tasks[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: ListTile(
                              leading: Checkbox(
                                value: task.isCompleted,
                                onChanged: (_) {
                                  taskProvider.toggleTask(task.id);
                                },
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.isCompleted
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  taskProvider.removeTask(task.id);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add),
      ),
    );
  }
}

// Modelo de Tarea.
class Task {
  final String id;
  final String title;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        isCompleted: json['isCompleted'],
      );
}

// Provider para gestionar el estado de las tareas y la persistencia.
class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  static const String tasksKey = 'tasks';

  TaskProvider() {
    _loadTasks();
  }

  List<Task> get tasks => _tasks;

  // Carga las tareas almacenadas en SharedPreferences.
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString(tasksKey);
    if (tasksString != null) {
      final List<dynamic> tasksJson = jsonDecode(tasksString);
      _tasks.clear();
      _tasks.addAll(tasksJson.map((json) => Task.fromJson(json)).toList());
      notifyListeners();
    }
  }

  // Guarda las tareas en SharedPreferences.
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksString =
        jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString(tasksKey, tasksString);
  }

  void addTask(String title) {
    _tasks.add(Task(id: DateTime.now().toString(), title: title));
    notifyListeners();
    _saveTasks();
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      notifyListeners();
      _saveTasks();
    }
  }

  void removeTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
    _saveTasks();
  }

  int get totalTasks => _tasks.length;
  int get completedTasks =>
      _tasks.where((task) => task.isCompleted).length;
  double get progress => totalTasks == 0 ? 0 : completedTasks / totalTasks;
}
