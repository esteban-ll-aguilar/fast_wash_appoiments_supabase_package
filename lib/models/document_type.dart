/// Tipos de documento de identificación ecuatoriano.
enum DocumentType {
  cedula,
  ruc;

  String get label => switch (this) {
    cedula => 'Cédula',
    ruc => 'RUC',
  };

  String get dbValue => name;

  static DocumentType fromDb(String? value) =>
    values.firstWhere((e) => e.dbValue == value, orElse: () => cedula);
}
