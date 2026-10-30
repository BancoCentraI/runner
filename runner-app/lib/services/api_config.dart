import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Configuração única da API do app.
///
/// A URL base vem da variável `API_BASE_URL` do arquivo `.env`, por exemplo:
///   API_BASE_URL=https://api.seudominio.com.br/api
///
/// Todas as telas devem montar as URLs com `ApiConfig.uri('/caminho')`,
/// assim não ficam endereços diferentes espalhados pelo projeto.
class ApiConfig {
  ApiConfig._();

  /// URL base, sem barra no final. Vazia se não estiver configurada.
  static String get baseUrl {
    var url = (dotenv.env['API_BASE_URL'] ?? '').trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Falso se a variável estiver vazia ou ainda com um endereço de exemplo.
  static bool get configurada {
    final url = baseUrl.toLowerCase();
    return url.isNotEmpty &&
        !url.contains('sua-api') &&
        Uri.tryParse(url)?.hasAuthority == true;
  }

  /// Monta a URL completa sem barras duplicadas.
  /// `ApiConfig.uri('home-dados')` e `ApiConfig.uri('/home-dados')` dão o
  /// mesmo resultado. Lança [ApiNaoConfiguradaException] se `.env` estiver
  /// sem a URL real.
  static Uri uri(String caminho, {Map<String, String>? query}) {
    if (!configurada) throw const ApiNaoConfiguradaException();
    final c = caminho.startsWith('/') ? caminho : '/$caminho';
    final u = Uri.parse('$baseUrl$c');
    return query == null ? u : u.replace(queryParameters: query);
  }

  /// Mensagem clara para mostrar ao usuário a partir de um erro de rede.
  static String mensagemErro(Object erro) {
    if (erro is ApiNaoConfiguradaException) return erro.mensagem;
    if (erro is TimeoutException) {
      return 'O servidor demorou para responder. Tente novamente.';
    }
    if (erro is SocketException ||
        (erro is http.ClientException &&
            erro.message.toLowerCase().contains('host lookup'))) {
      return 'Não foi possível encontrar o servidor. '
          'Verifique sua internet ou o endereço da API.';
    }
    if (erro is http.ClientException) {
      return 'Não foi possível conectar ao servidor.';
    }
    return 'Erro inesperado ao falar com o servidor.';
  }

  /// Mensagem clara para respostas HTTP de erro.
  static String mensagemStatus(int status) {
    if (status == 401 || status == 403) {
      return 'Sua sessão expirou. Entre novamente.';
    }
    if (status == 404) return 'Endereço da API não encontrado (404).';
    if (status >= 500) return 'O servidor está com problemas ($status).';
    return 'Resposta inesperada do servidor ($status).';
  }
}

class ApiNaoConfiguradaException implements Exception {
  const ApiNaoConfiguradaException();

  String get mensagem => 'A URL da API não está configurada. '
      'Defina API_BASE_URL no arquivo .env.';

  @override
  String toString() => mensagem;
}
