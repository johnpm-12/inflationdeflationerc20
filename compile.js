// simple script to compile all solidity files in contracts dir

var solc = require('solc');
var fs = require('fs');

// init solc input object, {'file path': 'file content'}
var input = {};

// walk a directory, calling fileFunc on every file and dirFunc on every directory
function walk(dir, fileFunc, dirFunc) {
    for (let file of fs.readdirSync(dir)) {
        let path = dir + '/' + file;
        if (fs.statSync(path).isFile()) {
            fileFunc(path);
        } else {
            dirFunc(path);
        }
    }
}

// add every solidity file to the input object
var fileFunction = (file) => {
    if (file.endsWith('.sol')) {
        input[file] = fs.readFileSync(file, 'utf8');
    }
};

// walk every dir recursively
var dirFunction = (dir) => {
    walk(dir, fileFunction, dirFunction);
};

// walk contracts dir
walk('./contracts', fileFunction, dirFunction);

// compile with optimization enabled
var output = solc.compile({ sources: input }, 1);

// check for and log errors
var fatal = false;
for (let error in output.errors) {
    let message = output.errors[error];
    // check if it's a warning or a fatal error
    if (message.slice(message.indexOf(' ') + 1).startsWith('Warning: ')) {
        console.log(message);
    } else {
        fatal = true;
        console.error(message);
    }
}

if (fatal) {
    console.error('Fatal error on compile. Aborting...');
} else {
    console.log('Writing to ./build...');
    if (!fs.existsSync('./build')) {
        fs.mkdirSync('./build');
    } else {
        // walk recursively and delete empty dirs after everything inside has been deleted
        var dirFunction2 = (dir) => {
            walk(dir, fs.unlinkSync, dirFunction2);
            fs.unlinkSync(dir);
        };
        walk('./build', fs.unlinkSync, dirFunction2);
    }
    // write a .bin and .abi file for every contract with bytecode
    for (let contractName in output.contracts) {
        let bytecode = output.contracts[contractName].bytecode;
        if (bytecode.length > 0) {
            let contractFileName = contractName.slice(contractName.lastIndexOf(':') + 1);
            fs.writeFileSync('./build/' + contractFileName + '.bin', bytecode);
            fs.writeFileSync('./build/' + contractFileName + '.abi', output.contracts[contractName].interface);
        }
    }
}
