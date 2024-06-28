import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'моё приложение',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
      ],
      home: const UserPanel(),
    );
  }
}

class UserPanel extends StatefulWidget {
  const UserPanel({super.key});

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  String backgroundImageUrl = 'https://cdn.pixabay.com/photo/2022/04/18/17/26/artwork-7141109_1280.png'; // дефолтнная картинка

  void setBackground(String imageUrl) {
    setState(() {
      backgroundImageUrl = imageUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Итоговая практическая работа"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade200,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(backgroundImageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                ElevatedButton(
                  child: const Text("Список дел"),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const Home()));
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: const Text("Заметки"),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesPage()));
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: const Text("Мой профиль"),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const Account()));
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: const Text("Настройки фона"),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(onBackgroundChanged: setBackground)));
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: const Text("Должности"),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Employees()));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late String vVod;
  List<Task> myList = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Метод для загрузки задач из shared_preferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      final List<dynamic> tasksJson = json.decode(tasksString);
      setState(() {
        myList = tasksJson.map((json) => Task.fromJson(json)).toList();
      });
    } else {
      setState(() {
        myList.addAll([
          Task(name: 'почитать'),
          Task(name: 'помыть посуду'),
          Task(name: 'спорт')
        ]);
      });
    }
  }

  // Метод для сохранения задач в shared_preferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksString = json.encode(myList.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', tasksString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список дел'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade200,
      ),
      body: ListView.builder(
          itemCount: myList.length,
          itemBuilder: (BuildContext context, int index) {
            return Dismissible(
              key: Key(myList[index].name),
              child: Card(
                child: ListTile(
                  title: Text(
                    myList[index].name,
                    style: TextStyle(
                      decoration: myList[index].isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  trailing: Checkbox(
                    value: myList[index].isDone,
                    onChanged: (bool? value) {
                      setState(() {
                        myList[index].isDone = value!;
                        _saveTasks();  // Сохраняем задачи при изменении
                      });
                    },
                  ),
                ),
              ),
              onDismissed: (direction) {
                setState(() {
                  myList.removeAt(index);
                  _saveTasks();  // Сохраняем задачи при удалении
                });
              },
            );
          }
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple.shade200,
          onPressed: () {
            showDialog(context: context, builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Добавить задачу'),
                content: TextField(
                  onChanged: (String value) {
                    vVod = value;
                  },
                ),
                actions: [
                  ElevatedButton(onPressed: () {
                    setState(() {
                      myList.add(Task(name: vVod));
                      _saveTasks();  // Сохраняем задачи при добавлении
                    });
                    Navigator.of(context).pop();
                  }, child: Text('Добавить'))
                ],
              );
            });
          },
          child: Icon(
              Icons.add_box,
              color: Colors.white
          )
      ),
    );
  }
}

class Task {
  String name;
  bool isDone;

  Task({required this.name, this.isDone = false});

  // Метод для преобразования Task в JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'isDone': isDone,
  };

  // Метод для создания Task из JSON
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    name: json['name'],
    isDone: json['isDone'],
  );
}

class Note {
  String title;
  String text;
  DateTime date;

  Note({
    required this.title,
    required this.text,
    required this.date,
  });

  String getFormattedDate() {
    final russianDateFormat = DateFormat.yMMMEd('ru');
    return russianDateFormat.format(date);
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'text': text,
    'date': date.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    title: json['title'],
    text: json['text'],
    date: DateTime.parse(json['date']),
  );
}

class AddNotePage extends StatefulWidget {
  final Function(String, String) onSave;

  AddNotePage({required this.onSave});

  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  String noteTitle = '';
  String noteText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить заметку'),
        backgroundColor: Colors.deepPurple.shade200,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(hintText: 'Заголовок'),
              onChanged: (value) {
                setState(() {
                  noteTitle = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(hintText: 'Текст'),
              onChanged: (value) {
                setState(() {
                  noteText = value;
                });
              },
              maxLines: null, // Автоматически расширяться по вертикали
              keyboardType: TextInputType.multiline, // Установка типа клавиатуры
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.onSave(noteTitle, noteText);
                Navigator.pop(context);
              },
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesString = prefs.getString('notes');
    if (notesString != null) {
      final List<dynamic> notesJson = json.decode(notesString);
      setState(() {
        notes = notesJson.map((json) => Note.fromJson(json)).toList();
      });
    }
  }

  void _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes.map((note) => note.toJson()).toList();
    await prefs.setString('notes', json.encode(notesJson));
  }

