const bigInt = require("big-integer");

// Cache de memoization a nivel de modulo (memoria de la instancia).
// Vive mientras la instancia del Function App este "caliente".
// Se PIERDE cuando Azure recicla la instancia (cold start tras ~5 min inactivo).
const memo = new Map();
memo.set(0, bigInt.zero);
memo.set(1, bigInt.one);

function fibMemo(n) {
  const cached = memo.get(n);
  if (cached !== undefined) return cached;
  const value = fibMemo(n - 1).add(fibMemo(n - 2));
  memo.set(n, value);
  return value;
}

module.exports = async function (context, req) {
  const nth = Number((req.body && req.body.nth) !== undefined ? req.body.nth : (req.query && req.query.nth));

  if (!Number.isInteger(nth) || nth < 0) {
    context.res = { status: 400, body: { error: "nth debe ser un entero >= 0" } };
    return;
  }

  const wasCached = memo.has(nth);
  const start = Date.now();
  let result;
  try {
    result = fibMemo(nth);
  } catch (e) {
    context.res = {
      status: 500,
      body: {
        error: "Stack overflow: el enfoque recursivo no soporta nth tan grande. Usa un nth moderado (<= ~7000).",
        nth
      }
    };
    return;
  }
  const elapsed = Date.now() - start;

  context.res = {
    body: {
      nth: nth,
      result: result.toString(),
      wasCached: wasCached,
      computeMs: elapsed,
      cacheSize: memo.size
    }
  };
};
