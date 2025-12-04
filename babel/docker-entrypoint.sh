#!/bin/sh
set -e

# Путь к файлу, переданному из хоста
INPUT_FILE="$1"
OUTPUT_TYPE="$2"

# Определение типа файла и соответствующего выходного пути
if echo "$INPUT_FILE" | grep -q "Core/sites/admin-cabinet/assets/js/src/"; then
    # Для Core JS файлов
    SRC_DIR=$(echo "$INPUT_FILE" | sed -E 's|(.*/js)/src/(.*)|\1|')
    REL_PATH=$(echo "$INPUT_FILE" | sed -E 's|.*/js/src/(.*)|\1|')
    REL_DIR=$(dirname "$REL_PATH")
    OUTPUT_DIR="${SRC_DIR}/pbx/${REL_DIR}"
elif echo "$INPUT_FILE" | grep -q "Extensions/.*/public/assets/js/src/"; then
    # Для Extensions файлов
    OUTPUT_DIR=$(echo "$INPUT_FILE" | sed -E 's|(.*/js)/src/(.*)|\1|')
elif echo "$INPUT_FILE" | grep -q ".*/sites/admin-cabinet/assets/js/src/"; then
    # Для Projects JS файлов
    SRC_DIR=$(echo "$INPUT_FILE" | sed -E 's|(.*/js)/src/(.*)|\1|')
    REL_PATH=$(echo "$INPUT_FILE" | sed -E 's|.*/js/src/(.*)|\1|')
    REL_DIR=$(dirname "$REL_PATH")
    OUTPUT_DIR="${SRC_DIR}/pbx/${REL_DIR}"

else
    echo "Неизвестный тип файла: $INPUT_FILE"
    exit 1
fi

# Создаем выходную директорию
mkdir -p "$OUTPUT_DIR"

# Запускаем babel
./node_modules/.bin/babel "$INPUT_FILE" --out-dir "$OUTPUT_DIR" --source-maps inline --presets airbnb

echo "Компиляция завершена: $INPUT_FILE -> $OUTPUT_DIR"