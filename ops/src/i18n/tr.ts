// Turkish (default). Every user-facing string lives here; components never
// hard-code copy. Keep keys flat + dotted for easy lookup.
const tr = {
  "app.title": "NOT IN PARIS",
  "app.subtitle": "Operasyon Sistemi",

  "lang.tr": "TR",
  "lang.en": "EN",

  "login.personal.title": "Kişisel giriş",
  "login.personal.hint": "Passkey (Face ID / parmak izi) ile",
  "login.personal.action": "Passkey ile gir",
  "login.pin.title": "Paylaşılan cihaz",
  "login.pin.hint": "Kim işlem yapıyor? PIN gir",
  "login.pin.placeholder": "PIN",
  "login.pin.action": "Gir",
  "login.pin.error": "PIN hatalı",
  "login.station.title": "İstasyon ekranı",
  "login.station.hint": "Tablet için paylaşımlı görünüm",
  "login.mock.note":
    "Demo modu: gerçek Passkey/PIN doğrulaması Supabase bağlanınca devreye girer.",

  "station.kitchen": "MUTFAK",
  "station.bar": "BAR",

  "nav.dashboard": "Pano",
  "nav.tasks": "Görevler",
  "nav.stock": "Stok",
  "nav.pos": "Satış",
  "nav.kds": "Mutfak",
  "nav.procurement": "Satın Alma",
  "nav.reports": "Raporlar",
  "nav.users": "Kullanıcılar",
  "nav.more": "Daha",

  "common.logout": "Çıkış",
  "common.comingSoon": "Bu modül sonraki fazda gelecek.",
  "common.phase": "Faz",
  "common.role": "Rol",

  "role.super_admin": "Süper Yönetici",
  "role.manager": "Yönetici",
  "role.operations": "Operasyon",
  "role.staff": "Personel",
  "role.station": "İstasyon",

  "screen.dashboard.title": "Pano",
  "screen.dashboard.body": "Günlük nabız, kritik stok ve özetler burada olacak.",
  "screen.tasks.title": "Görev Havuzu",
  "screen.tasks.body":
    "Görev oluştur, havuzdan üstlen ve kapat. Acil işaretleme ve alt-görev kilidi Faz 1'de.",
  "screen.stock.title": "Stok & Ürünler",
  "screen.stock.body": "Ürün kataloğu, stok hareketleri ve kritik stok uyarıları Faz 1'de.",
  "screen.pos.title": "Hızlı Satış",
  "screen.pos.body": "Hızlı POS, favoriler ve çoklu adisyon Faz 2'de.",
  "screen.kds.title": "Mutfak Ekranı",
  "screen.kds.body": "Gerçek zamanlı sipariş akışı (Yeni → Hazır) Faz 2'de.",
  "screen.procurement.title": "Satın Alma",
  "screen.procurement.body":
    "Tedarikçiler, satın alma siparişleri ve fatura OCR Faz 3'te.",
  "screen.reports.title": "Raporlar",
  "screen.reports.body": "Kâr marjı, bonus istatistikleri ve detaylı raporlar Faz 3–4'te.",
  "screen.users.title": "Kullanıcılar",
  "screen.users.body": "Kullanıcı ve rol yönetimi (yalnızca süper yönetici).",
  "screen.notFound.title": "Bulunamadı",
  "screen.notFound.body": "Bu sayfaya erişiminiz yok ya da sayfa mevcut değil."
};

export default tr;
export type TranslationKey = keyof typeof tr;
