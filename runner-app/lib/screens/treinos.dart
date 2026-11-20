import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/offline.dart';
import 'corrida.dart';
import 'emergencia.dart';
import 'painel.dart';
import 'rotas.dart';
import '../services/preferencia.dart';

// =============================================================================
// CORES (mesma paleta do app)
// =============================================================================

class _Cores {
  // Cores que são iguais nos dois temas
  static const tinta = Color(0xFF1A1A1A); // texto/ícone sobre verde-limão
  static const destaque = Color(0xFFD0FD38);
  static Color get escuro => // texto principal
      _modoEscuro ? const Color(0xFFF3F4F6) : const Color(0xFF1A1A1A);
  static Color get destaqueClaro =>
      _modoEscuro ? const Color(0xFF2E3A12) : const Color(0xFFEEF9C9);
  static Color get textoSecundario =>
      _modoEscuro ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  static Color get fundo =>
      _modoEscuro ? const Color(0xFF111311) : const Color(0xFFF6F7F4);
  static Color get borda =>
      _modoEscuro ? const Color(0xFF2C302A) : const Color(0xFFE5E7EB);
  static Color get segmento =>
      _modoEscuro ? const Color(0xFF252923) : const Color(0xFFE8EBE6);
  static Color get verde =>
      _modoEscuro ? const Color(0xFF9BC27A) : const Color(0xFF386641);
  static const vermelho = Color(0xFFEF4444);
  static Color get vermelhoFundo =>
      _modoEscuro ? const Color(0xFF2A1616) : const Color(0xFFFEF2F2);
  static Color get vermelhoBorda =>
      _modoEscuro ? const Color(0xFF5A2A2A) : const Color(0xFFFCA5A5);

  /// Cards e botões que são pretos no tema claro.
  static Color get superficie =>
      _modoEscuro ? const Color(0xFF262A23) : const Color(0xFF1A1A1A);

  /// Superfícies que são brancas no tema claro.
  static Color get card => _modoEscuro ? const Color(0xFF1C1F1B) : Colors.white;
}

/// Tema atual (claro/escuro), controlado nas Configurações.
bool get _modoEscuro => Preferencias.instancia.modoEscuro;

// =============================================================================
// AJUDANTES
// =============================================================================

double _toDouble(Object? v) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

