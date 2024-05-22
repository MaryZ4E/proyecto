import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/screens/class_screen.dart';
import 'package:proyecto/services/avatar_firebase.dart';

class ClassDetailScreen extends StatefulWidget {
  final String idClass;
  final String myUserId;

  const ClassDetailScreen({
    required this.idClass,
    required this.myUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  DocumentSnapshot? _classData;
  List<DocumentSnapshot> _classUsers = [];
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchClassData();
    _fetchClassUsers();
  }

  void _fetchClassData() async {
    try {
      final classData = await FirebaseFirestore.instance
          .collection('class')
          .doc(widget.idClass)
          .get();

      setState(() {
        _classData = classData;
        _isAdmin = classData['idAdmin'] == widget.myUserId;
      });
    } catch (error) {
      print('Error al obtener los datos de la clase: $error');
    }
  }

  void _fetchClassUsers() async {
    try {
      final classUserSnapshot = await FirebaseFirestore.instance
          .collection('class-user')
          .where('classId', isEqualTo: widget.idClass)
          .get();

      final userIds =
          classUserSnapshot.docs.map((doc) => doc['userId']).toList();
      final userDocs = await Future.wait(
        userIds.map((userId) =>
            FirebaseFirestore.instance.collection('users').doc(userId).get()),
      );

      setState(() {
        _classUsers = userDocs;
      });
    } catch (error) {
      print('Error al obtener los usuarios de la clase: $error');
    }
  }

  void _deleteClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text(
              '¿Estás seguro de que deseas eliminar esta clase? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('class')
            .doc(widget.idClass)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clase eliminada con éxito.')),
        );
        // _navigation();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la clase: $error')),
        );
      }
      Navigator.pop(context);
      Navigator.pop(context);
      // Navigator.pop(context);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ClassScreen(
      //       userId: widget.idClass,
      //     ),
      //   ),
      // );
    }
  }

  // void _navigation() async {
  //   await Future.delayed(Duration(seconds: 1));
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ClassDetailScreen(
  //         myUserId: widget.myUserId,
  //         idClass: widget.idClass,
  //       ),
  //     ),
  //   );
  // }

  void _addPerson() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agregar persona a la clase',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar usuario...',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchText = '';
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: _buildUserList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar usuarios'));
        }
        final List<DocumentSnapshot> users = snapshot.data!.docs;
        final filteredUsers = users.where((user) {
          final userData = user.data() as Map<String, dynamic>;
          final id = user.id;
          final name = userData['nombre'].toString().toLowerCase();
          final email = userData['email'].toString().toLowerCase();
          return !_classUsers.any((classUser) => classUser.id == id) &&
              (name.contains(_searchText.toLowerCase()) ||
                  email.contains(_searchText.toLowerCase()));
        }).toList();

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userData =
                filteredUsers[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: FutureBuilder(
                future:
                    AvatarFirebase().consultarAvatar(filteredUsers[index].id),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.white),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.data() == null) {
                    return CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.white),
                    );
                  }
                  final avatarData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final avatarUrl = avatarData['imageUrl'];
                  return CircleAvatar(
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Icon(Icons.person) : null,
                  );
                },
              ),
              title: Text(userData['nombre']),
              subtitle: Text(userData['email']),
              onTap: () {
                _confirmAddUser(filteredUsers[index]);
              },
            );
          },
        );
      },
    );
  }

  void _confirmAddUser(DocumentSnapshot user) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar adición'),
          content: Text(
              '¿Estás seguro de que deseas agregar a este usuario a la clase?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Agregar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((confirm) {
      if (confirm == true) {
        _addUserToClass(user);
        Navigator.pop(context);
      }
    });
  }

  void _addUserToClass(DocumentSnapshot user) async {
    try {
      await FirebaseFirestore.instance.collection('class-user').add({
        'classId': widget.idClass,
        'userId': user.id,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario agregado con éxito.')),
      );
      _fetchClassUsers(); // Refresh class users
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar usuario: $error')),
      );
    }
  }

  void _leaveClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar abandono'),
          content: Text('¿Estás seguro de que deseas abandonar esta clase?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Abandonar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final classUserSnapshot = await FirebaseFirestore.instance
            .collection('class-user')
            .where('classId', isEqualTo: widget.idClass)
            .where('userId', isEqualTo: widget.myUserId)
            .get();

        if (classUserSnapshot.docs.isNotEmpty) {
          await classUserSnapshot.docs.first.reference.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Has abandonado la clase.')),
          );
          // _navigation();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No estás en la clase.')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abandonar la clase: $error')),
        );
      }
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ClassScreen(
      //       userId: widget.idClass,
      //     ),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de la Clase'),
        actions: [
          if (_isAdmin) ...[
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: _addPerson,
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteClass,
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: _leaveClass,
            ),
          ],
        ],
      ),
      body: _classData != null
          ? _buildClassDetails()
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildClassDetails() {
    final classData = _classData!.data() as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nombre:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            classData['nombre'] ?? 'Nombre no disponible',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Descripción:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            classData['descripcion'] ?? 'Descripción no disponible',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Usuarios en la clase:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _classUsers.isNotEmpty
                ? ListView.builder(
                    itemCount: _filteredClassUsers().length,
                    itemBuilder: (context, index) {
                      final userData = _filteredClassUsers()[index].data()
                          as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () {
                          // Manejar la acción cuando se selecciona un usuario
                          // Por ejemplo, navegar a la pantalla de perfil del usuario
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              leading: FutureBuilder(
                                future: AvatarFirebase().consultarAvatar(
                                    _filteredClassUsers()[index].id),
                                builder: (context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.data() == null) {
                                    return CircleAvatar(
                                      backgroundColor: Colors.grey[300],
                                      child: Icon(Icons.person,
                                          color: Colors.white),
                                    );
                                  }
                                  final avatarData = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  final avatarUrl = avatarData['imageUrl'];
                                  return CircleAvatar(
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? Icon(Icons.person)
                                        : null,
                                  );
                                },
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    userData['nombre'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(' '),
                                  Text(
                                    userData['rol'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userData['email'],
                                      style: TextStyle(color: Colors.grey)),
                                  if (userData['rol'] == 'Estudiante')
                                    Text('Semestre: ${userData['semestre']}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Center(child: Text('No hay usuarios en esta clase')),
          ),
        ],
      ),
    );
  }

  List<DocumentSnapshot> _filteredClassUsers() {
    if (_searchText.isEmpty) {
      return _classUsers;
    }
    return _classUsers.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final name = userData['nombre'].toString().toLowerCase();
      final email = userData['email'].toString().toLowerCase();
      return name.contains(_searchText.toLowerCase()) ||
          email.contains(_searchText.toLowerCase());
    }).toList();
  }
}