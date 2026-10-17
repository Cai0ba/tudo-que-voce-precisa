import '../tools/catalog.dart';
import '../tools/tool.dart';

String _norm(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  var out = s.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    out = out.replaceAll(from[i], to[i]);
  }
  return out.trim();
}

/// Busca simples sem IA: todos os termos devem aparecer em nome, descrição,
/// categoria ou palavras-chave (ignorando acentos). Nome pesa mais.
List<Tool> searchTools(String query, {List<Tool> tools = toolCatalog}) {
  final terms = _norm(query)
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (terms.isEmpty) return tools;
  final scored = <(Tool, int)>[];
  for (final tool in tools) {
    final name = _norm(tool.name);
    final other = _norm(
      '${tool.description} ${tool.category.label} ${tool.keywords.join(' ')}',
    );
    var score = 0;
    var ok = true;
    for (final t in terms) {
      if (name.contains(t)) {
        score += 10;
      } else if (other.contains(t)) {
        score += 3;
      } else {
        ok = false;
        break;
      }
    }
    // Frases como "quantos anos" também casam como palavra-chave inteira.
    if (!ok && other.contains(terms.join(' '))) {
      ok = true;
      score = 5;
    }
    if (ok) scored.add((tool, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final s in scored) s.$1];
}
