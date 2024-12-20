import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Sign-in with Google
  void signInWithGoogle(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Trigger the Google Sign-In flow
      GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        // The user canceled the login
        Navigator.pop(context); // Hide loading indicator
        showErrorMessage(context, "Google sign-in was canceled.");
        return;
      }

      // Get the authentication details
      GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create the authentication credential
      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Sign in to Firebase with the credentials
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Get the user's unique ID
      String userId = userCredential.user!.uid;

      // Add user details to Firestore
      addUserDetails(
        userId: userId,
        firstName:
            userCredential.user!.displayName?.split(' ').first ?? 'No Name',
        lastName:
            userCredential.user!.displayName?.split(' ').last ?? 'No Last Name',
        email: userCredential.user!.email ?? 'No Email',
      );

      Navigator.pop(context); // Hide loading indicator
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Hide loading indicator
      showErrorMessage(context, e.message ?? "An error occurred.");
    }
  }

  // Add user details to Firestore
  Future<void> addUserDetails({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    });
  }

  // Show error message
  void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Sign out method
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
