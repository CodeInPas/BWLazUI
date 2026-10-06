unit bstypes;

{$mode objfpc}{$H+}

interface

type
  { TBsThemeColor: Palet warna semantik standar Bootstrap }
  TBsThemeColor = (
    btcPrimary,   // Biru
    btcSecondary, // Abu-abu
    btcSuccess,   // Hijau
    btcDanger,    // Merah
    btcWarning,   // Kuning
    btcInfo,      // Cyan
    btcLight,     // Terang / Putih
    btcDark,      // Gelap / Hitam
    btcLink,      // Warna teks tautan
    btcNone       // Tanpa warna (transparan)
  );

  { TBsStyle: Varian visual komponen (Solid, Outline, dll) }
  TBsStyle = (
    bssSolid,     // Fill warna penuh
    bssOutline,   // Hanya border dan teks berwarna
    bssSoft,      // Background transparan/pudar (varian modern)
    bssGhost      // Tanpa background dan border sampai di-hover
  );

  { TBsSize: Skala dimensi komponen }
  TBsSize = (
    bszSmall,     // sm
    bszDefault,   // md (default)
    bszLarge      // lg
  );

  { TBsControlState: Status interaktif kontrol UI }
  TBsControlState = (
    bcsNormal,    // Status standar
    bcsHover,     // Kursor berada di atas kontrol
    bcsActive,    // Sedang diklik / ditekan
    bcsDisabled,  // Dinonaktifkan (abu-abu, tidak interaktif)
    bcsFocused    // Sedang mendapat fokus keyboard (Ring outline)
  );

  { TBsPlacement: Posisi penempatan (untuk Tooltip, Popover, Offcanvas) }
  TBsPlacement = (
    bspTop,
    bspBottom,
    bspLeft,
    bspRight,
    bspCenter,
    bspAuto       // Kalkulasi posisi otomatis berdasarkan ruang
  );

  { TBsAlignment: Perataan konten atau teks }
  TBsAlignment = (
    bsaStart,     // Rata Kiri / Atas
    bsaCenter,    // Rata Tengah
    bsaEnd,       // Rata Kanan / Bawah
    bsaJustify    // Rata Kiri-Kanan
  );

  { TBsCornerType: Tipe radius sudut komponen }
  TBsCornerType = (
    bctSquare,    // Tanpa lengkungan (0px)
    bctSmall,     // Lengkungan kecil (border-radius-sm)
    bctNormal,    // Lengkungan standar (border-radius)
    bctLarge,     // Lengkungan besar (border-radius-lg)
    bctPill,      // Lengkungan penuh (Height / 2)
    bctCircle     // Bulat penuh (Width = Height, border-radius 50%)
  );

implementation

end.

