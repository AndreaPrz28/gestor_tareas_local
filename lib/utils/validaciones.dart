/// Longitud máxima permitida para el título (coincide con la columna en SQLite).
const int kLongitudMaximaTitulo = 120;

/// Devuelve un mensaje de error si el título no es válido, o `null` si es válido.
///
/// Reglas:
/// - No puede estar vacío ni contener solo espacios.
/// - No puede superar [kLongitudMaximaTitulo] caracteres (ya sin espacios extremos).
String? validarTitulo(String? titulo) {
  final limpio = titulo?.trim() ?? '';
  if (limpio.isEmpty) {
    return 'El título no puede estar vacío.';
  }
  if (limpio.length > kLongitudMaximaTitulo) {
    return 'El título no puede tener más de $kLongitudMaximaTitulo caracteres.';
  }
  return null;
}

/// Excepción que lanza el repositorio cuando se intenta guardar un título inválido.
class TituloInvalidoException implements Exception {
  final String mensaje;
  const TituloInvalidoException(this.mensaje);

  @override
  String toString() => mensaje;
}
