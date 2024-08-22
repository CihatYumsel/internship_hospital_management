const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.updateAvailableDates = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const today = new Date();
  const oneMonthLater = new Date(today.getFullYear(), today.getMonth() + 1, today.getDate());
  const twoMonthsLater = new Date(today.getFullYear(), today.getMonth() + 2, today.getDate());

  // Tarih formatı
  const formatDate = (date) => {
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    return `${day}-${month}-${year}`;
  };

  // Haftasonları kontrol fonksiyonu
  const isWeekend = (date) => {
    const day = date.getDay();
    return day === 6 || day === 0; // Cumartesi (6) veya Pazar (0)
  };

  // Doktorlar koleksiyonunu alın
  const doctorsSnapshot = await admin.firestore().collection('doctors').get();

  for (const doctorDoc of doctorsSnapshot.docs) {
    const doctorId = doctorDoc.id;
    const availabilityRef = admin.firestore().collection('doctors').doc(doctorId).collection('availability');

    // Güncel tarihler ve 2 ay sonrası
    const validDates = [];
    for (let date = new Date(today); date <= twoMonthsLater; date.setDate(date.getDate() + 1)) {
      if (!isWeekend(date)) { // Haftasonlarını hariç tut
        validDates.push(formatDate(new Date(date)));
      }
    }

    // Mevcut tarihleri kontrol et
    const datesSnapshot = await availabilityRef.get();
    for (const dateDoc of datesSnapshot.docs) {
      const dateStr = dateDoc.id;
      if (!validDates.includes(dateStr)) {
        await dateDoc.ref.delete(); // Tarih uygun değilse sil
      } else {
        validDates.splice(validDates.indexOf(dateStr), 1); // Uygun tarihleri güncelle
      }
    }

    // Eksik tarihler ekle
    for (const dateStr of validDates) {
      const dateData = {
        availableTimes: Array.from({ length: 48 }, (_, i) => {
          const hour = Math.floor(i / 4) + 9;
          const minute = (i % 4) * 15;
          return `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
        }), // Her gün 09:00'dan 17:00'ye kadar 15 dakikalık aralıklarla saatler
      };
      await availabilityRef.doc(dateStr).set(dateData);
    }
  }
});
