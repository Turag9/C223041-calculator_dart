# 🧮 Dart Console Calculator

A feature-rich interactive calculator built with **pure Dart** — no dependencies!

---

## ✨ Features

| Feature | Details |
|---|---|
| **Basic Operators** | `+` `-` `*` `/` `%` `^` (power) |
| **Math Functions** | `sin`, `cos`, `tan`, `sqrt`, `log`, `ln`, `abs`, `ceil`, `floor` |
| **Constants** | `pi`, `e` |
| **Memory** | `ms`, `mr`, `mc`, `m+` |
| **History** | Last 50 calculations |
| **`ans` keyword** | Use previous result in next expression |
| **ANSI Colors** | Beautiful colored terminal UI |

---

## 🚀 Run

```bash
dart run bin/calculator.dart
```

Or compile to native binary:

```bash
dart compile exe bin/calculator.dart -o calculator
./calculator
```

---

## 🔧 Usage Examples

```
 >>> 3 + 4 * 2
  = 11

 >>> sin(30) + cos(60)
  = 1

 >>> sqrt(144) ^ 2
  = 144

 >>> (2+3) * (4-1)
  = 15

 >>> ans + 100
  = 115

 >>> ms 42
Memory set to 42.

 >>> mr
Memory: 42

 >>> log(1000)
  = 3

 >>> pi * 5 ^ 2
  = 78.53981634

 >>> history
 1. 3 + 4 * 2 = 11
 2. sin(30) + cos(60) = 1
 ...
```

---

## 📋 Commands

| Command | Description |
|---|---|
| `help` | Show help guide |
| `history` | Show calculation history |
| `clear` | Clear screen |
| `mc` | Memory clear |
| `ms <value>` | Memory store |
| `mr` | Memory recall |
| `m+` | Add last result to memory |
| `exit` / `quit` | Exit the app |
