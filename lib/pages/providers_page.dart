import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:geolocator/geolocator.dart';
import 'package:service_app/pages/providerbooking_page.dart'; // Geolocation

class ProvidersPage extends StatelessWidget {
  final String serviceName;

  ProvidersPage({required this.serviceName});

  // Global variable to store distances
  final Map<String, double> providerDistances = {};

  // Fetch Nearby Providers
  Future<List<Map<String, dynamic>>> fetchNearbyProviders(
      String serviceName, Position userPosition) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('serviceprovider')
          .where('service', isEqualTo: serviceName)
          .get();

      // Clear distances before recalculating
      providerDistances.clear();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final providerLocation =
                data['location']; // Example: {"lat": 28.6, "lng": 77.2}

            // Calculate the distance and store it in the global variable
            final distance = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              providerLocation['lat'],
              providerLocation['lng'],
            );

            if (distance <= 10000) {
              // Filter providers within 10 km
              providerDistances[doc.id] =
                  distance; // Store distance with provider ID
              data['providerId'] = doc.id; // Add document ID for navigation
              data['distance'] = distance; // Include distance for sorting
              return data;
            }
            return null;
          })
          .where((provider) => provider != null) // Remove null entries
          .map((provider) => provider!) // Safely cast to non-nullable
          .toList();
    } catch (e) {
      print("Error fetching providers: $e");
      return [];
    }
  }

  // Retrieve User's Current Position
  Future<Position> getUserPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          "Location permissions are permanently denied. Cannot request permissions.");
    }

    // Get current location with updated method
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high, // Use LocationSettings to set accuracy
        distanceFilter: 10, // Optional: Set a distance filter
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nearby Providers")),
      body: FutureBuilder(
        future: getUserPosition().then(
            (userPosition) => fetchNearbyProviders(serviceName, userPosition)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return Center(child: Text("No providers found nearby."));
          }

          final providers = snapshot.data as List<Map<String, dynamic>>;
          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              final distance = providerDistances[provider['providerId']] ??
                  0.0; // Retrieve stored distance

              return ListTile(
                title: Text("${provider['firstname']} ${provider['lastname']}"),
                subtitle:
                    Text("${(distance / 1000).toStringAsFixed(2)} km away"),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Navigate to provider profile and booking page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderProfilePage(
                        providerId: provider['providerId'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
