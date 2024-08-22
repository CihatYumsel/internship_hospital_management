import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorAppointmentsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Randevularım"),
        backgroundColor: Colors.teal, // AppBar rengi
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .orderBy('date')
            .orderBy('time')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Randevunuz bulunmamaktadır.'));
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment =
                  appointments[index].data() as Map<String, dynamic>;
              final userId = appointment['userId'] as String;
              final status = appointment['status'] as String;

              return Card(
                elevation: 5, // Kartın gölgesi
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                      'Tarih: ${appointment['date']}\nSaat: ${appointment['time']}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Text('Hasta: Yükleniyor...');
                      }

                      if (userSnapshot.hasError || !userSnapshot.hasData) {
                        return Text('Hasta: Bilgi alınamadı');
                      }

                      final user =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final firstName = user['ad'] ?? 'Bilinmiyor';
                      final lastName = user['soyad'] ?? '';
                      final patientName = '$firstName $lastName';

                      return Text('Hasta: $patientName');
                    },
                  ),
                  trailing: status == 'cancelled'
                      ? Text(
                          'İptal Edildi',
                          style: TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            final bool? shouldCancel = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Randevu İptali'),
                                content: Text(
                                    'Bu randevuyu iptal etmek istediğinize emin misiniz?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text('Hayır'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text('Evet'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldCancel == true) {
                              final appointmentId = appointments[index].id;
                              final date = appointment['date'] as String;
                              final time = appointment['time'] as String;

                              await FirebaseFirestore.instance
                                  .collection('appointments')
                                  .doc(appointmentId)
                                  .update({
                                'status': 'cancelled',
                              });

                              final availabilityDoc = FirebaseFirestore.instance
                                  .collection('doctors')
                                  .doc(doctorId)
                                  .collection('availability')
                                  .doc(date);

                              await FirebaseFirestore.instance
                                  .runTransaction((transaction) async {
                                final docSnapshot =
                                    await transaction.get(availabilityDoc);

                                if (!docSnapshot.exists) {
                                  transaction.set(availabilityDoc, {
                                    'availableTimes': [time],
                                  });
                                } else {
                                  final availableTimes = List<String>.from(
                                      docSnapshot.data()?['availableTimes'] ??
                                          []);
                                  if (!availableTimes.contains(time)) {
                                    availableTimes.add(time);
                                    transaction.update(availabilityDoc, {
                                      'availableTimes': availableTimes,
                                    });
                                  }
                                }
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Randevu iptal edildi ve uygun saatler geri eklendi.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Text('İptal Et'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