double? _toDoubleOuNulo(Object? v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

int _toInt(Object? v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

String? _toStr(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

const _letrasDia = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
const _nomesDia = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];
const _meses = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

/// Distância conforme a preferência do usuário (km ou milhas).
String _distancia(double km, {bool comSigla = true}) {
  final milhas = Preferencias.instancia.unidade == UnidadeDistancia.milhas;
  final v = milhas ? km / 1.609344 : km;
  final t =
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  final n = t.replaceAll('.', ',');
  return comSigla ? '$n ${milhas ? 'mi' : 'km'}' : n;
}

// =============================================================================
// TREINOS PREDEFINIDOS (grátis, ficam no próprio app)
// =============================================================================
//
// Base: "Programa de Treinamento para Corredores — Nível 1 ao 5"
// (Iniciante 1–5 e Intermediário 1–5).

// ---------------------------------------------------------------------------
// Fases e níveis
// ---------------------------------------------------------------------------

enum _Fase {
  iniciante('Iniciante'),
  intermediario('Intermediário');

  const _Fase(this.rotulo);

  final String rotulo;
}

/// Os 10 níveis do programa. Cada um dura de 4 a 6 semanas.
enum _Nivel {
  iniciante1(
    _Fase.iniciante,
    1,
    frequencia: '3 dias/semana',
    tempo: '20–25 min',
    objetivo: 'Adaptação ao exercício',
    paraAvancar: 'completar os treinos sem desconforto excessivo.',
    semana: [
      'Caminhada',
      'Descanso',
      'Caminhada',
      'Descanso',
      'Caminhada',
      'Descanso',
      'Caminhada leve',
    ],
  ),
  iniciante2(
    _Fase.iniciante,
    2,
    frequencia: '3 dias/semana',
    tempo: '25–30 min',
    objetivo: 'Melhorar resistência',
    paraAvancar: 'alternar corrida e caminhada com controle.',
    semana: [
      'Corrida leve',
      'Descanso',
      'Corrida/caminhada',
      'Descanso',
      'Corrida leve',
      'Descanso',
      'Caminhada',
    ],
  ),
  iniciante3(
    _Fase.iniciante,
    3,
    frequencia: '3 dias/semana',
    tempo: '30–35 min',
    objetivo: 'Correr por mais tempo',
    paraAvancar: 'correr por períodos maiores sem parar.',
    semana: [
      'Corrida leve',
      'Força',
      'Corrida contínua',
      'Descanso',
      'Corrida leve',
      'Descanso',
      'Corrida leve',
    ],
  ),
  iniciante4(
    _Fase.iniciante,
    4,
    frequencia: '3–4 dias/semana',
    tempo: '35–40 min',
    objetivo: 'Desenvolver ritmo',
    paraAvancar: 'correr sem parar por cerca de 25 minutos.',
    semana: [
      'Corrida leve',
      'Força',
      'Corrida contínua',
      'Mobilidade',
      'Intervalos leves',
      'Descanso',
      'Corrida leve',
    ],
  ),
  iniciante5(
    _Fase.iniciante,
    5,
    frequencia: '4 dias/semana',
    tempo: '40–45 min',
    objetivo: 'Consolidar a corrida contínua',
    paraAvancar: 'correr sem parar por 30 minutos.',
    semana: [
      'Corrida contínua',
      'Força',
      'Ritmo moderado',
      'Descanso',
      'Intervalos',
      'Descanso',
      'Corrida longa leve',
    ],
  ),
  intermediario1(
    _Fase.intermediario,
    1,
    frequencia: '4 dias/semana',
    tempo: '40–50 min',
    objetivo: 'Aumentar volume',
    paraAvancar: 'manter regularidade nos intervalos.',
    semana: [
      'Corrida leve',
      'Intervalados',
      'Força',
      'Corrida moderada',
      'Descanso',
      'Corrida longa',
      'Descanso',
    ],
  ),
  intermediario2(
    _Fase.intermediario,
    2,
    frequencia: '4 dias/semana',
    tempo: '45–55 min',
    objetivo: 'Melhorar velocidade',
    paraAvancar: 'suportar um volume maior de treino.',
    semana: [
      'Corrida leve',
      'Intervalados',
      'Força',
      'Ritmo',
      'Descanso',
      'Corrida longa',
      'Recuperação',
    ],
  ),
  intermediario3(
    _Fase.intermediario,
    3,
    frequencia: '4 dias/semana',
    tempo: '50–60 min',
    objetivo: 'Trabalhar ritmo',
    paraAvancar: 'manter o ritmo controlado em sessões mais longas.',
    semana: [
      'Corrida leve',
      'Intervalados',
      'Força',
      'Ritmo',
      'Descanso',
      'Corrida longa',
      'Descanso',
    ],
  ),
  intermediario4(
    _Fase.intermediario,
    4,
    frequencia: '4–5 dias/semana',
    tempo: '55–70 min',
    objetivo: 'Melhorar resistência e potência',
    paraAvancar: 'ter boa resistência e recuperação entre os treinos.',
    semana: [
      'Corrida leve',
      'Intervalados',
      'Força',
      'Tempo run',
      'Mobilidade',
      'Corrida longa',
      'Recuperação',
    ],
  ),
  intermediario5(
    _Fase.intermediario,
    5,
    frequencia: '5 dias/semana',
    tempo: '60–80 min',
    objetivo: 'Preparação para provas de 5 km e 10 km',
    semana: [
      'Recuperação',
      'Intervalados',
      'Força',
      'Tempo run',
      'Descanso',
      'Corrida longa',
      'Descanso',
    ],
  );

  const _Nivel(
    this.fase,
    this.numero, {
    required this.frequencia,
    required this.tempo,
    required this.objetivo,
    required this.semana,
    this.paraAvancar,
  });

  final _Fase fase;
  final int numero;
  final String frequencia;
  final String tempo;
  final String objetivo;

  /// O que fazer em cada dia, de segunda a domingo (7 itens).
  final List<String> semana;

  /// Critério para passar ao próximo nível (null = último nível).
  final String? paraAvancar;

  /// Ex.: "Iniciante 3".
  String get rotulo => '${fase.rotulo} $numero';
}

// ---------------------------------------------------------------------------
// Tipos de treino
// ---------------------------------------------------------------------------

enum _Categoria {
  corrida('Corrida', Icons.directions_run_rounded,
      'Caminhada, rodagem, tiros e longões'),
  forca('Força', Icons.fitness_center_rounded, 'Pernas, glúteos e corpo todo'),
  core('Core', Icons.accessibility_new_rounded,
      'Abdômen, lombar e estabilidade'),
  tecnica(
      'Técnica', Icons.speed_rounded, 'Educativos de corrida e coordenação'),
  mobilidade('Mobilidade', Icons.self_improvement_rounded,
      'Aquecimento, alongamento e soltura');

  const _Categoria(this.rotulo, this.icone, this.descricao);

  final String rotulo;
  final IconData icone;
  final String descricao;
}
// ---------------------------------------------------------------------------
// Modelos
// ---------------------------------------------------------------------------

/// Etapa de um treino de corrida (texto + minutos).
class _Etapa {
  const _Etapa(this.texto, this.minutos);

  final String texto;
  final int minutos;
}

/// Um exercício com o passo a passo de como fazer.
class _Exercicio {
  const _Exercicio({
    required this.nome,
    required this.musculos,
    required this.passos,
    required this.dicas,
  });

  final String nome;
  final String musculos;
  final List<String> passos;
  final List<String> dicas;
}

/// Um exercício dentro de um treino: quantas séries e repetições (ou tempo).
class _Bloco {
  const _Bloco(
    this.exercicio, {
    this.series = 1,
    this.reps,
    this.segundos,
    this.porLado = false,
  });

  final _Exercicio exercicio;
  final int series;
  final int? reps;
  final int? segundos;
  final bool porLado;

  String get alvo {
    final base = reps != null ? '$reps reps' : '${segundos ?? 0} s';
    return porLado ? '$base por lado' : base;
  }

  String get prescricao => series > 1 ? '$series × $alvo' : alvo;

  /// Tempo estimado de uma série (3 s por repetição).
  int get segundosPorSerie =>
      (reps != null ? reps! * 3 : (segundos ?? 0)) * (porLado ? 2 : 1);
}

class _TreinoPredefinido {
  const _TreinoPredefinido({
    required this.titulo,
    required this.resumo,
    required this.icone,
    required this.categoria,
    required this.nivel,
    this.etapas = const [],
    this.blocos = const [],
    this.circuito = false,
    this.rodadas = 1,
    this.descansoSeg = 30,
    this.descansoRodadaSeg = 60,
    this.metaKm,
    this.recomendado = false,
  });

  final String titulo;
  final String resumo;
  final IconData icone;
  final _Categoria categoria;
  final _Nivel nivel;

  /// Só nos treinos de corrida.
  final List<_Etapa> etapas;
  final double? metaKm;

  /// Exercícios (força, HIIT, core, mobilidade).
  final List<_Bloco> blocos;

  /// true = faz um exercício de cada vez em sequência e repete [rodadas].
  /// false = faz todas as séries de um exercício antes de passar ao próximo.
  final bool circuito;
  final int rodadas;
  final int descansoSeg;
  final int descansoRodadaSeg;
  final bool recomendado;

  bool get ehCorrida => categoria == _Categoria.corrida;

  /// Duração estimada em minutos.
  int get minutos {
    if (ehCorrida) return etapas.fold<int>(0, (s, e) => s + e.minutos);
    var seg = 0;
    if (circuito) {
      final rodada = blocos.fold<int>(0, (s, b) => s + b.segundosPorSerie) +
          descansoSeg * math.max<int>(0, blocos.length - 1);
      seg =
          rodada * rodadas + descansoRodadaSeg * math.max<int>(0, rodadas - 1);
    } else {
      for (final b in blocos) {
        seg += (b.segundosPorSerie + descansoSeg) * b.series;
      }
    }
    return math.max<int>(1, (seg / 60).ceil());
  }

  String get comoFunciona {
    if (ehCorrida) return resumo;
    if (circuito) {
      return 'Faça os exercícios em sequência, com $descansoSeg s de pausa '
          'entre eles. Repita $rodadas ${rodadas == 1 ? 'rodada' : 'rodadas'}, '
          'descansando $descansoRodadaSeg s entre as rodadas.';
    }
    return 'Faça todas as séries de um exercício antes de passar para o '
        'próximo, descansando $descansoSeg s entre as séries.';
  }
}

// ---------------------------------------------------------------------------
// Biblioteca de exercícios
// ---------------------------------------------------------------------------

const _agachamento = _Exercicio(
  nome: 'Agachamento livre',
  musculos: 'Quadríceps, glúteos e posterior de coxa',
  passos: [
    'Fique em pé com os pés na largura dos ombros, pontas levemente para fora.',
    'Leve o quadril para trás e para baixo, como se fosse sentar numa cadeira.',
    'Desça até as coxas ficarem paralelas ao chão (ou até onde for confortável).',
    'Empurre o chão com os calcanhares para voltar à posição inicial.',
  ],
  dicas: [
    'Mantenha o peito aberto e as costas retas.',
    'Os joelhos acompanham a direção dos pés, sem cair para dentro.',
  ],
);

const _afundo = _Exercicio(
  nome: 'Afundo (avanço)',
  musculos: 'Quadríceps, glúteos e equilíbrio',
  passos: [
    'Em pé, dê um passo largo à frente com uma perna.',
    'Desça o quadril até os dois joelhos formarem cerca de 90°.',
    'O joelho de trás chega perto do chão, sem encostar.',
    'Empurre com o pé da frente para voltar e troque de perna.',
  ],
  dicas: [
    'Tronco reto e abdômen firme.',
    'O joelho da frente fica alinhado sobre o tornozelo.',
  ],
);

const _afundoLateral = _Exercicio(
  nome: 'Afundo lateral',
  musculos: 'Glúteos, adutores e quadríceps',
  passos: [
    'Em pé, com os pés juntos.',
    'Dê um passo largo para o lado e leve o quadril para trás, dobrando o '
        'joelho dessa perna.',
    'A outra perna fica esticada, com o pé inteiro no chão.',
    'Empurre o chão para voltar ao centro e troque de lado.',
  ],
  dicas: [
    'Peito aberto, sem curvar as costas.',
    'Desça só até sentir um alongamento confortável na perna esticada.',
  ],
);

const _bulgaro = _Exercicio(
  nome: 'Agachamento búlgaro',
  musculos: 'Quadríceps e glúteos (uma perna por vez)',
  passos: [
    'Fique de costas para um banco ou sofá, a um passo largo de distância.',
    'Apoie o peito do pé de trás no banco.',
    'Desça dobrando o joelho da frente até a coxa ficar quase paralela ao chão.',
    'Suba empurrando com o calcanhar da frente. Faça todas as repetições e '
        'troque de perna.',
  ],
  dicas: [
    'Use uma parede para se equilibrar, se precisar.',
    'Mantenha o joelho da frente alinhado com o pé.',
  ],
);

const _ponte = _Exercicio(
  nome: 'Ponte de glúteo',
  musculos: 'Glúteos, posterior de coxa e lombar',
  passos: [
    'Deite de barriga para cima, joelhos dobrados e pés no chão na largura '
        'do quadril.',
    'Deixe os braços ao lado do corpo, palmas para baixo.',
    'Contraia os glúteos e suba o quadril até formar uma linha reta dos '
        'ombros aos joelhos.',
    'Segure 1 segundo no alto e desça devagar.',
  ],
  dicas: [
    'Empurre o chão com os calcanhares.',
    'Não arqueie a lombar no topo: quem faz o movimento é o glúteo.',
  ],
);

const _panturrilha = _Exercicio(
  nome: 'Elevação de panturrilha',
  musculos: 'Panturrilhas e tornozelos',
  passos: [
    'Em pé, pés na largura do quadril, perto de uma parede para apoio.',
    'Suba na ponta dos pés o mais alto que conseguir.',
    'Segure 1 segundo no alto.',
    'Desça devagar até os calcanhares tocarem o chão.',
  ],
  dicas: [
    'Para dificultar, faça num degrau deixando o calcanhar descer além dele.',
    'Movimento controlado, sem quicar.',
  ],
);

const _stepUp = _Exercicio(
  nome: 'Subida no banco (step-up)',
  musculos: 'Quadríceps, glúteos e equilíbrio',
  passos: [
    'Fique de frente para um degrau ou banco firme.',
    'Apoie um pé inteiro em cima.',
    'Empurre com essa perna para subir até ficar em pé no banco.',
    'Desça controlando com a mesma perna e alterne.',
  ],
  dicas: [
    'Use um apoio estável, que não escorregue.',
    'Evite dar impulso com a perna que fica embaixo.',
  ],
);

const _agachamentoSalto = _Exercicio(
  nome: 'Agachamento com salto',
  musculos: 'Pernas, glúteos e potência',
  passos: [
    'Comece na posição de agachamento.',
    'Suba com força e salte, esticando o corpo.',
    'Aterrisse de forma suave, com os joelhos levemente dobrados.',
    'Emende direto no próximo agachamento.',
  ],
  dicas: [
    'Aterrisse primeiro na ponta dos pés e depois apoie o pé inteiro.',
    'Se sentir dor no joelho, troque pelo agachamento livre.',
  ],
);

const _flexao = _Exercicio(
  nome: 'Flexão de braço',
  musculos: 'Peito, ombros, tríceps e core',
  passos: [
    'Apoie as mãos no chão um pouco mais abertas que os ombros.',
    'Estique as pernas e apoie as pontas dos pés: o corpo forma uma linha reta.',
    'Dobre os cotovelos e desça o peito até perto do chão.',
    'Empurre o chão para voltar.',
  ],
  dicas: [
    'Abdômen e glúteos contraídos para o quadril não cair.',
    'Muito difícil? Apoie os joelhos no chão.',
  ],
);

const _flexaoInclinada = _Exercicio(
  nome: 'Flexão inclinada',
  musculos: 'Peito, ombros, tríceps e core',
  passos: [
    'Apoie as mãos na borda de uma mesa firme, banco ou parede.',
    'Afaste os pés para trás até o corpo ficar reto e inclinado.',
    'Dobre os cotovelos e leve o peito em direção ao apoio.',
    'Empurre para voltar.',
  ],
  dicas: [
    'Quanto mais baixo o apoio, mais difícil fica.',
    'Cotovelos a cerca de 45° do corpo, não totalmente abertos.',
  ],
);

const _superman = _Exercicio(
  nome: 'Superman',
  musculos: 'Lombar, glúteos e costas',
  passos: [
    'Deite de barriga para baixo com os braços esticados à frente.',
    'Contraia glúteos e costas e tire braços, peito e pernas do chão ao '
        'mesmo tempo.',
    'Segure 2 segundos no alto.',
    'Desça devagar.',
  ],
  dicas: [
    'Olhe para o chão para não forçar o pescoço.',
    'Suba só até onde não sentir desconforto na lombar.',
  ],
);

const _prancha = _Exercicio(
  nome: 'Prancha',
  musculos: 'Core (abdômen e lombar) e ombros',
  passos: [
    'Apoie os antebraços no chão, com os cotovelos abaixo dos ombros.',
    'Estique as pernas e apoie as pontas dos pés.',
    'Mantenha o corpo reto da cabeça aos calcanhares.',
    'Respire normalmente e segure pelo tempo indicado.',
  ],
  dicas: [
    'Não deixe o quadril cair nem subir demais.',
    'Contraia abdômen e glúteos.',
  ],
);

const _pranchaLateral = _Exercicio(
  nome: 'Prancha lateral',
  musculos: 'Oblíquos, core e glúteo médio',
  passos: [
    'Deite de lado e apoie o antebraço no chão, cotovelo abaixo do ombro.',
    'Pernas esticadas, um pé sobre o outro.',
    'Suba o quadril até o corpo formar uma linha reta.',
    'Segure pelo tempo indicado e troque de lado.',
  ],
  dicas: [
    'Muito difícil? Apoie o joelho de baixo no chão.',
    'Não deixe o quadril cair.',
  ],
);

const _deadBug = _Exercicio(
  nome: 'Dead bug',
  musculos: 'Core profundo e coordenação',
  passos: [
    'Deite de barriga para cima, braços esticados para o teto.',
    'Dobre quadril e joelhos a 90°, canelas paralelas ao chão.',
    'Estique devagar o braço direito para trás e a perna esquerda para '
        'frente, sem encostar no chão.',
    'Volte e repita com o lado oposto.',
  ],
  dicas: [
    'A lombar fica encostada no chão o tempo todo.',
    'Quanto mais devagar, melhor.',
  ],
);

const _birdDog = _Exercicio(
  nome: 'Perdigueiro (bird dog)',
  musculos: 'Core, lombar e glúteos',
  passos: [
    'Fique de quatro apoios: mãos abaixo dos ombros, joelhos abaixo do quadril.',
    'Estique o braço direito à frente e a perna esquerda para trás ao mesmo '
        'tempo.',
    'Segure 2 segundos, mantendo o quadril parado.',
    'Volte e troque de lado.',
  ],
  dicas: [
    'Imagine um copo de água nas costas: não deixe derramar.',
    'Olhe para o chão, com o pescoço alinhado.',
  ],
);

const _crunch = _Exercicio(
  nome: 'Abdominal (crunch)',
  musculos: 'Abdômen',
  passos: [
    'Deite de barriga para cima, joelhos dobrados e pés no chão.',
    'Coloque as mãos atrás da cabeça ou cruzadas no peito.',
    'Contraia o abdômen e tire os ombros do chão.',
    'Desça devagar, sem relaxar totalmente.',
  ],
  dicas: [
    'Não puxe a cabeça com as mãos.',
    'O movimento é curto: a lombar fica no chão.',
  ],
);

const _bicicleta = _Exercicio(
  nome: 'Abdominal bicicleta',
  musculos: 'Abdômen e oblíquos',
  passos: [
    'Deite de barriga para cima, mãos atrás da cabeça e ombros fora do chão.',
    'Tire os pés do chão com os joelhos dobrados.',
    'Leve o cotovelo direito em direção ao joelho esquerdo enquanto estica a '
        'perna direita.',
    'Troque de lado num movimento contínuo, como se pedalasse.',
  ],
  dicas: [
    'Gire o tronco, não só o cotovelo.',
    'Ritmo controlado vale mais que velocidade.',
  ],
);

const _escalador = _Exercicio(
  nome: 'Escalador (mountain climber)',
  musculos: 'Core, ombros e cardio',
  passos: [
    'Comece na posição de flexão, com os braços esticados.',
    'Leve um joelho em direção ao peito.',
    'Volte e leve o outro joelho, alternando rápido.',
    'Mantenha o quadril baixo e o ritmo constante.',
  ],
  dicas: [
    'Mãos firmes abaixo dos ombros.',
    'Iniciante? Faça mais devagar, sem saltar.',
  ],
);

const _skipping = _Exercicio(
  nome: 'Skipping alto (joelho alto)',
  musculos: 'Cardio, quadril e panturrilhas',
  passos: [
    'Corra parado no lugar.',
    'Eleve os joelhos até a altura do quadril, alternando.',
    'Movimente os braços como na corrida.',
    'Mantenha o tronco reto e o ritmo rápido.',
  ],
  dicas: [
    'Pise com a ponta dos pés.',
    'Mais leve: faça uma marcha com joelho alto, sem saltar.',
  ],
);

const _alongPosterior = _Exercicio(
  nome: 'Alongamento de posterior de coxa',
  musculos: 'Posterior de coxa e lombar',
  passos: [
    'Sente no chão com uma perna esticada e a outra dobrada, com a sola do '
        'pé encostada na parte interna da coxa.',
    'Com a coluna reta, incline o tronco à frente a partir do quadril.',
    'Leve as mãos em direção ao pé até sentir alongar atrás da coxa.',
    'Respire fundo e mantenha a posição.',
  ],
  dicas: [
    'Alongamento é tensão leve, nunca dor.',
    'Não force balançando o corpo.',
  ],
);

const _alongQuadriceps = _Exercicio(
  nome: 'Alongamento de quadríceps',
  musculos: 'Frente da coxa',
  passos: [
    'Em pé, apoie uma mão na parede.',
    'Dobre um joelho e segure o pé atrás com a mão do mesmo lado.',
    'Puxe o calcanhar em direção ao glúteo, mantendo os joelhos lado a lado.',
    'Mantenha e troque de perna.',
  ],
  dicas: [
    'Contraia o glúteo para alongar mais.',
    'Não arqueie a lombar.',
  ],
);

const _alongPanturrilha = _Exercicio(
  nome: 'Alongamento de panturrilha',
  musculos: 'Panturrilhas e tendão de Aquiles',
  passos: [
    'De frente para uma parede, apoie as mãos nela.',
    'Leve uma perna para trás, esticada, com o calcanhar no chão.',
    'Dobre o joelho da frente e incline o corpo em direção à parede.',
    'Mantenha e troque de lado.',
  ],
  dicas: [
    'A ponta do pé de trás aponta para a parede.',
    'Dobrar levemente o joelho de trás alonga a parte baixa da panturrilha.',
  ],
);

const _flexorQuadril = _Exercicio(
  nome: 'Alongamento do flexor do quadril',
  musculos: 'Frente do quadril',
  passos: [
    'Ajoelhe com uma perna à frente, pé no chão e joelho a 90°.',
    'O joelho de trás fica apoiado no chão (use uma toalha por baixo).',
    'Contraia o glúteo da perna de trás e leve o quadril levemente à frente.',
    'Sinta alongar na frente do quadril, mantenha e troque de lado.',
  ],
  dicas: [
    'Tronco reto, sem inclinar para trás.',
    'Ótimo para quem passa muito tempo sentado.',
  ],
);

const _figura4 = _Exercicio(
  nome: 'Alongamento de glúteo (figura 4)',
  musculos: 'Glúteos e quadril',
  passos: [
    'Deite de barriga para cima com os joelhos dobrados.',
    'Cruze o tornozelo direito sobre o joelho esquerdo.',
    'Segure atrás da coxa esquerda e puxe em direção ao peito.',
    'Sinta alongar o glúteo direito, mantenha e troque de lado.',
  ],
  dicas: [
    'Cabeça e ombros relaxados no chão.',
    'Empurre levemente o joelho de cima para fora para aumentar.',
  ],
);

const _crianca = _Exercicio(
  nome: 'Postura da criança',
  musculos: 'Lombar, ombros e quadril',
  passos: [
    'Ajoelhe e sente sobre os calcanhares.',
    'Incline o tronco à frente e estique os braços no chão.',
    'Apoie a testa no chão ou numa almofada.',
    'Respire fundo e relaxe as costas.',
  ],
  dicas: [
    'Afaste os joelhos se for mais confortável.',
    'Ótima para terminar o treino.',
  ],
);

const _gatoVaca = _Exercicio(
  nome: 'Gato-vaca',
  musculos: 'Mobilidade da coluna',
  passos: [
    'Fique de quatro apoios.',
    'Ao inspirar, afunde a barriga e olhe levemente para cima (vaca).',
    'Ao expirar, arredonde as costas e leve o queixo ao peito (gato).',
    'Alterne devagar, acompanhando a respiração.',
  ],
  dicas: [
    'Movimento lento e contínuo.',
    'Tente mexer a coluna inteira, de cima a baixo.',
  ],
);

const _rotacaoToracica = _Exercicio(
  nome: 'Rotação torácica',
  musculos: 'Mobilidade das costas e ombros',
  passos: [
    'Deite de lado com os joelhos dobrados à frente e os braços esticados, '
        'palmas juntas.',
    'Abra o braço de cima em arco até o outro lado, girando o peito para o '
        'teto.',
    'Acompanhe a mão com o olhar e mantenha os joelhos juntos no chão.',
    'Volte devagar. Faça as repetições e troque de lado.',
  ],
  dicas: [
    'Respire fundo ao abrir o braço.',
    'Não force além do confortável.',
  ],
);

const _circuloQuadril = _Exercicio(
  nome: 'Círculos de quadril',
  musculos: 'Mobilidade do quadril',
  passos: [
    'Em pé, mãos na cintura e pés na largura dos ombros.',
    'Faça círculos amplos com o quadril.',
    'Metade do tempo para um lado, metade para o outro.',
    'Mantenha os joelhos levemente dobrados.',
  ],
  dicas: [
    'Movimento suave, sem pressa.',
    'Ótimo aquecimento antes de correr.',
  ],
);

const _balancoPerna = _Exercicio(
  nome: 'Balanço de perna',
  musculos: 'Mobilidade do quadril e posterior',
  passos: [
    'Em pé, apoie uma mão numa parede.',
    'Balance a perna de fora para frente e para trás, de forma solta.',
    'Aumente a amplitude aos poucos.',
    'Faça as repetições e troque de perna.',
  ],
  dicas: [
    'Tronco parado: só a perna se move.',
    'Também dá para balançar para os lados, cruzando à frente do corpo.',
  ],
);

const _borboleta = _Exercicio(
  nome: 'Borboleta',
  musculos: 'Adutores (parte interna da coxa)',
  passos: [
    'Sente com as solas dos pés juntas e os joelhos abertos.',
    'Segure os pés com as mãos.',
    'Com a coluna reta, deixe os joelhos descerem em direção ao chão.',
    'Incline levemente o tronco à frente para alongar mais.',
  ],
  dicas: [
    'Não empurre os joelhos com força.',
    'Quanto mais perto do corpo estiverem os pés, mais intenso.',
  ],
);

const _marchaEstacionaria = _Exercicio(
  nome: 'Marcha estacionária',
  musculos: 'Aquecimento geral e coordenação',
  passos: [
    'Fique em pé, com o tronco reto e os braços soltos.',
    'Marche sem sair do lugar, levantando um joelho de cada vez.',
    'Movimente os braços como se estivesse caminhando.',
    'Aumente o ritmo aos poucos.',
  ],
  dicas: [
    'Pise de leve, sem bater o pé no chão.',
    'Respire de forma tranquila.',
  ],
);

const _rotacaoTornozelo = _Exercicio(
  nome: 'Rotação de tornozelos',
  musculos: 'Mobilidade dos tornozelos',
  passos: [
    'Em pé, apoie uma mão na parede.',
    'Tire um pé do chão, com o joelho levemente dobrado.',
    'Faça círculos com o pé, metade das voltas para cada sentido.',
    'Troque de pé.',
  ],
  dicas: [
    'Faça círculos grandes e lentos.',
    'Só o tornozelo se mexe; a perna fica parada.',
  ],
);

const _equilibrioUnilateral = _Exercicio(
  nome: 'Equilíbrio em uma perna',
  musculos: 'Tornozelo, quadril e estabilidade',
  passos: [
    'Fique em pé perto de uma parede, se precisar de apoio.',
    'Tire um pé do chão, dobrando o joelho à frente.',
    'Mantenha o corpo estável, olhando para um ponto fixo.',
    'Segure pelo tempo indicado e troque de perna.',
  ],
  dicas: [
    'Ficou fácil? Feche os olhos ou mexa os braços.',
    'O joelho de apoio fica levemente dobrado, não travado.',
  ],
);

const _afundoReverso = _Exercicio(
  nome: 'Afundo reverso',
  musculos: 'Quadríceps, glúteos e equilíbrio',
  passos: [
    'Em pé, com os pés na largura do quadril.',
    'Dê um passo largo para trás com uma perna.',
    'Desça até os dois joelhos formarem cerca de 90°.',
    'Empurre com o pé da frente para voltar e troque de perna.',
  ],
  dicas: [
    'Costuma pesar menos no joelho que o afundo para frente.',
    'Tronco reto e abdômen firme.',
  ],
);

const _ponteUnilateral = _Exercicio(
  nome: 'Ponte de glúteo unilateral',
  musculos: 'Glúteos e posterior de coxa (uma perna por vez)',
  passos: [
    'Deite de barriga para cima, joelhos dobrados e pés no chão.',
    'Estique uma perna para cima ou à frente.',
    'Empurre o chão com o pé de apoio e suba o quadril.',
    'Desça devagar. Faça as repetições e troque de perna.',
  ],
  dicas: [
    'O quadril sobe reto, sem pender para o lado da perna esticada.',
    'Faça primeiro a ponte normal até ficar fácil.',
  ],
);

const _panturrilhaUnilateral = _Exercicio(
  nome: 'Panturrilha unilateral',
  musculos: 'Panturrilha e tornozelo (uma perna por vez)',
  passos: [
    'Em pé, apoie as mãos numa parede.',
    'Tire um pé do chão e fique apoiado só na outra perna.',
    'Suba na ponta do pé o mais alto que conseguir.',
    'Desça devagar. Faça as repetições e troque de perna.',
  ],
  dicas: [
    'Descer devagar é a parte que mais fortalece.',
    'Ótimo para prevenir dores na canela e no tendão de Aquiles.',
  ],
);

const _abducaoQuadril = _Exercicio(
  nome: 'Abdução de quadril deitado',
  musculos: 'Glúteo médio (lateral do quadril)',
  passos: [
    'Deite de lado, com as pernas esticadas uma sobre a outra.',
    'Apoie a cabeça no braço de baixo.',
    'Suba a perna de cima sem girar o pé para o teto.',
    'Desça devagar. Faça as repetições e troque de lado.',
  ],
  dicas: [
    'O tronco não rola para trás.',
    'Esse músculo deixa o joelho mais estável na corrida.',
  ],
);

const _terraUnilateral = _Exercicio(
  nome: 'Levantamento terra unilateral',
  musculos: 'Posterior de coxa, glúteos e equilíbrio',
  passos: [
    'Fique em pé apoiado em uma perna, com o joelho levemente dobrado.',
    'Incline o tronco à frente enquanto leva a outra perna para trás.',
    'Desça até o tronco ficar quase paralelo ao chão.',
    'Volte contraindo o glúteo. Faça as repetições e troque de perna.',
  ],
  dicas: [
    'Costas retas do começo ao fim.',
    'Use uma parede para se equilibrar, se precisar.',
  ],
);

const _saltosPanturrilha = _Exercicio(
  nome: 'Saltos curtos de panturrilha',
  musculos: 'Panturrilhas, tornozelos e reatividade',
  passos: [
    'Em pé, com os pés juntos e os joelhos levemente dobrados.',
    'Dê pequenos saltos usando principalmente os tornozelos.',
    'Fique pouco tempo com o pé no chão entre um salto e outro.',
    'Mantenha um ritmo constante.',
  ],
  dicas: [
    'Saltos baixos e rápidos, como pular corda.',
    'Aterrisse na ponta dos pés, de forma suave.',
  ],
);

const _pranchaToque = _Exercicio(
  nome: 'Prancha com toque no ombro',
  musculos: 'Core, ombros e estabilidade',
  passos: [
    'Fique na posição de flexão, com os braços esticados.',
    'Afaste um pouco os pés para ganhar equilíbrio.',
    'Tire uma mão do chão e toque o ombro oposto.',
    'Volte a mão e alterne os lados.',
  ],
  dicas: [
    'O quadril não pode balançar de um lado para o outro.',
    'Mais leve: apoie os joelhos no chão.',
  ],
);

const _skippingBaixo = _Exercicio(
  nome: 'Skipping baixo',
  musculos: 'Técnica de passada e tornozelos',
  passos: [
    'Corra no lugar (ou avançando devagar por 15–30 m).',
    'Levante pouco os joelhos, com passos curtos e rápidos.',
    'Pise com a parte da frente do pé.',
    'Acompanhe com os braços, cotovelos dobrados.',
  ],
  dicas: [
    'Rapidez vale mais que altura.',
    'Tronco reto, olhando à frente.',
  ],
);

const _anfersen = _Exercicio(
  nome: 'Anfersen (calcanhar no glúteo)',
  musculos: 'Posterior de coxa e técnica de passada',
  passos: [
    'Corra no lugar (ou avançando devagar por 15–30 m).',
    'Leve os calcanhares em direção ao glúteo, alternando.',
    'Mantenha os joelhos apontando para o chão.',
    'Braços acompanham o movimento, como na corrida.',
  ],
  dicas: [
    'Ritmo rápido e leve.',
    'Não incline o tronco para frente.',
  ],
);

const _dribling = _Exercicio(
  nome: 'Dribling',
  musculos: 'Tornozelos, coordenação e frequência de passada',
  passos: [
    'Fique em pé, com os joelhos levemente dobrados.',
    'Dê passos muito curtos e rápidos, quase sem tirar os pés do chão.',
    'O calcanhar de cada pé toca o chão rapidamente.',
    'Avance devagar ou faça no lugar.',
  ],
  dicas: [
    'Pense em "pés rápidos", não em força.',
    'Ombros relaxados.',
  ],
);

// ---------------------------------------------------------------------------
// Treinos por nível
// ---------------------------------------------------------------------------
//
// "recomendado: true" marca o treino principal de cada nível.
// A duração (em minutos) é calculada sozinha: soma das etapas (corrida) ou
// séries + descansos (os outros tipos).

const _predefinidos = <_TreinoPredefinido>[
  // ============================ INICIANTE 1 ============================
  _TreinoPredefinido(
    titulo: 'Corre e caminha',
    resumo: '1 min correndo, 2 min caminhando',
    icone: Icons.directions_walk_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante1,
    recomendado: true,
    etapas: [
      _Etapa('Caminhada leve para aquecer', 4),
      _Etapa('6× (1 min correndo leve + 2 min caminhando)', 18),
      _Etapa('Caminhada para desacelerar', 3),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Caminhada contínua',
    resumo: '20 min em ritmo confortável',
    icone: Icons.directions_walk_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante1,
    etapas: [
      _Etapa('Caminhada leve para aquecer', 3),
      _Etapa('Caminhada em ritmo confortável, balançando os braços', 15),
      _Etapa('Caminhada bem leve para desacelerar', 2),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Aquecimento articular',
    resumo: 'Prepara o corpo antes de caminhar ou correr',
    icone: Icons.wb_sunny_outlined,
    categoria: _Categoria.mobilidade,
    nivel: _Nivel.iniciante1,
    descansoSeg: 5,
    blocos: [
      _Bloco(_marchaEstacionaria, segundos: 40),
      _Bloco(_rotacaoTornozelo, reps: 8, porLado: true),
      _Bloco(_circuloQuadril, segundos: 30),
      _Bloco(_balancoPerna, reps: 10, porLado: true),
      _Bloco(_gatoVaca, reps: 8),
    ],
  ),

  // ============================ INICIANTE 2 ============================
  _TreinoPredefinido(
    titulo: 'Corre e caminha 2:2',
    resumo: '2 min correndo, 2 min caminhando',
    icone: Icons.directions_walk_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante2,
    recomendado: true,
    etapas: [
      _Etapa('Caminhada leve para aquecer', 3),
      _Etapa('6× (2 min correndo leve + 2 min caminhando)', 24),
      _Etapa('Caminhada para desacelerar', 3),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Longão alternado',
    resumo: 'Corrida e caminhada no seu ritmo',
    icone: Icons.shuffle_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante2,
    etapas: [
      _Etapa('Caminhada leve para aquecer', 3),
      _Etapa('Alterne corrida leve e caminhada como se sentir bem', 20),
      _Etapa('Caminhada para desacelerar', 2),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Core essencial',
    resumo: 'Abdômen e lombar para correr melhor',
    icone: Icons.accessibility_new_rounded,
    categoria: _Categoria.core,
    nivel: _Nivel.iniciante2,
    circuito: true,
    rodadas: 2,
    descansoSeg: 20,
    descansoRodadaSeg: 45,
    blocos: [
      _Bloco(_deadBug, reps: 6, porLado: true),
      _Bloco(_birdDog, reps: 6, porLado: true),
      _Bloco(_prancha, segundos: 20),
      _Bloco(_ponte, reps: 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Alongamento pós-corrida',
    resumo: 'Para fazer depois de correr',
    icone: Icons.self_improvement_rounded,
    categoria: _Categoria.mobilidade,
    nivel: _Nivel.iniciante2,
    descansoSeg: 5,
    blocos: [
      _Bloco(_alongPosterior, segundos: 30, porLado: true),
      _Bloco(_alongQuadriceps, segundos: 30, porLado: true),
      _Bloco(_alongPanturrilha, segundos: 30, porLado: true),
      _Bloco(_crianca, segundos: 45),
    ],
  ),

  // ============================ INICIANTE 3 ============================
  _TreinoPredefinido(
    titulo: '4× 5 minutos',
    resumo: '5 min correndo, 2 min caminhando',
    icone: Icons.monitor_heart_outlined,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante3,
    recomendado: true,
    etapas: [
      _Etapa('Caminhada rápida para aquecer', 3),
      _Etapa('4× (5 min correndo leve + 2 min caminhando)', 28),
      _Etapa('Caminhada para desacelerar', 3),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Corrida leve 30',
    resumo: '30 min leve',
    icone: Icons.directions_run_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante3,
    etapas: [
      _Etapa('Caminhada rápida para aquecer', 3),
      _Etapa(
          'Corrida leve, num ritmo em que dá para conversar — caminhe '
          'se precisar',
          24),
      _Etapa('Caminhada para desacelerar', 3),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Primeira força',
    resumo: 'Corpo todo, sem equipamento',
    icone: Icons.fitness_center_rounded,
    categoria: _Categoria.forca,
    nivel: _Nivel.iniciante3,
    descansoSeg: 45,
    blocos: [
      _Bloco(_agachamento, series: 2, reps: 10),
      _Bloco(_ponte, series: 2, reps: 12),
      _Bloco(_panturrilha, series: 2, reps: 12),
      _Bloco(_flexaoInclinada, series: 2, reps: 8),
      _Bloco(_prancha, series: 2, segundos: 20),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Core e equilíbrio',
    resumo: 'Estabilidade para cada passada',
    icone: Icons.accessibility_new_rounded,
    categoria: _Categoria.core,
    nivel: _Nivel.iniciante3,
    circuito: true,
    rodadas: 2,
    descansoSeg: 20,
    descansoRodadaSeg: 45,
    blocos: [
      _Bloco(_birdDog, reps: 8, porLado: true),
      _Bloco(_crunch, reps: 12),
      _Bloco(_pranchaLateral, segundos: 15, porLado: true),
      _Bloco(_equilibrioUnilateral, segundos: 20, porLado: true),
    ],
  ),

  // ============================ INICIANTE 4 ============================
  _TreinoPredefinido(
    titulo: '3× 10 minutos',
    resumo: '10 min correndo, 2 min caminhando',
    icone: Icons.monitor_heart_outlined,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante4,
    recomendado: true,
    etapas: [
      _Etapa('Caminhada rápida para aquecer', 2),
      _Etapa('3× (10 min correndo + 2 min caminhando)', 36),
      _Etapa('Caminhada para desacelerar', 2),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Corrida leve 35',
    resumo: '35 min leve',
    icone: Icons.directions_run_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante4,
    etapas: [
      _Etapa('Caminhada rápida para aquecer', 3),
      _Etapa('Corrida leve e contínua; caminhe 1 min se precisar', 29),
      _Etapa('Caminhada para desacelerar', 3),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Intervalos leves',
    resumo: '1 min mais rápido, 2 min leve',
    icone: Icons.bolt_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante4,
    etapas: [
      _Etapa('Corrida bem leve para aquecer', 10),
      _Etapa('6× (1 min um pouco mais rápido + 2 min leve)', 18),
      _Etapa('Caminhada para desacelerar', 7),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Pernas de corredor',
    resumo: 'Pernas mais fortes e estáveis',
    icone: Icons.fitness_center_rounded,
    categoria: _Categoria.forca,
    nivel: _Nivel.iniciante4,
    descansoSeg: 45,
    blocos: [
      _Bloco(_agachamento, series: 3, reps: 12),
      _Bloco(_afundo, series: 2, reps: 8, porLado: true),
      _Bloco(_stepUp, series: 2, reps: 8, porLado: true),
      _Bloco(_panturrilha, series: 3, reps: 15),
      _Bloco(_ponte, series: 3, reps: 12),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Educativos básicos',
    resumo: 'Postura e passada mais leves',
    icone: Icons.speed_rounded,
    categoria: _Categoria.tecnica,
    nivel: _Nivel.iniciante4,
    circuito: true,
    rodadas: 2,
    descansoSeg: 30,
    descansoRodadaSeg: 60,
    blocos: [
      _Bloco(_skippingBaixo, segundos: 20),
      _Bloco(_anfersen, segundos: 20),
      _Bloco(_dribling, segundos: 20),
      _Bloco(_skipping, segundos: 20),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Mobilidade para corredores',
    resumo: 'Quadril, tornozelo e costas soltos',
    icone: Icons.self_improvement_rounded,
    categoria: _Categoria.mobilidade,
    nivel: _Nivel.iniciante4,
    descansoSeg: 5,
    blocos: [
      _Bloco(_balancoPerna, reps: 10, porLado: true),
      _Bloco(_circuloQuadril, segundos: 30),
      _Bloco(_flexorQuadril, segundos: 30, porLado: true),
      _Bloco(_figura4, segundos: 30, porLado: true),
      _Bloco(_rotacaoToracica, reps: 6, porLado: true),
    ],
  ),

  // ============================ INICIANTE 5 ============================
  _TreinoPredefinido(
    titulo: 'Corrida contínua 30',
    resumo: '30 min sem parar',
    icone: Icons.track_changes_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante5,
    recomendado: true,
    etapas: [
      _Etapa('Caminhada rápida para aquecer', 5),
      _Etapa('Corrida leve contínua, sem parar para caminhar', 30),
      _Etapa('Caminhada para desacelerar', 5),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Corrida longa leve',
    resumo: '40 min leve',
    icone: Icons.directions_run_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante5,
    etapas: [
      _Etapa('Caminhada rápida para aquecer', 3),
      _Etapa('Corrida leve e contínua, sem se preocupar com o ritmo', 37),
      _Etapa('Caminhada para desacelerar', 5),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Intervalos 1:1',
    resumo: '1 min forte, 1 min leve',
    icone: Icons.bolt_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante5,
    etapas: [
      _Etapa('Trote leve para aquecer', 10),
      _Etapa('10× (1 min forte + 1 min trote leve)', 20),
      _Etapa('Trote bem leve para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Ritmo moderado',
    resumo: 'Dá para falar frases curtas',
    icone: Icons.trending_up_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.iniciante5,
    etapas: [
      _Etapa('Trote leve para aquecer', 10),
      _Etapa('Corrida em ritmo moderado — dá para falar frases curtas', 20),
      _Etapa('Trote leve e caminhada para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Força de base',
    resumo: 'Corpo todo, mais completo',
    icone: Icons.fitness_center_rounded,
    categoria: _Categoria.forca,
    nivel: _Nivel.iniciante5,
    descansoSeg: 45,
    blocos: [
      _Bloco(_agachamento, series: 3, reps: 12),
      _Bloco(_afundoReverso, series: 3, reps: 8, porLado: true),
      _Bloco(_ponteUnilateral, series: 2, reps: 8, porLado: true),
      _Bloco(_panturrilha, series: 3, reps: 15),
      _Bloco(_flexaoInclinada, series: 3, reps: 10),
      _Bloco(_pranchaLateral, series: 2, segundos: 20, porLado: true),
    ],
  ),

  // ========================== INTERMEDIÁRIO 1 ==========================
  _TreinoPredefinido(
    titulo: 'Intervalado 5× 2 min',
    resumo: '2 min rápido, 2 min leve',
    icone: Icons.bolt_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario1,
    recomendado: true,
    etapas: [
      _Etapa('Trote leve para aquecer', 10),
      _Etapa('5× (2 min rápido + 2 min leve)', 20),
      _Etapa('Trote bem leve para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Corrida longa 45',
    resumo: '45 min leve',
    icone: Icons.directions_run_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario1,
    etapas: [
      _Etapa('Trote leve para aquecer', 5),
      _Etapa('Corrida leve e contínua', 35),
      _Etapa('Trote bem leve e caminhada', 5),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Corrida moderada',
    resumo: 'Ritmo constante',
    icone: Icons.trending_up_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario1,
    etapas: [
      _Etapa('Trote leve para aquecer', 10),
      _Etapa('Corrida em ritmo moderado e constante', 25),
      _Etapa('Trote leve para desacelerar', 5),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Força para correr',
    resumo: 'Pernas e core mais resistentes',
    icone: Icons.fitness_center_rounded,
    categoria: _Categoria.forca,
    nivel: _Nivel.intermediario1,
    descansoSeg: 60,
    blocos: [
      _Bloco(_agachamento, series: 3, reps: 15),
      _Bloco(_afundo, series: 3, reps: 10, porLado: true),
      _Bloco(_ponteUnilateral, series: 3, reps: 10, porLado: true),
      _Bloco(_panturrilhaUnilateral, series: 3, reps: 12, porLado: true),
      _Bloco(_prancha, series: 3, segundos: 30),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Educativos de corrida',
    resumo: 'Coordenação e frequência de passada',
    icone: Icons.speed_rounded,
    categoria: _Categoria.tecnica,
    nivel: _Nivel.intermediario1,
    circuito: true,
    rodadas: 3,
    descansoSeg: 30,
    descansoRodadaSeg: 60,
    blocos: [
      _Bloco(_skippingBaixo, segundos: 20),
      _Bloco(_skipping, segundos: 20),
      _Bloco(_anfersen, segundos: 20),
      _Bloco(_dribling, segundos: 20),
    ],
  ),

  // ========================== INTERMEDIÁRIO 2 ==========================
  _TreinoPredefinido(
    titulo: 'Intervalado 6× 2 min',
    resumo: '2 min rápido, 2 min leve',
    icone: Icons.bolt_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario2,
    recomendado: true,
    etapas: [
      _Etapa('Trote leve para aquecer', 12),
      _Etapa('6× (2 min rápido + 2 min leve)', 24),
      _Etapa('Trote bem leve para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Corrida longa 50',
    resumo: '50 min leve',
    icone: Icons.directions_run_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario2,
    etapas: [
      _Etapa('Trote leve para aquecer', 5),
      _Etapa('Corrida leve e contínua', 40),
      _Etapa('Trote bem leve e caminhada', 5),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Treino de ritmo',
    resumo: 'Moderadamente forte e constante',
    icone: Icons.trending_up_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario2,
    etapas: [
      _Etapa('Trote leve para aquecer', 10),
      _Etapa('Corrida em ritmo moderadamente forte e constante', 25),
      _Etapa('Trote leve para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Corrida regenerativa',
    resumo: 'Bem leve, para recuperar',
    icone: Icons.spa_outlined,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario2,
    etapas: [
      _Etapa('Caminhada para aquecer', 5),
      _Etapa('Trote muito leve, bem abaixo do seu ritmo normal', 20),
      _Etapa('Caminhada para desacelerar', 5),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Força unilateral',
    resumo: 'Uma perna por vez, mais equilíbrio',
    icone: Icons.fitness_center_rounded,
    categoria: _Categoria.forca,
    nivel: _Nivel.intermediario2,
    descansoSeg: 60,
    blocos: [
      _Bloco(_bulgaro, series: 3, reps: 8, porLado: true),
      _Bloco(_terraUnilateral, series: 3, reps: 8, porLado: true),
      _Bloco(_stepUp, series: 3, reps: 10, porLado: true),
      _Bloco(_abducaoQuadril, series: 3, reps: 12, porLado: true),
      _Bloco(_pranchaLateral, series: 3, segundos: 30, porLado: true),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Core resistente',
    resumo: 'Tronco firme até o fim da corrida',
    icone: Icons.accessibility_new_rounded,
    categoria: _Categoria.core,
    nivel: _Nivel.intermediario2,
    circuito: true,
    rodadas: 3,
    descansoSeg: 15,
    descansoRodadaSeg: 45,
    blocos: [
      _Bloco(_prancha, segundos: 40),
      _Bloco(_bicicleta, reps: 20),
      _Bloco(_deadBug, reps: 8, porLado: true),
      _Bloco(_superman, reps: 12),
    ],
  ),

  // ========================== INTERMEDIÁRIO 3 ==========================
  _TreinoPredefinido(
    titulo: 'Intervalado 5× 3 min',
    resumo: '3 min rápido, 2 min leve',
    icone: Icons.bolt_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario3,
    recomendado: true,
    etapas: [
      _Etapa('Trote leve para aquecer', 15),
      _Etapa('5× (3 min rápido + 2 min leve)', 25),
      _Etapa('Trote bem leve para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Corrida longa 55',
    resumo: '55 min leve',
    icone: Icons.directions_run_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario3,
    etapas: [
      _Etapa('Trote leve para aquecer', 5),
      _Etapa('Corrida leve e contínua', 45),
      _Etapa('Trote bem leve e caminhada', 5),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Ritmo sustentado',
    resumo: 'Moderadamente forte por mais tempo',
    icone: Icons.trending_up_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario3,
    etapas: [
      _Etapa('Trote leve para aquecer', 15),
      _Etapa('Corrida em ritmo moderadamente forte', 25),
      _Etapa('Trote leve para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Força total',
    resumo: 'Corpo todo, mais intenso',
    icone: Icons.fitness_center_rounded,
    categoria: _Categoria.forca,
    nivel: _Nivel.intermediario3,
    descansoSeg: 60,
    blocos: [
      _Bloco(_flexao, series: 3, reps: 10),
      _Bloco(_bulgaro, series: 3, reps: 10, porLado: true),
      _Bloco(_afundoLateral, series: 3, reps: 10, porLado: true),
      _Bloco(_terraUnilateral, series: 3, reps: 10, porLado: true),
      _Bloco(_superman, series: 3, reps: 12),
      _Bloco(_pranchaLateral, series: 2, segundos: 30, porLado: true),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Técnica e agilidade',
    resumo: 'Passada rápida e reativa',
    icone: Icons.speed_rounded,
    categoria: _Categoria.tecnica,
    nivel: _Nivel.intermediario3,
    circuito: true,
    rodadas: 3,
    descansoSeg: 30,
    descansoRodadaSeg: 60,
    blocos: [
      _Bloco(_skipping, segundos: 25),
      _Bloco(_anfersen, segundos: 25),
      _Bloco(_saltosPanturrilha, segundos: 20),
      _Bloco(_dribling, segundos: 25),
    ],
  ),

  // ========================== INTERMEDIÁRIO 4 ==========================
  _TreinoPredefinido(
    titulo: 'Tiros de 5 min',
    resumo: '4× 5 min em ritmo forte controlado',
    icone: Icons.bolt_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario4,
    recomendado: true,
    etapas: [
      _Etapa('Trote leve para aquecer', 15),
      _Etapa('4× (5 min forte controlado + 2 min leve)', 28),
      _Etapa('Trote bem leve para desacelerar', 12),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Corrida longa 65',
    resumo: '65 min leve',
    icone: Icons.directions_run_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario4,
    etapas: [
      _Etapa('Trote leve para aquecer', 5),
      _Etapa('Corrida leve e contínua', 55),
      _Etapa('Trote bem leve e caminhada', 5),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Tempo run',
    resumo: 'Forte e constante',
    icone: Icons.timer_outlined,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario4,
    etapas: [
      _Etapa('Trote leve para aquecer', 15),
      _Etapa('Corrida contínua em ritmo forte controlado', 30),
      _Etapa('Trote leve para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Recuperação ativa',
    resumo: 'Trote e caminhada, sem pressa',
    icone: Icons.spa_outlined,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario4,
    etapas: [
      _Etapa('Caminhada rápida para aquecer', 5),
      _Etapa('Alterne 3 min de trote leve e 1 min de caminhada rápida', 24),
      _Etapa('Caminhada para desacelerar', 5),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Potência de pernas',
    resumo: 'Força para subidas e sprints',
    icone: Icons.fitness_center_rounded,
    categoria: _Categoria.forca,
    nivel: _Nivel.intermediario4,
    descansoSeg: 60,
    blocos: [
      _Bloco(_agachamentoSalto, series: 3, reps: 10),
      _Bloco(_bulgaro, series: 3, reps: 10, porLado: true),
      _Bloco(_afundoLateral, series: 3, reps: 10, porLado: true),
      _Bloco(_ponteUnilateral, series: 3, reps: 12, porLado: true),
      _Bloco(_saltosPanturrilha, series: 3, segundos: 20),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Mobilidade completa',
    resumo: 'Soltura para a semana mais pesada',
    icone: Icons.self_improvement_rounded,
    categoria: _Categoria.mobilidade,
    nivel: _Nivel.intermediario4,
    descansoSeg: 5,
    blocos: [
      _Bloco(_balancoPerna, reps: 15, porLado: true),
      _Bloco(_circuloQuadril, segundos: 40),
      _Bloco(_flexorQuadril, segundos: 45, porLado: true),
      _Bloco(_borboleta, segundos: 45),
      _Bloco(_figura4, segundos: 45, porLado: true),
      _Bloco(_alongPanturrilha, segundos: 45, porLado: true),
      _Bloco(_rotacaoToracica, reps: 8, porLado: true),
    ],
  ),

  // ========================== INTERMEDIÁRIO 5 ==========================
  _TreinoPredefinido(
    titulo: 'Tiros de 5 min',
    resumo: '5× 5 min em ritmo forte controlado',
    icone: Icons.bolt_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario5,
    recomendado: true,
    etapas: [
      _Etapa('Trote leve para aquecer', 15),
      _Etapa('5× (5 min forte controlado + 2 min leve)', 35),
      _Etapa('Trote bem leve para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Corrida longa 75',
    resumo: '75 min leve',
    icone: Icons.directions_run_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario5,
    etapas: [
      _Etapa('Trote leve para aquecer', 5),
      _Etapa('Corrida leve e contínua', 65),
      _Etapa('Trote bem leve e caminhada', 5),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Tempo run longo',
    resumo: 'Forte e constante por mais tempo',
    icone: Icons.timer_outlined,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario5,
    etapas: [
      _Etapa('Trote leve para aquecer', 15),
      _Etapa('Corrida contínua em ritmo forte controlado', 35),
      _Etapa('Trote leve para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Simulado de 5 km',
    resumo: 'Ritmo regular do início ao fim',
    icone: Icons.track_changes_rounded,
    categoria: _Categoria.corrida,
    nivel: _Nivel.intermediario5,
    metaKm: 5,
    etapas: [
      _Etapa('Trote leve e 3 acelerações curtas para aquecer', 15),
      _Etapa(
          '5 km no ritmo planejado para a prova, sem largar rápido demais', 30),
      _Etapa('Trote leve para desacelerar', 10),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Força de prova',
    resumo: 'Potência e estabilidade',
    icone: Icons.fitness_center_rounded,
    categoria: _Categoria.forca,
    nivel: _Nivel.intermediario5,
    descansoSeg: 60,
    blocos: [
      _Bloco(_agachamentoSalto, series: 4, reps: 10),
      _Bloco(_bulgaro, series: 4, reps: 10, porLado: true),
      _Bloco(_terraUnilateral, series: 3, reps: 10, porLado: true),
      _Bloco(_panturrilhaUnilateral, series: 3, reps: 15, porLado: true),
      _Bloco(_pranchaToque, series: 3, reps: 20),
      _Bloco(_pranchaLateral, series: 3, segundos: 40, porLado: true),
    ],
  ),
  _TreinoPredefinido(
    titulo: 'Core de atleta',
    resumo: 'Tronco forte para o ritmo de prova',
    icone: Icons.accessibility_new_rounded,
    categoria: _Categoria.core,
    nivel: _Nivel.intermediario5,
    circuito: true,
    rodadas: 3,
    descansoSeg: 15,
    descansoRodadaSeg: 45,
    blocos: [
      _Bloco(_prancha, segundos: 45),
      _Bloco(_pranchaToque, reps: 20),
      _Bloco(_bicicleta, reps: 20),
      _Bloco(_escalador, segundos: 30),
      _Bloco(_pranchaLateral, segundos: 30, porLado: true),
    ],
  ),
];

// =============================================================================
// MODELOS DA API
// =============================================================================

class PlanoSemanal {
  const PlanoSemanal({
    this.titulo,
    required this.semanaAtual,
    required this.totalSemanas,
    required this.metaKm,
    required this.kmFeitos,
  });

  final String? titulo;
  final int semanaAtual;
  final int totalSemanas;
  final double metaKm;
  final double kmFeitos;

  double get progresso => metaKm > 0 ? (kmFeitos / metaKm).clamp(0.0, 1.0) : 0;
  double get faltam => math.max(0, metaKm - kmFeitos);

  factory PlanoSemanal.fromJson(Map<String, dynamic> j) => PlanoSemanal(
        titulo: _toStr(j['titulo']),
        semanaAtual: _toInt(j['semanaAtual']),
        totalSemanas: _toInt(j['totalSemanas']),
        metaKm: _toDouble(j['metaKm']),
        kmFeitos: _toDouble(j['kmFeitos']),
      );
}

class TreinoAgendado {
  const TreinoAgendado({
    required this.data,
    required this.titulo,
    this.tipo,
    this.resumo,
    this.distanciaKm,
    this.concluido = false,
  });

  final DateTime data;
  final String titulo;
  final String? tipo;
  final String? resumo;
  final double? distanciaKm;
  final bool concluido;

  static TreinoAgendado? fromJson(Map<String, dynamic> j) {
    final data = DateTime.tryParse('${j['data']}');
    final titulo = _toStr(j['titulo']);
    if (data == null || titulo == null) return null;
    return TreinoAgendado(
      data: data.toLocal(),
      titulo: titulo,
      tipo: _toStr(j['tipo']),
      resumo: _toStr(j['resumo']),
      distanciaKm: _toDoubleOuNulo(j['distanciaKm']),
      concluido: j['concluido'] == true,
    );
  }
}

class TreinosData {
  const TreinosData({this.plano, this.agenda = const []});

  final PlanoSemanal? plano;
  final List<TreinoAgendado> agenda;

  factory TreinosData.fromJson(Map<String, dynamic> j) {
    final p = j['plano'];
    return TreinosData(
      plano: p is Map<String, dynamic> ? PlanoSemanal.fromJson(p) : null,
      agenda: j['agenda'] is List
          ? (j['agenda'] as List)
              .whereType<Map<String, dynamic>>()
              .map(TreinoAgendado.fromJson)
              .whereType<TreinoAgendado>()
              .toList()
          : const [],
    );
  }
}

class _TreinosApi {
  /// GET /treinos com cache: sem internet, usa o último plano salvo no
  /// aparelho. Só devolve erro se não houver nada para mostrar.
  static Future<(TreinosData?, String?)> buscar() async {
    final r = await ApiOffline.buscar('/treinos', cache: 'treinos');
    final corpo = r.mapa;
    if (corpo == null) {
      return (null, r.erro ?? 'Resposta inválida do servidor.');
    }
    return (_somarPendentes(TreinosData.fromJson(corpo)), null);
  }

  /// Corridas desta semana ainda na fila já contam no progresso do plano.
  static TreinosData _somarPendentes(TreinosData d) {
    final p = d.plano;
    if (p == null) return d;
    final hoje = DateTime.now();
    final segunda =
        DateTime(hoje.year, hoje.month, hoje.day - (hoje.weekday - 1));
    var km = 0.0;
    for (final c in ApiOffline.corridasPendentes()) {
      final data =
          DateTime.tryParse('${c['iniciadoEm'] ?? c['finalizadoEm'] ?? ''}')
              ?.toLocal();
      if (data == null || data.isBefore(segunda)) continue;
      km += _toDouble(c['distanciaKm']);
    }
    if (km == 0) return d;
    return TreinosData(
      agenda: d.agenda,
      plano: PlanoSemanal(
        titulo: p.titulo,
        semanaAtual: p.semanaAtual,
        totalSemanas: p.totalSemanas,
        metaKm: p.metaKm,
        kmFeitos: p.kmFeitos + km,
      ),
    );
  }
}

// =============================================================================
// TELA
// =============================================================================

class TreinosScreen extends StatefulWidget {
  const TreinosScreen({super.key});

  @override
  State<TreinosScreen> createState() => _TreinosScreenState();
}

class _TreinosScreenState extends State<TreinosScreen> {
  bool _carregando = true;
  String? _erro;
  TreinosData _dados = const TreinosData();
  DateTime _diaSelecionado = _soData(DateTime.now());

  /// Nível escolhido nos treinos predefinidos (Iniciante 1 … Intermediário 5).
  _Nivel _nivel = _Nivel.iniciante1;

  /// Tipo escolhido no botão "Tipo de treino" (null = todos os tipos).
  _Categoria? _categoria;

  @override
  void initState() {
    super.initState();
    Preferencias.instancia.addListener(_atualizar);
    Sincronizador.instancia.enviados.addListener(_carregar);
    _carregar();
  }

  @override
  void dispose() {
    Preferencias.instancia.removeListener(_atualizar);
    Sincronizador.instancia.enviados.removeListener(_carregar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final (dados, erro) = await _TreinosApi.buscar();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = erro;
      if (dados != null) _dados = dados;
    });
  }

  // ---------------- Treinos predefinidos ----------------

  /// Treinos do nível escolhido, filtrados pelo tipo (se houver).
  List<_TreinoPredefinido> get _treinosDoNivel => _predefinidos
      .where((t) =>
          t.nivel == _nivel &&
          (_categoria == null || t.categoria == _categoria))
      .toList();

  void _escolherNivel(_Nivel n) {
    if (n == _nivel) return;
    HapticFeedback.selectionClick();
    setState(() => _nivel = n);
  }

  /// Folha com o que fazer em cada dia da semana do nível.
  void _verSemana() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Cores.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _FolhaSemana(nivel: _nivel),
    );
  }

  Future<void> _escolherTipo() async {
    HapticFeedback.selectionClick();
    final escolha = await showModalBottomSheet<(_Categoria?,)>(
      context: context,
      backgroundColor: _Cores.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _FolhaTipos(selecionada: _categoria, nivel: _nivel),
    );
    if (escolha == null || !mounted) return; // fechou sem escolher
    setState(() => _categoria = escolha.$1);
  }

  void _limparTipo() {
    HapticFeedback.selectionClick();
    setState(() => _categoria = null);
  }

  // ---------------- Navegação ----------------

  Future<void> _abrirRotas() async {
    HapticFeedback.selectionClick();
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RotasScreen()),
    );
    if (salvou == true && mounted) _carregar();
  }

  void _abrirEmergencia() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergenciaScreen()),
    );
  }

  /// Abre a corrida; se for salva, recarrega o progresso da semana.
  Future<void> _correr({
    required String titulo,
    required String subtitulo,
    double? metaKm,
  }) async {
    HapticFeedback.mediumImpact();
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CorridaScreen(
          titulo: titulo,
          subtitulo: subtitulo,
          metaKm: metaKm,
        ),
      ),
    );
    if (salvou == true && mounted) _carregar();
  }

  /// Corrida: folha com as etapas. Outros: tela com os exercícios.
  Future<void> _abrirPredefinido(_TreinoPredefinido t) async {
    HapticFeedback.selectionClick();
    if (!t.ehCorrida) {
      final concluiu = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => _DetalheTreinoScreen(treino: t)),
      );
      if (concluiu == true) _treinoConcluido(t);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Cores.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _FolhaPredefinido(
        treino: t,
        onComecar: () {
          Navigator.pop(ctx);
          _correr(
            titulo: t.titulo,
            subtitulo: 'TREINO PREDEFINIDO',
            metaKm: t.metaKm,
          );
        },
      ),
    );
  }

  /// Botão de play do card: corrida abre o GPS; os outros, o treino guiado.
  Future<void> _comecarPredefinido(_TreinoPredefinido t) async {
    if (t.ehCorrida) {
      _correr(
        titulo: t.titulo,
        subtitulo: 'TREINO PREDEFINIDO',
        metaKm: t.metaKm,
      );
      return;
    }
    HapticFeedback.mediumImpact();
    final concluiu = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _TreinoGuiadoScreen(treino: t)),
    );
    if (concluiu == true) _treinoConcluido(t);
  }

  void _treinoConcluido(_TreinoPredefinido t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Treino "${t.titulo}" concluído! 💪')),
    );
  }

  Widget _listaPredefinidos() {
    final lista = _treinosDoNivel;
    return Column(
      key: ValueKey('${_nivel.name}-${_categoria?.name}'),
      children: [
        if (lista.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _Cores.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _Cores.borda),
            ),
            child: Text(
              'O ${_nivel.rotulo} não tem treino de '
              '${_categoria?.rotulo ?? ''}. Escolha outro tipo ou outro nível.',
              style: TextStyle(
                  fontSize: 13, height: 1.4, color: _Cores.textoSecundario),
            ),
          ),
        for (final t in lista)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CardPredefinido(
              treino: t,
              onTap: () => _abrirPredefinido(t),
              onPlay: () => _comecarPredefinido(t),
            ),
          ),
      ],
    );
  }

  List<TreinoAgendado> get _treinosDoDia =>
      _dados.agenda.where((t) => _mesmoDia(t.data, _diaSelecionado)).toList()
        ..sort((a, b) => a.data.compareTo(b.data));

  @override
  Widget build(BuildContext context) {
    final plano = _dados.plano;

    return Scaffold(
      backgroundColor: _Cores.fundo,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _Cores.escuro,
          onRefresh: _carregar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // ---------------- Cabeçalho ----------------
              Text(
                plano != null ? 'PLANO PERSONALIZADO' : 'SEUS TREINOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _Cores.textoSecundario,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plano != null && plano.totalSemanas > 0
                    ? 'Semana ${plano.semanaAtual} de ${plano.totalSemanas}'
                    : 'Treinos',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _Cores.escuro,
                  letterSpacing: -0.5,
                ),
              ),
              if (plano?.titulo != null) ...[
                const SizedBox(height: 8),
                Text(plano!.titulo!,
                    style: TextStyle(
                        fontSize: 14.5, color: _Cores.textoSecundario)),
              ],
              const SizedBox(height: 16),

              // ---------------- Painel (aluno / treinador) ----------------
              // O botão decide sozinho o texto (aluno ou treinador).
              _BotaoPainel(aoVoltar: _carregar),
              const SizedBox(height: 16),

              // ---------------- Objetivo semanal ----------------
              if (_carregando)
                const _BlocoCarregando(altura: 132)
              else if (plano != null && plano.metaKm > 0)
                _CardObjetivo(plano: plano)
              else
                _CardSemPlano(erro: _erro, onTentar: _carregar),

              // ---------------- Predefinidos por nível ----------------
              const SizedBox(height: 26),
              Text('TREINE NO SEU RITMO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _Cores.textoSecundario,
                    letterSpacing: 1.3,
                  )),
              const SizedBox(height: 4),
              Text('Treinos predefinidos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro,
                  )),
              const SizedBox(height: 12),
              _SeletorNivel(selecionado: _nivel, onSelecionar: _escolherNivel),
              const SizedBox(height: 12),
              _CardNivel(nivel: _nivel, onTap: _verSemana),
              const SizedBox(height: 12),
              _BotaoTipo(
                categoria: _categoria,
                nivel: _nivel,
                onTap: _escolherTipo,
                onLimpar: _limparTipo,
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) =>
                    FadeTransition(opacity: a, child: c),
                child: _listaPredefinidos(),
              ),

              // ---------------- Agenda ----------------
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text('Agenda de treinos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _Cores.escuro,
                        )),
                  ),
                  Tooltip(
                    message: 'Voltar para hoje',
                    child: Material(
                      color: _Cores.card,
                      shape:
                          CircleBorder(side: BorderSide(color: _Cores.borda)),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                              () => _diaSelecionado = _soData(DateTime.now()));
                        },
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.calendar_today_outlined,
                              size: 18, color: _Cores.escuro),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SeletorSemana(
                selecionado: _diaSelecionado,
                agenda: _dados.agenda,
                onSelecionar: (d) {
                  HapticFeedback.selectionClick();
                  setState(() => _diaSelecionado = d);
                },
              ),
              const SizedBox(height: 12),
              if (_carregando)
                const _BlocoCarregando(altura: 80)
              else
                _ListaDoDia(
                  dia: _diaSelecionado,
                  treinos: _treinosDoDia,
                  onTreino: (t) => _correr(
                    titulo: t.titulo,
                    subtitulo: 'TREINO DO PLANO',
                    metaKm: t.distanciaKm,
                  ),
                ),

              // ---------------- Rotas e segurança ----------------
              const SizedBox(height: 28),
              Text('Para treinar na rua',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro,
                  )),
              const SizedBox(height: 12),
              _ExplorarCard(onTap: _abrirRotas),
              const SizedBox(height: 12),
              _EmergenciaCard(onTap: _abrirEmergencia),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// OBJETIVO SEMANAL
// =============================================================================

class _CardObjetivo extends StatelessWidget {
  const _CardObjetivo({required this.plano});

  final PlanoSemanal plano;

  @override
  Widget build(BuildContext context) {
    final concluido = plano.faltam <= 0.05;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: _Cores.destaque,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Círculos decorativos ao fundo
            Positioned(
              right: -70,
              top: -70,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OBJETIVO SEMANAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _Cores.tinta,
                            letterSpacing: 1.4,
                          )),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _distancia(plano.metaKm),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: _Cores.tinta,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        concluido
                            ? 'Meta da semana concluída! 🎉'
                            : 'Faltam ${_distancia(plano.faltam)} para concluir',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3F4A16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AnelProgresso(progresso: plano.progresso),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculo escuro com o percentual e um arco verde que se preenche.
class _AnelProgresso extends StatelessWidget {
  const _AnelProgresso({required this.progresso});

  final double progresso;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progresso),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: 92,
        height: 92,
        child: CustomPaint(
          painter: _AnelPainter(v),
          child: Center(
            child: Text(
              '${(v * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnelPainter extends CustomPainter {
  const _AnelPainter(this.progresso);

  final double progresso;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = _Cores.tinta);

    final ret = Rect.fromCircle(center: c, radius: r - 7);
    canvas.drawArc(
      ret,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    if (progresso > 0) {
      canvas.drawArc(
        ret,
        -math.pi / 2,
        math.pi * 2 * progresso,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = _Cores.destaque,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnelPainter old) => old.progresso != progresso;
}

/// Quem ainda não tem plano (ou a API falhou) vê este card no lugar do objetivo.
class _CardSemPlano extends StatelessWidget {
  const _CardSemPlano({required this.erro, required this.onTentar});

  final String? erro;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Cores.superficie,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _Cores.destaque,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              erro != null ? Icons.wifi_off_rounded : Icons.flag_outlined,
              color: _Cores.tinta,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  erro != null ? 'Plano indisponível' : 'Sem plano no momento',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  erro ??
                      'Quando um treinador montar seu plano, a meta da '
                          'semana aparece aqui. Enquanto isso, use os '
                          'treinos abaixo.',
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 12.5, height: 1.4),
                ),
                if (erro != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onTentar,
                    child: const Text('Tentar de novo',
                        style: TextStyle(
                          color: _Cores.destaque,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TREINOS PREDEFINIDOS
// =============================================================================

class _CardPredefinido extends StatefulWidget {
  const _CardPredefinido({
    required this.treino,
    required this.onTap,
    required this.onPlay,
  });

  final _TreinoPredefinido treino;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  State<_CardPredefinido> createState() => _CardPredefinidoState();
}

class _CardPredefinidoState extends State<_CardPredefinido> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.treino;
    final realce = t.recomendado || _pressionado;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressionado = true),
      onTapUp: (_) => setState(() => _pressionado = false),
      onTapCancel: () => setState(() => _pressionado = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _Cores.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: realce ? _Cores.destaque : _Cores.borda,
            width: realce ? 1.5 : 1,
          ),
          boxShadow: t.recomendado
              ? [
                  BoxShadow(
                    color: _Cores.destaque.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _Cores.destaqueClaro,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(t.icone, color: _Cores.escuro, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(t.titulo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _Cores.escuro,
                          )),
                      if (t.recomendado)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _modoEscuro
                                ? const Color(0xFF2A2E28)
                                : const Color(0xFFF1F2F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('RECOMENDADO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _Cores.escuro,
                                letterSpacing: 0.8,
                              )),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      [
                        '${t.minutos} min',
                        t.categoria.rotulo,
                        t.ehCorrida
                            ? t.resumo
                            : '${t.blocos.length} exercícios',
                      ].join(' · '),
                      style: TextStyle(
                          fontSize: 12.5, color: _Cores.textoSecundario)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _Cores.superficie,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPlay,
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.play_arrow_rounded,
                      color: _Cores.destaque, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detalhes do treino predefinido: etapas e botão para começar.
class _FolhaPredefinido extends StatelessWidget {
  const _FolhaPredefinido({required this.treino, required this.onComecar});

  final _TreinoPredefinido treino;
  final VoidCallback onComecar;

  @override
  Widget build(BuildContext context) {
    final t = treino;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _Cores.borda,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _Cores.superficie,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(t.icone, color: _Cores.destaque, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.titulo,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _Cores.escuro,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        [
                          '${t.minutos} min',
                          t.resumo,
                          if (t.metaKm != null)
                            'meta de ${_distancia(t.metaKm!)}',
                        ].join(' · '),
                        style: TextStyle(
                            fontSize: 13, color: _Cores.textoSecundario),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('COMO FUNCIONA',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: _Cores.textoSecundario,
                  letterSpacing: 1,
                )),
            const SizedBox(height: 10),
            for (var i = 0; i < t.etapas.length; i++)
              _LinhaEtapa(
                numero: i + 1,
                etapa: t.etapas[i],
                ultima: i == t.etapas.length - 1,
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Cores.fundo,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: _Cores.textoSecundario),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Respeite seus limites: se sentir dor ou falta de ar '
                      'fora do normal, diminua o ritmo ou pare.',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: _Cores.textoSecundario),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onComecar,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Começar treino',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Cores.superficie,
                foregroundColor: _Cores.destaque,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma etapa com número, linha vertical ligando as etapas e duração.
class _LinhaEtapa extends StatelessWidget {
  const _LinhaEtapa({
    required this.numero,
    required this.etapa,
    required this.ultima,
  });

  final int numero;
  final _Etapa etapa;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _Cores.destaque,
                    shape: BoxShape.circle,
                  ),
                  child: Text('$numero',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _Cores.tinta,
                      )),
                ),
                if (!ultima)
                  Expanded(
                    child: Container(width: 2, color: _Cores.destaqueClaro),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: ultima ? 0 : 16),
              child: Text(etapa.texto,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: _Cores.escuro,
                  )),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${etapa.minutos} min',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _Cores.textoSecundario,
                )),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SELETOR DE NÍVEL + CARD DO NÍVEL + SEMANA DO NÍVEL
// =============================================================================

/// Em cima: Iniciante | Intermediário. Embaixo: Nível 1 a 5 da fase escolhida.
class _SeletorNivel extends StatelessWidget {
  const _SeletorNivel({required this.selecionado, required this.onSelecionar});

  final _Nivel selecionado;
  final ValueChanged<_Nivel> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final fase = selecionado.fase;
    final daFase = _Nivel.values.where((n) => n.fase == fase).toList();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Cores.borda),
      ),
      child: Column(
        children: [
          // ---- Fase ----
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _Cores.segmento,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                for (final f in _Fase.values)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Trocar de fase leva ao nível 1 dela.
                      onTap: () => onSelecionar(
                          _Nivel.values.firstWhere((n) => n.fase == f)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: f == fase
                              ? _Cores.superficie
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(f.rotulo,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: f == fase
                                  ? _Cores.destaque
                                  : _Cores.textoSecundario,
                            )),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ---- Nível 1 a 5 ----
          Row(
            children: [
              for (final n in daFase)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelecionar(n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              n == selecionado ? _Cores.destaque : _Cores.fundo,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: n == selecionado
                                ? _Cores.destaque
                                : _Cores.borda,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text('NÍVEL',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: n == selecionado
                                      ? _Cores.tinta
                                      : _Cores.textoSecundario,
                                )),
                            Text('${n.numero}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: n == selecionado
                                      ? _Cores.tinta
                                      : _Cores.escuro,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Resumo do nível: objetivo, frequência, tempo e critério para avançar.
class _CardNivel extends StatelessWidget {
  const _CardNivel({required this.nivel, required this.onTap});

  final _Nivel nivel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget info(IconData icone, String texto) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _Cores.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 14, color: _Cores.verde),
              const SizedBox(width: 5),
              Text(texto,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _Cores.escuro,
                  )),
            ],
          ),
        );

    return Material(
      color: _Cores.destaqueClaro,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${nivel.fase.rotulo.toUpperCase()} · NÍVEL ${nivel.numero}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: _Cores.verde,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(nivel.objetivo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro,
                  )),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  info(Icons.calendar_today_outlined, nivel.frequencia),
                  info(Icons.timer_outlined, '${nivel.tempo} por treino'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.flag_outlined, size: 16, color: _Cores.verde),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      nivel.paraAvancar != null
                          ? 'Para avançar: ${nivel.paraAvancar}'
                          : 'Último nível: foco em provas de 5 km e 10 km.',
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: _Cores.textoSecundario),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Ver semana do nível',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _Cores.escuro,
                      )),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: _Cores.escuro),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Folha com o planejamento de segunda a domingo do nível.
class _FolhaSemana extends StatelessWidget {
  const _FolhaSemana({required this.nivel});

  final _Nivel nivel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _Cores.borda,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Semana do ${nivel.rotulo}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _Cores.escuro,
                )),
            const SizedBox(height: 4),
            Text('${nivel.frequencia} · ${nivel.tempo} por treino',
                style: TextStyle(fontSize: 13, color: _Cores.textoSecundario)),
            const SizedBox(height: 14),
            for (var i = 0; i < nivel.semana.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: nivel.semana[i] == 'Descanso'
                      ? _Cores.fundo
                      : _Cores.destaqueClaro,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(_nomesDia[i],
                          style: TextStyle(
                            fontSize: 13,
                            color: _Cores.textoSecundario,
                          )),
                    ),
                    Expanded(
                      child: Text(nivel.semana[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: nivel.semana[i] == 'Descanso'
                                ? _Cores.textoSecundario
                                : _Cores.escuro,
                          )),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Cores.fundo,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: _Cores.textoSecundario),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cada nível dura de 4 a 6 semanas. Avance quando atingir '
                      'o critério, não só porque o tempo passou.',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: _Cores.textoSecundario),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BOTÃO "TIPO DE TREINO" + FOLHA COM OS TIPOS
// =============================================================================

class _BotaoTipo extends StatelessWidget {
  const _BotaoTipo({
    required this.categoria,
    required this.nivel,
    required this.onTap,
    required this.onLimpar,
  });

  final _Categoria? categoria;
  final _Nivel nivel;
  final VoidCallback onTap;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    final c = categoria;
    final total = _predefinidos
        .where((t) => t.nivel == nivel && (c == null || t.categoria == c))
        .length;

    return Material(
      color: _Cores.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: c == null ? _Cores.borda : _Cores.destaque,
            width: c == null ? 1 : 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _Cores.superficie,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(c?.icone ?? Icons.tune_rounded,
                    color: _Cores.destaque, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c == null ? 'Tipo de treino' : c.rotulo,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: _Cores.escuro,
                        )),
                    const SizedBox(height: 1),
                    Text(
                      c == null
                          ? 'Todos os tipos · $total treinos neste nível'
                          : '$total ${total == 1 ? 'treino' : 'treinos'} '
                              'no ${nivel.rotulo}',
                      style: TextStyle(
                          fontSize: 12, color: _Cores.textoSecundario),
                    ),
                  ],
                ),
              ),
              if (c != null)
                IconButton(
                  onPressed: onLimpar,
                  tooltip: 'Mostrar todos os tipos',
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: _Cores.textoSecundario),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.expand_more_rounded, color: _Cores.escuro),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de tipos. Devolve um registro `(categoria,)`; `(null,)` = todos.
class _FolhaTipos extends StatelessWidget {
  const _FolhaTipos({required this.selecionada, required this.nivel});

  final _Categoria? selecionada;
  final _Nivel nivel;

  @override
  Widget build(BuildContext context) {
    Widget item({
      required _Categoria? valor,
      required IconData icone,
      required String titulo,
      required String subtitulo,
    }) {
      final ativo = valor == selecionada;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: ativo ? _Cores.destaqueClaro : _Cores.fundo,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context, (valor,));
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _Cores.superficie,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icone, color: _Cores.destaque, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: _Cores.escuro,
                            )),
                        const SizedBox(height: 1),
                        Text(subtitulo,
                            style: TextStyle(
                                fontSize: 12.5, color: _Cores.textoSecundario)),
                      ],
                    ),
                  ),
                  if (ativo)
                    Icon(Icons.check_circle_rounded, color: _Cores.verde)
                  else
                    Icon(Icons.chevron_right_rounded,
                        color: _Cores.textoSecundario),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Quantos treinos do tipo existem no nível atual.
    String quantos(_Categoria c) {
      final n = _predefinidos
          .where((t) => t.nivel == nivel && t.categoria == c)
          .length;
      if (n == 0) return 'nenhum neste nível';
      return n == 1 ? '1 treino' : '$n treinos';
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _Cores.borda,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Que tipo de treino?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _Cores.escuro,
                )),
            const SizedBox(height: 2),
            Text(nivel.rotulo,
                style: TextStyle(fontSize: 13, color: _Cores.textoSecundario)),
            const SizedBox(height: 14),
            item(
              valor: null,
              icone: Icons.apps_rounded,
              titulo: 'Todos',
              subtitulo: 'Todos os treinos do ${nivel.rotulo}',
            ),
            for (final c in _Categoria.values)
              item(
                valor: c,
                icone: c.icone,
                titulo: c.rotulo,
                subtitulo: '${c.descricao} · ${quantos(c)}',
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ROTAS E DESCOBERTAS
// =============================================================================

class _ExplorarCard extends StatelessWidget {
  const _ExplorarCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          color: _Cores.superficie,
          child: Stack(
            children: [
              const Positioned.fill(
                  child: CustomPaint(painter: _RotaPainter())),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _Cores.destaque,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.route_rounded,
                          color: _Cores.tinta, size: 20),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'EXPLORE SUA CIDADE',
                      style: TextStyle(
                        color: _Cores.destaque,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Rotas e descobertas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.only(right: 100),
                      child: Text(
                        'Escolha onde correr ou siga sem rota definida.',
                        style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: CircleAvatar(
                  backgroundColor: _Cores.card,
                  radius: 20,
                  child: Icon(Icons.arrow_forward_rounded,
                      color: _Cores.escuro, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mapa decorativo: linhas finas ao fundo + rota principal em verde.
class _RotaPainter extends CustomPainter {
  const _RotaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fino = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final linhas = [
      [
        Offset(w * 0.58, 0),
        Offset(w * 0.68, h * 0.28),
        Offset(w * 0.85, h * 0.40),
        Offset(w, h * 0.52)
      ],
      [
        Offset(w * 0.52, h * 0.95),
        Offset(w * 0.72, h * 0.62),
        Offset(w * 0.90, h * 0.20),
        Offset(w, h * 0.08)
      ],
      [
        Offset(w * 0.75, 0),
        Offset(w * 0.82, h * 0.22),
        Offset(w * 0.98, h * 0.30)
      ],
      [Offset(w * 0.62, h), Offset(w * 0.80, h * 0.82), Offset(w, h * 0.72)],
    ];
    for (final pontos in linhas) {
      final path = Path()..moveTo(pontos.first.dx, pontos.first.dy);
      for (final p in pontos.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, fino);
    }

    const corRota = Color(0xFF5B7A2B);
    final rota = Paint()
      ..color = corRota
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final inicio = Offset(w * 0.60, h * 0.70);
    final meio1 = Offset(w * 0.77, h * 0.64);
    final meio2 = Offset(w * 0.87, h * 0.43);
    final fim = Offset(w * 0.96, h * 0.53);

    canvas.drawPath(
      Path()
        ..moveTo(inicio.dx, inicio.dy)
        ..lineTo(meio1.dx, meio1.dy)
        ..lineTo(meio2.dx, meio2.dy)
        ..lineTo(fim.dx, fim.dy),
      rota,
    );
    canvas.drawCircle(inicio, 6, Paint()..color = corRota);
    canvas.drawCircle(
      fim,
      7,
      Paint()
        ..color = corRota
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// SEGURANÇA (botão de emergência)
// =============================================================================

class _EmergenciaCard extends StatelessWidget {
  const _EmergenciaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _Cores.vermelhoFundo,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: _Cores.vermelhoBorda.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _Cores.vermelho,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.gpp_maybe_outlined,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEGURANÇA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _modoEscuro
                          ? const Color(0xFFF87171)
                          : const Color(0xFFDC2626),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Botão de emergência',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _Cores.escuro,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Envie sua localização ao contato de confiança',
                    style: TextStyle(
                        fontSize: 12,
                        color: _Cores.textoSecundario,
                        height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 22, color: _Cores.escuro),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DETALHE DO TREINO (lista de exercícios)
// =============================================================================

class _DetalheTreinoScreen extends StatelessWidget {
  const _DetalheTreinoScreen({required this.treino});

  final _TreinoPredefinido treino;

  Future<void> _comecar(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final concluiu = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _TreinoGuiadoScreen(treino: treino)),
    );
    if (concluiu == true && context.mounted) Navigator.pop(context, true);
  }

  void _abrirExercicio(BuildContext context, _Bloco b) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Cores.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _FolhaExercicio(exercicio: b.exercicio, bloco: b),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = treino;
    return Scaffold(
      backgroundColor: _Cores.fundo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          Icon(Icons.arrow_back_rounded, color: _Cores.escuro),
                      tooltip: 'Voltar',
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Cabeçalho escuro
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _Cores.superficie,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _Cores.destaque,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(t.icone, color: _Cores.tinta, size: 26),
                        ),
                        const SizedBox(height: 16),
                        Text(t.categoria.rotulo.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _Cores.destaque,
                              letterSpacing: 1.3,
                            )),
                        const SizedBox(height: 4),
                        Text(t.titulo,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            )),
                        const SizedBox(height: 6),
                        Text(t.resumo,
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF9CA3AF))),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Etiqueta(
                                icone: Icons.timer_outlined,
                                texto: '~${t.minutos} min'),
                            _Etiqueta(
                                icone: Icons.signal_cellular_alt_rounded,
                                texto: t.nivel.rotulo),
                            _Etiqueta(
                                icone: Icons.format_list_numbered_rounded,
                                texto: '${t.blocos.length} exercícios'),
                            if (t.circuito)
                              _Etiqueta(
                                  icone: Icons.repeat_rounded,
                                  texto: '${t.rodadas} rodadas'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('COMO FUNCIONA',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _Cores.textoSecundario,
                        letterSpacing: 1,
                      )),
                  const SizedBox(height: 6),
                  Text(t.comoFunciona,
                      style: TextStyle(
                          fontSize: 14, height: 1.45, color: _Cores.escuro)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Exercícios',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _Cores.escuro,
                            )),
                      ),
                      Text('Toque para ver como fazer',
                          style: TextStyle(
                              fontSize: 12, color: _Cores.textoSecundario)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < t.blocos.length; i++) ...[
                    _CardExercicio(
                      numero: i + 1,
                      bloco: t.blocos[i],
                      mostrarSeries: !t.circuito,
                      onTap: () => _abrirExercicio(context, t.blocos[i]),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  const _AvisoLimites(),
                ],
              ),
            ),
            // Botão fixo embaixo
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: _Cores.card,
                border: Border(top: BorderSide(color: _Cores.borda)),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _comecar(context),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('Começar treino',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Cores.superficie,
                  foregroundColor: _Cores.destaque,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: _Cores.destaque),
          const SizedBox(width: 5),
          Text(texto,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
        ],
      ),
    );
  }
}

class _CardExercicio extends StatelessWidget {
  const _CardExercicio({
    required this.numero,
    required this.bloco,
    required this.mostrarSeries,
    required this.onTap,
  });

  final int numero;
  final _Bloco bloco;
  final bool mostrarSeries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Cores.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _Cores.borda),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _Cores.destaqueClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$numero',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _Cores.escuro,
                    )),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bloco.exercicio.nome,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: _Cores.escuro,
                        )),
                    const SizedBox(height: 2),
                    Text(bloco.exercicio.musculos,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: _Cores.textoSecundario)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(mostrarSeries ? bloco.prescricao : bloco.alvo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _Cores.verde,
                  )),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: _Cores.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvisoLimites extends StatelessWidget {
  const _AvisoLimites();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Cores.borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: _Cores.textoSecundario),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Respeite seus limites: se sentir dor ou falta de ar fora do '
              'normal, diminua o ritmo ou pare.',
              style: TextStyle(
                  fontSize: 12, height: 1.4, color: _Cores.textoSecundario),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMO FAZER O EXERCÍCIO (folha que sobe de baixo)
// =============================================================================

class _FolhaExercicio extends StatelessWidget {
  const _FolhaExercicio({required this.exercicio, this.bloco});

  final _Exercicio exercicio;
  final _Bloco? bloco;

  @override
  Widget build(BuildContext context) {
    final e = exercicio;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _Cores.borda,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text(e.nome,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro,
                  )),
              const SizedBox(height: 4),
              Text(e.musculos,
                  style:
                      TextStyle(fontSize: 13, color: _Cores.textoSecundario)),
              if (bloco != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _Cores.destaque,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(bloco!.prescricao,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _Cores.tinta,
                        )),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _ComoFazer(exercicio: e),
            ],
          ),
        ),
      ),
    );
  }
}

/// Passo a passo numerado + dicas. Usado na folha e no treino guiado.
class _ComoFazer extends StatelessWidget {
  const _ComoFazer({required this.exercicio});

  final _Exercicio exercicio;

  @override
  Widget build(BuildContext context) {
    final corTexto = _Cores.escuro;
    final corSecundaria = _Cores.textoSecundario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COMO FAZER',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: corSecundaria,
              letterSpacing: 1,
            )),
        const SizedBox(height: 10),
        for (var i = 0; i < exercicio.passos.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _Cores.destaque,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _Cores.tinta,
                      )),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(exercicio.passos[i],
                        style: TextStyle(
                            fontSize: 14, height: 1.4, color: corTexto)),
                  ),
                ),
              ],
            ),
          ),
        if (exercicio.dicas.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('DICAS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: corSecundaria,
                letterSpacing: 1,
              )),
          const SizedBox(height: 8),
          for (final d in exercicio.dicas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: _Cores.verde),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(d,
                        style: TextStyle(
                            fontSize: 13.5, height: 1.4, color: corTexto)),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// =============================================================================
