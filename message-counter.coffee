redis = require 'redis'

client = redis.createClient(process.argv[3] || 6379, process.argv[2] || '127.0.0.1')
console.log 'running...'

counters = {}

increment = (index) ->
  if !counters[index]
    counters[index] = 1
  else
    counters[index]++

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
  console.log line(maxLength + 7)
  for key, value of counters
    console.log "#{pad(key, maxLength)}   #{value}"
  console.log line(maxLength + 7)

client.psubscribe '*'
messagesSeen = 0
client.on 'pmessage', (pattern, channel, message) ->
  if channel.indexOf('.') == -1
    increment channel
  else
    increment "#{getDocumentCollection(channel)} (document)"
  messagesSeen++
  maybePrint()

printCount = 0
maybePrint = () ->
  if ++printCount >= 1000
    printCount = 0
    console.log "seen #{messagesSeen} messages"

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
