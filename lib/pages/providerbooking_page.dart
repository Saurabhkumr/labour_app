import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProviderProfilePage extends StatefulWidget {
  final String providerId;

  ProviderProfilePage({required this.providerId});

  @override
  _ProviderProfilePageState createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _bookProvider() {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date and time.')),
      );
      return;
    }

    // Save the booking details to Firestore (for example purpose only)
    FirebaseFirestore.instance.collection('bookings').add({
      'providerId': widget.providerId,
      'date': selectedDate,
      'time': selectedTime!.format(context),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking successful!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provider Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('serviceprovider')
            .doc(widget.providerId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final provider = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${provider['firstname']} ${provider['lastname']}",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text("Service: ${provider['service']}",
                          style: TextStyle(fontSize: 16)),
                      Text("Experience: ${provider['experience']} years",
                          style: TextStyle(fontSize: 16)),
                      Text("Phone: ${provider['phone']}",
                          style: TextStyle(fontSize: 16)),
                      Text(
                        "Address: ${provider['address']['street']}, ${provider['address']['city']}, ${provider['address']['state']}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Date and Time",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: _selectDate,
                            child: Text(selectedDate == null
                                ? 'Select Date'
                                : DateFormat.yMMMd().format(selectedDate!)),
                          ),
                          ElevatedButton(
                            onPressed: _selectTime,
                            child: Text(selectedTime == null
                                ? 'Select Time'
                                : selectedTime!.format(context)),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _bookProvider,
                        child: Text('Book Now'),
                      ),
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Reviews",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('providerId', isEqualTo: widget.providerId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final reviews = snapshot.data!.docs;

                    if (reviews.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(child: Text('No reviews yet.')),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        final reviewData =
                            review.data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text("Rating: ${reviewData['rating']}",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(reviewData['comments']),
                          trailing: Text(
                            DateFormat.yMMMd().format(
                                (reviewData['date'] as Timestamp).toDate()),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
