import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hastane_otomasyonu/pages/book_appointment_page.dart';
import 'package:hastane_otomasyonu/pages/main_page.dart';
import 'package:hastane_otomasyonu/pages/patient_appointments_page.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      userName = userDoc['ad'] + ' ' + userDoc['soyad'] ?? 'Hasta';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hasta Ana Sayfası"),
        centerTitle: true,
        backgroundColor: Colors.teal, // Ana sayfa ile uyumlu renk
      ),
      drawer: Drawer(
        backgroundColor: Colors.teal[50], // Alternatif renk tonu
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal, // Ana rengimizi başlıkta kullanalım
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Center(
                child: Text(
                  "Hoşgeldiniz, $userName",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            _buildDrawerItem("Randevu Al", onTap: _navigateToBookAppointment),
            _buildDrawerItem("Randevularım", onTap: _navigateToAppointments),
            const Spacer(),
            _buildDrawerItem(
              "Çıkış Yap",
              color: Colors.redAccent, // Çıkış yapma rengi
              onTap: _showExitConfirmationDialog,
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          "Hoşgeldiniz,\n$userName",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal[700], // Alternatif renk tonu
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title,
      {Color color = Colors.teal, void Function()? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Material(
          color: color,
          child: InkWell(
            onTap: onTap,
            child: ListTile(
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color:
                      color == Colors.redAccent ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToBookAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookAppointmentPage(),
      ),
    );
  }

  void _navigateToAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientAppointmentsPage(),
      ),
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Çıkış Yapmak Üzeresiniz"),
          content: const Text("Çıkış yapmak istediğinizden emin misiniz?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Hayır"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Evet"),
              onPressed: () {
                FirebaseAuth.instance.signOut().then((_) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainPage(),
                    ),
                    (route) => false, // Tüm mevcut rotaları temizler
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }
}
