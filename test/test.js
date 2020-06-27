let fs = require("fs")
let path = require("path")
let Tail = require('../src/tail').Tail
let expect = require('chai').expect
let exec = require("child_process").exec
const fileToTest = path.join(__dirname, 'example.txt');

describe('Tail', function () {
    beforeEach(done => {
        fs.writeFile(fileToTest, '', done)
    });

    afterEach(function (done) {
        fs.access(fileToTest, fs.constants.F_OK, function (err) {
            if (!err) {
                fs.unlink(fileToTest, done);
            } else {
                done();
            }
        });
    });

    const lineEndings = [{ le: '\r\n', desc: "Windows" }, { le: '\n', desc: "Linux" }]
    lineEndings.forEach(({ le, desc }) => {
        it('should read a file with ' + desc + ' line ending', function (done) {
            const text = `This is a ${desc} line ending  ${le}`;
            const nbOfLineToWrite = 100;
            let nbOfReadLines = 0;

            const fd = fs.openSync(fileToTest, 'w+');

            const tailedFile = new Tail(fileToTest, { fsWatchOptions: { interval: 100 } });

            tailedFile.on('line', function (line) {
                expect(line).to.be.equal(text.replace(/[\r\n]/g, ''));
                nbOfReadLines++;

                if (nbOfReadLines === nbOfLineToWrite) {
                    tailedFile.unwatch();
                    done();
                }
            });

            for (let index = 0; index < nbOfLineToWrite; index++) {
                fs.writeSync(fd, text);
            };
            fs.closeSync(fd);
        });
    });

    it('should handle null separator option to not split chunks', function (done) {
        const text = "This is \xA9test and 22\xB0 C";

        let fd = fs.openSync(fileToTest, 'w+');

        let tailedFile = new Tail(fileToTest, { separator: null, fsWatchOptions: { interval: 100 }, logger: console });

        tailedFile.on('line', function (line) {
            expect(line).to.be.equal(`${text}${text}`);
            tailedFile.unwatch();
            done();
        });

        fs.writeSync(fd, text);
        fs.writeSync(fd, text);
        fs.closeSync(fd);
    });

    it('should respect fromBeginning flag', function (done) {
        const fd = fs.openSync(fileToTest, 'w+');
        const lines = ['line  0', 'line  1'];
        let readLines = [];

        const tailedFile = new Tail(fileToTest, { fromBeginning: true, fsWatchOptions: { interval: 100 }, logger: console });
        tailedFile.on('line', function (line) {
            readLines.push(line);
            if (readLines.length == lines.length) {
                let match = readLines.reduce(function (acc, val, idx) {
                    return acc && (val == lines[idx]);
                }, true);

                if (match) {
                    tailedFile.unwatch();
                    done();
                }
            };
        });

        for (const l of lines) {
            fs.writeSync(fd, l + '\n')
        }
        fs.closeSync(fd);
    });

    it('should respect fromBeginning from even the first appended line', function (done) {
        let fd = fs.openSync(fileToTest, 'w+');
        const lines = ['line0', 'line1'];
        for (const l of lines) {
            fs.writeSync(fd, l + '\n');
        }

        fs.closeSync(fd);

        let readLines = [];
        const tailedFile = new Tail(fileToTest, { fromBeginning: true, fsWatchOptions: { interval: 100 } })
        tailedFile.on('line', function (line) {
            readLines.push(line);
            let match;
            if (readLines.length === lines.length) {
                match = readLines.reduce(function (acc, val, idx) {
                    return acc && (val === lines[idx]);
                }, true);
            };
            if (match) {
                tailedFile.unwatch();
                done();
            }
        });
    });

    it('should send error event on deletion of file while watching', function (done) {
        let text = "This is a line\n";
        let fd = fs.openSync(fileToTest, 'w+');
        const tailedFile = new Tail(fileToTest, { fsWatchOptions: { interval: 100 } });

        //ensure error gets called when the file is deleted
        tailedFile.on('error', function (_) {
            tailedFile.unwatch();
            done();
        });
        tailedFile.on('line', function (_) {
            fs.unlinkSync(fileToTest);
        });

        fs.writeSync(fd, text);
        fs.closeSync(fd);
    });

    it('should throw exception if file is missing', function(done) {
        try {
            new Tail("missingFile.txt", { fsWatchOptions: { interval: 100 }, logger: console });
        } catch (ex) {
            expect(ex.code).to.be.equal('ENOENT');
            done();
        }
    });

    it('should deal with file rename', function(done) {
     this.timeout(5000);
     const text = "This is a line\n";

     let tailedFile = new Tail( fileToTest, { fsWatchOptions: { interval: 100 }, logger: console });

     tailedFile.on('line', function(l) {
       done();
       tailedFile.unwatch();
     });

     const newName = path.join( __dirname, 'example2.txt');
     exec(`mv ${fileToTest} ${newName}`);

     let writeMore = function() {
       let fdNew = fs.openSync( newName, 'w+');
       fs.writeSync( fdNew, text);
       fs.closeSync( fdNew)
     };
     setTimeout( writeMore, 1500);

     after(function() {
         fs.unlinkSync(newName);
     });
    });
});
