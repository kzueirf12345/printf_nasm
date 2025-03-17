# Printme

В данном репозитории реализована урезанная версия функции `printf` из стандартной библиотеки C, с ограниченным набором спецификаторов. Функция написана на ассемблере `nasm` и поддерживает и следует стандарту вызовов **System V AMD64 ABI**, а значит может быть использована в проектах на **UNIX-подобных системах** с **64-битной** архитектурой.

## Структура проекта

- **`src/main.c`**: Пример использования функции `printme`.
- **`src/printme.asm`**: Код функции `printme` на ассемблере.
- **`Makefile`**: Пример сборки и линковки функции `printme` с проектом на C.

## Описание функции

Функция `printme` принимает форматную строку и переменное количество аргументов, обрабатывает спецификаторы и выводит результат в стандартный вывод. Возвращаемое значение — код ошибки в формате `long`.

> **Внимание!** Функция `printme` не поддерживает статическую проверку соответствия количества аргументов и их типов со спецификаторами форматной строки. Будьте внимательны!

### Поддерживаемые спецификаторы

- `%c`: Символ (`char`).
- `%d`: Десятичное число (`int64_t`).
- `%b`: Двоичное число (`uint64_t`).
- `%o`: Восьмеричное число (`uint64_t`).
- `%x`: Шестнадцатеричное число (`uint64_t`).
- `%s`: Строка (`char*`).
- `%n`: Сохраняет количество выведенных символов в указанную переменную (`uint64_t*`).
- `%%`: Выводит символ `%`.

### Возвращаемые ошибки

- **0 -** `NO_ERROR`: Корректное завершение функции.
- **1 -** `ERROR_INCORRECT_SPECIFER`: Некорректный спецификатор формата.
- **2 -** `ERROR_SYSCALL`: Ошибка системного вызова.

## Алгоритм работы функции `printme`

Функция `printme` работает следующим образом:

1. **Инициализация**:
   - Функция начинается с сохранения адреса возврата и аргументов в стеке.
   - Регистр `rsi` указывает на начало форматной строки.
   - Адрес начала аргументов сохраняем в регистр `r8`.

2. **Обработка форматной строки**:
   - Функция проходит по каждому символу форматной строки.
   - Если символ не является спецификатором (`%`), он выводится напрямую.
   - Если символ `%` обнаружен, функция переходит к обработке спецификатора.

3. **Обработка спецификаторов**:
   - Для каждого спецификатора используется jump-таблица (`.SpeciferTable`), которая связывает символы спецификаторов с соответствующими обработчиками.
   - В зависимости от спецификатора, вызывается соответствующий обработчик

4. **Оптимизация для числовых типов с основанием степени двойки**:
   - Для спецификаторов `%b`, `%o` и `%x` используется функция `HandleNum2`.
   - Вместо деления на основание системы счисления, используются битовые сдвиги, что значительно ускоряет процесс преобразования числа в строку.

5. **Обработка строки (`%s`)**:
   - Функция `HandleString` обрабатывает спецификатор `%s`.
   - Переданный аргумент интерпретируется как указатель на строку (адрес начала строки).
   - Функция вычисляет длину строки, проходя по ней до символа `\0`.
   - Строка выводится с помощью функции `PrintData`, которая добавляет её в буфер или выводит напрямую, если буфер переполнен.

6. **Обработка `%n`**:
   - Спецификатор `%n` не выводит данные, а сохраняет количество уже выведенных символов в переменную, переданную по указателю.
   - Функция извлекает указатель из аргументов и записывает в него значение из переменной `CntPrintedSymbols`, которая хранит текущее количество выведенных символов.

7. **Буферизация вывода**:
   - Для оптимизации вывода используется буфер размером 64 байта.
   - Если буфер переполняется, его содержимое выводится с помощью системного вызова `sys_write`.

8. **Завершение**:
   - После обработки всей форматной строки оставшиеся данные в буфере выводятся.
   - Функция возвращает код ошибки.

## Сборка и запуск

### Требования

Для сборки проекта необходимо установить:

- `nasm`
- `gcc`
- `make`

### Сборка проекта

1. Клонируйте репозиторий или скопируйте файлы проекта в рабочую директорию.
2. Перейдите в директорию проекта.
3. Выполните команду для сборки проекта:

   ```bash
   make
   ```

   Эта команда создаст исполняемый файл `printf_nasm.out`.

### Запуск проекта

После успешной сборки выполните команду для запуска программы:

```bash
make start
```

Или напрямую запустите исполняемый файл:

```bash
./printf_nasm.out
```

### Очистка проекта

Для удаления сгенерированных файлов выполните команду:

```bash
make clean_all
```