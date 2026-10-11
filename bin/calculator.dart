import 'dart:io';
import 'dart:math';

// ─────────────────────────────────────────────
//  ANSI Color Codes
// ─────────────────────────────────────────────
const String reset   = '\x1B[0m';
const String bold    = '\x1B[1m';
const String cyan    = '\x1B[36m';
const String green   = '\x1B[32m';
const String yellow  = '\x1B[33m';
const String red     = '\x1B[31m';
const String magenta = '\x1B[35m';
const String blue    = '\x1B[34m';
const String white   = '\x1B[37m';
const String bgBlue  = '\x1B[44m';
const String bgDark  = '\x1B[40m';

// ─────────────────────────────────────────────
//  Calculator State
// ─────────────────────────────────────────────
double _memory     = 0;
List<String> _history = [];

// ─────────────────────────────────────────────
//  Expression Evaluator (Shunting-yard)
// ─────────────────────────────────────────────
class Token {
  final String type;  // 'number' | 'op' | 'func' | 'lparen' | 'rparen'
  final String value;
  const Token(this.type, this.value);
}

List<Token> _tokenize(String expr) {
  final tokens = <Token>[];
  int i = 0;
  expr = expr.trim();

  while (i < expr.length) {
    final ch = expr[i];

    // Skip spaces
    if (ch == ' ') { i++; continue; }

    // Number (including decimals and unary minus handled separately)
    if (RegExp(r'[0-9.]').hasMatch(ch)) {
      int j = i;
      while (j < expr.length && RegExp(r'[0-9.]').hasMatch(expr[j])) j++;
      tokens.add(Token('number', expr.substring(i, j)));
      i = j;
      continue;
    }

    // Functions: sin, cos, tan, log, sqrt, abs
    if (RegExp(r'[a-z]').hasMatch(ch)) {
      int j = i;
      while (j < expr.length && RegExp(r'[a-z]').hasMatch(expr[j])) j++;
      tokens.add(Token('func', expr.substring(i, j)));
      i = j;
      continue;
    }

    if (ch == '(') { tokens.add(Token('lparen', '(')); i++; continue; }
    if (ch == ')') { tokens.add(Token('rparen', ')')); i++; continue; }

    // Operators: handle unary minus
    if ('+-*/%^'.contains(ch)) {
      // Unary minus: at start OR after '(' or another operator
      if (ch == '-' &&
          (tokens.isEmpty ||
           tokens.last.type == 'lparen' ||
           tokens.last.type == 'op')) {
        tokens.add(Token('number', '-1'));
        tokens.add(Token('op', '*'));
      } else {
        tokens.add(Token('op', ch));
      }
      i++;
      continue;
    }

    throw FormatException('Unknown character: $ch');
  }
  return tokens;
}

int _precedence(String op) {
  switch (op) {
    case '+': case '-': return 1;
    case '*': case '/': case '%': return 2;
    case '^': return 3;
    default: return 0;
  }
}

double _applyOp(String op, double a, double b) {
  switch (op) {
    case '+': return a + b;
    case '-': return a - b;
    case '*': return a * b;
    case '/':
      if (b == 0) throw Exception('Division by zero!');
      return a / b;
    case '%': return a % b;
    case '^': return pow(a, b).toDouble();
    default: throw Exception('Unknown operator: $op');
  }
}

double _applyFunc(String func, double arg) {
  switch (func) {
    case 'sin':  return sin(arg * pi / 180);
    case 'cos':  return cos(arg * pi / 180);
    case 'tan':  return tan(arg * pi / 180);
    case 'log':  return log(arg) / ln10;
    case 'ln':   return log(arg);
    case 'sqrt': return sqrt(arg);
    case 'abs':  return arg.abs();
    case 'ceil': return arg.ceilToDouble();
    case 'floor':return arg.floorToDouble();
    default: throw Exception('Unknown function: $func');
  }
}

/// Evaluate a mathematical expression string.
double evaluate(String expr) {
  // Replace constants
  expr = expr
      .replaceAll('pi', '3.141592653589793')
      .replaceAll('e',  '2.718281828459045')
      .toLowerCase();

  final tokens = _tokenize(expr);
  final output  = <double>[];
  final opStack = <String>[];   // operators & functions
  final typeStack = <String>[]; // 'op' | 'func'

  void popOp() {
    if (typeStack.last == 'func') {
      final func = opStack.removeLast();
      typeStack.removeLast();
      if (output.isEmpty) throw Exception('Not enough arguments for $func');
      output.add(_applyFunc(func, output.removeLast()));
    } else {
      final op = opStack.removeLast();
      typeStack.removeLast();
      if (output.length < 2) throw Exception('Not enough operands');
      final b = output.removeLast();
      final a = output.removeLast();
      output.add(_applyOp(op, a, b));
    }
  }

  for (final tok in tokens) {
    if (tok.type == 'number') {
      output.add(double.parse(tok.value));
    } else if (tok.type == 'func') {
      opStack.add(tok.value);
      typeStack.add('func');
    } else if (tok.type == 'op') {
      while (opStack.isNotEmpty &&
             typeStack.last == 'op' &&
             (_precedence(opStack.last) > _precedence(tok.value) ||
              (_precedence(opStack.last) == _precedence(tok.value) && tok.value != '^'))) {
        popOp();
      }
      opStack.add(tok.value);
      typeStack.add('op');
    } else if (tok.type == 'lparen') {
      opStack.add('(');
      typeStack.add('lparen');
    } else if (tok.type == 'rparen') {
      while (opStack.isNotEmpty && opStack.last != '(') popOp();
      if (opStack.isEmpty) throw Exception('Mismatched parentheses');
      opStack.removeLast(); // pop '('
      typeStack.removeLast();
      if (opStack.isNotEmpty && typeStack.last == 'func') popOp();
    }
  }

  while (opStack.isNotEmpty) {
    if (opStack.last == '(') throw Exception('Mismatched parentheses');
    popOp();
  }

  if (output.isEmpty) throw Exception('Empty expression');
  return output.last;
}

