const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');

// Получаем путь к файлу из аргументов
const filePath = process.argv[2];

// Определяем путь к babel
const babelPath = path.join(__dirname, 'node_modules/.bin/babel');

// Обработка для Core файлов
if (filePath.includes('Core/sites/admin-cabinet/assets/js/src/')) {
  // Находим индекс js/src в пути
  const srcIndex = filePath.indexOf('js/src/');
  
  // Получаем базовую часть пути (до js/src)
  const basePath = filePath.substring(0, srcIndex);
  
  // Получаем часть пути после js/src/
  const relativePath = filePath.substring(srcIndex + 7); // 7 = длина 'js/src/'
  
  // Создаем выходной путь в js/pbx с той же структурой подпапок
  const relativeDirPath = path.dirname(relativePath);
  const outputDir = path.join(basePath, 'js/pbx', relativeDirPath);

  // Убедимся, что директория существует
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
    console.log(`Создана директория: ${outputDir}`);
  }

  // Запускаем babel
  try {
    const cmd = `"${babelPath}" "${filePath}" --out-dir "${outputDir}" --source-maps inline --presets airbnb`;
    console.log(`Выполняем команду: ${cmd}`);
    execSync(cmd, { stdio: 'inherit' });
    
    const fileNameWithoutExt = path.basename(filePath, '.js');
    const outputFile = path.join(outputDir, `${fileNameWithoutExt}.js`);
    
    console.log(`Успешно скомпилировано: ${filePath} -> ${outputFile}`);
  } catch (error) {
    console.error(`Ошибка компиляции: ${error.message}`);
    process.exit(1);
  }
}
// Обработка для Extensions
else if (filePath.includes('Extensions/') && filePath.includes('/public/assets/js/src/')) {
  // Находим последний индекс /src/
  const srcPos = filePath.lastIndexOf('/src/');
  
  // Получаем директорию src
  const srcDir = filePath.substring(0, srcPos + 5); // +5 чтобы включить '/src/'
  
  // Создаем выходной путь (родительская директория src)
  const outputDir = path.dirname(srcDir);
  
  // Запускаем babel
  try {
    const cmd = `"${babelPath}" "${filePath}" --out-dir "${outputDir}" --source-maps inline --presets airbnb`;
    console.log(`Выполняем команду для Extensions: ${cmd}`);
    execSync(cmd, { stdio: 'inherit' });
    
    const fileNameWithoutExt = path.basename(filePath, '.js');
    const outputFile = path.join(outputDir, `${fileNameWithoutExt}.js`);
    
    console.log(`Успешно скомпилировано (Extensions): ${filePath} -> ${outputFile}`);
  } catch (error) {
    console.error(`Ошибка компиляции (Extensions): ${error.message}`);
    process.exit(1);
  }
}
else {
  console.log(`Файл ${filePath} не соответствует ни одному из паттернов, пропускаем`);
}