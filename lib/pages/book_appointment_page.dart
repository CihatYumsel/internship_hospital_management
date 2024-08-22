import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class BookAppointmentPage extends StatefulWidget {
  @override
  _BookAppointmentPageState createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  String? selectedSpecialty;
  String? selectedDoctorId;
  DateTime? selectedDate;
  List<DateTime> availableDates = [];
  List<String> availableTimes = []; // Saatleri saklamak için
  List<Map<String, String>> doctors = [];
  List<String> specialties = [];
  String? selectedTime;

  @override
  void initState() {
    super.initState();
    fetchSpecialties();
  }

  Future<void> fetchSpecialties() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('specialties').get();
      final specialtiesList =
          snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
      setState(() {
        specialties = specialtiesList;
      });
    } catch (e) {
      print('Uzmanlık alanlarını alırken bir hata oluştu: $e');
    }
  }

  Future<void> fetchDoctors(String specialty) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('specialty', isEqualTo: specialty)
          .get();

      final doctorsList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id, // Doktorun ID'si
          'name': data['name'] as String? ?? '',
        };
      }).toList();

      setState(() {
        doctors = doctorsList;
        selectedDoctorId = null; // Doktor değiştiğinde seçim sıfırlanır
        availableDates = [];
        selectedDate = null; // Seçili tarihi sıfırla
        selectedTime = null; // Seçili saati sıfırla
        availableTimes = []; // Saatleri sıfırla
      });
    } catch (e) {
      print('Doktorları alırken bir hata oluştu: $e');
    }
  }

  Future<void> fetchAvailableDates(String doctorId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('availability')
          .get();

      final availableDatesList = <DateTime>[];
      final dateFormat = DateFormat('dd-MM-yyyy');

      for (var doc in docSnapshot.docs) {
        final dateStr = doc.id; // Tarih (dd-MM-yyyy formatında)
        final data = doc.data() as Map<String, dynamic>;
        final availableTimes = List<String>.from(data['availableTimes'] ?? []);

        // Eğer saatler varsa, bu tarihi uygun tarihler listesine ekle
        if (availableTimes.isNotEmpty) {
          try {
            final date = dateFormat.parse(dateStr);
            availableDatesList.add(date);
          } catch (e) {
            print('Tarih formatında bir hata oluştu: $e');
          }
        }
      }

      setState(() {
        availableDates = availableDatesList;
      });
    } catch (e) {
      print('Uygun tarihleri alırken bir hata oluştu: $e');
    }
  }

  Future<void> fetchAvailableTimes(DateTime date) async {
    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      final dateStr = dateFormat.format(date); // Gün Ay Yıl formatında
      final docSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(selectedDoctorId)
          .collection('availability')
          .doc(dateStr)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final times = List<String>.from(data['availableTimes'] ?? []);

        // Saatleri artan sırada sıralama
        times.sort((a, b) => a.compareTo(b));

        setState(() {
          availableTimes = times;
        });
      } else {
        print('Saatler bulunamadı.');
      }
    } catch (e) {
      print('Uygun saatleri alırken bir hata oluştu: $e');
    }
  }

  Future<void> bookAppointment() async {
    if (selectedDoctorId == null ||
        selectedDate == null ||
        selectedTime == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Eksik Bilgi'),
          content: Text('Lütfen doktor, tarih ve saat seçin.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final dateFormat = DateFormat('dd-MM-yyyy');
      final appointmentDate = dateFormat.format(selectedDate!);

      await FirebaseFirestore.instance.collection('appointments').add({
        'date': appointmentDate,
        'time': selectedTime,
        'doctorId': selectedDoctorId,
        'notes': '',
        'status': 'upcoming',
        'userId': userId,
      });

      // Saat güncellemesi
      final availableTimesDoc = FirebaseFirestore.instance
          .collection('doctors')
          .doc(selectedDoctorId)
          .collection('availability')
          .doc(appointmentDate);

      final docSnapshot = await availableTimesDoc.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final availableTimes = List<String>.from(data['availableTimes'] ?? []);
        availableTimes.remove(selectedTime);

        if (availableTimes.isEmpty) {
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(selectedDoctorId)
              .collection('availability')
              .doc(appointmentDate)
              .delete();
          setState(() {
            availableDates.remove(selectedDate);
          });
        } else {
          await availableTimesDoc.update({'availableTimes': availableTimes});
        }
      }

      // Başarılı işlem sonrası bildirim
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Başarılı'),
          content: Text('Randevunuz başarıyla alındı.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tamam'),
            ),
          ],
        ),
      );

      // Seçimleri sıfırla
      setState(() {
        selectedSpecialty = null;
        selectedDoctorId = null;
        selectedDate = null;
        selectedTime = null;
        availableDates = [];
        availableTimes = [];
        doctors = [];
      });
    } catch (e) {
      print('Randevu alırken bir hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Randevu Al'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButton<String>(
                hint: Text('Uzmanlık Alanı Seçin'),
                value: selectedSpecialty,
                onChanged: (newValue) {
                  setState(() {
                    selectedSpecialty = newValue;
                    if (newValue != null) {
                      fetchDoctors(newValue);
                    }
                  });
                },
                items: specialties.map((specialty) {
                  return DropdownMenuItem<String>(
                    value: specialty,
                    child: Text(specialty),
                  );
                }).toList(),
              ),
              DropdownButton<String>(
                hint: Text('Doktor Seçin'),
                value: selectedDoctorId,
                onChanged: (newValue) {
                  setState(() {
                    selectedDoctorId = newValue;
                    if (newValue != null) {
                      fetchAvailableDates(newValue);
                    }
                  });
                },
                items: doctors.map((doctor) {
                  return DropdownMenuItem<String>(
                    value: doctor['id'],
                    child: Text(doctor['name'] ?? ''),
                  );
                }).toList(),
              ),
              if (selectedDoctorId != null) ...[
                Container(
                  margin: EdgeInsets.symmetric(vertical: 16.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: TableCalendar(
                      firstDay: DateTime.utc(
                          DateTime.now().year, DateTime.now().month, 1),
                      lastDay: DateTime.utc(
                          DateTime.now().year + 1, DateTime.now().month, 31),
                      focusedDay: selectedDate ??
                          DateTime.now(), // Güncel seçili tarihi göster
                      selectedDayPredicate: (day) {
                        return selectedDate != null &&
                            isSameDay(selectedDate, day);
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        defaultDecoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        disabledDecoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        outsideDecoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: TextStyle(color: Colors.black),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (availableDates
                            .any((date) => isSameDay(date, selectedDay))) {
                          setState(() {
                            selectedDate = selectedDay;
                            fetchAvailableTimes(selectedDay);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Seçtiğiniz tarih uygun değil.'),
                            ),
                          );
                        }
                      },
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          bool isAvailable = availableDates
                              .any((date) => isSameDay(date, day));
                          return Container(
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? Colors.white
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color:
                                      isAvailable ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (selectedDate != null) ...[
                  DropdownButton<String>(
                    hint: Text('Saat Seçin'),
                    value: selectedTime,
                    onChanged: (newValue) {
                      setState(() {
                        selectedTime = newValue;
                      });
                    },
                    items: availableTimes.map((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                  ),
                ],
                ElevatedButton(
                  onPressed: bookAppointment,
                  child: Text(
                    'Randevu Al',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
