# bankr

Gather your bank account data through a nice ruby-esque API. Currently in early -and I mean EARLY- alpha stage.

Currently ONLY supporting a very small scraper for La Caixa.

I recommend you not to use it yet, just wait a bit until it is a bit readier!

## Contributing

You can contribute by creating or enhancing a Scraper for your favorite bank, but just not yet! Bankr API is yet somewhat uncertain and it needs to grow up and mature.
By now we are proud if you just follow the project on Github and check out our updates!

## Running the specs

Just run:
  
    $ rake

Or if you don't trust our mock-stub-fu:

    $ cd lib
    $ ruby test_against_real_website.rb
  
Both options will require you to create a valid_data.yml file under spec/support/. Just follow the example_valid_data.yml there.

## Features (rather a wishlist)

* List your bank accounts
* Get account movements
* Custom alerts

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2011 Codegram. See LICENSE for details.
