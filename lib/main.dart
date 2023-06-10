import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sql;

void main(){

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const MyApp(),
  ));
}

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute(
        """CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
     name TEXT,
     lastName TEXT,
     createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""");
  }
  static Future<sql.Database> db() async {
    return sql.openDatabase('dbtech.db', version: 1,
        onCreate: (sql.Database database, int version) async {
          await createTables(database);
        });
  }

  static Future<int> createItem(String name, String? lastName) async {
    final db = await SQLHelper.db();

    final data = {'name': name, 'lastName': lastName};
    final id = await db.insert('items', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await SQLHelper.db();
    return db.query('items', orderBy: "id");
  }

  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await SQLHelper.db();
    return db.query('items', where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<int> updateItem(int id, String name, String? lastName) async {
    final db = await SQLHelper.db();

    final data = {
      'name': name,
      ' lastName': lastName,
      'createdAT': DateTime.now().toString()
    };

    final result =
    await db.update('items', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<void> deleteItem(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("items", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> _journals = [];

  bool _isLoading = true;

  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;

    });
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals();
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  Future<void> _addItem() async {
    await SQLHelper.createItem(nameController.text, lastNameController.text);
    _refreshJournals();
    print(_journals.length);
  }

  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, nameController.text, lastNameController.text);
    _refreshJournals();
  }

  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully deleted a journal')));
    _refreshJournals();
  }

  void _showForm(int? id) async {
    if (id != null) {
      final existingJournal =
      _journals.firstWhere((element) => element['id'] == id);
      nameController.text = existingJournal['name'];
      lastNameController.text = existingJournal[' lastName'];
    }

    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 120,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Name'),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(hintText: 'Last Name'),
            ),
            const SizedBox(height: 20,),
            ElevatedButton(
                onPressed: () async {
                  if (id == null) {
                    await _addItem();
                  }
                  if (id != null) {
                    await _updateItem(id);
                  }
                  nameController.text = '';
                  lastNameController.text = '';
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text(id == null ? 'Save' : 'Update')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('sqflite'),
      ),
      body: ListView.builder(
          itemCount: _journals.length,
          itemBuilder: (context, index) => Card(
            color: Colors.white12,
            margin: const EdgeInsets.all(15),
            child: ListTile(
              title: Text(_journals[index]['name']),
              subtitle: Text(_journals[index]['lastName']),
              trailing: SizedBox(
                width: 100,
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () => _showForm(_journals[index]['id']),
                        icon: const Icon(Icons.edit)),
                    IconButton(
                        onPressed: () =>
                            _deleteItem(_journals[index]['id']),
                        icon: const Icon(Icons.delete)),
                  ],
                ),
              ),
            ),
          )),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
