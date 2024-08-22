import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hastane_otomasyonu/firebase/firebase.dart';
import 'package:hastane_otomasyonu/pages/login_page.dart';
import 'package:hastane_otomasyonu/pages/patient_home_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController tcId = TextEditingController();
  final TextEditingController ad = TextEditingController();
  final TextEditingController soyad = TextEditingController();
  final TextEditingController cinsiyet = TextEditingController();
  final TextEditingController dogumYeri = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController sifre = TextEditingController();

  Future<void> _signup() async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: sifre.text.trim(),
      );
      await FirebaseClass().saveUserData(
        tcId.text.trim(),
        ad.text.trim(),
        soyad.text.trim(),
        cinsiyet.text.trim(),
        dogumYeri.text.trim(),
        email.text.trim(),
        sifre.text.trim(),
        "hasta",
      );
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PatientHomePage()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Zayıf şifre, daha güçlü bir şifre deneyin.")),
        );
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bu email'e ait bir hesap zaten mevcut."),
            action: SnackBarAction(
              label: "Giriş Yap",
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kayıt Ol"),
        centerTitle: true,
        backgroundColor: Colors.teal, // Ana renk uyumlu
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(tcId, "TC Kimlik No", maxLength: 11),
            _buildTextField(ad, "Ad"),
            _buildTextField(soyad, "Soyad"),
            _buildDropdownField(cinsiyet, "Cinsiyet", ['Erkek', 'Kadın']),
            _buildDropdownField(dogumYeri, "Doğum Yeri", [
              'Adana', 'Adıyaman', 'Afyonkarahisar',
              'Ağrı', // Diğer şehirleri de ekleyin
            ]),
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
              onPressed: _signup,
              child: const Text("Kayıt Ol",
                  style: TextStyle(fontSize: 18, color: Colors.black)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text(
                "Zaten hesabınız var mı? Giriş Yapın",
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
      {bool obscureText = false, int? maxLength}) {
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
        maxLength: maxLength,
      ),
    );
  }

  Widget _buildDropdownField(
      TextEditingController controller, String labelText, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: Colors.teal[50], // Arka plan rengi
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            controller.text = newValue ?? '';
          });
        },
      ),
    );
  }
}
