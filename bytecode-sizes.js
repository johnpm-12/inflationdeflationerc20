// simple script to check the bytecode sizes of compiled contracts in build dir
// max contract size is 24576 bytes https://github.com/ethereum/EIPs/blob/master/EIPS/eip-170.md

var fs = require('fs');

let files = [];

// push bytecode size and name of every file in build to files array
for (let file of fs.readdirSync('./build')) {
    let path = './build/' + file;
    if (fs.statSync(path).isFile() && file.endsWith('.bin')) {
        let bytecode = fs.readFileSync(path, 'utf8');
        files.push([bytecode.length / 2, file]);
    }
}

// sort by bytecode size
files.sort((a, b) => {
    return b[0] - a[0];
});

for (let file of files) {
    console.log(file[1] + ': ' + file[0] + ' bytes');
}
