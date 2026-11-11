import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guichetplus_agent/main.dart';

void main() {
  test('Guichet+ Agent application can be constructed', () {
    expect(const GuichetPlusAgentApp(), isA<Widget>());
  });
}