// TREINO GUIADO (executa passo a passo com cronômetro)
// =============================================================================

enum _TipoPasso { preparar, exercicio, descanso }

class _Passo {
  const _Passo({
    required this.tipo,
    required this.titulo,
    this.exercicio,
    this.segundos,
    this.alvo,
    this.detalhe,
    this.proximo,
  });

  final _TipoPasso tipo;
  final String titulo;
  final _Exercicio? exercicio;

  /// null = por repetições (espera o usuário tocar em "Feito").
  final int? segundos;
  final String? alvo;
  final String? detalhe;
  final String? proximo;
}

/// Transforma o treino na sequência de passos (exercícios e descansos).
List<_Passo> _montarPassos(_TreinoPredefinido t) {
  // Cada execução é uma lista de passos + o descanso que vem depois dela.
  final execucoes = <(List<_Passo>, int)>[];

  List<_Passo> execucao(_Bloco b, String? detalhe) {
    final e = b.exercicio;
    if (b.segundos != null) {
      if (!b.porLado) {
        return [
          _Passo(
            tipo: _TipoPasso.exercicio,
            titulo: e.nome,
            exercicio: e,
            segundos: b.segundos,
            detalhe: detalhe,
          ),
        ];
      }
      String lado(String l) => detalhe == null ? l : '$detalhe · $l';
      return [
        _Passo(
          tipo: _TipoPasso.exercicio,
          titulo: e.nome,
          exercicio: e,
          segundos: b.segundos,
          detalhe: lado('Lado direito'),
        ),
        _Passo(
          tipo: _TipoPasso.descanso,
          titulo: 'Troque de lado',
          segundos: 5,
          proximo: e.nome,
        ),
        _Passo(
          tipo: _TipoPasso.exercicio,
          titulo: e.nome,
          exercicio: e,
          segundos: b.segundos,
          detalhe: lado('Lado esquerdo'),
        ),
      ];
    }
    return [
      _Passo(
        tipo: _TipoPasso.exercicio,
        titulo: e.nome,
        exercicio: e,
        alvo: b.porLado ? '${b.reps} por lado' : '${b.reps} repetições',
        detalhe: detalhe,
      ),
    ];
  }

  if (t.circuito) {
    for (var r = 1; r <= t.rodadas; r++) {
      for (var i = 0; i < t.blocos.length; i++) {
        final fimRodada = i == t.blocos.length - 1;
        execucoes.add((
          execucao(t.blocos[i], 'Rodada $r de ${t.rodadas}'),
          fimRodada ? t.descansoRodadaSeg : t.descansoSeg,
        ));
      }
    }
  } else {
    for (final b in t.blocos) {
      for (var s = 1; s <= b.series; s++) {
        execucoes.add((
          execucao(b, b.series > 1 ? 'Série $s de ${b.series}' : null),
          t.descansoSeg,
        ));
      }
    }
  }

  final passos = <_Passo>[];
  if (execucoes.isEmpty) return passos;
  passos.add(_Passo(
    tipo: _TipoPasso.preparar,
    titulo: 'Prepare-se',
    segundos: 5,
    proximo: execucoes.first.$1.first.titulo,
  ));
  for (var i = 0; i < execucoes.length; i++) {
    passos.addAll(execucoes[i].$1);
    final ultimo = i == execucoes.length - 1;
    if (!ultimo && execucoes[i].$2 > 0) {
      passos.add(_Passo(
        tipo: _TipoPasso.descanso,
        titulo: 'Descanso',
        segundos: execucoes[i].$2,
        proximo: execucoes[i + 1].$1.first.titulo,
      ));
    }
  }
  return passos;
}

