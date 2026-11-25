import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/utils/validaciones.dart';

void main() {
  group('validarTitulo', () {
    test('rechaza cadena vacía', () {
      expect(validarTitulo(''), isNotNull);
    });

    test('rechaza títulos formados solo por espacios (P5)', () {
      expect(validarTitulo('    '), isNotNull);
      expect(validarTitulo(' \t \n '), isNotNull);
    });

    test('rechaza null', () {
      expect(validarTitulo(null), isNotNull);
    });

    test('rechaza títulos más largos que el máximo', () {
      expect(validarTitulo('a' * (kLongitudMaximaTitulo + 1)), isNotNull);
    });

    test('acepta un título normal y con espacios alrededor', () {
      expect(validarTitulo('Estudiar SQLite'), isNull);
      expect(validarTitulo('   Comprar pan   '), isNull);
    });
  });
}
