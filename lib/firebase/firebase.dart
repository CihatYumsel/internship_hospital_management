import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseClass {
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userSnapshot.exists) {
        final dynamic userData = userSnapshot.data();
        if (userData != null && userData['rol'] != null) {
          return userData['rol'].toString();
        }
      }
    } catch (e) {
      print('Rol alınamadı: $e');
    }
    return null;
  }

  Future<String?> getUserName(String uid) async {
    try {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userSnapshot.exists) {
        final dynamic userData = userSnapshot.data();
        if (userData != null && userData['ad'] != null) {
          return "${userData['ad']} ${userData["soyad"]}";
        }
      }
    } catch (e) {
      print('Ad alınamadı: $e');
    }
    return null;
  }

  Future<void> saveUserData(
      String tcNo,
      String ad,
      String soyad,
      String cinsiyet,
      String dogumYeri,
      String email,
      String sifre,
      String rol) async {
    final userID = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection("users").doc(userID).set({
      "tcNo": tcNo,
      "ad": ad,
      "soyad": soyad,
      "cinsiyet": cinsiyet,
      "dogumYeri": dogumYeri,
      "email": email,
      "sifre": sifre,
      "rol": rol
    });
  }

  Future<void> createUserWithEmailAndPassword(
      String tcId,
      String ad,
      String soyad,
      String cinsiyet,
      String dogumYeri,
      String email,
      String sifre,
      String rol) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: sifre,
      );
      await saveUserData(
          tcId, ad, soyad, cinsiyet, dogumYeri, email, sifre, rol);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String sifre) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: sifre,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }
}