  void _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNotePage(
          onSave: (title, text) {
            setState(() {
              notes.add(Note(
                title: title,
                text: text,
                date: DateTime.now(),
              ));
              _saveNotes();
            });
          },
        ),
      ),
    );
    if (result != null) {
      setState(() {
        notes.add(result);
        _saveNotes();
      });
    }
  }

  void _editNote(Note note) {
    TextEditingController titleController =
    TextEditingController(text: note.title);
    TextEditingController textController =
    TextEditingController(text: note.text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Редактировать заметку'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(hintText: 'Заголовок'),
                onChanged: (value) {
                  note.title = value;
                },
              ),
              TextField(
                controller: textController,
                decoration: InputDecoration(hintText: 'Текст'),
                onChanged: (value) {
                  note.text = value;
                },
                maxLines: null, // Автоматически расширяться по вертикали
                keyboardType: TextInputType.multiline, // Установка типа клавиатуры
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  note.title = titleController.text;
                  note.text = textController.text;
                  _saveNotes();
                });
                Navigator.of(context).pop();
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _deleteNote(Note note) {
    setState(() {
      notes.remove(note);
      _saveNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заметки'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade200,
      ),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Dismissible(
            key: Key(note.date.toString()),
            onDismissed: (direction) {
              _deleteNote(note);
            },
            child: Card(
              child: ListTile(
                title: Text(
                  note.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.text,
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Дата создания: ${note.getFormattedDate()}',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () => _editNote(note),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple.shade200,
        onPressed: _addNote,
        child: Icon(
          Icons.add_box,
          color: Colors.white,
        ),
      ),
    );
  }
}


class Account extends StatefulWidget {
  const Account({Key? key}) : super(key: key);

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String? _selectedImagePath;
  String _name = 'София';
  String _email = 'lublupoest@mail.ru';

  final List<String> predefinedImages = [
    'assets/kot.jpg',
    'assets/котик 2.jpg',
    'assets/кот3.jpg',
    'assets/кот 4.jpg',
    'assets/кот 5.jpg',
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedImagePath = prefs.getString('selected_image');
      _name = prefs.getString('name') ?? 'София';
      _email = prefs.getString('email') ?? 'lublupoest@mail.ru';
      _nameController.text = _name;
      _emailController.text = _email;
    });
  }

  void _saveImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_image', path);
  }

  void _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
  }

  void _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Мой профиль"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade200,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _selectedImagePath != null
                        ? AssetImage(_selectedImagePath!)
                        : null,
                    child: _selectedImagePath == null
                        ? Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.grey[800],
                    )
                        : null,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _selectImage(context);
                  },
                  child: Text('Редактировать аватар'),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    width: 300, // Задаем ширину для поля ввода
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Имя'),
                      onChanged: (value) {
                        setState(() {
                          _name = value;
                        });
                        _saveName(value);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Container(
                    width: 300, // Задаем ширину для поля ввода
                    child: TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Почта'),
                      onChanged: (value) {
                        setState(() {
                          _email = value;
                        });
                        _saveEmail(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200.0,
          child: ListView.builder(
            itemCount: predefinedImages.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                leading: Icon(Icons.photo),
                title: Text('Изображение ${index + 1}'),
                onTap: () {
                  setState(() {
                    _selectedImagePath = predefinedImages[index];
                    _saveImage(_selectedImagePath!);
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  final List<String> backgroundImages = [
    'https://cdn.pixabay.com/photo/2022/04/18/17/27/artwork-7141133_1280.png',
    'https://cdn.pixabay.com/photo/2022/04/18/17/27/artwork-7141134_1280.png',
    'https://cdn.pixabay.com/photo/2022/04/18/17/27/artwork-7141136_1280.png',
    'https://cdn.pixabay.com/photo/2015/05/04/20/03/purple-wallpaper-752886_1280.jpg'
  ];

  final Function(String) onBackgroundChanged;

  SettingsPage({required this.onBackgroundChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки фона'),
        backgroundColor: Colors.deepPurple.shade200,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: backgroundImages.map((imageUrl) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: GestureDetector(
                  onTap: () {
                    onBackgroundChanged(imageUrl);
                    Navigator.pop(context); // Возвращаемся на предыдущий экран после выбора фона
                  },
                  child: Container(
                    width: 300,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}


class Employees extends StatefulWidget {
  const Employees({super.key});

  @override
  State<Employees> createState() => _EmployeesState();
}

class _EmployeesState extends State<Employees> {
  List<dynamic>? jsonUsers;

  Future<void> getUsers() async {
    final response = await http.get(Uri.parse(
        'https://gist.githubusercontent.com/rominirani/8235702/raw/a50f7c449c41b6dc8eb87d8d393eeff62121b392/employees.json'));
    setState(() {
      var jsonBody = json.decode(response.body);
      jsonUsers = jsonBody["Employees"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Должности'),
        backgroundColor: Colors.deepPurple.shade200,
        actions: [
          ElevatedButton(
            onPressed: getUsers,
            child: const Text('Выгрузить данные'),
          ),
        ],
      ),
      body: jsonUsers == null
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return Card(
            child: ListTile(
              title: Text(
                  '${jsonUsers![index]["firstName"]} ${jsonUsers![index]["lastName"]}'),
              subtitle: Text(
                  'Должность: ${jsonUsers![index]["jobTitleName"]} \nEmail: ${jsonUsers![index]["emailAddress"]}'),
            ),
          );
        },
        itemCount: jsonUsers == null ? 0 : jsonUsers!.length,
      ),
    );
  }
}