class _TreinoGuiadoScreen extends StatefulWidget {
  const _TreinoGuiadoScreen({required this.treino});

  final _TreinoPredefinido treino;

  @override
  State<_TreinoGuiadoScreen> createState() => _TreinoGuiadoScreenState();
}

class _TreinoGuiadoScreenState extends State<_TreinoGuiadoScreen> {
  late final List<_Passo> _passos = _montarPassos(widget.treino);
  late final int _totalExercicios =
      _passos.where((p) => p.tipo == _TipoPasso.exercicio).length;

  int _indice = 0;
  int _restante = 0;
  int _decorrido = 0;
  bool _pausado = false;
  bool _concluido = false;
  bool _mostrarComoFazer = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_passos.isEmpty) {
      _concluido = true;
    } else {
      _entrar(0);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  _Passo get _atual => _passos[_indice];

  /// Posição do exercício atual (1, 2, 3...) entre todos os exercícios.
  int get _numeroExercicio => _passos
      .take(_indice + 1)
      .where((p) => p.tipo == _TipoPasso.exercicio)
      .length;

  void _entrar(int i) {
    _indice = i;
    _restante = _passos[i].segundos ?? 0;
    _mostrarComoFazer = false;
  }

  void _tick(Timer _) {
    if (_pausado || _concluido || !mounted) return;
    setState(() {
      _decorrido++;
      if (_atual.segundos == null) return;
      _restante--;
      if (_restante > 0 && _restante <= 3) HapticFeedback.selectionClick();
      if (_restante <= 0) _avancar();
    });
  }

  /// Vai para o próximo passo (sem setState: quem chama faz).
  void _avancar() {
    HapticFeedback.mediumImpact();
    if (_indice >= _passos.length - 1) {
      _concluido = true;
      _timer?.cancel();
      return;
    }
    _entrar(_indice + 1);
  }

  void _proximo() => setState(_avancar);

  void _anterior() {
    if (_indice == 0) return;
    HapticFeedback.selectionClick();
    setState(() => _entrar(_indice - 1));
  }

  void _alternarPausa() {
    HapticFeedback.selectionClick();
    setState(() => _pausado = !_pausado);
  }

  Future<void> _sair() async {
    if (_concluido) {
      Navigator.pop(context, true);
      return;
    }
    final pausadoAntes = _pausado;
    setState(() => _pausado = true);
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Cores.card,
        title: Text('Sair do treino?',
            style:
                TextStyle(color: _Cores.escuro, fontWeight: FontWeight.w800)),
        content: Text('O progresso deste treino será perdido.',
            style: TextStyle(color: _Cores.textoSecundario)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Continuar', style: TextStyle(color: _Cores.escuro)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair',
                style: TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (sair == true) {
      Navigator.pop(context, false);
    } else {
      setState(() => _pausado = pausadoAntes);
    }
  }

  String _relogio(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _sair();
      },
      child: Scaffold(
        backgroundColor: _Cores.fundo,
        body: SafeArea(
          child: _concluido ? _telaFim() : _telaPasso(),
        ),
      ),
    );
  }

  Widget _telaPasso() {
    final p = _atual;
    final ehExercicio = p.tipo == _TipoPasso.exercicio;
    final progresso = _passos.isEmpty ? 1.0 : _indice / _passos.length;

    return Column(
      children: [
        // ---------- Topo ----------
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: _sair,
                tooltip: 'Sair',
                icon: Icon(Icons.close_rounded, color: _Cores.escuro),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.treino.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _Cores.escuro,
                        )),
                    Text(
                      'Exercício ${math.max(1, _numeroExercicio)} de '
                      '$_totalExercicios',
                      style: TextStyle(
                          fontSize: 12, color: _Cores.textoSecundario),
                    ),
                  ],
                ),
              ),
              Icon(Icons.timer_outlined,
                  size: 16, color: _Cores.textoSecundario),
              const SizedBox(width: 4),
              Text(_relogio(_decorrido),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Cores.escuro,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progresso),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                color: _Cores.destaque,
                backgroundColor: _Cores.segmento,
              ),
            ),
          ),
        ),

        // ---------- Conteúdo ----------
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _CartaoPasso(
                  key: ValueKey(_indice),
                  passo: p,
                  restante: _restante,
                  pausado: _pausado,
                  relogio: _relogio,
                ),
              ),
              if (ehExercicio && p.exercicio != null) ...[
                const SizedBox(height: 16),
                Material(
                  color: _Cores.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: _Cores.borda),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () =>
                        setState(() => _mostrarComoFazer = !_mostrarComoFazer),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book_rounded,
                                  size: 18, color: _Cores.verde),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Como fazer este exercício',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: _Cores.escuro,
                                    )),
                              ),
                              Icon(
                                _mostrarComoFazer
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: _Cores.textoSecundario,
                              ),
                            ],
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            alignment: Alignment.topCenter,
                            child: _mostrarComoFazer
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: _ComoFazer(exercicio: p.exercicio!),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ---------- Controles ----------
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: _Cores.card,
            border: Border(top: BorderSide(color: _Cores.borda)),
          ),
          child: Row(
            children: [
              _BotaoRedondo(
                icone: Icons.skip_previous_rounded,
                dica: 'Voltar',
                onTap: _indice > 0 ? _anterior : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: p.segundos == null ? _proximo : _alternarPausa,
                  icon: Icon(
                    p.segundos == null
                        ? Icons.check_rounded
                        : (_pausado
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded),
                    size: 22,
                  ),
                  label: Text(
                    p.segundos == null
                        ? 'Feito'
                        : (_pausado ? 'Continuar' : 'Pausar'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Cores.superficie,
                    foregroundColor: _Cores.destaque,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _BotaoRedondo(
                icone: Icons.skip_next_rounded,
                dica: 'Pular',
                onTap: _proximo,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _telaFim() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (_, v, c) => Transform.scale(scale: v, child: c),
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: _Cores.destaque,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 52, color: _Cores.tinta),
            ),
          ),
          const SizedBox(height: 24),
          Text('Treino concluído!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _Cores.escuro,
              )),
          const SizedBox(height: 8),
          Text(widget.treino.titulo,
              style: TextStyle(fontSize: 15, color: _Cores.textoSecundario)),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _NumeroFim(
                    valor: _relogio(_decorrido), rotulo: 'tempo total'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumeroFim(
                    valor: '${widget.treino.blocos.length}',
                    rotulo: 'exercícios'),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Cores.superficie,
              foregroundColor: _Cores.destaque,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: const Text('Concluir',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

/// Cartão grande com o passo atual: exercício (escuro) ou descanso (verde).
class _CartaoPasso extends StatelessWidget {
  const _CartaoPasso({
    super.key,
    required this.passo,
    required this.restante,
    required this.pausado,
    required this.relogio,
  });

  final _Passo passo;
  final int restante;
  final bool pausado;
  final String Function(int) relogio;

  @override
  Widget build(BuildContext context) {
    final p = passo;
    final ehExercicio = p.tipo == _TipoPasso.exercicio;
    final fundo = ehExercicio ? _Cores.superficie : _Cores.destaque;
    final texto = ehExercicio ? Colors.white : _Cores.tinta;
    final secundario =
        ehExercicio ? const Color(0xFF9CA3AF) : const Color(0xFF3F4A16);

    final troca = p.titulo == 'Troque de lado';
    final rotulo = switch (p.tipo) {
      _TipoPasso.preparar => 'PREPARE-SE',
      _TipoPasso.descanso => 'DESCANSO',
      _TipoPasso.exercicio => 'EXERCÍCIO',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: ehExercicio ? _Cores.destaque : _Cores.tinta,
                letterSpacing: 1.4,
              )),
          const SizedBox(height: 8),
          if (!ehExercicio && !troca)
            Text(
                p.tipo == _TipoPasso.preparar
                    ? 'Primeiro exercício'
                    : 'A seguir',
                style: TextStyle(fontSize: 13, color: secundario)),
          Text(ehExercicio || troca ? p.titulo : (p.proximo ?? ''),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: texto,
                height: 1.15,
              )),
          if (troca && p.proximo != null) ...[
            const SizedBox(height: 2),
            Text(p.proximo!, style: TextStyle(fontSize: 13, color: secundario)),
          ],
          if (p.detalhe != null) ...[
            const SizedBox(height: 6),
            Text(p.detalhe!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: secundario,
                )),
          ],
          const SizedBox(height: 22),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                p.segundos != null ? relogio(restante) : (p.alvo ?? ''),
                style: TextStyle(
                  fontSize: p.segundos != null ? 72 : 44,
                  fontWeight: FontWeight.w900,
                  color: texto,
                  letterSpacing: -1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              p.segundos == null
                  ? 'Toque em "Feito" quando terminar'
                  : (pausado
                      ? 'Pausado'
                      : (p.tipo == _TipoPasso.exercicio
                          ? 'Segue sozinho quando o tempo acabar'
                          : (troca
                              ? 'Posicione-se para o outro lado'
                              : 'Respire e recupere'))),
              style: TextStyle(fontSize: 12.5, color: secundario),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoRedondo extends StatelessWidget {
  const _BotaoRedondo({
    required this.icone,
    required this.dica,
    required this.onTap,
  });

  final IconData icone;
  final String dica;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ativo = onTap != null;
    return Tooltip(
      message: dica,
      child: Material(
        color: _Cores.fundo,
        shape: CircleBorder(side: BorderSide(color: _Cores.borda)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(icone,
                color: ativo
                    ? _Cores.escuro
                    : _Cores.textoSecundario.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }
}

class _NumeroFim extends StatelessWidget {
  const _NumeroFim({required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Cores.borda),
      ),
      child: Column(
        children: [
          Text(valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _Cores.escuro,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
          const SizedBox(height: 2),
          Text(rotulo,
              style: TextStyle(fontSize: 12, color: _Cores.textoSecundario)),
        ],
      ),
    );
  }
}

// =============================================================================
// AGENDA
// =============================================================================

/// Os 7 dias da semana atual; dias com treino ganham um pontinho.
class _SeletorSemana extends StatelessWidget {
  const _SeletorSemana({
    required this.selecionado,
    required this.agenda,
    required this.onSelecionar,
  });

  final DateTime selecionado;
  final List<TreinoAgendado> agenda;
  final ValueChanged<DateTime> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final hoje = _soData(DateTime.now());
    final segunda = hoje.subtract(Duration(days: hoje.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Cores.borda),
      ),
      child: Row(
        children: List.generate(7, (i) {
          final dia = DateTime(segunda.year, segunda.month, segunda.day + i);
          final ativo = _mesmoDia(dia, selecionado);
          final ehHoje = _mesmoDia(dia, hoje);
          final treinosDia = agenda.where((t) => _mesmoDia(t.data, dia));
          final temTreino = treinosDia.isNotEmpty;
          final feito = temTreino && treinosDia.every((t) => t.concluido);

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelecionar(dia),
              child: Column(
                children: [
                  Text(_letrasDia[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _Cores.textoSecundario,
                      )),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ativo
                          ? _Cores.superficie
                          : (feito ? _Cores.destaque : Colors.transparent),
                      shape: BoxShape.circle,
                      border: ehHoje && !ativo
                          ? Border.all(color: _Cores.destaque, width: 2)
                          : null,
                    ),
                    child: Text('${dia.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ativo
                              ? Colors.white
                              : (feito ? _Cores.tinta : _Cores.escuro),
                        )),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: temTreino && !feito
                          ? _Cores.verde
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ListaDoDia extends StatelessWidget {
  const _ListaDoDia({
    required this.dia,
    required this.treinos,
    required this.onTreino,
  });

  final DateTime dia;
  final List<TreinoAgendado> treinos;
  final ValueChanged<TreinoAgendado> onTreino;

  @override
  Widget build(BuildContext context) {
    final rotulo = '${_nomesDia[dia.weekday - 1]}, ${dia.day} de '
        '${_meses[dia.month - 1]}';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Column(
        key: ValueKey(dia),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(rotulo.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: _Cores.textoSecundario,
                  letterSpacing: 1,
                )),
          ),
          if (treinos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _Cores.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _Cores.borda),
              ),
              child: Row(
                children: [
                  Icon(Icons.self_improvement_rounded,
                      color: _Cores.textoSecundario),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nenhum treino marcado. Dia livre para descansar ou '
                      'fazer um treino predefinido.',
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _Cores.textoSecundario),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final t in treinos) ...[
              _CardAgendado(treino: t, onTap: () => onTreino(t)),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _CardAgendado extends StatelessWidget {
  const _CardAgendado({required this.treino, required this.onTap});

  final TreinoAgendado treino;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = treino;
    final detalhes = [
      if (t.distanciaKm != null) _distancia(t.distanciaKm!),
      if (t.resumo != null) t.resumo!,
    ].join(' · ');

    return Material(
      color: _Cores.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _Cores.borda),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: t.concluido ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: t.concluido ? _Cores.destaque : _Cores.superficie,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  t.concluido
                      ? Icons.check_rounded
                      : Icons.directions_run_rounded,
                  color: t.concluido ? _Cores.tinta : _Cores.destaque,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (t.tipo != null)
                      Text(t.tipo!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _Cores.verde,
                            letterSpacing: 0.8,
                          )),
                    const SizedBox(height: 2),
                    Text(t.titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _Cores.escuro,
                          decoration:
                              t.concluido ? TextDecoration.lineThrough : null,
                        )),
                    if (detalhes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(detalhes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5, color: _Cores.textoSecundario)),
                    ],
                  ],
                ),
              ),
              if (t.concluido)
                Text('FEITO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: _Cores.verde,
                      letterSpacing: 0.8,
                    ))
              else
                Icon(Icons.chevron_right_rounded,
                    size: 22, color: _Cores.escuro),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COMUNS
// =============================================================================

class _BlocoCarregando extends StatelessWidget {
  const _BlocoCarregando({required this.altura});

  final double altura;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      decoration: BoxDecoration(
        color: _Cores.borda.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child:
              CircularProgressIndicator(strokeWidth: 2.5, color: _Cores.escuro),
        ),
      ),
    );
  }
}

// =============================================================================
// BOTÃO DO PAINEL (aluno / treinador)
// =============================================================================
//
// O botão descobre sozinho se o usuário é treinador ou aluno (pelo perfil salvo no
// aparelho) e muda o texto e o ícone. O conteúdo do painel quem decide é a
// API, dentro da PainelScreen (painel.dart).

class _BotaoPainel extends StatefulWidget {
  const _BotaoPainel({this.aoVoltar});

  /// Chamado quando o usuário volta do painel (ex.: recarregar a tela de trás).
  final VoidCallback? aoVoltar;

  @override
  State<_BotaoPainel> createState() => _BotaoPainelState();
}

class _BotaoPainelState extends State<_BotaoPainel> {
  /// false = aluno (padrão); true = treinador.
  bool _ehTreinador = false;

  @override
  void initState() {
    super.initState();
    _lerPapel();
  }

  /// Lê o perfil salvo e vê se o campo `ehTreinador` é true.
  Future<void> _lerPapel() async {
    final perfil = await CacheLocal.ler('perfil');
    final dados = perfil?.dados;
    if (!mounted || dados is! Map) return;
    setState(() => _ehTreinador = dados['ehTreinador'] == true);
  }

  /// Abre o painel; na volta relê o papel e avisa a tela de trás.
  Future<void> _abrir() async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PainelScreen()),
    );
    if (!mounted) return;
    _lerPapel();
    widget.aoVoltar?.call();
  }

  @override
  Widget build(BuildContext context) {
    final treinador = _ehTreinador;
    return Material(
      color: _Cores.superficie,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _abrir,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _Cores.destaque,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  treinador
                      ? Icons.space_dashboard_rounded
                      : Icons.insights_rounded,
                  color: _Cores.tinta,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treinador ? 'ÁREA DO TREINADOR' : 'ÁREA DO ALUNO',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _Cores.destaque,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      treinador
                          ? 'Painel do treinador'
                          : 'Meu painel de treinos',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      treinador
                          ? 'Alunos, agenda, desempenho e feedbacks'
                          : 'Treinos, evolução e feedbacks do treinador',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
