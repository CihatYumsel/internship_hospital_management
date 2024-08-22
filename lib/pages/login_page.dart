import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hastane_otomasyonu/firebase/firebase.dart';
import 'package:hastane_otomasyonu/pages/doctor_home_page.dart';
import 'package:hastane_otomasyonu/pages/patient_home_page.dart';
import 'package:hastane_otomasyonu/pages/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController sifre = TextEditingController();

  Future<void> _login() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: sifre.text.trim(),
      );
      final role = await FirebaseClass().getUserRole(credential.user!.uid);
      if (role == "hasta") {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PatientHomePage()),
        );
      } else {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DoctorHomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bu email için bir kullanıcı bulunamadı.")),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hatalı şifre.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giriş Yap"),
        centerTitle: true,
        backgroundColor: Colors.teal, // Ana renk uyumlu
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 100),
            _buildTextField(email, "Email"),
            _buildTextField(sifre, "Şifre", obscureText: true),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                    Colors.teal), // Renk temasına uygun
                padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 15)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                )),
                elevation: MaterialStateProperty.all(10),
              ),
              onPressed: _login,
              child: const Text("Giriş Yap",
                  style: TextStyle(fontSize: 18, color: Colors.black)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPage()),
                );
              },
              child: const Text(
                "Hesabınız yok mu? Kayıt Olun",
                style: TextStyle(color: Colors.black),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.teal, // Renk temasına uygun
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: Colors.teal[50], // Arka plan rengi
        ),
        obscureText: obscureText,
      ),
    );
  }
}
