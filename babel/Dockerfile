FROM node:18-alpine

WORKDIR /app

# Копируем только файлы зависимостей для эффективного кэширования слоев
COPY package*.json babel.config.json ./

# Устанавливаем зависимости
RUN npm install

# Создаем скрипт-обертку для babel
COPY babel-compile.js ./

# Создаем точку входа
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]