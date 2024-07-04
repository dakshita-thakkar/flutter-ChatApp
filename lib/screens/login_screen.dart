import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:io';

final _firebase = FirebaseAuth.instance;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  bool _newUser =
      true; //to check if the current user is a new user(sign-up) else login
  bool _isLogin = true; //to check if we are currently in login mode or not.
  final String emailPattern =
      r'^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$'; //Email RegEx
  final String passwordPattern =
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$'; //Password RegEx
  final _formKey = GlobalKey<FormState>(); //To store the form input values
  var _enteredEmail = ''; //initial email value
  var _enteredPassword = ''; //initial password value
  File? _enteredImage; //to store the user's image in the sign-up mode
  var _isAuthenticating = false;
  var _enteredUsername = ''; //initially username is an empty string

  void _showDialogue(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      message,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      label: const Text('Okay'),
                      icon: const Icon(Icons.check),
                    )
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }

  void _submit() async {
    final _isValid = _formKey.currentState!.validate();

    if (!_isValid || !_isLogin && _enteredImage == null) {
      //if inputs not valid, and the user did'nt pick an image in the sign-up mode, the code will not run further.
      _showDialogue('Picking an Image is Mandatory!');
      return;
    } else {
      //else save the credentials and post the credentials to Firebase using the signInwithEmailAndPassword method(if login mode)/createUserWithEmailAndPassword(if sign-up mode)
      _formKey.currentState!.save();
      try {
        setState(() {
          _isAuthenticating = true;
        });
        //using try-catch block becoz the signInwithEmailAndPassword method/createUserWithEmailAndPassword method may yield an error
        if (_isLogin) {
          final userCredentials = await _firebase.signInWithEmailAndPassword(
              email: _enteredEmail, password: _enteredPassword);
          print(userCredentials);
          // Handle successful login
        } else {
          final userCredentials =
              await _firebase.createUserWithEmailAndPassword(
                  email: _enteredEmail, password: _enteredPassword);
          //FireBase Auth does not support direct upload of images, hence we need to create a new User((created when we created the userCredentials) using the Firebase Auth package and then we can store any extra details associated with the user
          //FirebaseStorage package's instance was created, ref() give a reference to the firebase, a new folder called 'user-images' was created, withing which we will save every image with the name of user's id.jpg
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('${userCredentials.user!.uid}.jpg');
          await storageRef.putFile(_enteredImage!);
          final uploadedImageURL = await storageRef.getDownloadURL();
          print(uploadedImageURL);
          // Handle successful signup
          print(userCredentials);

          //Uploading the image to cloud
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredentials.user!.uid)
              .set({
            'username': _enteredUsername,
            'email': _enteredEmail,
            'image_url': uploadedImageURL
          });
        }
      } on FirebaseAuthException catch (error) {
        //In case of errors in login/sign-up appropriate error messages are shown in a Snackbar
        if (error.code == 'email-already-in-use') {
          // Handle email already in use error
        } else {
          // Handle other FirebaseAuthException errors
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? 'Authentication Failed')));
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('Login/Sign Up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    top: 30, bottom: 20, left: 20, right: 20),
                width: 200,
                child: Image.asset('assets/images/conversation.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePicker(
                              onPickedImage: (pickedImage) {
                                _enteredImage = pickedImage;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                                label: Row(
                              children: [
                                Text('Email Address'),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  Icons.email_rounded,
                                  color: Color.fromARGB(69, 0, 0, 0),
                                )
                              ],
                            )),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains(RegExp(emailPattern))) {
                                return 'Please enter a valid Email';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          if (!_isLogin)
                            TextFormField(
                              keyboardType: TextInputType.text,
                              enableSuggestions: false,
                              decoration: const InputDecoration(
                                  label: Row(
                                children: [
                                  Text('Username'),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Icon(Icons.person,
                                      color: Color.fromARGB(69, 0, 0, 0)),
                                ],
                              )),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    value.trim().length < 4) {
                                  return 'Username must be at least 4 characters long';
                                }
                                return null;
                              },
                              onSaved: (newValue) =>
                                  _enteredUsername = newValue!,
                            ),
                          const SizedBox(
                            height: 5,
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                                label: Row(
                              children: [
                                Text('Password'),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(Icons.key_rounded,
                                    color: Color.fromARGB(69, 0, 0, 0))
                              ],
                            )),
                            obscureText: true,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains(RegExp(passwordPattern))) {
                                return 'Please enter a valid password.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer),
                                child: Text(_isLogin ? 'Login' : 'Sign Up')),
                          if (!_isAuthenticating)
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                    _newUser = !_newUser;
                                  });
                                },
                                child: Text(_newUser
                                    ? 'Create an account'
                                    : 'I already have an account'))
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
