/**
 * Nomes de curso: cada curso pertence a uma universidade, e as páginas
 * públicas juntam pelo nome os cursos de universidades diferentes. Estas
 * funções definem quando dois nomes são o mesmo curso (sem diferenciar
 * maiúsculas, acentos e espaços repetidos) e quando são só parecidos
 * (abreviações e pequenas diferenças), para o administrador padronizar.
 */

/** Chave de agrupamento: sem acentos, em minúsculas e com um espaço só entre as palavras. */
function normalizarNome(nome) {
  return String(nome ?? '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Valor mais frequente da lista (nulos e vazios de fora). No empate, o que
 * apareceu primeiro: quem chama passa os registros na ordem de cadastro.
 */
function maisFrequente(valores) {
  const contagem = new Map();
  for (const valor of valores) {
    if (valor == null || String(valor).trim() === '') continue;
    contagem.set(valor, (contagem.get(valor) ?? 0) + 1);
  }
  let escolhido = null;
  let maior = 0;
  for (const [valor, total] of contagem) {
    if (total > maior) {
      escolhido = valor;
      maior = total;
    }
  }
  return escolhido;
}

/** Grafia exibida de um grupo: a mais usada, sem espaços sobrando. */
function grafiaMaisUsada(nomes) {
  return maisFrequente(nomes.map((nome) => String(nome ?? '').replace(/\s+/g, ' ').trim()));
}

/**
 * Agrupa cursos pelo nome normalizado. Cada grupo tem a grafia mais usada,
 * a área mais frequente, os graus (do mais para o menos frequente) e as
 * contagens de cursos e de universidades. Os cursos devem vir na ordem de
 * cadastro (id), que desempata a grafia e a área.
 */
function agruparPorNome(cursos) {
  const grupos = new Map();
  for (const curso of cursos) {
    const chave = normalizarNome(curso.nome);
    if (!chave) continue;
    if (!grupos.has(chave)) grupos.set(chave, []);
    grupos.get(chave).push(curso);
  }

  return [...grupos.entries()].map(([chave, itens]) => {
    // Graus pelo número de universidades que oferecem cada um (como na
    // página do curso); no empate, em ordem alfabética.
    const universidadesPorGrau = new Map();
    for (const { grau, universidadeId } of itens) {
      if (!grau) continue;
      if (!universidadesPorGrau.has(grau)) universidadesPorGrau.set(grau, new Set());
      universidadesPorGrau.get(grau).add(universidadeId);
    }
    return {
      chave,
      nome: grafiaMaisUsada(itens.map((c) => c.nome)),
      areaCurso: maisFrequente(itens.map((c) => c.areaCurso)),
      graus: [...universidadesPorGrau.entries()]
        .sort((a, b) => b[1].size - a[1].size || a[0].localeCompare(b[0], 'pt-BR'))
        .map(([grau]) => grau),
      totalOfertas: itens.length,
      totalUniversidades: new Set(itens.map((c) => c.universidadeId)).size,
      cursos: itens,
    };
  });
}

// Palavras que não ajudam a comparar nomes ("Engenharia de Produção" e
// "Engenharia Produção" são o mesmo curso).
const PALAVRAS_LIGACAO = new Set(['a', 'o', 'as', 'os', 'de', 'da', 'do', 'das', 'dos', 'e', 'em', 'na', 'no', 'para']);

function palavras(nome) {
  return normalizarNome(nome)
    .replace(/[^a-z0-9]+/g, ' ')
    .split(' ')
    .filter((p) => p && !PALAVRAS_LIGACAO.has(p));
}

function distancia(a, b) {
  const anterior = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i += 1) {
    let diagonal = anterior[0];
    anterior[0] = i;
    for (let j = 1; j <= b.length; j += 1) {
      const guardado = anterior[j];
      anterior[j] = Math.min(anterior[j] + 1, anterior[j - 1] + 1, diagonal + (a[i - 1] === b[j - 1] ? 0 : 1));
      diagonal = guardado;
    }
  }
  return anterior[b.length];
}

/** "ADS" e "Análise e Desenvolvimento de Sistemas". */
function ehSigla(curta, longa) {
  return curta.length === 1 && longa.length >= 2 && curta[0] === longa.map((p) => p[0]).join('');
}

/** "Eng. Civil" e "Engenharia Civil": cada palavra igual ou abreviada (3 letras ou mais). */
function ehAbreviacao(a, b) {
  if (a.length !== b.length) return false;
  return a.every((p, i) => {
    const q = b[i];
    if (p === q) return true;
    const [curta, longa] = p.length < q.length ? [p, q] : [q, p];
    return curta.length >= 3 && longa.startsWith(curta);
  });
}

/**
 * Dois nomes parecidos: iguais sem acentos, pontuação e palavras de ligação;
 * um é a sigla ou a abreviação do outro; ou diferem em uma letra (com duas
 * já juntaria cursos diferentes, como Engenharia Elétrica e Eletrônica).
 */
function nomesParecidos(a, b) {
  const pa = palavras(a);
  const pb = palavras(b);
  if (pa.length === 0 || pb.length === 0) return false;
  const ja = pa.join(' ');
  const jb = pb.join(' ');
  if (ja === jb) return true;
  if (ehSigla(pa, pb) || ehSigla(pb, pa)) return true;
  if (ehAbreviacao(pa, pb)) return true;
  const menor = Math.min(ja.length, jb.length);
  if (menor < 5) return false;
  return distancia(ja, jb) <= 1;
}

/**
 * Grupos de grafias parecidas entre os cursos: só entram os grupos com
 * mais de uma grafia diferente (o mesmo nome escrito igual em várias
 * universidades não precisa de padronização).
 */
function gruposDeNomesParecidos(cursos) {
  const grafias = [...new Set(cursos.map((c) => String(c.nome).trim()))];
  const pai = grafias.map((_, i) => i);
  const raiz = (i) => (pai[i] === i ? i : (pai[i] = raiz(pai[i])));

  for (let i = 0; i < grafias.length; i += 1) {
    for (let j = i + 1; j < grafias.length; j += 1) {
      if (raiz(i) !== raiz(j) && nomesParecidos(grafias[i], grafias[j])) pai[raiz(j)] = raiz(i);
    }
  }

  const porRaiz = new Map();
  grafias.forEach((grafia, i) => {
    const r = raiz(i);
    if (!porRaiz.has(r)) porRaiz.set(r, new Set());
    porRaiz.get(r).add(grafia);
  });

  return [...porRaiz.values()]
    .filter((conjunto) => conjunto.size > 1)
    .map((conjunto) => {
      const itens = cursos.filter((c) => conjunto.has(String(c.nome).trim()));
      return { nomeSugerido: grafiaMaisUsada(itens.map((c) => c.nome)), grafias: conjunto.size, cursos: itens };
    })
    .sort((a, b) => a.nomeSugerido.localeCompare(b.nomeSugerido, 'pt-BR'));
}

module.exports = { normalizarNome, maisFrequente, grafiaMaisUsada, agruparPorNome, nomesParecidos, gruposDeNomesParecidos };
