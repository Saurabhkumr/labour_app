import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:service_app/pages/electrician_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to handle logout
  void signUserOut() {
    _auth.signOut();
    Navigator.of(context)
        .pushReplacementNamed('/login'); // Optional: Navigate to login page
  }

  // Service Items List
  final List<Map<String, dynamic>> services = [
    {
      'title': 'Electrician',
      'icon': Icons.electrical_services,
      'color': Colors.blue,
      'page': ElectricianPage()
    },
    {
      'title': 'Plumber',
      'icon': Icons.plumbing,
      'color': Colors.green,
      // 'page': PlumberPage()
    },
    {
      'title': 'Carpenter',
      'icon': Icons.handyman,
      'color': Colors.orange,
      // 'page': CarpenterPage()
    },
    {
      'title': 'Car Mechanic',
      'icon': Icons.car_repair,
      'color': Colors.red,
      // 'page': CarMechanicPage()
    },
    // Add more services here if needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Service Provider"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signUserOut, // Logout button in AppBar
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Available Services",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        service['icon'],
                        color: service['color'],
                      ),
                      title: Text(service['title']),
                      onTap: () {
                        // Navigate to the respective page for the selected service
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => service['page'],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
