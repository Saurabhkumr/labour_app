import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add for authentication
import 'package:service_app/pages/providers_page.dart';

class ServicesPage extends StatefulWidget {
  @override
  _ServicesPageState createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final List<Map<String, String>> services = [
    {"name": "Plumber"},
    {"name": "Cleaner"},
    {"name": "Electrician"},
    // Add more services
  ];

  String? firstName;

  @override
  void initState() {
    super.initState();
    // Request permission and fetch location when the page is built
    _requestLocationPermission(context);

    // Fetch the user's name from Firebase
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user name from FirebaseFirestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            firstName = userDoc['firstName'];
          });
        }
      }
    } catch (e) {
      print("Error fetching name: $e");
    }
  }

  Future<void> _requestLocationPermission(BuildContext context) async {
    // Check the current permission status
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted) {
      // If permission is already granted, fetch location
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high, // Use LocationAccuracy directly
          distanceFilter: 100,
        ),
      );

      // Save the location to Firebase
      _saveUserLocationToFirebase(position);
    } else if (status.isDenied || status.isRestricted) {
      // If permission is not granted, request permission
      PermissionStatus requestedPermission =
          await Permission.location.request();

      // After the user responds to the permission dialog
      if (requestedPermission.isGranted) {
        // If the user grants permission, fetch the location
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 100,
          ),
        );

        // Save the location to Firebase
        _saveUserLocationToFirebase(position);
      } else {
        // Handle permission denied case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied!')),
        );
      }
    } else {
      // If permission status is unknown or something else
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location permission!')),
      );
    }
  }

  Future<void> _saveUserLocationToFirebase(Position position) async {
    try {
      final userId =
          FirebaseAuth.instance.currentUser?.uid; // Get the current user's ID
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'location': {
            'lat': position.latitude,
            'lng': position.longitude,
          }
        });
      }
    } catch (e) {
      print("Error saving location to Firebase: $e");
    }
  }

  // Logout function
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(
          context, '/login'); // Navigate to login page after logout
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select a Service")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // User info header
            UserAccountsDrawerHeader(
              accountName: Text(firstName ?? 'Guest'),
              accountEmail:
                  Text(FirebaseAuth.instance.currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black),
              ),
            ),
            ListTile(
              title: Text("Logout"),
              onTap: () {
                _logout();
              },
            ),
          ],
        ),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Navigate to providers list
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProvidersPage(serviceName: services[index]['name']!),
                ),
              );
            },
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 10),
                  Text(services[index]['name']!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
