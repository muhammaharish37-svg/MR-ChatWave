
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MRChatWave());
}

class MRChatWave extends StatelessWidget {
  const MRChatWave({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MR ChatWave',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final pages = [
    'Chats',
    'Status',
    'Calls',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: const Text(
          'MR ChatWave',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Icon(Icons.search),
          SizedBox(width: 20),
          Icon(Icons.more_vert),
          SizedBox(width: 12),
        ],
      ),
      body: selectedIndex == 0
          ? ListView(
              children: const [
                ChatTile('Ali Khan', 'Hello bro!', '10:30'),
                ChatTile('Ahmed', 'How are you?', '09:45'),
                ChatTile('Sara', 'Good morning ❤️', 'Yesterday'),
                ChatTile('Usman', 'See you soon!', 'Yesterday'),
                ChatTile('Friends Group', 'Welcome everyone', 'Monday'),
              ],
            )
          : Center(
              child: Text(
                pages[selectedIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A884),
        onPressed: () {},
        child: const Icon(Icons.message, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF075E54),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.circle_outlined),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call),
            label: 'Calls',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class ChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;

  const ChatTile(this.name, this.message, this.time, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF00A884),
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        message,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}


