let events = require(`events`)
let fs = require('fs')
let path = require('path')

// const environment = process.env['NODE_ENV'] || 'development'

class devNull {
    info() { };
    error() { };
};

class Tail extends events.EventEmitter {

    constructor(filename, options = {}) {
        super();
        this.filename = filename;
        this.absPath = path.dirname(this.filename);
        this.separator = (options.separator !== undefined) ? options.separator : /[\r]{0,1}\n/;// null is a valid param
        this.fsWatchOptions = options.fsWatchOptions || {};
        this.follow = options['follow'] != undefined ? options['follow'] : true;
        this.logger = options.logger || new devNull();
        this.useWatchFile = options.useWatchFile || false;
        this.flushAtEOF = options.flushAtEOF || false;
        this.encoding = options.encoding || 'utf-8';
        const fromBeginning = options.fromBeginning || false;
        this.nLines = options.nLines || undefined;

        this.logger.info(`Tail starting...`)
        this.logger.info(`filename: ${this.filename}`);
        this.logger.info(`encoding: ${this.encoding}`);

        try {
            fs.accessSync(this.filename, fs.constants.F_OK);
        } catch (err) {
            if (err.code == 'ENOENT') {
                throw err
            }
        }

        this.buffer = '';
        this.internalDispatcher = new events.EventEmitter();
        this.queue = [];
        this.isWatching = false;
        this.pos = 0;

        // this.internalDispatcher.on('next',this.readBlock);
        this.internalDispatcher.on('next', () => {
            this.readBlock();
        });

        let cursor;

        this.logger.info(`fromBeginning: ${fromBeginning}`);
        if (fromBeginning) {
            cursor = 0;
        } else if (this.nLines <= 0) {
            cursor = 0;
        } else if (this.nLines !== undefined) {
            cursor = this.getPositionAtNthLine(this.nLines);
        } else {
            cursor = this.latestPosition();
        }

        if (cursor === undefined) throw new Error("Tail can't initialize.");

        const flush = fromBeginning || (this.nLines != undefined);
        try {
            this.watch(cursor, flush);
        } catch (err) {
            this.logger.error(`watch for ${this.filename} failed: ${err}`);
            this.emit("error", `watch for ${this.filename} failed: ${err}`);
        }
    }

    /**
     * Grabs the index of the last line of text in the format /.*(\n)?/.
     * Returns null if a full line can not be found.
     * @param {string} text
     * @returns {number | null}
     */
    getIndexOfLastLine(text) {

        /**
         * Helper function get the last match as string
         * @param {string} haystack
         * @param {string | RegExp} needle
         * @returns {string | undefined}
         */
        const getLastMatch = (haystack, needle) => {
            const matches = haystack.match(needle);
            if (matches === null) {
                return;
            }

            return matches[matches.length - 1];
        };

        const endSep = getLastMatch(text, this.separator);

        if (!endSep) return null;

        const endSepIndex = text.lastIndexOf(endSep);
        let lastLine;

        if (text.endsWith(endSep)) {
            // If the text ends with a separator, look back further to find the next
            // separator to complete the line

            const trimmed = text.substring(0, endSepIndex);
            const startSep = getLastMatch(trimmed, this.separator);

            // If there isn't another separator, the line isn't complete so
            // so return null to get more data

            if (!startSep) {
                return null;
            }

            const startSepIndex = trimmed.lastIndexOf(startSep);

            // Exclude the starting separator, include the ending separator

            lastLine = text.substring(
                startSepIndex + startSep.length,
                endSepIndex + endSep.length
            );
        } else {
            // If the text does not end with a separator, grab everything after
            // the last separator
            lastLine = text.substring(endSepIndex + endSep.length);
        }

        return text.lastIndexOf(lastLine);
    }

    /**
     * Returns the position of the start of the `nLines`th line from the bottom.
     * Returns 0 if `nLines` is greater than the total number of lines in the file.
     * @param {number} nLines
     * @returns {number}
     */
    getPositionAtNthLine(nLines) {
        const { size } = fs.statSync(this.filename);

        if (size === 0) {
            return 0;
        }
        
        const fd = fs.openSync(this.filename, 'r');
        // Start from the end of the file and work backwards in specific chunks
        let currentReadPosition = size;
        const chunkSizeBytes = Math.min(1024, size);
        const lineBytes = [];

        let remaining = '';

        while (lineBytes.length < nLines) {
            // Shift the current read position backward to the amount we're about to read
            currentReadPosition -= chunkSizeBytes;

            // If negative, we've reached the beginning of the file and we should stop and return 0, starting the
            // stream at the beginning.
            if (currentReadPosition < 0) {
                return 0;
            }

            // Read a chunk of the file and prepend it to the working buffer
            const buffer = Buffer.alloc(chunkSizeBytes);
            const bytesRead = fs.readSync(fd, buffer,
                0,                  // position in buffer to write to
                chunkSizeBytes,     // number of bytes to read
                currentReadPosition // position in file to read from
            );

            // .subarray returns Uint8Array in node versions < 16.x and Buffer
            // in versions >= 16.x. To support both, allocate a new buffer with
            // Buffer.from which accepts both types
            const readArray = buffer.subarray(0, bytesRead);
            remaining = Buffer.from(readArray).toString(this.encoding) + remaining;

            let index = this.getIndexOfLastLine(remaining);

            while (index !== null && lineBytes.length < nLines) {
                const line = remaining.substring(index);

                lineBytes.push(Buffer.byteLength(line));
                remaining = remaining.substring(0, index);

                index = this.getIndexOfLastLine(remaining);
            }
        }

        fs.closeSync(fd);

        return size - lineBytes.reduce((acc, cur) => acc + cur, 0)
    }

