# ActiveSwitch

ActiveSwitch stores last reported at timestamps in Redis so you can detect if cron style jobs are running at an expected interval.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_switch'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_switch

## Usage

### Configuration & Registration

First, configure `ActiveSwitch`, for instance in a Rails initializer:

```ruby
# config/initializers/active_switch.rb

# configure the Redis client
ActiveSwitch.redis = Redis.new

# expect the big batch job to run within past day
ActiveSwitch.register(:big_batch_job, 1.day)

# expect the weekly mailer to run within the past week
ActiveSwitch.register(:weekly_mailer, 1.week)
```

Attempting to register the same name more than once will raise an `ActiveSwitch::AlreadyRegistered` exception.

Alternatively, you can register in one call with a hash:

```ruby
ActiveSwitch.register({
  big_batch_job: 1.day,
  weekly_mailer: 1.week
})
```

### Reporting In

After your scheduled task or background job completes, you can report it complete:

```ruby
ActiveSwitch.report(:weekly_mailer) # => true
```

Attempting to report on an unregistered name will raise an `ActiveSwitch::UnknownName` exception. This prevents
dead code paths or typos of names.

Alternatively, you can provide `.report` a block to yield:

```ruby
ActiveSwitch.report(:weekly_mailer) { 2 + 2 } # => 4
```

### Status Retrieval

Statuses can be retrieved with `.all`, `.active`, or `.inactive`:

```ruby
ActiveSwitch.report(:weekly_mailer)

# Returns hash of statuses with keys "big_batch_job" and "weekly_mailer"
#
#   {
#     "big_batch_job"=>#<ActiveSwitch::Status:0x007fbb9309e880 @name="big_batch_job", @last_reported_at=nil, @threshold_seconds=86400>},
#     "weekly_mailer"=>#<ActiveSwitch::Status:0x007fbb9309f990 @name="weekly_mailer", @last_reported_at=2017-12-03 23:02:42 -0800, @threshold_seconds=604800>}
#   }
ActiveSwitch.all

# Returns hash of statuses with key "weekly_mailer"
#
#   {
#     "weekly_mailer"=>#<ActiveSwitch::Status:0x007fbb9309f990 @name="weekly_mailer", @last_reported_at=2017-12-03 23:02:42 -0800, @threshold_seconds=604800>}
#   }
ActiveSwitch.active

# Returns hash of statuses with key "big_batch_job"
#
#   {
#     "big_batch_job"=>#<ActiveSwitch::Status:0x007fbb9309e880 @name="big_batch_job", @last_reported_at=nil, @threshold_seconds=86400>}
#   }
ActiveSwitch.inactive
```

Individual status may also be retrieved with `.status`

```ruby
ActiveSwitch.status(:weekly_mailer)
# => <ActiveSwitch::Status:0x007fbb9309f990 @name="weekly_mailer", @last_reported_at=2017-12-03 23:02:42 -0800, @threshold_seconds=604800>
```

### Status instances

A status instance can be asked for its values:

```ruby
status = ActiveSwitch.status(:weekly_mailer)
status.name #=> "weekly_mailer"
status.last_reported_at #=> 2017-12-03 23:02:42 -0800
status.threshold_seconds #=> 604800
```

It can also be checked if active or inactive:

```ruby
status.active? #=> true
status.inactive? #=> false
status.state #=> "ACTIVE"
```

A status is considered active if it was last reported within its registered threshold seconds.

## Redis Storage

All data is stored in a single Redis hash to avoid n+1 roundtrip lookups to Redis when gathering all statuses. Care should
be taken to avoid tracking too many switches to avoid overloading the hash. A maximum of about 1000 would be sane, and likely
beyond typical use.

The hash is stored under the key `active_switch_last_reported_ats` and reflects the following format:

```ruby
# Values are epoch seconds
{
  "weekly_mailer" => "1512371591",
  "big_batch_job" => "1512285202"
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bemurphy/active_switch.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

