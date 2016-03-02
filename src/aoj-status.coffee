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

debug = require('debug')('hubot-aoj-status')
ws = require('ws')

logger = () ->	# will be robot.logger
brain = {  	# will be robot.brain
  get:() ->
  set:() ->
}


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
aoj_stat_icon = [
  ':shit:'
  ':skull:'
  ':clock9:'
  ':boom:'
  ':smile:'
  ':hourglass_flowing_sand:'
  ':pizza:'
  ':no_entry:'
  ':interrobang:'
  ':runner:'
]
aoj_review_url='http://judge.u-aizu.ac.jp/onlinejudge/review.jsp'
watchlist = {}
aoj = null

aoj_onclose = (code, msg) ->
  logger.info "[AOJ] Connection to ionazn.org has been closed(#{code}): #{msg}"
  logger.info "[AOJ] Reconnecting in 3 seconds"
  setTimeout aoj_connect, 3000

aoj_onerror = (error) ->
  logger.error "[AOJ] Error on underlying socket: #{error}"

aoj_pingloop = () ->
  aoj.ping('ping')
  setTimeout aoj_pingloop, 60000

aoj_onopen = () ->
  aoj_pingloop()

aoj_connect = () ->
  debug('connecting to ionazn.org (AOJ status site)')
  aoj = new ws('ws://ionazn.org/status')
  debug('registering on action')
  aoj.on 'message', (data, flags) ->
    s = JSON.parse(data)
    id = s.userID
    rc = aoj_status[s.status]
    debug("#{id}'s status(=#{rc}) has come")
    if rc != 'AC'
      return
    sendmsg = (res) ->
      ic = aoj_stat_icon[s.status]
      pr = "#{s.problemID}: [#{s.problemTitle}]"
      if s.lessonID
        pr = "#{s.lessonID}_#{pr}"
      ref = "#{aoj_review_url}?rid=#{s.runID}"
      res.send "#{ic} #{id} got #{rc} for #{pr}(#{ref})"
    debug("#{id} is in watchlist?")
    if watchlist[id]
      debug("#{id} is in watchlist")
      sendmsg(r) for r in watchlist[id]
    else if res_for_all
      debug("ALL-MODE is enabled.  Adding #{id} into watchlist")
      register id, res_for_all, 'verbose'
    else
      debug("#{id} is NOT in watchlist.  Now my watchlist is:")
      debug("  #{user}") for user, resarr of watchlist
  debug('registering close, error, open actions')
  aoj.on 'close', aoj_onclose
  aoj.on 'error', aoj_onerror
  aoj.on 'open', aoj_onopen

aoj_connect()

memberp = (array, fn) ->
  debug("memberp() called with: #{array}");
  return true for item in array when fn(item)
  return false

register = (user, res, verbose=false) ->
  if watchlist[user] && memberp(watchlist[user], (obj) -> obj && obj.message && obj.message.room == res.message.room)
    if verbose
      res.send "I'm already watching #{user.split("").join(" ")}'s judge results on AOJ"
  else
    if watchlist[user]
      watchlist[user].push(res)
    else
      watchlist[user] = [res]
    brain_add res.message.room, user
    if verbose
      res.send "I'll watch #{user}'s judge results on AOJ"

unregister = (user, res) ->
  if watchlist[user] && memberp(watchlist[user], (obj) -> obj && obj.message && obj.message.room == res.message.room)
    watchlist[user] = watchlist[user].filter (obj) -> obj && obj.message && obj.message.room != res.message.room
    brain_del res.message.room, user
    res.send "I'll drop #{user} from watch list"
  else
    res.send "I'm not watching #{user.split("").join(" ")}"

room2user = null
brain_loaded = false
brain_onloaded = () ->
  if !brain_loaded
    try
      room2user = JSON.parse brain.get "hubot-aoj-status"
    catch error
      logger.error "JSON parse error (reason: #{error}"
  if !room2user
    room2user = {}
  brain_loaded = true

roomcheck = (res) ->
  room = res.message.room
  if !room2user[room]
    return
  register u, res for u, _ of room2user[room]
  delete room2user[room]

brain_add = (room, user) ->
  try
    r2u = JSON.parse brain.get "hubot-aoj-status"
    if !r2u
      r2u = {}
    if !r2u[room]
      r2u[room] = {}
    r2u[room][user] = true
    brain.set "hubot-aoj-status", JSON.stringify r2u
  catch error
    logger.error "JSON parse error (reason: #{error}"

brain_del = (room, user) ->
  try
    r2u = JSON.parse brain.get "hubot-aoj-status"
    if !r2u or !r2u[room]
      return
    delete r2u[room][user]
    brain.set "hubot-aoj-status", JSON.stringify r2u
  catch error
    logger.error "JSON parse error (reason: #{error}"

res_for_all = null
allmode_on = (res) ->
  res_for_all = res

module.exports = (robot) ->
  logger = robot.logger
  brain = robot.brain
  brain_data = {}

  robot.brain.on 'loaded', () ->
    brain_onloaded robot

  robot.respond /aoj reconnect/, (res) ->
    debug("requested to reconnect")
    res.send "Reconnecting..."
    aoj.close()

  robot.respond /aoj watch (.*)/, (res) ->
    debug("watch for #{res.match[1]}")
    register res.match[1], res, 'verbose'

  robot.respond /aoj unwatch (.*)/, (res) ->
    unregister res.match[1], res

  robot.respond /aoj list/, (res) ->
    msg = "I'm watching:"
    msg = "#{msg}\n  #{user.split("").join(" ")}" for r in res_array when r.message.room == res.message.room for user, res_array of watchlist
    res.send msg

  robot.hear /.*/, roomcheck

  # for debug
  robot.respond /aoj watchall/, (res) ->
    res.send "I'll watch for all status"
    allmode_on res

  robot.respond /aoj dump brain/, (res) ->
    try
      data = JSON.parse brain.get "hubot-aoj-status"
      if data
        msg = "here is data for AOJ:"
        msg = "#{msg}\n  #{user.split("").join(" ")}   \tat #{room}" for user,_ of users for room,users of data
        res.send msg
      else
        res.send "No data for AOJ in my brain"
    catch error
      logger.error "JSON parse error (reason: #{error}"

  robot.respond /aoj clear brain/, (res) ->
    res.send "I'll clear all data for AOJ on my brain"
    brain.set "hubot-aoj-status", null

  robot.respond /aoj dump watchlist/, (res) ->
    msg = "AOJ watchlist:"
    msg = "#{msg}\n  #{user.split("").join(" ")}   \tat #{r && r.message && r.message.room}" for r in res_array for user, res_array of watchlist
    res.send msg
