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
aoj = new ws('ws://ionazn.org/status')
aoj_status = [
  'CE'
  'WA'
  'TLE'
  'MLE'
  'AC'
  'Wating'
  'OLE'
  'RE'
  'PE'
  'Running'
  ]
aoj_review_url='http://judge.u-aizu.ac.jp/onlinejudge/review.jsp'
watching = {}

module.exports = (robot) ->
  robot.respond /aoj watch (.*)/, (res) ->
    who = res.match[1]
    if watching[who]
      res.send "I'm already watching #{who}'s judge results on AOJ"
    else
      res.send "I'll watch #{who}'s judge results on AOJ"
      watching[who] = true
      aoj.on 'message', (data, flags) ->
        s = JSON.parse(data)
        id = s.userID
        rc = aoj_status[s.status]
        if id == who && rc != 'Wating' && rc != 'Running'
          ic = if rc == 'AC' then ':smile:' else ':fearful:'
          pr = "#{s.problemID}: [#{s.problemTitle}]"
          if s.lessonID
            pr = "#{s.lessonID}_#{pr}"
          ref = "#{aoj_review_url}?rid=#{s.runID}"
          res.send "#{ic} #{id} got #{rc} for #{pr}(#{ref})"
