import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_screen.dart';
import 'security/secure_key_storage.dart';

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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF101820),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const AuthScreen();
      },
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

  final pages = ['Chats', 'Status', 'Calls', 'Settings'];

  @override
  void initState() {
    super.initState();
    _saveUserToFirestore();
    _testLocalKeyStorage();
  }

  Future<void> _testLocalKeyStorage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firstKey = await SecureKeyStorage.getOrCreateTestKey(user.uid);
      final secondKey = await SecureKeyStorage.getOrCreateTestKey(user.uid);

      final passed =
          firstKey.length == 32 &&
          secondKey.length == 32 &&
          listEquals(firstKey, secondKey);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            passed
                ? 'Local key storage test successful'
                : 'Local key storage test failed',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Local key storage test error: ${e.runtimeType}');
    }
  }

  Future<void> _saveUserToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final name = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'ChatWave User';

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('publicProfiles')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'name': name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore user save error: $e');
    }
  }

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
      body: selectedIndex == 3
          ? const ProfileScreen()
          : selectedIndex == 0
          ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('publicProfiles')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Users load nahi ho sake',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                final users =
                    snapshot.data?.docs
                        .where((doc) => doc.id != currentUid)
                        .toList() ??
                    [];

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'Abhi koi doosra registered user nahi hai',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data();
                    final name = data['name'] as String? ?? 'ChatWave User';

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
                      subtitle: const Text(
                        'MR ChatWave user',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(name: name),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )
          : Center(
              child: Text(
                pages[selectedIndex],
                style: const TextStyle(color: Colors.white, fontSize: 28),
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
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.circle_outlined),
            label: 'Status',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(name: name)),
        );
      },
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
      subtitle: Text(message, style: const TextStyle(color: Colors.white70)),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String name;

  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(text);
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: Text(widget.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF075E54),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _messages[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF18232D),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Message likhein...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF263540),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Color(0xFF00A884)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_photo_path');
    if (path != null && await File(path).exists() && mounted) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final extension = picked.path.split('.').last;
      final savedFile = await File(picked.path)
          .copy('${directory.path}/profile_photo.$extension');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_path', savedFile.path);

      if (!mounted) return;
      setState(() {
        _profileImage = savedFile;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Photo error: $e')));
    }
  }

  Future<void> _editName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName ?? "");

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter your name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              try {
                await user.updateDisplayName(name);
                await user.reload();

                if (!mounted || !dialogContext.mounted) return;
                setState(() {});
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Name updated successfully")),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 25),
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: const Color(0xFF00A884),
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person, size: 65, color: Colors.white)
                      : null,
                ),
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF00A884),
                    child: Icon(
                      Icons.camera_alt,
                      size: 19,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            user?.displayName ?? "MR ChatWave User",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 25),
        const Divider(color: Colors.white24),
        ListTile(
          leading: const Icon(Icons.person, color: Color(0xFF00A884)),
          title: const Text("Name", style: TextStyle(color: Colors.white70)),
          subtitle: Text(
            user?.displayName ?? "Name not set",
            style: const TextStyle(color: Colors.white),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF00A884)),
            onPressed: _editName,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.email, color: Color(0xFF00A884)),
          title: const Text("Email", style: TextStyle(color: Colors.white70)),
          subtitle: Text(
            user?.email ?? "No email",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: Color(0xFF00A884)),
          title: const Text(
            "About MR ChatWave",
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            "App information and founder",
            style: TextStyle(color: Colors.white70),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            );
          },
        ),
        const SizedBox(height: 25),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A884),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(14),
          ),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text("LOG OUT"),
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: const Text("About MR ChatWave"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 24),
          Icon(Icons.chat, size: 72, color: Color(0xFF00A884)),
          SizedBox(height: 16),
          Center(
            child: Text(
              "MR ChatWave",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              "Connect the World",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Divider(color: Colors.white24, height: 40),
          ListTile(
            leading: Icon(Icons.person, color: Color(0xFF00A884)),
            title: Text(
              "Founder & CEO",
              style: TextStyle(color: Colors.white70),
            ),
            subtitle: Text(
              "Maher Madni Mushtaq",
              style: TextStyle(color: Colors.white),
            ),
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: Color(0xFF00A884)),
            title: Text("App Version", style: TextStyle(color: Colors.white70)),
            subtitle: Text("1.0.0", style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            leading: Icon(Icons.copyright, color: Color(0xFF00A884)),
            title: Text("Copyright", style: TextStyle(color: Colors.white70)),
            subtitle: Text(
              "© 2026 MR ChatWave. All rights reserved.",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
