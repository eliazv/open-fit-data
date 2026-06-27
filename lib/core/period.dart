/// Intervalli temporali usati da Archivio/Trends/Export.
enum Period { today, d7, d30, d90, y1, all }

extension PeriodX on Period {
  String get label => switch (this) {
        Period.today => 'Oggi',
        Period.d7 => '7G',
        Period.d30 => '30G',
        Period.d90 => '90G',
        Period.y1 => '1A',
        Period.all => 'Tutto',
      };

  String get longLabel => switch (this) {
        Period.today => 'Oggi',
        Period.d7 => 'Ultimi 7 giorni',
        Period.d30 => 'Ultimo mese',
        Period.d90 => '90 giorni',
        Period.y1 => '1 anno',
        Period.all => 'Tutto',
      };

  String get menuLabel => switch (this) {
        Period.today => 'Oggi',
        Period.d7 => '7 giorni',
        Period.d30 => '30 giorni',
        Period.d90 => '90 giorni',
        Period.y1 => '1 anno',
        Period.all => 'Tutto',
      };

  /// Numero di giorni; null = tutto lo storico.
  int? get days => switch (this) {
        Period.today => 1,
        Period.d7 => 7,
        Period.d30 => 30,
        Period.d90 => 90,
        Period.y1 => 365,
        Period.all => null,
      };
}
