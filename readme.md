Redis Message Counter
=====================

To use:
```
$ npm install
$ npm install -g coffee-script
$ coffee message-counter.coffee [host] [port]
```

Host and port are optional. The script will print statistics every 500 redis messages it sees. When you hit ctrl+c to exit, it will print out final statistics and clean up the redis connection before exiting.
