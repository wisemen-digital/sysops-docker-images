const args = process.argv.slice(2);
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

console.log('Running worker…');
console.log('Command line arguments:', args);

(async () => {
  while (true) {
    console.log('Checking for jobs…');
    await sleep(30000);
  }
})();
