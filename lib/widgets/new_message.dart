import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() {
    return _NewMessageState();
  }
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;
    if (enteredMessage.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSending = false;
    });

    _messageController.clear();
    FocusScope.of(context).unfocus(); // This line will close the keyboard once the message is cleared

    final currentUser = FirebaseAuth.instance.currentUser!;

    final currentUserData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    FirebaseFirestore.instance.collection('chats').add({
      'text': enteredMessage,
      'createdAt': Timestamp.now(),
      'userId': currentUser.uid,
      'username': currentUserData.data()!['username'],
      'userImage': currentUserData.data()!['image_url'],
    });
  }

  // This method is meant to set _isSending == true if the TextField is not empty (i.e., there is a message to be sent)
  void _handleTextChanged(String text) {
    setState(() {
      _isSending = text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: 'Message'),
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              onChanged: _handleTextChanged, // Listen for text changes
            ),
          ),
          IconButton(
            onPressed: _isSending ? _submitMessage : null,
            icon: Icon(
              Icons.send,
              color: _isSending
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
