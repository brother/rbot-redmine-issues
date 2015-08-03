# coding: utf-8

# Redmine issue lookup plugin for rbot
#
# by Martin Bagge / brother <brother@bsnet.se>
#
# License: WTFPL

require 'open-uri'
require 'json'

class RedmineLookup < Plugin
   def privmsg(m)
     m.reply "The redmine issue lookup will wait for a issue number to be mentioned, then show some information relevant to that issue."
   end

   def help(plugin, topic="")
     "The redmine issue lookup will wait for a issue number to be mentioned, then show some information relevant to that issue."
   end

   def message(m)
     # move to config some day...
     host = "http://redmine.karen.hh.se"
     channel = "#kaos"

     if m.channel.to_s != channel
       return nil
     end

     # Only scan the line if needed.
     if m.message.downcase.match(/\#\d{1,}/)
       haystack=m.message.split(" ")

       # collect all the needles from the haystack
       # that is all the issue numbers...
       items ||= []
       haystack.each do |needle|
         if needle.match(/\#\d{1,}/)
           items << needle
         end
       end

       # output the information about the issues.
       items.each do |item|
         # For one reason or other I can not pass #1 to this...
         issueid = item[1..-1]
         begin
           data = JSON.parse(open(host + "/issues/" + issueid + ".json").read())
         rescue
           next
         end

         output =  data["issue"]["project"]["name"] + ": #" + String(data["issue"]["id"]) + " " + data["issue"]["subject"]

         # This id might not be the same in all setups...
         # 2 is default for 'in progress'
         if data["issue"]["status"]["id"] == 2
           output += " (" + data["issue"]["assigned_to"]["name"] + ")"
         else
           output += " (" + data["issue"]["status"]["name"] + ")"
         end

         @bot.say(m.channel, output)
         @bot.say(m.channel, "http://redmine.karen.hh.se/issues/" + String(data["issue"]["id"]))
       end
     end
   end
end

rl = RedmineLookup.new
rl.register("issuescan")