// ─────────────────────────────────────────────
//  UI Helpers
// ─────────────────────────────────────────────
void clearScreen() => stdout.write('\x1B[2J\x1B[H');

void printBanner() {
  clearScreen();
  print('$bgBlue$bold$white');
  print('  ╔══════════════════════════════════════╗  ');
  print('  ║       🧮  DART CALCULATOR  🧮         ║  ');
  print('  ╚══════════════════════════════════════╝  ');
  print(reset);
}

void printHelp() {
  print('''
$cyan$bold━━━━━━━━━━ OPERATORS ━━━━━━━━━━$reset
  $yellow+  -  *  /  %  ^$reset   (^ = power)

$cyan$bold━━━━━━━━━━ FUNCTIONS ━━━━━━━━━━$reset
  ${yellow}sin(x)   cos(x)   tan(x)$reset   (degrees)
  ${yellow}sqrt(x)  log(x)   ln(x)$reset
  ${yellow}abs(x)   ceil(x)  floor(x)$reset

$cyan$bold━━━━━━━━━━ CONSTANTS ━━━━━━━━━━$reset
  ${yellow}pi$reset  → 3.14159...   ${yellow}e$reset → 2.71828...

$cyan$bold━━━━━━━━━━ COMMANDS ━━━━━━━━━━$reset
  ${green}history$reset        → Calculation history
  ${green}clear$reset          → Clear screen
  ${green}mc$reset             → Memory clear
  ${green}ms <value>$reset     → Memory store
  ${green}mr$reset             → Memory recall
  ${green}m+$reset             → Add last result to memory
  ${green}help$reset           → Show this help
  ${green}exit / quit$reset    → Exit app

$cyan$bold━━━━━━━━━━ EXAMPLES ━━━━━━━━━━$reset
  $white3 + 4 * 2$reset          → ${yellow}11$reset
  ${white}sin(30) + cos(60)$reset  → ${yellow}1$reset
  ${white}sqrt(144) ^ 2$reset     → ${yellow}144$reset
  ${white}(2+3) * (4-1)$reset     → ${yellow}15$reset
''');
}

String _formatResult(double result) {
  if (result == result.truncateToDouble() && result.abs() < 1e15) {
    return result.toInt().toString();
  }
  // Up to 10 significant digits, remove trailing zeros
  String s = result.toStringAsPrecision(10);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

void printHistory() {
  if (_history.isEmpty) {
    print('${yellow}No history yet.$reset');
    return;
  }
  print('\n$cyan$bold━━━━━━━━━━ HISTORY ━━━━━━━━━━$reset');
  for (int i = 0; i < _history.length; i++) {
    print('  $white${i + 1}. ${_history[i]}$reset');
  }
  print('');
}

// ─────────────────────────────────────────────
//  Main Loop
// ─────────────────────────────────────────────
void main() {
  double lastResult = 0;

  printBanner();
  print('${green}Welcome! Type $bold"help"$reset$green for usage guide.$reset\n');

  while (true) {
    stdout.write('$cyan$bold >>> $reset');
    final raw = stdin.readLineSync();
    if (raw == null) break; // EOF

    final input = raw.trim();
    if (input.isEmpty) continue;

    // ── Commands ──────────────────────────────
    switch (input.toLowerCase()) {
      case 'exit':
      case 'quit':
        print('\n${magenta}Goodbye! 👋$reset\n');
        exit(0);

      case 'help':
        printHelp();
        continue;

      case 'history':
        printHistory();
        continue;

      case 'clear':
        printBanner();
        continue;

      case 'mc':
        _memory = 0;
        print('${green}Memory cleared.$reset\n');
        continue;

      case 'mr':
        print('${yellow}Memory: ${_formatResult(_memory)}$reset\n');
        continue;

      case 'm+':
        _memory += lastResult;
        print('${green}Added $lastResult to memory. Memory = ${_formatResult(_memory)}$reset\n');
        continue;
    }

    // ms <value>
    if (input.toLowerCase().startsWith('ms ')) {
      final valStr = input.substring(3).trim();
      try {
        _memory = double.parse(valStr);
        print('${green}Memory set to ${_formatResult(_memory)}.$reset\n');
      } catch (_) {
        print('${red}Invalid value for ms.$reset\n');
      }
      continue;
    }

    // ── Evaluate Expression ────────────────────
    // Replace 'ans' with last result
    final expr = input.replaceAll(RegExp(r'\bans\b', caseSensitive: false),
        lastResult.toString());

    try {
      final result = evaluate(expr);
      lastResult = result;
      final formatted = _formatResult(result);

      final historyEntry = '$input = $formatted';
      _history.add(historyEntry);
      if (_history.length > 50) _history.removeAt(0);

      print('$green$bold  = $formatted$reset\n');
    } on FormatException catch (e) {
      print('${red}Syntax Error: ${e.message}$reset\n');
    } catch (e) {
      print('${red}Error: $e$reset\n');
    }
  }
}
