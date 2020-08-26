import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tut_chat/pages/textComposer.dart';
import 'package:tut_chat/ui/chat/chatMessage.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User _currentFirebaseUser;
  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) { 
      _currentFirebaseUser = user;
    });
  }

  Future<User> _getUser() async {

    if(_currentFirebaseUser != null) return _currentFirebaseUser;

    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);

      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User user = authResult.user;

      return user;
    } catch (e) {
      return null;
    }
  }

  void _sendMessage({String text, File imgFile}) async {
    final User firebaseUser = await _getUser();

    if(firebaseUser == null){
       _scaffoldKey.currentState.showSnackBar(
         SnackBar(content:  Text('Não foi possível realizar o login.'),
         backgroundColor: Colors.red)
       );
    }
    Map<String, dynamic> data = {
      "uid": firebaseUser.uid,
      "senderName": firebaseUser.displayName,
      "senderPhotoUrl": firebaseUser.photoURL
    };

    if (imgFile != null) {
      StorageUploadTask task = FirebaseStorage.instance
          .ref()
          .child(DateTime.now().microsecondsSinceEpoch.toString())
          .putFile(imgFile);

      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;
    }

    if (text != null && text.isNotEmpty) {
      data['text'] = text;
    }

    FirebaseFirestore.instance.collection('messages').doc().set(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
        appBar: AppBar(
          title: Text('olá!'),
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .snapshots(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return Center(
                        child: CircularProgressIndicator(),
                      );

                      break;
                    default:
                      List<DocumentSnapshot> documents =
                          snapshot.data.docs.reversed.toList();

                      return ListView.builder(
                          itemCount: documents.length,
                          reverse: true,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: ChatMessage(documents[index].data(), true),
                            );
                          });
                  }
                },
              ),
            ),
            TextComposer(_sendMessage),
          ],
        ));
  }
}
