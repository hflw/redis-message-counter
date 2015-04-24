redis = require 'redis'
sizeof = require 'object-sizeof'

client = redis.createClient(process.argv[3] || 6379, process.argv[2] || '127.0.0.1')
console.log 'running...'

counters = {}
sizes = {}

increment = (index, message) ->
  if !counters[index]
    counters[index] = 1
    sizes[index] = sizeof(message)
  else
    counters[index]++
    sizes[index] += sizeof(index)

getDocumentCollection = (str) ->
  str.substring 0, str.indexOf('.')

pad = (str, count) ->
  while str.length < count
    str += ' '
  str

line = (length) ->
  l = '\n-'
  while l.length-1 < length
    l += '-'
  l+'\n'

getBiggestKeyLength = (obj) ->
  length = -Infinity
  for key of obj
    len = key.length
    if len > length
      length = len
  length

print = () ->
  maxLength = getBiggestKeyLength counters
  console.log line(maxLength + 22)
  for key, value of counters
    console.log "#{pad(key, maxLength)}   #{pad(value+'', 7)}  #{pad(Math.round(sizes[key]/1024), 5)} kB"
  console.log line(maxLength + 22)

client.psubscribe '*'
messagesSeen = 0
client.on 'pmessage', (pattern, channel, message) ->
  if channel.indexOf('.') == -1
    increment channel, message
  else
    increment "#{getDocumentCollection(channel)} (document)", message
  messagesSeen++
  maybePrint()

printCount = 0
maybePrint = () ->
  if ++printCount >= 500
    printCount = 0
    console.log "seen #{messagesSeen} messages"
    print()

startTime = new Date()
process.on 'SIGINT', () ->
  endTime = new Date()
  client.punsubscribe()
  client.end()
  # final stats
  print()
  elapsedSeconds = Math.round((endTime.getTime() - startTime.getTime()) / 1000)
  console.log "elapsed time: #{(elapsedSeconds/60).toFixed(2)} minutes"
  console.log "messages seen: #{messagesSeen}"
  console.log "throughput: #{(messagesSeen / elapsedSeconds).toFixed(2)} messages/s"
  console.log ''