    latestPosition() {
        try {
            return fs.statSync(this.filename).size;
        } catch (err) {
            this.logger.error(`size check for ${this.filename} failed: ${err}`);
            this.emit("error", `size check for ${this.filename} failed: ${err}`);
            throw err;
        }
    }

    readBlock() {
        if (this.queue.length >= 1) {
            const block = this.queue[0];
            if (block.end > block.start) {
                let stream = fs.createReadStream(this.filename, { start: block.start, end: block.end - 1, encoding: this.encoding });
                stream.on('error', (error) => {
                    this.logger.error(`Tail error: ${error}`);
                    this.emit('error', error);
                });
                stream.on('end', () => {
                    let _ = this.queue.shift();
                    if (this.queue.length > 0) {
                        this.internalDispatcher.emit('next');
                    }
                    if (this.flushAtEOF && this.buffer.length > 0) {
                        this.emit('line', this.buffer);
                        this.buffer = "";
                    }
                });
                stream.on('data', (d) => {
                    if (this.separator === null) {
                        this.emit("line", d);
                    } else {
                        this.buffer += d;
                        let parts = this.buffer.split(this.separator);
                        this.buffer = parts.pop();
                        for (const chunk of parts) {
                            this.emit("line", chunk);
                        }
                    }
                });
            }
        }
    }

    change() {
        let p = this.latestPosition()
        if (p < this.currentCursorPos) {//scenario where text is not appended but it's actually a w+
            this.currentCursorPos = p
        } else if (p > this.currentCursorPos) {
            this.queue.push({ start: this.currentCursorPos, end: p });
            this.currentCursorPos = p
            if (this.queue.length == 1) {
                this.internalDispatcher.emit("next");
            }
        }
    }

    watch(startingCursor, flush) {
        if (this.isWatching) return;
        this.logger.info(`filesystem.watch present? ${fs.watch != undefined}`);
        this.logger.info(`useWatchFile: ${this.useWatchFile}`);

        this.isWatching = true;
        this.currentCursorPos = startingCursor;
        //force a file flush is either fromBegining or nLines flags were passed.
        if (flush) this.change();

        if (!this.useWatchFile && fs.watch) {
            this.logger.info(`watch strategy: watch`);
            this.watcher = fs.watch(this.filename, this.fsWatchOptions, (e, filename) => { this.watchEvent(e, filename); });
        } else {
            this.logger.info(`watch strategy: watchFile`);
            fs.watchFile(this.filename, this.fsWatchOptions, (curr, prev) => { this.watchFileEvent(curr, prev) });
        }
    }

    rename(filename) {
        //TODO
        //MacOS sometimes throws a rename event for no reason.
        //Different platforms might behave differently.
        //see https://nodejs.org/api/fs.html#fs_fs_watch_filename_options_listener
        //filename might not be present.
        //https://nodejs.org/api/fs.html#fs_filename_argument
        //Better solution would be check inode but it will require a timeout and
        // a sync file read.
        if (filename === undefined || filename !== this.filename) {
            this.unwatch();
            if (this.follow) {
                this.filename = path.join(this.absPath, filename);
                this.rewatchId = setTimeout((() => {
                    try {
                        this.watch(this.currentCursorPos);
                    } catch (ex) {
                        this.logger.error(`'rename' event for ${this.filename}. File not available anymore.`);
                        this.emit("error", ex);
                    }
                }), 1000);
            } else {
                this.logger.error(`'rename' event for ${this.filename}. File not available anymore.`);
                this.emit("error", `'rename' event for ${this.filename}. File not available anymore.`);
            }
        } else {
            // this.logger.info("rename event but same filename")
        }
    }

    watchEvent(e, evtFilename) {
        try {
            if (e === 'change') {
                this.change();
            } else if (e === 'rename') {
                this.rename(evtFilename);
            }
        } catch (err) {
            this.logger.error(`watchEvent for ${this.filename} failed: ${err}`);
            this.emit("error", `watchEvent for ${this.filename} failed: ${err}`);
        }
    }

    watchFileEvent(curr, prev) {
        if (curr.size > prev.size) {
            this.currentCursorPos = curr.size;    //Update this.currentCursorPos so that a consumer can determine if entire file has been handled
            this.queue.push({ start: prev.size, end: curr.size });
            if (this.queue.length == 1) {
                this.internalDispatcher.emit("next");
            }
        }
    }

    unwatch() {
        if (this.watcher) {
            this.watcher.close();
        } else {
            fs.unwatchFile(this.filename);
        }
        if (this.rewatchId) {
            clearTimeout(this.rewatchId);
            this.rewatchId = undefined;
        }
        this.isWatching = false;
        this.queue = [];// TODO: is this correct behaviour?
        if (this.logger) {
            this.logger.info(`Unwatch ${this.filename}`);
        }
    }

}

exports.Tail = Tail
