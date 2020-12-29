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
        this.follow = options.follow || true;
        this.logger = options.logger || new devNull();
        this.useWatchFile = options.useWatchFile || false;
        this.flushAtEOF = options.flushAtEOF || false;
        this.encoding = options.encoding || `utf-8`;
        const fromBeginning = options.fromBeginning || false;


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

        this.logger.info(`fromBeginning: ${fromBeginning}`);
        let startingPos = undefined;
        if (fromBeginning) {
            startingPos = 0;
            //if fromBeginning triggers a check for content to flush the existing file
            //without waiting for a new appended line
            this.change(this.filename);
        } 
        this.watch(startingPos);
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

    change(filename) {
        let p = this.latestPosition()
        if (p < this.pos) {//scenario where text is not appended but it's actually a w+
            this.pos = p
        } else if (p > this.pos) {
            this.queue.push({ start: this.pos, end: p});
            this.pos = p
            if (this.queue.length == 1) {
                this.internalDispatcher.emit("next");
            }
        }
    }

    watch(startingPos) {
        if (this.isWatching) {
            return
        }
        this.logger.info(`filesystem.watch present? ${fs.watch != undefined}`);
        this.logger.info(`useWatchFile: ${this.useWatchFile}`);

        this.isWatching = true;
        this.pos = (startingPos === undefined) ? this.latestPosition() : startingPos;

        try {
            if (!this.useWatchFile && fs.watch) {
                this.logger.info(`watch strategy: watch`);
                this.watcher = fs.watch(this.filename, this.fsWatchOptions, (e, filename) => { this.watchEvent(e, filename); });
    
            } else {
                this.logger.info(`watch strategy: watchFile`);
                fs.watchFile(this.filename, this.fsWatchOptions, (curr, prev) => { this.watchFileEvent(curr, prev) });
            }
        } catch (err) {
            this.logger.error(`watch for ${this.filename} failed: ${err}`);
            this.emit("error", `watch for ${this.filename} failed: ${err}`);
            return
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
                    this.watch(this.pos); 
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
        if (e === 'change') {
            this.change(this.filename);
        } else if (e === 'rename') {
            this.rename(evtFilename);
        }
    }

    watchFileEvent(curr, prev) {
        if (curr.size > prev.size) {
            this.pos = curr.size;    //Update this.pos so that a consumer can determine if entire file has been handled
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
