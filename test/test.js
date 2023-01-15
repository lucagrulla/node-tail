let fs = require("fs")
let path = require("path")
let Tail = require('../src/tail').Tail
let expect = require('chai').expect
let assert = require('chai').assert
let exec = require("child_process").exec
const os = require("os")
const fileToTest = path.join(__dirname, 'example.txt');

describe('Tail', function () {
    beforeEach(function (done) {
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

        let tailedFile = new Tail(fileToTest, { separator: null, fsWatchOptions: { interval: 100 } });

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
        this.timeout(10000);
        const fd = fs.openSync(fileToTest, 'w+');
        const lines = ['line  0', 'line  1', 'line  2', 'line  3'];
        for (const l of lines) {
            fs.writeSync(fd, l + os.EOL)
        }
        fs.closeSync(fd);


        let readLines = [];

        //the additional timeout is required to avoid an odd behaviour where the file will results changed for no reason
        setTimeout(function () {
            const tailedFile = new Tail(fileToTest, { fromBeginning: true });
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

        }, 3000);


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
        // let text = "This is a line\n";
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

        fs.writeSync(fd, "This is a line\n");
        fs.closeSync(fd);
    });

    it('should throw exception if file is missing', function (done) {
        try {
            new Tail("missingFile.txt", { fsWatchOptions: { interval: 100 } });
        } catch (ex) {
            expect(ex.code).to.be.equal('ENOENT');
            done();
        }
    });

    it('should deal with file rename', function (done) {
        this.timeout(5000);
        const text = "This is a line\n";

        let tailedFile = new Tail(fileToTest, { fsWatchOptions: { interval: 100 } });

        tailedFile.on('line', function (l) {
            done();
            tailedFile.unwatch();
            fs.unlinkSync(newName);
        });

        const newName = path.join(__dirname, 'example2.txt');
        exec(`mv ${fileToTest} ${newName}`);

        let writeMore = function () {
            let fdNew = fs.openSync(newName, 'w+');
            fs.writeSync(fdNew, text);
            fs.closeSync(fdNew)
        };
        setTimeout(writeMore, 1500);
    });

    it('should emit lines in the right order', function (done) {
        const fd = fs.openSync(fileToTest, 'w+');
        const linesNo = 250000;

        const tailedFile = new Tail(fileToTest, { fromBeginning: true, fsWatchOptions: { interval: 100 } });
        let count = 0;
        tailedFile.on('line', function (l) {
            assert.equal(l, count);
            count++;
            if (count == linesNo) {
                tailedFile.unwatch();
                done();
            }
        });

        for (let i = 0; i < linesNo; i++) {
            fs.writeSync(fd, `${i}\n`);
        }
        fs.closeSync(fd);
    });

    it('should not lose data between rename events', function (done) {
        this.timeout(10000);
        const fd = fs.openSync(fileToTest, 'w+');
        const newName = path.join(__dirname, 'example2.txt');

        const tailedFile = new Tail(fileToTest, { fromBeginning: true, fsWatchOptions: { interval: 100 } });
        let readNo = 0;
        tailedFile.on('line', function (l) {
            assert.equal(l, readNo);
            readNo++;
            if (readNo == 30) {
                fs.closeSync(fd);
                clearInterval(id);
                tailedFile.unwatch();
                fs.unlinkSync(newName);
                done();
            }
        });

        let writeNo = 0;
        let id = setInterval(() => {
            fs.writeSync(fd, `${writeNo}\n`);
            writeNo++;
        }, 50);

        setTimeout(() => {
            exec(`mv ${fileToTest} ${newName}`);
        }, 250);
    });

    describe('nLines', () => {
        it(`should gracefully handle an empty file`, function (done) {
            const n = 3;
            const tailedFile = new Tail(fileToTest, { nLines: n, flushAtEOF: true, fsWatchOptions: { interval: 100 } });
            tailedFile.unwatch();
            done();
        });

        lineEndings.forEach(({ le, desc }) => {
            it(`should respect nLines when a file with ${desc} line endings ends with a newline`, function (done) {
                const fd = fs.openSync(fileToTest, 'w+');
                let tokens = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
                const input = tokens.reduce((acc, n) => { return `${acc}${n}${le}` }, "");
                fs.writeSync(fd, input);

                const n = 3;
                const tailedFile = new Tail(fileToTest, { nLines: n, flushAtEOF: true, fsWatchOptions: { interval: 100 } });
                let counter = 1;
                const toBePrinted = tokens.slice(tokens.length - n);
                tailedFile.on('line', (l) => {
                    assert.equal(parseInt(l), toBePrinted[counter - 1]);
                    if (counter == toBePrinted.length) {
                        done();
                        fs.closeSync(fd);
                        tailedFile.unwatch();
                    }
                    counter++;
                })
            });

            it(`should respect nLines when afile with ${desc} line endings does not end with newline`, function (done) {
                const fd = fs.openSync(fileToTest, 'w+');
                const tokens = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
                const input = tokens.reduce((acc, n, i) => {
                    let t = (i == tokens.length - 1) ? n : `${n}${le}`;
                    return `${acc}${t}`;
                }, "");
                fs.writeSync(fd, input);

                const n = 3;

                const tailedFile = new Tail(fileToTest, { nLines: n, flushAtEOF: true, fsWatchOptions: { interval: 100 } });

                const toBePrinted = tokens.slice(tokens.length - n);
                let counter = 1;
                tailedFile.on('line', (l) => {
                    assert.equal(parseInt(l), toBePrinted[counter - 1]);
                    if (counter == toBePrinted.length) {
                        done();
                        fs.closeSync(fd);
                        tailedFile.unwatch();
                    }
                    counter++;
                })
            });
        })
    });

    it('should throw a catchable exception if tailed file disappears', function (done) {
        let fd = fs.openSync(fileToTest, 'w+');
        const lines = ['line0', 'line1'];
        for (const l of lines) {
            fs.writeSync(fd, l + '\n');
        }
        fs.closeSync(fd);
        const tailedFile = new Tail(fileToTest, { flushAtEOF: true, logger: console, fsWatchOptions: { interval: 100 } });
        tailedFile.on('error', (e) => {
            assert.equal(e.code, "ENOENT")
            done()
        });

    setTimeout(() => {
        fs.unlinkSync(fileToTest);
    }, 2000);
});
});
