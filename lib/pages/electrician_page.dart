import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Electrician Data Model
class Electrician {
  final String firstname;
  final String lastname;
  final String phone;
  final double lat;
  final double lng;
  final List<String> reviews;

  Electrician({
    required this.firstname,
    required this.lastname,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.reviews,
  });

  // Factory constructor to create an Electrician object from Firestore data
  factory Electrician.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Electrician(
      firstname: data['firstname'] ?? '',
      lastname: data['lastname'] ?? '',
      phone: data['phone'].toString(),
      lat: data['lat']?.toDouble() ?? 0.0, // Now directly accessed as double
      lng: data['lng']?.toDouble() ?? 0.0, // Now directly accessed as double
      reviews: List<String>.from(data['reviews'] ?? []),
    );
  }
  String get fullName => '$firstname $lastname';
}

class ElectricianPage extends StatefulWidget {
  const ElectricianPage({super.key});

  @override
  State<ElectricianPage> createState() => _ElectricianPageState();
}

class _ElectricianPageState extends State<ElectricianPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Electricians"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('electricians').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No electricians found.'));
          }
          final electricians = snapshot.data!.docs
              .map((doc) => Electrician.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: electricians.length,
            itemBuilder: (context, index) {
              final electrician = electricians[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(electrician.firstname[0]),
                  ),
                  title: Text(electrician.fullName),
                  subtitle: Text('Phone: ${electrician.phone}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BookingPage(electrician: electrician),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BookingPage extends StatelessWidget {
  final Electrician electrician;

  const BookingPage({super.key, required this.electrician});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${electrician.fullName} - Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Electrician Profile
            Row(
              children: [
                CircleAvatar(
                  radius: 50,
                  child: Text(
                    electrician.firstname[0],
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      electrician.fullName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text('Phone: ${electrician.phone}'),
                    Text('Location: (${electrician.lat}, ${electrician.lng})'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Reviews Section
            const Text(
              'Reviews:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...electrician.reviews.map((review) => Text('⭐ $review')).toList(),
            const SizedBox(height: 20),
            // Book Appointment Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking successful!')),
                  );
                },
                child: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
