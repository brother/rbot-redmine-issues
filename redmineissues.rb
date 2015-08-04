# coding: utf-8

# Redmine issue lookup plugin for rbot
#
# by Martin Bagge / brother <brother@bsnet.se>
#
# License: WTFPL

require 'open-uri'
require 'json'

class RedmineLookup < Plugin
  Config.register Config::StringValue.new('redmine.host',
                                          :default => 'http://localhost',
                                          :desc => _('Domain URL with URI scheme.'))
  Config.register Config::ArrayValue.new('redmine.channels',
                                         :default => ['#kaos'],
                                         :desc => "The channels where the bot will listen (and reply).")

  def privmsg(m)
     m.reply "Listens to channel(s) and responds with issue information from a redmine tracker. Activate the REST API to make it work."
   end

   def help(plugin, topic="")
     "Activate your REST API in Redmine. configure host to read from and channel(s) to watch. See !config list redmine."
   end

   def message(m)
     # move to config some day...
     host = @bot.config['redmine.host']

     unless @bot.config['redmine.channels'].include?(m.channel.to_s)
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
         # See TODO
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
