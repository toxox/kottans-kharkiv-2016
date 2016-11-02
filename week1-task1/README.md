# Secure Messages

This is a test task for Kottans! :cat:

### Installation

Clone this repository and run the following commands:

```
bundle install
ruby app.rb
bundle exec sidekiq -r ./app.rb -c 3
```

Once done, the app should become available at `http://localhost:4567`

Run tests with

```
rspec
```

You can also see deployed version of the app [here](http://secure-messages.trublin.com/).
