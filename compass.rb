#!/usr/bin/ruby
require 'cinch'
require './calc'
require './ellipse'
require_relative 'plugins/link_info'

bot = Cinch::Bot.new do
    configure do |c|
        c.server = '$server'
        c.password = '$password'
        c.nick = 'Compass'
        c.channels = ['#$channel']
        c.plugins.plugins = [Cinch::LinkInfo]
    end

    @rules = []
    def rules; @rules; end

    def rule(kw, &block)
        rule = {block: block}
        kw.each do |k,v|
            if Symbol === k
                rule[k] = v
            elsif Array === k
                k.each {|k2| rule[k2] = v}
            end
        end
        rules.push(rule)
    end

    def match(rule, message, *args)
        puts "match(#{rule.inspect}, #{message}, #{args.inspect})"
        args.each do |kw|
            case rule[kw]
            when Regexp
                return true if rule[kw].match(message)
            when Array
                return true if rule[kw].include?(message)
            when String
                return true if rule[kw] == message
            end
        end
        false
    end

    on :message, "!quit" do |m|
        if m.user.nick == 'DeltaWhy'
            bot.quit("Bye")
        else
            m.reply "You're not the boss of me!"
        end
    end

    on :message do |m|
        if m.user.nick =~ /SkypeBot_*/
          m.message =~ /\A\<([^>]+)\> (.+)\z/
          message = $2
          nick = $1.split[0]
        else
          message = m.message
          nick = m.user.nick
        end
        direct = (message =~ /\Acompass[,:] (.+)\z/i)
        types = if !m.channel
                    [:private, :any]
                elsif direct
                    [:direct, :any]
                else
                    [:indirect, :any]
                end
        message = direct ? $1 : message
        bot.rules.each do |rule|
            res = rule[:block].call(m, message, nick) if bot.match(rule, message, *types)
            if res
                m.reply res
                break
            end
        end
    end
end

bot.rule any: /\Ahello compass\z/i, [:direct, :private] => "hello" do |m,cmd,nick|
    greetings = ["Hello", "Hi", "Howdy", "Hey"]
    "#{greetings.sample} #{nick}!"
end

bot.rule any: /\A!(circle|ellipse) ([0-9]+)( ([0-9]+))?\z/, [:direct, :private] => /\A!?(circle|ellipse) ([0-9]+)( ([0-9]+))?\z/ do |m,cmd,nick|
    cmd =~ /\A!?(circle|ellipse) ([0-9]+)( ([0-9]+))?\z/
    xdia = $2.to_i
    ydia = $4 ? $4.to_i : xdia
    next if xdia > 1000 || ydia > 1000
    res = ellipse(xdia, ydia)
    next unless res
    res = "#{nick}: #{res}" if m.message != cmd
    res
end

bot.rule any: /\A!roll ([0-9]*)d([0-9]+)\z/, [:direct, :private] => /\A!?roll ([0-9]*)d([0-9]+)\z/ do |m,cmd,nick|
    cmd =~ /\A!?roll ([0-9]*)d([0-9]+)\z/
    n = $1.to_i
    n = 1 if n == 0
    sides = $2.to_i
    sum = 0
    n.times { sum += Random.rand(1..sides) }
    res = sum.to_s
    res = "#{nick}: #{res}" if m.message != cmd
    res
end

bot.rule any: /\A!flip\z/, [:direct, :private] => /\A!?flip\z/ do |m,cmd,nick|
    res = ["heads","tails"].sample
    res = "#{nick}: #{res}" if m.message != cmd
    res
end

bot.rule any: /\A!?botsnack\z/i do |m,cmd,nick|
    ":D"
end

bot.rule any: /\A!disapprove( (.+))?\z/ do |m,cmd,nick|
    cmd =~ /\A!disapprove( (.+))?\z/
    res = ["(•_•)", "(;¬_¬)", "( ͠° ͟ʖ ͡°)", "(－‸ლ)"].sample
    res = "#{$2}: #{res}" if $2
    res
end

bot.rule direct: /\A(.*) or (.*?)\??\z/i do |m,cmd,nick|
    cmd =~ /\A(.*) or (.*?)\??\z/i
    [$1,$2].sample
end

bot.rule [:direct, :private] => // do |m,cmd,nick|
    res = calc(cmd) rescue nil
    next unless res
    res = "#{nick}: #{res}" if m.message != cmd
    res
end

bot.rule [:direct, :private] => // do |m,cmd,nick|
    "I don't know what you're talking about."
end

bot.start
