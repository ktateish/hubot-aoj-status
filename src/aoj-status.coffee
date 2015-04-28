# Description
#   A hubot script that watch judge results on AOJ
#
# Configuration:
#   N/A
#
# Commands:
#   hubot aoj watch <user> - hubot will watch <user>'s judge results
#
# Author:
#   Katsuyuki Tateishi[kt@wheel.jp]

ws = require('ws')

aoj_status = [
  'CE'
  'WA'
  'TLE'
  'MLE'
  'AC'
  'Waiting'
  'OLE'
  'RE'
  'PE'
  'Running'
  ]
aoj_review_url='http://judge.u-aizu.ac.jp/onlinejudge/review.jsp'
watchlist = {}
aoj = null

aoj_connect = () ->
  aoj = new ws('ws://ionazn.org/status')
  aoj.on 'message', (data, flags) ->
    s = JSON.parse(data)
    id = s.userID
    rc = aoj_status[s.status]
    if rc == 'Waiting' || rc == 'Running'
      return
    sendmsg = (res) ->
      ic = if rc == 'AC' then ':smile:' else ':fearful:'
      pr = "#{s.problemID}: [#{s.problemTitle}]"
      if s.lessonID
        pr = "#{s.lessonID}_#{pr}"
      ref = "#{aoj_review_url}?rid=#{s.runID}"
      res.send "#{ic} #{id} got #{rc} for #{pr}(#{ref})"
    if watchlist[id]
      sendmsg(r) for r in watchlist[id]
  aoj.on 'close', () ->
    setTimeout aoj_connect, 3000

aoj_connect()

memberp = (array, fn) ->
  if fn(item) then item else null for item in array

register = (res) ->
  user = res.match[1]
  if watchlist[user] && memberp(watchlist[user], (obj) -> obj.message.room == res.message.room)
    res.send "I'm already watching #{user.split("").join(" ")}'s judge results on AOJ"
  else
    if watchlist[user]
      watchlist[user].push(res)
    else
      watchlist[user] = [res]
    res.send "I'll watch #{user}'s judge results on AOJ"

module.exports = (robot) ->
  robot.respond /aoj reconnect/, (res) ->
    res.send "Reconnecting..."
    aoj.close()

  robot.respond /aoj watch (.*)/, (res) ->
    register res

  robot.respond /aoj list/, (res) ->
    msg = "I'm watching:"
    msg = "#{msg}\n  #{user.split("").join(" ")}" for user, _ of watchlist
    res.send msg
