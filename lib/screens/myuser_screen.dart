import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/screens/home_cliente_screen.dart';
import 'package:proyecto/screens/select_avatar_screen.dart';
import 'package:proyecto/settings/app_value_notifier.dart';

class MyUserScreen extends StatefulWidget {
  final String userId;

  const MyUserScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyUserScreen> createState() => _MyUserScreenState();
}

class _MyUserScreenState extends State<MyUserScreen> {
  late String _userName = '';
  late String _userEmail = '';
  late String _userRole = '';
  late String _userAvatarUrl = '';
  late Color _userColor = Colors.blue; // Default color

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _userName = userData['nombre'] ?? 'Nombre no disponible';
          _userEmail = userData['email'] ?? 'Correo no disponible';
          _userRole = userData['rol'] ?? 'Rol no disponible';
          _userColor =
              AppValueNotifier.getColorFromString(userData['color'] ?? 'blue');
          AppValueNotifier.setTheme(_userColor);
        });
      }

      final avatarSnapshot = await FirebaseFirestore.instance
          .collection('avatars')
          .doc(widget.userId)
          .get();
      if (avatarSnapshot.exists) {
        final avatarData = avatarSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _userAvatarUrl = avatarData['imageUrl'];
        });
      }
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
    }
  }

  Future<void> _saveUserColor(String colorString) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'color': colorString});
      setState(() {
        _userColor = AppValueNotifier.getColorFromString(colorString);
        AppValueNotifier.setTheme(_userColor);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Color actualizado'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error guardando el color del usuario: $e');
    }
  }

  Future<void> _subscribeToTheme() async {
    try {
      // Implementa aquí la lógica para suscribir al usuario al tema en Firebase
      // Por ejemplo, puedes usar Firebase Cloud Messaging para enviar notificaciones
      // relacionadas con el tema seleccionado.
      // Implementa la lógica según la estructura de tu base de datos en Firestore.
      // Aquí tienes un ejemplo básico de cómo suscribir al usuario al tema:

      // Primero, obtén una referencia a la colección de temas en Firebase
      final themeCollection = FirebaseFirestore.instance.collection('themes');

      // Luego, actualiza los datos del usuario para incluir la suscripción al tema
      await themeCollection.doc(widget.userId).update({'subscribed': true});

      // Puedes agregar aquí cualquier otra lógica necesaria, como enviar una notificación o realizar otras acciones relacionadas con la suscripción al tema.

      // Muestra un mensaje de éxito al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Te has suscrito al tema correctamente'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error al suscribir al tema: $e');
      // Maneja cualquier error que pueda ocurrir durante la suscripción al tema
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hubo un error al suscribirte al tema'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _subscribeToMessaging() async {
    try {
      // Implementa aquí la lógica para suscribir al usuario al servicio de mensajería
      // Puedes utilizar Firebase Cloud Messaging o cualquier otro servicio de mensajería.
      // Implementa la lógica según sea necesario para tus requerimientos.
      // Aquí tienes un ejemplo básico de cómo suscribir al usuario al servicio de mensajería:

      // Primero, obtén una referencia al servicio de mensajería en Firebase
      final messagingService = FirebaseMessaging.instance;

      // Luego, suscribe al usuario al servicio de mensajería
      await messagingService.subscribeToTopic('general');

      // Puedes agregar aquí cualquier otra lógica necesaria, como enviar una notificación o realizar otras acciones relacionadas con la suscripción al servicio de mensajería.

      // Muestra un mensaje de éxito al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Te has suscrito al servicio de mensajería correctamente'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error al suscribir al servicio de mensajería: $e');
      // Maneja cualquier error que pueda ocurrir durante la suscripción al servicio de mensajería
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Hubo un error al suscribirte al servicio de mensajería'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi perfil'),
        backgroundColor: _userColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeClienteScreen(
                        myIdUser: widget.userId,
                      )),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.subscriptions), // Ícono de suscripción al tema
            onPressed:
                _subscribeToTheme, // Lógica para suscribir al usuario al tema
          ),
          IconButton(
            icon: Icon(Icons
                .message), // Ícono de suscripción al servicio de mensajería
            onPressed:
                _subscribeToMessaging, // Lógica para suscribir al usuario al servicio de mensajería
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 100,
                backgroundImage: _userAvatarUrl.isNotEmpty
                    ? NetworkImage(_userAvatarUrl)
                    : AssetImage('assets/default_avatar.png') as ImageProvider,
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SelectAvatarScreen(
                              userId: widget.userId,
                            )),
                  );
                },
                child: Text(
                  'Cambiar imagen',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '$_userName',
                style: TextStyle(
                  fontSize: 30,
                ),
              ),
              SizedBox(height: 15),
              Text(
                '$_userEmail',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 20),
              Text(
                '$_userRole',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Seleccionar color de tema:',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _colorOption(Colors.blue, 'blue'),
                  _colorOption(Colors.green, 'green'),
                  _colorOption(Colors.red, 'red'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorOption(Color color, String colorString) {
    return GestureDetector(
      onTap: () {
        _saveUserColor(colorString);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _userColor == color ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}
