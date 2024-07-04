import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatefulWidget {
  const ChatMessages({super.key});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {


void setUpPushNotifications() async{
  final firebaseMessageObject = FirebaseMessaging.instance;
  final notificationSettings =  await firebaseMessageObject.requestPermission(); //asks the user to request and receive push notifications

  final token = await firebaseMessageObject.getToken(); //getToken yields the address of different devices through which we can target the push notifications to different devices
// print(token);

firebaseMessageObject.subscribeToTopic('chats');
}
  @override
  void initState() {
    
    super.initState();
    setUpPushNotifications();
    

  }

  @override
  Widget build(BuildContext context) {

    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, chatSnapshots) {
        if (chatSnapshots.connectionState == ConnectionState.waiting) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              const Text(
                'Please wait while we load your messages!',
                style: TextStyle(
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              )
            ],
          );
        }
        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages found. Start chatting!'),
          );
        }
        if (chatSnapshots.hasError) {
          return const Center(
            child: Text('Something went wrong...'),
          );
        }
        final loadedMessages = chatSnapshots.data!.docs;
        return ListView.builder(
          padding:
              const EdgeInsets.only(bottom: 40, left: 13, right: 13, top: 20),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            final chatMessage = loadedMessages[index].data();//chatMessage is the first message by a user
            final nextMessage = index + 1 < loadedMessages.length //First we check if there is a next message or not? This is done by adding +1 to the index and comparing it with the length of loaded messages. if index+1<loadedMessages.length means there is a nextMessage in line after the first chatMessage.
                ? loadedMessages[index + 1].data() //if a next message exists we get a hold of it by adding +1 to the index
                : null; //if nextMessage doesn't exist we return null.

            final currentMessageUserId = chatMessage['userId'];
            final nextMessageUserId = nextMessage != null ? nextMessage['userId'] : null;

            final nextUserIsSame = nextMessageUserId == currentMessageUserId;

            if(nextUserIsSame){
              return MessageBubble.next(message: chatMessage['text'], isMe: authenticatedUser.uid == currentMessageUserId);
            }else{
              return MessageBubble.first(userImage: chatMessage['userImage'], username: chatMessage['username'], message: chatMessage['text'], isMe: authenticatedUser.uid == currentMessageUserId);            }

          },
        );
      },
    );
  }
}
