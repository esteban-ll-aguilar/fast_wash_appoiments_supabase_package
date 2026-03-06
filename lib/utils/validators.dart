/// Utilidades para validar cédulas ecuatorianas.
/// 
/// Implementa el algoritmo oficial de validación de cédulas de identidad de Ecuador.
class DniValidator {
  /// Valida que una cédula ecuatoriana sea correcta usando el algoritmo oficial.
  /// 
  /// El algoritmo verifica:
  /// 1. Que tenga exactamente 10 dígitos
  /// 2. Que el último dígito sea el dígito verificador correcto
  /// 
  /// Retorna true si la cédula es válida, false en caso contrario.
  static bool isValidEcuadorianDni(String dni) {
    // Verificar que tenga exactamente 10 dígitos
    if (dni.length != 10) {
      return false;
    }

    // Verificar que todos sean números
    if (!RegExp(r'^\d+$').hasMatch(dni)) {
      return false;
    }

    // Arrays para las posiciones impares (índices 0, 2, 4, 6, 8) y pares (índices 1, 3, 5, 7)
    List<int> oddPositions = []; // 5 elementos
    List<int> evenPositions = []; // 4 elementos

    // Separar los primeros 9 dígitos en posiciones impares y pares
    for (int i = 0; i < 9; i++) {
      if (i % 2 == 0) {
        // Posiciones impares (0, 2, 4, 6, 8)
        oddPositions.add(int.parse(dni[i]));
      } else {
        // Posiciones pares (1, 3, 5, 7)
        evenPositions.add(int.parse(dni[i]));
      }
    }

    // Calcular la suma
    int sum = 0;

    // Multiplicar posiciones impares por 2 y restar 9 si es mayor a 9
    for (int i = 0; i < oddPositions.length; i++) {
      int value = oddPositions[i] * 2;
      if (value > 9) {
        value = value - 9;
      }
      sum += value;
    }

    // Sumar las posiciones pares
    for (int i = 0; i < evenPositions.length; i++) {
      sum += evenPositions[i];
    }

    // Calcular el dígito verificador
    int modulo = sum % 10;
    int verifier = modulo == 0 ? 0 : 10 - modulo;

    // El último dígito de la cédula (dígito verificador)
    int lastDigit = int.parse(dni[9]);

    // Verificar si el dígito verificador coincide
    return verifier == lastDigit;
  }

  /// Valida el DNI para usar en formularios Flutter.
  /// 
  /// Retorna un mensaje de error si el DNI es inválido, o null si es válido.
  static String? validateDni(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La cédula es requerida';
    }

    final dni = value.trim();

    if (dni.length != 10) {
      return 'La cédula debe tener 10 dígitos';
    }

    if (!RegExp(r'^\d+$').hasMatch(dni)) {
      return 'La cédula solo debe contener números';
    }

    if (!isValidEcuadorianDni(dni)) {
      return 'Cédula ecuatoriana inválida';
    }

    return null;
  }

  /// Formatea un DNI agregando guiones para mejor legibilidad.
  /// 
  /// Ejemplo: "1234567890" -> "123-456-7890"
  static String formatDni(String dni) {
    if (dni.length != 10) return dni;
    return '${dni.substring(0, 3)}-${dni.substring(3, 6)}-${dni.substring(6)}';
  }

  /// Remueve el formato de un DNI, dejando solo los números.
  /// 
  /// Ejemplo: "123-456-7890" -> "1234567890"
  static String unformatDni(String dni) {
    return dni.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

/// Validadores generales para formularios del módulo de citas.
class AppointmentValidators {
  /// Valida que un campo no esté vacío.
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida que un número sea positivo.
  static String? positiveNumber(String? value, {String fieldName = 'El valor'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName debe ser un número válido';
    }

    if (number <= 0) {
      return '$fieldName debe ser mayor a 0';
    }

    return null;
  }

  /// Valida que una fecha no sea en el pasado.
  static String? futureDate(DateTime? value) {
    if (value == null) {
      return 'La fecha es requerida';
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDate = DateTime(value.year, value.month, value.day);

    if (selectedDate.isBefore(todayDate)) {
      return 'No puede seleccionar una fecha pasada';
    }

    return null;
  }

  /// Valida un email básico.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&"*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }

    return null;
  }
}
